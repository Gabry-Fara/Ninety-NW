//
//  GameScene.swift
//  iPinball
//
//  Created by Ignazio Finizio on 16/01/22.
//

import SpriteKit


class GameScene: SKScene,SKPhysicsContactDelegate {
    
    
    //CONSTANTS
    let circleA_1Category: UInt32 = 0
    let ballCategory: UInt32 = 1
    let leftpad_rightpadCategory: UInt32 = 2
    let borderCategory: UInt32 = 4
    let upperStopCategory: UInt32 = 8
    let lowerStopCategory: UInt32 = 16
    let circle0Category: UInt32 = 32
    let circle1Category: UInt32 = 64
    let circle2Category: UInt32 = 128
    let star0_star5Category: UInt32 = 256
    let circleA_2Category: UInt32 = 512
    let launcherCategory: UInt32 = 1024
    let barCategory: UInt32 = 2048
    let outLimitCategory: UInt32 = 4096
    
    let maxBallVelocity = 2000.0
    
    
    
    
    //VARS
    var startMode = true
    var leftUp = false
    var rightUp = false
    
    var ball = SKSpriteNode()
    var leftPad = SKSpriteNode()
    var rightPad = SKSpriteNode()
    var launcher = SKSpriteNode()
    var score = SKLabelNode()
    var circle0 = SKSpriteNode()
    var circleA = SKSpriteNode()
    var circle1a = SKSpriteNode()
    var circle1b = SKSpriteNode()
    var circle1c = SKSpriteNode()
    var circle2a = SKSpriteNode()
    var circle2b = SKSpriteNode()
    var circle2c = SKSpriteNode()
    var circle2d = SKSpriteNode()
    var star0 = SKSpriteNode()
    var startMarker = SKSpriteNode()
    var leftDownLoop = SKAction()
    var rightDownLoop = SKAction()
    var circle0Blink = SKAction()
    var circle1Blink = SKAction()
    var circle2Blink = SKAction()
    var launchBallAction = SKAction()
    var loseSound = SKAction()
    var padSound = SKAction()
    var dingSound = SKAction()
    var lastTime: TimeInterval = 0
    var lastScroll = 0.0

    
    
    
    //SCORE MANAGER
    let scManager = scoreManager()
    
    
    override func sceneDidLoad() {
        super.sceneDidLoad()
        
        // Configurazione fisica del mondo
        physicsWorld.contactDelegate = self
        
        // BORDER: Crea un perimetro fisico basato sulla dimensione della scena
        self.physicsBody = SKPhysicsBody(edgeLoopFrom: self.frame)
        
        // --- NODES INITIALIZATION ---
        // NOTA: Se uno di questi nomi non coincide esattamente con il file .sks, l'app crasherà (Fatal Error)
        ball = childNode(withName: "ball") as! SKSpriteNode
        leftPad = childNode(withName: "leftPad") as! SKSpriteNode
        rightPad = childNode(withName: "rightPad") as! SKSpriteNode
        launcher = childNode(withName: "launcher") as! SKSpriteNode
        score = childNode(withName: "score") as! SKLabelNode
        
        circle0 = childNode(withName: "circle0") as! SKSpriteNode
        circleA = childNode(withName: "circleA") as! SKSpriteNode
        
        circle1a = childNode(withName: "circle1a") as! SKSpriteNode
        circle1b = childNode(withName: "circle1b") as! SKSpriteNode
        circle1c = childNode(withName: "circle1c") as! SKSpriteNode
        
        circle2a = childNode(withName: "circle2a") as! SKSpriteNode
        circle2b = childNode(withName: "circle2b") as! SKSpriteNode
        circle2c = childNode(withName: "circle2c") as! SKSpriteNode
        circle2d = childNode(withName: "circle2d") as! SKSpriteNode
        
        star0 = childNode(withName: "star0") as! SKSpriteNode
        startMarker = childNode(withName: "startMarker") as! SKSpriteNode
        
        // --- PROPERTIES ---
        circleA.physicsBody?.categoryBitMask = circleA_1Category
        
        // Restituzione (Elasticità): determina quanto rimbalza la pallina
        leftPad.physicsBody?.restitution = 0.5
        rightPad.physicsBody?.restitution = 0.5
        circle0.physicsBody?.restitution = 2.5
        circle1a.physicsBody?.restitution = 2.0
        circle1b.physicsBody?.restitution = 2.0
        circle1c.physicsBody?.restitution = 2.0
        circle2a.physicsBody?.restitution = 1.5
        circle2b.physicsBody?.restitution = 1.5
        circle2c.physicsBody?.restitution = 1.5
        circle2d.physicsBody?.restitution = 1.5
        
        // --- ACTIONS SETUP ---
        
        // Animazioni e suoni per i bumper (Circles)
        let blink0Action = SKAction.animate(with: ["StarBlueYellow", "StarBlueOrange", "StarBlueRed", "StarBlueYellow"], timePerFrame: 0.1)
        circle0Blink = SKAction.group([blink0Action, SKAction.playSoundFileNamed("circle0", waitForCompletion: false)])
        
        let blink1Action = SKAction.animate(with: ["StarBlueOrange", "StarBlueRed", "StarBlueYellow", "StarBluePurple", "StarBlueOrange"], timePerFrame: 0.1)
        circle1Blink = SKAction.group([blink1Action, SKAction.playSoundFileNamed("circle1", waitForCompletion: false)])
        
        let blink2Action = SKAction.animate(with: ["StarBlueCyan", "StarBlueOrange", "StarBlueWhite", "StarBluePurple", "StarBlueCyan"], timePerFrame: 0.1)
        circle2Blink = SKAction.group([blink2Action, SKAction.playSoundFileNamed("circle2", waitForCompletion: false)])
        
        // Calcolo rotazione flipper in radianti
        // Formula: $\theta_{rad} = \theta_{deg} \cdot \frac{\pi}{180}$
        let leftDownAction = SKAction.rotate(toAngle: CGFloat(-35 * Double.pi / 180), duration: 0.1)
        leftDownLoop = leftDownAction
        
        let rightDownAction = SKAction.rotate(toAngle: CGFloat(215 * Double.pi / 180), duration: 0.1)
        rightDownLoop = rightDownAction
        
        // Launcher e suoni generali
        let launchAnim = SKAction.animate(with: ["launcher", "launcher1", "launcher"], timePerFrame: 0.2)
        launchBallAction = SKAction.group([launchAnim, SKAction.playSoundFileNamed("circle0", waitForCompletion: false)])
        
        loseSound = SKAction.playSoundFileNamed("error", waitForCompletion: false)
        padSound = SKAction.playSoundFileNamed("pad", waitForCompletion: false)
        dingSound = SKAction.playSoundFileNamed("ding", waitForCompletion: false)
    }
    
    
    /*override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let touch = touches.first
        let touchLocation = touch!.location(in: self)
        
        if startMode {
            if touchLocation.x < 0 {
                launcher.run(launchBallAction, completion: {self.ball.physicsBody?.applyImpulse(CGVector(dx: 0, dy: 500))})
                startMode = false
            }
        }else {
            if touchLocation.x < 0 {
                if !leftUp {
                    leftPad.physicsBody?.applyAngularImpulse(7)
                    leftUp = true
                    leftPad.run(padSound)
                }
                
            }else if touchLocation.x > 0 {
                if !rightUp {
                    rightPad.physicsBody?.applyAngularImpulse(7)
                    rightUp = true
                    rightPad.run(padSound)
                }
            }
        }
    }
    
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        let touch = touches.first
        let touchLocation = touch!.location(in: self)
        
        if touchLocation.x < 0 {
            if leftUp {
                leftPad.run(leftDownLoop, completion: {self.leftUp = false})
            }
        }else if touchLocation.x > 0 {
            if rightUp {
                rightPad.run(rightDownLoop, completion: {self.rightUp = false})
            }
        }
    }*/
    
    func didBegin(_ contact: SKPhysicsContact) {
        let sum = (contact.bodyA.node?.physicsBody?.categoryBitMask)! + (contact.bodyB.node?.physicsBody?.categoryBitMask)!
        switch sum {
        case upperStopCategory + leftpad_rightpadCategory: //8 + 2
            if (contact.bodyA.node?.name == "leftPad"){
                leftUp = true
                padStop(node: contact.bodyA.node!)
            } else if (contact.bodyB.node?.name == "leftPad"){
                leftUp = true
                padStop(node: contact.bodyB.node!)
            } else if (contact.bodyA.node?.name == "rightPad"){
                rightUp = true
                padStop(node: contact.bodyA.node!)
            } else if (contact.bodyB.node?.name == "rightPad"){
                rightUp = true
                padStop(node: contact.bodyB.node!)
            }
        case outLimitCategory + ballCategory: //4096 + 1
            ball.run(loseSound)
            ball.run(SKAction.move(to: startMarker.position, duration: 0))
            startMode = true
            star0.isHidden = false
            circleA.physicsBody?.categoryBitMask = circleA_1Category  //0
            
        case circle0Category + ballCategory: //32 + 1
            scManager.incScore(points: 10)
            circle0.run(circle0Blink)
            
        case circle1Category + ballCategory: //64 + 1
            let node = (contact.bodyA.node?.physicsBody?.categoryBitMask == circle1Category) ? contact.bodyA.node : contact.bodyB.node
            scManager.incScore(points: 20)
            node!.run(circle1Blink)
            
        case circle2Category + ballCategory:  //128 + 1
            let node = (contact.bodyA.node?.physicsBody?.categoryBitMask == circle2Category) ? contact.bodyA.node : contact.bodyB.node
            scManager.incScore(points: 30)
            node!.run(circle2Blink)
            
        case star0_star5Category + ballCategory: //256 + 1
            let node = (contact.bodyA.node?.physicsBody?.categoryBitMask == star0_star5Category) ? contact.bodyA.node : contact.bodyB.node
            if node?.name != "star0" {
                node?.isHidden = true
                scManager.incScore(points: 100)
                ball.run(dingSound)
            }
        case circleA_2Category + ballCategory:   //512 + 1
            scManager.incScore(points: 40)
            circleA.run(circle0Blink)
            
        default:
            print("no action")
        }
        score.text = String(scManager.getScore())
    }
    
    
    func didEnd(_ contact: SKPhysicsContact) {
        let sum = (contact.bodyA.node?.physicsBody?.categoryBitMask)! + (contact.bodyB.node?.physicsBody?.categoryBitMask)!
        if sum == star0_star5Category + ballCategory {  //256 + 1
            let node = (contact.bodyA.node?.physicsBody?.categoryBitMask == star0_star5Category) ? contact.bodyA.node : contact.bodyB.node
            if node?.name == "star0" {
                node?.isHidden = true
                if (circleA.physicsBody?.categoryBitMask != circleA_2Category){
                    circleA.physicsBody?.categoryBitMask = circleA_2Category
                }
            }
        }
    }
    
    
    
    func padStop(node:  SKNode){
        node.physicsBody!.angularVelocity = 0
        node.physicsBody!.velocity = CGVector(dx: 0, dy: 0)
    }
    
    
    
    override func update(_ currentTime: TimeInterval) {
        // Inizializzazione del tempo al primo frame
        if lastTime == 0 {
            lastTime = currentTime
        }

        // Controlla il movimento ogni 0.1 secondi per evitare scatti (throttling)
        if currentTime - lastTime > 0.1 {
            let deltaScroll = scroll - lastScroll
            lastScroll = scroll
            lastTime = currentTime

            if startMode {
                // Se siamo all'inizio e la corona viene ruotata, lancia la pallina
                if deltaScroll != 0 {
                    launcher.run(launchBallAction, completion: {
                        self.ball.physicsBody?.applyImpulse(CGVector(dx: 0, dy: 500))
                    })
                    startMode = false
                }
            } else {
                // Logica dei flipper (pad)
                if deltaScroll < 0 {
                    // Ruotando in un senso, i flipper salgono
                    if !leftUp {
                        leftPad.physicsBody?.applyAngularImpulse(7)
                        leftUp = true
                        leftPad.run(padSound)
                        
                        rightPad.physicsBody?.applyAngularImpulse(7)
                        rightUp = true
                        rightPad.run(padSound)
                    }
                } else if deltaScroll > 0 {
                    // Ruotando nell'altro senso, i flipper scendono
                    if leftUp {
                        rightPad.run(rightDownLoop, completion: { self.rightUp = false })
                        leftPad.run(leftDownLoop, completion: { self.leftUp = false })
                    }
                }
            }
        }
    }

}


extension SKAction {
    static func animate(with: [String], timePerFrame: Double)->SKAction{
        var textureArray =  [SKTexture]()
        for im in with {
            textureArray.append(SKTexture(imageNamed: im))
        }
        
        let action = SKAction.animate(with: textureArray, timePerFrame: timePerFrame)
        return action
    }
}


class scoreManager{
    var score = 0
    
    func resetScore(){
        score = 0
    }
    
    func incScore(points: Int){
        score += points
    }
    
    func getScore()->Int {
        return score
    }
}
