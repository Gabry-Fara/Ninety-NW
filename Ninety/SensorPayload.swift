import Foundation

/// Represents the raw data batch transmitted from the Apple Watch to the iPhone via WatchConnectivity.
struct SensorPayload: Codable {
    let id: UUID
    let timestamp: Date
    let hrSamples: [Double]
    let accelerometerVariance: Double
    let isMockData: Bool
}
