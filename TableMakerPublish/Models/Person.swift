import SwiftUI
import Foundation
import UniformTypeIdentifiers

public struct Person: Identifiable, Codable, Equatable {
    public var id: UUID
    public var name: String
    public var isLocked: Bool
    public var colorIndex: Int
    public var profileImageData: Data?
    public var comment: String? // Comments/notes about this person
    public var dietaryRestrictions: [String] // e.g. ["Vegetarian", "Nut Allergy"]
    public var relationships: [UUID] // UUIDs of related people (e.g. sit with, avoid)
    
    // Array of predefined colors
    private static let colorOptions: [Color] = [
        .blue, .green, .orange, .pink, .purple, .red, .yellow, .teal, .indigo,
        .mint, .cyan, .brown, .gray, .blue.opacity(0.8), .green.opacity(0.8),
        .orange.opacity(0.8), .pink.opacity(0.8), .purple.opacity(0.8)
    ]
    
    public init(id: UUID = UUID(), name: String, isLocked: Bool = false, profileImageData: Data? = nil, comment: String? = nil, dietaryRestrictions: [String] = [], relationships: [UUID] = []) {
        // Validate name
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            fatalError("Person name cannot be empty")
        }
        
        // Validate dietary restrictions
        let validDietaryRestrictions = dietaryRestrictions.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        
        // Validate relationships (ensure no duplicates)
        let uniqueRelationships = Array(Set(relationships))
        
        // Validate and process profile image
        var validatedImageData: Data? = nil
        if let imageData = profileImageData {
            // Verify the image data is valid
            if let _ = UIImage(data: imageData) {
                // Compress the image to reduce storage size
                if let compressedData = UIImage(data: imageData)?.jpegData(compressionQuality: 0.7) {
                    validatedImageData = compressedData
                }
            }
        }
        
        self.id = id
        self.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        self.isLocked = isLocked
        self.profileImageData = validatedImageData
        self.comment = comment
        self.dietaryRestrictions = validDietaryRestrictions
        self.relationships = uniqueRelationships
        
        // Generate a consistent color based on the name
        let nameHash = name.lowercased().hash
        self.colorIndex = abs(nameHash) % Person.colorOptions.count
    }
    
    public var color: Color {
        Person.colorOptions[colorIndex]
    }
    
    // Helper method to get profile image
    public func getProfileImage() -> UIImage? {
        guard let imageData = profileImageData else { return nil }
        return UIImage(data: imageData)
    }
    
    // Helper method to update profile image
    public mutating func updateProfileImage(_ image: UIImage?) {
        if let image = image {
            // Compress the image before storing
            profileImageData = image.jpegData(compressionQuality: 0.7)
        } else {
            profileImageData = nil
        }
    }
    
    // MARK: - Codable Implementation
    
    public enum CodingKeys: String, CodingKey {
        case id, name, isLocked, colorIndex, profileImageData, comment, dietaryRestrictions, relationships
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        isLocked = try container.decode(Bool.self, forKey: .isLocked)
        colorIndex = try container.decode(Int.self, forKey: .colorIndex)
        
        // Validate image data during decoding
        if let imageData = try container.decodeIfPresent(Data.self, forKey: .profileImageData) {
            if let _ = UIImage(data: imageData) {
                profileImageData = imageData
            } else {
                profileImageData = nil
            }
        } else {
            profileImageData = nil
        }
        
        comment = try container.decodeIfPresent(String.self, forKey: .comment)
        dietaryRestrictions = try container.decodeIfPresent([String].self, forKey: .dietaryRestrictions) ?? []
        relationships = try container.decodeIfPresent([UUID].self, forKey: .relationships) ?? []
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(isLocked, forKey: .isLocked)
        try container.encode(colorIndex, forKey: .colorIndex)
        try container.encodeIfPresent(profileImageData, forKey: .profileImageData)
        try container.encodeIfPresent(comment, forKey: .comment)
        try container.encode(dietaryRestrictions, forKey: .dietaryRestrictions)
        try container.encode(relationships, forKey: .relationships)
    }
    
    // MARK: - Equatable
    
    public static func ==(lhs: Person, rhs: Person) -> Bool {
        return lhs.id == rhs.id
    }
} 

// MARK: - Drag & Drop Support

extension Person: Transferable {
    public static var transferRepresentation: some TransferRepresentation {
        // Use a standard data content type to avoid requiring a custom UTI declaration
        CodableRepresentation(contentType: .data)
    }
}