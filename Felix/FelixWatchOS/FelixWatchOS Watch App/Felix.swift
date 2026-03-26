//
//  Felix.swift
//  felix
//
//  Created by Ignazio Finizio on 16/01/23.
//

import SpriteKit
import CoreGraphics

// Category mask
// Felix: 1
// Platform: 2
// Hole: 4
// Ground: 8
// Little coin: 16
// Big coin: 32
// Finish: 64


class Felix: SKScene, SKPhysicsContactDelegate {
    var score = 0
    var gameEnded = false
    var restartHandler: (() -> Void)?
    
    var felix = SKSpriteNode()
    var start = SKSpriteNode()
    var scoreLabel = SKLabelNode()
    var messageLabel = SKLabelNode()
    var actionFelix = SKAction()
    var coin = SKSpriteNode()
    var actionCoin = SKAction()
    let defaultImpulse = 4000
    let stepDistance: CGFloat = 120
    var currentImpulse: Int = 0
    var startingTime: TimeInterval = 0

    override func sceneDidLoad() {
        super.sceneDidLoad()
        scaleMode = .aspectFill
        configureScene()
    }

    private func configureScene() {
        physicsWorld.contactDelegate = self

        // Nodes
        felix = childNode(withName: "Felix") as! SKSpriteNode
        start = childNode(withName: "Start") as! SKSpriteNode
        scoreLabel = camera!.childNode(withName: "score") as! SKLabelNode
        scoreLabel.text = String(score)
        messageLabel = camera!.childNode(withName: "message") as! SKLabelNode
        messageLabel.text = String("")
        currentImpulse = defaultImpulse

        // Actions
        enumerateChildNodes(withName: "coin") { node, _ in
            node.run(SKAction(named: "coin")!)
        }
    }

    override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        updateCameraPosition()
    }

    func handleVerticalScroll(deltaY: CGFloat) {
        if gameEnded {
            restartHandler?()
            return
        }

        if deltaY < 0 {
            jump()
        } else if deltaY > 0 {
            advance()
        }
    }

    func handleCrownRotation(delta: Double) {
        if gameEnded {
            restartHandler?()
            return
        }

        if delta < 0 {
            jump()
        } else if delta > 0 {
            advance()
        }
    }

    private func jump() {
        guard currentImpulse > 0 else { return }
        felix.physicsBody?.applyImpulse(CGVector(dx: 0, dy: currentImpulse))
        currentImpulse /= 2
        felix.removeAllActions()
        actionFelix = SKAction(named: "jump")!
        felix.run(actionFelix)
    }

    private func advance() {
        let newX = felix.position.x + stepDistance
        felix.position = CGPoint(x: newX, y: felix.position.y)
        felix.removeAllActions()
        if let runAction = SKAction(named: "run") {
            felix.run(runAction)
        }
        updateCameraPosition()
    }

    private func updateCameraPosition() {
        camera?.position = CGPoint(x: felix.position.x, y: felix.position.y)
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        let catA = contact.bodyA.categoryBitMask
        let catB = contact.bodyB.categoryBitMask
        
        if (catA+catB==5){ //4 + 1 Hole + Felix
            actionFelix = SKAction(named: "fall")!
            felix.run(actionFelix)
        }else if (catA+catB==9){ //8+1 Ground + Felix
            actionFelix = SKAction(named: "dead")!
            felix.run(actionFelix)
            gameEnded = true
            messageLabel.text = "YOU LOSE!!!"
            scene?.run(SKAction.playSoundFileNamed("error.wav", waitForCompletion: true))
        }else if (catA+catB==17){ //16+1 Little coin + Felix
            if(catA == 16) {
                contact.bodyA.node?.removeFromParent()
            } else{
                contact.bodyB.node?.removeFromParent()
            }
            score += 1
            scoreLabel.text = String(score)
        } else if (catA+catB==33){ //32+1 Big coin + Felix
            if(catA == 32) {
                contact.bodyA.node?.removeFromParent()
            } else{
                contact.bodyB.node?.removeFromParent()
            }
            score += 100
            scoreLabel.text = String(score)
        } else if (catA+catB==65){ //64 + 1 Finish + Felix
            felix.removeAllActions()
            actionFelix = SKAction(named: "jump")!
            felix.run(actionFelix)
            messageLabel.text = "YOU WIN!!!"
        }
}

    override func update(_ currentTime: TimeInterval) {
        updateCameraPosition()
        if startingTime == 0{
            startingTime = currentTime
        } else if (currentTime>=startingTime + 3){
            startingTime = currentTime
            currentImpulse = defaultImpulse
        }
    }
}
