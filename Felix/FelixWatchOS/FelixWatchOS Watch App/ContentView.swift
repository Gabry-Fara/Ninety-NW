//  ContentView.swift
//  FelixWatchOS Watch App

import SwiftUI
import SpriteKit
import Combine  // ✅ FIX: mancava, necessario per ObservableObject/@Published

// MARK: - SceneStore

final class SceneStore: ObservableObject {
    @Published var scene: Felix

    init() {
        scene = Self.makeScene()
        wireHandler()
    }

    func reload() {
        scene = Self.makeScene()
        wireHandler()
    }

    private func wireHandler() {
        scene.restartHandler = { [weak self] in
            DispatchQueue.main.async { self?.reload() }
        }
    }

    private static func makeScene() -> Felix {
        let s = Felix(fileNamed: "Felix") ?? Felix(size: .zero)
        s.scaleMode = .aspectFill
        return s
    }
}

// MARK: - ContentView

struct ContentView: View {
    @StateObject private var store = SceneStore()
    @State private var crownValue = 0.0
    @State private var lastCrownValue = 0.0

    var body: some View {
        // ✅ FIX: SpriteView è il modo corretto su watchOS 7+
        // WKInterfaceSKScene() è deprecato
        SpriteView(scene: store.scene)
            .ignoresSafeArea()
            .focusable(true)
            .digitalCrownRotation(
                $crownValue,
                from: -1000,
                through: 1000,
                by: 1,
                sensitivity: .medium,
                isContinuous: true,
                isHapticFeedbackEnabled: true
            )
            .onChange(of: crownValue) { newValue in
                let delta = newValue - lastCrownValue
                lastCrownValue = newValue
                guard abs(delta) >= 1 else { return }
                store.scene.handleCrownRotation(delta: delta)
            }
            .onTapGesture {
                if store.scene.gameEnded {
                    store.reload()
                }
            }
            .id(ObjectIdentifier(store.scene))
    }
}
