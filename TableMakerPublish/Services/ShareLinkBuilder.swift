import Foundation
#if canImport(CryptoKit)
import CryptoKit
#endif

struct ShareLinkBuilder {
    struct SnapshotBlob: Codable {
        let title: String
        let version: Int
        let checksum: String
        let doc: String // base64url of compressed JSON of GuestListDoc/SeatingArrangement
    }
    
    struct LiveBlob: Codable {
        let title: String
        let sessionID: String
        let allowEditing: Bool
        let checksum: String
    }
    
    enum Mode: String { case snapshot, live }
    
    static let base = "https://www.seatmakerapp.com/t"
    
    static func buildSnapshotLink(arrangement: SeatingArrangement, hostDisplayName: String) throws -> URL {
        let docJSON = try JSONEncoder().encode(arrangement)
        let compressed = try LZFSECompression.compress(docJSON)
        let docB64 = compressed.base64URLEncodedString()
        let checksum = sha256Hex(of: docJSON)
        let blob = SnapshotBlob(title: arrangement.title, version: 1, checksum: checksum, doc: docB64)
        let blobJson = try JSONEncoder().encode(blob)
        let blobB64 = blobJson.base64URLEncodedString()
        return try buildURL(mode: .snapshot, hostDisplayName: hostDisplayName, blobBase64Url: blobB64)
    }
    
    static func buildLiveLink(arrangementTitle: String, sessionID: String, allowEditing: Bool, hostDisplayName: String) throws -> URL {
        let checksum = sha256Hex(of: Data((arrangementTitle + sessionID).utf8))
        let blob = LiveBlob(title: arrangementTitle, sessionID: sessionID, allowEditing: allowEditing, checksum: checksum)
        let blobJson = try JSONEncoder().encode(blob)
        let blobB64 = blobJson.base64URLEncodedString()
        return try buildURL(mode: .live, hostDisplayName: hostDisplayName, blobBase64Url: blobB64)
    }
    
    private static func buildURL(mode: Mode, hostDisplayName: String, blobBase64Url: String) throws -> URL {
        // Prefer fragment-based universal link so it works even if serverless store resets.
        var comps = URLComponents(string: base)!
        comps.fragment = "v=1&mode=\(mode.rawValue)&host=\(hostDisplayName)&blob=\(blobBase64Url)"
        guard let url = comps.url else { throw URLError(.badURL) }
        return url
    }
    
    static func sha256Hex(of data: Data) -> String {
        #if canImport(CryptoKit)
        let digest = SHA256.hash(data: data)
        return digest.map { String(format: "%02x", $0) }.joined()
        #else
        // Fallback simple hash (non-cryptographic) to avoid adding dependencies if CryptoKit unavailable
        var hasher = Hasher()
        hasher.combine(data)
        return String(hasher.finalize())
        #endif
    }
}


