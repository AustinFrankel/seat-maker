import SwiftUI

struct EffortlessScreen: View {
    var onContinue: () -> Void
    @State private var showPopup = false
    @State private var isAnimating = false
    @State private var pulseScale: CGFloat = 1.0
    
    var body: some View {
        ZStack {
            // Enhanced background gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.blue.opacity(0.15),
                    Color.purple.opacity(0.1),
                    Color.blue.opacity(0.05)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Animated background circles
            ForEach(0..<3) { index in
                Circle()
                    .fill(Color.blue.opacity(0.1))
                    .frame(width: 200 + CGFloat(index * 50))
                    .offset(x: CGFloat(index * 30), y: CGFloat(index * -20))
                    .scaleEffect(isAnimating ? 1.2 : 0.8)
                    .animation(
                        .easeInOut(duration: 3)
                        .repeatForever(autoreverses: true)
                        .delay(Double(index) * 0.5),
                        value: isAnimating
                    )
            }
            
            VStack(spacing: 40) {
                Spacer()
                
                // Enhanced icon with animations
                ZStack {
                    // Outer glow
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color.blue.opacity(0.3), Color.clear],
                                center: .center,
                                startRadius: 0,
                                endRadius: 100
                            )
                        )
                        .frame(width: 200, height: 200)
                        .scaleEffect(pulseScale)
                    
                    // Main circle
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.blue.opacity(0.2), Color.purple.opacity(0.15)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 160, height: 160)
                        .overlay(
                            Circle()
                                .stroke(
                                    LinearGradient(
                                        colors: [Color.blue, Color.purple],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 3
                                )
                        )
                        .shadow(color: Color.blue.opacity(0.3), radius: 20, x: 0, y: 10)
                    
                    // Icon with rotation
                    Image(systemName: "person.3.fill")
                        .font(.system(size: 70, weight: .light))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.blue, Color.purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .rotationEffect(.degrees(isAnimating ? 5 : -5))
                        .animation(
                            .easeInOut(duration: 2)
                            .repeatForever(autoreverses: true),
                            value: isAnimating
                        )
                }
                
                VStack(spacing: 16) {
                    Text("Effortless Table Planning")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.blue, Color.purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .multilineTextAlignment(.center)
                    
                    Text("Add people, pick a table shape, and shuffle to create the perfect seating arrangement in seconds.")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                        .lineSpacing(4)
                }
                
                Spacer()
                
                // Enhanced button
                Button(action: {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                        showPopup = true
                        onContinue()
                    }
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 18, weight: .semibold))
                        Text("Start Planning")
                            .font(.system(size: 20, weight: .semibold, design: .rounded))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 40)
                    .padding(.vertical, 18)
                    .background(
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [Color.blue, Color.purple],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .shadow(color: Color.blue.opacity(0.4), radius: 15, x: 0, y: 8)
                    )
                    .scaleEffect(isAnimating ? 1.05 : 1.0)
                    .animation(
                        .easeInOut(duration: 2)
                        .repeatForever(autoreverses: true),
                        value: isAnimating
                    )
                }
                .buttonStyle(PlainButtonStyle())
                
                Spacer().frame(height: 50)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1)) {
                isAnimating = true
            }
            
            // Start pulse animation
            withAnimation(
                .easeInOut(duration: 2)
                .repeatForever(autoreverses: true)
            ) {
                pulseScale = 1.1
            }
        }
        .sheet(isPresented: $showPopup) {
            // Show your pop-up here (e.g., AddPeopleView or TableShapePicker)
        }
    }
}

struct EffortlessScreen_Previews: PreviewProvider {
    static var previews: some View {
        EffortlessScreen(onContinue: {})
    }
}
