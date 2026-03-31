import Foundation

// content category used in catalog and home shelf
struct Category: Identifiable, Hashable {
    let id: String
    let name: String
    let tagline: String
    let symbolName: String
    // gradient stop tokens: two color names from AppTheme
    let gradientStart: String
    let gradientEnd: String

    // human-readable label for filter chips
    var filterLabel: String { name }
}
