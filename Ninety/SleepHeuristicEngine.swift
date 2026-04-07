import Foundation

class SleepHeuristicEngine {
    static let shared = SleepHeuristicEngine()
    
    // Heuristic thresholds
    private let deepSleepHRVThreshold: Double = 80.0 // Very high HRV
    private let movementSpikeThreshold: Double = 0.5 // High variance indicating wake event
    private let remHRVolatilityThreshold: Double = 15.0 // SDNN standard deviation spike
    
    private var rollingVariances: [Double] = []
    private var rollingHRSamples: [Double] = []
    
    func processIncomingPayload(_ payload: SensorPayload) {
        
        rollingVariances.append(payload.accelerometerVariance)
        if rollingVariances.count > 12 {
            rollingVariances.removeFirst()
        }
        
        rollingHRSamples.append(contentsOf: payload.hrSamples)
        if rollingHRSamples.count > 50 {
            rollingHRSamples.removeFirst(rollingHRSamples.count - 50)
        }
        
        let avgVariance = rollingVariances.reduce(0, +) / Double(rollingVariances.count)
        
        let sdnn = calculateSDNN(from: rollingHRSamples)
        
        var sleepStateStr = "Calculating..."
        var shouldTrigger = false
        
        // Very basic mock logic for sleep inference mimicking the PDF state machine:
        if avgVariance > movementSpikeThreshold {
            sleepStateStr = "Micro-Awakening / Core Transition (OPTIMAL)"
            shouldTrigger = true
        } else if sdnn > deepSleepHRVThreshold {
            sleepStateStr = "Deep Sleep (SUBOPTIMAL - INHIBIT ALARM)"
        } else if sdnn > remHRVolatilityThreshold {
            sleepStateStr = "REM Sleep (OPTIMAL)"
            shouldTrigger = true
        } else {
            sleepStateStr = "Core Sleep"
        }
        
        let logMsg = """
        Analysis: [Variance: \(String(format: "%.3f", avgVariance))] [SDNN: \(String(format: "%.1f", sdnn))] -> \(sleepStateStr)
        """
        
        DispatchQueue.main.async {
            SleepSessionManager.shared.logs.insert(logMsg, at: 0)
        }
        
        if shouldTrigger {
            DispatchQueue.main.async {
                SleepSessionManager.shared.logs.insert("🎯 OPTIMAL WAKE STATE DETECTED! Triggering Dynamic Alarm!", at: 0)
                SmartAlarmManager.shared.triggerDynamicAlarm()
            }
        }
    }
    
    private func calculateSDNN(from hrSamples: [Double]) -> Double {
        guard hrSamples.count > 1 else { return 0.0 }
        
        // Convert HR (bpm) to roughly NN intervals in milliseconds
        // NN = 60000 / HR
        let nnIntervals = hrSamples.map { 60000.0 / $0 }
        
        let sum = nnIntervals.reduce(0, +)
        let mean = sum / Double(nnIntervals.count)
        
        let squaredDiffs = nnIntervals.map { pow($0 - mean, 2) }
        let sumSquaredDiffs = squaredDiffs.reduce(0, +)
        
        let variance = sumSquaredDiffs / Double(nnIntervals.count - 1)
        return sqrt(variance) // SDNN in ms
    }
}
