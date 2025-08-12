import Foundation
import SwiftUI

public enum TableShape: String, Codable, CaseIterable, Identifiable {
    case round
    case square
    case rectangle
    
    public var id: String { self.rawValue }
    
    public var displayName: String {
        switch self {
        case .round: return "Round Table"
        case .square: return "Square Table"
        case .rectangle: return "Rectangle Table"
        }
    }
    
    public var emoji: String {
        switch self {
        case .round: return "◯"
        case .square: return "□"
        case .rectangle: return "▭"
        }
    }
    
    public var path: Path {
        switch self {
        case .round:
            return Path(CGRect(x: -100, y: -100, width: 200, height: 200))
        case .square:
            return Path(CGRect(x: -100, y: -100, width: 200, height: 200))
        case .rectangle:
            return Path(CGRect(x: -120, y: -80, width: 240, height: 160))
        }
    }
}

public struct TableCollection: Codable {
    public var tables: [Int: SeatingArrangement]
    public var currentTableId: Int
    public var maxTableId: Int
    
    public init(tables: [Int: SeatingArrangement] = [:], currentTableId: Int = 0, maxTableId: Int = 0) {
        self.tables = tables
        self.currentTableId = currentTableId
        self.maxTableId = maxTableId
    }
}

public enum NavigationDirection: String, CaseIterable, Identifiable {
    case left
    case right
    
    public var id: String { self.rawValue }
} 