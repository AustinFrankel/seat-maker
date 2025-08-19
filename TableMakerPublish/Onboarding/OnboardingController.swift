import SwiftUI
import Combine

final class OnboardingController: ObservableObject {
    static let shared = OnboardingController()

    // Persistent flag: completed or skipped
    @AppStorage("hasCompletedInteractiveOnboarding") private(set) var hasCompletedInteractiveOnboarding: Bool = false

    // Steps and progress
    @Published private(set) var steps: [OnboardingStep] = []
    @Published var currentStepIndex: Int = 0
    @Published var isActive: Bool = false

    // Resolved frames for anchors in screen space
    @Published private(set) var anchorFrames: [String: CGRect] = [:]

    // Internal coordination
    private var cancellables = Set<AnyCancellable>()
    private let haptics = UINotificationFeedbackGenerator()
    private var startObserver: AnyCancellable?
    private var isWaitingToStart: Bool = false

    // Actions that can be triggered by the overlay (e.g., "Try it")
    private var actionHandlers: [AnchorTarget: () -> Void] = [:]

    private init() {}

    // MARK: - Public API

    func startIfNeeded(context: OnboardingContext) {
        guard !hasCompletedInteractiveOnboarding else { return }

        switch context {
        case .mainTable:
            // Start only after Part 1 slide intro has finished (hasSeenTutorial == true)
            if UserDefaults.standard.bool(forKey: "hasSeenTutorial") {
                configureMainTableSteps()

                let canStartNow: Bool = {
                    // Only start when at least one of the main anchors is present (not on Create Seating screen)
                    let keys = [AnchorTarget.add.rawValue, AnchorTarget.shuffle.rawValue, AnchorTarget.shapeSelector.rawValue]
                    return keys.contains(where: { anchorFrames[$0] != nil })
                }()

                if canStartNow {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                        self.isActive = true
                        self.currentStepIndex = 0
                    }
                    haptics.prepare()
                } else if !isWaitingToStart {
                    // Wait until anchors appear, then start
                    isWaitingToStart = true
                    startObserver = $anchorFrames
                        .receive(on: DispatchQueue.main)
                        .sink { [weak self] _ in
                            guard let self = self else { return }
                            let keys = [AnchorTarget.add.rawValue, AnchorTarget.shuffle.rawValue, AnchorTarget.shapeSelector.rawValue]
                            if keys.contains(where: { self.anchorFrames[$0] != nil }) {
                                self.startObserver?.cancel()
                                self.startObserver = nil
                                self.isWaitingToStart = false
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                                    self.isActive = true
                                    self.currentStepIndex = 0
                                }
                                self.haptics.prepare()
                            }
                        }
                }
            }
        }
    }

    /// Registers an action closure that the onboarding overlay can invoke for a given anchor.
    /// Use this to enable the "Try it" button to perform the same behavior as tapping the UI control.
    func registerAction(for target: AnchorTarget, handler: @escaping () -> Void) {
        actionHandlers[target] = handler
    }

    /// Programmatically perform the action for the given target, if one was registered.
    func performAction(for target: AnchorTarget) {
        actionHandlers[target]?()
    }

    func advance() {
        guard isActive else { return }
        // Find the next step ahead whose anchor is visible. Prefer visible anchors over `.none`.
        if let nextVisible = nextVisibleStepIndex(after: currentStepIndex) {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                currentStepIndex = nextVisible
            }
            haptics.notificationOccurred(.success)
            steps[currentStepIndex].onEnter?()
            return
        }
        // If none are visible, only then allow moving to the terminal `.none` step if it exists ahead.
        if let finalNone = steps[(currentStepIndex+1)..<steps.count].firstIndex(where: { $0.anchor == .none }) {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                currentStepIndex = finalNone
            }
            haptics.notificationOccurred(.success)
            steps[currentStepIndex].onEnter?()
            return
        }
        finish()
    }

    func skip() {
        hasCompletedInteractiveOnboarding = true
        withAnimation(.easeInOut(duration: 0.25)) {
            isActive = false
        }
    }

    func reset() {
        hasCompletedInteractiveOnboarding = false
        steps = []
        currentStepIndex = 0
        isActive = false
        actionHandlers.removeAll()
    }

    func finish() {
        hasCompletedInteractiveOnboarding = true
        withAnimation(.easeInOut(duration: 0.25)) {
            isActive = false
        }
        haptics.notificationOccurred(.success)
        // Fire a lightweight, colorful confetti burst (no black circles)
        DispatchQueue.main.async {
            guard let window = UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene }).first?.windows.first(where: { $0.isKeyWindow }) else { return }
            let emitter = CAEmitterLayer()
            // Emit from the very top so confetti gently falls down across the screen
            emitter.emitterPosition = CGPoint(x: window.bounds.midX, y: 0)
            emitter.emitterShape = .line
            emitter.emitterSize = CGSize(width: window.bounds.width, height: 2)
            emitter.beginTime = CACurrentMediaTime()

            enum ConfettiShape { case rectangle, triangle, circle }
            func confettiImage(shape: ConfettiShape, color: UIColor) -> CGImage? {
                let size = CGSize(width: 10, height: 14)
                let renderer = UIGraphicsImageRenderer(size: size)
                let img = renderer.image { ctx in
                    color.setFill()
                    switch shape {
                    case .rectangle:
                        UIBezierPath(roundedRect: CGRect(x: 0, y: 0, width: size.width, height: size.height), cornerRadius: 2).fill()
                    case .triangle:
                        let path = UIBezierPath()
                        path.move(to: CGPoint(x: size.width/2, y: 0))
                        path.addLine(to: CGPoint(x: size.width, y: size.height))
                        path.addLine(to: CGPoint(x: 0, y: size.height))
                        path.close()
                        path.fill()
                    case .circle:
                        UIBezierPath(ovalIn: CGRect(x: 0, y: 0, width: size.width, height: size.width)).fill()
                    }
                }
                return img.cgImage
            }

            let colors: [UIColor] = [.systemBlue, .systemPink, .systemGreen, .systemOrange, .systemPurple, .systemYellow]
            let shapes: [ConfettiShape] = [.rectangle, .triangle, .circle]

            var cells: [CAEmitterCell] = []
            for color in colors {
                for shape in shapes {
                    let cell = CAEmitterCell()
                    // Gentle top-to-bottom fall, less clustered
                    cell.birthRate = 6
                    cell.lifetime = 6.0
                    cell.lifetimeRange = 1.5
                    cell.velocity = 90
                    cell.velocityRange = 35
                    cell.emissionLongitude = .pi / 2 // straight down
                    cell.emissionRange = .pi / 12
                    cell.yAcceleration = 160
                    cell.xAcceleration = 10
                    cell.spin = 2.0
                    cell.spinRange = 1.0
                    cell.scale = 0.6
                    cell.scaleRange = 0.25
                    cell.alphaRange = 0.05
                    cell.alphaSpeed = -0.1
                    cell.contents = confettiImage(shape: shape, color: color)
                    cells.append(cell)
                }
            }
            emitter.emitterCells = cells
            window.layer.addSublayer(emitter)

            // Let it run a bit longer for a natural fall, then stop and clean up
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
                emitter.birthRate = 0
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                    emitter.removeFromSuperlayer()
                }
            }
        }
    }

    // Called from the root view to provide latest anchor rectangles
    func updateResolvedAnchors(_ resolver: (String) -> CGRect?) {
        var map: [String: CGRect] = [:]
        for key in AnchorTarget.allCases.map({ $0.rawValue }) {
            if let rect = resolver(key), !rect.isNull, rect.isFinite {
                map[key] = rect
            }
        }
        // Avoid publishing changes synchronously during view updates; defer to next runloop
        let newMap = map
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.anchorFrames = newMap
            self.ensureVisibleStepIfNeeded()
        }
        return
    }

    // Convenience: If a certain external event happens while on a step, advance
    func advanceIfOn(anchor target: AnchorTarget) {
        guard isActive, currentStepIndex < steps.count else { return }
        if steps[currentStepIndex].anchor == target {
            advance()
        }
    }

    // MARK: - Steps Configuration

    private func configureMainTableSteps() {
        // New ordered flow per requirements
        steps = [
            // 1. Add button on the main screen
            OnboardingStep(
                title: NSLocalizedString("Add guests.", comment: "onboarding.title.add"),
                body: NSLocalizedString("Tap Add to add people.", comment: "onboarding.body.add"),
                anchor: .add,
                // Allow advancing without actually tapping Add, but keep Try it available
                requiresAction: false,
                actionType: .tap
            ),
            // 2. Shuffle button
            OnboardingStep(
                title: NSLocalizedString("Randomize seating.", comment: "onboarding.title.shuffle"),
                body: NSLocalizedString("Shuffle to arrange seating.", comment: "onboarding.body.shuffle"),
                anchor: .shuffle,
                requiresAction: false,
                actionType: nil
            ),
            // 3. Change shape
            OnboardingStep(
                title: NSLocalizedString("Change table shape.", comment: "onboarding.title.shape"),
                body: NSLocalizedString("Pick a shape.", comment: "onboarding.body.shape"),
                anchor: .shapeSelector,
                requiresAction: false,
                actionType: nil
            ),
            // 4. Manage tables (table manager icon) – tooltip positioned a bit lower by overlay logic
            OnboardingStep(
                title: NSLocalizedString("Create and edit tables.", comment: "onboarding.title.tableManager"),
                body: NSLocalizedString("Manage tables.", comment: "onboarding.body.tableManager"),
                anchor: .tableManager,
                requiresAction: false,
                actionType: nil
            ),
            // 5. Settings
            OnboardingStep(
                title: NSLocalizedString("Find help and preferences.", comment: "onboarding.title.settings"),
                body: NSLocalizedString("Open Settings.", comment: "onboarding.body.settings"),
                anchor: .settings,
                requiresAction: false,
                actionType: nil
            ),
            // 6. Share
            OnboardingStep(
                title: NSLocalizedString("Share or export your layout.", comment: "onboarding.title.share"),
                body: NSLocalizedString("Share your layout.", comment: "onboarding.body.share"),
                anchor: .share,
                requiresAction: false,
                actionType: nil
            ),
            // Finish card (no anchor)
            OnboardingStep(
                title: NSLocalizedString("You’re all set.", comment: "onboarding.title.done"),
                body: "",
                anchor: .none,
                requiresAction: false,
                actionType: nil,
                nextCondition: .none
            )
        ]
    }

    // Move to the first step whose anchor is currently visible
    private func ensureVisibleStepIfNeeded() {
        guard isActive, currentStepIndex < steps.count else { return }
        // If current has no anchor or it's missing, jump to the first visible step
        let current = steps[currentStepIndex]
        let hasAnchor = (current.anchor != .none) && anchorFrames[current.anchor.rawValue] != nil
        if hasAnchor { return }
        if let idx = steps.firstIndex(where: { step in
            // Only choose steps whose anchor is actually visible; ignore .none to avoid jumping to the last
            step.anchor != .none && anchorFrames[step.anchor.rawValue] != nil
        }) {
            withAnimation(.easeInOut(duration: 0.2)) {
                currentStepIndex = idx
            }
        }
    }

    // Find the next step index ahead of the given index with a visible anchor (excluding `.none`).
    private func nextVisibleStepIndex(after index: Int) -> Int? {
        guard index + 1 < steps.count else { return nil }
        return steps[(index+1)..<steps.count].firstIndex(where: { step in
            step.anchor != .none && anchorFrames[step.anchor.rawValue] != nil
        })
    }
}

private extension CGRect {
    var isFinite: Bool { origin.x.isFinite && origin.y.isFinite && size.width.isFinite && size.height.isFinite }
}


