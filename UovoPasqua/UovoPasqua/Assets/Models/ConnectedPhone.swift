import Foundation

// mock device shown on the pairing screen
struct ConnectedPhone: Identifiable, Hashable {
    enum ConnectionState: String, Hashable {
        case connected = "Connesso"
        case ready = "Pronto"
        case waiting = "In attesa"

        var badgeSymbol: String {
            switch self {
            case .connected: return "checkmark.circle.fill"
            case .ready: return "dot.radiowaves.left.and.right"
            case .waiting: return "hourglass"
            }
        }
    }

    let id: String
    let deviceName: String
    let ownerName: String
    let modelName: String
    let batteryLevel: Int
    let signalStrength: Int
    let accentTop: String
    let accentBottom: String
    let state: ConnectionState
    let lastSeenLabel: String

    var stateLabel: String { state.rawValue }
    var batteryLabel: String { "\(batteryLevel)%" }
}
