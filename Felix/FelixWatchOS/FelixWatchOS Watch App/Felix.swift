//  Felix.swift
//  FelixWatchOS Watch App

import SpriteKit
import CoreGraphics
#if os(watchOS)
import WatchKit
#endif

// Category mask
// Felix: 1 / Platform: 2 / Hole: 4 / Ground: 8
// Little coin: 16 / Big coin: 32 / Finish: 64

class Felix: SKScene, SKPhysicsContactDelegate {
    var score = 0
    var gameEnded = false
    var restartHandler: (() -> Void)?

    var felix = SKSpriteNode()
    var start = SKSpriteNode()
    var scoreLabel = SKLabelNode()
    var messageLabel = SKLabelNode()
    var actionFelix = SKAction()
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
        felix = childNode(withName: "Felix") as! SKSpriteNode
        start = childNode(withName: "Start") as! SKSpriteNode
        scoreLabel = camera!.childNode(withName: "score") as! SKLabelNode
        scoreLabel.text = "0"
        messageLabel = camera!.childNode(withName: "message") as! SKLabelNode
        messageLabel.text = ""
        currentImpulse = defaultImpulse
        enumerateChildNodes(withName: "coin") { node, _ in
            node.run(SKAction(named: "coin")!)
        }
    }

    func handleCrownRotation(delta: Double) {
        if gameEnded { restartHandler?(); return }
        if delta < 0 { jump() } else if delta > 0 { advance() }
    }

    private func jump() {
        guard currentImpulse > 0 else { return }
        felix.physicsBody?.applyImpulse(CGVector(dx: 0, dy: currentImpulse))
        currentImpulse /= 2
        felix.removeAllActions()
        felix.run(SKAction(named: "jump")!)
    }

    private func advance() {
        felix.position.x += stepDistance
        felix.removeAllActions()
        if let run = SKAction(named: "run") { felix.run(run) }
        updateCameraPosition()
    }

    private func updateCameraPosition() {
        camera?.position = CGPoint(x: felix.position.x, y: felix.position.y)
    }

    func didBegin(_ contact: SKPhysicsContact) {
        let sum = contact.bodyA.categoryBitMask + contact.bodyB.categoryBitMask
        switch sum {
        case 5:  // Hole + Felix
            felix.run(SKAction(named: "fall")!)
        case 9:  // Ground + Felix
            felix.run(SKAction(named: "dead")!)
            gameEnded = true
            messageLabel.text = "YOU LOSE!!!"
            #if os(watchOS)
            WKInterfaceDevice.current().play(.failure)
            #else
            scene?.run(SKAction.playSoundFileNamed("error.wav", waitForCompletion: true))
            #endif
        case 17: // Little coin + Felix
            (contact.bodyA.categoryBitMask == 16 ? contact.bodyA.node : contact.bodyB.node)?.removeFromParent()
            score += 1
            scoreLabel.text = String(score)
            #if os(watchOS)
            WKInterfaceDevice.current().play(.click)
            #endif
        case 33: // Big coin + Felix
            (contact.bodyA.categoryBitMask == 32 ? contact.bodyA.node : contact.bodyB.node)?.removeFromParent()
            score += 100
            scoreLabel.text = String(score)
            #if os(watchOS)
            WKInterfaceDevice.current().play(.success)
            #endif
        case 65: // Finish + Felix
            felix.removeAllActions()
            felix.run(SKAction(named: "jump")!)
            messageLabel.text = "YOU WIN!!!"
            #if os(watchOS)
            WKInterfaceDevice.current().play(.success)
            #endif
        default: break
        }
    }

    override func update(_ currentTime: TimeInterval) {
        updateCameraPosition()
        if startingTime == 0 {
            startingTime = currentTime
        } else if currentTime >= startingTime + 3 {
            startingTime = currentTime
            currentImpulse = defaultImpulse
        }
    }
}
