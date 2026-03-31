import Foundation

// single media entry — film, series episode or documentary
struct MediaItem: Identifiable, Hashable {
    let id: String
    let title: String
    let subtitle: String          // year · rating · duration string
    let description: String
    let categoryID: String
    let durationSeconds: Int
    let progressSeconds: Int      // 0 = unwatched
    // two color tokens that build the placeholder artwork gradient
    let artworkColorTop: String
    let artworkColorBottom: String
    let artworkSymbol: String     // sf symbol shown in placeholder
    // ids of related items for "more like this"
    let relatedIDs: [String]

    var progressFraction: Double {
        guard durationSeconds > 0 else { return 0 }
        return min(Double(progressSeconds) / Double(durationSeconds), 1)
    }

    var isInProgress: Bool { progressSeconds > 0 && progressFraction < 1 }
}
