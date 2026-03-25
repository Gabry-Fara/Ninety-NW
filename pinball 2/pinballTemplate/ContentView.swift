//
//  ContentView.swift
//  pinballTemplate
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
struct SpriteKitView: NSViewRepresentable {
    let scene: SKScene
    
    func makeNSView(context: Context) -> SKView {
        let skView = SKView()
        skView.presentScene(scene)
        skView.becomeFirstResponder()
        return skView
    }
    
    func updateNSView(_ nsView: SKView, context: Context) {
        // Update if needed
    }
}
#endif

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
