import Foundation

struct GameStyle: Identifiable, Hashable {
    let id: String
    let name: String
    let tagline: String
    let previewAssetName: String
    let backgroundAssetName: String
    let gameplayAssetName: String
    let accentToken: String
    let backgroundToken: String
    let symbolName: String

    func assetName(for role: GameStyleArtworkRole) -> String {
        switch role {
        case .preview:
            return previewAssetName
        case .background:
            return backgroundAssetName
        case .gameplay:
            return gameplayAssetName
        }
    }
}

enum GameStyleArtworkRole {
    case preview
    case background
    case gameplay
}
