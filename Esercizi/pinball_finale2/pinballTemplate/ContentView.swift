//
//  ContentView.swift
//  pinballTemplate
//
//  Created by Ignazio Finizio on 16/01/23.
//

import SwiftUI
import SpriteKit

struct ContentView: View {
    var scene: SKScene {
        let scene = GameScene(fileNamed: "GameScene") ?? GameScene(size: CGSize(width: 750, height: 1334))
        scene.size = CGSize(width: 750, height: 1334)
        scene.scaleMode = .aspectFit
        return scene
    }
    
    var body: some View {
        #if os(macOS)
        SpriteKitView(scene: scene)
            .edgesIgnoringSafeArea(.all)
        #else
        SpriteView(scene: scene)
            .edgesIgnoringSafeArea(.all)
        #endif
    }
}

#if os(macOS)
class KeyboardSKView: SKView {
    override var acceptsFirstResponder: Bool {
        return true
    }
}

struct SpriteKitView: NSViewRepresentable {
    let scene: SKScene
    
    func makeNSView(context: Context) -> KeyboardSKView {
        let skView = KeyboardSKView()
        skView.presentScene(scene)
        return skView
    }
    
    func updateNSView(_ nsView: KeyboardSKView, context: Context) {
        DispatchQueue.main.async {
            nsView.window?.makeFirstResponder(nsView)
        }
    }
}
#endif

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
