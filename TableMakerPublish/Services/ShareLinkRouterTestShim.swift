import Foundation

// Internal-only shim to expose parsing and validation for tests without making router API public
enum ShareLinkRouterTestShim {
    static func parse(url: URL) throws -> ShareLinkRouter.Payload {
        return try _parse(url: url)
    }
    static func validateBasic(payload: ShareLinkRouter.Payload) throws {
        try _validate(payload: payload)
    }
}

// MARK: - Private hooks via fileprivate extensions
fileprivate func _parse(url: URL) throws -> ShareLinkRouter.Payload {
    // Re-implement minimal parsing to keep visibility clean and consistent with ShareLinkRouter
    guard let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems else {
        throw RouterError.malformed
    }
    func value(_ name: String) -> String? { items.first(where: { $0.name == name })?.value }
    guard let vStr = value("v"), let version = Int(vStr) else { throw RouterError.missingRequired("v") }
    guard let modeStr = value("mode"), let mode = ShareLinkRouter.RouteMode(rawValue: modeStr) else { throw RouterError.missingRequired("mode") }
    guard let ttlStr = value("ttl"), let ttl = Int(ttlStr) else { throw RouterError.missingRequired("ttl") }
    guard let pin = value("pin"), pin.count == 6, pin.allSatisfy({ $0.isNumber }) else { throw RouterError.invalidPIN }
    guard let host = value("host"), !host.isEmpty else { throw RouterError.missingRequired("host") }
    guard let blob = value("blob"), !blob.isEmpty else { throw RouterError.missingRequired("blob") }
    return ShareLinkRouter.Payload(version: version, mode: mode, expiresAtEpoch: ttl, pin: pin, host: host, blobBase64Url: blob)
}

fileprivate func _validate(payload: ShareLinkRouter.Payload) throws {
    guard payload.version == 1 else { throw RouterError.unsupportedVersion }
    if let ttl = payload.expiresAtEpoch {
        let now = Int(Date().timeIntervalSince1970)
        guard now <= ttl else { throw RouterError.expired }
    }
}


