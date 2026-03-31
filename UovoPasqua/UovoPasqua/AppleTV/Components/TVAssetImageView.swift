import SwiftUI
import UIKit

struct TVAssetImageView: View {
    let assetName: String
    let fallbackTopToken: String
    let fallbackBottomToken: String
    var contentMode: ContentMode = .fill

    var body: some View {
        if let image = UIImage(named: assetName) {
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: contentMode)
        } else {
            LinearGradient(
                colors: [
                    AppTheme.placeholderColor(fallbackTopToken),
                    AppTheme.placeholderColor(fallbackBottomToken)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
}
