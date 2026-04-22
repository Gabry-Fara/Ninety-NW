// HapticWakeUpManager.swift
// NinetyWatch Watch App
//
// Requirement 3 — Gradual Haptic Wake-Up Sequence
//
// When the iPhone fires the dynamic alarm (Layer 2), it sends a
// "hapticWakeUp" command to the Watch via WCSession. This manager
// intercepts that signal and plays a progressive vibration sequence
// using WKInterfaceDevice, ramping from gentle taps to urgent pulses
// so the wake-up is smooth and doesn't cancel the sleep-cycle benefit.
//
// Haptic phases:
//   Phase 1 (0–12s)   → gentle .notification every 3s
//   Phase 2 (12–24s)  → medium .directionUp every 2s
//   Phase 3 (24–36s)  → strong .click every 1.5s
//   Phase 4 (36s+)    → urgent .notification every 1s, for 30s max

import WatchKit
import Foundation
import Combine

@MainActor
class HapticWakeUpManager: ObservableObject {

    static let shared = HapticWakeUpManager()

    @Published var isPlaying = false

    private var hapticTimer: Timer?
    private var elapsedTicks: Int = 0

    // MARK: - Phase Configuration

    /// Each phase defines a haptic type, interval between taps, and duration in seconds.
    private struct Phase {
        let hapticType: WKHapticType
        let interval: TimeInterval
        let duration: TimeInterval
    }

    private let phases: [Phase] = [
        Phase(hapticType: .notification,  interval: 3.0, duration: 12),  // gentle
        Phase(hapticType: .directionUp,   interval: 2.0, duration: 12),  // medium
        Phase(hapticType: .click,         interval: 1.5, duration: 12),  // strong
        Phase(hapticType: .notification,  interval: 1.0, duration: 30),  // urgent
    ]

    // MARK: - Public API

    /// Starts the progressive haptic wake-up sequence.
    func startGradualWakeUp() {
        guard !isPlaying else { return }
        isPlaying = true
        elapsedTicks = 0

        // Use a high-frequency timer (0.5s) and gate haptics per-phase interval
        hapticTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            guard let manager = self else { return }
            Task { @MainActor in
                manager.tick()
            }
        }
    }

    /// Stops the haptic sequence immediately (e.g., user dismissed the alarm).
    func stop() {
        hapticTimer?.invalidate()
        hapticTimer = nil
        isPlaying = false
        elapsedTicks = 0
    }

    // MARK: - Internal

    private func tick() {
        let elapsed = Double(elapsedTicks) * 0.5  // seconds since start

        // Determine which phase we're in
        var cumulativeDuration: TimeInterval = 0
        var currentPhase: Phase?

        for phase in phases {
            if elapsed < cumulativeDuration + phase.duration {
                currentPhase = phase
                break
            }
            cumulativeDuration += phase.duration
        }

        guard let phase = currentPhase else {
            // All phases exhausted — stop
            stop()
            return
        }

        // Only play a haptic at the phase's specified interval
        let elapsedInPhase = elapsed - cumulativeDuration
        let tickInterval: TimeInterval = 0.5
        let shouldPlay = Int(elapsedInPhase / tickInterval) % Int(phase.interval / tickInterval) == 0

        if shouldPlay {
            WKInterfaceDevice.current().play(phase.hapticType)
        }

        elapsedTicks += 1
    }
}
