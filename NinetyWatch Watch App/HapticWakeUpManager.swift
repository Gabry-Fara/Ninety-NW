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
// Haptic phases (Optimized Rhythmic Wake-Up):
//   Phase 1 (0–15s)   → very light .click every 3s
//   Phase 2 (15–30s)  → slightly faster .click every 1.5s
//   Phase 3 (30–45s)  → stronger .directionUp every 1s
//   Phase 4 (45s+)    → urgent .notification every 0.5s

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
        Phase(hapticType: .click,         interval: 3.0, duration: 15),  // Phase 1: gentle pulse
        Phase(hapticType: .click,         interval: 1.5, duration: 15),  // Phase 2: faster pulse
        Phase(hapticType: .directionUp,   interval: 1.0, duration: 15),  // Phase 3: emerging
        Phase(hapticType: .notification,  interval: 0.5, duration: 20),  // Phase 4: urgent
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
        guard isPlaying else { return }
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
