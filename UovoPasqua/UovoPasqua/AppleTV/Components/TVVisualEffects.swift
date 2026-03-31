import SwiftUI

struct TVFocusEffectModifier: ViewModifier {
    let isFocused: Bool
    var scale: CGFloat
    var shadowColor: Color
    var shadowRadius: CGFloat
    var shadowYOffset: CGFloat

    func body(content: Content) -> some View {
        content
            .scaleEffect(isFocused ? scale : 1)
            .shadow(
                color: isFocused ? shadowColor : .clear,
                radius: shadowRadius,
                y: shadowYOffset
            )
            .animation(.easeOut(duration: AppTheme.focusAnimDuration), value: isFocused)
    }
}

struct TVGlassPanelModifier: ViewModifier {
    var cornerRadius: CGFloat = AppTheme.cornerRadiusLG
    var opacity: Double = 0.92
    var strokeColor: Color = Color.white.opacity(0.12)
    var strokeWidth: CGFloat = 1

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(.ultraThinMaterial)
                    .opacity(opacity)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .strokeBorder(strokeColor, lineWidth: strokeWidth)
                    )
            )
    }
}

extension View {
    func tvFocusEffect(
        isFocused: Bool,
        scale: CGFloat,
        shadowColor: Color,
        shadowRadius: CGFloat,
        shadowYOffset: CGFloat = 0
    ) -> some View {
        modifier(
            TVFocusEffectModifier(
                isFocused: isFocused,
                scale: scale,
                shadowColor: shadowColor,
                shadowRadius: shadowRadius,
                shadowYOffset: shadowYOffset
            )
        )
    }

    func tvGlassPanel(
        cornerRadius: CGFloat = AppTheme.cornerRadiusLG,
        opacity: Double = 0.92,
        strokeColor: Color = Color.white.opacity(0.12),
        strokeWidth: CGFloat = 1
    ) -> some View {
        modifier(
            TVGlassPanelModifier(
                cornerRadius: cornerRadius,
                opacity: opacity,
                strokeColor: strokeColor,
                strokeWidth: strokeWidth
            )
        )
    }
}
