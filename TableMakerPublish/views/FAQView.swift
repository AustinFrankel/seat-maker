import SwiftUI

struct FAQScreenView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var isAnimating = false
    @State private var selectedSection: String? = nil
    @State private var showPaywall = false
    
    var body: some View {
        ZStack {
            // Subtle background gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(.systemGroupedBackground),
                    Color(.systemBackground).opacity(0.8)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 32) {
                    // Enhanced Header
                    headerSection
                    
                    // FAQ Categories with enhanced design
                    LazyVStack(spacing: 28) {
                        // Getting Started Section
                        EnhancedFAQSectionView(
                            title: "Getting Started",
                            items: gettingStartedFAQs,
                            icon: "play.circle.fill",
                            color: .green,
                            isSelected: selectedSection == "Getting Started"
                        ) {
                            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                                selectedSection = selectedSection == "Getting Started" ? nil : "Getting Started"
                            }
                        }
                        
                        // Table Management Section
                        EnhancedFAQSectionView(
                            title: "Table Management",
                            items: tableManagementFAQs,
                            icon: "tablecells.fill",
                            color: .blue,
                            isSelected: selectedSection == "Table Management"
                        ) {
                            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                                selectedSection = selectedSection == "Table Management" ? nil : "Table Management"
                            }
                        }
                        
                        // Features & Customization Section
                        EnhancedFAQSectionView(
                            title: "Features & Customization",
                            items: featuresFAQs,
                            icon: "star.circle.fill",
                            color: .purple,
                            isSelected: selectedSection == "Features & Customization"
                        ) {
                            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                                selectedSection = selectedSection == "Features & Customization" ? nil : "Features & Customization"
                            }
                        }
                        
                        // Data & Privacy Section
                        EnhancedFAQSectionView(
                            title: "Data & Privacy",
                            items: dataPrivacyFAQs,
                            icon: "lock.shield.fill",
                            color: .orange,
                            isSelected: selectedSection == "Data & Privacy"
                        ) {
                            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                                selectedSection = selectedSection == "Data & Privacy" ? nil : "Data & Privacy"
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.bottom, 40)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1)) {
                isAnimating = true
            }
        }
        .fullScreenCover(isPresented: $showPaywall) {
            PaywallHost(isPresented: $showPaywall)
        }
        .onReceive(NotificationCenter.default.publisher(for: .showPaywall)) { _ in
            if shouldSuppressPaywall() { return }
            AdsManager.shared.cancelPendingCompletion()
            showPaywall = true
        }
        .onReceive(NotificationCenter.default.publisher(for: .didUnlockPro)) { _ in
            showPaywall = false
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 0) {
            // Regular back button
            HStack {
                Button(action: { dismiss() }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                        Text("Back")
                            .font(.system(size: 16, weight: .regular))
                    }
                    .foregroundColor(.blue)
                }
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            
            // Enhanced Header with visual appeal
            VStack(spacing: 20) {
                // Icon with animated glow
                ZStack {
                    // Outer glow
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color.blue.opacity(0.3), Color.clear],
                                center: .center,
                                startRadius: 0,
                                endRadius: 80
                            )
                        )
                        .frame(width: 160, height: 160)
                        .scaleEffect(isAnimating ? 1.2 : 0.8)
                        .animation(
                            .easeInOut(duration: 2)
                            .repeatForever(autoreverses: true),
                            value: isAnimating
                        )
                    
                    // Main icon container
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.blue.opacity(0.2), Color.purple.opacity(0.15)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 120, height: 120)
                        .overlay(
                            Circle()
                                .stroke(
                                    LinearGradient(
                                        colors: [Color.blue, Color.purple],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 2
                                )
                        )
                        .shadow(color: Color.blue.opacity(0.3), radius: 15, x: 0, y: 8)
                    
                    // Icon
                    Image(systemName: "questionmark.circle.fill")
                        .font(.system(size: 50, weight: .light))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.blue, Color.purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .rotationEffect(.degrees(isAnimating ? 5 : -5))
                        .animation(
                            .easeInOut(duration: 3)
                            .repeatForever(autoreverses: true),
                            value: isAnimating
                        )
                }
                
                VStack(spacing: 12) {
                    Text("Frequently Asked Questions")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.blue, Color.purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .multilineTextAlignment(.center)
                    
                    Text("Find answers to common questions about Seat Maker")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                }
            }
            .padding(.top, 20)
            .padding(.bottom, 30)
        }
    }
}

private struct EnhancedFAQSectionView: View {
    let title: String
    let items: [FAQItem]
    let icon: String
    let color: Color
    let isSelected: Bool
    let onTap: () -> Void
    
    @State private var isExpanded = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Section header button
            Button(action: onTap) {
                HStack(spacing: 16) {
                    // Icon with background
                    ZStack {
                        Circle()
                            .fill(color.opacity(0.15))
                            .frame(width: 50, height: 50)
                        
                        Image(systemName: icon)
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundColor(color)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.primary)
                        
                        Text("\(items.count) questions")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    // Animated chevron
                    Image(systemName: isSelected ? "chevron.up.circle.fill" : "chevron.down.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(color)
                        .rotationEffect(.degrees(isSelected ? 180 : 0))
                        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isSelected)
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color(.systemBackground))
                        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(color.opacity(0.2), lineWidth: 2)
                        )
                )
                .scaleEffect(isSelected ? 1.02 : 1.0)
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isSelected)
            }
            .buttonStyle(PlainButtonStyle())
            
            // FAQ items
            if isSelected {
                VStack(spacing: 16) {
                    ForEach(items) { item in
                        EnhancedFAQItemView(item: item, sectionColor: color)
                    }
                }
                .padding(.top, 16)
                .transition(
                    .asymmetric(
                        insertion: .opacity.combined(with: .move(edge: .top)).combined(with: .scale(scale: 0.95)),
                        removal: .opacity.combined(with: .move(edge: .top)).combined(with: .scale(scale: 0.95))
                    )
                )
                .animation(.spring(response: 0.5, dampingFraction: 0.8), value: isSelected)
            }
        }
    }
}

private struct EnhancedFAQItemView: View {
    let item: FAQItem
    let sectionColor: Color
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button(action: { 
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) { 
                    isExpanded.toggle() 
                }
            }) {
                HStack(spacing: 16) {
                    // Question icon
                    ZStack {
                        Circle()
                            .fill(sectionColor.opacity(0.1))
                            .frame(width: 40, height: 40)
                        
                        Image(systemName: item.icon)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(sectionColor)
                    }
                    
                    Text(item.question)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                        .lineLimit(isExpanded ? nil : 2)
                    
                    Spacer()
                    
                    // Animated chevron
                    Image(systemName: isExpanded ? "chevron.up.circle.fill" : "chevron.down.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(sectionColor)
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isExpanded)
                }
                .padding(20)
            }
            .buttonStyle(PlainButtonStyle())
            
            // Answer section
            if isExpanded {
                VStack(alignment: .leading, spacing: 16) {
                    Divider()
                        .background(sectionColor.opacity(0.2))
                    
                    Text(item.answer)
                        .font(.system(size: 15, weight: .regular))
                        .foregroundColor(.secondary)
                        .lineSpacing(4)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                }
                .transition(
                    .asymmetric(
                        insertion: .opacity.combined(with: .move(edge: .top)).combined(with: .scale(scale: 0.98)),
                        removal: .opacity.combined(with: .move(edge: .top)).combined(with: .scale(scale: 0.98))
                    )
                )
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isExpanded)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.06), radius: 6, x: 0, y: 3)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(sectionColor.opacity(0.1), lineWidth: 1)
                )
        )
        .scaleEffect(isExpanded ? 1.01 : 1.0)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isExpanded)
    }
}

struct FAQItem: Identifiable {
    let id = UUID()
    let question: String
    let answer: String
    let icon: String
    let iconColor: Color
}

// Getting Started FAQs
private let gettingStartedFAQs = [
    FAQItem(
        question: "How do I get started with Seat Maker?",
        answer: "Getting started is easy! After launching the app, tap the '+' button to create your first arrangement. You can then choose between round or rectangular tables, add guests, and start arranging them. The app includes an interactive tutorial that will guide you through all the basic features.",
        icon: "play.circle.fill",
        iconColor: .green
    ),
    FAQItem(
        question: "What types of events is Seat Maker suitable for?",
        answer: "Seat Maker is perfect for any event that requires seating arrangements, including:\n• Weddings and receptions\n• Corporate events and conferences\n• Birthday parties and celebrations\n• Holiday gatherings\n• Business dinners\n• School events and proms\nThe app is flexible enough to handle both small intimate gatherings and large-scale events.",
        icon: "calendar.circle.fill",
        iconColor: .blue
    ),
    FAQItem(
        question: "Is there a limit to the number of guests I can add?",
        answer: "Seat Maker supports up to 20 people per table, which is suitable for most event seating arrangements. You can create multiple tables to accommodate larger events. The app is optimized for events with multiple tables and provides an intuitive interface for managing complex seating arrangements.",
        icon: "person.3.fill",
        iconColor: .purple
    )
]

// Table Management FAQs
private let tableManagementFAQs = [
    FAQItem(
        question: "How do I customize table layouts?",
        answer: "Seat Maker offers several customization options:\n• Choose between round or rectangular tables\n• Add and remove people from tables\n• Lock people to specific seats\n• Shuffle seating arrangements\n• Hide or show seat numbers\n• Hide or show table numbers\nUse the settings and options available in the app to customize your layout.",
        icon: "slider.horizontal.3",
        iconColor: .orange
    ),
    FAQItem(
        question: "Can I set seating preferences or restrictions?",
        answer: "Yes! Seat Maker offers seating management features:\n• Lock guests to specific seats\n• Shuffle only unlocked seats\n• Create multiple tables for different groups\n• Manually arrange people by dragging\n• Add notes for special accommodations\nLong-press on a guest's name to access lock/unlock options.",
        icon: "hand.raised.fill",
        iconColor: .red
    ),
    FAQItem(
        question: "How does the shuffle feature work?",
        answer: "The shuffle feature randomly rearranges people while respecting locked seats. Only unlocked people will be moved to new positions, keeping locked people in their assigned seats. This is perfect for creating fair and random seating arrangements while maintaining any necessary fixed positions.",
        icon: "wand.and.stars",
        iconColor: .blue
    )
]

// Features & Customization FAQs
private let featuresFAQs = [
    FAQItem(
        question: "What sharing features are available?",
        answer: "Seat Maker offers several ways to share your arrangements:\n• Share via Universal Link QR (works from the Camera app)\n• Snapshot import works fully offline\n• Optional Live Share (nearby, peer‑to‑peer with PIN)\n• Export seating charts as text\n• Copy to clipboard and share individual tables\nAll data stays on device; no server is used.",
        icon: "square.and.arrow.up.fill",
        iconColor: .blue
    ),
    FAQItem(
        question: "Can I import guest lists from contacts?",
        answer: "Yes! Seat Maker can access your device contacts to help you add guests quickly. The app will request permission to access your contacts, and you can then search and select people to add to your seating arrangements. This makes it easy to populate your guest list without typing each name manually.",
        icon: "square.and.arrow.down.fill",
        iconColor: .green
    ),
    FAQItem(
        question: "What customization options are available for the display?",
        answer: "Seat Maker offers display customization options:\n• Hide or show seat numbers\n• Hide or show table numbers\n• Choose between round and rectangular tables\n• Adjust text sizes through system settings\n• Use dark or light mode\n• Accessibility features for better usability\nAccess these options in the app settings menu.",
        icon: "paintbrush.fill",
        iconColor: .purple
    )
]

// Data & Privacy FAQs
private let dataPrivacyFAQs = [
    FAQItem(
        question: "How is my data stored and protected?",
        answer: "Seat Maker takes data privacy seriously:\n• All data is stored locally on your device\n• No data is sent to external servers\n• No tracking or analytics for shared links\n• Peer‑to‑peer sessions are end‑to‑end encrypted by the system\n• Optional contact access for adding guests\nYour seating arrangements never leave your device unless you share them.",
        icon: "lock.shield.fill",
        iconColor: .blue
    ),
    FAQItem(
        question: "Can I backup and restore my arrangements?",
        answer: "Yes, Seat Maker provides backup options:\n• Export arrangements as text\n• Copy arrangements to clipboard\n• Save arrangements to your device\n• Share arrangements via messaging apps\n• Generate QR codes for sharing\nYour arrangements are automatically saved as you create them.",
        icon: "arrow.clockwise",
        iconColor: .green
    ),
    FAQItem(
        question: "What happens to my data if I uninstall the app?",
        answer: "When you uninstall Seat Maker:\n• Local data is removed from device\n• Exported files are preserved\n• Shared arrangements stay with recipients\n• No data remains on your device\nWe recommend exporting your arrangements before uninstalling if you want to keep them for future reference.",
        icon: "trash.fill",
        iconColor: .red
    )
] 
