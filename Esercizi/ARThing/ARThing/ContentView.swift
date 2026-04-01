//
//  ContentView.swift
//  ARThing
//
//  Created by Cristian on 01/04/26.
//

import SwiftUI
import RealityKit

struct ContentView : View {
    @State var sunEntity: Entity?
    @State var skullEntity: Entity?
    @State var hasSpawned: Bool = false

    var body: some View {
        RealityView { content in

            if let sun = try? await Entity(named: "Sun") {
                if let skull = try? await Entity(named: "Skull") {
                    sun.scale = [2, 2, 2]
                    skull.scale = [0.35, 0.35, 0.35]
                    skull.position = [-0.1, 0, 0]
                    
                    let anchor = AnchorEntity(.plane(.horizontal, classification: .any, minimumBounds: SIMD2<Float>(0.2, 0.2)))
                    anchor.addChild(sun)
//                    anchor.addChild(skull)
                    
                    content.add(anchor)
                    
                    content.camera = .spatialTracking
                    
                    self.sunEntity = sun
                    self.skullEntity = skull
                    
                    sun.generateCollisionShapes(recursive: true)
                }
            }
        }
        .onTapGesture {
            if let sun = self.sunEntity, let skull = self.skullEntity {
                if !hasSpawned {
                    hasSpawned = true
                    sun.addChild(skull)
                    
                    if let skullAnimation = skull.availableAnimations.first {
                        skull.playAnimation(skullAnimation.repeat())
                    }
                }
                
                var newTransform = sun.transform
//                newTransform.translation += [0, 1, 0]
                newTransform.rotation = simd_quatf(angle: .pi, axis: [1, 0, 0])
                
                sun.move(
                    to: newTransform,
                    relativeTo: sun.parent,
                    duration: 2.0
                )
            }
        }
        .edgesIgnoringSafeArea(.all)
    }

}

#Preview {
    ContentView()
}
