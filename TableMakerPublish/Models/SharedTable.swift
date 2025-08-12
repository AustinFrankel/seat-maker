import Foundation

public struct SharedTable: Codable {
    public let id: String
    public let arrangement: SeatingArrangement
    public let createdAt: Date
    public let expiresAt: Date
    
    public init(id: String = UUID().uuidString,
                arrangement: SeatingArrangement,
                createdAt: Date = Date(),
                expiresAt: Date = Date().addingTimeInterval(7 * 24 * 60 * 60)) { // 7 days expiration
        self.id = id
        self.arrangement = arrangement
        self.createdAt = createdAt
        self.expiresAt = expiresAt
    }
    
    public var isExpired: Bool {
        Date() > expiresAt
    }
    
    public var shareableLink: String {
        "tablemaker://share/\(id)"
    }
    
    public var webLink: String {
        "https://tablemaker.app/share/\(id)"
    }
} 