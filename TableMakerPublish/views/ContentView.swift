import SwiftUI
import Contacts
import MessageUI
import UIKit
import CoreImage.CIFilterBuiltins
import PhotosUI
import StoreKit // For App Store review prompt
import Combine
import Foundation
import UserNotifications
import UniformTypeIdentifiers
// If needed, add the following import to ensure the correct SeatingArrangement is used:
// import TableMakerPublish.Models

// Define a custom EnvironmentKey for showingTutorialInitially
struct ShowingTutorialInitiallyKey: EnvironmentKey {
    static let defaultValue: Bool = false
}

extension EnvironmentValues {
    var showingTutorialInitially: Bool {
        get { self[ShowingTutorialInitiallyKey.self] }
        set { self[ShowingTutorialInitiallyKey.self] = newValue }
    }
}

// Transferable wrapper for sharing a PNG image via ShareLink
struct TableLayoutImage: Transferable {
    let image: UIImage
    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .png) { value in
            guard let data = value.image.pngData() else {
                throw NSError(domain: "Share", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to encode image as PNG."])
            }
            return data
        }
    }
}

// Helper struct with utility functions that can be accessed from anywhere
struct UIHelpers {
    // Helper function to get emoji based on table shape
    static func getShapeEmoji(for shape: TableShape) -> String {
        switch shape {
        case .round:
            return "◯"
        case .square:
            return "□"
        case .rectangle:
            return "▭"
        }
    }
    
    // Helper function to determine event type and emoji from title
    static func formatEventTitle(_ title: String) -> (String, String) {
        if title.isEmpty {
            return ("", "🪑")
        }
        
        // Normalize title for case-insensitive matching
        let normalizedTitle = title.lowercased()
        
        // Party-related terms
        let partyTerms = ["party", "bash", "celebration", "get-together", "hangout", "kickback",
                         "shindig", "gathering", "soirée", "mixer", "fest", "fiesta", "jam",
                         "event", "function", "meetup", "rager"]
        
        // Food-related terms
        let foodTerms = ["dinner", "lunch", "breakfast", "brunch", "feast", "banquet", "meal",
                        "supper", "potluck", "bbq", "barbecue", "picnic", "buffet", "luncheon"]
        
        // Special event terms
        let weddingTerms = ["wedding", "reception", "ceremony", "nuptial"]
        let birthdayTerms = ["birthday", "bday"]
        let holidayTerms = ["christmas", "thanksgiving", "holiday", "easter", "halloween",
                          "new year", "valentine", "st. patrick"]
        let businessTerms = ["meeting", "conference", "seminar", "workshop", "presentation",
                           "office", "corporate", "business", "board"]
        
        // Format title with proper capitalization
        let formattedTitle = title
            .split(separator: " ")
            .map { $0.prefix(1).uppercased() + $0.dropFirst().lowercased() }
            .joined(separator: " ")
        
        // Check matches and return appropriate emoji
        for term in partyTerms where normalizedTitle.contains(term) {
            return (formattedTitle, "🎉")
        }
        
        for term in foodTerms where normalizedTitle.contains(term) {
            return (formattedTitle, "🍽️")
        }
        
        for term in weddingTerms where normalizedTitle.contains(term) {
            return (formattedTitle, "💍")
        }
        
        for term in birthdayTerms where normalizedTitle.contains(term) {
            return (formattedTitle, "🎂")
        }
        
        for term in holidayTerms where normalizedTitle.contains(term) {
            return (formattedTitle, "🎄")
        }
        
        for term in businessTerms where normalizedTitle.contains(term) {
            return (formattedTitle, "📊")
        }
        
        // Default case - no specific category found
        return (formattedTitle, "🪑")
    }
}

// Create an orientation lock class to prevent sideways rotation
class OrientationLock: ObservableObject {
    static let shared = OrientationLock()
    
    @Published var orientation: UIInterfaceOrientationMask = .portrait
    
    private init() {
        // Set initial orientation based on device type
        self.orientation = UIDevice.current.userInterfaceIdiom == .pad ? .all : .portrait
    }
    
    func lockOrientation() {
        // Set orientation based on device type
        if UIDevice.current.userInterfaceIdiom == .pad {
            self.orientation = .all
        } else {
            self.orientation = .portrait
        }
    }
}

// Create a UIApplicationDelegate to set the orientation
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        return OrientationLock.shared.orientation
    }
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        if UIDevice.current.userInterfaceIdiom == .phone {
            // Force portrait orientation only for iPhone
            UIDevice.current.setValue(UIInterfaceOrientation.portrait.rawValue, forKey: "orientation")
        }
        return true
    }
}

// Enforce portrait orientation for scene configuration
class SceneDelegate: NSObject, UIWindowSceneDelegate {
    func windowScene(_ windowScene: UIWindowScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        if UIDevice.current.userInterfaceIdiom == .phone {
            // Apply portrait-only constraint for iPhone
            windowScene.requestGeometryUpdate(.iOS(interfaceOrientations: .portrait))
        }
    }
}

// Derive 1–2 letter initials from a full name (first + last), uppercased
fileprivate func computeInitials(from name: String) -> String {
    let parts = name
        .trimmingCharacters(in: .whitespacesAndNewlines)
        .split(separator: " ")
        .map { String($0) }
    if parts.isEmpty { return "" }
    let first = parts.first?.prefix(1) ?? ""
    let last = parts.count > 1 ? (parts.last?.prefix(1) ?? "") : ""
    return (first + last).uppercased()
}

struct ContentView: View {
    @Environment(\.showingTutorialInitially) private var showingTutorialInitially
    // Add state for profile editor
    @State private var showingProfileEditor = false
    @State private var editingPersonIndex: Int? = nil
    @State private var editingPersonColor: Color = .blue
    @State private var editingPersonName: String = ""
    @State private var selectedProfileColor: Color = .blue
    @State private var profileImage: UIImage? = nil
    @State private var editingPersonComment: String = ""
    
    // Add alerts for maximum people and duplicate person
    @State private var showingMaxPeopleAlert = false
    @State private var showingDuplicatePersonAlert = false
    @State private var duplicatePersonMessage = ""
    
    // Rest of existing properties
    @StateObject private var viewModel = SeatingViewModel()
    @State private var showingAddPerson = false
    @State private var showingGuestManager = false
    @State private var newPersonName = ""
    @State private var showingHistory = false
    @State private var showingSaveDialog = false
    @State private var arrangementTitle = ""
    @State private var isAddingPerson = false
    @State private var isLoading = true
    @State private var showingSettings = false
    @State private var showingDuplicateAlert = false
    @State private var showingTerms = false
    @State private var showingDeleteHistoryAlert = false
    @State private var showExportSheet = false
    @State private var showingSaveConfirmation = false
    @State private var showingImagePicker = false
    @State private var showingQRCodeSheet = false
    @State private var arrangementQRCode: UIImage?
    @State private var qrGenerationProgress: Double = 0.0
    @State private var shareModeIsLive: Bool = false
    @State private var liveAllowEditing: Bool = true
    @State private var hostDisplayName: String = UIDevice.current.name
    @State private var showingTableManager = false
    @Environment(\.colorScheme) var systemColorScheme
    @AppStorage("isDarkMode") private var isDarkMode = false
    @AppStorage("userName") private var userName = ""
    @AppStorage("profileImageData") private var profileImageData: Data?
    @AppStorage("appTheme") private var appTheme: String = "classic"
    @AppStorage("customAccentHex") private var customAccentHex: String = "#007AFF"
    @State private var showingTutorial = false
    @State private var showingContactsPicker = false
    @State private var showingImportFromList = false
    @State private var importStartIntent: ImportSourceIntent? = nil
    @State private var showImportDialog = false
    @State private var selectedContacts: Set<String> = []
    @State private var isAddButtonGlowing = false
    @State private var showingDeleteAllPeopleAlert = false
    // Snapshot the context when opening History for contextual back navigation
    @State private var historyOriginSnapshot: TableCollection? = nil
    @State private var historyOriginWasEmptyState: Bool = false
    @AppStorage("loginCount") private var loginCount: Int = 0
    @AppStorage("hapticsEnabled") private var hapticsEnabled: Bool = true
    @State private var isShowingShareSheet = false
    @State private var openedToast: String? = nil
    @State private var showPaywall: Bool = false
    
    // Define unique colors for up to 12 people
    private let personColors: [Color] = [
        .blue, .green, .orange, .purple, .pink,
        .red, .teal, .indigo, .mint, .cyan, .brown, .yellow // yellow is last
    ]
    
    private var overrideColorScheme: ColorScheme? {
        isDarkMode ? .dark : .light
    }
    
    // Consider the entire collection empty when all tables have zero people
    private var isAllTablesEmpty: Bool {
        viewModel.tableCollection.tables.values.allSatisfy { $0.people.isEmpty }
    }
    // Local background resolver to avoid cross-file symbol lookup
    private func localResolveThemeBackground(_ theme: String, isDark: Bool) -> Color {
        switch theme {
        case "ocean":
            return isDark ? Color(red: 0.03, green: 0.10, blue: 0.15) : Color(red: 0.88, green: 0.96, blue: 1.00)
        case "sunset":
            return isDark ? Color(red: 0.12, green: 0.06, blue: 0.10) : Color(red: 1.00, green: 0.95, blue: 0.90)
        case "forest":
            return isDark ? Color(red: 0.06, green: 0.10, blue: 0.08) : Color(red: 0.93, green: 0.98, blue: 0.94)
        case "midnight":
            return isDark ? Color(red: 0.05, green: 0.05, blue: 0.08) : Color(red: 0.94, green: 0.95, blue: 0.98)
        case "custom":
            let accentUI = UIColor(colorFromHex(customAccentHex))
            let mixed: UIColor = isDark ? mix(accentUI, UIColor.black, t: 0.85) : mix(accentUI, UIColor.white, t: 0.92)
            return Color(mixed)
        default:
            // Classic is pure white in light, system background in dark
            return isDark ? Color(.systemBackground) : Color.white
        }
    }
    
    private func onToggleDarkMode(_ newValue: Bool) {
        isDarkMode = newValue
    }
    
    private func onShowTerms() {
        showingTerms = true
    }
    
    private func onDeleteHistory() {
        showingDeleteHistoryAlert = true
    }

    private func showOpenedToast(_ text: String = "Opened Table") {
        withAnimation { openedToast = text }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
            withAnimation { openedToast = nil }
        }
    }
    
    // Removed @Binding var showWelcomeScreen: Bool
    @State var showWelcomeScreen: Bool = false // Revert to @State
    
    @State private var showingZoomedTable = false
    
    // Add state for permission alerts
    @State private var permissionDeniedPhoto = false
    @State private var permissionDeniedContacts = false
    
    // Add state for review prompt
    @AppStorage("reviewPromptCount") private var reviewPromptCount: Int = 0
    @AppStorage("hasPromptedForReview") private var hasPromptedForReview: Bool = false
    @AppStorage("lastReviewPromptDate") private var lastReviewPromptDate: TimeInterval = 0
    @AppStorage("significantActionsCount") private var significantActionsCount: Int = 0
    @AppStorage("hasSeenTutorial") private var hasSeenTutorial: Bool = false
    @Environment(\.heroTableNamespace) private var heroNamespace
    
    // Add forceShowTutorial parameter
    // var forceShowTutorial: Bool = false // Removed
    
    @State private var isEditingTableName = false
    
    // Add missing state variables for delete person alert
    @State private var personToDeleteIndex: Int? = nil
    @State private var showingDeletePersonAlert: Bool = false
    
    @FocusState private var isTableNameFieldFocused: Bool
    
    // Add @State private var showEffortlessScreen = false
    @State private var showEffortlessScreen = false
    
    @State private var showingPhotoPermissionRequest = false
    // Add state for delete confirmation
    @State private var showDeleteConfirmation = false
    
    // 1. Add @State private var showContactsImportPrompt = false to ContentView.
    @State private var showContactsImportPrompt = false
    
    // Add a loading state for image upload
    // @State private var isProfileImageLoading = false
    
    // Notifications onboarding ask state
    @AppStorage("notificationsEnabled") private var notificationsEnabled: Bool = false
    @AppStorage("hasAskedNotificationsOnboarding") private var hasAskedNotificationsOnboarding: Bool = false
    
    // Breadcrumb prompt when blocking navigation on empty table
    @State private var showAddGuestsBreadcrumb = false
    
    var body: some View {
        ZStack {
            emptyStateConditionalView
            mainContentConditionalView
            headerConditionalView
            loadingConditionalView
            savingDialogConditionalView
            tutorialView
        }
        .onAppear {
            registerOnboardingActions()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                if !showEffortlessScreen {
                    OnboardingController.shared.startIfNeeded(context: .mainTable)
                }
            }
        }
        .onChange(of: showEffortlessScreen) { newValue in
            if !newValue {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                    OnboardingController.shared.startIfNeeded(context: .mainTable)
                }
            }
        }
        .overlay(alignment: .top) {
            if let toast = openedToast {
                Text(toast)
                    .font(.caption)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(Color(.systemGray5)))
                    .padding(.top, 6)
                    .transition(.opacity)
            }
        }
        .fullScreenCover(isPresented: $showingZoomedTable) {
            ZoomedTableView(
                arrangement: $viewModel.currentArrangement,
                tableName: $viewModel.currentTableName,
                personColors: personColors,
                onClose: { showingZoomedTable = false },
                onEditProfile: { person in
                    if let index = viewModel.currentArrangement.people.firstIndex(where: { $0.id == person.id }) {
                        editingPersonIndex = index
                        editingPersonName = person.name
                        editingPersonComment = person.comment ?? ""
                        selectedProfileColor = getPersonColor(for: person.id, in: viewModel.currentArrangement)
                        profileImage = nil
                        if let imageData = viewModel.currentArrangement.people[index].profileImageData {
                            profileImage = UIImage(data: imageData)
                        }
                        showingProfileEditor = true
                    }
                }
            )
        }
        .fullScreenCover(isPresented: $showingGuestManager) {
            InlineGuestManagerView(
                viewModel: viewModel,
                isPresented: $showingGuestManager,
                onAddPerson: {
                    // Route to the existing Add Person flow in ContentView
                    newPersonName = ""
                    showingGuestManager = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                        showingAddPerson = true
                    }
                }
            )
            // Provide anchor collection within the sheet
            .overlayPreferenceValue(OnboardingAnchorPreferenceKey.self) { anchors in
                GeometryReader { proxy in
                    let _ = OnboardingController.shared.updateResolvedAnchors { key in
                        guard let a = anchors[key] else { return nil }
                        return proxy[a]
                    }
                    Color.clear
                }
            }
        }
        .sheet(isPresented: $showingAddPerson) {
            addPersonView
                .overlayPreferenceValue(OnboardingAnchorPreferenceKey.self) { anchors in
                    GeometryReader { proxy in
                        let _ = OnboardingController.shared.updateResolvedAnchors { key in
                            guard let a = anchors[key] else { return nil }
                            return proxy[a]
                        }
                        Color.clear
                    }
                }
        }
        .sheet(isPresented: $showingHistory) {
            HistoryView(
                viewModel: viewModel,
                dismissAction: { handleHistoryDismiss() }
            )
        }
        .fullScreenCover(isPresented: $showPaywall) {
            PaywallHost(isPresented: $showPaywall)
        }
        .onReceive(NotificationCenter.default.publisher(for: .showPaywall)) { _ in
            showPaywall = true
        }
        .sheet(
            isPresented: Binding(
                get: { importStartIntent != nil },
                set: { if !$0 { importStartIntent = nil } }
            ),
            onDismiss: { importStartIntent = nil }
        ) {
            // Present the same inline flow; bind presentation to whether intent is set
            ImportFromListView(
                viewModel: viewModel,
                isPresented: Binding(
                    get: { importStartIntent != nil },
                    set: { if !$0 { importStartIntent = nil } }
                ),
                startIntent: importStartIntent
            )
        }
        .sheet(isPresented: $showingSettings, onDismiss: {
                // Clean up when settings view is dismissed
                DispatchQueue.main.async {
                    viewModel.objectWillChange.send()
                }
            }) {
            settingsView
        }
        .alert("Duplicate Name", isPresented: $showingDuplicateAlert) {
            Button("OK", role: .cancel) { showingAddPerson = false }
        } message: {
            Text("A person with this name already exists in one of your tables. Please choose a different name.")
        }
        .alert("Maximum People Reached", isPresented: $showingMaxPeopleAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Maximum of 20 people per table reached. Please create a new table for additional guests.")
        }
        .alert(duplicatePersonMessage, isPresented: $showingDuplicatePersonAlert) {
            Button("OK", role: .cancel) { }
        }
        .alert("Delete All History?", isPresented: $showingDeleteHistoryAlert) {
            deleteHistoryAlertContent
        } message: {
            Text("Are you sure you want to delete all saved arrangements?")
        }
        .sheet(isPresented: $showExportSheet, onDismiss: {
            // Do not reset the current table when the share/export view is dismissed without tapping Done
            showExportSheet = false
        }) {
            NavigationView {
                AllTablesExportView(
                    viewModel: viewModel,
                    showEffortlessScreen: $showEffortlessScreen,
                    showingTutorial: $showingTutorial,
                    parentExportItems: $exportItems,
                    parentIsShowingShareSheet: $isShowingShareSheet
                )
            }
        }
        .sheet(isPresented: $isShowingShareSheet, onDismiss: {
            isShowingShareSheet = false
            exportItems = []
        }) {
            if !exportItems.isEmpty {
                ActivityView(activityItems: exportItems)
            }
        }
        .sheet(isPresented: $viewModel.showingQRCodeSheet, onDismiss: {
            viewModel.showingQRCodeSheet = false
            // Reset QR code related state
            arrangementQRCode = nil
            // After QR, show only the empty state (not tutorial)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                showEffortlessScreen = true
            }
        }) {
            qrCodeShareView
        }
        .onChange(of: showExportSheet) { newValue in
            if newValue == false {
                showExportSheet = false
            }
        }
        .sheet(isPresented: $showingTerms) {
            TermsView(onDismiss: { showingTerms = false })
        }
        .onAppear {
            // Ensure the empty state is active underneath the tutorial on first launch
            // to prevent a brief flash of the main table when the tutorial marks completion
            if showingTutorialInitially {
                showEffortlessScreen = true
            }
            NotificationCenter.default.addObserver(forName: Notification.Name("HideEffortlessScreen"), object: nil, queue: .main) { _ in
                showEffortlessScreen = false
            }
            // If no guests exist across all tables, show the Create Seating screen on launch
            if isAllTablesEmpty && !viewModel.isViewingHistory {
                showEffortlessScreen = true
            }
            isLoading = false
            // Only show tutorial if explicitly requested, not automatically
            // This prevents tutorial from showing when user resets data
            
            // Add observers for max people and duplicate person alerts
            setupNotificationObservers()
            
            // Reset review prompt counter annually (following Apple guidelines)
            resetReviewPromptCounterIfNeeded()
            
            loginCount += 1
            NotificationCenter.default.addObserver(forName: .shareLinkImportCompleted, object: nil, queue: .main) { note in
                if let arrangement = note.userInfo?["arrangement"] as? SeatingArrangement {
                    Task { @MainActor in
                        viewModel.currentArrangement = arrangement
                        viewModel.currentTableName = arrangement.title
                        viewModel.isViewingHistory = true
                        showOpenedToast("Imported \(arrangement.title)")
                        presentImportChoice(arrangement: arrangement)
                    }
                }
            }
            NotificationCenter.default.addObserver(forName: .shareLinkError, object: nil, queue: .main) { note in
                let message = (note.userInfo?["message"] as? String) ?? "Invalid link"
                openedToast = message
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) { openedToast = nil }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("ReturnToWelcomeAfterDataDelete"))) { _ in
            // Dismiss settings and return to effortless screen
            showingSettings = false
            resetAndShowWelcomeScreen()
        }
        // When tables are created from Import From List or similar flows, force showing the main table view
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("HideEffortlessScreen"))) { _ in
            showEffortlessScreen = false
        }
        // React only when the hasSeenTutorial flag itself changes
        .onChange(of: hasSeenTutorial) { newValue in
            if newValue {
                if !showEffortlessScreen {
                    showEffortlessScreen = true
                }
                showingTutorial = false
            }
        }
        // Add sheet for profile editor
        .sheet(isPresented: $showingProfileEditor) {
            profileEditorView
                .ignoresSafeArea(.keyboard)
                .onTapGesture {
                    // Dismiss keyboard when tapping outside
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: showingSaveDialog)
        .sheet(isPresented: $showingImagePicker) {
            Group {
                switch PHPhotoLibrary.authorizationStatus(for: .readWrite) {
                case .authorized, .limited:
                    ImagePicker(image: $profileImage)
                case .notDetermined:
                    RequestPhotoAccessView(onComplete: { granted in
                        if granted {
                            showingImagePicker = true
                    } else {
                            permissionDeniedPhoto = true
                        }
                    })
                default:
                    EmptyView()
                }
            }
        }
        .alert("Photo Access Needed", isPresented: $permissionDeniedPhoto) {
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Seat Maker does not have access to your photos. To enable access, go to Settings > Privacy > Photos and turn on Photos for Seat Maker.")
        }
        .sheet(isPresented: $showingContactsPicker, onDismiss: {
            // Only reset contacts loading state here
            DispatchQueue.main.async {
                viewModel.isLoadingContacts = false
                showingContactsPicker = false
            }
        }) {
            ContactsPickerView(
                contacts: viewModel.contacts,
                onSelect: { selected in
                    DispatchQueue.main.async {
                        for name in selected {
                            let allPeopleNames = viewModel.tableCollection.tables.values.flatMap { $0.people.map { $0.name.lowercased() } }
                            let currentTableNames = viewModel.currentArrangement.people.map { $0.name.lowercased() }
                            let allNames = Set(allPeopleNames + currentTableNames)
                            if allNames.contains(name.lowercased()) {
                                print("Duplicate contact skipped: \(name)")
                            } else {
                                viewModel.addPerson(name: name)
                            }
                        }
                        viewModel.suggestedNames = []
                        showingContactsPicker = false
                        viewModel.isLoadingContacts = false
                        showingAddPerson = false // Dismiss add person view and return to main screen
                        showEffortlessScreen = false // Always show main table after import
                    }
                },
                onSmartSeating: { selected in
                    DispatchQueue.main.async {
                        viewModel.smartCreateTables(from: Array(selected))
                        viewModel.suggestedNames = []
                        showingContactsPicker = false
                        viewModel.isLoadingContacts = false
                        showingAddPerson = false
                        showEffortlessScreen = false
                    }
                }
            )
        }
        .sheet(isPresented: $showingHistory) {
            HistoryView(
                viewModel: viewModel,
                dismissAction: { handleHistoryDismiss() }
            )
        }
            // Removed automatic reset after sharing; preserving current table unless user taps Done
        // Add the delete person confirmation alert (place near other alerts in the view modifiers chain):
        .alert("Delete Person?", isPresented: $showingDeletePersonAlert) {
            Button("Delete", role: .destructive) {
                if let index = personToDeleteIndex {
                    viewModel.removePerson(at: index)
                    personToDeleteIndex = nil
                }
            }
            Button("Cancel", role: .cancel) {
                personToDeleteIndex = nil
            }
        } message: {
            Text("Are you sure you want to delete this person from the table?")
        }
        // Add a specific observer for when the tutorial is no longer showing
        .onChange(of: showingTutorial) { newValue in
            if newValue == false {
                // Tutorial has just been dismissed - ensure we go directly to effortless screen
                DispatchQueue.main.async {
                self.showEffortlessScreen = true
                }
            }
        }
        .sheet(isPresented: $showingPhotoPermissionRequest) {
            RequestPhotoAccessView(onComplete: { granted in
                showingPhotoPermissionRequest = false
                if granted {
                    showingImagePicker = true
                } else {
                    permissionDeniedPhoto = true
                }
            })
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(image: $profileImage)
        }
        // Add state for delete confirmation
        .alert("Delete Table", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                viewModel.deleteCurrentTable()
            }
        } message: {
            Text("Are you sure you want to delete this table? This action cannot be undone.")
        }
        // 1. Update permission denied alerts for Contacts and Photos
        .alert("Contacts Access Needed", isPresented: $permissionDeniedContacts) {
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Seat Maker does not have access to your contacts. To enable access, go to Settings > Privacy > Contacts and turn on Contacts for Seat Maker.")
        }
        // 3. Add .sheet(isPresented: $showContactsImportPrompt) { RequestContactsAccessView { _ in showContactsImportPrompt = false; showEffortlessScreen = false } } to ContentView's body.
        .sheet(isPresented: $showContactsImportPrompt) { RequestContactsAccessView { _ in showContactsImportPrompt = false; showEffortlessScreen = false } }
    }
    
    // Extracted helper to reduce type-check complexity
    private func composedEventTitle() -> String {
        let eventTitle = viewModel.currentArrangement.eventTitle
        let hasEventTitle = eventTitle?.isEmpty == false
        let fallbackTitle = arrangementTitle.isEmpty ? viewModel.currentArrangement.title : arrangementTitle
        let displayTitle = hasEventTitle ? (eventTitle ?? "") : fallbackTitle
        let finalTitle = displayTitle.isEmpty ? "New Arrangement" : displayTitle
        let (formattedTitle, emoji) = UIHelpers.formatEventTitle(finalTitle)
        return "\(emoji) \(formattedTitle)"
    }
    
    // Add a function to set up notification observers
    private func setupNotificationObservers() {
        NotificationCenter.default.addObserver(
            forName: Notification.Name("ShowMaxPeopleAlert"),
            object: nil,
            queue: .main
        ) { notification in
            showingMaxPeopleAlert = true
        }
        
        NotificationCenter.default.addObserver(
            forName: Notification.Name("ShowDuplicatePersonAlert"),
            object: nil,
            queue: .main
        ) { notification in
            if let message = notification.userInfo?["message"] as? String {
                duplicatePersonMessage = message
                showingDuplicatePersonAlert = true
            }
        }
    }
    
    // Present Settings reliably by dismissing any other sheets first, then toggling the flag
    private func openSettingsSafely() {
        // Dismiss potentially conflicting presentations
        showingContactsPicker = false
        isShowingShareSheet = false
        showExportSheet = false
        showingProfileEditor = false
        showingHistory = false
        showingAddPerson = false
        showingImagePicker = false
        showingTerms = false
        viewModel.showingQRCodeSheet = false
        importStartIntent = nil
        showingGuestManager = false
        
        // Defer presentation slightly to allow previous dismissals to settle
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation(.easeInOut(duration: 0.2)) {
                showingSettings = true
            }
        }
    }
    private var headerView: some View {
        VStack(spacing: 2) {
            if !viewModel.isViewingHistory {
                Spacer().frame(height: 16)
            }
            ZStack {
                // Left and right controls
                HStack {
                    // Left side: Back when viewing history, otherwise Settings (if appropriate)
                    if viewModel.isViewingHistory {
                        Button(action: {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
                                triggerHaptic()
                                handleHistoryBack()
                            }
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 20, weight: .semibold))
                                Text("Back")
                                    .font(.system(size: 17, weight: .semibold))
                            }
                            .frame(height: 48)
                        }
                        .padding(.top, 3)
                    } else if !showingTutorial && !showEffortlessScreen && !(viewModel.currentArrangement.people.isEmpty && viewModel.tableCollection.tables.isEmpty && viewModel.tableCollection.currentTableId == 0) && UserDefaults.standard.bool(forKey: "hasSeenTutorial") {
                        Button(action: {
                            triggerHaptic()
                            AdsManager.shared.showInterstitialThen {
                                openSettingsSafely()
                            }
                        }) {
                            Image(systemName: "gear")
                                .font(.system(size: 28))
                                .foregroundColor(.accentColor)
                                .frame(width: 48, height: 48)
                        }
                        .accessibilityIdentifier("btn.settings")
                        .onboardingAnchor(.settings)
                        .padding(.top, 3)
                    } else {
                        Spacer().frame(width: 40)
                    }
                    Spacer()
                    if !showingTutorial && !(viewModel.currentArrangement.people.isEmpty && viewModel.tableCollection.tables.isEmpty && viewModel.tableCollection.currentTableId == 0) && UserDefaults.standard.bool(forKey: "hasSeenTutorial") {
                        HStack(spacing: 4) {
                            Button(action: { DispatchQueue.main.async {
                                triggerHaptic()
                                AdsManager.shared.showInterstitialThen {
                                    showingTableManager = true
                                    OnboardingController.shared.advanceIfOn(anchor: .tableManager)
                                }
                            } }) {
                                Image(systemName: "rectangle.grid.2x2")
                                    .font(.system(size: 24))
                                    .foregroundColor(.accentColor)
                                    .frame(width: 40, height: 40)
                                    .accessibilityLabel("View tables")
                            }
                            .accessibilityIdentifier("btn.tableManager")
                            .onboardingAnchor(.tableManager)
                            .offset(y: 2) // move the icon down two pixels
                            Button(action: { DispatchQueue.main.async { triggerHaptic(); showingSaveDialog = true }; if OnboardingController.shared.isActive { DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { OnboardingController.shared.advanceIfOn(anchor: .share) } } }) {
                                Image(systemName: "square.and.arrow.up")
                                    .font(.system(size: 24))
                                    .foregroundColor(.accentColor)
                                    .frame(width: 40, height: 40)
                            }
                            .accessibilityIdentifier("btn.share")
                            .onboardingAnchor(.share)
                            .disabled(viewModel.currentArrangement.people.isEmpty && viewModel.tableCollection.tables.isEmpty)
                            .opacity((viewModel.currentArrangement.people.isEmpty && viewModel.tableCollection.tables.isEmpty) ? 0.5 : 1)
                        }
                        .padding(.top, 6) // default
                    } else {
                        Spacer().frame(width: 40)
                    }
                }
                // Centered title independent of left/right widths
                if !showingTutorial && !showEffortlessScreen && !(viewModel.currentArrangement.people.isEmpty && viewModel.tableCollection.tables.isEmpty && viewModel.tableCollection.currentTableId == 0) && UserDefaults.standard.bool(forKey: "hasSeenTutorial") {
                    Group {
                        if let userName = UserDefaults.standard.string(forKey: "userName"), !userName.isEmpty {
                            Text("\(userName)'s Tables")
                        } else {
                            Text("Your Tables")
                        }
                    }
                    .font(.system(size: 22, weight: .bold))
                    .padding(.top, 8)
                    .frame(maxWidth: .infinity, alignment: .center)
                }
            }
            .padding(.horizontal)
            .padding(.top, 3)
            .padding(.bottom, 3)
            Spacer()
        }
    }
    
    private var loadingView: some View {
        ZStack {
            Color(.systemBackground).opacity(0.7)
            ProgressView()
                .scaleEffect(1.5)
        }
    }
    private var saveDialogContent: some View {
        ZStack {
            VStack(spacing: 16) {
                Text("Name this Event")
                    .font(.title3.bold())
                    .padding(.bottom, 4)
                
                Text("What type of gathering is this for?")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.bottom, 4)
                
                TextField("Event Name (e.g. Smith Dinner)", text: $arrangementTitle)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)
                    .background(Color.clear)
                    .autocapitalization(.words)
                    .onAppear {
                        arrangementTitle = ""
                    }
                
                // Suggestion buttons for quick selection
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(["Party 🎉", "Dinner 🍽️", "Wedding 💍", "Meeting 📊", "Birthday 🎂", "Celebration 🎊"], id: \.self) { suggestion in
                            Button(action: {
                                arrangementTitle = suggestion.components(separatedBy: " ").first ?? suggestion
                            }) {
                                Text(suggestion)
                                    .font(.caption)
                                    .padding(.vertical, 6)
                                    .padding(.horizontal, 10)
                                    .background(
                                        Capsule()
                                            .fill(Color.blue.opacity(0.1))
                                            .overlay(
                                                Capsule()
                                                    .stroke(Color.accentColor.opacity(0.3), lineWidth: 1)
                                            )
                                    )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.bottom, 8)
                
                HStack {
                    Button("Cancel", role: .cancel) {
                        triggerHaptic()
                        arrangementTitle = ""
                        showingSaveDialog = false
                    }
                    .buttonStyle(.bordered)
                    .tint(.blue)
                    
                    Button("Save") {
                        triggerHaptic()
                        let eventToSave = arrangementTitle.isEmpty ? nil : arrangementTitle
                        viewModel.currentArrangement.eventTitle = eventToSave
                        // Do NOT set currentArrangement.title or currentTableName here
                        viewModel.saveCurrentTableState()
                        viewModel.saveCurrentArrangement()
                        arrangementTitle = ""
                        showingSaveDialog = false
                        showExportSheet = true
                        // Trigger review prompt after saving (positive action)
                        maybePromptForReview()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(arrangementTitle.isEmpty)
                }
                .padding(.top, 8)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        Color(.systemBackground)
                            .opacity(0.95)
                            .shadow(.inner(color: Color.primary.opacity(0.2), radius: 1))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.accentColor.opacity(0.5), lineWidth: 2.5) // Increased border width by 2 pixels
                    )
            )
            .shadow(color: Color.black.opacity(0.25), radius: 15, x: 0, y: 5)
            .frame(width: 340)
        }
    }
    
    private var deleteHistoryAlertContent: some View {
        Group {
            Button("Delete", role: .destructive) {
                viewModel.deleteAllHistory()
            }
            Button("Cancel", role: .cancel) { }
        }
    }
    
    private var mainContent: some View {
        VStack(spacing: 10) {
            // History back button is now integrated in header when viewing history
            // Show tutorial if necessary (first launch)
            if !UserDefaults.standard.bool(forKey: "hasSeenTutorial") && showingTutorial {
                TutorialView(onComplete: {
                    // Don't automatically show add person popup after tutorial
                    UserDefaults.standard.set(true, forKey: "hasSeenTutorial")
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                        showingTutorial = false
                        // Ensure we go directly to effortless screen without showing main table
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        showEffortlessScreen = true
                        }
                    }
                })
                .edgesIgnoringSafeArea(.all)
            } else if showEffortlessScreen || (isAllTablesEmpty && !viewModel.isViewingHistory) {
                // Show the empty state view (Effortless screen) if showEffortlessScreen is true,
                // or if the table data is empty and we're not in history view
                emptyStateView
                    .preferredColorScheme(overrideColorScheme)
                    .toolbar {
                        // Hide settings and share buttons on welcome screen
                        ToolbarItem(placement: .navigationBarTrailing) { EmptyView() }
                        ToolbarItem(placement: .navigationBarLeading) { EmptyView() }
                    }
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
            } else {
                // Otherwise, show the main content (table, history, settings, etc.)
                mainContentContent // Rename to avoid confusion with private var mainContent
                    .padding(.bottom, 20)
                    .preferredColorScheme(overrideColorScheme)
                    .offset(y: -2) // Move the main content (including the table) up by 2 pixels
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("TutorialDismissed"))) { _ in
            showingTutorial = false
        }
    }
    
    // Extract the content originally inside mainContent to a new private var
    private var mainContentContent: some View {
        VStack(spacing: 10) {
            // Content that was inside the old mainContent private var
            // History back button is now integrated in header when viewing history
            // This part is now handled by the top-level conditional in 'body'
            // No need to repeat the tutorial/emptyState/tableAndPeople logic here
            
            tableAndPeopleView // This is the actual main content view
            
        }
    }
    
    // Removed legacy historyBackButton; handled in header now
    
    private var tableAndPeopleView: some View {
        VStack(spacing: 10) {
            if !viewModel.isViewingHistory {
                Spacer().frame(height: 5)
            }
            VStack(spacing: 10) {
                Spacer().frame(height: 18)
                Spacer().frame(height: 8)
                // Main content/table area with navigation controls
                ZStack {
                    // The table view with swipe gesture applied directly to this container
                VStack {
                    ZStack {
                        TableView(
                            arrangement: viewModel.currentArrangement,
                            getPersonColor: { id in getPersonColor(for: id, in: viewModel.currentArrangement) },
                            onPersonTap: { person in
                                // Handle person tap to edit profile
                                if let index = viewModel.currentArrangement.people.firstIndex(where: { $0.id == person.id }) {
                                    editingPersonIndex = index
                                    editingPersonName = person.name
                                    editingPersonComment = person.comment ?? ""
                                    selectedProfileColor = getPersonColor(for: person.id, in: viewModel.currentArrangement)
                                    profileImage = nil
                                    if let imageData = viewModel.currentArrangement.people[index].profileImageData {
                                        profileImage = UIImage(data: imageData)
                                    }
                                    showingProfileEditor = true
                                }
                            }
                        )
                        .frame(maxWidth: 253, maxHeight: 211) // Keep these exact dimensions
                        
                            // Table name button always on top, centered
                            // Center table name inside the table
                            VStack {
                                Spacer().frame(height: getTableNameYPosition() - 10)
                                if !viewModel.hideTableNumber {
                                    Text(viewModel.currentTableName.isEmpty ? String(format: NSLocalizedString("Table %d", comment: "Default table name"), viewModel.tableCollection.currentTableId + 1) : viewModel.currentTableName)
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(.primary)
                                        .lineLimit(1)
                                        .truncationMode(.tail)
                                        .padding(.horizontal, 10)
                                }
                                Spacer()
                            }
                        }
                        .padding(.top, 14) // Was 10, now 14 (move down 4 pixels)
                    .padding(.bottom, 8)
                    .frame(width: 253, height: 211, alignment: .center) // Fixed dimensions
                    }
                    // Add swipe gesture to the entire ZStack container
                    .gesture(
                        DragGesture(minimumDistance: 20)
                            .onEnded { value in
                                if value.translation.width > 50 && viewModel.tableCollection.currentTableId > 0 {
                                    // Right to left swipe - navigate left
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        viewModel.saveCurrentTableState()
                                        viewModel.navigateToTable(direction: .left)
                                    }
                                } else if value.translation.width < -50 {
                                    // Left to right swipe - navigate right
                                    let shouldBlock = viewModel.currentArrangement.people.isEmpty && !viewModel.hasPeopleInFutureTables()
                                    if shouldBlock {
                                        withAnimation(.easeInOut(duration: 0.18)) { showAddGuestsBreadcrumb = true }
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
                                            withAnimation(.easeInOut(duration: 0.18)) { showAddGuestsBreadcrumb = false }
                                        }
                                    } else {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                            viewModel.saveCurrentTableState()
                                            viewModel.navigateToTable(direction: .right)
                                            // Prompt for name on new table
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                                if viewModel.currentTableName.isEmpty {
                                                    showNewTablePrompt = true
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                    )
                }
                .overlay(
                    // Left/Right navigation buttons as overlay for better touch response
                    HStack {
                        NavigationButton(
                            direction: .left,
                            tableShape: viewModel.currentArrangement.tableShape,
                            action: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    viewModel.saveCurrentTableState() // Save before navigating
                                    viewModel.navigateToTable(direction: .left)
                                }
                            },
                            isDisabled: viewModel.tableCollection.currentTableId == 0
                        )
                        .frame(width: 60, height: 60)
                        Spacer()
                        NavigationButton(
                            direction: .right,
                            tableShape: viewModel.currentArrangement.tableShape,
                            action: {
                                // Block only if current is empty AND all future tables are empty
                                let shouldBlock = viewModel.currentArrangement.people.isEmpty && !viewModel.hasPeopleInFutureTables()
                                if shouldBlock {
                                    withAnimation(.easeInOut(duration: 0.18)) { showAddGuestsBreadcrumb = true }
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
                                        withAnimation(.easeInOut(duration: 0.18)) { showAddGuestsBreadcrumb = false }
                                    }
                                } else {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        viewModel.saveCurrentTableState() // Save before navigating
                                        viewModel.navigateToTable(direction: .right)
                                        // Ensure we register the new table with system and prompt for name
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                            if viewModel.currentTableName.isEmpty {
                                                showNewTablePrompt = true
                                            }
                                        }
                                    }
                                }
                            },
                            isDisabled: false
                        )
                        .frame(width: 60, height: 60)
                    }
                    .padding(.horizontal, viewModel.currentArrangement.tableShape == .round ? 60 : 40) // wider for round tables
                    .padding(.top, getTableNameYPosition() - 75) // Match the vertical center of the table name
                )
                // Breadcrumb message when trying to navigate with empty table
                .overlay(alignment: .top) {
                    if showAddGuestsBreadcrumb {
                        Text("Add guests first")
                            .font(.caption.bold())
                            .foregroundColor(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Capsule().fill(Color.red.opacity(0.9)))
                            .shadow(color: Color.red.opacity(0.25), radius: 8, x: 0, y: 4)
                            .padding(.top, 6)
                            .transition(.move(edge: .top).combined(with: .opacity))
                    }
                }
            
            // Table ID indicator - made completely invisible
            ZStack {
                // Invisible spacer to maintain layout spacing
                Color.clear
                    .frame(height: 40) // Match the height of the visible table number
            }
            
            tableShapeSelector
                    .padding(.vertical, 4)
                    .padding(.top, -11) // Changed from -10 to -15 to move 5 pixels higher
                .frame(maxWidth: .infinity, alignment: .center)
                .accessibilityIdentifier("btn.shapeSelector")
                .onboardingAnchor(.shapeSelector)
            
            // People list with adjusted padding
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) { // Header row for People and manager icon
                    HStack(spacing: 8) {
                        Image(systemName: "person.fill")
                            .foregroundColor(.secondary)
                            .font(.headline)
                        Text("People:")
                            .font(.headline)
                            .dynamicTypeSize(.xSmall ... .accessibility5)
                            .minimumScaleFactor(0.7)
                            .lineLimit(1)
                            .accessibilityLabel("People List")
                    }
                    Spacer()
                    Button(action: { DispatchQueue.main.async { showingGuestManager = true; OnboardingController.shared.advanceIfOn(anchor: .managePeople) } }) {
                        Text("Manage")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.blue)
                            .accessibilityLabel("Open Guest Manager")
                    }
                    .accessibilityIdentifier("btn.managePeople")
                    .onboardingAnchor(.managePeople)
                }
                    .font(.headline)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 12)
                    .padding(.bottom, 2)
                        .padding(.top, -10) // Changed from -3 to -10 to move 7 pixels higher
                
                ZStack(alignment: .bottom) {
                    ScrollView {
                        LazyVStack(spacing: 8) {
                            ForEach(Array(viewModel.currentArrangement.people.enumerated()), id: \.element.id) { index, person in
                                MiniPersonRow(
                                    index: index,
                                    person: person,
                                    seatNumber: viewModel.currentArrangement.seatAssignments[person.id],
                                    color: getPersonColor(for: person.id, in: viewModel.currentArrangement),
                                    isLocked: person.isLocked,
                                    onNameUpdate: { newName in
                                        DispatchQueue.main.async {
                                            if let realIndex = viewModel.currentArrangement.people.firstIndex(where: { $0.id == person.id }) {
                                                viewModel.currentArrangement.people[realIndex].name = newName
                                                // Persist immediately so Table Manager reflects the change
                                                viewModel.saveCurrentTableState()
                                                viewModel.saveTableCollection()
                                            }
                                        }
                                    },
                                    onEdit: {
                                        if let realIndex = viewModel.currentArrangement.people.firstIndex(where: { $0.id == person.id }) {
                                            editingPersonIndex = realIndex
                                            editingPersonName = person.name
                                            editingPersonComment = person.comment ?? ""
                                            selectedProfileColor = getPersonColor(for: person.id, in: viewModel.currentArrangement)
                                            profileImage = nil
                                            if let imageData = viewModel.currentArrangement.people[realIndex].profileImageData {
                                                profileImage = UIImage(data: imageData)
                                            }
                                            showingProfileEditor = true
                                        }
                                    },
                                    onLockToggle: {
                                        triggerHaptic(.medium)
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                            viewModel.toggleLock(for: person.id)
                                        }
                                    },
                                    viewModel: viewModel
                                )
                                .draggable(person) {
                                    MiniPersonRowPreview(
                                        person: person,
                                        seatNumber: viewModel.currentArrangement.seatAssignments[person.id],
                                        color: getPersonColor(for: person.id, in: viewModel.currentArrangement),
                                        isLocked: person.isLocked,
                                        viewModel: viewModel
                                    )
                                }
                                .dropDestination(for: Person.self) { items, _ in
                                    guard let dropped = items.first,
                                          let sourceIndex = viewModel.currentArrangement.people.firstIndex(where: { $0.id == dropped.id }) else { return false }
                                    if sourceIndex == index { return true }
                                    let toIndex = index >= sourceIndex ? index + 1 : index
                                    viewModel.movePerson(from: IndexSet(integer: sourceIndex), to: toIndex)
                                    return true
                                }
                            }
                        }
                        .padding(.vertical, 6)
                        .padding(.horizontal, 6)
                        // Also allow dropping at the end of the list
                        .dropDestination(for: Person.self) { items, _ in
                            guard let dropped = items.first,
                                  let sourceIndex = viewModel.currentArrangement.people.firstIndex(where: { $0.id == dropped.id }) else { return false }
                            let toIndex = viewModel.currentArrangement.people.count
                            viewModel.movePerson(from: IndexSet(integer: sourceIndex), to: toIndex)
                            return true
                        }
                    }
                    .frame(maxWidth: .infinity, minHeight: 140)
                }
                .padding(5) // Added padding to push content away from border
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.gray.opacity(isDarkMode ? 0.5 : 0.3), lineWidth: isDarkMode ? 2.5 : 2) // Increased border width by 2 pixels
                )
            }
            .padding(.horizontal, 8)
                .padding(.top, 2) // Changed from -2 to 2 to move down 4 more pixels
            
            // Add/Delete buttons floating above Shuffle/History, with less space and smaller size
			ZStack {
				AddDeleteButtonsBar(
					viewModel: viewModel,
					showingAddPerson: $showingAddPerson,
					showingDeleteAllPeopleAlert: $showingDeleteAllPeopleAlert,
					onAdd: {
						triggerHaptic(.medium)
						newPersonName = ""
						showingAddPerson = true
					},
					onClearAll: {
						viewModel.currentArrangement.people.removeAll()
						viewModel.currentArrangement.seatAssignments.removeAll()
						viewModel.saveCurrentTableState()
					}
				)
				.padding(.bottom, 4)
				.padding(.top, 2)
				.frame(maxWidth: .infinity)
				.offset(y: 0)
			}
            .frame(maxWidth: .infinity)
            .zIndex(2)

            Spacer(minLength: 10) // Slightly more space before Shuffle/History

            // Shuffle/History area at the bottom, themed background
            VStack(spacing: 12) {
                Button(action: { 
                    triggerHaptic(.medium)
                    withAnimation(.interactiveSpring(response: 0.5, dampingFraction: 0.78, blendDuration: 0.2)) { 
                        viewModel.shuffleSeats()
                        // Trigger review prompt after positive action
                        maybePromptForReview()
                    }
                }) {
                    HStack(spacing: 10) {
                        Image(systemName: "dice.fill")
                            .font(.system(size: 22, weight: .bold)) // Increased from 18
                        Text("SHUFFLE")
                            .font(.system(size: 20, weight: .bold)) // Increased from 16
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54) // Increased from 44
                    .background(
                        RoundedRectangle(cornerRadius: 22)
                            .fill(Color.accentColor)
                            .shadow(color: Color.accentColor.opacity(0.18), radius: 8, x: 0, y: 2)
                    )
                }
                .accessibilityLabel("Shuffle")
                .accessibilityIdentifier("btn.shuffle")
                .accessibilityAddTraits(.isButton)
                .onboardingAnchor(.shuffle)
                .disabled(viewModel.currentArrangement.people.isEmpty)
                .opacity(viewModel.currentArrangement.people.isEmpty ? 0.5 : 1)

                Button(action: {
                    triggerHaptic(.medium)
                    // Snapshot origin before presenting History
                    historyOriginSnapshot = viewModel.tableCollection
                    historyOriginWasEmptyState = showEffortlessScreen
                    showingHistory = true
                }) {
                    HStack(spacing: 10) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 20, weight: .bold)) // Increased from 18
                        Text("HISTORY")
                            .font(.system(size: 20, weight: .bold)) // Increased from 18
                    }
                    .foregroundColor(.blue)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44) // Increased from 56
                    .background(
                        RoundedRectangle(cornerRadius: 22)
                            .fill(Color(.systemBackground).opacity(isDarkMode ? 0 : 1))
                            .shadow(color: Color.accentColor.opacity(0.10), radius: 6, x: 0, y: 1)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 22)
                            .stroke(Color.accentColor, lineWidth: 2)
                    )
                }
                .accessibilityLabel("History")
                .accessibilityAddTraits(.isButton)
                .disabled(viewModel.savedArrangements.isEmpty)
                .opacity(viewModel.savedArrangements.isEmpty ? 0.5 : 1)
                .offset(y: -1) // Move 3 pixels higher (was -3)
            }
            .padding(.horizontal, 16) // Less padding
            .padding(.bottom, 18) // Was 12, now 18 (move down 6px)
            .background(
                localResolveThemeBackground(appTheme, isDark: isDarkMode)
                    .opacity(0.98)
                    .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: -2)
            )
            .cornerRadius(18)
            .frame(maxWidth: .infinity)
            .zIndex(1)
        }
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity, alignment: .center)
        // Present Table Manager
        .sheet(isPresented: $showingTableManager) {
            TableManagerView(
                viewModel: viewModel,
                isPresented: $showingTableManager,
                onOpenTable: { id in
                    viewModel.switchToTable(id: id)
                    showingTableManager = false
                    // If onboarding is highlighting the table manager, advance when destination appears
                    OnboardingController.shared.advanceIfOn(anchor: .tableManager)
                }
            )
        }
            .alert("Name This Table", isPresented: $showingTableNamePrompt) {
            TextField("Table Name", text: $tempTableName)
                .autocapitalization(.words)
            
            Button("Cancel", role: .cancel) {
                DispatchQueue.main.async { showingTableNamePrompt = false }
            }
            
            Button("Save") {
                let trimmed = tempTableName.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmed.isEmpty {
                    viewModel.currentTableName = trimmed
                    viewModel.currentArrangement.title = trimmed
                    viewModel.saveCurrentTableState()
                }
                tempTableName = ""
                DispatchQueue.main.async { showingTableNamePrompt = false }
            }
        } message: {
            Text("What would you like to call this table?")
        }
            .alert("Name This Table", isPresented: $showNewTablePrompt) {
                TextField("Table Name", text: $tempTableName)
                .autocapitalization(.words)
            
            Button("Save", action: {
                if !tempTableName.isEmpty {
                    viewModel.currentTableName = tempTableName
                } else {
                    viewModel.currentTableName = "Table \(viewModel.tableCollection.currentTableId + 1)"
                }
                viewModel.saveCurrentTableState()
                tempTableName = ""
                 // Safely dismiss the alert
                DispatchQueue.main.async { showNewTablePrompt = false }
            })
        } message: {
                Text("What type of gathering is this for?")
        }
        .alert("Export Complete", isPresented: $showExportCompleteAlert) {
            Button("Keep Tables", role: .cancel) {}
            
                Button("Return to Welcome Screen", role: .destructive) {
                resetAndShowWelcomeScreen()
            }
        } message: {
            let tableCount = viewModel.tableCollection.tables.count
            let peopleCount = viewModel.tableCollection.tables.values.reduce(0) { $0 + $1.people.count }
            let tablesText = tableCount == 1 ? "1 table" : "\(tableCount) tables"
            let peopleText = peopleCount == 1 ? "1 person" : "\(peopleCount) people"
                return Text("Successfully exported \(tablesText) with \(peopleText). Your arrangement has been saved to history. Would you like to return to the welcome screen?")
        }
        }
        .padding(.top, !viewModel.isViewingHistory ? 11 : -7) // Was 18/0, now 11/-7 (move up 7px)
        // 4. In all photo adding logic (profile image, etc.), always check/request permission and handle denied/limited states.
        .sheet(isPresented: $showContactsImportPrompt) { RequestContactsAccessView { _ in showContactsImportPrompt = false; showEffortlessScreen = false } }
    }
    
    // State for table name prompt
    @State private var showingTableNamePrompt = false
    @State private var tempTableName = ""
    @State private var showNewTablePrompt = false
    
    private func showTableNamePrompt() {
        tempTableName = viewModel.currentTableName
        showingTableNamePrompt = true
    }
    
    // Function to reset and go back to welcome screen
    private func resetAndShowWelcomeScreen() {
        // Clear all tables
        viewModel.tableCollection.tables = [:]
        viewModel.tableCollection.currentTableId = 0
        viewModel.tableCollection.maxTableId = 0
        // Clear current arrangement
        viewModel.currentArrangement = SeatingArrangement(
            title: "New Arrangement",
            people: [],
            tableShape: viewModel.defaultTableShape
        )
        viewModel.currentTableName = ""
        // Ensure we're not in viewing history mode
        viewModel.isViewingHistory = false
        // Save the cleared state
        viewModel.saveTableCollection()
        // Keep hasSeenTutorial as true to show welcome screen, not tutorial
        UserDefaults.standard.set(true, forKey: "hasSeenTutorial")
        // Reset all relevant state for consistent layout
        showingProfileEditor = false
        editingPersonIndex = nil
        editingPersonName = ""
        editingPersonComment = ""
        profileImage = nil
        // Show the effortless screen instead of tutorial
        showEffortlessScreen = true
        showingTutorial = false
    }
    
    // Custom NavigationButton for animated positioning
    struct NavigationButton: View {
        let direction: NavigationDirection
        let tableShape: TableShape
        let action: () -> Void
        let isDisabled: Bool
        
        @State private var initialPosition = CGPoint.zero
        @State private var targetPosition = CGPoint.zero
        @State private var currentPosition = CGPoint.zero
        
        var arrowIcon: String {
            direction == .left ? "arrow.left" : "arrow.right"
        }
        
        var body: some View {
            Button(action: action) {
                Image(systemName: arrowIcon)
                    .font(.system(size: 26, weight: .semibold)) // Increased from 22
                    .foregroundColor(.blue)
                    .frame(width: 50, height: 50) // Increased from 44
                    .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle()) // Use plain style to improve tap response
            .disabled(isDisabled)
            .padding(direction == .left ? .trailing : .leading, getArrowPadding())
            .contentShape(Rectangle()) // Add another contentShape to ensure tappable area
            .onChange(of: tableShape) { newShape in
                // Animate position change when table shape changes
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    // Position will update due to getArrowPadding()
                }
            }
        }
        
        // Dynamic padding based on table shape - making arrows wider
        private func getArrowPadding() -> CGFloat {
            switch tableShape {
            case .round:
                return 185 // Increased from 160 to 185 for more separation
            case .rectangle:
                return direction == .left ? 50 : 55 // Moved right arrow left: was 60, now 55
            case .square:
                return 149
            }
        }
    }
    
    // Add a helper method for navigation buttons
    private func navigationButton(direction: NavigationDirection, icon: String) -> some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                viewModel.navigateToTable(direction: direction)
            }
        }) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.accentColor)
                .frame(width: 44, height: 44)
                .background(
                    Circle()
                        .fill(Color.accentColor.opacity(0.12))
                        .shadow(color: Color.accentColor.opacity(0.2), radius: 4, x: 0, y: 2)
                )
        }
        .disabled(direction == .left && viewModel.tableCollection.currentTableId == 0)
        .opacity(direction == .left && viewModel.tableCollection.currentTableId == 0 ? 0.5 : 1.0)
    }
    
    // Update the actionButtons to include the Export All Tables button
    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button(action: { triggerHaptic(.medium); withAnimation(.interactiveSpring(response: 0.5, dampingFraction: 0.78, blendDuration: 0.2)) { viewModel.shuffleSeats() } }) {
                HStack {
                    Image(systemName: "dice.fill")
                    Text("SHUFFLE")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.accentColor)
                        .shadow(color: Color.accentColor.opacity(0.3), radius: 8, x: 0, y: 4)
                )
            }
            .disabled(viewModel.currentArrangement.people.isEmpty)
            .opacity(viewModel.currentArrangement.people.isEmpty ? 0.5 : 1)
            .padding(.top, -37) // Was -30, now -37 (move up 7px)

            Button(action: {
                triggerHaptic(.medium)
                historyOriginSnapshot = viewModel.tableCollection
                historyOriginWasEmptyState = showEffortlessScreen
                showingHistory = true
            }) {
                HStack {
                    Image(systemName: "clock.arrow.circlepath")
                    Text("HISTORY")
                }
                .font(.headline)
                .foregroundColor(.accentColor)
                .frame(maxWidth: .infinity)
                .frame(height: 56) // Increased from 46 to 56 to meet minimum touch target
                .background(
                    RoundedRectangle(cornerRadius: 22)
                        .fill(Color(.systemBackground).opacity(isDarkMode ? 0 : 1))
                        .shadow(color: Color.accentColor.opacity(0.10), radius: 6, x: 0, y: 1)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 22)
                        .stroke(Color.accentColor, lineWidth: 2)
                )
            }
            .disabled(viewModel.savedArrangements.isEmpty)
            .opacity(viewModel.savedArrangements.isEmpty ? 0.5 : 1)

            Button(action: { triggerHaptic(.medium); showDeleteConfirmation = true }) {
                HStack {
                    Image(systemName: "trash")
                    Text("DELETE TABLE")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.red)
                        .shadow(color: Color.red.opacity(0.3), radius: 8, x: 0, y: 4)
                )
            }
            .disabled(viewModel.tableCollection.tables.isEmpty)
            .opacity(viewModel.tableCollection.tables.isEmpty ? 0.5 : 1)
        }
        .padding(.horizontal)
        .padding(.top, -10)
    }
    
    // Add a method to export all tables
    private func exportAllTables() {
        // Gate export behind Pro
        if !canUseUnlimitedFeatures() {
            showPaywall = true
            return
        }
        // Get comprehensive text for all tables
        let exportText = viewModel.exportAllTables()
        
        AdsManager.shared.showInterstitialThen {
            let activityVC = UIActivityViewController(
                activityItems: [exportText],
                applicationActivities: nil
            )
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let rootVC = windowScene.windows.first?.rootViewController {
                rootVC.present(activityVC, animated: true)
            }
        }
        
        // In export/share completion (e.g. after showing export sheet or successful export), increment reviewPromptCount and show review prompt if needed:
        maybePromptForReview()
    }
    
    private func maybePromptForReview() {
        significantActionsCount += 1
        
        // Follow Apple's guidelines: prompt at appropriate times
        let currentTime = Date().timeIntervalSince1970
        let daysSinceLastPrompt = (currentTime - lastReviewPromptDate) / (24 * 60 * 60)
        
        // Only prompt if:
        // 1. User has performed significant actions (5+ tables created/shuffled)
        // 2. At least 7 days since last prompt (or never prompted)
        // 3. Haven't exceeded 3 prompts per year
        let shouldPrompt = significantActionsCount >= 5 && 
                          daysSinceLastPrompt >= 7 && 
                          reviewPromptCount < 3
        
        if shouldPrompt && !hasPromptedForReview {
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                 AppStore.requestReview(in: windowScene)
                reviewPromptCount += 1
                lastReviewPromptDate = currentTime
                // Reset significant actions counter
                significantActionsCount = 0
                hasPromptedForReview = true
            }
        }
    }
    
    private func resetReviewPromptCounterIfNeeded() {
        let currentTime = Date().timeIntervalSince1970
        let yearInSeconds: TimeInterval = 365 * 24 * 60 * 60
        
        // Reset counter if it's been more than a year since the last prompt
        if lastReviewPromptDate > 0 && (currentTime - lastReviewPromptDate) > yearInSeconds {
            reviewPromptCount = 0
            significantActionsCount = 0
        }
    }
    
    private var tableShapeSelector: some View {
        let shapeOrder: [TableShape] = [.round, .rectangle, .square]
        return HStack(spacing: 12) {
            ForEach(shapeOrder, id: \.self) { shape in
                Button(action: { 
                    triggerHaptic(.medium)
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                        viewModel.currentArrangement.tableShape = shape
                    }
                }) {
                    TableShapeSelectorButton(
                        shape: shape,
                        isSelected: viewModel.currentArrangement.tableShape == shape,
                        action: {
                            triggerHaptic(.medium)
                            withAnimation(.interactiveSpring(response: 0.5, dampingFraction: 0.75, blendDuration: 0.12)) {
                                viewModel.currentArrangement.tableShape = shape
                            }
                        }
                    )
                }
            }
        }
        .padding(.vertical, 4)
        .padding(.top, 0)
        .frame(maxWidth: .infinity, alignment: .center)
        .accessibilityIdentifier("btn.shapeSelector")
        .onboardingAnchor(.shapeSelector)
    }
    
    struct TableShapeSelectorButton: View {
        let shape: TableShape
        let isSelected: Bool
        let action: () -> Void
        @Environment(\.colorScheme) var colorScheme
        var body: some View {
            Button(action: action) {
                VStack(spacing: 1) {
                    let outlineColor: Color = isSelected ? Color.accentColor : (colorScheme == .dark ? Color.white.opacity(0.45) : Color.gray.opacity(0.45))
                    let outlineWidth: CGFloat = isSelected ? 3 : 2.1
            switch shape {
                    case .round:
                        Circle()
                            .stroke(outlineColor, lineWidth: outlineWidth)
                            .frame(width: 38, height: 38)
                    .transition(.opacity.combined(with: .scale(scale: 0.85)))
                    case .rectangle:
                        Rectangle()
                            .stroke(outlineColor, lineWidth: outlineWidth)
                            .frame(width: 54, height: 38)
                    .transition(.opacity.combined(with: .scale(scale: 0.85)))
                    case .square:
                        Rectangle()
                            .stroke(outlineColor, lineWidth: outlineWidth)
                            .frame(width: 38, height: 38)
                    .transition(.opacity.combined(with: .scale(scale: 0.85)))
                    }
                    Text(shape.displayName.replacingOccurrences(of: " Table", with: ""))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(isSelected ? Color.accentColor : (colorScheme == .dark ? Color.white.opacity(0.8) : Color.gray))
                        .multilineTextAlignment(.center)
                        .padding(.top, 0.5)
                }
                .padding(4)
                .animation(.spring(response: 0.6, dampingFraction: 0.8), value: isSelected)
            }
            .frame(minWidth: 44, minHeight: 44)
            .accessibilityLabel(shape.displayName)
            .accessibilityAddTraits(isSelected ? .isSelected : .isButton)
        }
    }
    private var emptyStateView: some View {
        ZStack {
            // Gradient background matching screenshot: light blue (top) to light pink (bottom)
            LinearGradient(gradient: Gradient(colors: [Color.blue.opacity(0.18), Color.pink.opacity(0.14)]), startPoint: .top, endPoint: .bottom)
                .frame(maxHeight: .infinity)
                .ignoresSafeArea()
                .padding(.bottom, -25) // Extend 25pt lower
            VStack(spacing: 16) { // smaller spacing, less vertical space
                Spacer().frame(height: 100)
                // add people to be seated screen
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.12))
                        .frame(width: 120, height: 120) // smaller
                    Circle()
                        .stroke(Color.blue.opacity(0.25), lineWidth: 6)
                        .frame(width: 120, height: 120)
                    Image(systemName: "person.3.fill")
                        .font(.system(size: 60)) // smaller
                        .foregroundColor(Color.blue.opacity(0.8))
                }
                // Title and subtitle
                Text("Seat Maker")
                    .font(.system(size: 24, weight: .bold)) // Reduced from 28
                    .foregroundColor(.blue)
                    .shadow(color: Color.accentColor.opacity(0.08), radius: 4, x: 0, y: 2)
                Text("Create seating for events")
                    .font(.system(size: 16, weight: .regular)) // Changed from 18 to 16
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                    .padding(.top, 0) // Move up by 3 pixels (was -3)
                // Steps (numbers aligned)
                VStack(alignment: .leading, spacing: 10) {
                    stepRow(number: 1, text: "Add people to be seated")
                    stepRow(number: 2, text: "Choose a table shape")
                    stepRow(number: 3, text: "Shuffle to arrange seating")
                }
                .padding(.vertical)
                .padding(.horizontal, 16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.secondary.opacity(0.08))
                )
                .padding(.horizontal)
                
                // Get Started button
                Button(action: { 
                    showingAddPerson = true
                    // Don't automatically trigger add person popup when entering this screen
                    OnboardingController.shared.advanceIfOn(anchor: .getStarted)
                }) {
                    HStack {
                        Image(systemName: "person.badge.plus")
                        Text(viewModel.hasSavedArrangements ? "Add People" : "Get Started")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.blue)
                            // Base shadow
                            .shadow(color: Color.blue.opacity(0.25), radius: 8, x: 0, y: 4)
                            // Subtle glow
                            .shadow(color: Color.blue.opacity(0.55), radius: 12, x: 0, y: 0)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.blue.opacity(0.35), lineWidth: 1.5)
                            .blur(radius: 0.5)
                    )
                    .frame(width: 183)
                }
                .accessibilityIdentifier("btn.getStarted")
                .onboardingAnchor(.getStarted)
                .padding(.top, 4)
                
                if viewModel.hasSavedArrangements {
                    Button(action: {
                        historyOriginSnapshot = viewModel.tableCollection
                        historyOriginWasEmptyState = showEffortlessScreen
                        showingHistory = true
                    }) {
                        HStack {
                            Image(systemName: "clock.arrow.circlepath")
                            Text("View History")
                        }
                        .font(.headline)
                        .foregroundColor(.blue)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10) // Match Add People button
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color.white)
                                .shadow(color: Color.blue.opacity(0.08), radius: 8, x: 0, y: 2)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.blue, lineWidth: 2)
                        )
                        .frame(width: 183)
                    }
                    .padding(.top, 0) // Reduced from 4 to 0 to move 4 pixels higher
                    .buttonStyle(PlainButtonStyle())
                    .contentShape(Rectangle())
                }
                
                Spacer()
            }
            .padding(.top, 18)
        }
        .transition(.opacity.combined(with: .scale))
        .onAppear {
            requestNotificationsOnboardingIfAppropriate()
        }
    }
    
    private func stepRow(number: Int, text: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Text("\(number)")
                .font(.title2.monospacedDigit())
                .foregroundColor(.accentColor)
                .frame(width: 28, alignment: .leading)
            Text(text)
                .font(.headline)
                .foregroundColor(.primary)
        }
    }
    private var addPersonView: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Name at top
                TextField("Enter name", text: $newPersonName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    // No background or border
                    .autocapitalization(.words)
                    .onChange(of: newPersonName) { newValue in
                        viewModel.getSuggestedNames(for: newValue)
                    }
                if !viewModel.suggestedNames.isEmpty {
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 8) {
                            ForEach(viewModel.suggestedNames, id: \ .self) { name in
                                Button(action: {
                                    newPersonName = name
                                    viewModel.suggestedNames = []
                                }) {
                                    Text(name)
                                        .foregroundColor(.primary)
                                        .padding(.vertical, 8)
                                        .padding(.horizontal, 12)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .background(Color.secondary.opacity(0.1))
                                        .cornerRadius(8)
                                }
                            }
                        }
                    }
                    .frame(maxHeight: 200)
                }
                Spacer()
                // Import from List (top of the two)
                Button(action: {
                    // Always allow entering the import flow. Monetization is enforced when creating tables.
                    showingAddPerson = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                        importStartIntent = .text // jump to Source without auto-opening any picker
                    }
                }) {
                    HStack {
                        Image(systemName: "text.badge.plus")
                        Text("Import from List")
                    }
                    .font(.headline) // match contacts
                    .dynamicTypeSize(.xSmall ... .accessibility5)
                    .minimumScaleFactor(0.7)
                    .foregroundColor(.blue)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .frame(height: 52)
                    .frame(maxWidth: 320)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.blue.opacity(0.10))
                    )
                }
                .padding(.horizontal, 0)
                .offset(y: 9) // moved down by 5px
                // Removed dropdown; handled directly in button action above
                // Import from Contacts button (bottom)
                Button(action: {
                    // Request contacts access *before* presenting the picker
                    CNContactStore().requestAccess(for: .contacts) { granted, error in
                        DispatchQueue.main.async {
                            if granted {
                                showingContactsPicker = true
                                Task { @MainActor in
                                    viewModel.fetchContacts()
                                }
                            } else {
                                // Only show the redirect alert when permission was explicitly denied
                                permissionDeniedContacts = true
                                viewModel.isLoadingContacts = false
                            }
                        }
                    }
                }) {
                    HStack {
                        Image(systemName: "person.crop.circle.badge.plus")
                            .accessibilityHidden(true)
                        Text("Import from Contacts")
                    }
                    .font(.headline)
                    .dynamicTypeSize(.xSmall ... .accessibility5)
                    .minimumScaleFactor(0.7)
                    .foregroundColor(.blue)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .frame(height: 52)
                    .frame(maxWidth: 320)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.blue.opacity(0.10))
                    )
                }
                .disabled(viewModel.isLoadingContacts) // Disable button while loading contacts
                .padding(.top, 4)
                .padding(.bottom, 6)
                .accessibilityLabel("Import from Contacts")
                .accessibilityHint("Opens your contacts list to select people to add to the table")
                
                // Add button - only glow when name is entered
                HStack {
                    Spacer()
                    Button(action: {
                        if !newPersonName.isEmpty {
                            // Only check duplicates within the current table for manual add
                            let currentTableNames = Set(viewModel.currentArrangement.people.map { $0.name.lowercased() })
                            if currentTableNames.contains(newPersonName.lowercased()) {
                                // Do not close add person sheet, just show notification
                                NotificationCenter.default.post(
                                    name: Notification.Name("ShowDuplicatePersonAlert"),
                                    object: nil,
                                    userInfo: [
                                        "message": "\(newPersonName) is already seated at this table.",
                                        "personName": newPersonName
                                    ]
                                )
                                // Optionally clear the text field
                                // newPersonName = ""
                            } else {
                                viewModel.addPerson(name: newPersonName)
                                newPersonName = ""
                                showingAddPerson = false // Ensure popup closes and does not reopen
                                isAddButtonGlowing = false // Remove glow after tap
                                // FIX: Hide effortless screen after adding a person
                                showEffortlessScreen = false
                            }
                        }
                    }) {
                        Text("Add")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.horizontal, 40)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.blue)
                                    .shadow(color: Color.blue.opacity(0.3), radius: 6, x: 0, y: 2)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.white.opacity(isAddButtonGlowing ? 0.9 : 0), lineWidth: 3)
                                .shadow(color: Color.white.opacity(isAddButtonGlowing ? 0.7 : 0), radius: 12)
                            )
                    }
                    .disabled(newPersonName.isEmpty)
                    .onChange(of: newPersonName) { newValue in
                        // Only show glow when there is text
                        isAddButtonGlowing = !newValue.isEmpty
                    }
                    Spacer()
                }
                .padding(.bottom)
            }
            .navigationTitle("Add Person")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        showingAddPerson = false
                    }.tint(.blue)
                }
            }
            .sheet(isPresented: $showingContactsPicker, onDismiss: {
                // Only reset contacts loading state here
                DispatchQueue.main.async {
                    viewModel.isLoadingContacts = false
                    showingContactsPicker = false
                }
            }) {
                ContactsPickerView(
                    contacts: viewModel.contacts,
                    onSelect: { selected in
                        DispatchQueue.main.async {
                            for name in selected {
                                let allPeopleNames = viewModel.tableCollection.tables.values.flatMap { $0.people.map { $0.name.lowercased() } }
                                let currentTableNames = viewModel.currentArrangement.people.map { $0.name.lowercased() }
                                let allNames = Set(allPeopleNames + currentTableNames)
                                if allNames.contains(name.lowercased()) {
                                    print("Duplicate contact skipped: \(name)")
                                } else {
                                    viewModel.addPerson(name: name)
                                }
                            }
                            viewModel.suggestedNames = []
                            showingContactsPicker = false
                            viewModel.isLoadingContacts = false
                            showingAddPerson = false // Dismiss add person view and return to main screen
                            showEffortlessScreen = false // Always show main table after import
                        }
                    },
                    onSmartSeating: { selected in
                        DispatchQueue.main.async {
                            viewModel.smartCreateTables(from: Array(selected))
                            viewModel.suggestedNames = []
                            showingContactsPicker = false
                            viewModel.isLoadingContacts = false
                            showingAddPerson = false
                            showEffortlessScreen = false
                        }
                    }
                )
            }
            .sheet(isPresented: $showingHistory) {
                HistoryView(
                    viewModel: viewModel,
                    dismissAction: {
                        showingHistory = false
                        // Ensure table name is always 'Table X' if empty or 'New Arrangement'
                        if viewModel.currentTableName.isEmpty || viewModel.currentTableName == "New Arrangement" {
                            viewModel.currentTableName = String(format: NSLocalizedString("Table %d", comment: "Default table name"), viewModel.tableCollection.currentTableId + 1)
                        }
                        // If not viewing a history item, ensure we reset to welcome screen
                        if !viewModel.isViewingHistory {
                            resetAndShowWelcomeScreen()
                        }
                    }
                )
            }
            .onDisappear {
                // Only reset contacts loading state here
                DispatchQueue.main.async {
                    viewModel.isLoadingContacts = false
                    showingContactsPicker = false
                }
            }
            .alert("Duplicate Name", isPresented: $showingDuplicateAlert) {
                Button("OK", role: .cancel) { 
                    // On duplicate alert dismissal, ensure add person sheet stays open
                    showingDuplicateAlert = false
                }
            } message: {
                Text("A person with this name already exists in one of your tables. Please choose a different name.")
            }
        }
    }

    // MARK: - Onboarding registrations
    private func registerOnboardingActions() {
        // Manage People (opens guest manager sheet)
        OnboardingController.shared.registerAction(for: .managePeople) {
            DispatchQueue.main.async {
                showingGuestManager = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    OnboardingController.shared.advanceIfOn(anchor: .managePeople)
                }
            }
        }
        // Add button (main bar)
        OnboardingController.shared.registerAction(for: .add) {
            DispatchQueue.main.async {
                triggerHaptic(.medium)
                newPersonName = ""
                showingAddPerson = true
                // Do not auto-advance; user will press Next to proceed from step 1
            }
        }
        // Shuffle
        OnboardingController.shared.registerAction(for: .shuffle) {
            DispatchQueue.main.async {
                triggerHaptic(.medium)
                withAnimation(.interactiveSpring(response: 0.5, dampingFraction: 0.78, blendDuration: 0.2)) {
                    viewModel.shuffleSeats()
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    OnboardingController.shared.advanceIfOn(anchor: .shuffle)
                }
            }
        }
        // Shape selector
        OnboardingController.shared.registerAction(for: .shapeSelector) {
            DispatchQueue.main.async {
                // Nudge the currently selected shape to reapply state, just to give feedback
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    let current = viewModel.currentArrangement.tableShape
                    viewModel.currentArrangement.tableShape = current
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    OnboardingController.shared.advanceIfOn(anchor: .shapeSelector)
                }
            }
        }
        // Get Started (same as tapping the primary empty-state button)
        OnboardingController.shared.registerAction(for: .getStarted) {
            DispatchQueue.main.async {
                showingAddPerson = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    OnboardingController.shared.advanceIfOn(anchor: .getStarted)
                }
            }
        }
        // Table Manager
        OnboardingController.shared.registerAction(for: .tableManager) {
            DispatchQueue.main.async {
                showingTableManager = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    OnboardingController.shared.advanceIfOn(anchor: .tableManager)
                }
            }
        }
        // Share (open save/export dialog which then shows sheet)
        OnboardingController.shared.registerAction(for: .share) {
            DispatchQueue.main.async {
                showingSaveDialog = true
            }
        }
        // Settings
        OnboardingController.shared.registerAction(for: .settings) {
            DispatchQueue.main.async { openSettingsSafely() }
        }
    }
    
    private var saveButton: some View {
        Button(action: {
            viewModel.saveCurrentArrangement()
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                showingSaveConfirmation = true
                // Reset to new arrangement after a short delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    viewModel.resetArrangement()
                }
            }
        }) {
            Image(systemName: "square.and.arrow.up.circle.fill")
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(.green)
                .frame(width: 44, height: 44)
                .background(
                    Circle()
                        .fill(Color.green.opacity(0.1))
                )
        }
    }
    
    private var settingsView: some View {
        NavigationView {
            SettingsViewImpl()
                .environmentObject(viewModel)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(action: { 
                            // Ensure proper cleanup when dismissing
                            OrientationLock.shared.lockOrientation()
                            ImageCacheManager.shared.clearCache()
                            showingSettings = false 
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 16, weight: .semibold))
                                Text("Back")
                            }
                            .foregroundColor(.accentColor)
                        }
                    }
                    ToolbarItem(placement: .principal) {
                        Text("Settings")
                            .font(.headline)
                    }
                }
                .onAppear {
                    // Initialize shared managers when view appears
                    _ = OrientationLock.shared
                    _ = ImageCacheManager.shared
                    _ = LocalizationManager.shared
                    NotificationService.shared.configureOnAppear()
                }
                .onDisappear {
                    // Cleanup when view disappears
                    OrientationLock.shared.lockOrientation()
                    ImageCacheManager.shared.clearCache()
                }
        }
        .preferredColorScheme(isDarkMode ? .dark : .light)
        .tint(.blue)
        .accessibilityLabel("Settings")
        .accessibilityHint("Configure app settings and preferences")
    }
    
    // appearanceSection implemented inside SettingsViewImpl
    // MARK: - Settings View Implementation
        struct SettingsViewImpl: View {
        // Environment Objects
        @EnvironmentObject var viewModel: SeatingViewModel
        @Environment(\.colorScheme) var colorScheme
        @Environment(\.dismiss) var dismiss
        @Environment(\.openURL) var openURL
        @ObservedObject private var rc = RevenueCatManager.shared

        // State variables for view control
        @State private var showPrivacyPolicy = false
        @State private var showDataUsage = false
        @State private var showDeleteAlert = false
        @State private var showMail = false
        @State private var mailResult: Result<MFMailComposeResult, Error>? = nil
        @State private var showDeletionConfirmation = false
        @State private var showingImagePicker = false
        @State private var profileImage: UIImage?
        @State private var showingTutorial = false
        @State private var showResetConfirmation = false
        @State private var showComingSoon = false
        @State private var permissionDeniedPhoto = false
        @State private var showAppIconConfirmation = false
        @State private var showAboutMe = false
        @State private var showFAQ = false
        @State private var showContactForm = false
        @State private var showPaywall = false
        @State private var purchaseToast: String? = nil
        
        // App Storage variables
        @AppStorage("isDarkMode") private var isDarkMode = false
        @AppStorage("appTheme") private var appTheme: String = "classic"
        @AppStorage("customAccentHex") private var customAccentHex: String = "#007AFF"
        @AppStorage("userName") private var userName = ""
        @AppStorage("profileImageData") private var profileImageData: Data?
        @AppStorage("pendingAppIcon") private var pendingAppIcon: String = "Default"
        @AppStorage("notificationsEnabled") private var notificationsEnabled: Bool = false
        
        // MARK: - Appearance helpers (nested for scoping and compiler performance)
        private struct SettingsThemePickerRow: View {
            @Binding var appTheme: String
            var body: some View {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ThemeSwatchChip(appTheme: $appTheme, id: "blue", label: "Blue", colors: [Color.blue, Color.purple])
                        ThemeSwatchChip(appTheme: $appTheme, id: "teal", label: "Teal", colors: [Color.teal, Color.blue])
                        ThemeSwatchChip(appTheme: $appTheme, id: "orange", label: "Orange", colors: [Color.orange, Color.red])
                        ThemeSwatchChip(appTheme: $appTheme, id: "pink", label: "Pink", colors: [Color.pink, Color.purple])
                        ThemeSwatchChip(appTheme: $appTheme, id: "green", label: "Green", colors: [Color.green, Color.teal])
                        ThemeSwatchChip(appTheme: $appTheme, id: "indigo", label: "Indigo", colors: [Color.indigo, Color.blue])
                        ThemeSwatchChip(appTheme: $appTheme, id: "gold", label: "Gold", colors: [Color.yellow, Color.orange])
                        ThemeSwatchChip(appTheme: $appTheme, id: "purple", label: "Purple", colors: [Color.purple, Color.indigo])
                        ThemeSwatchChip(appTheme: $appTheme, id: "cyan", label: "Cyan", colors: [Color.cyan, Color.blue])
                        ThemeSwatchChip(appTheme: $appTheme, id: "mint", label: "Mint", colors: [Color.mint, Color.teal])
                        ThemeSwatchChip(appTheme: $appTheme, id: "red", label: "Red", colors: [Color.red, Color.orange])
                        ThemeSwatchChip(appTheme: $appTheme, id: "brown", label: "Brown", colors: [Color.brown, Color.orange])
                        ThemeSwatchChip(appTheme: $appTheme, id: "gray", label: "Gray", colors: [Color.gray, Color.black.opacity(0.6)])
                        ThemeSwatchChip(appTheme: $appTheme, id: "custom", label: "Custom", colors: [Color.accentColor.opacity(0.6), Color.accentColor])
                    }
                    .padding(.vertical, 2)
                }
            }
        }

        private struct ThemeSwatchChip: View {
            @Binding var appTheme: String
            let id: String
            let label: String
            let colors: [Color]
            var body: some View {
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) { appTheme = id }
                }) {
                    VStack(spacing: 6) {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 34, height: 26)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(appTheme == id ? Color.primary.opacity(0.6) : Color.clear, lineWidth: 2)
                            )
                        Text(label)
                            .font(.system(size: 11, weight: .regular))
                            .foregroundColor(.secondary)
                    }
                }
                .buttonStyle(PlainButtonStyle())
                .accessibilityLabel("Select \(label) theme")
            }
        }

        // Local swatch used in Appearance section (limited to 5 themes)
        private struct ThemeSwatch: View {
            @Binding var appTheme: String
            let id: String
            let label: String
            let colors: [Color]
            var body: some View {
                Button(action: { withAnimation(.easeInOut(duration: 0.2)) { appTheme = id } }) {
                    VStack(spacing: 6) {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 36, height: 28)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(appTheme == id ? Color.primary.opacity(0.6) : Color.clear, lineWidth: 2)
                            )
                        Text(label)
                            .font(.system(size: 11, weight: .regular))
                            .foregroundColor(.secondary)
                    }
                }
                .buttonStyle(PlainButtonStyle())
                .accessibilityLabel("Select \(label) theme")
            }
        }

        // Manager state class
        private final class ManagerState: ObservableObject {
            @Published private(set) var orientationLock: OrientationLock
            @Published private(set) var imageCacheManager: ImageCacheManager
            @Published private(set) var localizationManager: LocalizationManager
            private var cancellables = Set<AnyCancellable>()
            
            init() {
                self.orientationLock = OrientationLock.shared
                self.imageCacheManager = ImageCacheManager.shared
                self.localizationManager = LocalizationManager.shared
                
                // Set up observation
                NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)
                    .sink { [weak self] _ in
                        self?.objectWillChange.send()
                    }
                    .store(in: &cancellables)
            }
        }
        
        @StateObject private var managerState = ManagerState()
        
        private var orientationLock: OrientationLock {
            managerState.orientationLock
        }
        
        private var imageCacheManager: ImageCacheManager {
            managerState.imageCacheManager
        }
        
        private var localizationManager: LocalizationManager {
            managerState.localizationManager
        }
        
        @AppStorage("selectedLanguage") private var selectedLanguage = "en"
        
        init() {
            // No initialization needed for selectedLanguage as it's now properly declared with @AppStorage
        }
        
        private func handleDarkModeChange(_ newValue: Bool) {
            withAnimation(.easeInOut(duration: 0.3)) {
                isDarkMode = newValue
            }
            // Force immediate UI update
            DispatchQueue.main.async {
                viewModel.objectWillChange.send()
                // Also update the color scheme for the settings view instantly
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                    windowScene.windows.first?.overrideUserInterfaceStyle = newValue ? .dark : .light
                }
            }
        }
        
        var body: some View {
            VStack(spacing: 0) {
                Form {
                    // Profile Section
                    Section(header: Text("Profile")) {
                        HStack {
                            profileImageView
                            profileInfoView
                        }
                        .padding(.vertical, 4)
                        Button(action: {
                            Task {
                                let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
                                if status == .notDetermined {
                                    let newStatus = await withCheckedContinuation { continuation in
                                        PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
                                            continuation.resume(returning: status)
                                        }
                                    }
                                    if newStatus == .authorized || newStatus == .limited {
                                        showingImagePicker = true
                                    } else {
                                        permissionDeniedPhoto = true
                                    }
                                } else if status == .authorized || status == .limited {
                                    showingImagePicker = true
                                } else {
                                    permissionDeniedPhoto = true
                                }
                            }
                        }) {
                            Label("Change Profile Picture", systemImage: "photo")
                                .foregroundColor(.blue)
                        }
                        // Move Restart tour right below change profile picture
                        Button(action: {
                            OnboardingController.shared.reset()
                            dismiss()
                            // Start shortly after settings sheet dismisses so anchors are available
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                                OnboardingController.shared.startIfNeeded(context: .mainTable)
                            }
                        }) {
                            HStack {
                                Image(systemName: "questionmark.circle")
                                    .foregroundColor(.blue)
                                    .frame(width: 28, height: 28)
                                Text("Take a tour")
                                    .foregroundColor(.blue)
                            }
                        }
                        .accessibilityIdentifier("settings.restartInteractiveTour")
                        .accessibilityLabel("Take a tour")
                    }
                    // Remove "Help & Tutorials" header per request
                    // Appearance Section
                    Section(header: Text("Appearance")) {
                        HStack {
                            Image(systemName: isDarkMode ? "moon.fill" : "sun.max.fill")
                                .foregroundColor(.primary)
                                .frame(width: 24, height: 24)
                            Toggle("Dark Mode", isOn: Binding(
                                get: { isDarkMode },
                                set: { newValue in
                                    handleDarkModeChange(newValue)
                                }
                            ))
                            .tint(.blue)
                        }
                        .padding(.vertical, 4)

                        HStack(alignment: .center, spacing: 12) {
                            Image(systemName: "paintpalette.fill")
                                .foregroundColor(.primary)
                                .frame(width: 24, height: 24)
                            VStack(alignment: .leading, spacing: 8) {
                                Text("App Theme")
                                HStack(spacing: 10) {
                                    ThemeSwatch(appTheme: $appTheme, id: "classic", label: "Classic", colors: [Color.gray.opacity(0.2), Color.white])
                                    ThemeSwatch(appTheme: $appTheme, id: "ocean", label: "Ocean", colors: [Color.cyan, Color.blue])
                                    ThemeSwatch(appTheme: $appTheme, id: "sunset", label: "Sunset", colors: [Color.orange, Color.pink])
                                    ThemeSwatch(appTheme: $appTheme, id: "forest", label: "Forest", colors: [Color.green, Color.teal])
                                    ThemeSwatch(appTheme: $appTheme, id: "midnight", label: "Purple", colors: [Color.indigo, Color.purple])
                                    ThemeSwatch(appTheme: $appTheme, id: "custom", label: "Custom", colors: [Color.accentColor.opacity(0.6), Color.accentColor])
                                }
                                // Custom color picker shown when Custom theme selected
                                if appTheme == "custom" {
                                    VStack(alignment: .leading, spacing: 10) {
                                        // Live accent preview bar above the text, using the chosen color
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(colorFromHex(customAccentHex))
                                            .frame(height: 10)
                                        Text("Custom Accent Color")
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                        ColorPicker("Pick a color", selection: Binding(
                                            get: { colorFromHex(customAccentHex) },
                                            set: { newColor in
                                                customAccentHex = hexFromColor(newColor)
                                                // Force refresh of accent globally
                                                UserDefaults.standard.set(customAccentHex, forKey: "customAccentHex")
                                            }
                                        ))
                                        .labelsHidden()
                                    }
                                }
                            }
                        }
                        .padding(.vertical, 6)
                    }
                    // Reminders Section
                    Section(header: Text("Reminders")) {
                        HStack {
                            Image(systemName: notificationsEnabled ? "bell.fill" : "bell")
                                .foregroundColor(.primary)
                                .frame(width: 24, height: 24)
                            Toggle("Alerts", isOn: Binding(
                                get: { notificationsEnabled },
                                set: { newValue in
                                    notificationsEnabled = newValue
                                    if newValue {
                                        NotificationService.shared.enableDailyReminder()
                                    } else {
                                        NotificationService.shared.disableReminders()
                                    }
                                }
                            ))
                            .tint(.accentColor)
                        }
                        .padding(.vertical, 4)

                        // Alerts are automatically scheduled at 10:00 when enabled
                    }
                    // Table Defaults Section
                    Section(header: Text("Table Defaults")) {
                        // Default Shape Picker
                        HStack {
                            Image(systemName: "square.on.square")
                                .foregroundColor(.primary)
                                .frame(width: 24, height: 24)
                            Text("Default Shape")
                            Spacer()
                            Picker("", selection: Binding(
                                get: { viewModel.defaultTableShape },
                                set: { viewModel.defaultTableShape = $0 }
                            )) {
                                ForEach(TableShape.allCases, id: \ .self) { shape in
                                    Text(shape.rawValue.capitalized)
                                }
                            }
                            .pickerStyle(.menu)
                        }
                        // Lock by Default Toggle
                        HStack {
                            Image(systemName: viewModel.lockByDefault ? "lock.fill" : "lock.open")
                                .foregroundColor(.primary)
                                .frame(width: 24, height: 24)
                            Toggle("Lock People by Default", isOn: Binding(
                                get: { viewModel.lockByDefault },
                                set: { viewModel.lockByDefault = $0 }
                            ))
                            .tint(.accentColor)
                        }
                        .padding(.vertical, 4)
                        // Hide Seat Numbers Toggle
                        HStack {
                            Image(systemName: viewModel.hideSeatNumbers ? "eye.slash" : "eye")
                                .foregroundColor(.primary)
                                .frame(width: 24, height: 24)
                            Toggle("Hide Seat Numbers", isOn: Binding(
                                get: { viewModel.hideSeatNumbers },
                                set: {
                                    viewModel.hideSeatNumbers = $0
                                    viewModel.hideSeatNumbersStorage = $0
                                }
                            ))
                            .tint(.accentColor)
                        }
                        .padding(.vertical, 4)
                        // Hide Table Number Toggle
                        HStack {
                            Image(systemName: viewModel.hideTableNumber ? "number.circle.fill" : "number.circle")
                                .foregroundColor(.primary)
                                .frame(width: 24, height: 24)
                            Toggle("Hide Table Number", isOn: Binding(
                                get: { viewModel.hideTableNumber },
                                set: {
                                    viewModel.hideTableNumber = $0
                                    viewModel.hideTableNumberStorage = $0
                                }
                            ))
                            .tint(.accentColor)
                        }
                        .padding(.vertical, 4)
                    }
                    // Statistics Section
                    Section(header: Text("Statistics")) {
            HStack {
                Image(systemName: "square.stack.fill") // Changed icon
                     .foregroundColor(.primary)
                     .frame(width: 24, height: 24)
                Text("Total Tables Created")
                Spacer()
                Text("\(viewModel.savedArrangements.count)")
                    .foregroundColor(.secondary)
    }
            HStack {
                Image(systemName: "person.3")
                    .foregroundColor(.primary)
                    .frame(width: 24, height: 24)
                Text("Total People Seated")
                Spacer()
                Text("\(viewModel.totalPeopleSeated)")
                    .foregroundColor(.secondary)
            }
        }
    
                    // Privacy & Data Section
                    Section(header: Text("Privacy & Data")) {
                        Button(action: {
                            // Show the coming soon screen instead of exporting
                            showComingSoon = true
                        }) {
                            HStack {
                                Image(systemName: "arrow.down.doc.fill")
                                    .font(.system(size: 18))
                                    .frame(width: 28, height: 28)
                                    .foregroundColor(.green)
                                Text("Export Data as CSV")
                                    .font(.system(size: 16))
                                    .foregroundColor(.primary)
                            }
                        }
                        .sheet(isPresented: $showComingSoon) {
                            ComingSoonView()
                        }
                        .disabled(viewModel.savedArrangements.isEmpty)
                        
                        Button {
                            showPrivacyPolicy = true
                        } label: {
                            HStack {
                                Image(systemName: "hand.raised.fill")
                                    .foregroundColor(.purple) // Changed icon color to purple
                                    .font(.system(size: 18))
                                    .frame(width: 28, height: 28)
                                Text("Privacy Policy")
                                    .font(.system(size: 16))
                                    .foregroundColor(.primary)
                            }
                        }
                        .sheet(isPresented: $showPrivacyPolicy) {
                            TermsView(onDismiss: { showPrivacyPolicy = false })
                        }
                        
                        Button {
                            showDataUsage = true
                        } label: {
                            HStack {
                                Image(systemName: "internaldrive.fill")
                                    .foregroundColor(.pink) // Changed icon color to pink
                                    .font(.system(size: 18))
                                    .frame(width: 28, height: 28)
                                Text("Data Usage")
                                    .font(.system(size: 16))
                                    .foregroundColor(.primary)
                            }
                        }
                        .alert(isPresented: $showDataUsage) {
                            Alert(
                                title: Text("Data Usage"),
                                message: Text("""
                                Seat Maker only stores your data locally on your device. We request access to your contacts to help you add people, and to your photo library for profile images. No data is shared with third parties. You can withdraw consent at any time by revoking permissions in iOS Settings.
                                """),
                                dismissButton: .default(Text("OK"))
                            )
                        }
                    }

                    // Permissions Section
                    Section(header: Text("Permissions")) {
                        Text("You can manage Contacts and Photos permissions in the iOS Settings app under Seat Maker. If you deny access, you can still use the app, but some features may be limited.")
                    }

                    // After Permissions section, before Account & Data section
                    Section(header: Text("Support & Feedback").font(.caption).foregroundColor(.secondary)) {
                        Button(action: { 
                            // Request app store review following Apple guidelines
                            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                                AppStore.requestReview(in: windowScene)
                            }
                        }) {
                            HStack {
                                ZStack {
                                    Circle().fill(Color.yellow.opacity(0.18)).frame(width: 36, height: 36)
                                    Image(systemName: "star.fill").font(.system(size: 20, weight: .bold)).foregroundColor(.yellow)
                                }
                                Text("Rate Seat Maker").font(.system(size: 15, weight: .semibold)).foregroundColor(.primary)
                                Spacer()
                                Image(systemName: "chevron.right").font(.system(size: 12, weight: .medium)).foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .padding(.horizontal, 16)
                            .background(RoundedRectangle(cornerRadius: 14).fill(Color.yellow.opacity(0.10)))
                            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.yellow.opacity(0.25), lineWidth: 1))
                            .shadow(color: Color.yellow.opacity(0.08), radius: 2, x: 0, y: 1)
                        }
                        .accessibilityLabel("Rate Seat Maker on the App Store")
                        .padding(.bottom, 8)
                        
                        Button(action: { showContactForm = true }) {
                            HStack {
                                ZStack {
                                    Circle().fill(Color.green.opacity(0.16)).frame(width: 36, height: 36)
                                    Image(systemName: "envelope.fill").font(.system(size: 20, weight: .bold)).foregroundColor(.green)
                                }
                                Text("Send Feedback").font(.system(size: 15, weight: .semibold)).foregroundColor(.primary)
                                Spacer()
                                Image(systemName: "chevron.right").font(.system(size: 12, weight: .medium)).foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .padding(.horizontal, 16)
                            .background(RoundedRectangle(cornerRadius: 14).fill(Color.green.opacity(0.10)))
                            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.green.opacity(0.24), lineWidth: 1))
                            .shadow(color: Color.green.opacity(0.06), radius: 2, x: 0, y: 1)
                        }
                        .sheet(isPresented: $showContactForm) { ContactFormView() }
                        .accessibilityLabel("Send feedback to the developer")
                        .padding(.bottom, 8)
                        
                        Button(action: { showFAQ = true }) {
                            HStack {
                                ZStack {
                                    Circle().fill(Color.blue.opacity(0.12)).frame(width: 36, height: 36)
                                    Image(systemName: "questionmark.circle.fill").font(.system(size: 20, weight: .bold)).foregroundColor(.blue)
                                }
                                Text("Frequently Asked Questions").font(.system(size: 15, weight: .semibold)).foregroundColor(.primary)
                                Spacer()
                                Image(systemName: "chevron.right").font(.system(size: 12, weight: .medium)).foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .padding(.horizontal, 16)
                            .background(RoundedRectangle(cornerRadius: 14).fill(Color.blue.opacity(0.07)))
                            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.blue.opacity(0.13), lineWidth: 1))
                            .shadow(color: Color.blue.opacity(0.04), radius: 2, x: 0, y: 1)
                        }
                        .sheet(isPresented: $showFAQ) { FAQScreenView() }
                        .accessibilityLabel("Frequently Asked Questions")
                        .padding(.bottom, 8)
                        
                        Button(action: { showAboutMe = true }) {
                            HStack {
                                ZStack {
                                    Circle().fill(Color.purple.opacity(0.12)).frame(width: 36, height: 36)
                                    Image(systemName: "person.crop.circle.fill").font(.system(size: 20, weight: .bold)).foregroundColor(.purple)
                                }
                                Text("About the Creator").font(.system(size: 15, weight: .semibold)).foregroundColor(.primary)
                                Spacer()
                                Image(systemName: "chevron.right").font(.system(size: 12, weight: .medium)).foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .padding(.horizontal, 16)
                            .background(RoundedRectangle(cornerRadius: 14).fill(Color.purple.opacity(0.07)))
                            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.purple.opacity(0.13), lineWidth: 1))
                            .shadow(color: Color.purple.opacity(0.04), radius: 2, x: 0, y: 1)
                        }
                        .sheet(isPresented: $showAboutMe) { CreatorProfileView() }
                        .accessibilityLabel("About the Creator")
                    }

                    // Account & Data Section with Restore Purchases at top
                    Section(header: Text("Account & Data")) {
                        // Restore Purchases moved here to top
                        Button("Restore Purchases") {
                            RevenueCatManager.shared.restore { result in
                                purchaseToast = (try? result.get()) != nil ? "Restored ✅" : "Restore failed"
                            }
                        }
                        
                        Button(action: {
                            // Show confirmation before resetting
                            showResetConfirmation = true
                        }) {
                            HStack {
                                Image(systemName: "arrow.clockwise")
                                    .foregroundColor(.orange)
                    .frame(width: 24, height: 24)
                                Text("Reset to Default Settings")
                                    .foregroundColor(.orange)
                            }
                        }
                        .alert(isPresented: $showResetConfirmation) {
                            Alert(
                                title: Text("Reset Settings?"),
                                message: Text("This will restore all app settings to their default values. This won't delete your saved arrangements."),
                                primaryButton: .destructive(Text("Reset")) {
                                    viewModel.resetToDefaults()
                                    // Force immediate UI update for dark mode
                                    isDarkMode = false
                                    // Update the color scheme for the settings view instantly
                                    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                                        windowScene.windows.first?.overrideUserInterfaceStyle = .light
                                    }
                                },
                                secondaryButton: .cancel()
                            )
                        }
                        
                        Button(action: {
                            showDeleteAlert = true
                        }) {
                HStack {
                                Image(systemName: "trash.fill")
                .foregroundColor(.red)
                .frame(width: 24, height: 24)
                                Text("Delete All Data")
                .foregroundColor(.red)
                            }
                        }
                        .alert(isPresented: $showDeleteAlert) {
                            Alert(
                                title: Text("Delete All Data?"),
                                message: Text("This will erase all your app data from this device. This action cannot be undone."),
                                primaryButton: .destructive(Text("Delete")) {
                                    // Ensure ads are not shown during or immediately after a destructive delete
                                    AdsManager.shared.suppressInterstitials(for: 60)
                                    // Erase all user data
                                    if let bundleID = Bundle.main.bundleIdentifier {
                                        UserDefaults.standard.removePersistentDomain(forName: bundleID)
                                    }
                                    profileImageData = nil
                                    userName = ""
                                    viewModel.deleteAllHistory()
                                    viewModel.tableCollection.tables = [:]
                                    viewModel.tableCollection.currentTableId = 0
                                    viewModel.tableCollection.maxTableId = 0
                                    viewModel.currentArrangement = SeatingArrangement(title: "New Arrangement", people: [], tableShape: viewModel.defaultTableShape)
                                    viewModel.currentTableName = ""
                                    viewModel.isViewingHistory = false
                                    viewModel.saveTableCollection()
                                    showDeletionConfirmation = true
                                },
                                secondaryButton: .cancel()
                            )
                        }
                        .alert("Data Deleted", isPresented: $showDeletionConfirmation) {
                            Button("OK", role: .cancel) {
                                // Post a notification to return to welcome screen at parent level
                                NotificationCenter.default.post(name: Notification.Name("ReturnToWelcomeAfterDataDelete"), object: nil)
                            }
                        } message: {
                            Text("All your data has been deleted from this device.")
                        }
                    }
                }
                .navigationTitle("Settings")
                .navigationBarTitleDisplayMode(.inline)
                .preferredColorScheme(isDarkMode ? .dark : .light)
                // Show default grouped backgrounds so section boxes appear in light mode
                .scrollContentBackground(.visible)
                .sheet(isPresented: $showMail) {
                    MailViewImpl(result: $mailResult)
                }
                .sheet(isPresented: $showingImagePicker) {
                    ImagePicker(image: $profileImage)
                }
                .sheet(isPresented: $showingTutorial) {
                    HelpTutorialView()
                }
                .onChange(of: profileImage) { newImage in
                    Task {
                        if let image = newImage {
                            // Process image on background thread to prevent freezing
                            let compressedData = await Task.detached(priority: .userInitiated) {
                                return image.jpegData(compressionQuality: 0.8)
                            }.value
                            await MainActor.run {
                                // Clear the old image data first, then set the new one
                                profileImageData = nil
                                profileImageData = compressedData
                            }
                        } else {
                            // Clear both image and data when image is removed
                            await MainActor.run {
                                profileImageData = nil
                            }
                        }
                    }
                }
                .onAppear {
                    if let data = profileImageData {
                        profileImage = UIImage(data: data)
                    }
                }
                // FAQ & About Buttons below the Form
               
            }
        }
        
        // Individual app icon selection option - updated with system images as fallback
        private func appIconOption(name: String, imageName: String, systemName: String, isSelected: Bool) -> some View {
            Button(action: {
                viewModel.changeAppIcon(to: name == "Default" ? nil : name)
            }) {
                VStack {
                    ZStack {
                        // Fallback icon placeholder if image is not found
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.gray.opacity(0.2))
                            .frame(width: 60, height: 60)
                        
                        // Try to load icon image, fall back to symbol if not found
                        if UIImage(named: imageName) != nil {
                            Image(imageName)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .cornerRadius(12)
                                .frame(width: 60, height: 60)
                        } else {
                            // Fallback to specified system image
                            Image(systemName: systemName)
                                .font(.system(size: 30))
                                .foregroundColor(.accentColor)
                        }
                        
                        // Selection indicator
                        if isSelected {
                            RoundedRectangle(cornerRadius: 12)
                                .strokeBorder(Color.accentColor, lineWidth: 3)
                                .frame(width: 60, height: 60)
                        }
                    }
                    
                    Text(name)
                        .font(.caption)
                        .foregroundColor(.primary)
                }
                // Avoid nested paywall sheets inside settings; rely on top-level fullScreenCover
                .alert(purchaseToast ?? "", isPresented: Binding(get: { purchaseToast != nil }, set: { _ in purchaseToast = nil })) {
                    Button("OK", role: .cancel) {}
                }
            }
        }
        
        private var profileImageView: some View {
            Button(action: {
                let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
                if status == .notDetermined {
                    PHPhotoLibrary.requestAuthorization(for: .readWrite) { newStatus in
                        DispatchQueue.main.async {
                            if newStatus == .authorized || newStatus == .limited {
                                showingImagePicker = true
                            } else {
                                permissionDeniedPhoto = true
                            }
                        }
                    }
                } else if status == .authorized || status == .limited {
                    showingImagePicker = true
                } else {
                    permissionDeniedPhoto = true
                }
            }) {
                Group {
                    if let image = profileImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 80, height: 80)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.accentColor, lineWidth: 2))
                            .accessibilityLabel("Profile picture")
                    } else if let data = profileImageData, let image = UIImage(data: data) {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 80, height: 80)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.accentColor, lineWidth: 2))
                            .accessibilityLabel("Profile picture")
                    } else {
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .frame(width: 80, height: 80)
                            .foregroundColor(.blue)
                            .accessibilityLabel("Default profile picture")
                    }
                }
                .animation(.easeInOut(duration: 0.2), value: profileImage)
                .animation(.easeInOut(duration: 0.2), value: profileImageData)
            }
            .alert("Photo Access Needed", isPresented: $permissionDeniedPhoto) {
                Button("Open Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Seat Maker does not have access to your photos. To enable access, go to Settings > Privacy > Photos and turn on Photos for Seat Maker.")
            }
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(image: $profileImage)
                    .onDisappear {
                        // Ensure UI updates properly when picker is dismissed
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            // Force UI refresh to prevent glitches
                            if let data = profileImageData, let img = UIImage(data: data) {
                                if profileImage != img {
                                    profileImage = img
                                }
                            } else {
                                // Clear profile image if no data exists
                                profileImage = nil
                            }
                        }
                    }
            }
            .onAppear {
                // Always sync state from storage on appear
                DispatchQueue.main.async {
                if let data = profileImageData, let img = UIImage(data: data) {
                    profileImage = img
                } else {
                    profileImage = nil
                    }
                }
            }
            .onChange(of: profileImageData) { newData in
                // Sync state if storage changes
                DispatchQueue.main.async {
                if let data = newData, let img = UIImage(data: data) {
                    profileImage = img
                } else {
                    profileImage = nil
                    }
                }
            }
            .onChange(of: profileImage) { newImage in
                
                if let img = newImage {
                    Task {
                        // Process image on background thread to prevent freezing
                        let compressedData = await Task.detached(priority: .userInitiated) {
                            return img.jpegData(compressionQuality: 0.8)
                        }.value
                        await MainActor.run {
                            // Only update if this is still the current image (prevent race conditions)
                            if self.profileImage == img {
                                // Clear old data first, then set new data
                                self.profileImageData = nil
                                self.profileImageData = compressedData
                            }
                        }
                    }
                } else {
                    // Clear data when image is removed
                    profileImageData = nil
                }
            }
        }
        
        private var profileInfoView: some View {
            VStack(alignment: .leading, spacing: 4) {
                TextField("Your Name", text: $userName, onCommit: {
                    if !userName.isEmpty {
                        UserDefaults.standard.set(userName, forKey: "userName")
                        if notificationsEnabled { NotificationService.shared.enableDailyReminder() }
                    }
                    if !viewModel.currentTableName.isEmpty {
                        viewModel.currentArrangement.title = viewModel.currentTableName
                        viewModel.saveCurrentTableState()
                        viewModel.saveTableCollection()
                    }
                })
                    .font(.system(size: 23, weight: .bold)) // 3 sizes bigger than default 17
                
                // Fix pluralization for tables
                Text(viewModel.savedArrangements.count == 1 ?
                     "1 table created" :
                     "\(viewModel.savedArrangements.count) tables created")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.leading)
        }
        
        // Method to export all data as CSV
        private func exportCSV() {
            let csvData = viewModel.exportAllTablesToCSV()
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyyMMdd_HHmmss"
            let dateString = dateFormatter.string(from: Date())
            let fileName = "tablemaker_export_\(dateString).csv"
            let tempDir = FileManager.default.temporaryDirectory
            let fileURL = tempDir.appendingPathComponent(fileName)
            do {
                try csvData.write(to: fileURL, atomically: true, encoding: .utf8)
                let activityVC = UIActivityViewController(activityItems: [fileURL], applicationActivities: nil)
                // iPad support
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let rootVC = windowScene.windows.first?.rootViewController {
                    activityVC.popoverPresentationController?.sourceView = rootVC.view
                    rootVC.present(activityVC, animated: true)
                }
            } catch {
                // Show an alert if export fails
                let alert = UIAlertController(title: "Export Failed", message: "Could not export CSV file. Please try again.", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let rootVC = windowScene.windows.first?.rootViewController {
                    rootVC.present(alert, animated: true)
                }
            }
        }
    }

    // Helper for in-app email
    struct MailViewImpl: UIViewControllerRepresentable {
        @Binding var result: Result<MFMailComposeResult, Error>?

        func makeUIViewController(context: Context) -> MFMailComposeViewController {
            let vc = MFMailComposeViewController()
            vc.setToRecipients(["austinhfrankel@gmail.com"])
                            vc.setSubject("Seat Maker Support") // Changed from "Table Picker Support"
            vc.mailComposeDelegate = context.coordinator
            return vc
        }

        func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: Context) {}

        func makeCoordinator() -> Coordinator {
            Coordinator(self)
        }

        class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
            let parent: MailViewImpl
            init(_ parent: MailViewImpl) { self.parent = parent }
            func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
                if let error = error {
                    parent.result = .failure(error)
                } else {
                    parent.result = .success(result)
                }
                controller.dismiss(animated: true)
            }
        }
    }
    
    // MARK: - Messages compose wrapper
    struct MessageComposeView: UIViewControllerRepresentable {
        let recipients: [String]
        let body: String?
        @Environment(\.dismiss) private var dismiss

        class Coordinator: NSObject, MFMessageComposeViewControllerDelegate {
            var parent: MessageComposeView
            init(parent: MessageComposeView) { self.parent = parent }
            func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
                controller.dismiss(animated: true)
            }
        }

        func makeCoordinator() -> Coordinator { Coordinator(parent: self) }

        func makeUIViewController(context: Context) -> MFMessageComposeViewController {
            let vc = MFMessageComposeViewController()
            vc.messageComposeDelegate = context.coordinator
            vc.recipients = recipients
            if let body = body { vc.body = body }
            return vc
        }

        func updateUIViewController(_ uiViewController: MFMessageComposeViewController, context: Context) {}
    }
    
    // MARK: - Group Text trigger button
    struct GroupTextButton: View {
        @ObservedObject var viewModel: SeatingViewModel
        @State private var showComposer = false
        @State private var recipients: [String] = []
        @State private var showAlert = false
        @State private var alertMessage = ""

        var body: some View {
            Button(action: { Task { await prepareAndShow() } }) {
                Label("Text All Guests", systemImage: "message")
                    .foregroundColor(.white)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 24 + 15)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.green)
                    )
                    .frame(maxWidth: UIScreen.main.bounds.width * 0.6 + 15)
            }
            .disabled(!MFMessageComposeViewController.canSendText())
            .opacity(MFMessageComposeViewController.canSendText() ? 1 : 0.5)
            .sheet(isPresented: $showComposer) {
                MessageComposeView(recipients: recipients, body: defaultBody())
            }
            .alert("Cannot Text Guests", isPresented: $showAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
        }

        private func defaultBody() -> String {
            let title = viewModel.currentArrangement.eventTitle ?? viewModel.currentTableName
            if title.isEmpty { return "Hi everyone – details for your table from Seat Maker." }
            return "Hi everyone – info for \(title) from Seat Maker."
        }

        private func uniquePeopleAcrossNonEmptyTables() -> [Person] {
            let tables = viewModel.tableCollection.tables.values.filter { !$0.people.isEmpty }
            var seen: Set<UUID> = []
            var result: [Person] = []
            for table in tables {
                for p in table.people where !seen.contains(p.id) {
                    seen.insert(p.id)
                    result.append(p)
                }
            }
            return result
        }

        private func prepareAndShow() async {
            guard MFMessageComposeViewController.canSendText() else {
                alertMessage = "This device can't send messages."
                showAlert = true
                return
            }

            let people = uniquePeopleAcrossNonEmptyTables()
            if people.isEmpty {
                alertMessage = "No guests found to text. Add people to a table first."
                showAlert = true
                return
            }

            let numbers = await viewModel.fetchPhoneNumbers(for: people)
            if numbers.isEmpty {
                alertMessage = "Couldn't find phone numbers for these guests in your Contacts. Make sure your contacts include phone numbers and match the guests' names."
                showAlert = true
                return
            }
            recipients = numbers
            showComposer = true
        }
    }

    // A smaller per-table variant that only targets the provided people
    struct GroupTextButtonForPeople: View {
        @ObservedObject var viewModel: SeatingViewModel
        let people: [Person]
        @State private var showComposer = false
        @State private var recipients: [String] = []
        @State private var showAlert = false
        @State private var alertMessage = ""

        var body: some View {
            HStack {
                Spacer()
                Button(action: { Task { await prepareAndShow() } }) {
                    Label("Text This Table", systemImage: "message")
                        .font(.system(size: 14, weight: .semibold))
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.green.opacity(0.9))
                        )
                        .foregroundColor(.white)
                }
                .disabled(!MFMessageComposeViewController.canSendText())
                .opacity(MFMessageComposeViewController.canSendText() ? 1 : 0.5)
            }
            .sheet(isPresented: $showComposer) {
                MessageComposeView(recipients: recipients, body: defaultBody())
            }
            .alert("Cannot Text Guests", isPresented: $showAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
        }

        private func defaultBody() -> String {
            let title = viewModel.currentArrangement.eventTitle ?? viewModel.currentTableName
            if title.isEmpty { return "Hi everyone – details for your table from Seat Maker." }
            return "Hi everyone – info for \(title) from Seat Maker."
        }

        private func prepareAndShow() async {
            guard MFMessageComposeViewController.canSendText() else {
                alertMessage = "This device can't send messages."
                showAlert = true
                return
            }
            if people.isEmpty {
                alertMessage = "No guests found to text."
                showAlert = true
                return
            }
            let numbers = await viewModel.fetchPhoneNumbers(for: people)
            if numbers.isEmpty {
                alertMessage = "Couldn't find phone numbers for these guests in your Contacts. Make sure your contacts include phone numbers and match the guests' names."
                showAlert = true
                return
            }
            recipients = numbers
            showComposer = true
        }
    }
    
    // Helper function to get color for a person
    private func getPersonColor(for index: Int) -> Color {
        personColors[index % personColors.count]
    }
    
    // Helper function to get color for a person by UUID
    private func getPersonColor(for id: UUID, in arrangement: SeatingArrangement) -> Color {
        if let person = arrangement.people.first(where: { $0.id == id }) {
            if person.colorIndex < personColors.count {
                return personColors[person.colorIndex]
            } else if let index = arrangement.people.firstIndex(where: { $0.id == id }) {
                // Ensure everyone gets a different color by cycling through available colors
                return personColors[index % personColors.count]
            }
        }
        return .blue // Default color
    }
    
    // Helper function to get color for a person by UUID in table visualization
    private func getPersonColorForVisualization(for id: UUID, in arrangement: SeatingArrangement) -> Color {
        if let person = arrangement.people.first(where: { $0.id == id }) {
            if person.colorIndex < personColors.count {
                return personColors[person.colorIndex]
            } else if let index = arrangement.people.firstIndex(where: { $0.id == id }) {
                return personColors[index % personColors.count]
            }
        }
        return .blue // Default color
    }
    
    // TableView size logic - further reduced
    private var tableMaxHeight: CGFloat {
        switch viewModel.currentArrangement.tableShape {
        case .round:
            return 520 * 1.43 // Increased by 10% from 1.3
        case .rectangle:
            return 520 * 1.43 // Increased by 10% from 1.3
        case .square:
            return 520 * 1.43 // Increased by 10% from 1.3
        }
    }
    // Completely rewritten TableView implementation to fix rectangle and square tables
    struct TableView: View {
        @Environment(\.heroTableNamespace) private var heroNamespace
        let arrangement: SeatingArrangement
        let getPersonColor: (UUID) -> Color
        let onPersonTap: (Person) -> Void
        
        private let positionCalculator = SeatPositionCalculator()

        private func iconSize(for totalSeats: Int) -> CGFloat {
            switch totalSeats {
            case 1...3: return 40
            case 4...6: return 33
            case 7...9: return 27
            case 10...16: return 22
            default: return 18
            }
        }
        
        var body: some View {
            GeometryReader { geometry in
                let seatPositions = positionCalculator.calculatePositions(
                    for: arrangement.tableShape,
                    in: geometry.size,
                    totalSeats: arrangement.people.count,
                    iconSize: iconSize(for: arrangement.people.count)
                )

                ZStack {
                    tableShape(in: geometry)
                    matchedGeometryAnchor(in: geometry)
                    ForEach(arrangement.people) { person in
                        if let seatNumber = arrangement.seatAssignments[person.id] {
                            if seatPositions.indices.contains(seatNumber) {
                                let position = seatPositions[seatNumber]
                            SeatView(
                                person: person,
                                totalSeats: arrangement.people.count,
                                color: getPersonColor(person.id),
                                    position: position,
                                onTap: { onPersonTap(person) }
                            )
                            .transition(.scale.combined(with: .opacity))
                            }
                        }
                    }
                }
                .animation(.interactiveSpring(response: 0.5, dampingFraction: 0.78, blendDuration: 0.2), value: arrangement.tableShape)
                .animation(.interactiveSpring(response: 0.5, dampingFraction: 0.78, blendDuration: 0.2), value: arrangement.seatAssignments)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.top, 15)
            }
        }
        
        private func tableShape(in geometry: GeometryProxy) -> some View {
            let width = geometry.size.width
            let height = geometry.size.height
            
            switch arrangement.tableShape {
          
 case .round:
                return AnyView(
                    Circle()
                        .stroke(Color.gray.opacity(0.4), lineWidth: 3)
                        .background(Circle().fill(Color.gray.opacity(0.1)))
                        .frame(width: min(width, height) * 0.95, height: min(width, height) * 0.95)
                        .position(x: width/2, y: height/2)
                        .transition(.asymmetric(
                            insertion: .scale(scale: 0.8).combined(with: .opacity),
                            removal: .scale(scale: 0.8).combined(with: .opacity)
                        ))
                        .animation(.interactiveSpring(response: 0.5, dampingFraction: 0.78, blendDuration: 0.2), value: arrangement.tableShape)
                )
            case .rectangle:
                let tableWidth = width * 0.95 // Increased from 0.9 to 0.95
                let tableHeight = height * 0.75 // Increased from 0.7 to 0.75
                return AnyView(
                    Rectangle()
                        .stroke(Color.gray.opacity(0.4), lineWidth: 3)
                        .background(Rectangle().fill(Color.gray.opacity(0.1)))
                        .frame(width: tableWidth, height: tableHeight)
                        .position(x: width/2, y: height/2)
                        .transition(.asymmetric(
                            insertion: .scale(scale: 0.8).combined(with: .opacity),
                            removal: .scale(scale: 0.8).combined(with: .opacity)
                        ))
                        .animation(.interactiveSpring(response: 0.5, dampingFraction: 0.78, blendDuration: 0.2), value: arrangement.tableShape)
                )
            case .square:
                let side = min(width, height) * 0.9
                return AnyView(
                    Rectangle()
                        .stroke(Color.gray.opacity(0.4), lineWidth: 3)
                        .background(Rectangle().fill(Color.gray.opacity(0.1)))
                        .frame(width: side, height: side)
                        .position(x: width/2, y: height/2)
                        .transition(.asymmetric(
                            insertion: .scale(scale: 0.8).combined(with: .opacity),
                            removal: .scale(scale: 0.8).combined(with: .opacity)
                        ))
                        .animation(.interactiveSpring(response: 0.5, dampingFraction: 0.78, blendDuration: 0.2), value: arrangement.tableShape)
                )
            }
        }

        private func matchedGeometryAnchor(in geometry: GeometryProxy) -> some View {
            let width = geometry.size.width
            let height = geometry.size.height
            let overlayFrame: CGSize
            switch arrangement.tableShape {
            case .round:
                let side = min(width, height) * 0.95
                overlayFrame = CGSize(width: side, height: side)
            case .rectangle:
                overlayFrame = CGSize(width: width * 0.95, height: height * 0.75)
            case .square:
                let side = min(width, height) * 0.9
                overlayFrame = CGSize(width: side, height: side)
            }
            return Color.clear
                .frame(width: overlayFrame.width, height: overlayFrame.height)
                .position(x: width/2, y: height/2)
                .heroMatched(ns: heroNamespace)
                .allowsHitTesting(false)
        }
    }

    struct SeatView: View {
        let person: Person
        let totalSeats: Int
        let color: Color
        let position: CGPoint
        let onTap: () -> Void
        @Environment(\.colorScheme) var colorScheme
        
        private func formatName(_ name: String) -> String {
            // Show only first name for table labels
            let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty { return name }
            // If name has parentheses, keep the base name before parenthesis and then take only first token
            let base: String = {
                if let parenIndex = trimmed.firstIndex(of: "(") {
                    return String(trimmed[..<parenIndex]).trimmingCharacters(in: .whitespacesAndNewlines)
                }
                return trimmed
            }()
            if let firstToken = base.split(separator: " ").first {
                return String(firstToken)
            }
            return base
        }
        
        var iconSize: CGFloat {
            switch totalSeats {
            case 1...3: return 40
            case 4...6: return 33
            case 7...9: return 27
            case 10...16: return 22
            default: return 18
            }
        }
        
        var body: some View {
            VStack(spacing: 2) {
                    ZStack {
                        if person.isLocked {
                            Circle()
                                .stroke(Color.accentColor, lineWidth: 3)
                                .frame(width: iconSize + 1, height: iconSize + 1)
                        }
                        Circle()
                            .strokeBorder(colorScheme == .dark ? Color.white.opacity(0.7) : Color.black.opacity(0.2), lineWidth: 1)
                        .background(Circle().fill(color.opacity(colorScheme == .dark ? 0.18 : 0.12)))
                            .frame(width: iconSize, height: iconSize)
                        
                        Group {
                            if let image = person.getProfileImage() {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: iconSize - 4, height: iconSize - 4)
                                    .clipShape(Circle())
                                .overlay(Circle().stroke(Color.white.opacity(0.3), lineWidth: 1))
                            } else {
                                Text(computeInitials(from: person.name))
                                    .font(.system(size: iconSize * 0.45, weight: .bold))
                                    .foregroundColor(color)
                                    .frame(width: iconSize - 4, height: iconSize - 4)
                                .background(Circle().fill(color.opacity(0.2)))
                            }
                        }
                    }
                    Text(formatName(person.name))
                        .font(.caption)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                        .frame(width: max(iconSize * 2, 48))
                        .multilineTextAlignment(.center)
                }
                .position(x: position.x, y: position.y)
                .onTapGesture(perform: onTap)
            }
        }
    
    // Custom button style for press feedback
    struct PressableButtonStyle: ButtonStyle {
        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
                .opacity(configuration.isPressed ? 0.9 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
        }
    }
    
    // MARK: - Share Arrangement (SMS)
    private func shareArrangement() {
        // Create export text with app store link
        var exportText = viewModel.currentArrangement.exportDescription
                    exportText += "\n\n📱 Download Seat Maker App"

        // Render the table as an image with title and people
        let renderer = ImageRenderer(content:
            VStack(spacing: 12) {
                // Header with emojis
                VStack(spacing: 4) {
                    Text("🪑 Table Arrangement")
                        .font(.headline)
                        
                    HStack(spacing: 8) {
                        Label(
                            viewModel.currentArrangement.tableShape.rawValue.capitalized,
                            systemImage: viewModel.currentArrangement.tableShape == .round ? "circle" :
                                        viewModel.currentArrangement.tableShape == .rectangle ? "rectangle" : "square"
                        )
                        .font(.subheadline)
                        
                        Text("•")
                        
                        // Fix pluralization
                        let peopleCount = viewModel.currentArrangement.people.count
                        let peopleText = peopleCount == 1 ? "1 person" : "\(peopleCount) people"
                        
                        Label(
                            peopleText,
                            systemImage: "person.2"
                        )
                        .font(.subheadline)
                    }
                }
                .padding(.top)
                
                // Table with people
            TableView(
                arrangement: viewModel.currentArrangement,
                    getPersonColor: { id in getPersonColor(for: id, in: viewModel.currentArrangement) },
                    onPersonTap: { _ in } // Empty handler as this is just an image
                )
                .frame(width: 320, height: 280)
                .padding(.horizontal)
                
                // Add people list below
                if !viewModel.currentArrangement.people.isEmpty {
                    Divider()
                    Text("Seating Order")
                        .font(.headline)
                        .padding(.top, -4) // Changed from 4 to -4 to move up 8 pixels
                    
                    // Order people by seat number
                    let peopleList = viewModel.currentArrangement.people
                        .sorted { a, b in
                            let seatA = viewModel.currentArrangement.seatAssignments[a.id] ?? 0
                            let seatB = viewModel.currentArrangement.seatAssignments[b.id] ?? 0
                            return seatA < seatB
                        }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(Array(peopleList.enumerated()), id: \.element.id) { index, person in
                            HStack(spacing: 10) {
                                Text("\(index + 1).")
                                    .foregroundColor(.blue)
                                    .fontWeight(.medium)
                                    .frame(width: 28, alignment: .trailing)
                                
                                Circle()
                                    .fill(getPersonColor(for: person.id, in: viewModel.currentArrangement).opacity(0.3))
                                    .frame(width: 30, height: 30)
                                    .overlay(
                                        Text(computeInitials(from: person.name))
                                            .font(.system(size: 12, weight: .semibold))
                                            .foregroundColor(getPersonColor(for: person.id, in: viewModel.currentArrangement))
                                    )
                                
                                Text(person.name.split(separator: " ").first.map(String.init) ?? person.name)
                                    .font(.system(size: 16))
                                
                                if person.isLocked {
                                    Image(systemName: "lock.fill")
                                        .foregroundColor(.blue)
                                }
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 2)
                        }
                    }
                    .padding(.bottom)
                }
            }
            .background(Color(.systemBackground))
            .cornerRadius(12)
        )
        
        if let uiImage = renderer.uiImage {
            let items: [Any] = [uiImage, exportText]
            showExportSheetWithItems(items)
        } else {
            let items: [Any] = [exportText]
            showExportSheetWithItems(items)
        }
    }
    
    private func showExportSheetWithItems(_ items: [Any]) {
        // Use a coordinator to present the ActivityView with custom items
        exportItems = items
        showExportSheet = true
        
    }

    // Present a confirmation sheet with Viewer / Make Editable
    private func presentImportChoice(arrangement: SeatingArrangement) {
        let alert = UIAlertController(title: "Imported ''\(arrangement.title)''", message: "Open read-only or create an editable copy.", preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Open as Viewer", style: .default, handler: { _ in
            // Leave as-is, read-only view can be represented by isViewingHistory true
            viewModel.isViewingHistory = true
        }))
        alert.addAction(UIAlertAction(title: "Make Editable", style: .default, handler: { _ in
            // Create local editable copy and switch out of history mode
            var editable = arrangement
            editable.id = UUID()
            editable.date = Date()
            viewModel.currentArrangement = editable
            viewModel.currentTableName = editable.title
            viewModel.isViewingHistory = false
            viewModel.saveCurrentArrangement()
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            rootVC.present(alert, animated: true) {
                ShareLinkRouter.shared.markPresentationComplete()
            }
        }
    }
    @State private var exportItems: [Any] = []
    
    // QR Code Share View with fixed functionality
    private var qrCodeShareView: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                // Mode controls
                Picker("Mode", selection: $shareModeIsLive) {
                    Text("Snapshot").tag(false)
                    Text("Live Share").tag(true)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                if shareModeIsLive {
                    Toggle("Allow edits for joiners", isOn: $liveAllowEditing)
                        .padding(.horizontal)
                }
                
                // Header with BETA badge (moved up by reducing top padding)
                VStack(spacing: 8) {
                    Text(userName.isEmpty ? "Your Table QR Code" : "\(userName)'s Table QR Code")
                        .font(.title.bold())
                        .multilineTextAlignment(.center)
                    
                    // BETA badge
                    Text("BETA")
                        .font(.caption.bold())
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [.orange, .red],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        )
                        .shadow(color: .orange.opacity(0.3), radius: 4, x: 0, y: 2)
                }
                .padding(.top, 4)
                
                if let qrCode = arrangementQRCode {
                    ZStack {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(
                                LinearGradient(
                                    colors: [Color(.systemBackground), Color(.systemGray6)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .shadow(color: Color.accentColor.opacity(0.15), radius: 15, x: 0, y: 6)
                        
                        VStack(spacing: 12) {
                            Image(uiImage: qrCode)
                                .interpolation(.none)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 240, height: 240)
                                .padding(20)
                            
                            Text("Scan to view table")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .frame(width: 280, height: 300)
                    .padding(.bottom, 6)
                } else {
                    VStack(spacing: 20) {
                        // Enhanced loading animation
                        ZStack {
                            Circle()
                                .stroke(Color.accentColor.opacity(0.2), lineWidth: 8)
                                .frame(width: 80, height: 80)
                            
                            Circle()
                                .trim(from: 0, to: 0.7)
                                .stroke(
                                    LinearGradient(
                                        colors: [.blue, .purple],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    style: StrokeStyle(lineWidth: 8, lineCap: .round)
                                )
                                .frame(width: 80, height: 80)
                                .rotationEffect(.degrees(-90))
                                .animation(.linear(duration: 1).repeatForever(autoreverses: false), value: UUID())
                        }
                        
                        VStack(spacing: 8) {
                            Text("Generating QR Code...")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            // Progress bar
                            GeometryReader { geometry in
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(Color.blue.opacity(0.2))
                                        .frame(height: 8)
                                    
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(
                                            LinearGradient(
                                                colors: [.blue, .purple],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .frame(width: geometry.size.width * qrGenerationProgress, height: 8)
                                        .animation(.easeInOut(duration: 0.3), value: qrGenerationProgress)
                                }
                            }
                            .frame(height: 8)
                            .frame(maxWidth: 200)
                            
                            Text("Creating beautiful table display...")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(30)
                    .onAppear { 
                        // Reset progress and start generation
                        qrGenerationProgress = 0.0
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            generateQRCode()
                        }
                    }
                }
                // Primary share action near the QR so it's higher on screen
                Button(action: {
                    if let qrCode = arrangementQRCode {
                        exportItems = [qrCode]
                        AdsManager.shared.showInterstitialThen {
                            viewModel.showingQRCodeSheet = false
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                                isShowingShareSheet = true
                            }
                        }
                    }
                }) {
                    Label("Share QR Code", systemImage: "square.and.arrow.up")
                        .font(.headline)
                        .padding(.vertical, 10)
                        .padding(.horizontal, 32)
                        .background(RoundedRectangle(cornerRadius: 10).fill(Color.accentColor))
                        .foregroundColor(.white)
                        .shadow(color: Color.accentColor.opacity(0.12), radius: 4, x: 0, y: 2)
                }
                .padding(.top, 4)

                // Show people as mini rows below QR
                if !viewModel.currentArrangement.people.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("People at this table:")
                            .font(.headline)
                            .foregroundColor(.secondary)
                            .padding(.leading, 8)
                        ScrollView(.vertical, showsIndicators: false) {
                            VStack(spacing: 6) {
                                ForEach(Array(viewModel.currentArrangement.people.enumerated()), id: \ .element.id) { idx, person in
                                    MiniPersonRowPreview(
                                        person: person,
                                        seatNumber: viewModel.currentArrangement.seatAssignments[person.id],
                                        color: getPersonColor(for: person.id, in: viewModel.currentArrangement),
                                        isLocked: person.isLocked,
                                        viewModel: viewModel
                                    )
                                    .frame(maxWidth: 220)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                        .frame(maxHeight: 180)
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color(.systemGray6))
                            .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 2)
                    )
                    .padding(.horizontal, 8)
                }
                Spacer(minLength: 4)
                if shareModeIsLive {
                    Button(action: {
                        LiveShareService.shared.stopHostingOrBrowsing()
                    }) {
                        Label("Stop Sharing", systemImage: "wifi.slash")
                            .font(.subheadline)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 16)
                            .background(RoundedRectangle(cornerRadius: 10).fill(Color.red.opacity(0.15)))
                    }
                }
                Spacer(minLength: 0)
            }
            }
            .navigationBarTitle("QR Code", displayMode: .inline)
            .navigationBarItems(
                leading: Button(action: {
                    // Back: dismiss QR and reopen the Share Tables sheet over the create screen
                    viewModel.showingQRCodeSheet = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                        showExportSheet = true
                    }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                        Text("Back")
                    }
                }.tint(.blue),
                trailing: Button("Done") {
                showingQRCodeSheet = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    if shareModeIsLive {
                        LiveShareService.shared.stopHostingOrBrowsing()
                    }
                    resetToEmptyTable()
                    showEffortlessScreen = true
                    viewModel.refreshStatistics()
                    viewModel.showingQRCodeSheet = false
                }
            }.tint(.blue))
        }
    }
    
    // Function to generate QR/link using new ShareLayoutCoordinator
    private func generateQRCode() {
        let arrangement = viewModel.currentArrangement
        Task {
            self.qrGenerationProgress = 0.2
            let result = await ShareLayoutCoordinator.shared.generateShareLink(arrangement: arrangement, preferServerless: true)
            self.qrGenerationProgress = 0.6
            self.generateQRFromDataURL(result.viewerURL.absoluteString)
        }
    }
    // Create HTML content for the table display
    private func createTableHTML(arrangement: SeatingArrangement, tableName: String) -> String {
        
        // Sort people by seat number
        let sortedPeople = arrangement.people.sorted {
            let seatA = arrangement.seatAssignments[$0.id] ?? 0
            let seatB = arrangement.seatAssignments[$1.id] ?? 0
            return seatA < seatB
        }
        
        // Generate people HTML with colors
        let peopleHTML = sortedPeople.map { person in
            let seatNumber = (arrangement.seatAssignments[person.id] ?? 0) + 1
            let lockIcon = person.isLocked ? " 🔒" : ""
            let personColor = getPersonColorHex(for: person.id, in: arrangement)
            return """
            <div class='person-item'>
                <div class='person-color' style='background-color: \(personColor);'></div>
                <span class='person-name'>\(person.name)\(lockIcon)</span>
                <span class='seat-number'>\(seatNumber)</span>
            </div>
            """
        }.joined()
        
        let shapeDisplay = getShapeDisplay(arrangement.tableShape.rawValue)
        let tableIcon = getTableIcon(arrangement.tableShape.rawValue)
        
        return """
        <!DOCTYPE html>
        <html lang="en">
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0, user-scalable=no">
            <title>\(tableName) - Seat Maker</title>
            <style>
                * {
                    box-sizing: border-box;
                }
                body { 
                    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; 
                    margin: 0; 
                    padding: 16px; 
                    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                    min-height: 100vh;
                    color: #333;
                    display: flex;
                    align-items: center;
                    justify-content: center;
                }
                .container { 
                    max-width: 380px; 
                    width: 100%;
                    background: white; 
                    border-radius: 24px; 
                    padding: 24px; 
                    box-shadow: 0 20px 40px rgba(0,0,0,0.15);
                    text-align: center;
                }
                .title { 
                    font-size: 24px; 
                    font-weight: 700; 
                    margin-bottom: 8px; 
                    color: #1a1a1a;
                    line-height: 1.2;
                }
                .subtitle { 
                    color: #666; 
                    margin-bottom: 24px; 
                    font-size: 14px;
                    font-weight: 500;
                }
                .shape-badge {
                    display: inline-block;
                    background: #e9ecef;
                    color: #495057;
                    padding: 4px 12px;
                    border-radius: 12px;
                    font-size: 11px;
                    font-weight: 600;
                    text-transform: uppercase;
                    margin-bottom: 20px;
                }
                .table-container {
                    position: relative;
                    margin: 20px auto;
                    width: 200px;
                    height: 200px;
                    display: flex;
                    align-items: center;
                    justify-content: center;
                }
                .table-visual { 
                    width: 160px; 
                    height: 160px; 
                    border: 3px solid #4299e1; 
                    background: linear-gradient(135deg, rgba(66, 153, 225, 0.1) 0%, rgba(66, 153, 225, 0.05) 100%);
                    display: flex;
                    align-items: center;
                    justify-content: center;
                    font-size: 16px;
                    color: #4299e1;
                    font-weight: 600;
                    box-shadow: inset 0 2px 4px rgba(0,0,0,0.1);
                    position: relative;
                    \(arrangement.tableShape == .round ? "border-radius: 50%;" : "border-radius: 12px;")
                }
                .seat-visual {
                    position: absolute;
                    width: 32px;
                    height: 32px;
                    border-radius: 50%;
                    display: flex;
                    align-items: center;
                    justify-content: center;
                    font-weight: 600;
                    color: white;
                    font-size: 11px;
                    border: 2px solid white;
                    box-shadow: 0 2px 6px rgba(0,0,0,0.2);
                    text-shadow: 0 1px 2px rgba(0,0,0,0.3);
                }
                .people-list { 
                    margin-top: 24px; 
                    text-align: left;
                }
                .people-title { 
                    font-size: 18px; 
                    font-weight: 600; 
                    margin-bottom: 16px; 
                    text-align: center;
                    color: #1a1a1a;
                }
                .person-item { 
                    display: flex; 
                    align-items: center; 
                    padding: 12px 16px; 
                    margin: 8px 0; 
                    background: #f8f9fa; 
                    border-radius: 12px;
                    border-left: 4px solid #4299e1;
                    box-shadow: 0 2px 4px rgba(0,0,0,0.05);
                }
                .person-color {
                    width: 24px;
                    height: 24px;
                    border-radius: 50%;
                    margin-right: 12px;
                    box-shadow: 0 2px 4px rgba(0,0,0,0.1);
                }
                .person-name { 
                    font-size: 14px; 
                    font-weight: 500;
                    flex: 1;
                    color: #1a1a1a;
                }
                .seat-number { 
                    background: linear-gradient(135deg, #4299e1 0%, #3182ce 100%);
                    color: white; 
                    border-radius: 12px; 
                    padding: 6px 10px;
                    font-weight: 600; 
                    font-size: 12px;
                    box-shadow: 0 2px 4px rgba(66, 153, 225, 0.3);
                }
                .footer { 
                    margin-top: 24px; 
                    padding-top: 20px; 
                    border-top: 1px solid #e2e8f0; 
                    color: #718096; 
                    font-size: 13px;
                }
                .app-link {
                    display: inline-block;
                    background: linear-gradient(135deg, #4299e1 0%, #3182ce 100%);
                    color: white;
                    text-decoration: none;
                    padding: 12px 24px;
                    border-radius: 20px;
                    margin-top: 12px;
                    font-weight: 600;
                    font-size: 14px;
                    transition: all 0.3s;
                    box-shadow: 0 4px 12px rgba(66, 153, 225, 0.3);
                }
                .app-link:hover {
                    transform: translateY(-2px);
                    box-shadow: 0 6px 16px rgba(66, 153, 225, 0.4);
                }
            </style>
        </head>
        <body>
            <div class="container">
                <div class="title">\(tableName)</div>
                <div class="subtitle">\(sortedPeople.count) \(sortedPeople.count == 1 ? "person" : "people")</div>
                <div class="shape-badge">\(shapeDisplay)</div>
                
                <div class="table-container">
                    <div class="table-visual">
                        \(tableIcon) Table
                    </div>
                    \(generateSeatsHTML(arrangement: arrangement))
                </div>
                
                <div class="people-list">
                    <div class="people-title">📋 Seating Arrangement</div>
                    \(peopleHTML)
                </div>
                
                <div class="footer">
                    Created with Seat Maker
                    <br>
                    <a href="https://apps.apple.com/app/seat-maker" class="app-link">📱 Download Seat Maker</a>
                </div>
            </div>
        </body>
        </html>
        """
    }
    
    private func getShapeDisplay(_ shape: String) -> String {
        switch shape.lowercased() {
        case "round": return "Round Table"
        case "square": return "Square Table"
        case "rectangle": return "Rectangle Table"
        default: return "Table"
        }
    }
    
    private func getTableIcon(_ shape: String) -> String {
        switch shape.lowercased() {
        case "round": return "◯"
        case "square": return "□"
        case "rectangle": return "▭"
        default: return "◯"
        }
    }
    
    // Helper function to get person color in hex format for HTML
    private func getPersonColorHex(for id: UUID, in arrangement: SeatingArrangement) -> String {
        let color = getPersonColor(for: id, in: arrangement)
        
        // Convert SwiftUI Color to hex string
        switch color {
        case .blue: return "#007AFF"
        case .green: return "#34C759"
        case .orange: return "#FF9500"
        case .purple: return "#AF52DE"
        case .pink: return "#FF2D92"
        case .red: return "#FF3B30"
        case .teal: return "#5AC8FA"
        case .indigo: return "#5856D6"
        case .mint: return "#00C7BE"
        case .yellow: return "#FFCC00"
        case .cyan: return "#32ADE6"
        case .brown: return "#A2845E"
        default: return "#007AFF"
        }
    }
    // Helper function to get person color name for JSON
    private func getPersonColorName(for id: UUID, in arrangement: SeatingArrangement) -> String {
        let color = getPersonColor(for: id, in: arrangement)
        
        // Convert SwiftUI Color to color name
        switch color {
        case .blue: return "blue"
        case .green: return "green"
        case .orange: return "orange"
        case .purple: return "purple"
        case .pink: return "pink"
        case .red: return "red"
        case .teal: return "teal"
        case .indigo: return "indigo"
        case .mint: return "mint"
        case .yellow: return "yellow"
        case .cyan: return "cyan"
        case .brown: return "brown"
        default: return "blue"
        }
    }
    
    // Generate HTML for visual seat positions around the table
    private func generateSeatsHTML(arrangement: SeatingArrangement) -> String {
        let people = arrangement.people
        guard !people.isEmpty else { return "" }
        
        let seatHTML = people.enumerated().map { index, person in
            let seatNumber = (arrangement.seatAssignments[person.id] ?? index) + 1
            let personColor = getPersonColorHex(for: person.id, in: arrangement)
            let position = calculateSeatPosition(
                index: index, 
                total: people.count, 
                tableShape: arrangement.tableShape
            )
            
            return """
            <div class="seat-visual" style="
                background-color: \(personColor);
                left: \(position.x)px;
                top: \(position.y)px;
            ">\(seatNumber)</div>
            """
        }.joined()
        
        return seatHTML
    }
    
    // Calculate seat position around the table perimeter
    private func calculateSeatPosition(index: Int, total: Int, tableShape: TableShape) -> CGPoint {
        let centerX: CGFloat = 100 // Center of 200px container
        let centerY: CGFloat = 100
        let radius: CGFloat = 90 // Distance from center
        
        switch tableShape {
        case .round:
            let angle = (2 * Double.pi * Double(index)) / Double(total)
            let x = centerX + radius * cos(angle) - 16 // -16 for half seat width
            let y = centerY + radius * sin(angle) - 16 // -16 for half seat height
            return CGPoint(x: x, y: y)
            
        case .rectangle:
            let perimeter = 4
            let sideLength = total / perimeter
            let remainder = total % perimeter
            
            if index < sideLength + (remainder > 0 ? 1 : 0) {
                // Top side
                let x = centerX - 60 + (120 * CGFloat(index)) / CGFloat(sideLength + (remainder > 0 ? 1 : 0)) - 16
                return CGPoint(x: x, y: centerY - 70)
            } else if index < 2 * sideLength + (remainder > 1 ? 1 : 0) {
                // Right side
                let sideIndex = index - sideLength - (remainder > 0 ? 1 : 0)
                let y = centerY - 60 + (120 * CGFloat(sideIndex)) / CGFloat(sideLength + (remainder > 1 ? 1 : 0)) - 16
                return CGPoint(x: centerX + 70, y: y)
            } else if index < 3 * sideLength + (remainder > 2 ? 1 : 0) {
                // Bottom side
                let sideIndex = index - 2 * sideLength - (remainder > 1 ? 1 : 0)
                let x = centerX + 60 - (120 * CGFloat(sideIndex)) / CGFloat(sideLength + (remainder > 2 ? 1 : 0)) - 16
                return CGPoint(x: x, y: centerY + 70)
            } else {
                // Left side
                let sideIndex = index - 3 * sideLength - (remainder > 2 ? 1 : 0)
                let y = centerY + 60 - (120 * CGFloat(sideIndex)) / CGFloat(sideLength + (remainder > 3 ? 1 : 0)) - 16
                return CGPoint(x: centerX - 70, y: y)
            }
            
        case .square:
            // Similar to rectangle but with equal sides
            let angle = (2 * Double.pi * Double(index)) / Double(total)
            let x = centerX + 70 * cos(angle) - 16
            let y = centerY + 70 * sin(angle) - 16
            return CGPoint(x: x, y: y)
        }
    }
    
    // Helper function to create a text-based QR code as fallback
    private func createTextBasedQRCode(from text: String) {
        if let qrFilter = CIFilter(name: "CIQRCodeGenerator") {
            let data = text.data(using: .utf8)
            qrFilter.setValue(data, forKey: "inputMessage")
            qrFilter.setValue("M", forKey: "inputCorrectionLevel")
            
            if let qrImage = qrFilter.outputImage {
                let transform = CGAffineTransform(scaleX: 10, y: 10)
                let scaledQrImage = qrImage.transformed(by: transform)
                
                let ciContext = CIContext(options: [.useSoftwareRenderer: false])
                if let cgImage = ciContext.createCGImage(scaledQrImage, from: scaledQrImage.extent) {
                    self.arrangementQRCode = UIImage(cgImage: cgImage)
                }
            }
        }
        
        // If still nil, create an ultra-simple fallback
        if arrangementQRCode == nil {
            let renderer = UIGraphicsImageRenderer(size: CGSize(width: 250, height: 250))
            arrangementQRCode = renderer.image { _ in
                UIColor.white.setFill()
                UIBezierPath(rect: CGRect(x: 0, y: 0, width: 250, height: 250)).fill()
                
                let attrs: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 16),
                    .foregroundColor: UIColor.black
                ]
                
                "Table Arrangement\n\(viewModel.currentArrangement.title)".draw(
                    with: CGRect(x: 25, y: 100, width: 200, height: 50),
                    options: .usesLineFragmentOrigin,
                    attributes: attrs,
                    context: nil
                )
            }
        }
    }
    
    // MARK: - ContactsPickerView
    struct ContactsPickerView: View {
        let contacts: [String]
        var searchText: String = ""
        let onSelect: ([String]) -> Void
        let onSmartSeating: ([String]) -> Void
        @State private var localSearchText: String = ""
        @State private var selectedContacts: Set<String> = []
        @State private var isMultiSelectMode: Bool = false
        @Environment(\.dismiss) private var dismiss
        
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
                    .background(Color(.systemGray6)) // Add background color
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
                                    // Fire the same alert flow used when permission is denied
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
                                    .padding(.vertical, 6) // Add vertical padding
                                }
                                .accessibilityLabel(contact)
                                .accessibilityHint("Select to add \(contact) to the table")
                            }
                        }
                        .listStyle(PlainListStyle())
                    }
                }
                .navigationTitle("Select Contacts")
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Cancel") {
                            dismiss()
                        }
                        .tint(.blue)
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Smart Seating") {
                            if !selectedContacts.isEmpty {
                                onSmartSeating(Array(selectedContacts))
                            }
                        }
                        .disabled(selectedContacts.isEmpty)
                        .tint(.blue)
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") {
                            if !selectedContacts.isEmpty {
                                onSelect(Array(selectedContacts))
                            }
                        }
                        .disabled(selectedContacts.isEmpty)
                        .tint(.blue)
                    }
                }
                .onAppear {
                    localSearchText = searchText
                    // Auto-enable multi-select
                    isMultiSelectMode = true
                }
            }
            .accessibilityLabel("Select Contact")
            .accessibilityHint("Search for and select contacts to add to the table")
        }
    }
    
    // MARK: - Helper Views
    
    struct ActivityView: UIViewControllerRepresentable {
        let activityItems: [Any]
        
        func makeUIViewController(context: Context) -> UIActivityViewController {
            UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
        }
        
        func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
    }
    
    struct ImagePicker: UIViewControllerRepresentable {
        @Binding var image: UIImage?
        @Environment(\.presentationMode) private var presentationMode
        
        func makeUIViewController(context: Context) -> PHPickerViewController {
            var config = PHPickerConfiguration()
            config.filter = .images
            config.selectionLimit = 1
            let picker = PHPickerViewController(configuration: config)
            picker.delegate = context.coordinator
            return picker
        }
        
        func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
        
        func makeCoordinator() -> Coordinator {
            Coordinator(self)
        }
        
        class Coordinator: NSObject, PHPickerViewControllerDelegate {
            let parent: ImagePicker
            init(_ parent: ImagePicker) { self.parent = parent }
            func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
                picker.dismiss(animated: true)
                guard let provider = results.first?.itemProvider, provider.canLoadObject(ofClass: UIImage.self) else { return }
                provider.loadObject(ofClass: UIImage.self) { image, _ in
                    DispatchQueue.main.async {
                        self.parent.image = image as? UIImage
                    }
                }
            }
        }
    }
    
    // MARK: - HistoryView
struct TermsView: View {
    let onDismiss: () -> Void
    @State private var isLoading = true
        @State private var selectedTab = 0
        @State private var showingEmailAlert = false
        
    var body: some View {
            VStack(spacing: 0) {
                // Header with title and close button
                HStack {
                    Spacer()
                    Text("Privacy & Settings")
                .font(.title2).fontWeight(.bold)
                    Spacer()
                    Button(action: onDismiss) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.gray)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 16)
                .padding(.bottom, 12)
                
                // Tab selection
                Picker("", selection: $selectedTab) {
                    Text("Privacy Policy").tag(0)
                    Text("Data Usage").tag(1)
                    Text("Support").tag(2)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                .padding(.bottom, 16)
                
            if isLoading {
                    Spacer()
                ProgressView()
                    .scaleEffect(1.2)
                    .padding(.vertical, 24)
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            isLoading = false
                        }
                    }
                    Spacer()
            } else {
                    TabView(selection: $selectedTab) {
                        // Privacy Policy Tab
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        Text("Privacy Policy")
                            .font(.headline)
                                .foregroundColor(.primary) // Changed from .purple to .primary
                            .padding(.bottom, 4)
                                
                                Group {
                                    Text("Last Updated: \(formattedDate())")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                        .padding(.bottom, 10)
                                    
                                    Text("Seat Maker takes your privacy seriously. This policy explains how we handle your information.") // Changed from "Table Picker"
                                        .padding(.bottom, 8)
                                    
                                    Text("Information We Don't Collect")
                            .font(.headline)
                                    .foregroundColor(.primary) // Changed from .purple to .primary
                                        .padding(.vertical, 4)
                                    
                                    Text("Seat Maker does not collect, store, or transmit any personal data, including but not limited to:")
                                        .padding(.bottom, 4)
                                    
                                    VStack(alignment: .leading, spacing: 6) {
                                        bulletPoint("Personal identifiers")
                                        bulletPoint("Contact information")
                                        bulletPoint("Location data")
                                        bulletPoint("Usage statistics")
                                        bulletPoint("Browsing history")
                                    }
                                    .padding(.bottom, 12)
                                    
                                    Text("Data Storage")
                                        .font(.headline)
                                    .foregroundColor(.primary) // Changed from .purple to .primary
                                        .padding(.vertical, 4)
                                    
                                    Text("All data, including seating arrangements and settings, is stored locally on your device only. No backups or copies are stored on remote servers.")
                                        .padding(.bottom, 12)
                                    
                                    Text("Third-Party Services")
                                        .font(.headline)
                                    .foregroundColor(.primary) // Changed from .purple to .primary
                                        .padding(.vertical, 4)
                                    
                                    Text("Seat Maker does not integrate with any third-party analytics, advertising, or tracking services.")
                                        .padding(.bottom, 12)
                                }
                    }
                    .padding()
                }
                        .tag(0)
                        
                        // Data Usage Tab
                        ScrollView {
                            VStack(alignment: .leading, spacing: 18) {
                                Text("Data Usage Information")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                    .padding(.bottom, 4)
                                
                                Group {
                                    Text("Seat Maker is designed with privacy as a priority:") // Changed from "Table Picker"
                                        .padding(.bottom, 8)
                                    
                                    Text("Local Storage Only")
                                        .font(.headline)
                                    .foregroundColor(.primary) // Changed from .pink to .primary
                                        .padding(.vertical, 4)
                                    
                                    Text("All data including table arrangements, people names, and settings are stored only on your device and never transmitted elsewhere.")
                                        .padding(.bottom, 12)
                                    
                                    Text("No Internet Required")
                                        .font(.headline)
                                    .foregroundColor(.primary) // Changed from .pink to .primary
                                        .padding(.vertical, 4)
                                    
                                    Text("Seat Maker functions completely offline and does not require internet access to operate.") // Changed from "Table Picker"
                                        .padding(.bottom, 12)
                                    
                                    Text("Data Deletion")
                                        .font(.headline)
                                    .foregroundColor(.primary) // Changed from .pink to .primary
                                        .padding(.vertical, 4)
                                    
                                    Text("To delete your data, you can:")
                                        .padding(.bottom, 4)
                                    
                                    VStack(alignment: .leading, spacing: 6) {
                                        bulletPoint("Clear individual seating arrangements using the History view")
                                        bulletPoint("Delete all seating history in the Settings tab")
                                        bulletPoint("Uninstall the app to remove all data completely")
                                    }
                                    .padding(.bottom, 12)
                                }
                            }
                            .padding()
                        }
                        .tag(1)
                        
                        // Support Tab
                        ScrollView {
                            VStack(alignment: .leading, spacing: 18) {
                                Text("Contact Support")
                .font(.headline)
                                    .padding(.bottom, 4)
                                
                                Group {
                                    Text("If you have any questions, feedback, or need assistance with Seat Maker, please don't hesitate to contact us:") // Changed from "Table Picker"
                                        .padding(.bottom, 16)
                                    
                                    VStack(alignment: .center, spacing: 20) {
                                        Button(action: {
                                            showingEmailAlert = true
                                        }) {
                                            HStack {
                                                Image(systemName: "envelope.fill")
                                                    .font(.system(size: 18))
                                            Text("Email Me")
                                                    .font(.system(size: 16, weight: .medium))
                                            }
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 20)
                                            .padding(.vertical, 12)
                                            .background(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .fill(Color.accentColor)
                                            )
                                        }
                                        .padding(.bottom, 20)
                                        
                                        Text("Response Time")
                                            .font(.headline)
                                            .padding(.top, 8)
                                        
                                        Text("We aim to respond to all inquiries within 48 hours.")
                                            .multilineTextAlignment(.center)
                                            .padding(.horizontal)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 20)
                                    
                                    Divider()
                                    
                                    Text("App Permissions")
                                        .font(.headline)
                                        .padding(.top, 12)
                                        .padding(.bottom, 4)
                                    
                                    Text("Seat Maker requests the following device permissions:") // Changed from "Table Picker"
                                        .padding(.bottom, 4)
                                    
                                    permissionRow(
                                        icon: "square.and.arrow.up",
                                        title: "Sharing",
                                        description: "Used only when you choose to share a seating arrangement."
                                    )
                                }
                            }
                .padding()
        }
                        .tag(2)
                        .alert(isPresented: $showingEmailAlert) {
                            Alert(
                                title: Text("Contact Support"),
                                message: Text("Would you like to send an email to austinhfrankel@gmail.com?"),
                                primaryButton: .default(Text("Open Mail")) {
                                    openEmail()
                                },
                                secondaryButton: .cancel()
                            )
                        }
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                }
            }
            .background(Color(.systemGroupedBackground).edgesIgnoringSafeArea(.all))
        }
        
        private func bulletPoint(_ text: String) -> some View {
            HStack(alignment: .top, spacing: 8) {
                Text("•")
                    .font(.system(size: 14, weight: .bold))
                Text(text)
                    .font(.system(size: 15))
            }
        }
        
        private func permissionRow(icon: String, title: String, description: String) -> some View {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(.blue)
                    .frame(width: 24, height: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 16, weight: .medium))
                    Text(description)
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 4)
        }
        
        private func formattedDate() -> String {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MMMM yyyy"
            return dateFormatter.string(from: Date())
        }
        
        private func openEmail() {
            if let url = URL(string: "mailto:austinhfrankel@gmail.com") {
                UIApplication.shared.open(url)
            }
        }
    }
    
    // Helper function to generate QR from data URL
    private func generateQRFromDataURL(_ dataURL: String) {
        // Update progress: URL created
        DispatchQueue.main.async {
            self.qrGenerationProgress = 0.6
        }
        
        guard let data = dataURL.data(using: .utf8) else { 
            DispatchQueue.main.async {
                self.createTextBasedQRCode(from: "Table arrangement data")
                self.qrGenerationProgress = 1.0
            }
            return 
        }

        // Update progress: Generating QR
        DispatchQueue.main.async {
            self.qrGenerationProgress = 0.8
        }

        let filter = CIFilter.qrCodeGenerator()
        filter.setValue(data, forKey: "inputMessage")
        filter.setValue("H", forKey: "inputCorrectionLevel") // High error correction

        guard let outputImage = filter.outputImage else { 
            DispatchQueue.main.async {
                self.createTextBasedQRCode(from: "Table arrangement data")
                self.qrGenerationProgress = 1.0
            }
            return 
        }

        // Scale the image for better quality
        let scale = 12.0
        let transformedImage = outputImage.transformed(by: CGAffineTransform(scaleX: scale, y: scale))

        // Create UIImage with better quality
        let context = CIContext(options: [.useSoftwareRenderer: false])
        guard let cgImage = context.createCGImage(transformedImage, from: transformedImage.extent) else { 
            DispatchQueue.main.async {
                self.createTextBasedQRCode(from: "Table arrangement data")
                self.qrGenerationProgress = 1.0
            }
            return 
        }

        // Update UI on main thread
        DispatchQueue.main.async {
            self.arrangementQRCode = UIImage(cgImage: cgImage)
            self.qrGenerationProgress = 1.0
            
            // Verify QR code was created successfully
            if self.arrangementQRCode == nil {
                self.createTextBasedQRCode(from: "Table arrangement data")
            }
        }
    }
    
    // Create a simplified HTML version for smaller QR codes
    private func createSimplifiedTableHTML(arrangement: SeatingArrangement, tableName: String) -> String {
        
        // Sort people by seat number
        let sortedPeople = arrangement.people.sorted {
            let seatA = arrangement.seatAssignments[$0.id] ?? 0
            let seatB = arrangement.seatAssignments[$1.id] ?? 0
            return seatA < seatB
        }
        
        // Generate simplified people HTML
        let peopleHTML = sortedPeople.map { person in
            let seatNumber = (arrangement.seatAssignments[person.id] ?? 0) + 1
            let lockIcon = person.isLocked ? " 🔒" : ""
            return "<div>\(seatNumber). \(person.name)\(lockIcon)</div>"
        }.joined()
        
        return """
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>\(tableName)</title>
            <style>
                body{font-family:Arial;margin:20px;background:#667eea;color:#fff;text-align:center}
                .container{background:#fff;color:#333;padding:20px;border-radius:15px;max-width:300px;margin:0 auto}
                .title{font-size:20px;font-weight:bold;margin-bottom:10px}
                .table{width:100px;height:100px;border:2px solid #4299e1;margin:15px auto;border-radius:\(arrangement.tableShape == .round ? "50%" : "10px");background:#f0f8ff;display:flex;align-items:center;justify-content:center;font-weight:bold;color:#4299e1}
                .people div{padding:5px;margin:3px 0;background:#f8f9fa;border-radius:5px;text-align:left}
            </style>
        </head>
        <body>
            <div class="container">
                <div class="title">\(tableName)</div>
                <div class="table">Table</div>
                <div class="people">\(peopleHTML)</div>
                <div style="margin-top:15px;font-size:12px;color:#666">Created with Seat Maker</div>
            </div>
        </body>
        </html>
        """
    }
    
    // Person name with double-tap edit functionality
    struct PersonNameView: View {
        let person: Person
        let onUpdate: (String) -> Void
        var showDoneButtonOnRight: Bool = false
        @State private var isEditing = false
        @State private var editedName: String = ""
        @State private var keyboardHeight: CGFloat = 0
        var body: some View {
            if isEditing {
                HStack(spacing: 8) {
                    TextField("Name", text: $editedName, onCommit: {
                        finishEditing()
                    })
                    .font(.headline)
                    .padding(10)
                    .background(Color(.systemBackground))
                    .cornerRadius(16)
                    .shadow(color: Color.black.opacity(0.12), radius: 6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.accentColor, lineWidth: 1.5)
                    )
                    .frame(width: 120) // Fixed width to match non-editing state
                    .zIndex(100)
                    if showDoneButtonOnRight {
                        Button(action: finishEditing) {
                            Text("Done")
                                .font(.headline)
                                .foregroundColor(.blue)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 6)
                                .background(Color.blue.opacity(0.08))
                                .cornerRadius(8)
                        }
                    }
                }
            } else {
                Text(person.name)
                    .font(.headline)
                    .lineLimit(1)
                    .minimumScaleFactor(0.9)
                    .frame(width: 120) // Fixed width to match editing state
                    .onTapGesture {
                        isEditing = true
                        editedName = person.name
                    }
            }
        }
        private func finishEditing() {
            if !editedName.isEmpty {
                onUpdate(editedName)
            }
            isEditing = false
        }
    }
    
    // Helper structs for keyboard avoidance
    struct ViewOffsetKey: PreferenceKey {
        static var defaultValue: CGFloat = 0
        static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
            value = nextValue()
        }
    }
    
    struct KeyboardAvoidingOverlay: View {
        let keyboardHeight: CGFloat
        
        var body: some View {
            GeometryReader { proxy in
                Color.clear
                    .preference(key: ViewOffsetKey.self, value: proxy.frame(in: .global).minY)
            }
            .frame(height: keyboardHeight / 2) // Use partial height to reduce distortion
        }
    }
    // Profile editor view with enhanced design
    private var profileEditorView: some View {
        NavigationView {
            ScrollView {
                ZStack {
                    // Background gradient - extends through entire view
                    LinearGradient(
                        gradient: Gradient(colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.05)]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .ignoresSafeArea(.all)
                    
                    VStack(spacing: 24) {
                        // Name editing section comes FIRST now (moved above icon section)
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Profile Name")
                                .font(.headline)
                                .foregroundColor(.secondary)
                                .padding(.leading, 4)
                            
                            TextField("Enter name", text: $editingPersonName)
                                .font(.title3)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.secondary.opacity(0.1))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                                        )
                                )
                                .autocapitalization(.words)
                                .submitLabel(.done)
                        }
                        .padding(.horizontal)
                        .padding(.top, 15)
                    
                    // Profile image/icon section with enhanced visuals
                    VStack(spacing: 16) {
                        ZStack {
                            // Create layered background for profile image
                            Circle()
                                .fill(selectedProfileColor.opacity(0.1))
                                .frame(width: 140, height: 140)
                            Circle()
                                .fill(selectedProfileColor.opacity(0.2))
                                .frame(width: 130, height: 130)
                            
                            // Profile image display
                            if let image = profileImage {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 120, height: 120)
                                    .clipShape(Circle())
                                    .overlay(
                                        Circle()
                                            .stroke(Color.white, lineWidth: 3)
                                    )
                                    .shadow(radius: 3)
                            } else {
                                Text(computeInitials(from: editingPersonName))
                                    .font(.system(size: 60, weight: .semibold))
                                    .foregroundColor(selectedProfileColor)
                                    .frame(width: 120, height: 120)
                                    .background(
                                        Circle()
                                            .fill(selectedProfileColor.opacity(0.2))
                                    )
                                    .overlay(
                                        Circle()
                                            .stroke(Color.white, lineWidth: 3)
                                    )
                            }
                        }
                        .overlay(
                            Button(action: {
                                // Always check and request photo permission before showing picker
                                let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
                                if status == .notDetermined {
                                    PHPhotoLibrary.requestAuthorization(for: .readWrite) { newStatus in
                                        DispatchQueue.main.async {
                                            if newStatus == .authorized || newStatus == .limited {
                                                showingImagePicker = true
                                            } else {
                                                permissionDeniedPhoto = true
                                            }
                                        }
                                    }
                                } else if status == .authorized || status == .limited {
                                    showingImagePicker = true
                                } else {
                                    permissionDeniedPhoto = true
                                }
                            }) {
                                ZStack {
                                    Circle()
                                        .fill(Color.accentColor)
                                        .frame(width: 44, height: 44)
                                        .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
                                    Image(systemName: "camera.fill")
                                        .font(.system(size: 20))
                                        .foregroundColor(.white)
                                }
                            }
                            .offset(x: 35, y: 5), // Moved closer: was x: 50, y: 10, now x: 35, y: 5
                            alignment: .bottomTrailing
                        )
                        
                        Text("Choose Profile Color")
                            .font(.headline)
                            .foregroundColor(.secondary)
                            .padding(.top, 10)
                        
                        // Enhanced color picker with better highlighting
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 15), count: 4), spacing: 15) {
                            ForEach(personColors, id: \ .self) { color in
                                Button(action: {
                                    withAnimation(.spring(response: 0.2)) {
                                        selectedProfileColor = color
                                        // Update the person's color immediately
                                        if let index = editingPersonIndex {
                                            viewModel.updatePersonColorIndex(personId: viewModel.currentArrangement.people[index].id, colorIndex: personColors.firstIndex(of: color) ?? 0)
                                            // Save the arrangement to persist the color change
                                            viewModel.saveCurrentArrangement()
                                        }
                                    }
                                }) {
                                    ZStack {
                                        Circle()
                                            .fill(color)
                                            .frame(width: 50, height: 50)
                                        
                                        if selectedProfileColor == color {
                                            Circle()
                                                .strokeBorder(Color.white, lineWidth: 3)
                                                .frame(width: 50, height: 50)
                                            
                                            Circle()
                                                .fill(Color.white)
                                                .frame(width: 15, height: 15)
                                        }
                                        
                                        // Always show initials
                                        if !editingPersonName.isEmpty {
                                            Text(computeInitials(from: editingPersonName))
                                                .font(.system(size: 20, weight: .semibold))
                                                .foregroundColor(.white)
                                        }
                                    }
                                }
                                .frame(minWidth: 44, minHeight: 44) // Ensure minimum touch target
                                .buttonStyle(PlainButtonStyle())
                                .shadow(color: Color.black.opacity(0.1), radius: 2)
                                .scaleEffect(selectedProfileColor == color ? 1.1 : 1.0)
                            }
                        }
                        .padding(.horizontal)
                        
                        // Add a comment box below the color picker
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Comments")
                            .font(.headline)
                            .foregroundColor(.secondary)
                            .padding(.leading, 4)
                                .padding(.top, 10)
                            
                            ZStack(alignment: .topLeading) {
                                TextEditor(text: $editingPersonComment)
                                    .frame(height: 120) // Increased from 80 to 120
                                    .padding(8)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color.secondary.opacity(0.1))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                                            )
                                    )
                                    .submitLabel(.done)
                                if editingPersonComment.isEmpty {
                                    Text("Add notes about this person...")
                                        .foregroundColor(.secondary.opacity(0.7))
                                        .padding(.leading, 14)
                                        .padding(.top, 16)
                                }
                            }
                    }
                    .padding(.horizontal)
                        .padding(.top, 10)
                    }
                    .padding(.bottom, 10)
                    
                        Spacer(minLength: 100) // Add extra space at bottom for keyboard
                    }
                }
            }
            .navigationBarTitle("Edit Profile", displayMode: .inline)
            .navigationBarItems(
                leading: Button(action: { 
                    // Reset profile image when canceling
                    profileImage = nil
                    showingProfileEditor = false 
                }) {
                    Text("Cancel")
                        .fontWeight(.medium)
                },
                trailing: Button(action: {
                    if let index = editingPersonIndex {
                        var updatedPerson = viewModel.currentArrangement.people[index]
                        updatedPerson.name = editingPersonName
                        
                        if let colorIndex = personColors.firstIndex(of: selectedProfileColor) {
                            updatedPerson.colorIndex = colorIndex
                        }
                        
                        // Update profile image if one was selected
                        if let img = profileImage {
                            updatedPerson.profileImageData = img.jpegData(compressionQuality: 0.8)
                        }
                        
                        // Save comment
                        updatedPerson.comment = editingPersonComment
                        
                        viewModel.currentArrangement.people[index] = updatedPerson
                        viewModel.saveCurrentArrangement()
                    }
                    // Reset profile image after saving
                    profileImage = nil
                    editingPersonComment = ""
                    showingProfileEditor = false
                }) {
                    Text("Save")
                        .fontWeight(.semibold)
                }
                .disabled(editingPersonName.isEmpty)
            )
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(image: $profileImage)
            }
        }
    }
    
    // Function to share as text - with improved format for tables
    private func shareText() {
        // Gate share/export behind Pro
        if !canUseUnlimitedFeatures() {
            showPaywall = true
            return
        }
        viewModel.saveCurrentTableState()
        let exportText = viewModel.exportAllTables()
        AdsManager.shared.showInterstitialThen {
            let activityVC = UIActivityViewController(
                activityItems: [exportText],
                applicationActivities: nil
            )
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let rootVC = windowScene.windows.first?.rootViewController {
                rootVC.present(activityVC, animated: true) {
                    // After share sheet is dismissed, return to welcome
                    DispatchQueue.main.async {
                        resetAndShowWelcomeScreen()
                    }
                }
            }
        }
    }
    // Function to share as image
    private func shareImage() {
        // Gate image export behind Pro
        if !canUseUnlimitedFeatures() {
            showPaywall = true
            return
        }
        let (formattedTitle, eventEmoji) = UIHelpers.formatEventTitle(viewModel.currentArrangement.title)
        let renderer = ImageRenderer(content:
            VStack(spacing: 12) {
                // Header with emojis and table info
                VStack(spacing: 4) {
                    Text("\(eventEmoji) \(formattedTitle)")
                        .font(.system(size: 22, weight: .bold))
                    
                    Text("Table Layout")
                            .font(.headline)
                            .foregroundColor(.secondary)
                            .padding(.bottom, 4)
                    
                    // People count with appropriate text
                    HStack(spacing: 4) {
                        Text("People:")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        let peopleCount = viewModel.currentArrangement.people.count
                        Text("\(peopleCount)")
                            .font(.subheadline)
                            .foregroundColor(.blue)
                            .fontWeight(.bold)
                        
                        Text("•")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        // Use the static helper method
                        let shapeEmoji = UIHelpers.getShapeEmoji(for: viewModel.currentArrangement.tableShape)
                        
                        Text("\(shapeEmoji) \(viewModel.currentArrangement.tableShape.rawValue.capitalized)")
                            .font(.subheadline)
                    }
                }
                .padding(.top)
                
                // Table with people
                TableView(
                    arrangement: viewModel.currentArrangement,
                    getPersonColor: { id in getPersonColor(for: id, in: viewModel.currentArrangement) },
                    onPersonTap: { _ in } // Empty handler as this is just an image
                )
                .frame(width: 320, height: 280)
                .padding(.horizontal)
                
                // Add people list below
                if !viewModel.currentArrangement.people.isEmpty {
                    Divider()
                        .padding(.horizontal)
                    
                    Text("Seating Order")
                        .font(.headline)
                        .padding(.top, -4) // Changed from 4 to -4 to move up 8 pixels
                    
                    // Order people by seat number
                    let peopleList = viewModel.currentArrangement.people
                        .sorted { a, b in
                            let seatA = viewModel.currentArrangement.seatAssignments[a.id] ?? 0
                            let seatB = viewModel.currentArrangement.seatAssignments[b.id] ?? 0
                            return seatA < seatB
                        }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(Array(peopleList.enumerated()), id: \.element.id) { index, person in
                            HStack(spacing: 10) {
                                Text("\(index + 1).")
                                    .foregroundColor(.blue)
                                    .fontWeight(.medium)
                                    .frame(width: 28, alignment: .trailing)
                                
                                Circle()
                                    .fill(getPersonColor(for: person.id, in: viewModel.currentArrangement).opacity(0.3))
                                    .frame(width: 30, height: 30)
                                    .overlay(
                                        Text(computeInitials(from: person.name))
                                            .font(.system(size: 12, weight: .semibold))
                                            .foregroundColor(getPersonColor(for: person.id, in: viewModel.currentArrangement))
                                    )
                                
                                Text(person.name.split(separator: " ").first.map(String.init) ?? person.name)
                                    .font(.system(size: 16))
                                
                                if person.isLocked {
                                    Image(systemName: "lock.fill")
                                        .foregroundColor(.blue)
                                }
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 4)
                        }
                    }
                    .padding(.bottom)
                }
            }
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .padding(16)
        )
        if let uiImage = renderer.uiImage {
            let activityVC = UIActivityViewController(
                activityItems: [uiImage],
                applicationActivities: nil
            )
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let rootVC = windowScene.windows.first?.rootViewController {
                rootVC.present(activityVC, animated: true) {
                    DispatchQueue.main.async {
                        resetAndShowWelcomeScreen()
                    }
                }
            }
        }
    }

    // MARK: - ShareLink helpers (image export)
    private func sharePreviewTitle() -> String {
        let eventTitle = viewModel.currentArrangement.eventTitle ?? ""
        let displayTitle = eventTitle.isEmpty ? viewModel.currentArrangement.title : eventTitle
        let (formatted, emoji) = UIHelpers.formatEventTitle(displayTitle)
        return "\(emoji) \(formatted)"
    }

    private func buildShareLayoutView() -> some View {
        let titleText = sharePreviewTitle()
        return VStack(spacing: 12) {
            // Header with event/title
            Text(titleText)
                .font(.system(size: 22, weight: .bold))
                .multilineTextAlignment(.center)

            // Secondary info row
            HStack(spacing: 6) {
                let peopleCount = viewModel.currentArrangement.people.count
                Text("People: \(peopleCount)")
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text("•")
                    .foregroundColor(.secondary)
                let shapeEmoji = UIHelpers.getShapeEmoji(for: viewModel.currentArrangement.tableShape)
                Text("\(shapeEmoji) \(viewModel.currentArrangement.tableShape.rawValue.capitalized)")
                    .font(.subheadline)
            }

            // Table layout visualization
            TableView(
                arrangement: viewModel.currentArrangement,
                getPersonColor: { id in getPersonColor(for: id, in: viewModel.currentArrangement) },
                onPersonTap: { _ in }
            )
            .frame(width: 360, height: 300)
            .padding(.top, 4)
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
    }
    // Build a composite view including ALL non-empty tables with names beneath previews
    private func buildAllTablesCompositeShareView() -> some View {
        let tables: [(id: Int, table: SeatingArrangement)] = viewModel.tableCollection.tables
            .filter { !$0.value.people.isEmpty }
            .sorted { $0.key < $1.key }
            .enumerated()
            .map { (offset, element) in (id: offset + 1, table: element.value) }

        let titleText = sharePreviewTitle()
        let peopleTotal = tables.reduce(0) { $0 + $1.table.people.count }

        // Use a scroll container with a fixed max height so long exports are not clipped
        return ScrollView {
            VStack(alignment: .leading, spacing: 12) {
            // Top header
            VStack(spacing: 6) {
                Text(titleText)
                    .font(.system(size: 22, weight: .bold))
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                HStack(spacing: 8) {
                    Text("People: \(peopleTotal)")
                        .font(.subheadline).fontWeight(.medium)
                    Text("•").foregroundColor(.secondary)
                    Text("Tables: \(tables.count)")
                        .font(.subheadline).fontWeight(.medium)
                }
                .frame(maxWidth: .infinity)
            }

                ForEach(Array(tables.enumerated()), id: \.offset) { _, item in
                    VStack(alignment: .leading, spacing: 8) {
                    let table = item.table
                    let tableName = table.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Table \(item.id)" : table.title
                    Text(tableName)
                        .font(.headline)

                    SharePreviewSimpleTableView(
                        arrangement: table,
                        getPersonColor: { id in
                            if let person = table.people.first(where: { $0.id == id }) {
                                if person.colorIndex < personColors.count {
                                    return personColors[person.colorIndex]
                                } else if let idx = table.people.firstIndex(where: { $0.id == id }) {
                                    return personColors[idx % personColors.count]
                                }
                            }
                            return .blue
                        }
                    )
                    .frame(height: 140)
                    .padding(.horizontal, 10)

                    if !table.people.isEmpty {
                        let orderedPeople = table.people
                            .sorted { a, b in
                                let seatA = table.seatAssignments[a.id] ?? 0
                                let seatB = table.seatAssignments[b.id] ?? 0
                                return seatA < seatB
                            }
                        VStack(alignment: .leading, spacing: 4) {
                            ForEach(Array(orderedPeople.enumerated()), id: \.element.id) { idx, person in
                                HStack(spacing: 8) {
                                    Text("\(idx + 1).")
                                        .foregroundColor(.blue)
                                        .font(.footnote.bold())
                                        .frame(width: 18, alignment: .trailing)
                                    Text(person.name.split(separator: " ").first.map(String.init) ?? person.name)
                                        .font(.footnote)
                                }
                            }
                        }
                        .padding(.top, 4)
                    }
                    }
                    .padding(12)
                    .background(Color.white)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color(.systemGray5), lineWidth: 1)
                    )
                }
            }
            .padding(16)
            .background(Color.white)
            .cornerRadius(14)
        }
    }

    // Build a single composite view that includes ALL non-empty tables for image sharing
    private func buildAllTablesShareView() -> some View {
        // Gather non-empty tables in ascending order of id
        let tables: [(id: Int, table: SeatingArrangement)] = viewModel.tableCollection.tables
            .filter { !$0.value.people.isEmpty }
            .sorted { $0.key < $1.key }
            .enumerated()
            .map { (offset, element) in (id: offset + 1, table: element.value) }

        let eventTitle = viewModel.currentArrangement.eventTitle ?? ""
        let (formattedTitle, emoji) = UIHelpers.formatEventTitle(eventTitle)
        let peopleTotal = tables.reduce(0) { $0 + $1.table.people.count }

        return VStack(alignment: .leading, spacing: 12) {
            // Top summary header
            VStack(spacing: 6) {
                if !eventTitle.isEmpty {
                    Text("\(emoji) \(formattedTitle)")
                        .font(.system(size: 22, weight: .bold))
                        .multilineTextAlignment(.center)
                }
                HStack(spacing: 8) {
                    Text("People: \(peopleTotal)")
                        .font(.subheadline).fontWeight(.medium)
                    Text("•").foregroundColor(.secondary)
                    Text("Tables: \(tables.count)")
                        .font(.subheadline).fontWeight(.medium)
                }
            }
            .frame(maxWidth: .infinity)

            // Each table section
            ForEach(Array(tables.enumerated()), id: \.offset) { _, item in
                VStack(alignment: .leading, spacing: 8) {
                    let table = item.table
                    let tableName = table.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Table \(item.id)" : table.title
                    Text(tableName)
                        .font(.headline)
                    SharePreviewSimpleTableView(
                        arrangement: table,
                        getPersonColor: { id in
                            if let person = table.people.first(where: { $0.id == id }) {
                                if person.colorIndex < personColors.count {
                                    return personColors[person.colorIndex]
                                } else if let idx = table.people.firstIndex(where: { $0.id == id }) {
                                    return personColors[idx % personColors.count]
                                }
                            }
                            return .blue
                        }
                    )
                    .frame(height: 140)
                    .padding(.horizontal, 10)
                    // Names list below preview
                    if !table.people.isEmpty {
                        let orderedPeople = table.people
                            .sorted { a, b in
                                let seatA = table.seatAssignments[a.id] ?? 0
                                let seatB = table.seatAssignments[b.id] ?? 0
                                return seatA < seatB
                            }
                        VStack(alignment: .leading, spacing: 4) {
                            ForEach(Array(orderedPeople.enumerated()), id: \.element.id) { idx, person in
                                HStack(spacing: 8) {
                                    Text("\(idx + 1).")
                                        .foregroundColor(.blue)
                                        .font(.footnote.bold())
                                        .frame(width: 18, alignment: .trailing)
                                    Text(person.name.split(separator: " ").first.map(String.init) ?? person.name)
                                        .font(.footnote)
                                }
                            }
                        }
                        .padding(.top, 4)
                    }
                }
                .padding(12)
                .background(Color.white)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(.systemGray5), lineWidth: 1)
                )
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(14)
    }

// A lightweight, file-scoped table preview usable outside of AllTablesExportView
private struct SharePreviewSimpleTableView: View {
    let arrangement: SeatingArrangement
    let getPersonColor: (UUID) -> Color

    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height
            ZStack {
                // Draw table shape
                Group {
                    switch arrangement.tableShape {
                    case .round:
                        Circle()
                            .stroke(Color.gray.opacity(0.4), lineWidth: 3)
                            .background(Circle().fill(Color.gray.opacity(0.1)))
                            .frame(width: min(width, height) * 0.95, height: min(width, height) * 0.95)
                            .position(x: width/2, y: height/2)
                    case .rectangle:
                        Rectangle()
                            .stroke(Color.gray.opacity(0.4), lineWidth: 3)
                            .background(Rectangle().fill(Color.gray.opacity(0.1)))
                            .frame(width: width * 0.62, height: height * 0.75)
                            .position(x: width/2, y: height/2)
                    case .square:
                        Rectangle()
                            .stroke(Color.gray.opacity(0.4), lineWidth: 3)
                            .background(Rectangle().fill(Color.gray.opacity(0.1)))
                            .frame(width: min(width, height) * 0.9, height: min(width, height) * 0.9)
                            .position(x: width/2, y: height/2)
                    }
                }
                // Place people around the perimeter
                ForEach(Array(arrangement.people.enumerated()), id: \.element.id) { index, person in
                    let pos = calculatePersonPosition(
                        index: index,
                        total: arrangement.people.count,
                        tableShape: arrangement.tableShape,
                        width: width,
                        height: height
                    )
                    ZStack {
                        Circle()
                            .fill(getPersonColor(person.id).opacity(0.7))
                            .frame(width: 24, height: 24)
                        Text(computeInitials(from: person.name))
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .position(x: pos.x, y: pos.y)
                }
            }
        }
        .frame(height: 100)
    }

    private func calculatePersonPosition(index: Int, total: Int, tableShape: TableShape, width: CGFloat, height: CGFloat) -> CGPoint {
        switch tableShape {
        case .round:
            let radius = min(width, height) * 0.45
            let angle = 2 * .pi * CGFloat(index) / CGFloat(max(total, 1)) - .pi / 2
            let x = width/2 + radius * cos(angle)
            let y = height/2 + radius * sin(angle)
            return CGPoint(x: x, y: y)
        case .rectangle:
            let w = width * 0.62
            let h = height * 0.75
            let perimeter = 2 * (w + h)
            let distance = perimeter * CGFloat(index) / CGFloat(max(total, 1))
            if distance < w {
                return CGPoint(x: (width-w)/2 + distance, y: (height-h)/2)
            } else if distance < w + h {
                return CGPoint(x: (width+w)/2, y: (height-h)/2 + (distance-w))
            } else if distance < 2*w + h {
                return CGPoint(x: (width+w)/2 - (distance-w-h), y: (height+h)/2)
            } else {
                return CGPoint(x: (width-w)/2, y: (height+h)/2 - (distance-2*w-h))
            }
        case .square:
            let side = min(width, height) * 0.9
            let perimeter = 4 * side
            let distance = perimeter * CGFloat(index) / CGFloat(max(total, 1))
            if distance < side {
                return CGPoint(x: (width-side)/2 + distance, y: (height-side)/2)
            } else if distance < 2*side {
                return CGPoint(x: (width+side)/2, y: (height-side)/2 + (distance-side))
            } else if distance < 3*side {
                return CGPoint(x: (width+side)/2 - (distance-2*side), y: (height+side)/2)
            } else {
                return CGPoint(x: (width-side)/2, y: (height+side)/2 - (distance-3*side))
            }
        }
    }
}
    private func renderImage<Content: View>(from view: Content, scale: CGFloat = UIScreen.main.scale) -> UIImage {
        let renderer = ImageRenderer(content: view)
        renderer.scale = scale
        renderer.isOpaque = true
        if let image = renderer.uiImage { return image }
        // Fallback tiny white image
        let format = UIGraphicsImageRendererFormat()
        format.scale = scale
        let renderer2 = UIGraphicsImageRenderer(size: CGSize(width: 2, height: 2), format: format)
        return renderer2.image { ctx in
            UIColor.white.setFill()
            ctx.fill(CGRect(x: 0, y: 0, width: 2, height: 2))
        }
    }

    private func previewTableImage() -> UIImage {
        renderImage(from: buildShareLayoutView(), scale: 2)
    }

    // Build a composite view of all non-empty tables for image sharing (scoped to AllTablesExportView)
    // Removed duplicate placeholder

    private func previewAllTablesImage() -> UIImage {
        let composed = buildAllTablesCompositeShareView()
            .frame(maxWidth: UIScreen.main.bounds.width * 0.94)
        return renderImage(from: composed, scale: 2)
    }

    private func generateShareableTableImage() -> TableLayoutImage {
        let image = renderImage(from: buildShareLayoutView(), scale: UIScreen.main.scale)
        return TableLayoutImage(image: image)
    }

    // Combined export function
    private func exportCombinedArrangement() {
        // First, check if we need to prompt for table name
        if viewModel.currentTableName.isEmpty {
            // Show the save dialog to name the table before exporting
            showingSaveDialog = true
            return
        }
        
        // First save the current state to ensure it's included
        viewModel.saveCurrentTableState()
        
        // If there are multiple tables, use the multi-table export
        if viewModel.tableCollection.tables.count > 1 {
            let exportText = viewModel.exportAllTables()
            shareExportText(exportText)
        } else {
            // Use the single table export for just one table
            var exportText = viewModel.currentArrangement.exportDescription
            
            // Fix pluralization if needed in the export text
            let peopleCount = viewModel.currentArrangement.people.count
            if peopleCount == 1 {
                exportText = exportText.replacingOccurrences(of: "1 people", with: "1 person")
            }
            
            shareExportText(exportText)
        }
        
        // Show alert asking if user wants to clear tables and return to welcome screen
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
        showExportCompleteAlert = true
        }
    }

    // Helper to share the export text
    private func shareExportText(_ text: String) {
        AdsManager.shared.showInterstitialThen {
            let activityVC = UIActivityViewController(
                activityItems: [text],
                applicationActivities: nil
            )
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let rootVC = windowScene.windows.first?.rootViewController {
                rootVC.present(activityVC, animated: true) {
                    DispatchQueue.main.async {
                        resetAndShowWelcomeScreen()
                    }
                }
            }
        }
    }
    
    @State private var showExportCompleteAlert = false
    
    // Helper function to determine event type and emoji from title
    private func getFormattedEventTitle(_ title: String) -> (String, String) {
        if title.isEmpty {
            return ("", "🪑")
        }
        
        // Normalize title for case-insensitive matching
        let normalizedTitle = title.lowercased()
        
        // Party-related terms
        let partyTerms = ["party", "bash", "celebration", "get-together", "hangout", "kickback",
                         "shindig", "gathering", "soirée", "mixer", "fest", "fiesta", "jam",
                         "event", "function", "meetup", "rager"]
        
        // Food-related terms
        let foodTerms = ["dinner", "lunch", "breakfast", "brunch", "feast", "banquet", "meal",
                        "supper", "potluck", "bbq", "barbecue", "picnic", "buffet", "luncheon"]
        
        // Special event terms
        let weddingTerms = ["wedding", "reception", "ceremony", "nuptial"]
        let birthdayTerms = ["birthday", "bday"]
        let holidayTerms = ["christmas", "thanksgiving", "holiday", "easter", "halloween",
                          "new year", "valentine", "st. patrick"]
        let businessTerms = ["meeting", "conference", "seminar", "workshop", "presentation",
                           "office", "corporate", "business", "board"]
        
        // Format title with proper capitalization
        let formattedTitle = title
            .split(separator: " ")
            .map { $0.prefix(1).uppercased() + $0.dropFirst().lowercased() }
            .joined(separator: " ")
        
        // Check matches and return appropriate emoji
        for term in partyTerms where normalizedTitle.contains(term) {
            return (formattedTitle, "🎉")
        }
        
        for term in foodTerms where normalizedTitle.contains(term) {
            return (formattedTitle, "🍽️")
        }
        
        for term in weddingTerms where normalizedTitle.contains(term) {
            return (formattedTitle, "💍")
        }
        
        for term in birthdayTerms where normalizedTitle.contains(term) {
            return (formattedTitle, "🎂")
        }
        
        for term in holidayTerms where normalizedTitle.contains(term) {
            return (formattedTitle, "🎄")
        }
        
        for term in businessTerms where normalizedTitle.contains(term) {
            return (formattedTitle, "📊")
        }
        
        // Default case - no specific category found
        return (formattedTitle, "🪑")
    }

    private func triggerHaptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        if hapticsEnabled {
            let generator = UIImpactFeedbackGenerator(style: style)
            generator.impactOccurred()
        }
    }

    // Add this helper function to calculate the Y position based on table shape
    private func getTableNameYPosition() -> CGFloat {
        switch viewModel.currentArrangement.tableShape {
        case .round:
            return (211/2) // Original position + 6 pixels
        case .rectangle:
            return (211/2) // Original position + 6 pixels
        case .square:
            return (211/2)
            // Original position + 6 pixels
        }
    }

    @State private var isEditingTableNameInline = false
    @State private var inlineTableName = ""

    private func saveInlineTableName() {
        let trimmed = inlineTableName.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            viewModel.currentTableName = trimmed
            viewModel.currentArrangement.title = trimmed
            viewModel.saveCurrentTableState()
        }
        isEditingTableNameInline = false
        isTableNameFieldFocused = false
    }

    // 1. Add a new function to reset to an empty table (not tutorial)
    private func resetToEmptyTable() {
        viewModel.currentArrangement = SeatingArrangement(
            title: "",
            people: [],
            tableShape: viewModel.defaultTableShape
        )
        viewModel.currentTableName = ""
        viewModel.saveCurrentTableState()
        showEffortlessScreen = true // Show the empty state screen
    }

    private func handleHistoryBack() {
        // Dismiss history sheet first
        showingHistory = false
        // Restore depending on origin
        if let snapshot = historyOriginSnapshot {
            // If history opened from another table context, restore it
            viewModel.tableCollection = snapshot
            if let current = snapshot.tables[snapshot.currentTableId] {
                viewModel.currentArrangement = current
                viewModel.currentTableName = current.title
            }
            viewModel.isViewingHistory = false
            // Preserve whether we were on the empty state (Create seating for events)
            showEffortlessScreen = historyOriginWasEmptyState
        } else {
            // No snapshot means opened from Create Seating for Events
            // Keep user on the Create Seating screen
            showEffortlessScreen = true
            viewModel.isViewingHistory = false
        }
        // Clear snapshot after use
        historyOriginSnapshot = nil
        historyOriginWasEmptyState = false
    }
    private func handleHistoryDismiss() {
        showingHistory = false
        // Ensure table name is always 'Table X' if empty or 'New Arrangement'
        if viewModel.currentTableName.isEmpty || viewModel.currentTableName == "New Arrangement" {
            viewModel.currentTableName = String(format: NSLocalizedString("Table %d", comment: "Default table name"), viewModel.tableCollection.currentTableId + 1)
        }
        // If not viewing a history item, ensure we reset to welcome screen
        if !viewModel.isViewingHistory {
            // Respect origin: if coming from create seating, keep effortless screen
            showEffortlessScreen = true
        } else {
            // When a history item was opened, go directly to the main table view
            showEffortlessScreen = false
        }
        // Clear snapshot when dismissing
        historyOriginSnapshot = nil
        historyOriginWasEmptyState = false
    }

    // Extracted Add/Delete bar to isolate any layout/capture issues
    private struct AddDeleteButtonsBar: View {
        @ObservedObject var viewModel: SeatingViewModel
        @Binding var showingAddPerson: Bool
        @Binding var showingDeleteAllPeopleAlert: Bool
        var onAdd: () -> Void
        var onClearAll: () -> Void
        var body: some View {
            HStack(spacing: 12) {
                Button(action: onAdd) {
                    HStack(spacing: 8) {
                        Image(systemName: "person.badge.plus")
                            .font(.system(size: 15, weight: .semibold))
                            .accessibilityHidden(true)
                        Text(viewModel.currentArrangement.people.isEmpty ? NSLocalizedString("Get Started", comment: "Button to get started") : NSLocalizedString("Add", comment: "Button to add a person"))
                            .font(.system(size: 15, weight: .semibold))
                            .dynamicTypeSize(.xSmall ... .accessibility5)
                            .minimumScaleFactor(0.7)
                            .lineLimit(1)
                            .accessibilityLabel(viewModel.currentArrangement.people.isEmpty ? NSLocalizedString("Get Started", comment: "Button to get started") : NSLocalizedString("Add Person", comment: "Button to add a person"))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 9)
                    .background(
                        Capsule()
                            .fill(Color.green)
                            .shadow(color: Color.green.opacity(0.22), radius: 6, x: 0, y: 2)
                    )
                }
                .buttonStyle(PlainButtonStyle())
                .contentShape(Rectangle())
                .zIndex(2)
                .accessibilityAddTraits(.isButton)
                .accessibilityIdentifier("btn.add")
                .onboardingAnchor(.add)

                Button(action: { showingDeleteAllPeopleAlert = true }) {
                    Image(systemName: "trash")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 36, height: 36)
                        .background(
                            Circle()
                                .fill(Color.red)
                                .shadow(color: Color.red.opacity(0.22), radius: 6, x: 0, y: 2)
                        )
                }
                .disabled(viewModel.currentArrangement.people.isEmpty)
                .opacity(viewModel.currentArrangement.people.isEmpty ? 0.5 : 1.0)
                .zIndex(2)
                .alert("Clear Table?", isPresented: $showingDeleteAllPeopleAlert) {
                    Button("Clear", role: .destructive) { onClearAll() }
                    Button("Cancel", role: .cancel) {}
                } message: {
                    Text("Are you sure you want to remove all people from this table?")
                }
            }
        }
    }

    // --- Moved computed properties inside ContentView ---
    private var tutorialView: some View {
        Group {
            if showingTutorial || !UserDefaults.standard.bool(forKey: "hasSeenTutorial") {
                TutorialView(onComplete: {
                    UserDefaults.standard.set(true, forKey: "hasSeenTutorial")
                    showingTutorial = false
                    showEffortlessScreen = true // Show creating seating for events screen
                    // Ask notifications permission right after onboarding completes
                    requestNotificationsOnboardingIfAppropriate()
                })
                .edgesIgnoringSafeArea(.all)
            }
        }
    }

    // MARK: - Notifications Onboarding
    private func requestNotificationsOnboardingIfAppropriate() {
        // Only auto-ask once during onboarding
        if hasAskedNotificationsOnboarding { return }
        let center = UNUserNotificationCenter.current()
        center.getNotificationSettings { settings in
            switch settings.authorizationStatus {
            case .notDetermined:
                center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
                    DispatchQueue.main.async {
                        self.hasAskedNotificationsOnboarding = true
                        if granted {
                            self.notificationsEnabled = true
                            NotificationService.shared.enableDailyReminder()
                        }
                    }
                }
            case .authorized, .provisional, .ephemeral:
                DispatchQueue.main.async {
                    self.hasAskedNotificationsOnboarding = true
                    // Auto-enable alerts since permission is already granted
                    self.notificationsEnabled = true
                    NotificationService.shared.enableDailyReminder()
                }
            case .denied:
                DispatchQueue.main.async {
                    self.hasAskedNotificationsOnboarding = true
                }
            @unknown default:
                DispatchQueue.main.async {
                    self.hasAskedNotificationsOnboarding = true
                }
            }
        }
    }
    private var emptyStateConditionalView: some View {
        Group {
            if (self.showEffortlessScreen || (viewModel.currentArrangement.people.isEmpty && viewModel.tableCollection.tables.isEmpty && viewModel.tableCollection.currentTableId == 0 && !viewModel.isViewingHistory))
                && !(showingTutorial || !UserDefaults.standard.bool(forKey: "hasSeenTutorial")) {
                emptyStateView
                    .preferredColorScheme(.light)
            }
        }
    }
    private var mainContentConditionalView: some View {
        Group {
            if !(showingTutorial || !UserDefaults.standard.bool(forKey: "hasSeenTutorial") || self.showEffortlessScreen || (viewModel.currentArrangement.people.isEmpty && viewModel.tableCollection.tables.isEmpty && viewModel.tableCollection.currentTableId == 0 && !viewModel.isViewingHistory)) {
                mainContentContent
                    .padding(.bottom, 20)
                    .preferredColorScheme(overrideColorScheme)
                    .offset(y: -2)
            }
        }
    }
    private var headerConditionalView: some View {
        Group {
            if !(self.showEffortlessScreen || (viewModel.currentArrangement.people.isEmpty && viewModel.tableCollection.tables.isEmpty && viewModel.tableCollection.currentTableId == 0 && !viewModel.isViewingHistory)) {
                headerView
            }
        }
    }
    private var loadingConditionalView: some View {
        Group {
            if isLoading {
                loadingView
            }
        }
    }
    private var savingDialogConditionalView: some View {
        Group {
            if showingSaveDialog {
                Color.black.opacity(0.4)
                    .edgesIgnoringSafeArea(.all)
                    .onTapGesture { showingSaveDialog = false }
                saveDialogContent
                    .transition(.scale.combined(with: .opacity))
            }
        }
    }
    // Deprecated: peopleRows replaced by LazyVStack + draggable/dropDestination based reordering
    // Keeping the name stubbed to avoid accidental references. Not used anymore.
    private var peopleRows: [AnyView] { [] }
}
// Create a new comprehensive export view to display all tables
struct AllTablesExportView: View {
    @ObservedObject var viewModel: SeatingViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var arrangementTitle: String
    @State private var isEditingTitle = false
    @State private var isShowingShareSheet = false
    @State private var shareText: String = ""
    @Binding var parentExportItems: [Any]
    @Binding var parentIsShowingShareSheet: Bool
    
    // Add bindings for navigation state
    @Binding var showEffortlessScreen: Bool
    @Binding var showingTutorial: Bool
    
    // Define unique colors for up to 12 people (same as ContentView)
    private let personColors: [Color] = [
        .blue, .green, .orange, .purple, .pink,
        .red, .teal, .indigo, .mint, .yellow,
        .cyan, .brown
    ]
    
    init(viewModel: SeatingViewModel, showEffortlessScreen: Binding<Bool>, showingTutorial: Binding<Bool>, parentExportItems: Binding<[Any]>, parentIsShowingShareSheet: Binding<Bool>) {
        self.viewModel = viewModel
        self._showEffortlessScreen = showEffortlessScreen
        self._showingTutorial = showingTutorial
        self._parentExportItems = parentExportItems
        self._parentIsShowingShareSheet = parentIsShowingShareSheet
        // Initialize with current arrangement title
        _arrangementTitle = State(initialValue: viewModel.currentArrangement.title)
    }
    
    // Helper function to get color for a person
    private func personColor(for id: UUID, in arrangement: SeatingArrangement) -> Color {
        if let person = arrangement.people.first(where: { $0.id == id }) {
            if person.colorIndex < personColors.count {
                return personColors[person.colorIndex]
            } else if let index = arrangement.people.firstIndex(where: { $0.id == id }) {
                return personColors[index % personColors.count]
            }
        }
        return .blue // Default color
    }
    
    // Simple table preview for export view
    private struct SimpleTableView: View {
        let arrangement: SeatingArrangement
        let getPersonColor: (UUID) -> Color
        
        var body: some View {
            GeometryReader { geometry in
                let width = geometry.size.width
                let height = geometry.size.height
                let dotSize = max(22, min(30, min(width, height) * 0.18))
                ZStack {
                    // Draw table shape
                    Group {
                        switch arrangement.tableShape {
                        case .round:
                            Circle()
                                .stroke(Color.gray.opacity(0.4), lineWidth: 3)
                                .background(Circle().fill(Color.gray.opacity(0.1)))
                                .frame(width: min(width, height) * 0.95, height: min(width, height) * 0.95)
                                .position(x: width/2, y: height/2)
                        case .rectangle:
                            Rectangle()
                                .stroke(Color.gray.opacity(0.4), lineWidth: 3)
                                .background(Rectangle().fill(Color.gray.opacity(0.1)))
                                .frame(width: width * 0.72, height: height * 0.75) // Slightly wider for readability
                                .position(x: width/2, y: height/2)
                        case .square:
                            Rectangle()
                                .stroke(Color.gray.opacity(0.4), lineWidth: 3)
                                .background(Rectangle().fill(Color.gray.opacity(0.1)))
                                .frame(width: min(width, height) * 0.92, height: min(width, height) * 0.92)
                                .position(x: width/2, y: height/2)
                        }
                    }
                    // Place people around the perimeter
                    ForEach(Array(arrangement.people.enumerated()), id: \.element.id) { index, person in
                        let pos = calculatePersonPosition(
                            index: index,
                            total: arrangement.people.count,
                            tableShape: arrangement.tableShape,
                            width: width,
                            height: height
                        )
                        ZStack {
                            Circle()
                                .fill(getPersonColor(person.id).opacity(0.7))
                                .frame(width: dotSize, height: dotSize)
                            Text(computeInitials(from: person.name))
                                .font(.system(size: max(10, dotSize * 0.42), weight: .bold))
                                .foregroundColor(.white)
                        }
                        .position(x: pos.x, y: pos.y)
                    }
                }
            }
            .frame(height: 150)
        }
        
        // Helper to calculate perimeter positions
        private func calculatePersonPosition(index: Int, total: Int, tableShape: TableShape, width: CGFloat, height: CGFloat) -> CGPoint {
            switch tableShape {
            case .round:
                let radius = min(width, height) * 0.45
                let angle = 2 * .pi * CGFloat(index) / CGFloat(max(total, 1)) - .pi / 2
                let x = width/2 + radius * cos(angle)
                let y = height/2 + radius * sin(angle)
                return CGPoint(x: x, y: y)
            case .rectangle:
                let w = width * 0.72 // Match the preview width above
                let h = height * 0.75
                let perimeter = 2 * (w + h)
                let distance = perimeter * CGFloat(index) / CGFloat(max(total, 1))
                if distance < w {
                    return CGPoint(x: (width-w)/2 + distance, y: (height-h)/2)
                } else if distance < w + h {
                    return CGPoint(x: (width+w)/2, y: (height-h)/2 + (distance-w))
                } else if distance < 2*w + h {
                    return CGPoint(x: (width+w)/2 - (distance-w-h), y: (height+h)/2)
                } else {
                    return CGPoint(x: (width-w)/2, y: (height+h)/2 - (distance-2*w-h))
                }
            case .square:
                let side = min(width, height) * 0.92
                let perimeter = 4 * side
                let distance = perimeter * CGFloat(index) / CGFloat(max(total, 1))
                if distance < side {
                    return CGPoint(x: (width-side)/2 + distance, y: (height-side)/2)
                } else if distance < 2*side {
                    return CGPoint(x: (width+side)/2, y: (height-side)/2 + (distance-side))
                } else if distance < 3*side {
                    return CGPoint(x: (width+side)/2 - (distance-2*side), y: (height+side)/2)
                } else {
                    return CGPoint(x: (width-side)/2, y: (height+side)/2 - (distance-3*side))
                }
            }
        }
    }
    
    // Simple person dot for table preview
    private struct PersonDot: View {
        let person: Person
        let color: Color
        let position: CGPoint // Position relative to table's top-left
        
        var body: some View {
            Circle()
                .fill(color.opacity(0.7))
                .frame(width: 14, height: 14)
                // Position the dot relative to the center of the table preview (approx. 60, 50 based on table sizes)
                .position(x: position.x + 60, y: position.y + 50 - 4) // Simplified positioning
                .offset(x: 55, y: -40) // Add offset for share screen
        }
    }
    
    // Simple person bubble for list
    private struct PersonBubble: View {
        let person: Person
        let color: Color
        
        var body: some View {
            ZStack {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 30, height: 30)
                
                Text(computeInitials(from: person.name))
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(color)
            }
            .overlay(
                Circle()
                    .stroke(color.opacity(0.5), lineWidth: 1)
            )
        }
    }
    
    // Get only tables with people in them, renumbered sequentially
    private var nonEmptyTables: [(id: Int, table: SeatingArrangement)] {
        let filteredTables = viewModel.tableCollection.tables
            .filter { !$0.value.people.isEmpty }
            .sorted { $0.key < $1.key }
        
        // Renumber tables sequentially
        return filteredTables.enumerated().map { index, table in
            return (id: index + 1, table: table.value)
        }
    }
    
    // Local helper for event title formatting to keep expressions small for the type-checker
    private func composedEventTitle() -> String {
        let eventTitle = viewModel.currentArrangement.eventTitle
        let hasEventTitle = eventTitle?.isEmpty == false
        let fallbackTitle = arrangementTitle.isEmpty ? viewModel.currentArrangement.title : arrangementTitle
        let displayTitle = hasEventTitle ? (eventTitle ?? "") : fallbackTitle
        let finalTitle = displayTitle.isEmpty ? "New Arrangement" : displayTitle
        let (formattedTitle, emoji) = UIHelpers.formatEventTitle(finalTitle)
        return "\(emoji) \(formattedTitle)"
    }

    // MARK: - ShareLink helpers (image export, local to AllTablesExportView)
    private func sharePreviewTitle() -> String {
        composedEventTitle()
    }

    private func buildShareLayoutView() -> some View {
        let titleText = sharePreviewTitle()
        return VStack(spacing: 12) {
            // Header
            Text(titleText)
                .font(.system(size: 22, weight: .bold))
                .multilineTextAlignment(.center)

            // Info row
            HStack(spacing: 6) {
                let peopleCount = viewModel.currentArrangement.people.count
                Text("People: \(peopleCount)")
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text("•").foregroundColor(.secondary)
                let shapeEmoji = UIHelpers.getShapeEmoji(for: viewModel.currentArrangement.tableShape)
                Text("\(shapeEmoji) \(viewModel.currentArrangement.tableShape.rawValue.capitalized)")
                    .font(.subheadline)
            }

            // Table preview for the current arrangement
            SimpleTableView(
                arrangement: viewModel.currentArrangement,
                getPersonColor: { id in personColor(for: id, in: viewModel.currentArrangement) }
            )
            .frame(height: 150)
            .padding(.horizontal, 12)
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(.systemGray5), lineWidth: 1)
        )
    }

    private func renderImage<Content: View>(from view: Content, scale: CGFloat = UIScreen.main.scale) -> UIImage {
        let renderer = ImageRenderer(content: view)
        renderer.scale = scale
        renderer.isOpaque = true
        if let image = renderer.uiImage { return image }
        let format = UIGraphicsImageRendererFormat()
        format.scale = scale
        let fallback = UIGraphicsImageRenderer(size: CGSize(width: 2, height: 2), format: format)
        return fallback.image { ctx in
            UIColor.white.setFill()
            ctx.fill(CGRect(x: 0, y: 0, width: 2, height: 2))
        }
    }
    // Build a composite image of ALL non-empty tables with names (local to AllTablesExportView)
    private func buildAllTablesCompositeShareView() -> some View {
        let tables: [(id: Int, table: SeatingArrangement)] = viewModel.tableCollection.tables
            .filter { !$0.value.people.isEmpty }
            .sorted { $0.key < $1.key }
            .enumerated()
            .map { (offset, element) in (id: offset + 1, table: element.value) }

        let titleText = sharePreviewTitle()
        let peopleTotal = tables.reduce(0) { $0 + $1.table.people.count }

        return VStack(alignment: .leading, spacing: 12) {
            VStack(spacing: 6) {
                Text(titleText)
                    .font(.system(size: 22, weight: .bold))
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                HStack(spacing: 8) {
                    Text("People: \(peopleTotal)")
                        .font(.subheadline).fontWeight(.medium)
                    Text("•").foregroundColor(.secondary)
                    Text("Tables: \(tables.count)")
                        .font(.subheadline).fontWeight(.medium)
                }
                .frame(maxWidth: .infinity)
            }

            ForEach(Array(tables.enumerated()), id: \.offset) { _, item in
                VStack(alignment: .leading, spacing: 8) {
                    let table = item.table
                    let tableName = table.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Table \(item.id)" : table.title
                    Text(tableName)
                        .font(.headline)
                    SimpleTableView(
                        arrangement: table,
                        getPersonColor: { id in personColor(for: id, in: table) }
                    )
                    .frame(height: 140)
                    .padding(.horizontal, 10)
                    if !table.people.isEmpty {
                        let orderedPeople = table.people
                            .sorted { a, b in
                                let seatA = table.seatAssignments[a.id] ?? 0
                                let seatB = table.seatAssignments[b.id] ?? 0
                                return seatA < seatB
                            }
                        VStack(alignment: .leading, spacing: 4) {
                            ForEach(Array(orderedPeople.enumerated()), id: \.element.id) { idx, person in
                                HStack(spacing: 8) {
                                    Text("\(idx + 1).")
                                        .foregroundColor(.blue)
                                        .font(.footnote.bold())
                                        .frame(width: 18, alignment: .trailing)
                                    Text(person.name.split(separator: " ").first.map(String.init) ?? person.name)
                                        .font(.footnote)
                                }
                            }
                        }
                        .padding(.top, 4)
                    }
                }
                .padding(12)
                .background(Color.white)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(.systemGray5), lineWidth: 1)
                )
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(14)
    }

    private func previewAllTablesImage() -> UIImage {
        let composed = buildAllTablesCompositeShareView()
            .frame(maxWidth: UIScreen.main.bounds.width * 0.94)
        return renderImage(from: composed, scale: 2)
    }

    private func previewTableImage() -> UIImage {
        renderImage(from: buildShareLayoutView(), scale: 2)
    }

    // Generate a PNG file URL for the current table layout (works well with Instagram)
    private func generateShareableImageURL() -> URL? {
        let image = self.renderImage(from: self.buildShareLayoutView(), scale: UIScreen.main.scale)
        guard let data = image.pngData() else { return nil }
        let tmp = FileManager.default.temporaryDirectory
        let fileURL = tmp.appendingPathComponent("SeatMaker-Table-Layout.png")
        try? FileManager.default.removeItem(at: fileURL)
        do {
            try data.write(to: fileURL, options: .atomic)
            return fileURL
        } catch {
            return nil
        }
    }

    private func presentActivity(items: [Any]) {
        let activityVC = UIActivityViewController(activityItems: items, applicationActivities: nil)
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            rootVC.present(activityVC, animated: true)
        }
    }

    // Extracted share options UI to avoid large expressions in body
    private var shareOptionsView: some View {
        VStack(spacing: 6) {
            Text("Share Options")
                .font(.headline)
                .padding(.bottom, 2)
            // Use a single fixed width for all share buttons to ensure consistent sizing
            // Increase width by 5 to satisfy spacing request
            let fixedButtonWidth = min(UIScreen.main.bounds.width * 0.88, 500) + 5

            // Share as Text (free)
            Button(action: {
                // Cancel any previously queued share actions awaiting ad dismissal
                AdsManager.shared.cancelPendingCompletion()
                // Save a snapshot to history before sharing
                viewModel.saveCurrentArrangement()
                let text = viewModel.exportAllTables()
                shareText = text
                // Prepare items for the single root ActivityView sheet
                parentExportItems = [text]
                AdsManager.shared.showInterstitialThen {
                    // Dismiss this export sheet first to avoid multiple-sheet conflicts
                    dismiss()
                    // Reset to a fresh arrangement underneath the share sheet
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        viewModel.resetAndShowWelcomeScreen()
                        showEffortlessScreen = true
                    }
                    // Present the share sheet after the dismissal animation finishes
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                        parentIsShowingShareSheet = true
                    }
                }
            }) {
                Label("  Share as Text  ", systemImage: "square.and.arrow.up")
                    .foregroundColor(.white)
                    .padding(.vertical, 14)
                    .padding(.horizontal, 24)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemBlue))
                    )
                    .frame(width: fixedButtonWidth)
                    .frame(height: 56)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
            .buttonStyle(PlainButtonStyle())
            .padding(.bottom, 4)

            // Share as Image (always loads the picture, no paywall) – include ALL tables in one image
            Button(action: {
                // Share as UIImage to avoid file-provider/share-mode issues for temporary URLs
                // Cancel any previously queued share actions awaiting ad dismissal
                AdsManager.shared.cancelPendingCompletion()
                // Save a snapshot to history before sharing
                viewModel.saveCurrentArrangement()
                // Include ALL non-empty tables in one composite image (with table names)
                let image = previewAllTablesImage()
                // Add a short promo link to the app at the end (official App Store link)
                let promo = "\n\nMade with Seat Maker — get the app: https://apps.apple.com/us/app/seat-maker/id6748284141"
                parentExportItems = [image, promo]
                AdsManager.shared.showInterstitialThen {
                    // Dismiss this export sheet first to avoid multiple-sheet conflicts
                    dismiss()
                    // Reset to a fresh arrangement underneath the share sheet
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        viewModel.resetAndShowWelcomeScreen()
                        showEffortlessScreen = true
                    }
                    // Present the share sheet after the dismissal animation finishes
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                        parentIsShowingShareSheet = true
                    }
                }
            }) {
                Label("Share as Image", systemImage: "photo")
                    .foregroundColor(.white)
                    .padding(.vertical, 14)
                    .padding(.horizontal, 24)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            // Use a distinct but fitting color for image sharing
                            .fill(Color.purple)
                    )
                    .frame(width: fixedButtonWidth)
                    .frame(height: 56)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
            .buttonStyle(PlainButtonStyle())
            .padding(.bottom, 4)

            // QR Code
            Button(action: {
                // Cancel any previously queued share actions awaiting ad dismissal
                AdsManager.shared.cancelPendingCompletion()
                generateAndShowQRCode()
            }) {
                // White background with blue border, include QR icon
                Label(" Generate QR ", systemImage: "qrcode")
                    .foregroundColor(.blue)
                    .padding(.vertical, 14)
                    .padding(.horizontal, 24)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.accentColor, lineWidth: 2)
                    )
                    .frame(width: fixedButtonWidth)
                    .frame(height: 56)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
            .buttonStyle(PlainButtonStyle())
        }
    }

    // Theme swatch view that binds to appTheme safely inside SettingsViewImpl
    private struct ThemeSwatch: View {
        @Binding var appTheme: String
        let id: String
        let label: String
        let colors: [Color]
        var body: some View {
            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) { appTheme = id }
            }) {
                VStack(spacing: 6) {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 34, height: 26)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(appTheme == id ? Color.primary.opacity(0.6) : Color.clear, lineWidth: 2)
                        )
                    Text(label)
                        .font(.system(size: 11, weight: .regular))
                        .foregroundColor(.secondary)
                }
            }
            .buttonStyle(PlainButtonStyle())
            .accessibilityLabel("Select \(label) theme")
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Format the title as editable
                VStack(spacing: 8) {
                    if isEditingTitle {
                        TextField("Event Name", text: $arrangementTitle, onCommit: {
                            // Update the title when editing is done
                            viewModel.currentArrangement.eventTitle = arrangementTitle
                            isEditingTitle = false
                        })
                        .font(.title2.bold())
                        .multilineTextAlignment(.center)
                        .padding(.vertical, 6)
                        .padding(.horizontal)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.secondary.opacity(0.1))
                        )
                        .padding(.horizontal, 40)
            
                    } else {
                        // The event title with edit button
                        HStack {
                            Spacer()
                            // Use eventTitle if available, otherwise fall back to table name
                    let titleValue = composedEventTitle()
                    Text(titleValue)
                                .font(.title2.bold())
                                .multilineTextAlignment(.center)
                                .onTapGesture {
                                    isEditingTitle = true
                                }
                            Button(action: {
                                isEditingTitle = true
                            }) {
                                Image(systemName: "pencil.circle")
                                    .foregroundColor(.blue)
                                    .font(.system(size: 22))
                            }
                            .padding(.leading, 4)
                            Spacer()
                        }
                        .padding(.top)
                        Text("Tables Overview")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                }
                
                Divider()
                
                // Summary of all tables - only count non-empty tables
                let totalTables = nonEmptyTables.count
                let totalPeople = viewModel.tableCollection.tables.values.reduce(0) { $0 + $1.people.count }
                
                VStack(spacing: 6) {
                    // Total statistics
                    HStack {
                        Text("Total Tables:")
                            .fontWeight(.medium)
                        
                        Text("\(totalTables)")
                            .foregroundColor(.blue)
                            .fontWeight(.bold)
                        
                        Spacer()
                        
                        Text("Total People:")
                            .fontWeight(.medium)
                        
                        Text("\(totalPeople)")
                            .foregroundColor(.blue)
                            .fontWeight(.bold)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.blue.opacity(0.1))
                    )
                }
                .padding(.horizontal)
                
                // Share options - moved higher on the screen above tables
                shareOptionsView
                    .padding(.bottom, 18) // Was 20, now 18 (move up 2px)
                
                // Show only tables with people, in an adaptive grid for wider/phone screens
                let availableWidth = UIScreen.main.bounds.width
                let minCard = min(360, availableWidth * 0.9)
                let columns = [GridItem(.adaptive(minimum: minCard), spacing: 14, alignment: .top)]
                LazyVGrid(columns: columns, alignment: .center, spacing: 16) {
                        ForEach(nonEmptyTables, id: \.id) { tableId, arrangement in
                            VStack(spacing: 16) {
                                // Combined table header, visualization, and people in one box
                                VStack(spacing: 12) {
                                    // Table header with editable name
                                    HStack {
                                        if editingTableId == tableId {
                                            // Show text field when editing
                                            TextField("Table Name", text: $editingTableName)
                                                .font(.system(size: 20, weight: .bold))
                                                .textFieldStyle(PlainTextFieldStyle())
                                                .onSubmit {
                                                    saveEditedTableName(tableId: tableId)
                                                }
                                                .onTapGesture {
                                                    // Prevent tap from dismissing
                                                }
                                            Button("Save") {
                                                saveEditedTableName(tableId: tableId)
                                            }
                                            .foregroundColor(.blue)
                                            .font(.system(size: 14, weight: .medium))
                                        } else {
                                            let displayName = (arrangement.title.isEmpty ? (viewModel.currentTableName.isEmpty ? "Table \(tableId)" : viewModel.currentTableName) : arrangement.title)
                                            Text(displayName)
                                                .font(.system(size: 20, weight: .bold))
                                                .foregroundColor(.primary)
                                                .lineLimit(1)
                                                .truncationMode(.tail)
                                                .padding(.bottom, 2)
                                            Button(action: {
                                                startEditingTableName(tableId: tableId, currentName: arrangement.title.isEmpty ? "Table \(tableId)" : arrangement.title)
                                            }) {
                                                Image(systemName: "pencil")
                                                    .foregroundColor(.blue)
                                                    .font(.system(size: 16, weight: .medium))
                                            }
                                        }
                                        Spacer()
                                        // Get shape emoji using our helper function
                                        let shape = UIHelpers.getShapeEmoji(for: arrangement.tableShape)
                                        Text("\(shape)")
                                            .font(.subheadline)
                                    }
                                    .padding(.horizontal, 16)
                                    
                                    // Table visualization
                                    SimpleTableView(
                                        arrangement: arrangement,
                                        getPersonColor: { id in personColor(for: id, in: arrangement) }
                                    )
                                    .frame(height: 160)
                                    .padding(.horizontal, 16)
                                    
                                    // People at this table
                                    if !arrangement.people.isEmpty {
                                        VStack(alignment: .leading, spacing: 8) {
                                            Text("People at this table:")
                                                .font(.subheadline)
                                                .foregroundColor(.secondary)
                                                .padding(.horizontal, 16)
                                            
                                            // Show first 4 people, then "and X more" if needed
                                            let sortedPeople = arrangement.people.sorted { a, b in
                                                let seatA = arrangement.seatAssignments[a.id] ?? 0
                                                let seatB = arrangement.seatAssignments[b.id] ?? 0
                                                return seatA < seatB
                                            }
                                            
                                            let displayPeople = sortedPeople.prefix(4)
                                            let remainingCount = sortedPeople.count - displayPeople.count
                                            
                                            HStack {
                                                ForEach(Array(displayPeople), id: \.id) { person in
                                                    PersonBubble(
                                                        person: person,
                                                        color: personColor(for: person.id, in: arrangement)
                                                    )
                                                }
                                                
                                                if remainingCount > 0 {
                                                    Text("+\(remainingCount) more")
                                                        .font(.system(size: 12))
                                                        .padding(6)
                                                        .background(
                                                            Capsule()
                                                                .fill(Color.secondary.opacity(0.2))
                                                        )
                                                        .foregroundColor(.secondary)
                                                }
                                                
                                                Spacer()
                                            }
                                            .padding(.horizontal, 16)
                                             // Per-table share as text (single table)
                                             Button(action: {
                                                 let text = viewModel.exportSingleTable(arrangement)
                                                 shareText = text
                                                 parentExportItems = [text]
                                                 AdsManager.shared.showInterstitialThen {
                                                     // Dismiss export sheet first to avoid multiple-sheet conflicts
                                                     dismiss()
                                                     DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                                                         parentIsShowingShareSheet = true
                                                     }
                                                 }
                                             }) {
                                                 HStack(spacing: 6) {
                                                     Image(systemName: "square.and.arrow.up")
                                                     Text("Share This Table")
                                                         .fontWeight(.semibold)
                                                 }
                                                 .font(.system(size: 14))
                                                 .padding(.vertical, 8)
                                                 .padding(.horizontal, 12)
                                                 .background(
                                                     RoundedRectangle(cornerRadius: 10)
                                                         .fill(Color.blue.opacity(0.1))
                                                 )
                                                 .foregroundColor(.blue)
                                             }
                                             .padding(.horizontal, 16)
                                             .padding(.top, 6)
                                        }
                                    }
                                }
                                .padding(.vertical, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color(.systemBackground))
                                        .shadow(color: Color.black.opacity(0.08), radius: 4, y: 2)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color(.systemGray5), lineWidth: 1)
                                )
                            }
                        }
                }
                .padding(.horizontal)
            }
        }
        .navigationBarTitle("Share Tables", displayMode: .inline)
        .navigationBarItems(trailing: Button("Done") {
            // Update the title before dismissing if it has changed
            if viewModel.currentArrangement.title != arrangementTitle {
                viewModel.currentArrangement.title = arrangementTitle
            }
            // Save a snapshot of the current arrangement to history then reset to a brand new empty arrangement
            viewModel.saveCurrentArrangement()
            dismiss()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
                    viewModel.resetAndShowWelcomeScreen()
                    showEffortlessScreen = true
                    showingTutorial = false
                }
            }
        }.tint(.blue))
        .accessibilityLabel("Share Tables")
        .accessibilityHint("Allows you to share your table arrangement with others")
        .safeAreaInset(edge: .bottom) {
            // ensure scroll can reach bottom by reserving a small inset
            Color.clear.frame(height: 20)
        }
    }
    
    // Helper to generate and show QR code
    private func generateAndShowQRCode() {
        // First update title if it changed
        if viewModel.currentArrangement.title != arrangementTitle {
            viewModel.currentArrangement.title = arrangementTitle
        }
        // Save a snapshot to history as part of QR generation
        viewModel.saveCurrentArrangement()
        
        // Close this sheet and show QR code sheet
        dismiss()
        
        // Use DispatchQueue to ensure proper timing
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            viewModel.showingQRCodeSheet = true
            
            // After QR code is shown, set up to return to welcome screen
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.viewModel.resetAndShowWelcomeScreen()
            }
        }
    }
    // --- Add state and helpers for editing table names ---
    @State private var editingTableId: Int? = nil
    @State private var editingTableName: String = ""

    private func startEditingTableName(tableId: Int, currentName: String) {
        editingTableId = tableId
        editingTableName = currentName
    }
    


    private func saveEditedTableName(tableId: Int) {
        guard let idx = nonEmptyTables.firstIndex(where: { $0.id == tableId }) else { return }
        let tableKey = viewModel.tableCollection.tables.keys.sorted()[idx]
        if var arrangement = viewModel.tableCollection.tables[tableKey] {
            let trimmedName = editingTableName.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmedName.isEmpty {
                arrangement.title = trimmedName // Update the title in the arrangement
                viewModel.tableCollection.tables[tableKey] = arrangement // Update the arrangement in the collection
                // If this is the current table, update the currentTableName as well
                if viewModel.tableCollection.currentTableId == tableKey {
                    viewModel.currentTableName = trimmedName
                    viewModel.currentArrangement.title = trimmedName
                }
                viewModel.saveTableCollection() // Save the entire collection
            }
        }
        editingTableId = nil
        editingTableName = ""
    }
}
// Helper for share sheet
struct ShareSheet: UIViewControllerRepresentable {
    var activityItems: [Any]
    var applicationActivities: [UIActivity]? = nil
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: applicationActivities)
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
// Helper component for the person bubble in table preview
struct PersonBubble: View {
    let person: Person
    let color: Color
    
    var body: some View {
        ZStack {
            Circle()
                .fill(color.opacity(0.2))
                .frame(width: 30, height: 30)
            
            Text(computeInitials(from: person.name))
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(color)
        }
        .overlay(
            Circle()
                .stroke(color.opacity(0.5), lineWidth: 1)
        )
    }
}

struct ContentView_Previews: PreviewProvider {
    @State static var showWelcomeScreen = false
    static var previews: some View {
        // Pass a literal false since the preview doesn't need a dynamic binding
        ContentView(showWelcomeScreen: false)
    }
}

// Add the new ZoomedTableView below:
struct ZoomedTableView: View {
    @Binding var arrangement: SeatingArrangement
    @Binding var tableName: String
    let personColors: [Color]
    var onClose: () -> Void
    var onEditProfile: (Person) -> Void
    @State private var rotation: Angle = .zero
    @State private var isRenaming = false
    @State private var tempName = ""
    var body: some View {
        ZStack(alignment: .topLeading) {
            Color(.systemBackground).edgesIgnoringSafeArea(.all)
            VStack(spacing: 24) {
                HStack {
                    Button(action: onClose) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.blue)
                            .padding(12)
                            .background(Circle().fill(Color.white).shadow(radius: 2))
                    }
                    Spacer()
                }
                .padding(.top, 30)
                .padding(.leading, 10)
                Spacer().frame(height: 10)
                // 3D Table
                ZStack {
                    Table3DView(
                        arrangement: arrangement,
                        personColors: personColors,
                        rotation: $rotation,
                        onEditProfile: onEditProfile
                    )
                    .frame(width: 340, height: 280)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                rotation = Angle(degrees: Double(value.translation.width))
                            }
                    )
                }
                .shadow(radius: 20)
                // Table name editor
                if isRenaming {
                    HStack {
                        TextField("Table Name", text: $tempName)
                            .font(.title2.bold())
                            .padding(8)
                            .background(RoundedRectangle(cornerRadius: 8).fill(Color.secondary.opacity(0.1)))
                        Button("Save") {
                            tableName = tempName
                            arrangement.title = tempName
                            isRenaming = false
                        }
                        .disabled(tempName.isEmpty)
                    }
                    .padding(.horizontal)
                } else {
                    HStack {
                        Text(tableName.isEmpty ? "Table" : tableName)
                            .font(.title2.bold())
                        Button(action: {
                            tempName = tableName
                            isRenaming = true
                        }) {
                            Image(systemName: "pencil")
                                .foregroundColor(.blue)
                        }
                    }
                }
                Spacer()
            }
        }
    }
}
// 3D TableView with improved icons
struct Table3DView: View {
    let arrangement: SeatingArrangement
    let personColors: [Color]
    @Binding var rotation: Angle
    var onEditProfile: (Person) -> Void
    
    // Helper function to calculate position
    private func calculatePosition(seatNumber: Int, totalSeats: Int) -> (x: CGFloat, y: CGFloat) {
        let angle = Double(seatNumber) / Double(totalSeats) * 2 * .pi
        let radius: CGFloat = 110
        let x = cos(angle + rotation.radians) * radius
        let y = sin(angle + rotation.radians) * radius * 0.5
        return (x: 170 + x, y: 100 + y)
    }
    
    // Helper view for person avatar
    private func PersonAvatar(person: Person) -> some View {
        ZStack {
            Circle()
                .fill(personColors[person.colorIndex % personColors.count].opacity(0.8))
                .frame(width: 54, height: 54)
                .shadow(radius: 6)
            
            if let imageData = person.profileImageData, let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 50, height: 50)
                    .clipShape(Circle())
            } else {
                Text(computeInitials(from: person.name))
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.white)
            }
        }
    }
    
    // Helper view for person seat
    private func PersonSeat(person: Person, seatNumber: Int) -> some View {
        let position = calculatePosition(seatNumber: seatNumber, totalSeats: arrangement.people.count)
        
        return VStack(spacing: 4) {
            PersonAvatar(person: person)
                .onTapGesture {
                    onEditProfile(person)
                }
            
            Text(person.name.split(separator: " ").first.map(String.init) ?? person.name)
                .font(.caption)
                .foregroundColor(.primary)
                .frame(width: 70)
                .lineLimit(1)
                .padding(.all, 8) // Add padding around the text
                .contentShape(Rectangle()) // Extend the tappable area to the padding
        }
        .position(x: position.x, y: position.y)
    }
    
    var body: some View {
        ZStack {
            // 3D effect table
            RoundedRectangle(cornerRadius: 40)
                .fill(LinearGradient(gradient: Gradient(colors: [Color.gray.opacity(0.25), Color.gray.opacity(0.1)]), startPoint: .top, endPoint: .bottom))
                .frame(width: 260, height: arrangement.tableShape == .rectangle ? 120 : 200)
                .rotation3DEffect(rotation, axis: (x: 0, y: 1, z: 0))
                .shadow(color: .gray.opacity(0.3), radius: 20, x: 0, y: 10)
            
            // Seats
            ForEach(arrangement.people) { person in
                if let seatNumber = arrangement.seatAssignments[person.id] {
                    PersonSeat(person: person, seatNumber: seatNumber)
                }
            }
        }
    }
}

// Add helper views for requesting permissions
struct RequestPhotoAccessView: View {
    let onComplete: (Bool) -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "photo.on.rectangle")
                .font(.system(size: 60))
                .foregroundColor(.blue)
            
            Text("Photo Access Required")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Please allow access to your photos to select a profile picture.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            
            Button(action: {
                PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
                    DispatchQueue.main.async {
                        onComplete(status == .authorized || status == .limited)
                    }
                }
            }) {
                Text("Allow Access")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(width: 200, height: 50)
                    .background(Color.blue)
                    .cornerRadius(12)
            }
            
            Button(action: {
                onComplete(false)
            }) {
                Text("Not Now")
                    .font(.headline)
                    .foregroundColor(.blue)
            }
        }
        .padding()
    }
}
struct RequestContactsAccessView: View {
    let onComplete: (Bool) -> Void
    var body: some View {
        Color.clear
            .onAppear {
                CNContactStore().requestAccess(for: .contacts) { granted, _ in
                    DispatchQueue.main.async {
                        onComplete(granted)
                    }
                }
            }
    }
}

// Add FAQView below SettingsViewImpl:
struct FAQView: View {
    @State private var expandedIndex: Int? = nil
    
    // Break down the FAQ data into a separate property
    private let faqData: [(icon: String, questionKey: String, answerKey: String, color: Color)] = [
        ("person.3.fill", "faq_add_people_q", "faq_add_people_a", .green),
        ("table.fill", "faq_create_tables_q", "faq_create_tables_a", .blue),
        ("dice.fill", "faq_shuffle_q", "faq_shuffle_a", .purple),
        ("lock.fill", "faq_lock_seat_q", "faq_lock_seat_a", .orange),
        ("square.and.arrow.up", "faq_share_q", "faq_share_a", .pink),
        ("globe", "faq_language_q", "faq_language_a", .teal)
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Break down the FAQ list into a separate view
            FAQListView(faqData: faqData, expandedIndex: $expandedIndex)
            
            // Contact Support button in a separate view
            ContactSupportButton()
        }
        .padding(.vertical, 4)
    }
}

// Separate view for FAQ list items
private struct FAQListView: View {
    let faqData: [(icon: String, questionKey: String, answerKey: String, color: Color)]
    @Binding var expandedIndex: Int?
    
    var body: some View {
        ForEach(faqData.indices, id: \.self) { idx in
            FAQItemView(faq: faqData[idx], isExpanded: expandedIndex == idx) {
                withAnimation {
                    expandedIndex = expandedIndex == idx ? nil : idx
                }
            }
        }
    }
}

// Separate view for individual FAQ items
private struct FAQItemView: View {
    let faq: (icon: String, questionKey: String, answerKey: String, color: Color)
    let isExpanded: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(alignment: .top, spacing: 12) {
                // Icon
                ZStack {
                    Circle()
                        .fill(faq.color.opacity(0.18))
                        .frame(width: 36, height: 36)
                    Image(systemName: faq.icon)
                        .foregroundColor(faq.color)
                        .font(.system(size: 18, weight: .bold))
                        .accessibilityHidden(true)
                }
                
                // Question and Answer
                VStack(alignment: .leading, spacing: 4) {
                    Text(NSLocalizedString(faq.questionKey, comment: "FAQ question"))
                        .font(.headline)
                        .dynamicTypeSize(.xSmall ... .accessibility5)
                        .minimumScaleFactor(0.7)
                        .lineLimit(2)
                        .accessibilityLabel(NSLocalizedString(faq.questionKey, comment: "FAQ question"))
                    if isExpanded {
                        Text(NSLocalizedString(faq.answerKey, comment: "FAQ answer"))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding(.top, 2)
                            .transition(.opacity)
                            .dynamicTypeSize(.xSmall ... .accessibility5)
                            .minimumScaleFactor(0.7)
                            .lineLimit(3)
                            .accessibilityLabel(NSLocalizedString(faq.answerKey, comment: "FAQ answer"))
                    }
                }
                Spacer()
                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .foregroundColor(.gray)
                    .accessibilityHidden(true)
            }
            .padding(.vertical, 8)
            .background(RoundedRectangle(cornerRadius: 12).fill(Color(.systemGray6)))
        }
        .buttonStyle(PlainButtonStyle())
        .frame(minWidth: 44, minHeight: 44)
        .accessibilityLabel(Text(NSLocalizedString(faq.questionKey, comment: "FAQ question")))
        .accessibilityAddTraits(.isButton)
    }
}

// Separate view for Contact Support button
private struct ContactSupportButton: View {
    var body: some View {
        HStack {
            Spacer()
            Button(action: {
                if let url = URL(string: "mailto:austinhfrankel@gmail.com") {
                    UIApplication.shared.open(url)
                }
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "envelope.fill")
                        .foregroundColor(.white)
                        .font(.system(size: 18, weight: .bold))
                    Text("Contact Support")
                        .font(.headline)
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.blue, Color.purple]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .cornerRadius(16)
                    .shadow(color: Color.accentColor.opacity(0.18), radius: 8, x: 0, y: 4)
                )
            }
            Spacer()
        }
        .padding(.top, 18)
    }
}

// Add LocalizationManager singleton at the bottom of the file:
final class LocalizationManager: ObservableObject {
    static let shared = LocalizationManager()
    @Published var locale: Locale = Locale.current
    private var cancellables = Set<AnyCancellable>()
    private init() {
        NotificationCenter.default.addObserver(forName: UserDefaults.didChangeNotification, object: nil, queue: .main) { [weak self] _ in
            let lang = UserDefaults.standard.string(forKey: "selectedLanguage") ?? "en"
            self?.setLanguage(lang)
        }
    }
    func setLanguage(_ code: String) {
        locale = Locale(identifier: code)
        objectWillChange.send()
    }
}

// Add this at the bottom of the file:
struct ComingSoonView: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: [Color.blue.opacity(0.2), Color.purple.opacity(0.15)]), startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            VStack(spacing: 32) {
                Spacer()
                Image(systemName: "clock.badge.exclamationmark.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 90, height: 90)
                    .foregroundColor(.blue)
                    .shadow(radius: 8)
                Text("Coming Soon")
                    .font(.largeTitle).fontWeight(.bold)
                    .foregroundColor(colorScheme == .dark ? .white : .blue)
                Text("Exporting your data as CSV will be available in a future update. Stay tuned!")
                    .font(.title3)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                Spacer()
                Button(action: { dismiss() }) {
                    Text("Close")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 40)
                        .padding(.vertical, 14)
                        .background(Capsule().fill(Color.accentColor))
                }
                Spacer().frame(height: 30)
            }
        }
        
    }
}
// Add ContactFormView below SettingsViewImpl:
struct ContactFormView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var feedbackText = ""
    @State private var feedbackCategory = "General Feedback"
    @State private var userEmail = ""
    @State private var isSubmitting = false
    @State private var showSuccessAlert = false
    @State private var showErrorAlert = false
    
    private let feedbackCategories = [
        "General Feedback",
        "Bug Report",
        "Feature Request",
        "App Suggestion",
        "Technical Issue",
        "Other"
    ]
    
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [Color.green.opacity(0.1), Color.blue.opacity(0.05)]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        VStack(spacing: 8) {
                            ZStack {
                                Circle().fill(Color.green.opacity(0.15)).frame(width: 80, height: 80)
                                Image(systemName: "envelope.badge.fill")
                                    .font(.system(size: 40, weight: .bold))
                                    .foregroundColor(.green)
                            }
                            
                            Text("Send Feedback")
                                .font(.title2.bold())
                                .foregroundColor(.primary)
                            
                            Text("Help us improve Seat Maker with your thoughts and suggestions")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        .padding(.top, 20)
                        
                        VStack(spacing: 20) {
                            // Feedback Category
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Category")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                Picker("Category", selection: $feedbackCategory) {
                                    ForEach(feedbackCategories, id: \.self) { category in
                                        Text(category).tag(category)
                                    }
                                }
                                .pickerStyle(MenuPickerStyle())
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color(.systemBackground))
                                        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                                )
                            }
                            
                            // Email (Optional)
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Your Email (Optional)")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                TextField("email@example.com", text: $userEmail)
                                    .textFieldStyle(PlainTextFieldStyle())
                                    .keyboardType(.emailAddress)
                                    .autocapitalization(.none)
                                    .padding()
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color(.systemBackground))
                                            .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                                    )
                            }
                            
                            // Feedback Text
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Your Feedback")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                ZStack(alignment: .topLeading) {
                                    TextEditor(text: $feedbackText)
                                        .frame(minHeight: 120)
                                        .padding(8)
                                        .background(
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(Color(.systemBackground))
                                                .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                                        )
                                    
                                    if feedbackText.isEmpty {
                                        Text("Tell us what you think about Seat Maker...")
                                            .foregroundColor(.secondary)
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 16)
                                    }
                                }
                            }
                            
                            // Submit Button
                            Button(action: submitFeedback) {
                                HStack {
                                    if isSubmitting {
                                        ProgressView()
                                            .scaleEffect(0.8)
                                            .foregroundColor(.white)
                                    } else {
                                        Image(systemName: "paperplane.fill")
                                            .font(.system(size: 16, weight: .bold))
                                    }
                                    Text(isSubmitting ? "Sending..." : "Send Feedback")
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 52)
                                .background(
                                    LinearGradient(
                                        gradient: Gradient(colors: [Color.green, Color.green.opacity(0.8)]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(16)
                                .shadow(color: Color.green.opacity(0.3), radius: 8, x: 0, y: 4)
                            }
                            .disabled(feedbackText.isEmpty || isSubmitting)
                            .opacity(feedbackText.isEmpty ? 0.6 : 1.0)
                        }
                        .padding(.horizontal, 24)
                        
                        Spacer(minLength: 40)
                    }
                }
            }
            .navigationBarTitle("Feedback", displayMode: .inline)
            .navigationBarItems(
                leading: Button("Cancel") {
                    dismiss()
                }
            )
            .alert("Feedback Sent!", isPresented: $showSuccessAlert) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("Thank you for your feedback! We'll review it carefully.")
            }
            .alert("Error", isPresented: $showErrorAlert) {
                Button("OK") {}
            } message: {
                Text("Unable to send feedback. Please check your email app is configured.")
            }
        }
    }
    
    private func submitFeedback() {
        guard !feedbackText.isEmpty else { return }
        
        isSubmitting = true
        
        // Create email content
        let emailSubject = "Seat Maker Feedback - \(feedbackCategory)"
        let emailBody = """
        Category: \(feedbackCategory)
        \(userEmail.isEmpty ? "" : "User Email: \(userEmail)")
        
        Feedback:
        \(feedbackText)
        
        ---
        Sent from Seat Maker iOS App
        """
        
        // Create mailto URL
        guard let emailURL = createEmailURL(
            to: "austinhfrankel@gmail.com",
            subject: emailSubject,
            body: emailBody
        ) else {
            isSubmitting = false
            showErrorAlert = true
            return
        }
        
        // Open email app
        if UIApplication.shared.canOpenURL(emailURL) {
            UIApplication.shared.open(emailURL) { success in
                DispatchQueue.main.async {
                    isSubmitting = false
                    if success {
                        showSuccessAlert = true
                    } else {
                        showErrorAlert = true
                    }
                }
            }
        } else {
            isSubmitting = false
            showErrorAlert = true
        }
    }
    
    private func createEmailURL(to: String, subject: String, body: String) -> URL? {
        let subjectEncoded = subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let bodyEncoded = body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        
        let urlString = "mailto:\(to)?subject=\(subjectEncoded)&body=\(bodyEncoded)"
        return URL(string: urlString)
    }
}

struct AboutMeView: View {
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: [Color.blue.opacity(0.18), Color.purple.opacity(0.12)]), startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            VStack(spacing: 32) {
                Spacer()
                Image(systemName: "person.crop.circle.fill")
                    .resizable()
                    .frame(width: 100, height: 100)
                    .foregroundColor(.blue)
                    .shadow(radius: 8)
                Text("Austin Frankel")
                    .font(.largeTitle).fontWeight(.bold)
                    .foregroundColor(.blue)
                Text("Product designer, developer, and creative mind behind Seat Maker. Austin is passionate about building delightful, intuitive tools that empower people to connect and create memorable experiences.\n\nFind more at: ")
                    .font(.title3)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                Link(destination: URL(string: "https://www.linkedin.com/in/austin-frankel/")!) {
                    HStack(spacing: 8) {
                        Image(systemName: "link")
                        Text("linkedin.com/in/austin-frankel")
                    }
                    .font(.headline)
                    .foregroundColor(.blue)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.7)))
                }
                Spacer()
                Button(action: { dismiss() }) {
                    Text("Close")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 40)
                        .padding(.vertical, 14)
                        .background(Capsule().fill(Color.accentColor))
                }
                Spacer().frame(height: 30)
            }
        }
    }
}
class SeatPositionCalculator {
    func calculatePositions(for shape: TableShape, in size: CGSize, totalSeats: Int, iconSize: CGFloat) -> [CGPoint] {
        guard totalSeats > 0 else { return [] }
        
        let positions: [CGPoint]
        
        switch shape {
        case .round:
            positions = calculateRoundPositions(in: size, totalSeats: totalSeats, iconSize: iconSize)
        case .rectangle:
            positions = calculateRectanglePositions(in: size, totalSeats: totalSeats, iconSize: iconSize)
        case .square:
            positions = calculateSquarePositions(in: size, totalSeats: totalSeats, iconSize: iconSize)
        }
        
        return adjustForOverlaps(positions: positions, iconSize: iconSize)
    }
    
    private func calculateRoundPositions(in size: CGSize, totalSeats: Int, iconSize: CGFloat) -> [CGPoint] {
        let centerX = size.width / 2
        let centerY = size.height / 2
        let adjustedCenterY = centerY + 10
        let tableDiameter = min(size.width, size.height) * 0.85
        let tableRadius = tableDiameter / 2
        // Bring people closer to the perimeter for round tables
        let perimeterOffset = iconSize * (0.45 + 0.02 * CGFloat(totalSeats))
        let adjustedOffset = perimeterOffset * 0.9

        return (0..<totalSeats).map { i in
            let startAngle = -Double.pi / 2
            let angle = startAngle + (2 * .pi * Double(i)) / Double(totalSeats)
            let x = centerX + (tableRadius + adjustedOffset) * cos(angle)
            let y = adjustedCenterY + (tableRadius + adjustedOffset) * sin(angle)
            return CGPoint(x: x, y: y)
        }
    }
    
    private func calculateRectanglePositions(in size: CGSize, totalSeats: Int, iconSize: CGFloat) -> [CGPoint] {
        let centerX = size.width / 2
        let centerY = size.height / 2
        let adjustedCenterY = centerY + 10
        let tableWidth = size.width * 0.85
        let tableHeight = size.height * 0.6
        let halfWidth = tableWidth / 2
        let halfHeight = tableHeight / 2
        // Increase offset as people increase
        let perimeterOffset = iconSize * (0.5 + 0.04 * CGFloat(totalSeats))
        var positions: [CGPoint] = []
        
        if totalSeats == 0 { return [] }
        
        if totalSeats <= 4 {
            // One per side, centered
            let offsets: [(CGFloat, CGFloat)] = [
                (0, -halfHeight - perimeterOffset), // Top
                (halfWidth + perimeterOffset, 0),   // Right
                (0, halfHeight + perimeterOffset), // Bottom
                (-halfWidth - perimeterOffset, 0)   // Left
            ]
            for i in 0..<totalSeats {
                let (dx, dy) = offsets[i]
                positions.append(CGPoint(x: centerX + dx, y: adjustedCenterY + dy))
            }
        } else if totalSeats <= 8 {
            // Two per side, better spacing
            let topSpacing = tableWidth * 0.5
            let sideSpacing = tableHeight * 0.5
            let offsets: [(CGFloat, CGFloat)] = [
                (-topSpacing/2, -halfHeight - perimeterOffset), (topSpacing/2, -halfHeight - perimeterOffset), // Top
                (halfWidth + perimeterOffset, -sideSpacing/2), (halfWidth + perimeterOffset, sideSpacing/2), // Right
                (topSpacing/2, halfHeight + perimeterOffset), (-topSpacing/2, halfHeight + perimeterOffset), // Bottom
                (-halfWidth - perimeterOffset, sideSpacing/2), (-halfWidth - perimeterOffset, -sideSpacing/2) // Left
            ]
            for i in 0..<totalSeats {
                let (dx, dy) = offsets[i]
                positions.append(CGPoint(x: centerX + dx, y: adjustedCenterY + dy))
            }
        } else {
            // For more than 8 people, distribute evenly around the rectangle perimeter
            let totalPerimeter = 2 * (tableWidth + tableHeight)
            let spacing = totalPerimeter / CGFloat(totalSeats)
            
            for i in 0..<totalSeats {
                let distance = spacing * CGFloat(i)
                
                if distance < tableWidth {
                    // Top side
                    let x = centerX - halfWidth + distance
                    positions.append(CGPoint(x: x, y: adjustedCenterY - halfHeight - perimeterOffset))
                } else if distance < tableWidth + tableHeight {
                    // Right side
                    let y = adjustedCenterY - halfHeight + (distance - tableWidth)
                    positions.append(CGPoint(x: centerX + halfWidth + perimeterOffset, y: y))
                } else if distance < 2 * tableWidth + tableHeight {
                    // Bottom side
                    let x = centerX + halfWidth - (distance - tableWidth - tableHeight)
                    positions.append(CGPoint(x: x, y: adjustedCenterY + halfHeight + perimeterOffset))
                } else {
                    // Left side
                    let y = adjustedCenterY + halfHeight - (distance - 2 * tableWidth - tableHeight)
                    positions.append(CGPoint(x: centerX - halfWidth - perimeterOffset, y: y))
                }
            }
        }
        return positions
    }
    
    private func calculateSquarePositions(in size: CGSize, totalSeats: Int, iconSize: CGFloat) -> [CGPoint] {
        let centerX = size.width / 2
        let centerY = size.height / 2
        let adjustedCenterY = centerY + 10
        let tableSide = min(size.width, size.height) * 0.85
        let halfSide = tableSide / 2
        // Bring people closer to the perimeter for square tables
        let perimeterOffset = iconSize * (0.35 + 0.02 * CGFloat(totalSeats))
        var positions: [CGPoint] = []
        
        if totalSeats == 0 { return [] }
        
        if totalSeats <= 4 {
            // One per side, centered
            let offsets: [(CGFloat, CGFloat)] = [
                (0, -halfSide - perimeterOffset), // Top
                (halfSide + perimeterOffset, 0), // Right
                (0, halfSide + perimeterOffset), // Bottom
                (-halfSide - perimeterOffset, 0) // Left
            ]
            for i in 0..<totalSeats {
                let (dx, dy) = offsets[i]
                positions.append(CGPoint(x: centerX + dx, y: adjustedCenterY + dy))
            }
        } else if totalSeats <= 8 {
            // Two per side, spaced
            let spacing = tableSide * 0.4
            let offsets: [(CGFloat, CGFloat)] = [
                (-spacing/2, -halfSide - perimeterOffset), (spacing/2, -halfSide - perimeterOffset), // Top
                (halfSide + perimeterOffset, -spacing/2), (halfSide + perimeterOffset, spacing/2), // Right
                (spacing/2, halfSide + perimeterOffset), (-spacing/2, halfSide + perimeterOffset), // Bottom
                (-halfSide - perimeterOffset, spacing/2), (-halfSide - perimeterOffset, -spacing/2) // Left
            ]
            for i in 0..<totalSeats {
                let (dx, dy) = offsets[i]
                positions.append(CGPoint(x: centerX + dx, y: adjustedCenterY + dy))
            }
        } else {
            // For more than 8 people, distribute evenly around the square perimeter
            let perimeter = 4 * tableSide
            let spacing = perimeter / CGFloat(totalSeats)
            
            for i in 0..<totalSeats {
                let distance = spacing * CGFloat(i)
                
                if distance < tableSide {
                    // Top side
                    let x = centerX - halfSide + distance
                    positions.append(CGPoint(x: x, y: adjustedCenterY - halfSide - perimeterOffset))
                } else if distance < 2 * tableSide {
                    // Right side
                    let y = adjustedCenterY - halfSide + (distance - tableSide)
                    positions.append(CGPoint(x: centerX + halfSide + perimeterOffset, y: y))
                } else if distance < 3 * tableSide {
                    // Bottom side
                    let x = centerX + halfSide - (distance - 2 * tableSide)
                    positions.append(CGPoint(x: x, y: adjustedCenterY + halfSide + perimeterOffset))
                } else {
                    // Left side
                    let y = adjustedCenterY + halfSide - (distance - 3 * tableSide)
                    positions.append(CGPoint(x: centerX - halfSide - perimeterOffset, y: y))
                }
            }
        }
        return positions
    }
    private func adjustForOverlaps(positions: [CGPoint], iconSize: CGFloat) -> [CGPoint] {
        var adjusted = positions
        if adjusted.count < 2 { return adjusted }
        let minDistance = iconSize * 1.05
        let maxPasses = 8
        for _ in 0..<maxPasses {
            var changed = false
            for i in 0..<adjusted.count {
                for j in (i + 1)..<adjusted.count {
                    let pos1 = adjusted[i]
                    let pos2 = adjusted[j]
                    let dist = hypot(pos1.x - pos2.x, pos1.y - pos2.y)
                    if dist < minDistance {
                        let angle = atan2(pos1.y - pos2.y, pos1.x - pos2.x)
                        let nudge = (minDistance - dist) / 2
                        adjusted[i].x += cos(angle) * nudge
                        adjusted[i].y += sin(angle) * nudge
                        adjusted[j].x -= cos(angle) * nudge
                        adjusted[j].y -= sin(angle) * nudge
                        changed = true
                    }
                }
            }
            if !changed { break }
        }
        // Final jitter if still too close
        for i in 0..<adjusted.count {
            for j in (i + 1)..<adjusted.count {
                let pos1 = adjusted[i]
                let pos2 = adjusted[j]
                let dist = hypot(pos1.x - pos2.x, pos1.y - pos2.y)
                if dist < minDistance {
                    let jitter: CGFloat = CGFloat.random(in: 8...16)
                    let angle = CGFloat.random(in: 0..<(2 * .pi))
                    adjusted[i].x += cos(angle) * jitter
                    adjusted[i].y += sin(angle) * jitter
                    adjusted[j].x -= cos(angle) * jitter
                    adjusted[j].y -= sin(angle) * jitter
                }
            }
        }
        // After all passes, if any positions are still too close, nudge them apart deterministically
        for i in 0..<adjusted.count {
            for j in (i + 1)..<adjusted.count {
                let pos1 = adjusted[i]
                let pos2 = adjusted[j]
                let dist = hypot(pos1.x - pos2.x, pos1.y - pos2.y)
                if dist < minDistance {
                    let angle = CGFloat.pi / 4 * CGFloat(i - j)
                    let nudge: CGFloat = minDistance - dist + 2
                    adjusted[i].x += cos(angle) * nudge
                    adjusted[i].y += sin(angle) * nudge
                    adjusted[j].x -= cos(angle) * nudge
                    adjusted[j].y -= sin(angle) * nudge
                }
            }
        }
        return adjusted
    }
}

// 1. Extract the row into a MiniPersonRow view
struct MiniPersonRow: View {
    let index: Int
    let person: Person
    let seatNumber: Int?
    let color: Color
    let isLocked: Bool
    let onNameUpdate: (String) -> Void
    let onEdit: () -> Void
    let onLockToggle: () -> Void
    @ObservedObject var viewModel: SeatingViewModel
    
    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            if let seatNumber = seatNumber {
                if !viewModel.hideSeatNumbers {
                    Text("\(seatNumber + 1)")
                        .font(.headline)
                        .foregroundColor(.blue)
                        .frame(width: 30)
                } else {
                    EmptyView()
                }
            } else {
                EmptyView()
            }
            PersonNameView(person: person, onUpdate: onNameUpdate, showDoneButtonOnRight: true)
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
                .onTapGesture(perform: onEdit)
            Button(action: onLockToggle) {
                Image(systemName: isLocked ? "lock.fill" : "lock.open")
                    .foregroundColor(isLocked ? .blue : .gray)
                    .font(.system(size: 18, weight: .semibold))
                    .padding(7)
                    .background(
                        Circle()
                            .fill(isLocked ? Color.blue.opacity(0.12) : Color.gray.opacity(0.08))
                    )
                    .scaleEffect(isLocked ? 1.1 : 1.0)
            }
            .buttonStyle(PlainButtonStyle())
            Image(systemName: "line.3.horizontal")
                .foregroundColor(.gray)
                .font(.system(size: 20, weight: .medium))
                .padding(.trailing, 2)
        }
        .padding(.vertical, 6) // Increased from 2 to 6 to make taller
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(Color(.systemBackground).opacity(0.97))
                .shadow(color: Color(.black).opacity(0.06), radius: 3, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22)
                .stroke(Color.gray.opacity(0.13), lineWidth: 1.5)
        )
    }
}

// 2. Extract the drag preview into a MiniPersonRowPreview view
struct MiniPersonRowPreview: View {
    let person: Person
    let seatNumber: Int?
    let color: Color
    let isLocked: Bool
    @ObservedObject var viewModel: SeatingViewModel
    
    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            if let seatNumber = seatNumber {
                if !viewModel.hideSeatNumbers {
                    Text("\(seatNumber + 1)")
                        .font(.headline)
                        .foregroundColor(.blue)
                        .frame(width: 30)
                } else {
                    EmptyView()
                }
            } else {
                EmptyView()
            }
            Text(person.name.split(separator: " ").first.map(String.init) ?? person.name)
                .font(.headline)
                .foregroundColor(.primary)
                .frame(width: 120, alignment: .leading)
            Button(action: {}) {
                Image(systemName: isLocked ? "lock.fill" : "lock.open")
                    .foregroundColor(isLocked ? .blue : .gray)
                    .font(.system(size: 18, weight: .semibold))
                    .padding(7)
                    .background(
                        Circle()
                            .fill(isLocked ? Color.blue.opacity(0.12) : Color.gray.opacity(0.08))
                    )
                    .scaleEffect(isLocked ? 1.1 : 1.0)
            }
            .buttonStyle(PlainButtonStyle())
            Image(systemName: "line.3.horizontal")
                .foregroundColor(.gray)
                .font(.system(size: 20, weight: .medium))
                .padding(.trailing, 2)
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 10)
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(Color(.systemBackground).opacity(0.97))
                .shadow(color: Color(.black).opacity(0.06), radius: 3, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22)
                .stroke(Color.gray.opacity(0.13), lineWidth: 1.5)
        )
    }
}

//

// MARK: - Table Manager (inline definition to ensure availability without Xcode project changes)
struct TableManagerView: View {
    @ObservedObject var viewModel: SeatingViewModel
    @Binding var isPresented: Bool
    var onOpenTable: ((Int) -> Void)? = nil

    enum SortKey: String, CaseIterable, Identifiable { case name, seats, shape; var id: String { rawValue } }
    @State private var sortKey: SortKey = .name
    @State private var sortAscending: Bool = true
    @State private var isSelecting: Bool = false
    @State private var selectedIds: Set<Int> = []
    @State private var showRenamePrompt: Int? = nil
    @State private var tempName: String = ""
    @State private var showToast: String? = nil
    @State private var showingReorder: Bool = false
    @State private var pendingDeleteIds: [Int] = []
    @State private var showDeleteConfirm: Bool = false

    private var allTablesSorted: [(id: Int, table: SeatingArrangement)] {
        let items = viewModel.tableCollection.tables.map { ($0.key, $0.value) }
        let sorted: [(Int, SeatingArrangement)] = items.sorted { a, b in
            switch sortKey {
            case .name:
                let an = a.1.title.localizedCaseInsensitiveCompare(b.1.title)
                return sortAscending ? (an == .orderedAscending) : (an == .orderedDescending)
            case .seats:
                return sortAscending ? (a.1.people.count < b.1.people.count) : (a.1.people.count > b.1.people.count)
            case .shape:
                let an = a.1.tableShape.rawValue.localizedCaseInsensitiveCompare(b.1.tableShape.rawValue)
                return sortAscending ? (an == .orderedAscending) : (an == .orderedDescending)
            }
        }
        return sorted
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                HStack {
                    Button(isSelecting ? "Done" : "Select") { isSelecting.toggle(); if !isSelecting { selectedIds.removeAll() } }
                        .font(.system(size: 16, weight: .semibold))
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.vertical, 8)

                if allTablesSorted.isEmpty {
                    Spacer()
                    VStack(spacing: 14) {
                        Image(systemName: "square.on.square")
                            .font(.system(size: 50))
                            .foregroundColor(.secondary)
                        Text("No tables yet")
                            .font(.headline)
                        Button(action: { createNewTableAndOpen() }) {
                            Label("Create your first table", systemImage: "plus.circle.fill")
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    Spacer()
                } else {
                    ScrollView {
                        let columns = [GridItem(.flexible()), GridItem(.flexible())]
                        LazyVGrid(columns: columns, spacing: 12) {
                            ForEach(allTablesSorted, id: \.0) { id, arrangement in
                                TableCard(
                                    id: id,
                                    arrangement: arrangement,
                                    isSelected: selectedIds.contains(id),
                                    isSelecting: isSelecting,
                                    onTap: { openTable(id: id) },
                                    onToggleSelect: {
                                        if selectedIds.contains(id) { selectedIds.remove(id) } else { selectedIds.insert(id) }
                                    },
                                    onRename: { startRename(id: id, current: arrangement.title) },
                                     onDuplicate: { _ = viewModel.duplicateTable(id: id) },
                                     onDelete: { requestDeleteFor(id) },
                                    viewModel: viewModel
                                )
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 8)
                        .padding(.bottom, 12)
                    }
                }

                if isSelecting && !selectedIds.isEmpty {
                    HStack {
                        Spacer()
                        Button(role: .destructive) { requestDeleteSelected() } label: {
                            Label("Delete", systemImage: "trash")
                        }
                        .buttonStyle(.bordered)
                        Spacer()
                    }
                    .padding()
                }
            }
            .navigationTitle("All Tables")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { isPresented = false }) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                            Text("Close")
                        }
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 12) {
                        Button(action: { showingReorder = true }) {
                            Label("Reorder", systemImage: "arrow.up.arrow.down.circle")
                        }
                        Button(action: { createNewTableAndOpen() }) {
                            Label("New Table", systemImage: "plus")
                        }
                    }
                }
            }
            .sheet(isPresented: $showingReorder) {
                ReorderTablesView(viewModel: viewModel, isPresented: $showingReorder)
            }
            .tint(.blue)
            .alert("Rename Table", isPresented: Binding(get: { showRenamePrompt != nil }, set: { if !$0 { showRenamePrompt = nil } })) {
                TextField("Table name", text: $tempName).autocapitalization(.words)
                Button("Cancel", role: .cancel) { showRenamePrompt = nil }
                Button("Save") { commitRename() }
            }
            .alert("Delete Table?", isPresented: $showDeleteConfirm) {
                Button("Delete", role: .destructive) {
                    viewModel.deleteTables(ids: pendingDeleteIds)
                    for id in pendingDeleteIds { selectedIds.remove(id) }
                    pendingDeleteIds.removeAll()
                }
                Button("Cancel", role: .cancel) { pendingDeleteIds.removeAll() }
            } message: {
                Text(pendingDeleteIds.count > 1 ? "One or more selected tables have seated people. This will remove them from those tables." : "This table has seated people. Delete anyway?")
            }
            .overlay(alignment: .top) {
                if let toast = showToast {
                    Text(toast)
                        .font(.caption)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Capsule().fill(Color(.systemGray5)))
                        .padding(.top, 6)
                        .transition(.opacity)
                }
            }
        }
    }

    private func openTable(id: Int) {
        viewModel.switchToTable(id: id)
        showTransientToast("Opened Table \(id + 1)")
        onOpenTable?(id)
        isPresented = false
    }

    private func createNewTableAndOpen() {
        // Gate creating additional tables behind Pro if more than 1 exists
        let existingCount = viewModel.tableCollection.tables.count
        if existingCount >= 1 && !canUseUnlimitedFeatures() {
            NotificationCenter.default.post(name: .showPaywall, object: nil)
            return
        }
        let id = viewModel.createAndSwitchToNewTable()
        showTransientToast("Opened Table \(id + 1)")
        onOpenTable?(id)
        isPresented = false
    }

    private func startRename(id: Int, current: String) {
        tempName = current
        showRenamePrompt = id
    }

    private func commitRename() {
        guard let id = showRenamePrompt else { return }
        viewModel.renameTable(id: id, to: tempName)
        showRenamePrompt = nil
        tempName = ""
    }

    private func bulkDuplicateSelected() {
        let ids = selectedIds.sorted()
        for id in ids { _ = viewModel.duplicateTable(id: id) }
        selectedIds.removeAll()
    }

    private func requestDeleteFor(_ id: Int) {
        let hasSeated = !(viewModel.tableCollection.tables[id]?.people.isEmpty ?? true)
        if hasSeated {
            pendingDeleteIds = [id]
            showDeleteConfirm = true
        } else {
            viewModel.deleteTables(ids: [id])
        }
    }

    private func requestDeleteSelected() {
        let ids = Array(selectedIds)
        guard !ids.isEmpty else { return }
        let requiresConfirm = ids.contains { !(viewModel.tableCollection.tables[$0]?.people.isEmpty ?? true) }
        if requiresConfirm {
            pendingDeleteIds = ids
            showDeleteConfirm = true
        } else {
            viewModel.deleteTables(ids: ids)
            selectedIds.removeAll()
        }
    }

    private func showTransientToast(_ message: String) {
        withAnimation { showToast = message }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
            withAnimation { showToast = nil }
        }
    }
}

private struct TableCard: View {
    let id: Int
    let arrangement: SeatingArrangement
    let isSelected: Bool
    let isSelecting: Bool
    let onTap: () -> Void
    let onToggleSelect: () -> Void
    let onRename: () -> Void
    let onDuplicate: () -> Void
    let onDelete: () -> Void
    @ObservedObject var viewModel: SeatingViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Spacer(minLength: 0)
            // Mini table preview centered within a fixed area so it sits visually near the card center
            ZStack {
                ContentView.TableView(
                    arrangement: arrangement,
                    getPersonColor: { id in
                        arrangement.people.first(where: { $0.id == id })?.color ?? .blue
                    },
                    onPersonTap: { _ in }
                )
                .scaleEffect(0.76)
                .frame(height: 125)
                .padding(.top, 16)
            }
            .frame(height: 176)
            .background(RoundedRectangle(cornerRadius: 12).fill(Color(.systemBackground)))
            // Move controls to the top of the preview area
            .overlay(alignment: .topLeading) {
                Button(action: onRename) {
                    Image(systemName: "rectangle.and.pencil.and.ellipsis")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.blue)
                        .padding(8)
                        .background(Capsule().fill(Color(.systemGray6)))
                        .frame(minWidth: 44, minHeight: 44)
                }
                .padding(6)
                .offset(y: -14)
            }
            .overlay(alignment: .topTrailing) {
                Button(action: { onDelete() }) {
                    Image(systemName: "trash")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.red)
                        .padding(8)
                        .background(Capsule().fill(Color(.systemGray6)))
                        .frame(minWidth: 44, minHeight: 44)
                }
                .padding(6)
                .offset(y: -14)
            }
            

            // Push labels to the bottom of the card area
            Spacer()
            Text(arrangement.title.isEmpty ? "Table \(id + 1)" : arrangement.title)
                .font(.headline)
                .lineLimit(1)
                .padding(.top, 10) // move label down slightly

            HStack(spacing: 8) {
                        Text("\(arrangement.people.count) seated")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text(arrangement.tableShape.rawValue.capitalized)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(Color(.systemGray5)))
            }
        }
        .frame(minHeight: 236)
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.06), radius: 3, x: 0, y: 2)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(isSelected ? Color.blue : Color.gray.opacity(0.15), lineWidth: isSelected ? 2 : 1)
                )
        )
        .contextMenu {
            Button("Rename", action: onRename)
            Button(role: .destructive) { onDelete() } label: { Text("Delete") }
        }
        .onTapGesture {
            if isSelecting { onToggleSelect() } else { onTap() }
        }
    }
}
// Inline reorder view for tables
struct ReorderTablesView: View {
    @ObservedObject var viewModel: SeatingViewModel
    @Binding var isPresented: Bool
    @State private var order: [Int] = []
    @Environment(\.editMode) private var editMode

    var body: some View {
        NavigationView {
            List {
                ForEach(Array(order.enumerated()), id: \.offset) { _, id in
                    HStack {
                        // Remove leading drag handle icon for a cleaner row
                        Text(viewModel.tableCollection.tables[id]?.title.isEmpty == false ? (viewModel.tableCollection.tables[id]?.title ?? "Table") : "Table \(id + 1)")
                        Spacer()
                        Text("\(viewModel.tableCollection.tables[id]?.people.count ?? 0) seated")
                            .foregroundColor(.secondary)
                            .font(.subheadline)
                    }
                }
                .onMove { source, destination in
                    order.move(fromOffsets: source, toOffset: destination)
                }
                .onDelete { offsets in
                    let ids = offsets.map { order[$0] }
                    viewModel.deleteTables(ids: ids)
                    order.remove(atOffsets: offsets)
                }
            }
            .navigationTitle("Reorder Tables")
            .navigationBarItems(
                leading: Button("Cancel") { isPresented = false }.tint(.blue),
                trailing:
                    HStack(spacing: 12) {
                        Button("Done") {
                            viewModel.reorderTables(newOrder: order)
                            isPresented = false
                            editMode?.wrappedValue = .inactive
                        }.tint(.blue)
                    }
            )
            .onAppear {
                order = viewModel.tableCollection.tables.keys.sorted()
                editMode?.wrappedValue = .active
            }
        }
    }
}
