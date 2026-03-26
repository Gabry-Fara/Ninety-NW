//
//  ContentView.swift
//  iPinballTV
//

import SwiftUI
import SpriteKit

struct ContentView: View {
    
    private let scene: SKScene = {
        guard let scene = GameScene(fileNamed: "GameScene") else {
            fatalError("impossibile caricare GameScene.sks")
        }
        
        scene.scaleMode = .aspectFit
        scene.size = CGSize(width: 750, height: 1334)
        return scene
    }()
    
    var body: some View {
        SpriteView(scene: scene)
            .ignoresSafeArea()
    }
}
