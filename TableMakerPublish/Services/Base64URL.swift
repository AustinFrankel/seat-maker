import Foundation

enum Base64URLError: Error {
    case invalidString
}

extension Data {
    func base64URLEncodedString() -> String {
        let base64 = self.base64EncodedString()
        let base64url = base64
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
        // No padding for URL-safe
        return base64url
    }
    
    init(base64URLEncoded base64url: String) throws {
        var base64 = base64url
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        // Pad with '=' to make length a multiple of 4
        let remainder = base64.count % 4
        if remainder > 0 {
            base64 += String(repeating: "=", count: 4 - remainder)
        }
        guard let decoded = Data(base64Encoded: base64) else {
            throw Base64URLError.invalidString
        }
        self = decoded
    }
}


