import Foundation

// a named row of media items used in home and library
struct ShelfSection: Identifiable {
    let id: String
    let title: String
    let subtitle: String?
    let items: [MediaItem]
}
