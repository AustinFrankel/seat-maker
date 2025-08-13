import Foundation
import SwiftUI
import Contacts
@preconcurrency import Contacts

@MainActor
class SeatingViewModel: ObservableObject {
    @Published var currentArrangement: SeatingArrangement
    @Published var savedArrangements: [SeatingArrangement] = []
    @Published var isShuffling = false
    @Published var suggestedNames: [String] = []
    @Published var contacts: [String] = []
    @Published var isLoadingContacts = false
    @Published var justAddedPerson = false
    @Published var isViewingHistory = false
    @Published var hideSeatNumbers: Bool = false
    @Published var hideTableNumber: Bool = false
    
    // Add properties for multi-table support
    @Published var tableCollection = TableCollection()
    @Published var currentTableName: String = ""
    
    @AppStorage("defaultTableShape") private var _defaultTableShapeRaw: String = TableShape.round.rawValue
    @AppStorage("lockByDefault") var lockByDefault: Bool = false
    @AppStorage("hideSeatNumbers") var hideSeatNumbersStorage: Bool = false
    @AppStorage("hideTableNumber") var hideTableNumberStorage: Bool = false
    @AppStorage("tableCollection") private var tableCollectionData: Data?
    
    // Add property for QR code sheet
    @Published var showingQRCodeSheet: Bool = false
    
    @Published var sharingService = TableSharingService()
    @Published var showingShareSheet = false
    @Published var currentSharedTable: SharedTable?
    
    var defaultTableShape: TableShape {
        get {
            return TableShape(rawValue: _defaultTableShapeRaw) ?? .round
        }
        set {
            _defaultTableShapeRaw = newValue.rawValue
        }
    }
    
    var hasSavedArrangements: Bool {
        !savedArrangements.isEmpty
    }
    
    var totalPeopleSeated: Int {
        savedArrangements.reduce(0) { $0 + $1.people.count }
    }
    
    var averagePeoplePerTable: Double {
        guard !savedArrangements.isEmpty else { return 0 }
        return Double(totalPeopleSeated) / Double(savedArrangements.count)
    }
    
    var mostUsedTableShape: TableShape {
        let shapeCounts = savedArrangements.reduce(into: [TableShape: Int]()) { counts, arrangement in
            counts[arrangement.tableShape, default: 0] += 1
        }
        return shapeCounts.max(by: { $0.value < $1.value })?.key ?? .round
    }
    
    private let userDefaults = UserDefaults.standard
    private let arrangementsKey = "savedArrangements"
    private let usedNamesKey = "usedNames"
    private var loadTask: Task<Void, Never>?
    private var usedNames: Set<String> = []
    
    // Add contacts cache
    private var contactsCache: [String]?
    private var lastContactsFetch: Date?
    private let contactsCacheTimeout: TimeInterval = 300 // 5 minutes
    private var isFetchingContacts = false // Add flag to prevent multiple simultaneous fetches
    private var contactsFetchTask: Task<Void, Never>? // Add task reference for cancellation
    
    init() {
        // Initialize properties before using self
        let rawShapeValue = UserDefaults.standard.string(forKey: "defaultTableShape") ?? TableShape.round.rawValue
        let initialShape = TableShape(rawValue: rawShapeValue) ?? .round
        
        self.currentArrangement = SeatingArrangement(
            title: "New Arrangement",
            people: [],
            tableShape: initialShape
        )
        
        // Initialize hideSeatNumbers and hideTableNumber from storage
        self.hideSeatNumbers = hideSeatNumbersStorage
        self.hideTableNumber = hideTableNumberStorage
        
        // Set default value for hideTableNumber if it hasn't been set before
        if !UserDefaults.standard.bool(forKey: "hasInitializedTableNumber") {
            self.hideTableNumber = false // Start with table numbers showing
            self.hideTableNumberStorage = false
            UserDefaults.standard.set(true, forKey: "hasInitializedTableNumber")
        }
        
        // Load saved arrangements and used names asynchronously with lower priority
        loadTask = Task(priority: .background) {
            await loadSavedArrangements()
            await loadUsedNames()
            
            // Load table collection on main actor with user-initiated priority
            await MainActor.run {
                loadTableCollection()
            }
        }
    }
    
    deinit {
        loadTask?.cancel()
        contactsFetchTask?.cancel()
    }

    // MARK: - Import from List integration
    /// Create multiple tables from imported assignments and shapes.
    /// - Parameters:
    ///   - assignments: Array of arrays, each inner array is the list of imported person names for that table.
    ///   - shapes: Table shapes to assign per table (cycled if fewer than assignments).
    ///   - eventTitle: Optional event title to store with tables and snapshot.
    @MainActor
    func createTablesFromImported(assignments: [[String]], shapes: [TableShape], eventTitle: String?) {
        guard !assignments.isEmpty else { return }
        // Save current table state first
        saveCurrentTableState()
        var newTables: [Int: SeatingArrangement] = tableCollection.tables
        var nextId = (newTables.keys.max() ?? -1) + 1

        for (index, peopleNames) in assignments.enumerated() {
            let shape = shapes.isEmpty ? defaultTableShape : shapes[index % max(shapes.count, 1)]
            var arrangement = SeatingArrangement(
                id: UUID(),
                title: "Table \(nextId + 1)",
                eventTitle: eventTitle,
                date: Date(),
                people: [],
                tableShape: shape,
                seatAssignments: [:]
            )
            // Build Person objects preserving name; tags/notes not modeled on Person except dietary/relationships/comment
            var seatIndex = 0
            for name in peopleNames {
                let person = Person(name: name, isLocked: lockByDefault)
                arrangement.people.append(person)
                arrangement.seatAssignments[person.id] = seatIndex
                seatIndex += 1
            }
            newTables[nextId] = arrangement
            nextId += 1
        }

        tableCollection.tables = newTables
        tableCollection.currentTableId = max(0, (newTables.keys.min() ?? 0))
        tableCollection.maxTableId = (newTables.keys.max() ?? 0)
        if let current = newTables[tableCollection.currentTableId] {
            currentArrangement = current
            currentTableName = current.title
        }
        saveTableCollection()

        // Save snapshot in history
        saveCurrentArrangement()
    }
    
    func fetchContacts(completion: ((Bool) -> Void)? = nil) {
        print("[Contacts] fetchContacts called")
        if isFetchingContacts {
            print("[Contacts] Fetch already in progress.")
            completion?(false)
            return
        }
        
        // Check cache first
        if let cachedContacts = contactsCache,
           let lastFetch = lastContactsFetch,
           Date().timeIntervalSince(lastFetch) < contactsCacheTimeout {
            print("[Contacts] Using cached contacts.")
            DispatchQueue.main.async {
                self.contacts = cachedContacts
                self.isLoadingContacts = false
                completion?(true)
            }
            return
        }
        
        isFetchingContacts = true
        isLoadingContacts = true
        
        Task {
            do {
                let store = CNContactStore()
                let status = CNContactStore.authorizationStatus(for: .contacts)
                
                if status == .notDetermined {
                    print("[Contacts] Authorization not determined, requesting access.")
                    let granted = try await CNContactStore().requestAccess(for: .contacts)
                    if !granted {
                        print("[Contacts] Permission denied.")
                        await MainActor.run {
                            self.isLoadingContacts = false
                            self.isFetchingContacts = false
                            NotificationCenter.default.post(name: Notification.Name("ShowContactsDeniedAlert"), object: nil)
                            completion?(false)
                        }
                        return
                    }
                } else if status != .authorized {
                    print("[Contacts] Permission denied.")
                    await MainActor.run {
                        self.isLoadingContacts = false
                        self.isFetchingContacts = false
                        NotificationCenter.default.post(name: Notification.Name("ShowContactsDeniedAlert"), object: nil)
                        completion?(false)
                    }
                    return
                }
                
                let keysToFetch: [CNKeyDescriptor] = [
                    CNContactGivenNameKey as CNKeyDescriptor,
                    CNContactFamilyNameKey as CNKeyDescriptor
                ]
                
                var fetchedContacts: [String] = []
                let request = CNContactFetchRequest(keysToFetch: keysToFetch)
                request.sortOrder = .givenName
                
                // Perform the enumeration on a background thread
                try await Task.detached {
                    try store.enumerateContacts(with: request) { contact, _ in
                        let fullName = "\(contact.givenName) \(contact.familyName)".trimmingCharacters(in: .whitespacesAndNewlines)
                        if !fullName.isEmpty {
                            fetchedContacts.append(fullName)
                        }
                    }
                }.value
                
                // Update UI on main thread
                await MainActor.run {
                    self.contacts = fetchedContacts
                    self.contactsCache = fetchedContacts
                    self.lastContactsFetch = Date()
                    self.isLoadingContacts = false
                    self.isFetchingContacts = false
                    completion?(true)
                }
                
            } catch {
                print("[Contacts] Error fetching contacts: \(error)")
                await MainActor.run {
                    self.isLoadingContacts = false
                    self.isFetchingContacts = false
                    completion?(false)
                }
            }
        }
    }
    
    // MARK: - Phone numbers lookup for group text
    /// Best-effort lookup of phone numbers for the provided people by matching their names in the user's Contacts.
    /// Returns a unique list of sanitized phone numbers suitable for use with the Messages composer.
    func fetchPhoneNumbers(for people: [Person]) async -> [String] {
        // Request access first if needed
        let store = CNContactStore()
        let status = CNContactStore.authorizationStatus(for: .contacts)
        if status == .notDetermined {
            do { _ = try await store.requestAccess(for: .contacts) } catch { return [] }
        } else if status != .authorized {
            return []
        }

        // Helper to keep only digits and leading '+'
        func sanitizePhone(_ raw: String) -> String {
            let allowed = Set("+0123456789")
            var result = ""
            for ch in raw { if allowed.contains(ch) { result.append(ch) } }
            // Ensure only a single leading '+' is kept
            if let firstPlus = result.firstIndex(of: "+") {
                if firstPlus != result.startIndex { result.remove(at: firstPlus) }
                // Remove any additional '+'
                result = result.enumerated().filter { $0.element != "+" || $0.offset == 0 }.map { String($0.element) }.joined()
            }
            return result
        }

        var numbers: Set<String> = []
        let keysToFetch: [CNKeyDescriptor] = [
            CNContactGivenNameKey as CNKeyDescriptor,
            CNContactFamilyNameKey as CNKeyDescriptor,
            CNContactPhoneNumbersKey as CNKeyDescriptor
        ]

        // Match by name using Contacts predicate for robustness
        for person in people {
            let nameQuery = person.name.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !nameQuery.isEmpty else { continue }
            let predicate = CNContact.predicateForContacts(matchingName: nameQuery)
            do {
                let matches = try store.unifiedContacts(matching: predicate, keysToFetch: keysToFetch)
                // Prefer exact display name match when possible, otherwise take the first match
                let chosen: CNContact? = {
                    if let exact = matches.first(where: { ("")
                        .appending($0.givenName).appending(" ").appending($0.familyName)
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                        .localizedCaseInsensitiveCompare(nameQuery) == .orderedSame }) {
                        return exact
                    }
                    return matches.first
                }()
                if let contact = chosen {
                    if let firstNumber = contact.phoneNumbers.first?.value.stringValue, !firstNumber.isEmpty {
                        let sanitized = sanitizePhone(firstNumber)
                        if !sanitized.isEmpty { numbers.insert(sanitized) }
                    }
                }
            } catch {
                // Skip this person on error and continue
                continue
            }
        }

        return Array(numbers)
    }
    
    func addPerson(name: String) {
        // Validate input
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            NotificationCenter.default.post(
                name: Notification.Name("ShowErrorAlert"),
                object: nil,
                userInfo: ["message": "Name cannot be empty"]
            )
            return
        }
        
        // Check if we've reached the maximum number of people (20)
        if currentArrangement.people.count >= 20 {
            NotificationCenter.default.post(
                name: Notification.Name("ShowMaxPeopleAlert"),
                object: nil,
                userInfo: ["message": "Maximum of 20 people per table reached"]
            )
            return
        }
        
        // Only check for duplicates if we have tables with people
        if !tableCollection.tables.isEmpty {
            if let collectionData = tableCollectionData {
                do {
                    let decodedCollection = try JSONDecoder().decode(TableCollection.self, from: collectionData)
                    let allPeople = decodedCollection.tables.flatMap { (tableId, arrangement) -> [(person: Person, tableId: Int)] in
                        return arrangement.people.map { (person: $0, tableId: tableId) }
                    }
                    
                    if let existingSeat = allPeople.first(where: { $0.person.name.lowercased() == trimmedName.lowercased() }) {
                        NotificationCenter.default.post(
                            name: Notification.Name("ShowDuplicatePersonAlert"),
                            object: nil,
                            userInfo: [
                                "message": "\(trimmedName) is already seated at Table \(existingSeat.tableId + 1)",
                                "personName": trimmedName,
                                "tableId": existingSeat.tableId
                            ]
                        )
                        return
                    }
                } catch {
                    print("Error decoding table collection: \(error)")
                    // Continue with adding the person if we can't verify duplicates
                }
            }
        }
        
        // Create and add the person
        let person = Person(name: trimmedName, isLocked: lockByDefault)
        
        // Ensure unique color assignment
        var uniqueColorIndex = person.colorIndex
        let usedColorIndices = Set(currentArrangement.people.map { $0.colorIndex })
        let availableColors = Array(0..<12) // Use first 12 colors for better variety
        
        if usedColorIndices.contains(uniqueColorIndex) {
            // Find an unused color
            for colorIndex in availableColors {
                if !usedColorIndices.contains(colorIndex) {
                    uniqueColorIndex = colorIndex
                    break
                }
            }
            // If all colors are used, use a random one
            if usedColorIndices.contains(uniqueColorIndex) {
                uniqueColorIndex = availableColors.randomElement() ?? 0
            }
        }
        
        // Create person with unique color
        var personWithUniqueColor = person
        personWithUniqueColor.colorIndex = uniqueColorIndex
        currentArrangement.people.append(personWithUniqueColor)
        
        // Assign the new person to the next available seat
        let lastSeat = currentArrangement.people.count - 1
        currentArrangement.seatAssignments[person.id] = lastSeat
        
        // Add to used names
        usedNames.insert(trimmedName)
        saveUsedNames()
        
        // Set flag that we just added a person
        justAddedPerson = true
        // Persist immediately so Table Manager reflects counts right away
        saveCurrentTableState()
        saveTableCollection()
    }
    
    func removePerson(at index: Int) {
        guard index >= 0 && index < currentArrangement.people.count else {
            print("Invalid index for removing person: \(index)")
            return
        }
        
        let personId = currentArrangement.people[index].id
        currentArrangement.people.remove(at: index)
        currentArrangement.seatAssignments.removeValue(forKey: personId)
        
        // Reassign remaining seats to maintain order
        for (index, person) in currentArrangement.people.enumerated() {
            currentArrangement.seatAssignments[person.id] = index
        }
    }
    
    func toggleLock(for personId: UUID) {
        guard let index = currentArrangement.people.firstIndex(where: { $0.id == personId }) else {
            print("Person with ID \(personId) not found")
            return
        }
        currentArrangement.people[index].isLocked.toggle()
    }
    

    
    func shuffleSeats() {
        isShuffling = true
        let people = currentArrangement.people
        let locked = people.filter { $0.isLocked }
        let unlocked = people.filter { !$0.isLocked }
        // Don't shuffle if only one person or all are locked
        if people.count <= 1 || unlocked.isEmpty {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.isShuffling = false
            }
            return
        }
        let totalSeats = people.count
        let currentAssignments = currentArrangement.seatAssignments
        var newAssignments: [UUID: Int] = [:]
        var attempt = 0
        let maxAttempts = 12
        var changed = false
        repeat {
            attempt += 1
            newAssignments.removeAll()
            // Keep locked people in their current positions
            for person in locked {
                if let currentSeat = currentAssignments[person.id] {
                    newAssignments[person.id] = currentSeat
                }
            }
            // Shuffle unlocked people
            var availableSeats = Set(0..<totalSeats)
            for (_, seat) in newAssignments { availableSeats.remove(seat) }
            var availableSeatsArray = Array(availableSeats)
            availableSeatsArray.shuffle()
            for (idx, person) in unlocked.enumerated() {
                if idx < availableSeatsArray.count {
                    newAssignments[person.id] = availableSeatsArray[idx]
                } else {
                    newAssignments[person.id] = availableSeatsArray.randomElement() ?? idx
                }
            }
            // Ensure all seat assignments are unique
            let uniqueSeats = Set(newAssignments.values)
            // Check if arrangement changed for unlocked people
            changed = unlocked.contains { person in
                newAssignments[person.id] != currentAssignments[person.id]
            }
            if uniqueSeats.count == newAssignments.count && changed {
                break
            }
        } while attempt < maxAttempts
        // If after all attempts, arrangement didn't change, force a swap
        if !changed && unlocked.count > 1 {
            let ids = unlocked.map { $0.id }
            if ids.count > 1 {
                let a = ids[0], b = ids[1]
                let seatA = currentAssignments[a] ?? 0
                let seatB = currentAssignments[b] ?? 1
                newAssignments[a] = seatB
                newAssignments[b] = seatA
            }
        }
        withAnimation(.spring(response: 0.7, dampingFraction: 0.7)) {
            currentArrangement.seatAssignments = newAssignments
            // Keep people array ordered by seat number so lists show 1., 2., ...
            currentArrangement.people.sort { a, b in
                (newAssignments[a.id] ?? 0) < (newAssignments[b.id] ?? 0)
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.isShuffling = false
        }
    }
    
    func saveCurrentArrangement() {
        // First, save to the table collection
        saveCurrentTableState()
        
        // Use eventTitle for the history title if available
        let historyTitle: String
        if let eventTitle = currentArrangement.eventTitle, !eventTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            historyTitle = eventTitle
        } else if !currentTableName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            historyTitle = currentTableName
        } else {
            historyTitle = "Table \(tableCollection.currentTableId + 1)"
        }
        
        // Create a new arrangement with a unique ID for the history
        let newArrangement = SeatingArrangement(
            id: UUID(),
            title: historyTitle, // Use event name for history
            eventTitle: currentArrangement.eventTitle, // Event name
            date: Date(),
            people: currentArrangement.people,
            tableShape: currentArrangement.tableShape,
            seatAssignments: currentArrangement.seatAssignments
        )
        
        // Add to saved arrangements and sort by date
        savedArrangements.append(newArrangement)
        savedArrangements.sort(by: { $0.date > $1.date })
        
        // Save asynchronously
        Task {
            await saveToUserDefaults()
            saveTableCollection() // Also save the table collection
        }
    }
    
    func loadArrangement(_ arrangement: SeatingArrangement) {
        // Save the current table state before loading from history
        saveCurrentTableState()
        
        // Now set the current arrangement from history
        currentArrangement = arrangement
        currentTableName = arrangement.title  // Set the table name from the arrangement
        isViewingHistory = true
    }
    
    func movePerson(from source: IndexSet, to destination: Int) {
        // Prevent moving locked people and keep locked positions fixed
        let lockedIndices = Set(currentArrangement.people.enumerated().compactMap { $0.element.isLocked ? $0.offset : nil })
        // If the source includes any locked index, ignore the move
        if source.contains(where: { lockedIndices.contains($0) }) {
            return
        }
        // Adjust destination to nearest unlocked slot
        var adjustedDestination = destination
        if lockedIndices.contains(adjustedDestination) {
            if let src = source.first, src < destination {
                while adjustedDestination < currentArrangement.people.count && lockedIndices.contains(adjustedDestination) {
                    adjustedDestination += 1
                }
            } else {
                while adjustedDestination > 0 && lockedIndices.contains(adjustedDestination - 1) {
                    adjustedDestination -= 1
                }
            }
        }
        withAnimation(.interactiveSpring(response: 0.42, dampingFraction: 0.86, blendDuration: 0.22)) {
            currentArrangement.people.move(fromOffsets: source, toOffset: adjustedDestination)
            // Update seat assignments to maintain order
            for (index, person) in currentArrangement.people.enumerated() {
                currentArrangement.seatAssignments[person.id] = index
            }
        }
    }
    
    func deleteAllHistory() {
        // Clear all arrangements and tables
        savedArrangements.removeAll()
        tableCollection.tables.removeAll()
        tableCollection.currentTableId = 0
        tableCollection.maxTableId = 0
        currentArrangement = SeatingArrangement(tableShape: defaultTableShape)
        currentTableName = ""
        isViewingHistory = false
        
        // Clear all UserDefaults data
        UserDefaults.standard.removeObject(forKey: arrangementsKey)
        UserDefaults.standard.removeObject(forKey: "tableCollection")
        UserDefaults.standard.removeObject(forKey: usedNamesKey)
        
        // Clear contacts cache
        contactsCache = nil
        lastContactsFetch = nil
        contacts.removeAll()
        
        // Save cleared state
        saveTableCollection()
        Task {
            await saveToUserDefaults()
        }
        
        // Set hasSeenTutorial to false to show tutorial view
        UserDefaults.standard.set(false, forKey: "hasSeenTutorial")
        
        // Force UI update
        objectWillChange.send()
    }
    
    func resetAndShowWelcomeScreen() {
        // Clear all data but keep tutorial as seen
        tableCollection.tables = [:]
        tableCollection.currentTableId = 0
        tableCollection.maxTableId = 0
        currentArrangement = SeatingArrangement(
            title: "New Arrangement",
            people: [],
            tableShape: defaultTableShape
        )
        currentTableName = ""
        isViewingHistory = false
        saveTableCollection()
        UserDefaults.standard.set(true, forKey: "hasSeenTutorial")
        
        // Force UI update
        objectWillChange.send()
    }
    
    func getSuggestedNames(for searchText: String) {
        guard !searchText.isEmpty else { suggestedNames = []; return }
        
        // Filter fetched contacts
        suggestedNames = contacts.filter { $0.lowercased().contains(searchText.lowercased()) }
    }
    
    private func loadSavedArrangements() async {
        do {
            if let data = userDefaults.data(forKey: arrangementsKey) {
                let decoded = try JSONDecoder().decode([SeatingArrangement].self, from: data)
                
                // Validate each arrangement
                let validArrangements = decoded.filter { arrangement in
                    // Validate title
                    guard !arrangement.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                        return false
                    }
                    
                    // Validate people
                    guard !arrangement.people.isEmpty else {
                        return false
                    }
                    
                    // Validate seat assignments
                    for person in arrangement.people {
                        guard let seat = arrangement.seatAssignments[person.id],
                              seat >= 0 && seat < arrangement.people.count else {
                            return false
                        }
                    }
                    
                    return true
                }
                
                await MainActor.run {
                    self.savedArrangements = validArrangements
                }
            }
        } catch {
            print("Error loading saved arrangements: \(error.localizedDescription)")
            NotificationCenter.default.post(
                name: Notification.Name("ShowErrorAlert"),
                object: nil,
                userInfo: ["message": "Failed to load saved arrangements"]
            )
        }
    }
    
    private func loadUsedNames() async {
        if let data = userDefaults.data(forKey: usedNamesKey),
           let decoded = try? JSONDecoder().decode(Set<String>.self, from: data) {
            await MainActor.run {
                self.usedNames = decoded
            }
        }
    }
    
    private func saveToUserDefaults() async {
        do {
            // Validate arrangements before saving
            let validArrangements = savedArrangements.filter { arrangement in
                !arrangement.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
                !arrangement.people.isEmpty
            }
            
            let encoded = try JSONEncoder().encode(validArrangements)
            userDefaults.set(encoded, forKey: arrangementsKey)
        } catch {
            print("Error saving arrangements: \(error.localizedDescription)")
            NotificationCenter.default.post(
                name: Notification.Name("ShowErrorAlert"),
                object: nil,
                userInfo: ["message": "Failed to save arrangements"]
            )
        }
    }
    
    private func saveUsedNames() {
        do {
            let encoded = try JSONEncoder().encode(usedNames)
            userDefaults.set(encoded, forKey: usedNamesKey)
        } catch {
            print("Error saving used names: \(error.localizedDescription)")
            // You might want to handle this error appropriately
        }
    }
    
    func resetArrangement() {
        // Save the current table state before resetting
        saveCurrentTableState()
        
        // Reset to a new arrangement
        currentArrangement = SeatingArrangement(
            title: String(format: NSLocalizedString("Table %d", comment: "Default table name"), tableCollection.currentTableId + 1),
            eventTitle: nil,
            people: [],
            tableShape: defaultTableShape
        )
        currentTableName = String(format: NSLocalizedString("Table %d", comment: "Default table name"), tableCollection.currentTableId + 1)
        isViewingHistory = false // Ensure we're not in viewing history mode
    }
    
    // Add this method to allow deleting a saved arrangement by index
    func deleteArrangement(at indexSet: IndexSet) {
        savedArrangements.remove(atOffsets: indexSet)
        Task {
            await saveToUserDefaults()
        }
    }

    // Public method to trigger statistics refresh
    func refreshStatistics() {
        // This is just a trigger to update the UI if needed
        // Total tables and people are computed properties now
        objectWillChange.send()
    }
    
    // Export all arrangements as CSV
    func exportToCSV() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        
        var csv = "Table Name,Date Created,Table Shape,Number of People,People\n"
        
        for arrangement in savedArrangements {
            let dateStr = dateFormatter.string(from: arrangement.date)
            let peopleStr = arrangement.people.map { $0.name }.joined(separator: "; ")
            
            csv += "\"\(arrangement.title)\",\"\(dateStr)\",\"\(arrangement.tableShape.rawValue.capitalized)\",\(arrangement.people.count),\"\(peopleStr)\"\n"
        }
        
        return csv
    }
    
    func resetToDefaults() {
        // Reset @AppStorage values
        _defaultTableShapeRaw = TableShape.round.rawValue
        lockByDefault = false
        hideSeatNumbersStorage = false
        hideTableNumberStorage = false
        UserDefaults.standard.removeObject(forKey: "userName")
        UserDefaults.standard.removeObject(forKey: "profileImageData")
        // Reset dark mode to light mode
        UserDefaults.standard.set(false, forKey: "isDarkMode")
        // Reset current arrangement properties that are affected by defaults
        currentArrangement.tableShape = .round
        // --- ADDED: Clear all tables and arrangements ---
        tableCollection.tables = [:]
        tableCollection.currentTableId = 0;
        tableCollection.maxTableId = 0;
        currentArrangement = SeatingArrangement(
            title: "New Arrangement",
            people: [],
            tableShape: .round
        )
        currentTableName = ""
        isViewingHistory = false
        saveTableCollection()
        UserDefaults.standard.set(true, forKey: "hasSeenTutorial")
        objectWillChange.send()
    }
    
    func toggleHideSeatNumbers() {
        hideSeatNumbers.toggle()
        hideSeatNumbersStorage = hideSeatNumbers
    }
    
    // Add method to update a person's color index
    func updatePersonColorIndex(personId: UUID, colorIndex: Int) {
        guard let index = currentArrangement.people.firstIndex(where: { $0.id == personId }) else {
            print("Person with ID \(personId) not found")
            return
        }
        currentArrangement.people[index].colorIndex = colorIndex
        // Also update in saved arrangements if this person is in a saved arrangement
        for i in 0..<savedArrangements.count {
            if let personIndex = savedArrangements[i].people.firstIndex(where: { $0.id == personId }) {
                savedArrangements[i].people[personIndex].colorIndex = colorIndex
            }
        }
    }
    
    // Add methods for multi-table navigation
    
    // Public method to navigate to another table based on direction
    func navigateToTable(direction: NavigationDirection) {
        // First save the current table state
        saveCurrentTableState()
        
        // Determine the next table ID based on direction (only left/right)
        var nextTableId = tableCollection.currentTableId
        switch direction {
        case .left:
            nextTableId = max(0, tableCollection.currentTableId - 1)
        case .right:
            nextTableId = tableCollection.currentTableId + 1
        }
        
        // Validate the next table ID
        guard nextTableId >= 0 else {
            NotificationCenter.default.post(
                name: Notification.Name("ShowErrorAlert"),
                object: nil,
                userInfo: ["message": "Invalid table navigation"]
            )
            return
        }
        
        // Load or create the next table
        if let existingTable = tableCollection.tables[nextTableId] {
            // Load existing table
            loadTable(existingTable, id: nextTableId)
        } else {
            // Create a new blank table with sequential numbering
            createNewTable(id: nextTableId)
        }
        
        // Update current table ID and max ID
        tableCollection.maxTableId = max(tableCollection.maxTableId, nextTableId)
        tableCollection.currentTableId = nextTableId
        
        // Save the table collection
        saveTableCollection()
        
        // Trigger haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
    
    // Save the current table state to the collection
    func saveCurrentTableState() {
        // Validate current arrangement before saving
        guard !currentArrangement.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            NotificationCenter.default.post(
                name: Notification.Name("ShowErrorAlert"),
                object: nil,
                userInfo: ["message": "Table title cannot be empty"]
            )
            return
        }
        
        var currentArrangement = self.currentArrangement
        currentArrangement.title = currentTableName
        // Do NOT overwrite eventTitle here
        tableCollection.tables[tableCollection.currentTableId] = currentArrangement
    }
    
    // Load an existing table
    private func loadTable(_ arrangement: SeatingArrangement, id: Int) {
        self.currentArrangement = arrangement
        self.currentTableName = arrangement.title
    }
    
    // Save all tables to user defaults
    func saveTableCollection() {
        do {
            // Ensure we have valid data to save
            if tableCollection.tables.isEmpty {
                // If no tables, create a default one
                createNewTable(id: 0)
            }
            
            // Ensure current table is saved and only update its name
            if var currentTable = tableCollection.tables[tableCollection.currentTableId] {
                // Only update the current table's title
                if !currentTableName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    currentTable.title = currentTableName
                } else {
                    // If no name, use a default like "Table X"
                    currentTable.title = "Table \(tableCollection.currentTableId + 1)"
                }
                tableCollection.tables[tableCollection.currentTableId] = currentTable
            }
            
            let encoded = try JSONEncoder().encode(tableCollection)
            tableCollectionData = encoded
            
            // Notify observers of the change
            objectWillChange.send()
        } catch {
            print("Error saving table collection: \(error.localizedDescription)")
            NotificationCenter.default.post(
                name: Notification.Name("ShowErrorAlert"),
                object: nil,
                userInfo: ["message": "Failed to save table data"]
            )
        }
    }
    
    // Create a new blank table
    private func createNewTable(id: Int) {
        // Create a new blank arrangement
        let newArrangement = SeatingArrangement(
            id: UUID(),
            title: "Table \(id + 1)",  // Always use sequential numbering
            eventTitle: nil,
            date: Date(),
            people: [],
            tableShape: defaultTableShape,
            seatAssignments: [:]
        )
        // Set as current
        self.currentArrangement = newArrangement
        self.currentTableName = newArrangement.title
        // Save this new table to the collection
        tableCollection.tables[id] = newArrangement
    }
    
    // Load all tables from user defaults
    private func loadTableCollection() {
        guard let data = tableCollectionData else {
            // Initialize with a default table if no data exists
            createNewTable(id: 0)
            return
        }
        
        do {
            let decoded = try JSONDecoder().decode(TableCollection.self, from: data)
            
            // Validate the decoded data
            guard decoded.currentTableId >= 0,
                  decoded.maxTableId >= decoded.currentTableId else {
                // If validation fails, create a new table collection
                self.tableCollection = TableCollection()
                createNewTable(id: 0)
                return
            }
            
            self.tableCollection = decoded
            
            // Load the current table
            if let currentTable = tableCollection.tables[tableCollection.currentTableId] {
                self.currentArrangement = currentTable
                self.currentTableName = currentTable.title
            } else {
                // If current table doesn't exist, create a new one
                createNewTable(id: tableCollection.currentTableId)
            }
            
            // Ensure we have at least one table
            if tableCollection.tables.isEmpty {
                createNewTable(id: 0)
            }
            
            // Notify observers of the change
            objectWillChange.send()
        } catch {
            print("Error loading table collection: \(error.localizedDescription)")
            NotificationCenter.default.post(
                name: Notification.Name("ShowErrorAlert"),
                object: nil,
                userInfo: ["message": "Failed to load table data"]
            )
            // Initialize with a default table if loading fails
            createNewTable(id: 0)
        }
    }
    
    // Export all tables with a summary - updated format
    func exportAllTables() -> String {
        // Save current table first
        saveCurrentTableState()
        
        // Use eventTitle for the event name
        let eventTitle = currentArrangement.eventTitle ?? ""
        let (formattedTitle, eventEmoji) = UIHelpers.formatEventTitle(eventTitle)
        
        // Filter to only include tables with people
        let nonEmptyTables = tableCollection.tables
            .filter { !$0.value.people.isEmpty }
            .sorted { $0.key < $1.key }
        
        // Renumber tables sequentially for display
        let displayTables = nonEmptyTables.enumerated().map { index, table in
            return (id: index + 1, originalId: table.key, table: table.value)
        }
        
        // Start with Event as the first line
        var summary = eventTitle.isEmpty ? "" : "Event: \(eventEmoji) \(formattedTitle)\n"
        
        // Add total counts
        let totalTables = displayTables.count
        let totalPeople = nonEmptyTables.reduce(0) { $0 + $1.value.people.count }
        summary += "People: \(totalPeople)\n"
        summary += "Tables: \(totalTables)\n\n"
        
        // Add each table with its people (no emoji, just table name)
        for (displayId, _, table) in displayTables {
            let tableName = table.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Table \(displayId)" : table.title
            let peopleCount = table.people.count
            let peopleText = peopleCount == 1 ? "1 person" : "\(peopleCount) people"
            summary += "▸ \(tableName) (\(peopleText))\n"
            
            // Sort people by seat number
            let sortedPeople = table.people.sorted {
                let seatA = table.seatAssignments[$0.id] ?? 0
                let seatB = table.seatAssignments[$1.id] ?? 0
                return seatA < seatB
            }
            
            // Add people with seat numbers
            for person in sortedPeople {
                if let seatNumber = table.seatAssignments[person.id] {
                    summary += "  \(seatNumber + 1). \(person.name)\(person.isLocked ? " 🔒" : "")\n"
                }
            }
            
            // Add a blank line between tables
            summary += "\n"
        }
        
        // Add app info and App Store link
        summary += "Created with Seat Maker App\n\n"
        summary += "📱 Download Seat Maker: https://apps.apple.com/us/app/seat-maker/id6748284141"
        
        return summary
    }

    /// Export a single table's details in the same clean format as exportAllTables
    /// - Parameter table: The `SeatingArrangement` to export
    /// - Returns: A formatted string suitable for sharing in Messages or any share target
    func exportSingleTable(_ table: SeatingArrangement) -> String {
        // Use event title if available
        let eventTitle = table.eventTitle ?? currentArrangement.eventTitle ?? ""
        let (formattedTitle, eventEmoji) = UIHelpers.formatEventTitle(eventTitle)

        var summary = eventTitle.isEmpty ? "" : "Event: \(eventEmoji) \(formattedTitle)\n"

        // Totals (for a single table)
        let totalPeople = table.people.count
        summary += "People: \(totalPeople)\n"
        summary += "Tables: 1\n\n"

        // Table header (respect custom table name when present)
        let tableName = table.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Table 1" : table.title
        let peopleText = totalPeople == 1 ? "1 person" : "\(totalPeople) people"
        summary += "▸ \(tableName) (\(peopleText))\n"

        // Sort by seat number for consistent display
        let sortedPeople = table.people.sorted {
            let seatA = table.seatAssignments[$0.id] ?? 0
            let seatB = table.seatAssignments[$1.id] ?? 0
            return seatA < seatB
        }

        for person in sortedPeople {
            if let seatNumber = table.seatAssignments[person.id] {
                summary += "  \(seatNumber + 1). \(person.name)\(person.isLocked ? " 🔒" : "")\n"
            }
        }

        summary += "\nCreated with Seat Maker App\n\n"
        summary += "📱 Download Seat Maker: https://apps.apple.com/us/app/seat-maker/id6748284141"

        return summary
    }
    
    // Helper function to get emoji and formatted title
    private func getEventDetails() -> (String, String) {
        let eventTitle = currentArrangement.eventTitle ?? ""
        return UIHelpers.formatEventTitle(eventTitle)
    }
    
    // Refresh saved arrangements from storage
    func refreshSavedArrangements() {
        // Force refresh from UserDefaults
        if let savedData = UserDefaults.standard.data(forKey: arrangementsKey) {
            do {
                let decodedArrangements = try JSONDecoder().decode([SeatingArrangement].self, from: savedData)
                self.savedArrangements = decodedArrangements.sorted(by: { $0.date > $1.date })
            } catch {
                print("Error refreshing saved arrangements: \(error)")
            }
        }
        
        // Make sure tables are loaded correctly
        loadTableCollection()
    }
    

    
    /// Remove all people from the current table (does not affect other tables or history)
    func removeAllPeopleFromCurrentTable() {
        currentArrangement.people.removeAll()
        currentArrangement.seatAssignments.removeAll()
    }
    
    func shareCurrentTable() async {
        do {
            let sharedTable = try await sharingService.shareTable(currentArrangement)
            currentSharedTable = sharedTable
            sharingService.shareTableLink(sharedTable)
        } catch {
            print("Error sharing table: \(error)")
        }
    }
    
    func loadSharedTable(id: String) async {
        do {
            let sharedTable = try await sharingService.fetchSharedTable(id: id)
            if !sharedTable.isExpired {
                currentArrangement = sharedTable.arrangement
                currentTableName = sharedTable.arrangement.title
                isViewingHistory = true
            }
        } catch {
            print("Error loading shared table: \(error)")
        }
    }
    
    // Add this method to export all tables as a detailed CSV
    func exportAllTablesToCSV() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        var csv = "Table Name,Date Created,Table Shape,Number of People,Person Name,Seat Number,Locked\n"
        let tables = tableCollection.tables.sorted { $0.key < $1.key }
        for (_, table) in tables {
            let dateStr = dateFormatter.string(from: table.date)
            let peopleCount = table.people.count
            if peopleCount == 0 {
                csv += "\"\(table.title)\",\"\(dateStr)\",\"\(table.tableShape.rawValue.capitalized)\",0,,,\n"
            } else {
                let sortedPeople = table.people.sorted {
                    let seatA = table.seatAssignments[$0.id] ?? 0
                    let seatB = table.seatAssignments[$1.id] ?? 0
                    return seatA < seatB
                }
                for person in sortedPeople {
                    let seatNumber = table.seatAssignments[person.id].map { String($0 + 1) } ?? ""
                    let locked = person.isLocked ? "Yes" : "No"
                    csv += "\"\(table.title)\",\"\(dateStr)\",\"\(table.tableShape.rawValue.capitalized)\",\(peopleCount),\"\(person.name)\",\(seatNumber),\(locked)\n"
                }
            }
        }
        return csv
    }
    
    // Add this method to allow changing the app icon
    @MainActor
    func changeAppIcon(to iconName: String?) {
        guard UIApplication.shared.supportsAlternateIcons else { return }
        let name = (iconName == "Default") ? nil : iconName
        UIApplication.shared.setAlternateIconName(name) { error in
            if let error = error {
                print("Failed to change app icon: \(error.localizedDescription)")
            } else {
                print("App icon changed to \(iconName ?? "Default")")
            }
        }
    }
    
    // Add method to reset state after sharing
    func resetAfterSharing() {
        isViewingHistory = false
        currentArrangement = SeatingArrangement(tableShape: defaultTableShape)
        currentTableName = ""
        contactsCache = nil
        lastContactsFetch = nil
    }
    
    // Add function to delete current table
    func deleteCurrentTable() {
        // Remove the current table
        tableCollection.tables.removeValue(forKey: tableCollection.currentTableId)
        
        // If we deleted the last table, create a new one
        if tableCollection.tables.isEmpty {
            createNewTable(id: 0)
            tableCollection.currentTableId = 0
            tableCollection.maxTableId = 0
        } else {
            // Find the next available table ID
            let nextId = tableCollection.tables.keys.sorted().first ?? 0
            tableCollection.currentTableId = nextId
            if let nextTable = tableCollection.tables[nextId] {
                loadTable(nextTable, id: nextId)
            }
        }
        
        // Save the updated collection
        saveTableCollection()
    }

    // MARK: - Table Manager Helpers
    /// Create a new blank table at the next available id and switch to it. Returns the new table id.
    @discardableResult
    func createAndSwitchToNewTable() -> Int {
        saveCurrentTableState()
        let nextId: Int
        if tableCollection.tables.isEmpty {
            nextId = 0
        } else {
            nextId = (tableCollection.tables.keys.max() ?? -1) + 1
        }
        let newArrangement = SeatingArrangement(
            id: UUID(),
            title: "Table \(nextId + 1)",
            eventTitle: nil,
            date: Date(),
            people: [],
            tableShape: defaultTableShape,
            seatAssignments: [:]
        )
        tableCollection.tables[nextId] = newArrangement
        tableCollection.currentTableId = nextId
        tableCollection.maxTableId = max(tableCollection.maxTableId, nextId)
        currentArrangement = newArrangement
        currentTableName = newArrangement.title
        saveTableCollection()
        return nextId
    }

    /// Duplicate an existing table id, create a new id, and return the new id.
    @discardableResult
    func duplicateTable(id: Int) -> Int? {
        guard let existing = tableCollection.tables[id] else { return nil }
        saveCurrentTableState()
        let nextId = (tableCollection.tables.keys.max() ?? -1) + 1
        var copy = existing
        copy.id = UUID()
        // Prefer sequential default title
        copy.title = "Table \(nextId + 1)"
        tableCollection.tables[nextId] = copy
        tableCollection.maxTableId = max(tableCollection.maxTableId, nextId)
        saveTableCollection()
        return nextId
    }

    /// Delete multiple tables by ids. Adjusts current table if needed.
    func deleteTables(ids: [Int]) {
        guard !ids.isEmpty else { return }
        saveCurrentTableState()
        for id in ids { tableCollection.tables.removeValue(forKey: id) }
        if tableCollection.tables.isEmpty {
            // Recreate a default table
            createNewTable(id: 0)
            tableCollection.currentTableId = 0
            tableCollection.maxTableId = 0
        } else if ids.contains(tableCollection.currentTableId) {
            // Switch to the lowest available id
            if let firstId = tableCollection.tables.keys.sorted().first,
               let table = tableCollection.tables[firstId] {
                loadTable(table, id: firstId)
                tableCollection.currentTableId = firstId
            }
        }
        saveTableCollection()
    }

    /// Rename a table title and save.
    func renameTable(id: Int, to newName: String) {
        let trimmed = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        if var table = tableCollection.tables[id] {
            table.title = trimmed
            tableCollection.tables[id] = table
            if id == tableCollection.currentTableId {
                currentTableName = trimmed
                currentArrangement.title = trimmed
            }
            saveTableCollection()
        }
    }

    /// Switch current editor to a specific table id (if exists) and save.
    func switchToTable(id: Int) {
        saveCurrentTableState()
        if let table = tableCollection.tables[id] {
            loadTable(table, id: id)
            tableCollection.currentTableId = id
            saveTableCollection()
        }
    }

    /// Reorder tables by providing a new ordered list of existing ids. Reindexes to 0..n-1.
    func reorderTables(newOrder: [Int]) {
        // Validate that all ids exist
        let existingIds = Set(tableCollection.tables.keys)
        guard Set(newOrder) == existingIds else { return }

        // Remember current table's old id
        let oldCurrentId = tableCollection.currentTableId

        // Build new mapping
        var newTables: [Int: SeatingArrangement] = [:]
        for (newIndex, oldId) in newOrder.enumerated() {
            if let table = tableCollection.tables[oldId] {
                newTables[newIndex] = table
            }
        }

        // Update collection
        tableCollection.tables = newTables
        tableCollection.maxTableId = max(0, newOrder.count - 1)

        // Update current id to new index of the old current table
        if let newIndex = newOrder.firstIndex(of: oldCurrentId) {
            tableCollection.currentTableId = newIndex
            if let current = newTables[newIndex] {
                loadTable(current, id: newIndex)
            }
        } else if let first = newTables.keys.sorted().first, let firstTable = newTables[first] {
            tableCollection.currentTableId = first
            loadTable(firstTable, id: first)
        }

        saveTableCollection()
    }
}
