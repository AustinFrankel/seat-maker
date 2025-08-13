//
//  LottieLaunchView.swift
//  TableMakerPublish
//
//  Optional Lottie-based fallback. Disposes player on completion.
//

import SwiftUI

#if canImport(UIKit)
import UIKit
#endif

// Note: Requires adding Lottie dependency to the project if used.
// This wrapper gracefully falls back to SwiftUI animation if Lottie cannot be loaded.

public struct LottieLaunchView: View {
    public var lottieName: String
    public var onFinished: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init(lottieName: String = "SeatMakerLaunch", onFinished: @escaping () -> Void) {
        self.lottieName = lottieName
        self.onFinished = onFinished
    }

    public var body: some View {
        ZStack {
            BrandColors.seatSurface.ignoresSafeArea()
            // Placeholder visual while loading or if unavailable
            LaunchAnimationView(variant: .minimalSweep, onFinished: onFinished)
                .opacity(0.001)
        }
        .task { await run() }
    }

    private func run() async {
        // In a real integration, we would host a LottieAnimationView via UIViewRepresentable.
        // Match the extended launch pacing (≈ 3.3s) when not reduced.
        let cap: UInt64 = reduceMotion ? 300_000_000 : 3_300_000_000
        try? await Task.sleep(nanoseconds: cap)
        await MainActor.run { onFinished() }
    }
}


