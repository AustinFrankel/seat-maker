import SwiftUI
import UIKit

// MARK: - CoachMark Overlay

struct CoachMarkOverlayView: View {
    @ObservedObject var controller: OnboardingController
    @Environment(\.colorScheme) private var colorScheme

    // Spotlight pulse
    @State private var pulse: Bool = false

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                if controller.isActive {
                    overlayContents(proxy: proxy)
                        .transition(.opacity.combined(with: .scale))
                        .animation(.easeInOut(duration: 0.25), value: controller.currentStepIndex)
                        .onAppear { withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) { pulse.toggle() } }
                }
            }
            .allowsHitTesting(controller.isActive)
            // Anchor resolution is handled in the parent overlay to avoid double collection
        }
    }

    @ViewBuilder
    private func overlayContents(proxy: GeometryProxy) -> some View {
        let step = controller.steps[safe: controller.currentStepIndex]
        let anchorId = step?.anchor.rawValue ?? AnchorTarget.none.rawValue
        let rect = controller.anchorFrames[anchorId]
        // Compute spotlight rect in a local closure to avoid control-flow under ViewBuilder
        let spotlightRect: CGRect? = {
            // Unwrap the step first to avoid Optional<AnchorTarget>.none ambiguity
            guard let s = step else { return nil }
            // Skip spotlight when the step explicitly targets the sentinel `.none` anchor
            if s.anchor == .none { return nil }
            guard let r = rect else { return rect }
            // Move spotlight down 15pt for every step as requested, and a bit more for top bar icons.
            let base = r.offsetBy(dx: 0, dy: 28)
            switch s.anchor {
            case .shapeSelector:
                // 3/7: move up 5px and widen by 25px on both sides
                return base.insetBy(dx: -25, dy: 0).offsetBy(dx: 0, dy: -5)
            case .tableManager:
                // 4/7: move slightly less up so tooltip can sit lower; net +3px lower than before
                return base.offsetBy(dx: 0, dy: -4)
            case .settings:
                // 5/7: move up 7px
                return base.offsetBy(dx: 0, dy: -7)
            case .share:
                // 6/7: move up slightly less so tooltip sits lower; net +3px lower than before
                return base.offsetBy(dx: 0, dy: -3)
            default:
                return base
            }
        }()

        ZStack {
            // Let taps pass through even when spotlight is present so the user can press Next without being forced to tap the highlighted control
            PassthroughSpotlightRepresentable(spotlightRect: spotlightRect, isBlockingOutside: false)
                .background(
                    SpotlightMask(spotlightRect: spotlightRect, cornerRadius: 14, pulse: pulse)
                        .fill(
                            // Improve contrast in dark mode by using a lighter overlay, keep darker dim in light mode
                            colorScheme == .dark ? Color.white.opacity(0.25) : Color.black.opacity(0.55),
                            style: FillStyle(eoFill: true)
                        )
                        .ignoresSafeArea()
                )

            if let step = step {
                // For step 3 (shape selector), constrain the tooltip width to the control width + padding
                if step.anchor == .shapeSelector, let spot = spotlightRect {
                    // Make the change-shape window a bit narrower for a cleaner look
                    let desired = max(220, spot.width - 6)
                    tooltip(for: step, in: proxy, spotlight: spotlightRect)
                        .frame(width: min(desired, proxy.size.width - 60))
                } else {
                    tooltip(for: step, in: proxy, spotlight: spotlightRect)
                }
            }
            // Add a visible highlight fill and border inside the spotlight to be clearly visible in dark mode
            if let spot = spotlightRect {
                // Subtle inner fill only in dark mode so the hole is visible
                if colorScheme == .dark {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color.yellow.opacity(0.12))
                        .frame(width: spot.width, height: spot.height)
                        .position(x: spot.midX, y: spot.midY)
                        .allowsHitTesting(false)
                }
                // Accent border around the spotlight for all modes
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.accentColor.opacity(0.9), lineWidth: 2)
                    .frame(width: spot.width + 12, height: spot.height + 12)
                    .position(x: spot.midX, y: spot.midY)
                    .allowsHitTesting(false)
            }
        }
        .ignoresSafeArea()
    }

    @ViewBuilder
    private func tooltip(for step: OnboardingStep, in proxy: GeometryProxy, spotlight: CGRect?) -> some View {
        VStack(spacing: 10) {
            // Position tooltip near spotlight; if no spotlight, center
            Spacer(minLength: 0)
            if let spot = spotlight {
                TooltipCard(
                    stepIndex: controller.currentStepIndex,
                    totalSteps: controller.steps.count,
                    title: step.title,
                    message: step.body,
                    // Show Try it whenever the step has an action type, regardless of requiring it
                    showsTryIt: (step.actionType != nil),
                    onNext: { controller.advance() },
                    onSkip: { controller.skip() },
                    onTryIt: { controller.performAction(for: step.anchor) },
                    onBack: {
                        if controller.currentStepIndex > 0 {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                                controller.currentStepIndex -= 1
                            }
                        }
                    }
                )
                .frame(maxWidth: 320)
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .position(
                    x: {
                        // Keep the card within safe horizontal bounds
                        let minX: CGFloat = 170
                        let maxX: CGFloat = proxy.size.width - 170
                        return min(max(spot.midX, minX), maxX)
                    }(),
                    y: {
                        // Prefer below; if not enough room, place above the spotlight. Then apply +10pt global offset.
                        var below = spot.maxY + 92 + 10
                        // For the Create/Edit Tables step, nudge tooltip down by 3px
                        if step.anchor == .tableManager { below += 3 }
                        // For Share step 6/7, also nudge by 3px
                        if step.anchor == .share { below += 3 }
                        // If we're targeting the top bar icons (status bar overlap), push the card lower
                        if spot.minY < 80 { below += 24 }
                        let above = max(spot.minY - 120, 120)
                        return (below > proxy.size.height - 120) ? above : below
                    }()
                )
                .accessibilityElement(children: .contain)
                .accessibilityLabel(step.title)
            } else {
                Spacer()
                TooltipCard(
                    stepIndex: controller.currentStepIndex,
                    totalSteps: controller.steps.count,
                    title: step.title,
                    message: step.body,
                    showsTryIt: false,
                    primaryLabel: controller.currentStepIndex == controller.steps.count - 1 ? NSLocalizedString("Finish", comment: "onboarding.finish") : NSLocalizedString("Next", comment: "onboarding.next"),
                    onNext: { controller.advance() },
                    onSkip: { controller.skip() },
                    onTryIt: {},
                    onBack: {
                        if controller.currentStepIndex > 0 {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                                controller.currentStepIndex -= 1
                            }
                        }
                    }
                )
                .frame(maxWidth: 320)
                .padding(.horizontal, 16)
                .padding(.bottom, 32)
                Spacer()
            }
        }
        .transition(.opacity)
    }
}

// MARK: - Spotlight Mask Shape

struct SpotlightMask: Shape {
    let spotlightRect: CGRect?
    let cornerRadius: CGFloat
    let pulse: Bool

    func path(in rect: CGRect) -> Path {
        var p = Path(rect)
        if let spot = spotlightRect {
            let radius = cornerRadius + (pulse ? 1.5 : 0)
            let rounded = UIBezierPath(roundedRect: spot.insetBy(dx: -6, dy: -6), cornerRadius: radius)
            p.addPath(Path(rounded.cgPath))
        }
        return p
    }
}

// MARK: - Tooltip Card

struct TooltipCard: View {
    let stepIndex: Int
    let totalSteps: Int
    let title: String
    let message: String
    var showsTryIt: Bool = false
    var primaryLabel: String = NSLocalizedString("Next", comment: "onboarding.next")
    var onNext: () -> Void
    var onSkip: () -> Void
    var onTryIt: () -> Void
    var onBack: () -> Void = {}

    var bodyView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                // Progress indicator
                Text("\(min(stepIndex + 1, totalSteps))/\(totalSteps)")
                    .font(.footnote.weight(.semibold))
                    .foregroundColor(.secondary)
                Spacer()
                Button(action: {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    onSkip()
                }) {
                    Text(NSLocalizedString("Skip", comment: "onboarding.skip"))
                        .font(.footnote.weight(.semibold))
                }
                .accessibilityLabel("Skip")
            }
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
            if !message.isEmpty {
                Text(message)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            HStack(spacing: 12) {
                // Back button on the left
                if stepIndex > 0 {
                    Button(action: {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        onBack()
                    }) {
                        Text(NSLocalizedString("Back", comment: "onboarding.back"))
                            .font(.callout.weight(.semibold))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(Capsule().fill(Color(.systemBackground)))
                            .overlay(Capsule().stroke(Color.blue.opacity(0.3)))
                    }
                    .accessibilityLabel("Back")
                }
                Button(action: {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    onNext()
                }) {
                    Text(primaryLabel)
                        .font(.callout.weight(.semibold))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Capsule().fill(Color.blue))
                        .foregroundColor(.white)
                }
                .accessibilityLabel(primaryLabel)
                if showsTryIt {
                    Button(action: {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        onTryIt()
                    }) {
                        Text(NSLocalizedString("Try it", comment: "onboarding.tryIt"))
                            .font(.callout.weight(.semibold))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Capsule().fill(Color(.systemBackground)))
                            .overlay(Capsule().stroke(Color.blue.opacity(0.3)))
                    }
                    .accessibilityLabel("Try it")
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.15), radius: 12, x: 0, y: 6)
        )
        .dynamicTypeSize(.xSmall ... .accessibility3)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(title)
    }

    var body: some View { bodyView }
}

// MARK: - Passthrough spotlight (UIKit-based hit testing)

final class PassthroughSpotlightView: UIView {
    var spotlightRect: CGRect? { didSet { setNeedsLayout() } }
    var isBlockingOutside: Bool = false

    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        guard isBlockingOutside else { return false }
        if let spot = spotlightRect { return !spot.contains(point) }
        return true
    }
}

struct PassthroughSpotlightRepresentable: UIViewRepresentable {
    var spotlightRect: CGRect?
    var isBlockingOutside: Bool

    func makeUIView(context: Context) -> PassthroughSpotlightView {
        let v = PassthroughSpotlightView(frame: .zero)
        v.isUserInteractionEnabled = true
        v.backgroundColor = .clear
        return v
    }

    func updateUIView(_ uiView: PassthroughSpotlightView, context: Context) {
        uiView.spotlightRect = spotlightRect
        uiView.isBlockingOutside = isBlockingOutside
    }
}

// MARK: - Safe subscript

private extension Array {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}


