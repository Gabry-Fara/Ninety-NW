import SwiftUI

enum GameStyleArtworkMode {
    case preview
    case backdrop
}

struct GameStyleArtworkView: View {
    let style: GameStyle
    var mode: GameStyleArtworkMode = .preview
    var blurRadius: CGFloat = 0

    private var previewHeight: CGFloat {
        mode == .preview ? 280 : 0
    }

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            LinearGradient(
                colors: [
                    AppTheme.placeholderColor(style.backgroundToken),
                    AppTheme.placeholderColor(style.accentToken),
                    .black
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Image(mode == .preview ? style.previewAssetName : style.backgroundAssetName)
                .resizable()
                .scaledToFill()
                .opacity(mode == .preview ? 0.92 : 0.72)
                .blur(radius: blurRadius + (mode == .preview ? 0.3 : 3.5))
                .scaleEffect(mode == .preview ? 1.02 : 1.08)
                .clipped()

            LinearGradient(
                stops: [
                    .init(color: .clear, location: 0.25),
                    .init(color: .black.opacity(mode == .preview ? 0.72 : 0.88), location: 1.0)
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            if mode == .preview {
                VStack(alignment: .leading, spacing: 8) {
                    Text(style.name)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)

                    Text(style.tagline)
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.8))
                        .frame(maxWidth: 380, alignment: .leading)

                    Label("preview partita", systemImage: style.symbolName)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.8))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.white.opacity(0.12))
                        .clipShape(Capsule())
                }
                .padding(AppTheme.spacingLG)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: mode == .preview ? previewHeight : .infinity)
        .frame(height: mode == .preview ? previewHeight : nil)
        .clipShape(RoundedRectangle(cornerRadius: mode == .preview ? AppTheme.cornerRadiusLG : 0))
    }
}

#Preview("preview") {
    GameStyleArtworkView(style: SampleDataProvider.gameStyles[0])
        .padding()
        .background(Color.black)
}
