import SwiftUI

// MARK: - Onboarding Types

enum OnboardingContext {
    case mainTable
}

enum ActionType {
    case tap
}

enum Condition {
    case none
}

enum AnchorTarget: String, CaseIterable, Identifiable {
    case getStarted = "btn.getStarted"
    case managePeople = "btn.managePeople"
    case add = "btn.add"
    case shuffle = "btn.shuffle"
    case shapeSelector = "btn.shapeSelector"
    case tableManager = "btn.tableManager"
    case share = "btn.share"
    case settings = "btn.settings"
    case none = "btn.none"

    var id: String { rawValue }
}

struct OnboardingStep: Identifiable {
    let id: String
    let title: String
    let body: String
    let anchor: AnchorTarget
    let requiresAction: Bool
    let actionType: ActionType?
    let nextCondition: Condition
    var onEnter: (() -> Void)?

    init(
        id: String = UUID().uuidString,
        title: String,
        body: String,
        anchor: AnchorTarget,
        requiresAction: Bool,
        actionType: ActionType? = nil,
        nextCondition: Condition = .none,
        onEnter: (() -> Void)? = nil
    ) {
        self.id = id
        self.title = title
        self.body = body
        self.anchor = anchor
        self.requiresAction = requiresAction
        self.actionType = actionType
        self.nextCondition = nextCondition
        self.onEnter = onEnter
    }
}

// MARK: - Anchor Preference Key

struct OnboardingAnchorPreferenceKey: PreferenceKey {
    static var defaultValue: [String: Anchor<CGRect>] = [:]

    static func reduce(value: inout [String: Anchor<CGRect>], nextValue: () -> [String: Anchor<CGRect>]) {
        value.merge(nextValue(), uniquingKeysWith: { $1 })
    }
}

// MARK: - View Modifier to Register Anchors

struct OnboardingAnchorModifier: ViewModifier {
    let target: AnchorTarget

    func body(content: Content) -> some View {
        content
            .anchorPreference(key: OnboardingAnchorPreferenceKey.self, value: .bounds) { anchor in
                [target.rawValue: anchor]
            }
            .accessibilityIdentifier(target.rawValue)
    }
}

extension View {
    func onboardingAnchor(_ target: AnchorTarget) -> some View {
        modifier(OnboardingAnchorModifier(target: target))
    }
}


