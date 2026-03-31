import Foundation

// main navigation tabs
enum AppTab: String, CaseIterable, Hashable {
    case home    = "Home"
    case catalog = "Catalog"
    case search  = "Search"
    case library = "Library"

    var symbolName: String {
        switch self {
        case .home:    return "house.fill"
        case .catalog: return "square.grid.2x2.fill"
        case .search:  return "magnifyingglass"
        case .library: return "bookmark.fill"
        }
    }
}
