import SwiftUI

// design tokens — all sizes in points, tvOS safe-area friendly
enum AppTheme {

    // MARK: spacing
    static let spacingXS: CGFloat  = 8
    static let spacingSM: CGFloat  = 16
    static let spacingMD: CGFloat  = 32
    static let spacingLG: CGFloat  = 48
    static let spacingXL: CGFloat  = 64
    static let spacingXXL: CGFloat = 96

    // MARK: card sizes
    static let cardWidth: CGFloat       = 300
    static let cardHeight: CGFloat      = 180
    static let cardCornerRadius: CGFloat = 12

    static let categoryCardWidth: CGFloat  = 260
    static let categoryCardHeight: CGFloat = 140

    // MARK: hero
    static let heroHeight: CGFloat          = 620
    static let heroCoverFraction: CGFloat   = 0.65  // fraction of screen width for artwork

    // MARK: grid
    static let catalogColumns: Int = 5
    static let catalogItemWidth: CGFloat = 270
    static let catalogItemHeight: CGFloat = 162

    // MARK: corner radii
    static let cornerRadiusSM: CGFloat = 8
    static let cornerRadiusMD: CGFloat = 12
    static let cornerRadiusLG: CGFloat = 20

    // MARK: focus animation
    static let focusScaleCard: CGFloat    = 1.05
    static let focusScaleButton: CGFloat  = 1.08
    static let focusAnimDuration: Double  = 0.18

    // MARK: gradient placeholder colors mapped by token name
    static func placeholderColor(_ token: String) -> Color {
        switch token {
        case "indigo":   return Color(red: 0.29, green: 0.25, blue: 0.76)
        case "teal":     return Color(red: 0.17, green: 0.58, blue: 0.65)
        case "crimson":  return Color(red: 0.72, green: 0.11, blue: 0.22)
        case "violet":   return Color(red: 0.50, green: 0.18, blue: 0.78)
        case "amber":    return Color(red: 0.85, green: 0.55, blue: 0.10)
        case "forest":   return Color(red: 0.13, green: 0.47, blue: 0.27)
        case "ocean":    return Color(red: 0.08, green: 0.35, blue: 0.62)
        case "rose":     return Color(red: 0.78, green: 0.20, blue: 0.45)
        case "slate":    return Color(red: 0.28, green: 0.32, blue: 0.40)
        case "gold":     return Color(red: 0.80, green: 0.65, blue: 0.15)
        case "midnight": return Color(red: 0.08, green: 0.08, blue: 0.18)
        default:         return Color(red: 0.25, green: 0.25, blue: 0.35)
        }
    }

    // overlay gradient for readability on hero and cards
    static let heroOverlayGradient = LinearGradient(
        stops: [
            .init(color: .black.opacity(0.0), location: 0.35),
            .init(color: .black.opacity(0.85), location: 1.0)
        ],
        startPoint: .top,
        endPoint: .bottom
    )

    static let cardOverlayGradient = LinearGradient(
        stops: [
            .init(color: .clear, location: 0.5),
            .init(color: .black.opacity(0.7), location: 1.0)
        ],
        startPoint: .top,
        endPoint: .bottom
    )
}
