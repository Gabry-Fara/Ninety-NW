//
//  ContentView.swift
//  Felix
//
//  Created by Ignazio Finizio on 16/01/23.
//

import SwiftUI
import Combine
import SpriteKit

final class SceneStore: ObservableObject {
    @Published var scene: Felix

    init() {
        scene = Felix(fileNamed: "Felix") ?? Felix(size: .zero)
        scene.scaleMode = .aspectFill
        wireRestartHandler()
    }

    func reloadScene() {
        scene = Felix(fileNamed: "Felix") ?? Felix(size: .zero)
        scene.scaleMode = .aspectFill
        wireRestartHandler()
    }

    private func wireRestartHandler() {
        scene.restartHandler = { [weak self] in
            DispatchQueue.main.async {
                self?.reloadScene()
            }
        }
    }
}

struct ContentView: View {
    @StateObject private var store = SceneStore()
    @State private var crownValue = 0.0
    @State private var previousCrownValue = 0.0

    var body: some View {
        SpriteView(scene: configuredScene())
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
                let delta = newValue - previousCrownValue
                previousCrownValue = newValue

                guard abs(delta) >= 1 else { return }
                store.scene.handleCrownRotation(delta: delta)
            }
    }

    private func configuredScene() -> Felix {
        store.scene.scaleMode = .aspectFill
        return store.scene
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
