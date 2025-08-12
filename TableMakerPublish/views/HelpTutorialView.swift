import SwiftUI

struct HelpTutorialView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var step: Int = 0
    private let totalSteps = 10

    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()
                VStack(spacing: 0) {
                    ProgressView(value: Double(step + 1), total: Double(totalSteps))
                        .accentColor(.blue)
                        .padding(.horizontal)
                        .padding(.top, 12)

                    Spacer(minLength: 10)

                    TabView(selection: $step) {
                        HelpStepCard(
                            icon: "book.fill",
                            iconColor: .blue,
                            title: "Welcome to Seat Maker!",
                            description: "Seat Maker helps you create, manage, and share seating arrangements for any event. This in-depth guide will show you all the features, tips, and best practices.",
                            illustration: AnyView(
                                Image(systemName: "tablecells")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 80, height: 80)
                                    .foregroundColor(.blue.opacity(0.7))
                            ),
                            showArrow: false
                        ).tag(0)

                        HelpStepCard(
                            icon: "plus.circle.fill",
                            iconColor: .green,
                            title: "Getting Started",
                            description: "Tap 'Add' to enter a name or import from contacts. You can add up to 20 people per table. Use the suggestions to speed up entry.",
                            illustration: AnyView(
                                VStack(spacing: 8) {
                                    HStack(spacing: 8) {
                                        Image(systemName: "person.crop.circle.badge.plus")
                                            .font(.system(size: 32))
                                            .foregroundColor(.green)
                                        Text("Add People")
                                            .font(.subheadline)
                                            .foregroundColor(.primary)
                                    }
                                    .padding(8)
                                    .background(RoundedRectangle(cornerRadius: 12).fill(Color.green.opacity(0.08)))
                                }
                            ),
                            showArrow: false
                        ).tag(1)

                        HelpStepCard(
                            icon: "tablecells",
                            iconColor: .blue,
                            title: "Creating & Naming Tables",
                            description: "You can create and name tables in Settings. Use the left/right arrows to switch tables.",
                            illustration: AnyView(
                                VStack(spacing: 0) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 16)
                                            .fill(Color.blue.opacity(0.08))
                                            .frame(width: 180, height: 80)
                                        Text("Table 1")
                                            .font(.title2.bold())
                                            .foregroundColor(.blue)
                                            .padding(.top, 8)
                                    }
                                }
                            ),
                            showArrow: false
                        ).tag(2)

                        HelpStepCard(
                            icon: "person.3.fill",
                            iconColor: .purple,
                            title: "Managing People",
                            description: "Tap a person's name to edit it. Long-press to edit or delete. Drag the handle to reorder people. Use color coding for easy identification.",
                            illustration: AnyView(
                                VStack(spacing: 8) {
                                    HStack(spacing: 8) {
                                        Image(systemName: "person.fill")
                                            .font(.system(size: 32))
                                            .foregroundColor(.blue)
                                        Text("Alice")
                                            .font(.headline)
                                            .foregroundColor(.primary)
                                        Spacer()
                                        Image(systemName: "line.horizontal.3")
                                            .foregroundColor(.gray)
                                    }
                                    .padding(8)
                                    .background(RoundedRectangle(cornerRadius: 10).fill(Color.blue.opacity(0.08)))
                                    HStack(spacing: 8) {
                                        Image(systemName: "person.fill")
                                            .font(.system(size: 32))
                                            .foregroundColor(.orange)
                                        Text("Bob")
                                            .font(.headline)
                                            .foregroundColor(.primary)
                                        Spacer()
                                        Image(systemName: "line.horizontal.3")
                                            .foregroundColor(.gray)
                                    }
                                    .padding(8)
                                    .background(RoundedRectangle(cornerRadius: 10).fill(Color.orange.opacity(0.08)))
                                }
                            ),
                            showArrow: false
                        ).tag(3)

                        HelpStepCard(
                            icon: "dice.fill",
                            iconColor: .purple,
                            title: "Shuffling Seats",
                            description: "Tap the 'Shuffle' button to randomize seating. Locked people will stay in their seats. Try shuffling multiple times for different results!",
                            illustration: AnyView(
                                VStack(spacing: 8) {
                                    Image(systemName: "dice.fill")
                                        .font(.system(size: 48))
                                        .foregroundColor(.purple)
                                    Text("Tap to Shuffle!")
                                        .font(.headline)
                                        .foregroundColor(.purple)
                                }
                            ),
                            showArrow: false
                        ).tag(4)

                        HelpStepCard(
                            icon: "lock.fill",
                            iconColor: .blue,
                            title: "Locking & Unlocking",
                            description: "Tap the lock icon next to a person to lock or unlock their seat. Locked people are not moved when shuffling. Use this for VIPs or special guests.",
                            illustration: AnyView(
                                HStack(spacing: 16) {
                                    VStack {
                                        Image(systemName: "lock.open")
                                            .font(.system(size: 32))
                                            .foregroundColor(.gray)
                                        Text("Unlocked")
                                            .font(.caption)
                                    }
                                    VStack {
                                        Image(systemName: "lock.fill")
                                            .font(.system(size: 32))
                                            .foregroundColor(.blue)
                                        Text("Locked")
                                            .font(.caption)
                                    }
                                }
                            ),
                            showArrow: false
                        ).tag(5)

                        HelpStepCard(
                            icon: "square.on.circle",
                            iconColor: .blue,
                            title: "Table Shapes",
                            description: "Choose from round, rectangle, or square tables. Table shape affects how people are arranged visually. Use the shape selector to switch instantly.",
                            illustration: AnyView(
                                HStack(spacing: 18) {
                                    VStack {
                                        Image(systemName: "circle")
                                            .font(.system(size: 32))
                                            .foregroundColor(.blue)
                                            .frame(maxWidth: 100)
                                        Text("Round")
                                            .font(.caption)
                                    }
                                    VStack {
                                        Image(systemName: "rectangle")
                                            .font(.system(size: 32))
                                            .foregroundColor(.blue)
                                            .frame(maxWidth: 100)
                                        Text("Rectangle")
                                            .font(.caption)
                                    }
                                    VStack {
                                        Image(systemName: "square")
                                            .font(.system(size: 32))
                                            .foregroundColor(.blue)
                                            .frame(maxWidth: 100)
                                        Text("Square")
                                            .font(.caption)
                                    }
                                }
                            ),
                            showArrow: false
                        ).tag(6)

                        HelpStepCard(
                            icon: "eye.fill",
                            iconColor: .teal,
                            title: "Hiding Seat Numbers",
                            description: "Toggle seat numbers on or off for a cleaner look. Use the eye icon in settings to hide or show seat numbers as needed.",
                            illustration: AnyView(
                                Image(systemName: "eye.slash")
                                    .font(.system(size: 38))
                                    .foregroundColor(.teal)
                            ),
                            showArrow: false
                        ).tag(7)

                        HelpStepCard(
                            icon: "square.and.arrow.up",
                            iconColor: .blue,
                            title: "Exporting & Sharing",
                            description: "Export your arrangement as text, image, or CSV. Share via Messages, Email, or QR code. Use the share button for quick access.",
                            illustration: AnyView(
                                HStack(spacing: 18) {
                                    Image(systemName: "square.and.arrow.up")
                                        .font(.system(size: 32))
                                        .foregroundColor(.blue)
                                    Image(systemName: "qrcode")
                                        .font(.system(size: 32))
                                        .foregroundColor(.green)
                                }
                            ),
                            showArrow: false
                        ).tag(8)

                        HelpStepCard(
                            icon: "lightbulb.fill",
                            iconColor: .yellow,
                            title: "Tips & Accessibility",
                            description: "Use color coding for guests. The app supports VoiceOver, Dynamic Type, and large hit targets for accessibility. All features work offline.",
                            illustration: AnyView(
                                Image(systemName: "hand.raised.fill")
                                    .font(.system(size: 38))
                                    .foregroundColor(.yellow)
                            ),
                            showArrow: false
                        ).tag(9)
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                    .animation(.spring(response: 0.22, dampingFraction: 0.8), value: step)

                    Spacer()

                    HStack {
                        Button(action: { if step > 0 { step -= 1 } }) {
                            HStack {
                                Image(systemName: "arrow.left.circle.fill")
                                Text("Back")
                            }
                        }
                        .disabled(step == 0)
                        .opacity(step == 0 ? 0.5 : 1)
                        .buttonStyle(PlainButtonStyle())
                        .font(.headline)
                        .foregroundColor(.blue)
                        Spacer()
                        Button(action: { if step < totalSteps - 1 { step += 1 } else { dismiss() } }) {
                            HStack {
                                Text(step == totalSteps - 1 ? "Done" : "Next")
                                Image(systemName: step == totalSteps - 1 ? "checkmark.circle.fill" : "arrow.right.circle.fill")
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .font(.headline)
                    }
                    .padding(.horizontal, 28)
                    .padding(.bottom, 24)
                }
            }
            .navigationTitle("Help & Tutorial")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}

private struct HelpStepCard: View {
    let icon: String
    let iconColor: Color
    let title: String
    let description: String
    let illustration: AnyView
    let showArrow: Bool
    var body: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .topTrailing) {
                RoundedRectangle(cornerRadius: 28)
                    .fill(LinearGradient(gradient: Gradient(colors: [Color.white, iconColor.opacity(0.05)]), startPoint: .top, endPoint: .bottom))
                    .shadow(color: iconColor.opacity(0.08), radius: 12, x: 0, y: 4)
                VStack(spacing: 18) {
                    ZStack {
                        Circle()
                            .fill(iconColor.opacity(0.15))
                            .frame(width: 60, height: 60)
                        Image(systemName: icon)
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(iconColor)
                    }
                    .padding(.top, 18)
                    Text(title)
                        .font(.title2.bold())
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                        .foregroundColor(.primary)
                    illustration
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                    Text(description)
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 18)
                        .padding(.bottom, 18)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(minHeight: 400)
        }
        .padding(.horizontal, 18)
        .padding(.top, 8)
    }
}

struct HelpTutorialView_Previews: PreviewProvider {
    static var previews: some View {
        HelpTutorialView()
    }
} 
