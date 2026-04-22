//
//  GuidedTourView.swift
//  Ninety
//
//  Compact spotlight-based onboarding tour.
//  Frames captured via .onGeometryChange in .global space.
//

import SwiftUI

// MARK: - Shared Frame Store

class TourFrameStore: ObservableObject {
    @Published var clockPillFrame: CGRect   = .zero
    @Published var daySelectorFrame: CGRect = .zero
    @Published var alarmButtonFrame: CGRect = .zero
}

// MARK: - Tour Step

private enum TourStep: Int, CaseIterable {
    case welcome = 0, timePicker, daySelector, alarmToggle, privacy, ready

    var icon: String {
        switch self {
        case .welcome:     return "brain.head.profile.fill"
        case .timePicker:  return "clock.fill"
        case .daySelector: return "calendar"
        case .alarmToggle: return "bell.badge.fill"
        case .privacy:     return "lock.shield.fill"
        case .ready:       return "sparkles"
        }
    }

    var title: String {
        switch self {
        case .welcome:     return "Welcome to Ninety"
        case .timePicker:  return "Set Your Wake Time"
        case .daySelector: return "Customize Every Day"
        case .alarmToggle: return "On or Off. Your Call."
        case .privacy:     return "Private by Design"
        case .ready:       return "You're All Set"
        }
    }

    var body: String {
        switch self {
        case .welcome:
            return "Ninety uses on-device machine learning to find the ideal moment to wake you — within the time you set."
        case .timePicker:
            return "Tap the clock to choose when you need to be up. Ninety wakes you at the best point in your sleep cycle."
        case .daySelector:
            return "Each day can have its own wake-up time. Tap a day to select it and adjust the schedule."
        case .alarmToggle:
            return "Toggle the alarm for each day independently — keep your weekdays and weekends perfectly balanced."
        case .privacy:
            return "Your sleep data never leaves your device. No servers, no cloud — everything runs locally on your iPhone."
        case .ready:
            return "Everything is set up. Sweet dreams."
        }
    }

    var isFullScreen: Bool {
        switch self { case .welcome, .privacy, .ready: return true; default: return false }
    }
}

// MARK: - Guided Tour View

struct GuidedTourView: View {
    @Binding var isPresented: Bool
    @EnvironmentObject private var frameStore: TourFrameStore
    @AppStorage("appLanguage") private var appLanguage: String = AppLanguage.english.rawValue
    @AppStorage("hapticFeedbackEnabled") private var hapticFeedbackEnabled: Bool = true
    @Environment(\.colorScheme) private var colorScheme

    @State private var step: TourStep = .welcome
    @State private var show: Bool = false
    @State private var cardScale: CGFloat = 0.92
    @State private var iconAngle: Double = 0

    private let haptic = UIImpactFeedbackGenerator(style: .light)
    private var accent: Color { .themeAccent(for: colorScheme) }

    // Spotlight padding around the element
    private let pad: CGFloat = 12
    // Estimated card height for vertical placement math
    private let estCardH: CGFloat = 170
    // Reserved bottom space for the fixed navigation row.
    private let bottomBarClearance: CGFloat = 132

    init(isPresented: Binding<Bool>) {
        self._isPresented = isPresented
    }

    fileprivate init(isPresented: Binding<Bool>, initialStep: TourStep) {
        self._isPresented = isPresented
        self._step = State(initialValue: initialStep)
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                // Full-screen tap blocker so controls underneath the tour
                // never receive touches while onboarding is visible.
                Rectangle()
                    .fill(Color.black.opacity(0.001))
                    .contentShape(Rectangle())
                    .ignoresSafeArea()
                    .onTapGesture {}

                Color.black.opacity(step.isFullScreen ? 0.7 : 0.0)
                    .ignoresSafeArea()
                    .onTapGesture {}
                    .allowsHitTesting(false)

                group(in: proxy)
                    .allowsHitTesting(false)
            }
            .opacity(show ? 1 : 0)
            .overlay(alignment: .bottom) {
                navRow
                    .padding(.horizontal, 24)
                    .padding(.bottom, proxy.safeAreaInsets.bottom + 44)
            }
        }
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.easeOut(duration: 0.3)) { show = true; cardScale = 1 }
        }
    }

    @ViewBuilder
    private func group(in proxy: GeometryProxy) -> some View {
        if step.isFullScreen {
            fullCard(in: proxy)
        } else {
            spotCard(in: proxy)
        }
    }

    // MARK: - Full-screen card

    private func fullCard(in proxy: GeometryProxy) -> some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 16) {
                // Compact icon
                Image(systemName: step.icon)
                    .font(.system(size: 34, weight: .medium))
                    .foregroundStyle(accent)
                    .symbolRenderingMode(.hierarchical)
                    .padding(16)
                    .background(Circle().fill(accent.opacity(0.12)))
                    .rotationEffect(.degrees(iconAngle))

                Text(step.title.localized(for: appLanguage))
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .multilineTextAlignment(.center)

                Text(step.body.localized(for: appLanguage))
                    .font(.system(size: 17, design: .rounded))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .lineLimit(4)
                    .padding(.horizontal, 4)

                if step != .ready { dots }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 22)
            .frame(maxWidth: min(proxy.size.width - 40, 340))
            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 28))
            .scaleEffect(cardScale)

            Spacer()
        }
        .frame(width: proxy.size.width)
    }

    // MARK: - Spotlight card

    private func spotCard(in proxy: GeometryProxy) -> some View {
        // Convert global target frame to this overlay's local coordinate space.
        let overlayGlobal = proxy.frame(in: .global)
        let localRaw = spotFrame.offsetBy(dx: -overlayGlobal.minX, dy: -overlayGlobal.minY)
        let raw = localRaw
        let hFrame = raw.insetBy(dx: -pad, dy: -pad)

        let spaceBelow = proxy.size.height - bottomBarClearance - hFrame.maxY
        let below = spaceBelow >= estCardH + pad + 24

        let cy: CGFloat = below
            ? hFrame.maxY + pad + estCardH / 2
            : hFrame.minY - pad - estCardH / 2
        let minY = proxy.safeAreaInsets.top + estCardH / 2 + 8
        let maxY = proxy.size.height - proxy.safeAreaInsets.bottom - bottomBarClearance - estCardH / 2
        let safeCY = (cy + spotlightCardYOffset).clamped(to: minY...maxY)

        return ZStack {
            // Dimmed mask with cutout
            SpotlightShape(cutout: hFrame, radius: spotR + pad)
                .fill(style: FillStyle(eoFill: true))
                .foregroundStyle(Color.black.opacity(0.62))
                .ignoresSafeArea()

            // Accent ring
            RoundedRectangle(cornerRadius: spotR + pad, style: .continuous)
                .strokeBorder(accent, lineWidth: 2)
                .frame(width: hFrame.width, height: hFrame.height)
                .shadow(color: accent.opacity(0.45), radius: 10)
                .position(x: hFrame.midX, y: hFrame.midY)

            // Tooltip card
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Image(systemName: step.icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(accent)
                        .symbolRenderingMode(.hierarchical)
                    Text(step.title.localized(for: appLanguage))
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                    Spacer(minLength: 0)
                }

                Text(step.body.localized(for: appLanguage))
                    .font(.system(size: 14, design: .rounded))
                    .foregroundStyle(.secondary)
                    .lineSpacing(2)
                    .lineLimit(3)

                dots.padding(.top, 1)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .frame(width: min(proxy.size.width - 36, 320))
            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 18))
            .scaleEffect(cardScale)
            .position(x: proxy.size.width / 2, y: safeCY)
        }
        .ignoresSafeArea()
    }

    // MARK: - Helpers

    private var spotFrame: CGRect {
        switch step {
        case .timePicker:  return frameStore.clockPillFrame
        case .daySelector: return frameStore.daySelectorFrame
        case .alarmToggle: return frameStore.alarmButtonFrame
        default:           return .zero
        }
    }

    private var spotR: CGFloat {
        switch step {
        case .timePicker:  return 38
        case .daySelector: return 20
        default:           return 24
        }
    }

    private var spotlightCardYOffset: CGFloat {
        switch step {
        case .alarmToggle: return 28
        default:           return 0
        }
    }

    private var dots: some View {
        HStack(spacing: 6) {
            ForEach(TourStep.allCases, id: \.rawValue) { s in
                Circle()
                    .fill(s == step ? accent : Color.primary.opacity(0.2))
                    .frame(width: s == step ? 8 : 5, height: s == step ? 8 : 5)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: step)
            }
        }
    }

    private var navRow: some View {
        HStack(spacing: 8) {
            if step.rawValue > 0 && step != .ready {
                Button { go(back: true) } label: {
                    Image(systemName: "chevron.left")
                        .font(.subheadline.weight(.semibold))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                }
                .buttonStyle(GlassButtonStyle(isProminent: false, tint: nil))
            }

            Button { step == .ready ? close() : go(back: false) } label: {
                Text(step == .ready
                     ? "Get Started".localized(for: appLanguage)
                     : "Next".localized(for: appLanguage))
                    .font(.subheadline.weight(.semibold))
                    .padding(.horizontal, step == .ready ? 36 : 24)
                    .padding(.vertical, 8)
            }
            .buttonStyle(GlassButtonStyle(isProminent: true, tint: accent))
        }
    }

    private func go(back: Bool) {
        if hapticFeedbackEnabled { haptic.impactOccurred() }
        let n = back ? step.rawValue - 1 : step.rawValue + 1
        guard let target = TourStep(rawValue: n) else { return }
        withAnimation(.spring(response: 0.25, dampingFraction: 0.85)) { cardScale = 0.9 }
        withAnimation(.spring(response: 0.35, dampingFraction: 0.75).delay(0.12)) {
            step = target; iconAngle = 0; cardScale = 1
        }
        withAnimation(.easeInOut(duration: 0.55).delay(0.3)) { iconAngle = 360 }
    }

    private func close() {
        if hapticFeedbackEnabled { haptic.impactOccurred() }
        withAnimation(.easeIn(duration: 0.22)) { show = false; cardScale = 0.94 }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { isPresented = false }
    }
}

// MARK: - Spotlight cutout shape

private struct SpotlightShape: Shape {
    let cutout: CGRect
    let radius: CGFloat
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.addRect(rect)
        p.addPath(Path(roundedRect: cutout, cornerRadius: radius, style: .continuous))
        return p
    }
}

// MARK: - TourTargetModifier

enum TourTargetRole { case clockPill, daySelector, alarmButton }

struct TourTargetModifier: ViewModifier {
    let role: TourTargetRole
    @EnvironmentObject private var store: TourFrameStore

    func body(content: Content) -> some View {
        content
            .onGeometryChange(for: CGRect.self) { geo in
                geo.frame(in: .global)
            } action: { frame in
                switch role {
                case .clockPill:    store.clockPillFrame   = frame
                case .daySelector:  store.daySelectorFrame = frame
                case .alarmButton:  store.alarmButtonFrame = frame
                }
            }
    }
}

extension View {
    func tourTarget(_ role: TourTargetRole) -> some View {
        modifier(TourTargetModifier(role: role))
    }
}

// MARK: - Clamp helper

extension Comparable {
    func clamped(to r: ClosedRange<Self>) -> Self { min(max(self, r.lowerBound), r.upperBound) }
}

private struct GuidedTourPreviewHost: View {
    @State private var isPresented = true
    @StateObject private var frameStore = TourFrameStore()

    let step: TourStep

    var body: some View {
        ZStack {
            HorizonBackground(isActive: true)
                .ignoresSafeArea()

            VStack(spacing: 28) {
                RoundedRectangle(cornerRadius: 38, style: .continuous)
                    .fill(Color.white.opacity(0.14))
                    .frame(width: 286, height: 96)

                Capsule()
                    .fill(Color.white.opacity(0.16))
                    .frame(width: 260, height: 54)

                Spacer()

                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(Color.white.opacity(0.18))
                    .frame(width: 180, height: 58)
            }
            .padding(.top, 160)
            .padding(.bottom, 48)

            if isPresented {
                GuidedTourView(isPresented: $isPresented, initialStep: step)
                    .environmentObject(frameStore)
            }
        }
        .onAppear {
            frameStore.clockPillFrame = CGRect(x: 54, y: 188, width: 286, height: 96)
            frameStore.daySelectorFrame = CGRect(x: 67, y: 325, width: 260, height: 54)
            frameStore.alarmButtonFrame = CGRect(x: 107, y: 686, width: 180, height: 58)
        }
    }
}

#Preview("Guided Tour Welcome") {
    GuidedTourPreviewHost(step: .welcome)
}

#Preview("Guided Tour Time Picker") {
    GuidedTourPreviewHost(step: .timePicker)
}

#Preview("Guided Tour Alarm") {
    GuidedTourPreviewHost(step: .alarmToggle)
}
