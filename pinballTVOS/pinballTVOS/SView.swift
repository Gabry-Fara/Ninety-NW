//
//  SView.swift
//  WhatchApp01
//
//  Created by AFP PAL 21 on 26/03/26.
//
import SwiftUI
import SpriteKit

struct Sview: View {
    var scene: SKScene {
        let scene = SKScene(fileNamed: "GameScene")
        scene!.size = CGSize(width: 750, height: 1334)
        scene?.scaleMode = .aspectFit
        return scene!
    }
    
    var body: some View {
        SpriteView(scene: scene)
            //.edgesIgnoringSafeArea(.all)
    }
}
