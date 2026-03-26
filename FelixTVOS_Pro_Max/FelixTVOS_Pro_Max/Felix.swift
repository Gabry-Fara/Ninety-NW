//
//  Felix.swift
//  FelixTVOS_Pro_Max
//
//  Created by AFP PAL 21 on 26/03/26.
//

import SpriteKit

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
    
    var felix = SKSpriteNode()
    var start = SKSpriteNode()
    var scoreLabel = SKLabelNode()
    var messageLabel = SKLabelNode()
    var actionFelix = SKAction()
    var coin = SKSpriteNode()
    var actionCoin = SKAction()
    let defaultImpulse = 4000
    var currentImpulse: Int = 0
    var startingTime: TimeInterval = 0
    
    // ✅ FIX: variabile mancante aggiunta qui
    var gesturesInstalled = false

    override func didMove(to view: SKView) {
        super.didMove(to: view)
        
        // ✅ FIX: didMove non più annidato, guard corretto
        guard !gesturesInstalled else { return }
        gesturesInstalled = true

        // ✅ tvOS: Swipe su (telecomando Siri)
        let swipeUp = UISwipeGestureRecognizer(target: self, action: #selector(swipedUp))
        swipeUp.direction = .up
        view.addGestureRecognizer(swipeUp)

        // ✅ tvOS: Tap centrale (tasto "select" del telecomando)
        let tap = UITapGestureRecognizer(target: self, action: #selector(tapped))
        tap.allowedPressTypes = [NSNumber(value: UIPress.PressType.select.rawValue)]
        view.addGestureRecognizer(tap)

        physicsWorld.contactDelegate = self

        // Nodes
        felix = childNode(withName: "Felix") as! SKSpriteNode
        start = childNode(withName: "Start") as! SKSpriteNode
        scoreLabel = camera!.childNode(withName: "score") as! SKLabelNode
        scoreLabel.text = String(score)
        messageLabel = camera!.childNode(withName: "message") as! SKLabelNode
        messageLabel.text = ""

        // Animazione monete
        self.enumerateChildNodes(withName: "coin") { node, _ in
            node.run(SKAction(named: "coin")!)
        }
    }

    // ✅ tvOS: swipe su dal telecomando → salto
    @objc func swipedUp() {
        guard !gameEnded else { return }
        felix.physicsBody?.applyImpulse(CGVector(dx: 0, dy: currentImpulse))
        currentImpulse /= 2
        felix.removeAllActions()
        actionFelix = SKAction(named: "jump")!
        felix.run(actionFelix)
    }

    // ✅ tvOS: tap "select" → riavvia se game over
    @objc func tapped() {
        if gameEnded {
            let newScene = Felix(fileNamed: "Felix") // ✅ FIX: era GameScene, classe corretta è Felix
            newScene!.scaleMode = self.scaleMode
            self.view?.presentScene(newScene!, transition: SKTransition.fade(withDuration: 1.0))
        }
    }

    // ✅ touchesBegan mantenuto per compatibilità con simulatore, ma su tvOS reale
    //    il flusso passa dai gesture recognizer sopra.
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let touchLocation = touch.location(in: self)
        let node = self.atPoint(touchLocation)
        
        if !gameEnded {
            if node.name == "Jump" {
                felix.physicsBody?.applyImpulse(CGVector(dx: 0, dy: currentImpulse))
                currentImpulse /= 2
                felix.removeAllActions()
                actionFelix = SKAction(named: "jump")!
                felix.run(actionFelix)
            }
        } else {
            if node.name == "Felix" {
                let newScene = Felix(fileNamed: "Felix") // ✅ FIX: era GameScene
                newScene!.scaleMode = self.scaleMode
                self.view?.presentScene(newScene!, transition: SKTransition.fade(withDuration: 1.0))
            }
        }
    }

    func didBegin(_ contact: SKPhysicsContact) {
        let catA = contact.bodyA.categoryBitMask
        let catB = contact.bodyB.categoryBitMask
        let sum = catA + catB

        switch sum {
        case 5: // Hole (4) + Felix (1)
            actionFelix = SKAction(named: "fall")!
            felix.run(actionFelix)

        case 9: // Ground (8) + Felix (1)
            actionFelix = SKAction(named: "dead")!
            felix.run(actionFelix)
            gameEnded = true
            messageLabel.text = "YOU LOSE!!!"
            scene?.run(SKAction.playSoundFileNamed("error.wav", waitForCompletion: true))

        case 17: // Little coin (16) + Felix (1)
            (catA == 16 ? contact.bodyA.node : contact.bodyB.node)?.removeFromParent()
            score += 1
            scoreLabel.text = String(score)

        case 33: // Big coin (32) + Felix (1)
            (catA == 32 ? contact.bodyA.node : contact.bodyB.node)?.removeFromParent()
            score += 100
            scoreLabel.text = String(score)

        case 65: // Finish (64) + Felix (1)
            felix.removeAllActions()
            actionFelix = SKAction(named: "jump")!
            felix.run(actionFelix)
            messageLabel.text = "YOU WIN!!!"

        default:
            break
        }
    }

    override func update(_ currentTime: TimeInterval) {
        if startingTime == 0 {
            startingTime = currentTime
        } else if currentTime >= startingTime + 3 {
            startingTime = currentTime
            currentImpulse = defaultImpulse
        }
    }
}
