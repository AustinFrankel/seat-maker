//
//  LaunchIntegration.swift
//  TableMakerPublish
//
//  Integrates the launch animation overlay with matched geometry handoff.
//

import SwiftUI

public struct LaunchOverlayContainer<Content: View>: View {
    @State private var showLaunch: Bool = true
    @Namespace private var heroNamespace
    private var content: () -> Content

    public init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }

    public var body: some View {
        ZStack {
            content()
                .overlay(alignment: .center) {
                    if showLaunch {
                        BrandColors.seatSurface.ignoresSafeArea()
                    }
                }

            if showLaunch {
                LaunchAnimationView(variant: .tableBloom) {
                    withAnimation(.easeInOut(duration: 0.20)) { showLaunch = false }
                }
                .transition(.opacity)
            }
        }
        .environment(\.heroTableNamespace, heroNamespace)
    }
}

// Shared namespace key for matched geometry between launch and home
private struct HeroTableNamespaceKey: EnvironmentKey { static let defaultValue: Namespace.ID? = nil }
public extension EnvironmentValues {
    var heroTableNamespace: Namespace.ID? {
        get { self[HeroTableNamespaceKey.self] }
        set { self[HeroTableNamespaceKey.self] = newValue }
    }
}

public struct HeroMatchedGeometry: ViewModifier {
    public var namespace: Namespace.ID?
    public func body(content: Content) -> some View {
        if let ns = namespace {
            content.matchedGeometryEffect(id: "heroTable", in: ns)
        } else {
            content
        }
    }
}

public extension View {
    func heroMatched(ns: Namespace.ID?) -> some View { self.modifier(HeroMatchedGeometry(namespace: ns)) }
}


