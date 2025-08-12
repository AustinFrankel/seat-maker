import SwiftUI
import Photos
import PhotosUI
import UIKit

struct TutorialView: View {
    @Environment(\.presentationMode) var presentationMode
    @AppStorage("hasSeenTutorial") private var hasSeenTutorial = false
    @State private var currentPage = 0
    @State private var iconBounce = false
    @State private var tutorialOpacity: Double = 1.0
    @State private var slideOffset: CGFloat = 0
    @State private var fadeInOpacity: Double = 0
    var onComplete: (() -> Void)? = nil
    
    private struct TutorialPage: Identifiable {
        let id = UUID()
        let icon: String
        let title: String
        let subtitle: String
        var color: Color
    }
    
    private let pages: [TutorialPage] = [
        TutorialPage(
            icon: "table",
            title: "Welcome to Seat Maker",
            subtitle: "Create seating for events",
            color: .blue
        ),
        TutorialPage(
            icon: "paintbrush.fill",
            title: "Personalize Every Seat",
            subtitle: "Tap seats to assign names, lock individuals, shuffle guests, and more.",
            color: .purple
        ),
        TutorialPage(
            icon: "person.2.fill",
            title: "Add Guests Instantly",
            subtitle: "Add guests by typing names or importing from contacts.",
            color: .green
        ),
        TutorialPage(
            icon: "square.and.arrow.up.on.square.fill",
            title: "Save & Share Effortlessly",
            subtitle: "Save your arrangements and share them via messages or QR codes.",
            color: .orange
        )
    ]
    
    var body: some View {
        ZStack(alignment: .top) {
            Color.white.ignoresSafeArea()
            VStack(spacing: 0) {
                Spacer(minLength: 0)
                ZStack {
                    ForEach(Array(pages.enumerated()), id: \.offset) { idxAndPage in
                        let idx = idxAndPage.offset
                        let page = idxAndPage.element
                        if idx == currentPage {
                            GeometryReader { geo in
                                VStack(spacing: 0) {
                                    Spacer(minLength: geo.size.height * 0.18 + 15)
                                    VStack(spacing: 0) {
                                        if idx == 0, let tableImage = UIImage(named: "tableMakerImage") {
                                            Image(uiImage: tableImage)
                                                .resizable()
                                                .frame(width: 120, height: 120)
                                                .clipShape(Circle())
                                                .shadow(radius: 8)
                                                .padding(.bottom, 24)
                                                .scaleEffect(iconBounce ? 1.08 : 1.0)
                                                .animation(.interpolatingSpring(stiffness: 180, damping: 8).repeatForever(autoreverses: true), value: iconBounce)
                                                .onAppear {
                                                    withAnimation(.easeOut(duration: 0.13)) {
                                                        fadeInOpacity = 1
                                                    }
                                                    iconBounce = true
                                                }
                                        } else {
                                            Image(systemName: page.icon)
                                                .resizable()
                                                .scaledToFit()
                                                .frame(width: 100, height: 100)
                                                .foregroundColor(page.color)
                                                .padding(.bottom, 24)
                                                .scaleEffect(iconBounce ? 1.08 : 1.0)
                                                .shadow(color: page.color.opacity(0.3), radius: 10, x: 0, y: 4)
                                                .animation(.interpolatingSpring(stiffness: 180, damping: 8).repeatForever(autoreverses: true), value: iconBounce)
                                                .onAppear {
                                                    withAnimation(.easeOut(duration: 0.13)) {
                                                        fadeInOpacity = 1
                                                    }
                                                    iconBounce = true
                                                }
                                        }
                                        Text(page.title)
                                            .font(.system(size: 26, weight: .bold))
                                            .multilineTextAlignment(.center)
                                            .foregroundColor(.black)
                                            .padding(.bottom, 10)
                                            .transition(.opacity)
                                        Text(page.subtitle)
                                            .font(.system(size: 17, weight: .regular))
                                            .foregroundColor(.gray)
                                            .multilineTextAlignment(.center)
                                            .padding(.horizontal, 24)
                                            .transition(.opacity)
                                    }
                                    .frame(width: min(geo.size.width * 0.8, 340))
                                    .offset(x: slideOffset)
                                    .opacity(fadeInOpacity)
                                    .gesture(
                                        DragGesture()
                                            .onEnded { value in
                                                if value.translation.width < -40 && currentPage < pages.count - 1 {
                                                    // Swipe left
                                                    withAnimation(.spring(response: 0.18, dampingFraction: 0.7)) {
                                                        slideOffset = -geo.size.width
                                                        fadeInOpacity = 0
                                                    }
                                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
                                                        currentPage += 1
                                                        slideOffset = geo.size.width
                                                        withAnimation(.spring(response: 0.18, dampingFraction: 0.7)) {
                                                            slideOffset = 0
                                                            fadeInOpacity = 1
                                                        }
                                                    }
                                                } else if value.translation.width > 40 && currentPage > 0 {
                                                    // Swipe right
                                                    withAnimation(.spring(response: 0.18, dampingFraction: 0.7)) {
                                                        slideOffset = geo.size.width
                                                        fadeInOpacity = 0
                                                    }
                                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
                                                        currentPage -= 1
                                                        slideOffset = -geo.size.width
                                                        withAnimation(.spring(response: 0.18, dampingFraction: 0.7)) {
                                                            slideOffset = 0
                                                            fadeInOpacity = 1
                                                        }
                                                    }
                                                }
                                            }
                                    )
                                    Spacer()
                                    
                                    // Navigation Buttons with enhanced animations
                                    HStack(spacing: 18) {
                                        if idx > 0 {
                                            Button(action: {
                                                withAnimation(.spring(response: 0.18, dampingFraction: 0.7)) {
                                                    slideOffset = geo.size.width
                                                    fadeInOpacity = 0
                                                }
                                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
                                                    currentPage -= 1
                                                    slideOffset = -geo.size.width
                                                    withAnimation(.spring(response: 0.18, dampingFraction: 0.7)) {
                                                        slideOffset = 0
                                                        fadeInOpacity = 1
                                                    }
                                                }
                                            }) {
                                                Text("Previous")
                                                    .font(.system(size: 18, weight: .bold))
                                                    .foregroundColor(.blue)
                                                    .padding(.horizontal, 36)
                                                    .padding(.vertical, 16)
                                                    .background(Color.blue.opacity(0.1))
                                                    .clipShape(Capsule())
                                                    .scaleEffect(iconBounce ? 1.04 : 1.0)
                                                    .animation(.easeInOut(duration: 0.12), value: iconBounce)
                                            }
                                            .transition(.asymmetric(insertion: .move(edge: .leading), removal: .move(edge: .trailing)))
                                        }
                                        
                                        if idx == pages.count - 1 {
                                            Button(action: {
                                                // Call onComplete immediately to allow underlying view to update state (e.g., showEffortlessScreen)
                                                if let onComplete = onComplete {
                                                    onComplete()
                                                }
                                                // Then persist the flag and fade out
                                                hasSeenTutorial = true
                                                withAnimation(.easeInOut(duration: 0.13)) {
                                                    tutorialOpacity = 0
                                                }
                                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.13) {
                                                    if onComplete == nil {
                                                        presentationMode.wrappedValue.dismiss()
                                                    }
                                                }
                                            }) {
                                                Text("Get Started")
                                                    .font(.system(size: 18, weight: .bold))
                                                    .foregroundColor(.white)
                                                    .padding(.horizontal, 28)
                                                    .padding(.vertical, 16)
                                                    .background(
                                                        Capsule()
                                                            .fill(LinearGradient(colors: [.blue, .purple], startPoint: .leading, endPoint: .trailing))
                                                            .shadow(color: Color.blue.opacity(0.3), radius: 8, x: 0, y: 4)
                                                    )
                                                    .scaleEffect(iconBounce ? 1.04 : 1.0)
                                                    .animation(.easeInOut(duration: 0.12), value: iconBounce)
                                            }
                                            .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
                                        } else {
                                            Button(action: {
                                                withAnimation(.spring(response: 0.18, dampingFraction: 0.7)) {
                                                    slideOffset = -geo.size.width
                                                    fadeInOpacity = 0
                                                }
                                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
                                                    currentPage += 1
                                                    slideOffset = geo.size.width
                                                    withAnimation(.spring(response: 0.18, dampingFraction: 0.7)) {
                                                        slideOffset = 0
                                                        fadeInOpacity = 1
                                                    }
                                                }
                                            }) {
                                                Text("Next")
                                                    .font(.system(size: 16, weight: .bold))
                                                    .foregroundColor(.white)
                                                    .padding(.horizontal, 36)
                                                    .padding(.vertical, 16)
                                                    .background(
                                                        Capsule()
                                                            .fill(LinearGradient(colors: [.blue, .purple], startPoint: .leading, endPoint: .trailing))
                                                            .shadow(color: Color.blue.opacity(0.3), radius: 8, x: 0, y: 4)
                                                    )
                                                    .scaleEffect(iconBounce ? 1.04 : 1.0)
                                                    .animation(.easeInOut(duration: 0.12), value: iconBounce)
                                            }
                                            .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
                                        }
                                    }
                                    .padding(.bottom, 60)
                                    .opacity(fadeInOpacity)
                                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: currentPage)
                                }
                                .frame(width: geo.size.width, height: geo.size.height)
                                .onAppear {
                                    withAnimation(.easeOut(duration: 0.13)) {
                                        fadeInOpacity = 1
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        
        // Skip button with enhanced styling
        HStack {
            Spacer()
            Button("Skip") {
                // Call onComplete immediately to allow underlying view to update state
                if let onComplete = onComplete {
                    onComplete()
                }
                // Then persist the flag and fade out
                hasSeenTutorial = true
                withAnimation(.easeInOut(duration: 0.13)) {
                    tutorialOpacity = 0
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.13) {
                    if onComplete == nil {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
            .foregroundColor(.blue)
            .font(.system(size: 18, weight: .medium))
            .padding(.horizontal, 20)
            .padding(.vertical, 8)
            .background(Color.blue.opacity(0.1))
            .clipShape(Capsule())
            .padding(.trailing, 24)
            .padding(.top, 60)
        }
    }
        .opacity(tutorialOpacity)
    .onAppear {
        slideOffset = 50
        fadeInOpacity = 0
        withAnimation(.spring(response: 0.18, dampingFraction: 0.7)) {
            slideOffset = 0
            fadeInOpacity = 1
            }
        }
    }
}

struct TutorialStep: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let icon: String // Can be SF Symbol or custom identifier
    let position: TooltipPosition
}

enum TooltipPosition {
    case top, center, bottom
}

struct TutorialStepView: View {
    let step: TutorialStep
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 30) {
            if step.icon == "tableMakerImage" {
                Image("tableMakerImage")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 120, height: 120)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(Color.blue.opacity(0.25), lineWidth: 6)
                    )
                    .shadow(color: Color(.sRGBLinear, white: 0, opacity: 0.08), radius: 12, x: 0, y: 6)
                    .scaleEffect(isAnimating ? 1.08 : 1.0)
                    .animation(
                        Animation.easeInOut(duration: 1.0)
                            .repeatForever(autoreverses: true),
                        value: isAnimating
                    )
            } else {
                Image(systemName: step.icon)
                    .font(.system(size: 80))
                    .foregroundColor(.blue)
                    .scaleEffect(isAnimating ? 1.1 : 1.0)
                    .animation(
                        Animation.easeInOut(duration: 1.0)
                            .repeatForever(autoreverses: true),
                        value: isAnimating
                    )
            }
            VStack(spacing: 12) {
                Text(step.title)
                    .font(.title)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.black)
                Text(step.description)
                    .font(.body)
                    .foregroundColor(.black)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
        }
        .padding()
        .onAppear {
            isAnimating = true
        }
    }
}

struct TooltipView: View {
    let text: String
    let position: TooltipPosition
    @Binding var opacity: Double
    @Binding var offset: CGFloat
    
    var body: some View {
        Text(text)
            .font(.subheadline)
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color.blue)
            .cornerRadius(8)
            .opacity(opacity)
            .offset(y: offset)
    }
}
