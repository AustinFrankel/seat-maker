// This is the ONLY source of truth for the SeatingArrangement struct. Do not redefine elsewhere.
import Foundation
import SwiftUI

// MARK: - Seating Arrangement
public struct SeatingArrangement: Identifiable, Codable, Hashable {
    public var id: UUID
    public var title: String // Table name
    public var eventTitle: String? // Event name (new)
    public var date: Date
    public var people: [Person]
    public var tableShape: TableShape
    public var seatAssignments: [UUID: Int]
    // Total people across the entire arrangement (all tables) at the time of save.
    // Optional for backward compatibility with previously saved data.
    public var totalPeopleAtSave: Int? = nil
    
    public init(id: UUID = UUID(), title: String = "Table 1", eventTitle: String? = nil, date: Date = Date(), people: [Person] = [], tableShape: TableShape = .round, seatAssignments: [UUID: Int] = [:], totalPeopleAtSave: Int? = nil) {
        self.id = id
        self.title = title
        self.eventTitle = eventTitle
        self.date = date
        self.people = people
        self.tableShape = tableShape
        self.seatAssignments = seatAssignments
        self.totalPeopleAtSave = totalPeopleAtSave
    }
    
    public var exportDescription: String {
        // Simplified format with emojis as requested
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        
        let eventLine = eventTitle != nil && !eventTitle!.isEmpty ? "🎉 Event: \(eventTitle!)\n" : ""
        var result = eventLine
        result += "🪑 Table: \(title)\n"
        result += "📅 Created on: \(formatter.string(from: date))\n"
        result += "\(tableShape.emoji) Table Shape: \(tableShape.rawValue.capitalized)\n"
        
        // Fix pluralization and explicitly include "People: X" line
        let peopleCount = people.count
        let peopleText = peopleCount == 1 ? "1 person" : "\(peopleCount) people"
        result += "👥 People: \(peopleText)\n\n"
        
        result += "Seating Order:\n\n"
        
        // Get properly ordered people using their seat assignments
        let orderedPeople = people.sorted { (person1, person2) -> Bool in
            let seat1 = seatAssignments[person1.id] ?? 0
            let seat2 = seatAssignments[person2.id] ?? 0
            return seat1 < seat2
        }
        
        if orderedPeople.isEmpty {
            result += "No one seated yet"
        } else {
            for (index, person) in orderedPeople.enumerated() {
                result += "\(index + 1). \(person.name)\n"
            }
        }
        
        return result
    }
    
    // MARK: - Hashable
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    public static func ==(lhs: SeatingArrangement, rhs: SeatingArrangement) -> Bool {
        return lhs.id == rhs.id
    }
}
