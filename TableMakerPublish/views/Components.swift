import SwiftUI

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 20) {
            // Use a gradient background
            LinearGradient(gradient: Gradient(colors: [Color.blue.opacity(0.2), Color.purple.opacity(0.15)]), startPoint: .top, endPoint: .bottom)
                .frame(maxHeight: .infinity)
                .ignoresSafeArea()
                .padding(.bottom, -25) // Extend 25pt lower
            
            VStack(spacing: 20) {
                Spacer()
                // App icon or illustration
                Image(systemName: "person.3.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 120)
                    .foregroundColor(.blue)
                    .shadow(color: Color.blue.opacity(0.08), radius: 4, x: 0, y: 2)
                
                // Title and subtitle
                Text("Creating seating for events")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.blue)
                    .shadow(color: Color.blue.opacity(0.08), radius: 4, x: 0, y: 2)
                Text("Add people to get started")
                    .font(.title3)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                Spacer()
            }
        }
    }
}

// Removed duplicate HistoryView - using the one from HistoryView.swift

struct SettingsView: View {
    @ObservedObject var viewModel: SeatingViewModel
    @Binding var isPresented: Bool
    
    var body: some View {
        // Implementation will be added
        Text("Settings View")
    }
}

struct QRCodeShareView: View {
    @ObservedObject var viewModel: SeatingViewModel
    @Binding var isPresented: Bool
    
    var body: some View {
        // Implementation will be added
        Text("QR Code Share View")
    }
}

struct TermsView: View {
    @Binding var isPresented: Bool
    
    var body: some View {
        // Implementation will be added
        Text("Terms View")
    }
}

// Simple flow layout to wrap chips without breaking words
struct FlowLayout<Content: View>: View {
    let spacing: CGFloat
    let alignment: HorizontalAlignment
    let content: Content

    init(spacing: CGFloat = 8, alignment: HorizontalAlignment = .leading, @ViewBuilder content: () -> Content) {
        self.spacing = spacing
        self.alignment = alignment
        self.content = content()
    }

    var body: some View {
        GeometryReader { geo in
            self.generateContent(in: geo.size.width)
        }
        .frame(maxWidth: .infinity, alignment: Alignment(horizontal: alignment, vertical: .center))
    }

    private func generateContent(in availableWidth: CGFloat) -> some View {
        return ZStack(alignment: Alignment(horizontal: alignment, vertical: .top)) {
            _FlowLayout(spacing: spacing, availableWidth: availableWidth) { content }
        }
    }
}

private struct _FlowLayout<Content: View>: View {
    let spacing: CGFloat
    let availableWidth: CGFloat
    let content: Content

    init(spacing: CGFloat, availableWidth: CGFloat, @ViewBuilder content: () -> Content) {
        self.spacing = spacing
        self.availableWidth = availableWidth
        self.content = content()
    }

    var body: some View {
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        return ZStack(alignment: .topLeading) {
            content
                .background(WidthPreferenceSetter())
                .alignmentGuide(.leading) { d in
                    if (abs(currentX - d.width) > availableWidth) {
                        currentX = 0
                        currentY -= d.height + spacing
                    }
                    let result = currentX
                    if content is EmptyView == false { currentX -= d.width + spacing }
                    return result
                }
                .alignmentGuide(.top) { _ in currentY }
        }
    }
}

private struct WidthPreferenceSetter: View {
    var body: some View { Color.clear }
}

// Helper functions
func getPersonColor(index: Int) -> Color {
    let colors: [Color] = [.blue, .red, .green, .orange, .purple, .pink, .yellow, .mint, .teal]
    return colors[index % colors.count]
}

func triggerHaptic() {
    let generator = UIImpactFeedbackGenerator(style: .medium)
    generator.impactOccurred()
} 