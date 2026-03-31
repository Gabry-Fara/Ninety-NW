import SwiftUI

// lightweight in-memory state shared across tabs via environment
@Observable
final class AppState {
    var watchlistIDs: Set<String> = []

    func isInWatchlist(_ item: MediaItem) -> Bool {
        watchlistIDs.contains(item.id)
    }

    func toggleWatchlist(_ item: MediaItem) {
        if watchlistIDs.contains(item.id) {
            watchlistIDs.remove(item.id)
        } else {
            watchlistIDs.insert(item.id)
        }
    }

    var watchlistItems: [MediaItem] {
        SampleDataProvider.allItems.filter { watchlistIDs.contains($0.id) }
    }
}
