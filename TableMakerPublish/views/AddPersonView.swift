import SwiftUI
import Contacts
import UniformTypeIdentifiers

// Include the ContactsListView directly in this file to avoid project reference issues
struct ContactsListView: View {
    let contacts: [String]
    var searchText: String = ""
    let onSelect: ([String]) -> Void
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
                        Spacer()
                    }
                } else {
                    List {
                        ForEach(filteredContacts, id: \.self) { contact in
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
                VStack(spacing: 12) {
                    // Import from List (top)
                    Button(action: {
                        // Close Add Person, then open Import flow at Source step
                        isPresented = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                            importStartIntent = .text // opens Source step without auto-opening
                        }
                    }) {
                        HStack {
                            Image(systemName: "text.badge.plus")
                            Text("Import from List")
                                .fontWeight(.semibold)
                        }
                        .font(.title3)
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 22.5) // base width
                        .padding(.vertical, 14) // slightly shorter height
                        .padding(.top, 5) // move down ~5px
                        .background(Color.blue.opacity(0.12))
                        .cornerRadius(16)
                    }
                    .padding(.horizontal, -1.5) // expand overall width by ~3px beyond container
                    // Removed dropdown entirely; handled directly above

                    // Import from contacts (bottom)
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
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 16)
                        .background(Color.blue.opacity(0.12))
                        .cornerRadius(16)
                    }

                    if viewModel.isLoadingContacts {
                        ProgressView()
                            .scaleEffect(1.2)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 6) // ~10px lower toward the bottom
                .background(.ultraThinMaterial)
                .ignoresSafeArea(.keyboard, edges: .bottom)
            }
            .navigationTitle(NSLocalizedString("Add Person", comment: "Navigation title for add person view"))
            .navigationBarItems(
                leading: Button(NSLocalizedString("Cancel", comment: "Cancel button")) {
                    isPresented = false
                },
                trailing: Button(NSLocalizedString("Add", comment: "Add button")) {
                    addPerson()
                }
                .disabled(newPersonName.isEmpty)
            )
            // Contacts picker sheet
            .sheet(isPresented: $showingContactsPicker, onDismiss: {
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
        // Match main screen duplicate behavior: check across ALL tables plus current table
        let allPeopleNames = viewModel.tableCollection.tables.values.flatMap { $0.people.map { $0.name.lowercased() } }
        let currentTableNames = viewModel.currentArrangement.people.map { $0.name.lowercased() }
        let allNames = Set(allPeopleNames + currentTableNames)
        if allNames.contains(newPersonName.lowercased()) {
            // Keep the sheet open and show a consistent alert
            showingDuplicateAlert = true
            return
        }
        // Enforce 20-person limit (same as ViewModel guard)
        if viewModel.currentArrangement.people.count < 20 {
            viewModel.addPerson(name: newPersonName)
            DispatchQueue.main.async {
                isPresented = false
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
    var peoplePerTable: Int = 8
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

    @State private var rawRows: [[String]] = []
    @State private var mapping = FieldMapping()
    @State private var mappedPeople: [ImportedPersonData] = []

    @State private var previewAssignments: [[ImportedPersonData]] = []
    @State private var computingPreview: Bool = false
    @State private var showSuccess: Bool = false

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                switch step {
                case 1: step1Settings
                case 2: step2Source
                case 3: step3Mapping
                case 4: step4Preview
                default: step1Settings
                }
            }
            .navigationTitle(navigationTitleForStep(step))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Back") {
                        if step == 1 { isPresented = false } else { step -= 1 }
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    if step == 3 {
                        Button("Create Tables") { createTables() }
                            .disabled(previewAssignments.isEmpty)
                    } else if step < 3 {
                        Button("Next") { continueTapped() }
                            .disabled(step == 1 ? !(settings.peoplePerTable >= 2 && !settings.selectedShapes.isEmpty) : !canContinue())
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
            // Start on Seating settings to configure table division before sourcing
            step = 1
            peoplePerTableText = String(settings.peoplePerTable)
        }
    }

    private var step1Settings: some View {
        ScrollView {
            VStack(spacing: 16) {
                Text("Set up your tables").font(.title2).bold().frame(maxWidth: .infinity, alignment: .leading)
                Text("Pick a shape and how many people fit at each table.")
                    .font(.subheadline).foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                GroupBox(label: Text("People per table")) {
                    HStack(spacing: 12) {
                        TextField("", text: $peoplePerTableText)
                            .keyboardType(.numberPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(width: 80)
                            .onChange(of: peoplePerTableText) { t in
                                let v = Int(t) ?? settings.peoplePerTable
                                settings.peoplePerTable = min(max(2, v), 30)
                            }
                        Stepper(value: $settings.peoplePerTable, in: 2...30) { EmptyView() }
                            .labelsHidden()
                            .onChange(of: settings.peoplePerTable) { v in peoplePerTableText = String(v) }
                    }
                }

                GroupBox(label: Text("Table shape")) { shapeSelector }

                GroupBox(label: Text("Table count")) {
                    Toggle("Set manually", isOn: $settings.manualTableCountEnabled)
                    if settings.manualTableCountEnabled {
                        Stepper(value: $settings.manualTableCount, in: 1...200) { Text("\(settings.manualTableCount)") }
                    }
                }
            }
            .padding()
            // Keyboard toolbar with Done button for number input
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    }
                }
            }
        }
    }

    private var shapeSelector: some View {
        // Use a flexible flow layout so chips don't wrap mid-word
        HStack(spacing: 12) {
            ContentView.TableShapeSelectorButton(shape: .round, isSelected: settings.selectedShapes.contains(.round)) {
                if settings.selectedShapes.contains(.round) { settings.selectedShapes.removeAll { $0 == .round } } else { settings.selectedShapes.append(.round) }
                if settings.selectedShapes.isEmpty { settings.selectedShapes = [.round] }
            }
            ContentView.TableShapeSelectorButton(shape: .rectangle, isSelected: settings.selectedShapes.contains(.rectangle)) {
                if settings.selectedShapes.contains(.rectangle) { settings.selectedShapes.removeAll { $0 == .rectangle } } else { settings.selectedShapes.append(.rectangle) }
                if settings.selectedShapes.isEmpty { settings.selectedShapes = [.rectangle] }
            }
            ContentView.TableShapeSelectorButton(shape: .square, isSelected: settings.selectedShapes.contains(.square)) {
                if settings.selectedShapes.contains(.square) { settings.selectedShapes.removeAll { $0 == .square } } else { settings.selectedShapes.append(.square) }
                if settings.selectedShapes.isEmpty { settings.selectedShapes = [.square] }
            }
        }
    }

    private var step2Source: some View {
        ScrollView {
            VStack(spacing: 18) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Choose a source").font(.title2).bold()
                        Text("CSV, Google Sheets, or paste names").font(.subheadline).foregroundColor(.secondary)
                    }
                    Spacer()
                }
                .padding(.horizontal)
                card(title: "CSV file", subtitle: "") {
                    HStack {
                        Button(action: { showFileImporter = true }) { Label("Choose CSV", systemImage: "doc.badge.plus") }
                        Spacer()
                    }
                }
                .fileImporter(isPresented: $showFileImporter, allowedContentTypes: [UTType.commaSeparatedText, UTType.text], allowsMultipleSelection: false) { result in
                    switch result {
                    case .success(let urls):
                        guard let url = urls.first else { return }
                        do {
                            let data = try Data(contentsOf: url)
                            if let text = String(data: data, encoding: .utf8) ?? String(data: data, encoding: .ascii) {
                                pastedText = text
                                parseTextToGrid(text)
                                step = 3
                            } else {
                                sourceError = "We couldn’t read that CSV. Try UTF-8 format or open and re-save."
                            }
                        } catch {
                            sourceError = "We couldn’t read that CSV. Try UTF-8 format or open and re-save."
                        }
                    case .failure:
                        break
                    }
                }

                card(title: "Google Sheets", subtitle: "") {
                    VStack(alignment: .leading, spacing: 8) {
                        TextField("Paste Google Sheet link", text: $googleSheetURLString)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        HStack { Button(action: { fetchGoogleSheet() }) { Label("Connect Google Sheets", systemImage: "link") }; Spacer() }
                    }
                }

                card(title: "Text list", subtitle: "") {
                    ZStack(alignment: .topLeading) {
                        TextEditor(text: $pastedText)
                            .frame(minHeight: 260)
                            .padding(8)
                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(.systemGray4)))
                        if pastedText.isEmpty {
                            Text("One name per line. You can add commas for extra fields if you have them.")
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 14)
                        }
                    }
                    // No hint or Use Text button; parse automatically on Continue
                }
                Spacer(minLength: 40)
            }
            .padding()
        }
    }

    private func card<Content: View>(title: String, subtitle: String, @ViewBuilder content: () -> Content) -> some View {
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

    private var step3Mapping: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Removed explicit headers toggle; infer automatically
                    ForEach(mapping.headerNames.dropFirst(), id: \.self) { header in
                        HStack {
                            Text(header).font(.subheadline)
                            Spacer()
                            Picker("Map to", selection: Binding(
                                get: { mapping.mapping[header, default: headerDefault(header)] },
                                set: { mapping.mapping[header] = $0; recomputeMappedPeople() }
                            )) {
                                ForEach(fieldTargets().filter { $0 != "Tag" && $0 != "Name" }, id: \.self) { target in Text(target).tag(target) }
                            }
                            .pickerStyle(MenuPickerStyle())
                        }
                        .padding(.vertical, 6)
                    }
                    // Auto-clean enforced; tags creation disabled
                    // Preview heading removed per request; preview shown only as tables below
                }
                .padding()
            }
            .onAppear {
                if mapping.headerNames.isEmpty && !rawRows.isEmpty {
                    detectHeadersAndInitMapping()
                }
                // Auto-generate preview right away when entering mapping
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { recomputeMappedPeople(); recomputePreview() }
            }
            // Inline options & preview actions at bottom of mapping screen
            if !previewAssignments.isEmpty || !mappedPeople.isEmpty {
            VStack(spacing: 12) {
                if computingPreview { ProgressView("Building preview...").padding() }
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(previewAssignments.indices, id: \.self) { idx in
                            VStack(alignment: .leading, spacing: 8) {
                                let shape = shapeForTable(index: idx)
                                Text("Table \(idx + 1) – \(shape.rawValue.capitalized)").font(.headline)
                                ForEach(previewAssignments[idx]) { person in
                                    HStack { Text(person.name) }
                                }
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal)
                }
                Button(action: { recomputePreview() }) { Label("Reshuffle", systemImage: "shuffle") }
                    .buttonStyle(.bordered)
                    .padding(.top, 4)
            }
                .padding(.top, 8)
            }
        }
    }

    private var step4Preview: some View {
        VStack(spacing: 12) {
            GroupBox(label: Text("Seating logic options")) {
                VStack(alignment: .leading, spacing: 12) {
                    Picker("Assignment mode", selection: $settings.assignmentMode) { ForEach(ImportAssignmentMode.allCases) { m in Text(m.rawValue).tag(m) } }.pickerStyle(SegmentedPickerStyle())
                    Picker("Group mode", selection: $settings.groupConstraint) { ForEach(ImportGroupConstraint.allCases) { c in Text(c.rawValue).tag(c) } }.pickerStyle(SegmentedPickerStyle())
                    Toggle("Respect VIP (one per table if possible)", isOn: .constant(true)).disabled(true)
                }
            }
            if computingPreview { ProgressView("Building preview...").padding() }
            else if previewAssignments.isEmpty { Button("Build Preview") { recomputePreview() } }
            else {
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
                                }
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal)
                }
            }
            HStack {
                Button("Reshuffle") { recomputePreview() }
                Spacer()
                Button("Create Tables") { createTables() }
                    .buttonStyle(.borderedProminent)
                    .disabled(previewAssignments.isEmpty)
            }
            .padding(.horizontal)
            Spacer(minLength: 8)
        }
        .padding(.top, 8)
        .onAppear { if previewAssignments.isEmpty { recomputePreview() } }
        .alert("Success", isPresented: $showSuccess) {
            Button("OK") { isPresented = false }
        } message: {
            let totals = previewAssignments.reduce(into: (tables: 0, people: 0)) { acc, arr in acc.tables += 1; acc.people += arr.count }
            Text("Tables created: \(totals.tables) tables, \(totals.people) guests.")
        }
    }

    // Actions
    private func continueTapped() {
        switch step {
        case 1: step = 2
        case 2:
            if rawRows.isEmpty && pastedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                sourceError = "Please choose a CSV, connect a Google Sheet, or paste a list."
                return
            }
            if !pastedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && rawRows.isEmpty {
                parseTextToGrid(pastedText)
            }
            if mapping.headerNames.isEmpty { detectHeadersAndInitMapping() }
            // Auto-map first column to Name if no mapping exists
            if !mapping.headerNames.isEmpty {
                let firstHeader = mapping.headerNames.first ?? "Column 1"
                if mapping.mapping[firstHeader] == nil { mapping.mapping[firstHeader] = "Name" }
            }
            // Always auto-clean names; remove UI toggle
            mapping.autoCleanNames = true
            mapping.createTagsFromExtras = false
            recomputeMappedPeople()
            step = 3
        case 3:
            guard mappedPeople.contains(where: { !$0.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }) else {
                sourceError = "Map at least one name column."
                return
            }
            // Build preview inline and show actions at bottom instead of separate step
            recomputePreview()
        default: break
        }
    }

    private func canContinue() -> Bool {
        switch step {
        case 1: return settings.peoplePerTable >= 2 && !settings.selectedShapes.isEmpty
        case 2: return !rawRows.isEmpty || !pastedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case 3: return mappedPeople.contains(where: { !$0.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty })
        default: return false
        }
    }

    private func navigationTitleForStep(_ step: Int) -> String {
        switch step {
        case 1: return "Seating settings"
        case 2: return "Source"
        case 3: return "Preview"
        case 4: return "Options & preview"
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
                if let text = String(data: data, encoding: .utf8) ?? String(data: data, encoding: .ascii) {
                    pastedText = text
                    parseTextToGrid(text)
                    step = 3
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
        DispatchQueue.main.async {
            let first = rawRows.first ?? []
            mapping.hasHeaders = headerLooksLikeHeaders(first)
            mapping.headerNames = mapping.hasHeaders ? first : defaultColumnNames(count: first.count)
            mapping.mapping = [:]
            recomputeMappedPeople()
        }
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

    private func recomputePreview() {
        guard !mappedPeople.isEmpty else { previewAssignments = []; return }
        computingPreview = true
        DispatchQueue.global(qos: .userInitiated).async {
            let tables = buildAssignments(people: mappedPeople, settings: settings)
            DispatchQueue.main.async { self.previewAssignments = tables; self.computingPreview = false }
        }
    }

    private func buildAssignments(people: [ImportedPersonData], settings: ImportSeatingSettings) -> [[ImportedPersonData]] {
        let perTable = max(2, settings.peoplePerTable)
        let total = people.count
        // Minimum tables such that people per table <= 20
        let minTablesForCapacity = max(1, Int(ceil(Double(total) / Double(min(perTable, 20)))))
        let autoTables = Int(ceil(Double(total) / Double(perTable)))
        let computedTables = max(minTablesForCapacity, autoTables)
        let tableCount: Int = settings.manualTableCountEnabled ? max(minTablesForCapacity, settings.manualTableCount) : computedTables
        if tableCount == 0 { return [] }
        var tables: [[ImportedPersonData]] = Array(repeating: [], count: tableCount)
        let vips = people.filter { $0.vip }
        let nonVIPs = people.filter { !$0.vip }
        var vipIndex = 0
        for idx in 0..<tableCount { if vipIndex < vips.count { tables[idx].append(vips[vipIndex]); vipIndex += 1 } }
        while vipIndex < vips.count {
            if let idx = tables.firstIndex(where: { $0.count < perTable }) { tables[idx].append(vips[vipIndex]); vipIndex += 1 } else { break }
        }
        if settings.groupConstraint == .keepTogether {
            let groups = Dictionary(grouping: nonVIPs, by: { $0.group ?? "" }).sorted { $0.key < $1.key }
            for (_, members) in groups { var idx = tables.firstIndex { $0.count + members.count <= perTable } ?? tables.firstIndex { $0.count < perTable } ?? 0; for m in members { if tables[idx].count >= perTable { idx = (idx + 1) % tableCount }; tables[idx].append(m) } }
        } else if settings.groupConstraint == .spreadAcross {
            let groups = Dictionary(grouping: nonVIPs, by: { $0.group ?? UUID().uuidString })
            var groupArrays = groups.values.map { Array($0) }
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
        let shapes = (0..<assigned.count).map { shapeForTable(index: $0) }
        let namesOnly: [[String]] = assigned.map { $0.map { $0.name } }
        viewModel.createTablesFromImported(assignments: namesOnly, shapes: shapes, eventTitle: "Imported from List – \(DateFormatter.localizedString(from: Date(), dateStyle: .short, timeStyle: .short))")
        showSuccess = true
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

