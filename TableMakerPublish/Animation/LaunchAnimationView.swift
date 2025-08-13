//
//  LaunchAnimationView.swift
//  TableMakerPublish
//
//  Premium opening animation for Seat Maker. Reduce Motion supported.
//

import SwiftUI
import UIKit

public struct LaunchAnimationView: View {
    public enum Variant { case minimalSweep, tableBloom }

    public var onFinished: () -> Void
    public var variant: Variant

    @StateObject private var controller = LaunchAnimationController()
    @Environment(\.colorScheme) private var colorScheme
    @State private var gridScale: CGFloat = 1.02
    @State private var gridOpacity: CGFloat = 0.0
    @State private var tableTrim: CGFloat = 0.0
    // Dynamic elements for the richer variant
    @State private var seatsVisibleCount: Int = 0
    @State private var backgroundBlur: CGFloat = 8.0
    @State private var seatPulse: CGFloat = 1.0
    @State private var radarRotation: Double = 0.0
    @State private var tiltAmount: Double = 8.0
    // Logo
    @State private var logoVisible: Bool = false
    @State private var logoScale: CGFloat = 0.96
    // Pulse ring behind logo
    @State private var ringScale: CGFloat = 0.70
    @State private var ringOpacity: CGFloat = 0.0
    @Environment(\.heroTableNamespace) private var heroNamespace

    // Accessibility
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init(variant: Variant = .minimalSweep, onFinished: @escaping () -> Void) {
        self.variant = variant
        self.onFinished = onFinished
    }

    public var body: some View {
        ZStack {
            BrandColors.seatSurface
                .ignoresSafeArea()

            blueprintBackground

            GeometryReader { proxy in
                let size = proxy.size
                let minSide = min(size.width, size.height)
                let tableRadius = minSide * 0.18
                let center = CGPoint(x: size.width / 2.0, y: size.height / 2.0)

                ZStack {
                    // Invisible matched-geometry anchor only (no visible circle)
                    Circle()
                        .trim(from: 0, to: tableTrim)
                        .stroke(Color.clear, style: StrokeStyle(lineWidth: 6, lineCap: .butt))
                        .frame(width: tableRadius * 2, height: tableRadius * 2)
                        .modifier(ConditionalMatchedGeometry(namespace: heroNamespace))
                        .opacity(0)
                        .allowsHitTesting(false)

                    // Visible table stroke (start at top)
                    Circle()
                        .trim(from: 0, to: tableTrim)
                        .stroke(BrandColors.seatBlue.opacity(0.90), style: StrokeStyle(lineWidth: 6, lineCap: .round))
                        .frame(width: tableRadius * 2, height: tableRadius * 2)
                        .rotationEffect(.degrees(-90))
                        .shadow(color: .black.opacity(0.12), radius: 10, x: 0, y: 6)
                        .opacity(tableTrim > 0 ? 1.0 : 0.0)
                        .overlay(
                            Circle()
                                .trim(from: 0, to: tableTrim)
                                .stroke(BrandColors.seatAccent.opacity(0.35), style: StrokeStyle(lineWidth: 2, lineCap: .round))
                                .frame(width: tableRadius * 2, height: tableRadius * 2)
                                .rotationEffect(.degrees(-90))
                                .blur(radius: 3)
                                .opacity(tableTrim > 0 ? 1.0 : 0.0)
                        )

                    if variant == .tableBloom {
                        // Seats layer
                        seatsLayer(center: center, radius: tableRadius * 1.52)
                        // High-tech radar sweep overlay
                        radarOverlay(radius: tableRadius * 1.82)
                    }

                    // Logo only (no wordmark), sized to fit within the circle
                    logoLayer(tableRadius: tableRadius)
                        .accessibilityLabel(Text("App logo"))
                        .accessibilityAddTraits(.isHeader)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .onChange(of: controller.isCompleted) { newValue in
            if newValue { onFinished() }
        }
        .onChange(of: controller.phase) { newPhase in
            handlePhaseChange(newPhase)
        }
        .onAppear { start() }
        .transaction { transaction in
            transaction.animation = nil
        }
        .rotation3DEffect(.degrees(tiltAmount), axis: (x: 1, y: 0.12, z: 0))
        .animation(.easeOut(duration: 2.2), value: tiltAmount)
    }

    private var blueprintBackground: some View {
        BlueprintGrid(spacing: 22, lineWidth: 0.5, opacity: 0.05, animatedScale: gridScale)
            .opacity(gridOpacity)
            .animation(.easeInOut(duration: 0.35), value: gridOpacity)
            .animation(.easeInOut(duration: 0.35), value: gridScale)
            .blur(radius: backgroundBlur)
            .animation(.easeOut(duration: 0.60), value: backgroundBlur)
            .blendMode(.normal)
            .overlay(sweepOverlay.mask(Rectangle()))
            .overlay(vignetteOverlay)
    }

    private var sweepOverlay: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            LinearGradient(colors: [
                BrandColors.seatAccent.opacity(0.0),
                BrandColors.seatAccent.opacity(0.16),
                BrandColors.seatAccent.opacity(0.0)
            ], startPoint: .leading, endPoint: .trailing)
                .frame(width: width * 0.50)
                .offset(x: controller.phase == .sweep ? width * 0.80 : -width * 0.50)
                .animation(.easeInOut(duration: 0.80), value: controller.phase)
        }
        .allowsHitTesting(false)
    }

    private var vignetteOverlay: some View {
        RadialGradient(colors: [Color.black.opacity(0.0), Color.black.opacity(0.10)], center: .center, startRadius: 0, endRadius: 600)
            .blendMode(.multiply)
            .allowsHitTesting(false)
    }

    private func seatsLayer(center: CGPoint, radius: CGFloat) -> some View {
        let seatCount = 10
        return ZStack {
            ForEach(0..<seatCount, id: \.self) { index in
                let point = PolarPosition.pointsEvenlySpaced(count: seatCount, center: center, radius: radius)[index]
                SeatDot(isVisible: index < seatsVisibleCount, pulse: seatPulse)
                    .scaleEffect(index < seatsVisibleCount ? seatPulse : 0.6)
                    .position(x: point.x, y: point.y)
            }
        }
    }

    private func radarOverlay(radius: CGFloat) -> some View {
        Circle()
            .trim(from: 0.00, to: 0.08)
            .stroke(
                AngularGradient(
                    gradient: Gradient(colors: [
                        BrandColors.seatAccent.opacity(0.0),
                        BrandColors.seatAccent.opacity(0.45),
                        BrandColors.seatAccent.opacity(0.0)
                    ]),
                    center: .center
                ),
                style: StrokeStyle(lineWidth: 12, lineCap: .round)
            )
            .frame(width: radius * 2, height: radius * 2)
            .rotationEffect(.degrees(-90 + radarRotation))
            .opacity((controller.phase == .cards || controller.phase == .logo) ? 1.0 : 0.0)
    }

    private func logoLayer(tableRadius: CGFloat) -> some View {
        ZStack {
            Circle()
                .stroke(BrandColors.seatAccent.opacity(0.4), lineWidth: 3)
                .frame(width: tableRadius * 2 * 0.92, height: tableRadius * 2 * 0.92)
                .scaleEffect(ringScale)
                .opacity(ringOpacity)
            Image("tableMakerImage")
                .resizable()
                .scaledToFit()
                .frame(width: tableRadius * 1.15, height: tableRadius * 1.15)
                .shadow(color: .black.opacity(logoVisible ? 0.18 : 0.0), radius: 12, x: 0, y: 6)
        }
        .opacity(logoVisible ? 1.0 : 0.0)
        .scaleEffect(logoScale)
        .animation(.spring(response: 0.55, dampingFraction: 0.75), value: logoVisible)
        .animation(.spring(response: 0.55, dampingFraction: 0.75), value: logoScale)
        .onChange(of: controller.phase) { newPhase in
            if newPhase == .logo {
                withAnimation(.spring(response: 0.55, dampingFraction: 0.75)) {
                    logoVisible = true
                    logoScale = 1.0
                }
                // Pulse ring
                ringScale = 0.70
                ringOpacity = 0.35
                withAnimation(.easeOut(duration: 0.70)) {
                    ringScale = 1.15
                    ringOpacity = 0.0
                }
            }
        }
        .accessibilityElement(children: .combine)
    }

    private func start() {
        if reduceMotion {
            withAnimation(.easeInOut(duration: 0.30)) {
                gridOpacity = 1.0
                gridScale = 1.0
                tableTrim = 1.0
                logoVisible = true
                logoScale = 1.0
            }
            controller.startSequence(respectReduceMotion: true)
            return
        }

        controller.startSequence(respectReduceMotion: false)

        // Grid
        withAnimation(.easeInOut(duration: 0.60)) {
            gridOpacity = 1.0
            gridScale = 1.0
            backgroundBlur = 6.0
        }
        // Subtle tilt that eases out
        tiltAmount = 8.0
        withAnimation(.easeOut(duration: 2.2)) { tiltAmount = 0.0 }

        // Table draw starts later for drama
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.20) {
            withAnimation(.easeInOut(duration: 0.70)) {
                tableTrim = 1.0
            }
        }

        // Safety cap aligned with extended controller total ≈ 3.4–3.6s
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.60) {
            if controller.phase != .done {
                controller.startSequence(respectReduceMotion: true)
            }
        }
    }

    private func handlePhaseChange(_ newPhase: LaunchAnimationController.Phase) {
        switch newPhase {
        case .grid:
            backgroundBlur = 8.0
        case .sweep:
            withAnimation(.easeOut(duration: 0.60)) { backgroundBlur = 5.0 }
            // Gentle grid breathing
            withAnimation(.easeInOut(duration: 2.4).repeatForever(autoreverses: true)) {
                gridScale = 1.01
            }
        case .table:
            withAnimation(.easeOut(duration: 0.70)) { backgroundBlur = 3.0 }
        case .seats:
            withAnimation(.easeOut(duration: 0.60)) { backgroundBlur = 2.0 }
            seatsVisibleCount = 0
            let seatCount = 10
            for i in 0..<seatCount {
                let delay = 0.06 * Double(i)
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                    withAnimation(.spring(response: 0.40, dampingFraction: 0.75)) {
                        seatsVisibleCount = i + 1
                    }
                }
            }
            // Seat pulse glow
            seatPulse = 0.96
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                seatPulse = 1.05
            }
        case .cards:
            // Repurpose as radar sweep phase
            withAnimation(.easeOut(duration: 0.60)) { backgroundBlur = 1.0 }
            radarRotation = 0.0
            withAnimation(.linear(duration: 1.4).repeatForever(autoreverses: false)) {
                radarRotation = 360.0
            }
        case .logo:
            withAnimation(.easeOut(duration: 0.50)) { backgroundBlur = 0.0 }
        case .done:
            break
        }
    }
}

private struct SeatDot: View {
    var isVisible: Bool
    var pulse: CGFloat
    var body: some View {
        Circle()
            .fill(BrandColors.seatAccent)
            .frame(width: 12, height: 12)
            .opacity(isVisible ? 1.0 : 0.0)
            .shadow(color: BrandColors.seatAccent.opacity(isVisible ? 0.55 : 0.0), radius: isVisible ? 8 * pulse : 0, x: 0, y: 0)
            .overlay(
                Circle()
                    .stroke(BrandColors.seatAccent.opacity(isVisible ? 0.6 : 0.0), lineWidth: 1)
                    .blur(radius: 0.5)
            )
    }
}

// Removed name cards around the table per design direction

private struct ConditionalMatchedGeometry: ViewModifier {
    var namespace: Namespace.ID?
    func body(content: Content) -> some View {
        if let ns = namespace {
            content.matchedGeometryEffect(id: "heroTable", in: ns)
        } else {
            content
        }
    }
}


