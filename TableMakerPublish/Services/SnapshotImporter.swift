import Foundation

enum SnapshotImporter {
    static func persistToHistory(_ arrangement: SeatingArrangement) {
        // Persist using the same storage as app uses via UserDefaults keys
        let defaults = UserDefaults.standard
        let arrangementsKey = "savedArrangements"
        var list: [SeatingArrangement] = []
        if let data = defaults.data(forKey: arrangementsKey) {
            if let decoded = try? JSONDecoder().decode([SeatingArrangement].self, from: data) {
                list = decoded
            }
        }
        var copy = arrangement
        copy.id = UUID()
        copy.date = Date()
        list.append(copy)
        list.sort { $0.date > $1.date }
        if let encoded = try? JSONEncoder().encode(list) {
            defaults.set(encoded, forKey: arrangementsKey)
        }
    }
}


