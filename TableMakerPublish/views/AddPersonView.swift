import SwiftUI
import Contacts
import UniformTypeIdentifiers

// Include the ContactsListView directly in this file to avoid project reference issues
struct ContactsListView: View {
    let contacts: [String]
    var searchText: String = ""
    let onSelect: ([String]) -> Void
    var onSmartSeating: (([String]) -> Void)? = nil
    @State private var localSearchText: String = ""
    @State private var selectedContacts: Set<String> = []
    @State private var isMultiSelectMode: Bool = false
    @Environment(\.dismiss) private var dismiss
    @State private var showingError = false
    @State private var errorMessage = ""
    
    var filteredContacts: [String] {
        if localSearchText.isEmpty {
            return contacts
        }
        return contacts.filter { $0.lowercased().contains(localSearchText.lowercased()) }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search field with improved styling
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    TextField("Search contacts", text: $localSearchText)
                        .textFieldStyle(PlainTextFieldStyle())
                }
                .padding(12)
                .background(Color(.systemGray6))
                .cornerRadius(20)
                .padding(.horizontal)
                .padding(.top, 8)
                
                // Selected contacts display
                if isMultiSelectMode && !selectedContacts.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(Array(selectedContacts), id: \.self) { contact in
                                HStack(spacing: 4) {
                                    Text(contact)
                                        .font(.system(size: 14))
                                    Button(action: {
                                        selectedContacts.remove(contact)
                                    }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(.gray)
                                            .font(.system(size: 14))
                                    }
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(15)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                    }
                    .background(Color(.systemBackground))
                }
                
                if filteredContacts.isEmpty {
                    VStack {
                        Spacer()
                        Text("No contacts found")
                            .foregroundColor(.secondary)
                            .onAppear {
                                // If nothing is available, prompt user to grant access via settings
                                NotificationCenter.default.post(name: Notification.Name("ShowContactsDeniedAlert"), object: nil)
                            }
                        Spacer()
                    }
                } else {
                    List {
                        ForEach(Array(filteredContacts.enumerated()), id: \.offset) { _, contact in
                            Button(action: {
                                if isMultiSelectMode {
                                    if selectedContacts.contains(contact) {
                                        selectedContacts.remove(contact)
                                    } else {
                                        selectedContacts.insert(contact)
                                    }
                                } else {
                                    onSelect([contact])
                                }
                            }) {
                                HStack {
                                    Text(contact)
                                        .foregroundColor(.primary)
                                        .dynamicTypeSize(.xSmall ... .accessibility5)
                                        .minimumScaleFactor(0.7)
                                    Spacer()
                                    if isMultiSelectMode {
                                        Image(systemName: selectedContacts.contains(contact) ? "checkmark.circle.fill" : "circle")
                                            .foregroundColor(selectedContacts.contains(contact) ? .blue : .gray)
                                    }
                                }
                                .padding(.vertical, 6)
                            }
                            .accessibilityLabel(contact)
                            .accessibilityHint("Select to add \(contact) to the table")
                        }
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle("Select Contact")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    if isMultiSelectMode {
                        if let onSmartSeating = onSmartSeating {
                            Button("Smart Seating") {
                                if !selectedContacts.isEmpty {
                                    onSmartSeating(Array(selectedContacts))
                                }
                            }
                            .disabled(selectedContacts.isEmpty)
                        }
                        Button("Done") {
                            if !selectedContacts.isEmpty {
                                onSelect(Array(selectedContacts))
                            }
                        }
                        .disabled(selectedContacts.isEmpty)
                    } else {
                        Button(action: {
                            isMultiSelectMode = true
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "checkmark.circle")
                                Text("Select Multiple")
                            }
                        }
                    }
                }
            }
            .onAppear {
                localSearchText = searchText
                // Check if we have any contacts
                if contacts.isEmpty {
                    errorMessage = "No contacts available. Please check your contacts access settings."
                    showingError = true
                }
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text(errorMessage)
            }
        }
        .accessibilityLabel("Select Contact")
        .accessibilityHint("Search for and select contacts to add to the table")
    }
}

struct AddPersonView: View {
    @ObservedObject var viewModel: SeatingViewModel
    @Binding var isPresented: Bool
    @State private var newPersonName = ""
    @State private var showingContactsPicker = false
    @State private var showingImportFromList = false
    @State private var importStartIntent: ImportSourceIntent? = nil
    @State private var showImportDialog = false
    @State private var showingDuplicateAlert = false
    @State private var showingPrePermission = false
    @State private var permissionDeniedContacts = false
    @FocusState private var isFocused: Bool
    
    var body: some View {
        NavigationView {
            ZStack(alignment: .bottom) {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        // Name input with suggestions (top)
                        VStack(alignment: .leading, spacing: 8) {
                            TextField(NSLocalizedString("Name", comment: "Placeholder for name input"), text: $newPersonName)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .textInputAutocapitalization(.words)
                                .focused($isFocused)
                                .onChange(of: newPersonName) { newValue in
                                    viewModel.getSuggestedNames(for: newValue)
                                }

                            // Name suggestions
                            if !newPersonName.isEmpty && !viewModel.suggestedNames.isEmpty {
                                ScrollView {
                                    VStack(alignment: .leading) {
                                        ForEach(viewModel.suggestedNames, id: \.self) { name in
                                            Button(action: { newPersonName = name }) {
                                                Text(name)
                                                    .padding(.horizontal, 12)
                                                    .padding(.vertical, 12)
                                                    .frame(maxWidth: .infinity, alignment: .leading)
                                                    .background(Color.blue.opacity(0.1))
                                                    .cornerRadius(8)
                                            }
                                            .padding(.vertical, 2)
                                        }
                                    }
                                    .padding(.vertical, 4)
                                }
                                .frame(maxHeight: UIScreen.main.bounds.height * 0.25)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .topLeading)
                    .padding([.horizontal, .top])
                    .padding(.bottom, 180) // keep above bottom controls
                }

                // Bottom-anchored import actions
                VStack(spacing: 10) {
                    // Import from contacts (now first)
                    Button(action: {
                        CNContactStore().requestAccess(for: .contacts) { granted, _ in
                            DispatchQueue.main.async {
                                if granted {
                                    showingContactsPicker = true
                                    viewModel.fetchContacts()
                                } else {
                                    NotificationCenter.default.post(name: Notification.Name("ShowContactsDeniedAlert"), object: nil)
                                    permissionDeniedContacts = true
                                }
                            }
                        }
                    }) {
                        HStack {
                            Image(systemName: "person.crop.circle.badge.plus")
                            Text(NSLocalizedString("Import from Contacts", comment: "Button to import from contacts"))
                                .fontWeight(.semibold)
                        }
                        .font(.title3)
                        .foregroundColor(.blue)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 16)
                        .frame(minHeight: 56)
                        .frame(maxWidth: 320)
                        .background(Color.blue.opacity(0.12))
                        .cornerRadius(16)
                    }
                    
                    // Import from List (present as full-screen cover over this sheet)
                    Button(action: {
                        // Present Import flow immediately without dismissing this sheet
                        importStartIntent = .text
                    }) {
                        HStack {
                            Image(systemName: "text.badge.plus")
                            Text("Import from List")
                                .fontWeight(.semibold)
                        }
                        .font(.title3)
                        .foregroundColor(.blue)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 16)
                        .frame(minHeight: 56)
                        .frame(maxWidth: 320)
                        .background(Color.blue.opacity(0.12))
                        .cornerRadius(16)
                    }
                    .padding(.top, 8)

                    if viewModel.isLoadingContacts {
                        ProgressView()
                            .scaleEffect(1.2)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 2) // ~10px lower toward the bottom
                .background(.ultraThinMaterial)
                .ignoresSafeArea(.keyboard, edges: .bottom)
            }
            .navigationTitle(NSLocalizedString("Add Person", comment: "Navigation title for add person view"))
            .navigationBarItems(
                leading: Button(NSLocalizedString("Cancel", comment: "Cancel button")) {
                    isPresented = false
                }.tint(.blue),
                trailing: Button(NSLocalizedString("Add", comment: "Add button")) {
                    addPerson()
                }.tint(.blue)
                .disabled(newPersonName.isEmpty)
            )
            // Contacts picker presented as full screen to avoid nested-sheet limitation
            .fullScreenCover(isPresented: $showingContactsPicker, onDismiss: {
                viewModel.isLoadingContacts = false
                isPresented = false
            }) {
                ContactsListView(
                    contacts: viewModel.contacts,
                    searchText: newPersonName,
                    onSelect: { names in
                        Task { @MainActor in
                            for name in names {
                                if !name.isEmpty && !viewModel.currentArrangement.people.contains(where: { $0.name.lowercased() == name.lowercased() }) {
                                    viewModel.addPerson(name: name)
                                }
                            }
                            showingContactsPicker = false
                            isPresented = false
                            // Ensure main screen shows the table after importing contacts
                            NotificationCenter.default.post(name: Notification.Name("HideEffortlessScreen"), object: nil)
                        }
                    },
                    onSmartSeating: { names in
                        Task { @MainActor in
                            viewModel.smartCreateTables(from: names)
                            showingContactsPicker = false
                            isPresented = false
                            NotificationCenter.default.post(name: Notification.Name("HideEffortlessScreen"), object: nil)
                        }
                    }
                )
            }
            // Import from list flow presented over this sheet to avoid nested-sheet conflicts
            .fullScreenCover(
                isPresented: Binding(
                    get: { importStartIntent != nil },
                    set: { if !$0 { importStartIntent = nil } }
                ),
                onDismiss: { importStartIntent = nil }
            ) {
                ImportFromListView(
                    viewModel: viewModel,
                    isPresented: Binding(
                        get: { importStartIntent != nil },
                        set: { if !$0 { importStartIntent = nil } }
                    ),
                    startIntent: importStartIntent
                )
            }
            .alert(NSLocalizedString("Duplicate Name", comment: "Alert title for duplicate name"), isPresented: $showingDuplicateAlert) {
                Button(NSLocalizedString("OK", comment: "OK button"), role: .cancel) { }
            } message: {
                Text(NSLocalizedString("A person with this name already exists. Please choose a different name.", comment: "Duplicate name alert message"))
            }
            // Alert for denied permission
            .alert(NSLocalizedString("Contacts Access Needed", comment: "Alert title for contacts permission denied"), isPresented: $permissionDeniedContacts) {
                Button(NSLocalizedString("Open Settings", comment: "Open Settings button")) {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                Button(NSLocalizedString("Cancel", comment: "Cancel button"), role: .cancel) { }
            } message: {
                Text(NSLocalizedString("To import contacts, please enable contacts access in Settings > Privacy > Contacts.", comment: "Contacts permission denied message"))
            }
            .onAppear {
                // Auto-focus the text field when view appears
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    isFocused = true
                }
                // Register NotificationCenter observer for denied contacts
                NotificationCenter.default.addObserver(forName: Notification.Name("ShowContactsDeniedAlert"), object: nil, queue: .main) { _ in
                    self.permissionDeniedContacts = true
                }
            }
            .onDisappear {
                // Reset state when view disappears
                viewModel.isLoadingContacts = false
                viewModel.contacts = []
                // Remove NotificationCenter observer
                NotificationCenter.default.removeObserver(self, name: Notification.Name("ShowContactsDeniedAlert"), object: nil)
            }
        }
    }
    
    private func addPerson() {
        guard !newPersonName.isEmpty else { return }
        // Only prevent duplicates within the current table
        let currentTableNames = Set(viewModel.currentArrangement.people.map { $0.name.lowercased() })
        if currentTableNames.contains(newPersonName.lowercased()) {
            showingDuplicateAlert = true
            return
        }
        // Enforce 20-person limit (same as ViewModel guard)
        if viewModel.currentArrangement.people.count < 20 {
            viewModel.addPerson(name: newPersonName)
            DispatchQueue.main.async {
                isPresented = false
                // Ensure main screen shows the table after adding a person
                NotificationCenter.default.post(name: Notification.Name("HideEffortlessScreen"), object: nil)
            }
        }
    }
}

// Visually appealing pre-permission modal
struct PrePermissionView: View {
    let title: String
    let message: String
    let icon: String
    let onContinue: () -> Void
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: icon)
                .resizable()
                .scaledToFit()
                .frame(width: 64, height: 64)
                .foregroundColor(.blue)
            Text(title)
                .font(.title2).bold()
                .multilineTextAlignment(.center)
            Text(message)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            Spacer()
            Button(action: onContinue) {
                Text(NSLocalizedString("Continue", comment: "Continue button for pre-permission"))
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(14)
            }
            .padding(.horizontal)
        }
        .padding()
    }
}

// MARK: - Import From List Flow (inline to avoid project reference issues)

// Data Models for Import Flow
struct ImportedPersonData: Identifiable, Hashable {
    let id = UUID()
    var name: String
    var group: String?
    var tags: [String] = []
    var vip: Bool = false
    var keepApartTags: [String] = []
    var keepWithNames: [String] = []
    var dietary: [String] = []
    var notes: String? = nil
    var email: String? = nil
    var phone: String? = nil
}

enum ImportAssignmentMode: String, CaseIterable, Identifiable {
    case fillInOrder = "Fill in order"
    case roundRobin = "Round-robin"
    var id: String { rawValue }
}

enum ImportSeatLabels: String, CaseIterable, Identifiable {
    case numeric = "1…N"
    case alphabetic = "A…N"
    var id: String { rawValue }
}

enum ImportGroupConstraint: String, CaseIterable, Identifiable {
    case none = "None"
    case keepTogether = "Keep groups together"
    case spreadAcross = "Spread groups across tables"
    var id: String { rawValue }
}

enum ImportShapeRotationMode: String, CaseIterable, Identifiable {
    case cycle = "Cycle shapes"
    case staticOne = "Use one shape for all"
    var id: String { rawValue }
}

struct ImportSeatingSettings {
    var peoplePerTable: Int = 2
    var selectedShapes: [TableShape] = [.round]
    var rotationMode: ImportShapeRotationMode = .staticOne
    var manualTableCountEnabled: Bool = false
    var manualTableCount: Int = 0
    var seatLabels: ImportSeatLabels = .numeric
    var groupConstraint: ImportGroupConstraint = .none
    var assignmentMode: ImportAssignmentMode = .roundRobin
}

struct FieldMapping: Hashable {
    var headerNames: [String] = []
    var hasHeaders: Bool = true
    var mapping: [String: String] = [:]
    var autoCleanNames: Bool = true
    var createTagsFromExtras: Bool = true
}

enum ImportSourceIntent {
    case csv
    case google
    case text
}

struct ImportFromListView: View {
    @ObservedObject var viewModel: SeatingViewModel
    @Binding var isPresented: Bool
    var startIntent: ImportSourceIntent? = nil

    @State private var step: Int = 1
    @State private var settings = ImportSeatingSettings()
    @State private var peoplePerTableText: String = ""

    @State private var showFileImporter = false
    @State private var googleSheetURLString: String = ""
    @State private var pastedText: String = ""
    @State private var sourceError: String? = nil
    @State private var isProcessingSource: Bool = false

    @State private var rawRows: [[String]] = []
    @State private var mapping = FieldMapping()
    @State private var mappedPeople: [ImportedPersonData] = []

    @State private var previewAssignments: [[ImportedPersonData]] = []
    @State private var computingPreview: Bool = false
    @State private var showSuccess: Bool = false
    @State private var hasProcessedSource: Bool = false

    var body: some View {
        NavigationStack {
            ZStack {
                if step == 1 {
                    step1Settings
                        .transition(.opacity)
                } else if step == 2 {
                    step2Source
                        .transition(.opacity)
                } else if step == 3 {
                    // Mapping UI removed; keep placeholder to preserve state machine
                    step3Mapping
                        .transition(.opacity)
                } else if step == 4 {
                    step4Preview
                        .transition(.opacity)
                }
            }
            .animation(.default, value: step)
            .navigationTitle(navigationTitleForStep(step))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Back") {
                        // Always take user back to Seating settings (Step 1) instead of Choose a Source/blank preview
                        if step > 1 {
                            step = 1
                        } else {
                            isPresented = false
                        }
                    }
                }
            }
            .alert(isPresented: Binding(get: { sourceError != nil }, set: { if !$0 { sourceError = nil } })) {
                Alert(title: Text("Import Error"), message: Text(sourceError ?? ""), dismissButton: .default(Text("OK")))
            }
        }
        .onChange(of: settings.peoplePerTable) { _ in if step == 4 { recomputePreview() } }
        .onChange(of: settings.manualTableCountEnabled) { _ in if step == 4 { recomputePreview() } }
        .onChange(of: settings.manualTableCount) { _ in if step == 4 { recomputePreview() } }
        .onChange(of: settings.assignmentMode) { _ in if step == 4 { recomputePreview() } }
        .onChange(of: settings.groupConstraint) { _ in if step == 4 { recomputePreview() } }
        .onChange(of: settings.selectedShapes) { _ in if step == 4 { recomputePreview() } }
        .onAppear {
            // Start at Choose Source for a clearer flow
            withAnimation(.easeInOut(duration: 0.25)) { step = 2 }
            peoplePerTableText = String(settings.peoplePerTable)
        }
    }

    private var step1Settings: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                VStack(spacing: 20) {

                    // Card 1 – People per table
                    settingsCard(title: "People per table", subtitle: "How many guests per table") {
                        Text("Guests will be distributed across tables based on this number. You can adjust later.")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                            .padding(.bottom, 4)
                        HStack(spacing: 8) {
                            let buttonSize: CGFloat = 36
                            RepeatButton(
                                onTap: {
                                    let newVal = max(1, settings.peoplePerTable - 1)
                                    settings.peoplePerTable = newVal
                                    peoplePerTableText = String(newVal)
                                },
                                onRepeat: {
                                    let newVal = max(1, settings.peoplePerTable - 1)
                                    settings.peoplePerTable = newVal
                                    peoplePerTableText = String(newVal)
                                }
                            ) {
                                Image(systemName: "minus")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(width: buttonSize, height: buttonSize)
                                    .background(RoundedRectangle(cornerRadius: 14).fill(Color.blue))
                            }
                            .accessibilityLabel("Decrease people per table")

                            Spacer(minLength: 0)
                            Text("\(settings.peoplePerTable)")
                                .font(.system(size: 40, weight: .bold, design: .rounded))
                                .frame(minWidth: 80)
                                .accessibilityLabel("People per table value")
                            Spacer(minLength: 0)

                            RepeatButton(
                                onTap: {
                                    let maxAllowed = max(1, min(20, mappedPeople.isEmpty ? 20 : mappedPeople.count))
                                    let newVal = min(maxAllowed, settings.peoplePerTable + 1)
                                    settings.peoplePerTable = newVal
                                    peoplePerTableText = String(newVal)
                                },
                                onRepeat: {
                                    let maxAllowed = max(1, min(20, mappedPeople.isEmpty ? 20 : mappedPeople.count))
                                    let newVal = min(maxAllowed, settings.peoplePerTable + 1)
                                    settings.peoplePerTable = newVal
                                    peoplePerTableText = String(newVal)
                                }
                            ) {
                                Image(systemName: "plus")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(width: buttonSize, height: buttonSize)
                                    .background(RoundedRectangle(cornerRadius: 14).fill(Color.blue))
                            }
                            .accessibilityLabel("Increase people per table")
                        }
                        .padding(.vertical, 6)
                    }

                    // Card 2 – Table shape
                    settingsCard(title: "Table shape", subtitle: "Choose the shape of your tables") {
                        HStack(spacing: 14) {
                            shapeChoice(isSelected: settings.selectedShapes.first == .round, label: "Round", shapeSize: CGSize(width: 56, height: 56)) {
                                Circle().inset(by: 4)
                            } tap: {
                                settings.selectedShapes = [.round]
                            }
                            shapeChoice(isSelected: settings.selectedShapes.first == .square, label: "Square", shapeSize: CGSize(width: 56, height: 56)) {
                                Rectangle().inset(by: 6)
                            } tap: {
                                settings.selectedShapes = [.square]
                            }
                            shapeChoice(isSelected: settings.selectedShapes.first == .rectangle, label: "Rectangle", shapeSize: CGSize(width: 88, height: 48)) {
                                RoundedRectangle(cornerRadius: 10).inset(by: 6)
                            } tap: {
                                settings.selectedShapes = [.rectangle]
                            }
                        }
                        .padding(.top, 4)
                    }

                    // Card 3 – Table count
                    settingsCard(title: "Table count", subtitle: "") {
                        VStack(alignment: .leading, spacing: 12) {
                            Toggle("Set manually", isOn: $settings.manualTableCountEnabled)
                                .tint(.accentColor)
                            if settings.manualTableCountEnabled {
                                HStack(spacing: 8) {
                                    let buttonSize: CGFloat = 36
                                    RepeatButton(
                                        onTap: { settings.manualTableCount = max(1, settings.manualTableCount - 1) },
                                        onRepeat: { settings.manualTableCount = max(1, settings.manualTableCount - 1) }
                                    ) {
                                        Image(systemName: "minus")
                                            .font(.system(size: 20, weight: .bold))
                                            .foregroundColor(.white)
                                            .frame(width: buttonSize, height: buttonSize)
                                            .background(RoundedRectangle(cornerRadius: 14).fill(Color.blue))
                                    }
                                    .accessibilityLabel("Decrease table count")

                                    Spacer(minLength: 0)
                                    Text("\(max(1, settings.manualTableCount))")
                                        .font(.system(size: 36, weight: .bold, design: .rounded))
                                        .frame(minWidth: 80)
                                    Spacer(minLength: 0)

                                    RepeatButton(
                                        onTap: { settings.manualTableCount = min(200, settings.manualTableCount + 1) },
                                        onRepeat: { settings.manualTableCount = min(200, settings.manualTableCount + 1) }
                                    ) {
                                        Image(systemName: "plus")
                                            .font(.system(size: 20, weight: .bold))
                                            .foregroundColor(.white)
                                            .frame(width: buttonSize, height: buttonSize)
                                            .background(RoundedRectangle(cornerRadius: 14).fill(Color.blue))
                                    }
                                    .accessibilityLabel("Increase table count")
                                }
                                .padding(.top, 2)
                            } else {
                                HStack {
                                    Image(systemName: "info.circle").foregroundColor(.secondary)
                                    Text("Auto‑calculate based on people per table")
                                        .foregroundColor(.secondary)
                                        .font(.subheadline)
                                    Spacer()
                                }
                            }
                        }
                    }

                    Spacer(minLength: 80)
                }
                .padding(.horizontal)
                .padding(.top, 0)
                .toolbar {
                    ToolbarItemGroup(placement: .keyboard) {
                        Spacer()
                        Button("Done") { UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil) }
                    }
                }
            }

            // Sticky bottom bar
            VStack(spacing: 0) {
                Divider()
                Button(action: { continueTapped() }) {
                    Text("Next")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(RoundedRectangle(cornerRadius: 16).fill(Color.blue))
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                }
                .disabled(!(settings.peoplePerTable >= 1 && !settings.selectedShapes.isEmpty))
                .opacity((settings.peoplePerTable >= 1 && !settings.selectedShapes.isEmpty) ? 1 : 0.5)
                .background(.ultraThinMaterial)
            }
        }
    }

    private var shapeSelector: some View { EmptyView() }

    // Card helper
    private func settingsCard<Content: View>(title: String, subtitle: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title).font(.headline)
            if !subtitle.isEmpty { Text(subtitle).font(.footnote).foregroundColor(.secondary) }
            content()
        }
        .padding()
        .background(Color(.systemBackground))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color(.systemGray4)))
        .cornerRadius(14)
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
    }

    // Shape choice helper
    private func shapeChoice<ShapeType: InsettableShape>(isSelected: Bool, label: String, shapeSize: CGSize = CGSize(width: 72, height: 56), @ViewBuilder _ shape: () -> ShapeType, tap: @escaping () -> Void) -> some View {
        Button(action: tap) {
            VStack(spacing: 8) {
                shape()
                    .fill(isSelected ? Color.blue : Color.clear)
                    .overlay(shape().stroke(isSelected ? Color.blue : Color.gray.opacity(0.4), lineWidth: 2))
                    .frame(width: shapeSize.width, height: shapeSize.height)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(isSelected ? Color.blue.opacity(0.12) : Color(.systemBackground))
                            .shadow(color: Color.black.opacity(0.06), radius: 6, x: 0, y: 3)
                    )
                Text(label)
                    .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? .blue : .primary)
            }
            .frame(maxWidth: .infinity)
            .padding(10)
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel(label)
    }

    private var step2Source: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                VStack(spacing: 20) {
                    // Card 1 – Text List
                    card(title: "Text List", subtitle: "Paste names, one per line") {
                        ZStack(alignment: .topLeading) {
                            TextEditor(text: $pastedText)
                                .frame(minHeight: 130)
                                .padding(10)
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(.systemGray4)))
                            if pastedText.isEmpty {
                                Text("One name per line. You can add commas for extra fields if you have them.")
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 14)
                            }
                        }
                        .accessibilityLabel("Text list input")
                    }

                    // Card 2 – CSV File
                    card(title: "CSV File", subtitle: "Upload a CSV file from your device") {
                        Button(action: { showFileImporter = true }) {
                            Text("Choose CSV")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(.blue)
                                .frame(maxWidth: .infinity)
                                .frame(height: 48)
                                .background(RoundedRectangle(cornerRadius: 14).fill(Color.blue.opacity(0.1)))
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .fileImporter(isPresented: $showFileImporter, allowedContentTypes: [UTType.commaSeparatedText, UTType.text], allowsMultipleSelection: false) { result in
                        switch result {
                        case .success(let urls):
                            guard let url = urls.first else { return }
                            do {
                                let _ = url.startAccessingSecurityScopedResource()
                                defer { url.stopAccessingSecurityScopedResource() }
                                let data = try Data(contentsOf: url)
                                if let text = decodeCSVData(data) {
                                    pastedText = text
                                    parseTextToGrid(text)
                                    // Prepare mapping then send user to Settings (Step 1)
                                    detectHeadersAndInitMapping()
                                    recomputeMappedPeople()
                                    hasProcessedSource = true
                                    step = 1
                                } else {
                                    sourceError = "We couldn’t read that CSV. Try UTF-8/UTF-16/Windows-1252/ISO-8859-1."
                                }
                            } catch {
                                sourceError = "We couldn’t read that CSV. Try UTF-8/UTF-16/Windows-1252/ISO-8859-1."
                            }
                        case .failure:
                            break
                        }
                    }

                    // Card 3 – Google Sheets
                    card(title: "Google Sheets", subtitle: "Paste link or connect your account") {
                        VStack(alignment: .leading, spacing: 10) {
                            TextField("Paste Google Sheet link", text: $googleSheetURLString)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            Button(action: { fetchGoogleSheet() }) {
                                Text("Connect Google Sheets")
                                    .font(.system(size: 17, weight: .semibold))
                                    .foregroundColor(.orange)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 48)
                                    .background(RoundedRectangle(cornerRadius: 14).fill(Color.orange.opacity(0.12)))
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }

                    Spacer(minLength: 80)
                }
                .padding()
                .allowsHitTesting(!isProcessingSource)
            }

            // Sticky bottom bar – Next
            VStack(spacing: 0) {
                Divider()
                Button(action: { continueTapped() }) {
                    Text("Next")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(RoundedRectangle(cornerRadius: 16).fill(Color.blue))
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                }
                .disabled(!canContinue() || isProcessingSource)
                .opacity((canContinue() && !isProcessingSource) ? 1 : 0.5)
                .background(.ultraThinMaterial)
            }
            if isProcessingSource {
                VStack {
                    ProgressView("Preparing...")
                        .progressViewStyle(CircularProgressViewStyle())
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 14).fill(Color(.systemBackground)))
                        .shadow(color: Color.black.opacity(0.12), radius: 12, x: 0, y: 6)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black.opacity(0.15))
                .ignoresSafeArea()
            }
        }
    }

    private func card<Content: View>(title: String, subtitle: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                let emoji = iconEmoji(for: title)
                if !emoji.isEmpty {
                    Text(emoji).font(.system(size: 28))
                        .accessibilityHidden(true)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.headline).bold()
                    if !subtitle.isEmpty { Text(subtitle).font(.subheadline).foregroundColor(.secondary) }
                }
                Spacer()
            }
            content()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.06), radius: 10, x: 0, y: 4)
        )
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color(.systemGray4)))
    }

    private func iconEmoji(for title: String) -> String {
        let key = title.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        switch key {
        case "text list": return "📝"
        case "csv file": return "📄"
        case "google sheets": return "📊"
        default: return ""
        }
    }

    // Repeat-on-hold button wrapper
    struct RepeatButton<Label: View>: View {
        let onTap: () -> Void
        let onRepeat: () -> Void
        let label: () -> Label
        @State private var repeatTimer: Timer? = nil

        var body: some View {
            Button(action: onTap) { label() }
                .onLongPressGesture(minimumDuration: 0.35, maximumDistance: 30, pressing: { pressing in
                    if pressing { startRepeating() } else { stopRepeating() }
                }, perform: {})
        }

        private func startRepeating() {
            if repeatTimer == nil {
                repeatTimer = Timer.scheduledTimer(withTimeInterval: 0.08, repeats: true) { _ in
                    onRepeat()
                }
            }
        }

        private func stopRepeating() {
            repeatTimer?.invalidate()
            repeatTimer = nil
        }
    }

    private var step3Mapping: some View {
        // Column customization removed; route around this screen in flow.
        EmptyView()
    }

    private var step4Preview: some View {
        VStack(spacing: 0) {
            // PREVIEW FIRST (tables at top)
            if computingPreview { ProgressView("Building preview...").padding(.vertical, 8) }
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(previewAssignments.indices, id: \.self) { idx in
                        VStack(alignment: .leading, spacing: 8) {
                            let shape = shapeForTable(index: idx)
                            Text("Table \(idx + 1) – \(shape.rawValue.capitalized)").font(.headline)
                            ForEach(previewAssignments[idx]) { person in
                                HStack {
                                    Text(person.name)
                                    if person.vip { Text("VIP").font(.caption).padding(4).background(Color.yellow.opacity(0.3)).cornerRadius(6) }
                                    if let g = person.group, !g.isEmpty { Text(g).font(.caption).padding(4).background(Color.blue.opacity(0.15)).cornerRadius(6) }
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 44)
                                .contentShape(Rectangle())
                                .transition(.opacity.combined(with: .scale))
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                }
                .padding(.horizontal)
                .animation(.easeInOut(duration: 0.35), value: previewAssignments)
                .padding(.bottom, 12)
            }

            // ACTIONS BELOW
            VStack(spacing: 0) {
                Divider()
                HStack(spacing: 12) {
                    // Swap order: show Shuffle first, then Create Tables
                    Button(action: {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        recomputePreview()
                    }) {
                        Text("Shuffle")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(RoundedRectangle(cornerRadius: 16).fill(Color.blue))
                    }
                    .disabled(previewAssignments.isEmpty || computingPreview)

                    Button(action: { createTables() }) {
                        Text("Create Tables")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(RoundedRectangle(cornerRadius: 16).fill(Color.green))
                    }
                    .disabled(previewAssignments.isEmpty || computingPreview)
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(.ultraThinMaterial)
            }
        }
        .padding(.top, 0)
        .task {
            // Always compute on first presentation; .task avoids duplicate work during transitions
            await MainActor.run { recomputePreview() }
        }
        .alert("Success", isPresented: $showSuccess) {
            Button("OK") {
                isPresented = false
            }
        } message: {
            let totals = previewAssignments.reduce(into: (tables: 0, people: 0)) { acc, arr in acc.tables += 1; acc.people += arr.count }
            Text("Tables created: \(totals.tables) tables, \(totals.people) guests.")
        }
    }

    // Actions
    private func continueTapped() {
        switch step {
        case 1:
            if hasProcessedSource {
                // Navigate instantly to Preview, then build
                step = 4
                recomputePreview()
            } else {
                step = 2
            }
        case 2:
            processSourceAndNavigate()
        case 3:
            // Mapping screen is removed; route directly to Preview
            step = 4
            recomputePreview()
        default:
            break
        }
    }

    // Determine if we launched from the empty "Create seating for events" flow
    private var isComingFromCreateSeating: Bool {
        viewModel.currentArrangement.people.isEmpty && viewModel.tableCollection.tables.isEmpty
    }

    // Unified source processing and navigation
    private func processSourceAndNavigate() {
        isProcessingSource = true
        sourceError = nil

        let trimmedText = pastedText.trimmingCharacters(in: .whitespacesAndNewlines)
        let hasText = !trimmedText.isEmpty
        let hasRows = !rawRows.isEmpty
        let hasGoogleLink = !googleSheetURLString.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty

        if hasGoogleLink && !hasText && !hasRows {
            fetchGoogleSheetForNext()
            return
        }

        if hasText && !hasRows { parseTextToGrid(trimmedText) }
        continueAfterParsing()
    }

    private func continueAfterParsing() {
        if mapping.headerNames.isEmpty { detectHeadersAndInitMapping() }
        if let firstHeader = mapping.headerNames.first, mapping.mapping[firstHeader] == nil { mapping.mapping[firstHeader] = "Name" }
        mapping.autoCleanNames = true
        mapping.createTagsFromExtras = false
        recomputeMappedPeople()
        // Auto-suggest people-per-table based on guest count
        let total = mappedPeople.count
        let suggested = min(total, suggestedPeoplePerTable(for: total))
        settings.peoplePerTable = suggested
        peoplePerTableText = String(suggested)

        // After processing source, move directly to Preview and compute so it never appears blank
        isProcessingSource = false
        hasProcessedSource = true
        step = 4
        recomputePreview()
    }

    private func fetchGoogleSheetForNext() {
        guard let url = URL(string: googleSheetURLString.trimmingCharacters(in: .whitespacesAndNewlines)), !googleSheetURLString.isEmpty else {
            isProcessingSource = false
            return
        }
        let exportURL: URL = transformGoogleSheetsURLToCSV(url: url) ?? url
        Task {
            do {
                let (data, _) = try await URLSession.shared.data(from: exportURL)
                if let text = decodeCSVData(data) {
                    pastedText = text
                    parseTextToGrid(text)
                    // Jump to Preview immediately
                    continueAfterParsing()
                } else {
                    sourceError = "We couldn’t read that CSV. Try UTF-8/UTF-16/Windows-1252/ISO-8859-1."
                    isProcessingSource = false
                }
            } catch {
                sourceError = "Connect to the internet to import from Google Sheets, or export the sheet as CSV."
                isProcessingSource = false
            }
        }
    }

    private func canContinue() -> Bool {
        switch step {
        case 1:
            // Clamp people-per-table to not exceed available names if already parsed
            let maxAllowed = max(1, min(20, mappedPeople.isEmpty ? 20 : mappedPeople.count))
            if settings.peoplePerTable > maxAllowed { settings.peoplePerTable = maxAllowed }
            return settings.peoplePerTable >= 1 && !settings.selectedShapes.isEmpty
        case 2:
            // Require at least 2 names when using text list
            let names = pastedText.split(whereSeparator: { $0.isNewline }).map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
            let hasAtLeastTwo = names.count >= 2 || !rawRows.isEmpty
            return hasAtLeastTwo
        case 3: return mappedPeople.contains(where: { !$0.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty })
        default: return false
        }
    }

    private func navigationTitleForStep(_ step: Int) -> String {
        switch step {
        case 1: return "Seating settings"
        case 2: return "Choose a Source"
        case 3: return "Preview"
        case 4: return "Preview"
        default: return "Import from List"
        }
    }

    // Parsing
    private func parseTextToGrid(_ text: String) {
        let lines = text.split(whereSeparator: { $0.isNewline }).map { String($0) }
        var rows: [[String]] = []
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty { continue }
            rows.append(splitCSVLine(trimmed))
        }
        rawRows = rows
        mapping.headerNames = []
    }

    // Attempt to decode CSV content across common encodings with BOM handling
    private func decodeCSVData(_ data: Data) -> String? {
        // Strip common BOMs
        let utf8BOM: [UInt8] = [0xEF, 0xBB, 0xBF]
        let utf16LEBOM: [UInt8] = [0xFF, 0xFE]
        let utf16BEBOM: [UInt8] = [0xFE, 0xFF]
        var content = data
        if content.count >= 3 && Array(content.prefix(3)) == utf8BOM { content = content.dropFirst(3) }
        if content.count >= 2 && Array(content.prefix(2)) == utf16LEBOM { content = content.dropFirst(2) }
        if content.count >= 2 && Array(content.prefix(2)) == utf16BEBOM { content = content.dropFirst(2) }

        // Try encodings in order
        if let s = String(data: content, encoding: .utf8) { return s }
        if let s = String(data: content, encoding: .utf16LittleEndian) { return s }
        if let s = String(data: content, encoding: .utf16BigEndian) { return s }
        if let s = String(data: content, encoding: .unicode) { return s }
        if let s = String(data: content, encoding: .windowsCP1252) { return s }
        if let s = String(data: content, encoding: .isoLatin1) { return s }
        if let s = String(data: content, encoding: .ascii) { return s }
        return nil
    }

    private func splitCSVLine(_ line: String) -> [String] {
        var result: [String] = []
        var current = ""
        var inQuotes = false
        var iterator = line.makeIterator()
        while let ch = iterator.next() {
            if ch == "\"" { inQuotes.toggle(); continue }
            if ch == "," && !inQuotes {
                result.append(current.trimmingCharacters(in: .whitespaces))
                current = ""
            } else { current.append(ch) }
        }
        result.append(current.trimmingCharacters(in: .whitespaces))
        return result
    }

    private func fetchGoogleSheet() {
        guard let url = URL(string: googleSheetURLString.trimmingCharacters(in: .whitespacesAndNewlines)), !googleSheetURLString.isEmpty else { return }
        let exportURL: URL = transformGoogleSheetsURLToCSV(url: url) ?? url
        Task {
            do {
                let (data, _) = try await URLSession.shared.data(from: exportURL)
                if let text = decodeCSVData(data) {
                    pastedText = text
                    parseTextToGrid(text)
                    detectHeadersAndInitMapping()
                    recomputeMappedPeople()
                    recomputePreview() {
                        step = 4
                    }
                } else { sourceError = "We couldn’t read that CSV. Try UTF-8 format or open and re-save." }
            } catch {
                sourceError = "Connect to the internet to import from Google Sheets, or export the sheet as CSV."
            }
        }
    }

    private func transformGoogleSheetsURLToCSV(url: URL) -> URL? {
        let s = url.absoluteString
        if s.contains("/edit") {
            let base = s.components(separatedBy: "/edit").first ?? s
            if let export = URL(string: base + "/export?format=csv") { return export }
        }
        return nil
    }

    // Mapping helpers
    private func detectHeadersAndInitMapping() {
        let first = rawRows.first ?? []
        mapping.hasHeaders = headerLooksLikeHeaders(first)
        mapping.headerNames = mapping.hasHeaders ? first : defaultColumnNames(count: first.count)
        // Seed sensible defaults for all headers so first-time Preview isn't blank
        mapping.mapping = [:]
        for header in mapping.headerNames {
            mapping.mapping[header] = headerDefault(header)
        }
        // Ensure at least one column is treated as Name
        if !mapping.mapping.values.contains("Name"), let firstHeader = mapping.headerNames.first {
            mapping.mapping[firstHeader] = "Name"
        }
        recomputeMappedPeople()
    }

    private func headerLooksLikeHeaders(_ firstRow: [String]) -> Bool {
        let common = ["name", "first", "last", "group", "notes", "email", "phone", "vip", "keepapart", "keepwith", "dietary"]
        let matches = firstRow.filter { h in common.contains(h.lowercased().replacingOccurrences(of: " ", with: "")) }
        return matches.count >= max(1, firstRow.count / 3)
    }

    private func defaultColumnNames(count: Int) -> [String] { (0..<count).map { "Column \($0 + 1)" } }

    private func fieldTargets() -> [String] { ["Ignore", "Name", "First", "Last", "Group", "Notes", "Email", "Phone", "VIP", "KeepApart", "KeepWith", "Dietary", "Tag"] }

    private func headerDefault(_ header: String) -> String {
        let key = header.lowercased()
        if key.contains("name") { return "Name" }
        if key == "first" { return "First" }
        if key == "last" { return "Last" }
        if key.contains("group") || key.contains("tag") { return "Group" }
        if key.contains("note") { return "Notes" }
        if key.contains("email") { return "Email" }
        if key.contains("phone") { return "Phone" }
        if key.contains("vip") { return "VIP" }
        if key.contains("keepapart") { return "KeepApart" }
        if key.contains("keepwith") { return "KeepWith" }
        if key.contains("diet") { return "Dietary" }
        return "Ignore"
    }

    private func recomputeMappedPeople() {
        guard !rawRows.isEmpty else { mappedPeople = []; return }
        var rows = rawRows
        if mapping.hasHeaders && !rows.isEmpty { rows.removeFirst() }
        let headers = mapping.headerNames
        var people: [ImportedPersonData] = []
        var seenNames: Set<String> = []
        for row in rows {
            var name: String = ""
            var first: String = ""
            var last: String = ""
            var group: String? = nil
            var tags: [String] = []
            var vip = false
            var keepApart: [String] = []
            var keepWith: [String] = []
            var dietary: [String] = []
            var notes: String? = nil
            var email: String? = nil
            var phone: String? = nil
            for (idx, cell) in row.enumerated() {
                let header = idx < headers.count ? headers[idx] : "Column \(idx+1)"
                let target = mapping.mapping[header] ?? headerDefault(header)
                let value = cell.trimmingCharacters(in: .whitespacesAndNewlines)
                if value.isEmpty { continue }
                switch target {
                case "Name": name = value
                case "First": first = value
                case "Last": last = value
                case "Group": group = value
                case "Notes": notes = value
                case "Email": email = value
                case "Phone": phone = value
                case "VIP": vip = value.lowercased().hasPrefix("y") || value == "1" || value.lowercased() == "vip"
                case "KeepApart": keepApart.append(contentsOf: value.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) })
                case "KeepWith": keepWith.append(contentsOf: value.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) })
                case "Dietary": dietary.append(contentsOf: value.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) })
                case "Tag": tags.append(contentsOf: value.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) })
                default: break
                }
            }
            if name.isEmpty {
                let parts = [first, last].filter { !$0.isEmpty }
                if !parts.isEmpty { name = parts.joined(separator: " ") }
            }
            name = mapping.autoCleanNames ? titleCased(name.trimmingCharacters(in: .whitespacesAndNewlines)) : name
            guard !name.isEmpty else { continue }
            if mapping.autoCleanNames {
                if seenNames.contains(name.lowercased()) { continue }
                seenNames.insert(name.lowercased())
            }
            if mapping.createTagsFromExtras {
                for (idx, cell) in row.enumerated() {
                    let header = idx < headers.count ? headers[idx] : "Column \(idx+1)"
                    if (mapping.mapping[header] ?? headerDefault(header)) == "Ignore" {
                        let raw = cell.trimmingCharacters(in: .whitespacesAndNewlines)
                        if !raw.isEmpty { tags.append(raw) }
                    }
                }
            }
            let person = ImportedPersonData(name: name, group: group, tags: tags, vip: vip, keepApartTags: keepApart, keepWithNames: keepWith, dietary: dietary, notes: notes, email: email, phone: phone)
            people.append(person)
        }
        mappedPeople = people
    }

    private func titleCased(_ s: String) -> String { s.lowercased().split(separator: " ").map { $0.prefix(1).uppercased() + $0.dropFirst() }.joined(separator: " ") }

    private func recomputePreview(completion: (() -> Void)? = nil) {
        guard !mappedPeople.isEmpty else {
            // Ensure we clear state and still advance caller if needed
            previewAssignments = []
            computingPreview = false
            completion?()
            return
        }
        computingPreview = true
        DispatchQueue.global(qos: .userInitiated).async {
            let tables = buildAssignments(people: mappedPeople, settings: settings)
            DispatchQueue.main.async {
                self.previewAssignments = tables
                self.computingPreview = false
                completion?()
            }
        }
    }

    private func buildAssignments(people: [ImportedPersonData], settings: ImportSeatingSettings) -> [[ImportedPersonData]] {
        // Clamp per-table to 20 max
        let perTableInput = max(1, min(20, settings.peoplePerTable))
        let total = people.count
        // Manual count path: ensure enough tables to keep <=20 per table
        if settings.manualTableCountEnabled {
            let minTablesForCapacity = max(1, Int(ceil(Double(total) / 20.0)))
            let manualCount = max(minTablesForCapacity, max(1, settings.manualTableCount))
            return distribute(people: people, into: manualCount, perTableLimit: 20, targetPerTable: perTableInput, settings: settings)
        }
        // Auto: honor the chosen people-per-table value
        let targetPerTable = min(perTableInput, max(1, total))
        let autoTables = max(1, Int(ceil(Double(total) / Double(targetPerTable))))
        let minTablesForCapacity = max(1, Int(ceil(Double(total) / 20.0)))
        let tableCount = max(minTablesForCapacity, autoTables)
        return distribute(people: people, into: tableCount, perTableLimit: 20, targetPerTable: targetPerTable, settings: settings)
    }

    // Helper to distribute people based on constraints
    private func distribute(people: [ImportedPersonData], into tableCount: Int, perTableLimit: Int, targetPerTable: Int, settings: ImportSeatingSettings) -> [[ImportedPersonData]] {
        let perTable = min(perTableLimit, max(1, targetPerTable))
        if tableCount == 0 { return [] }
        var tables: [[ImportedPersonData]] = Array(repeating: [], count: tableCount)
        // Randomize VIP and non‑VIP order so Shuffle actually changes results
        let vips = people.filter { $0.vip }.shuffled()
        let nonVIPs = people.filter { !$0.vip }.shuffled()
        var vipIndex = 0
        for idx in 0..<tableCount { if vipIndex < vips.count { tables[idx].append(vips[vipIndex]); vipIndex += 1 } }
        while vipIndex < vips.count {
            if let idx = tables.firstIndex(where: { $0.count < perTable }) { tables[idx].append(vips[vipIndex]); vipIndex += 1 } else { break }
        }
        if settings.groupConstraint == .keepTogether {
            let groups = Dictionary(grouping: nonVIPs, by: { $0.group ?? "" })
            // Shuffle group order for variety
            for members in groups.values.shuffled() {
                var idx = tables.firstIndex { $0.count + members.count <= perTable } ?? tables.firstIndex { $0.count < perTable } ?? 0
                for m in members {
                    if tables[idx].count >= perTable { idx = (idx + 1) % tableCount }
                    tables[idx].append(m)
                }
            }
        } else if settings.groupConstraint == .spreadAcross {
            let groups = Dictionary(grouping: nonVIPs, by: { $0.group ?? UUID().uuidString })
            var groupArrays = groups.values.map { Array($0) }.shuffled()
            var didPlace = true
            var t = 0
            while didPlace {
                didPlace = false
                for g in 0..<groupArrays.count {
                    if groupArrays[g].isEmpty { continue }
                    var attempts = 0
                    while attempts < tableCount && tables[t].count >= perTable { t = (t + 1) % tableCount; attempts += 1 }
                    if tables[t].count < perTable { tables[t].append(groupArrays[g].removeFirst()); didPlace = true; t = (t + 1) % tableCount }
                }
            }
        } else {
            let order = nonVIPs
            switch settings.assignmentMode {
            case .fillInOrder:
                var idx = 0
                for p in order { while idx < tableCount && tables[idx].count >= perTable { idx += 1 }; if idx >= tableCount { break }; tables[idx].append(p) }
            case .roundRobin:
                var idx = 0
                for p in order { var attempts = 0; while attempts < tableCount && tables[idx].count >= perTable { idx = (idx + 1) % tableCount; attempts += 1 }; if tables[idx].count < perTable { tables[idx].append(p) }; idx = (idx + 1) % tableCount }
            }
        }
        return tables
    }

    private func shapeForTable(index: Int) -> TableShape {
        guard !settings.selectedShapes.isEmpty else { return .round }
        if settings.rotationMode == .staticOne { return settings.selectedShapes.first ?? .round }
        return settings.selectedShapes[index % settings.selectedShapes.count]
    }

    private func createTables() {
        let assigned = previewAssignments
        guard !assigned.isEmpty else { return }
        // Capture origin before mutating ViewModel so we know whether to dismiss
        _ = isComingFromCreateSeating
        let shapes = (0..<assigned.count).map { shapeForTable(index: $0) }
        let namesOnly: [[String]] = assigned.map { $0.map { $0.name } }
        viewModel.createTablesFromImported(assignments: namesOnly, shapes: shapes, eventTitle: "Imported from List – \(DateFormatter.localizedString(from: Date(), dateStyle: .short, timeStyle: .short))")
        // Ensure the main screen switches out of the empty state and shows the new tables
        NotificationCenter.default.post(name: Notification.Name("HideEffortlessScreen"), object: nil)
        // Always close the Import flow and show the tables immediately
        isPresented = false
    }

    // Heuristic for autosetting people-per-table based on total guests
    private func suggestedPeoplePerTable(for totalGuests: Int) -> Int {
        switch totalGuests {
        case ..<5: return 4
        case 5...8: return 4
        case 9...12: return 6
        case 13...20: return 8
        case 21...40: return 10
        case 41...60: return 12
        case 61...100: return 14
        case 101...160: return 16
        default: return 18
        }
    }

    private func sampleCSV() -> String {
        """
        First,Last,Group,Notes,VIP,KeepApart,KeepWith,Dietary
        Hank,Zakroff,Family,Wheelchair,No,,Jane Kim,Vegetarian
        David,Taylor,Coworkers,,Yes,Executive,,
        Jane,Kim,Family,,No,,Hank Zakroff,Gluten-free
        """
    }
}

private extension View { func eraseToAnyView() -> AnyView { AnyView(self) } }


