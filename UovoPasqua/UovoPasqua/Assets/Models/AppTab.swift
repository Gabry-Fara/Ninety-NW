import Foundation

// tab di navigazione principali
enum AppTab: String, CaseIterable, Hashable {
    case home  = "Home"
    case style = "Stile"

    var symbolName: String {
        switch self {
        case .home:  return "house.fill"
        case .style: return "paintpalette.fill"
        }
    }
}
