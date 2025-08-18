//
//  LaunchAnimationController.swift
//  TableMakerPublish
//
//  Drives the phase sequencing for the launch animation.
//

import SwiftUI
import Combine

public final class LaunchAnimationController: ObservableObject {
    public enum Phase: CaseIterable { case grid, sweep, table, seats, cards, logo, done }

    @Published public private(set) var phase: Phase = .grid
    @Published public private(set) var isCompleted: Bool = false

    private var cancellables: Set<AnyCancellable> = []

    public init() {}

    public func startSequence(respectReduceMotion: Bool) {
        if respectReduceMotion {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.30) { [weak self] in
                self?.phase = .done
                self?.isCompleted = true
            }
            return
        }

        // Enhanced pacing, ≈ 3.3s total
        // grid(0–0.60s) → sweep(0.60–1.20s) → table(1.20–1.90s) → seats(1.90–2.60s) → cards(2.60–3.00s) → logo(3.00–3.40s) → done
        phase = .grid
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.60) { [weak self] in
            guard let self else { return }
            self.phase = .sweep
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.60) { [weak self] in
                guard let self else { return }
                self.phase = .table
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.70) { [weak self] in
                    guard let self else { return }
                    self.phase = .seats
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.60) { [weak self] in
                        guard let self else { return }
                        self.phase = .cards
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.40) { [weak self] in
                            guard let self else { return }
                            self.phase = .logo
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.90) { [weak self] in
                                guard let self else { return }
                                self.phase = .done
                                self.isCompleted = true
                            }
                        }
                    }
                }
            }
        }
    }
}


