import SwiftUI

enum QuickActionStyle {
    case primary    // filled, prominent
    case secondary  // outline / muted
}

struct QuickActionButtonView: View {
    let label: String
    let symbolName: String
    let style: QuickActionStyle
    let action: () -> Void

    @Environment(\.isFocused) private var isFocused

    var body: some View {
        Button(action: action) {
            HStack(spacing: AppTheme.spacingXS) {
                Image(systemName: symbolName)
                    .font(.headline)
                Text(label)
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            .padding(.horizontal, AppTheme.spacingMD)
            .padding(.vertical, AppTheme.spacingSM)
            .background(background)
            .foregroundStyle(foregroundColor)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadiusMD))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.cornerRadiusMD)
                    .strokeBorder(strokeColor, lineWidth: isFocused ? 2 : 0)
            )
            .tvFocusEffect(
                isFocused: isFocused,
                scale: AppTheme.focusScaleButton,
                shadowColor: .white.opacity(0.2),
                shadowRadius: 12
            )
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var background: some View {
        switch style {
        case .primary:
            Color.white
        case .secondary:
            Color.white.opacity(isFocused ? 0.2 : 0.1)
        }
    }

    private var foregroundColor: Color {
        switch style {
        case .primary:   return .black
        case .secondary: return .white
        }
    }

    private var strokeColor: Color {
        switch style {
        case .primary:   return .clear
        case .secondary: return .white.opacity(0.6)
        }
    }
}

#Preview("primary") {
    QuickActionButtonView(label: "Play", symbolName: "play.fill", style: .primary) {}
        .padding()
        .background(Color.black)
}
