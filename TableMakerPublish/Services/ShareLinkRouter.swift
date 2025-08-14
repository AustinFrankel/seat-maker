import Foundation

@MainActor
final class ShareLinkRouter {
    static let shared = ShareLinkRouter()
    private init() {}
    
    enum RouteMode: String { case snapshot, live }
    
    struct Payload {
        let version: Int
        let mode: RouteMode
        let expiresAtEpoch: Int?
        let pin: String?
        let host: String
        let blobBase64Url: String
    }
    
    private let allowedHosts: Set<String> = [
        "share.seatmaker.app",
        "seatmakerapp.com",
        "www.seatmakerapp.com"
    ]
    private let legacyPathPrefix = "/sm/share"
    private var isPresenting: Bool = false
    private var queuedURL: URL?
    
    func handleIncomingURL(_ url: URL) {
        // Accept legacy and new universal links
        guard url.scheme == "https", let host = url.host, allowedHosts.contains(host) else { return }
        if isPresenting {
            queuedURL = url
            return
        }
        do {
            // New scheme: https://www.seatmakerapp.com/t/{slug} or /t#v=1&d=...
            if url.path.hasPrefix("/t") || url.absoluteString.contains("/t#") {
                if let fragment = url.fragment, fragment.contains("d=") {
                    isPresenting = true
                    let data = try ShareLayoutCoordinator.decodeFragment(fragment)
                    let arrangement = try ShareLayoutCoordinator.arrangement(fromSnapshot: data)
                    SnapshotImporter.persistToHistory(arrangement)
                    NotificationCenter.default.post(name: .shareLinkImportCompleted, object: nil, userInfo: ["arrangement": arrangement, "title": arrangement.title])
                } else if url.pathComponents.count >= 2 {
                    isPresenting = true
                    let slug = url.lastPathComponent
                    Task { @MainActor in
                        do {
                            let data = try await ShareLayoutCoordinator.fetchSnapshot(slug: slug, base: url)
                            let arrangement = try ShareLayoutCoordinator.arrangement(fromSnapshot: data)
                            SnapshotImporter.persistToHistory(arrangement)
                            NotificationCenter.default.post(name: .shareLinkImportCompleted, object: nil, userInfo: ["arrangement": arrangement, "title": arrangement.title])
                        } catch {
                            NotificationCenter.default.post(name: .shareLinkError, object: nil, userInfo: ["message": error.localizedDescription])
                        }
                    }
                }
                return
            }
            // Legacy flow via query params or fragment containing legacy params
            let payload = try parse(url: url)
            try validateBasic(payload: payload)
            switch payload.mode {
            case .snapshot:
                isPresenting = true
                try handleSnapshot(blobB64: payload.blobBase64Url)
            case .live:
                isPresenting = true
                try handleLive(blobB64: payload.blobBase64Url, pin: payload.pin)
            }
        } catch {
            NotificationCenter.default.post(name: .shareLinkError, object: nil, userInfo: ["message": error.localizedDescription])
        }
    }
    
    func markPresentationComplete() {
        isPresenting = false
        if let next = queuedURL {
            queuedURL = nil
            handleIncomingURL(next)
        }
    }
    
    private func parse(url: URL) throws -> Payload {
        guard let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems else {
            throw RouterError.malformed
        }
        func value(_ name: String) -> String? { items.first(where: { $0.name == name })?.value }
        guard let vStr = value("v"), let version = Int(vStr) else { throw RouterError.missingRequired("v") }
        guard let modeStr = value("mode"), let mode = RouteMode(rawValue: modeStr) else { throw RouterError.missingRequired("mode") }
        let ttl = Int(value("ttl") ?? "")
        let pinValue = value("pin")
        if let pinStr = pinValue, !(pinStr.count == 6 && pinStr.allSatisfy({ $0.isNumber })) { throw RouterError.invalidPIN }
        guard let host = value("host"), !host.isEmpty else { throw RouterError.missingRequired("host") }
        guard let blob = value("blob"), !blob.isEmpty else { throw RouterError.missingRequired("blob") }
        return Payload(version: version, mode: mode, expiresAtEpoch: ttl, pin: pinValue, host: host, blobBase64Url: blob)
    }
    
    private func validateBasic(payload: Payload) throws {
        guard payload.version == 1 else { throw RouterError.unsupportedVersion }
        if let ttl = payload.expiresAtEpoch {
            let now = Int(Date().timeIntervalSince1970)
            guard now <= ttl else { throw RouterError.expired }
        }
    }
    
    private func handleSnapshot(blobB64: String) throws {
        let data = try Data(base64URLEncoded: blobB64)
        let blob = try JSONDecoder().decode(ShareLinkBuilder.SnapshotBlob.self, from: data)
        guard let docData = try? Data(base64URLEncoded: blob.doc) else { throw RouterError.malformed }
        let decompressed = try LZFSECompression.decompress(docData)
        // Validate checksum
        let checksum = ShareLinkBuilder.sha256HexPublic(of: decompressed)
        guard checksum == blob.checksum else { throw RouterError.checksumMismatch }
        let arrangement = try JSONDecoder().decode(SeatingArrangement.self, from: decompressed)
        SnapshotImporter.persistToHistory(arrangement)
        NotificationCenter.default.post(name: .shareLinkImportCompleted, object: nil, userInfo: [
            "arrangement": arrangement,
            "title": blob.title
        ])
    }
    
    private func handleLive(blobB64: String, pin: String?) throws {
        let data = try Data(base64URLEncoded: blobB64)
        let blob = try JSONDecoder().decode(ShareLinkBuilder.LiveBlob.self, from: data)
        // Basic checksum: title + sessionID
        let expected = ShareLinkBuilder.sha256HexPublic(of: Data((blob.title + blob.sessionID).utf8))
        guard expected == blob.checksum else { throw RouterError.checksumMismatch }
        LiveShareService.shared.join(sessionID: blob.sessionID, pin: pin ?? "000000") { result in
            switch result {
            case .success(let arrangement):
                NotificationCenter.default.post(name: .shareLinkImportCompleted, object: nil, userInfo: [
                    "arrangement": arrangement,
                    "title": blob.title,
                    "live": true,
                    "allowEditing": blob.allowEditing
                ])
            case .failure(let error):
                NotificationCenter.default.post(name: .shareLinkError, object: nil, userInfo: ["message": error.localizedDescription])
            }
        }
    }
}

enum RouterError: LocalizedError {
    case malformed
    case missingRequired(String)
    case unsupportedVersion
    case expired
    case invalidPIN
    case checksumMismatch
    
    var errorDescription: String? {
        switch self {
        case .malformed: return "This QR link is invalid."
        case .missingRequired(let k): return "Missing required parameter: \(k)."
        case .unsupportedVersion: return "This link version is not supported."
        case .expired: return "This QR link has expired."
        case .invalidPIN: return "PIN must be 6 digits."
        case .checksumMismatch: return "Link data failed integrity check."
        }
    }
}

extension Notification.Name {
    static let shareLinkImportCompleted = Notification.Name("ShareLinkImportCompleted")
    static let shareLinkError = Notification.Name("ShareLinkError")
}

extension ShareLinkBuilder {
    // Expose hash for router validation
    static func sha256HexPublic(of data: Data) -> String {
        return sha256Hex(of: data)
    }
}


