//
//  GameScene.swift
//  iPinballTV
//
//  Created by Ignazio Finizio on 16/01/22.
//

import SpriteKit
import UIKit

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    // MARK: - constants
    
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
    
    // MARK: - vars
    
    var startMode = true
    var leftUp = false
    var rightUp = false
    var gesturesInstalled = false
    
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
    
    // MARK: - score manager
    
    let scManager = scoreManager()
    
    // MARK: - lifecycle
    
    override func sceneDidLoad() {
        super.sceneDidLoad()
        
        physicsWorld.contactDelegate = self
        
        // bordo fisico scena
        self.physicsBody = SKPhysicsBody(edgeLoopFrom: self.frame)
        
        // nodes
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
        
        // properties
        circleA.physicsBody?.categoryBitMask = circleA_1Category
        
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
        
        // actions
        let blink0Action = SKAction.animate(
            with: ["StarBlueYellow", "StarBlueOrange", "StarBlueRed", "StarBlueYellow"],
            timePerFrame: 0.1
        )
        circle0Blink = SKAction.group([
            blink0Action,
            SKAction.playSoundFileNamed("circle0", waitForCompletion: false)
        ])
        
        let blink1Action = SKAction.animate(
            with: ["StarBlueOrange", "StarBlueRed", "StarBlueYellow", "StarBluePurple", "StarBlueOrange"],
            timePerFrame: 0.1
        )
        circle1Blink = SKAction.group([
            blink1Action,
            SKAction.playSoundFileNamed("circle1", waitForCompletion: false)
        ])
        
        let blink2Action = SKAction.animate(
            with: ["StarBlueCyan", "StarBlueOrange", "StarBlueWhite", "StarBluePurple", "StarBlueCyan"],
            timePerFrame: 0.1
        )
        circle2Blink = SKAction.group([
            blink2Action,
            SKAction.playSoundFileNamed("circle2", waitForCompletion: false)
        ])
        
        let leftDownAction = SKAction.rotate(toAngle: CGFloat(-35 * Double.pi / 180), duration: 0.1)
        leftDownLoop = leftDownAction
        
        let rightDownAction = SKAction.rotate(toAngle: CGFloat(215 * Double.pi / 180), duration: 0.1)
        rightDownLoop = rightDownAction
        
        let launchAnim = SKAction.animate(with: ["launcher", "launcher1", "launcher"], timePerFrame: 0.2)
        launchBallAction = SKAction.group([
            launchAnim,
            SKAction.playSoundFileNamed("circle0", waitForCompletion: false)
        ])
        
        loseSound = SKAction.playSoundFileNamed("error", waitForCompletion: false)
        padSound = SKAction.playSoundFileNamed("pad", waitForCompletion: false)
        dingSound = SKAction.playSoundFileNamed("ding", waitForCompletion: false)
        
        score.text = String(scManager.getScore())
    }
    
    override func didMove(to view: SKView) {
        super.didMove(to: view)
        
        guard !gesturesInstalled else { return }
        gesturesInstalled = true
        
        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(swipedRight))
        swipeRight.direction = .right
        view.addGestureRecognizer(swipeRight)
        
        let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(swipedLeft))
        swipeLeft.direction = .left
        view.addGestureRecognizer(swipeLeft)
        
        let swipeUp = UISwipeGestureRecognizer(target: self, action: #selector(swipedUp))
        swipeUp.direction = .up
        view.addGestureRecognizer(swipeUp)
        
        let swipeDown = UISwipeGestureRecognizer(target: self, action: #selector(swipedDown))
        swipeDown.direction = .down
        view.addGestureRecognizer(swipeDown)
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(tapped))
        view.addGestureRecognizer(tap)
    }
    
    // MARK: - apple tv remote controls
    
    @objc func swipedUp() {
        if startMode {
            launchBall()
        } else {
            raiseBothPads()
        }
    }
    
    @objc func swipedDown() {
        lowerBothPads()
    }
    
    @objc func swipedLeft() {
        triggerLeftPad()
    }
    
    @objc func swipedRight() {
        triggerRightPad()
    }
    
    @objc func tapped() {
        if startMode {
            launchBall()
        } else {
            raiseBothPads()
        }
    }
    
    // MARK: - game controls
    
    func launchBall() {
        guard startMode else { return }
        
        launcher.run(launchBallAction) { [weak self] in
            self?.ball.physicsBody?.applyImpulse(CGVector(dx: 0, dy: 500))
        }
        startMode = false
    }
    
    func raiseBothPads() {
        if !leftUp {
            leftPad.physicsBody?.applyAngularImpulse(7)
            leftUp = true
            leftPad.run(padSound)
        }
        
        if !rightUp {
            rightPad.physicsBody?.applyAngularImpulse(7)
            rightUp = true
            rightPad.run(padSound)
        }
    }
    
    func lowerBothPads() {
        if leftUp {
            leftPad.run(leftDownLoop) { [weak self] in
                self?.leftUp = false
            }
        }
        
        if rightUp {
            rightPad.run(rightDownLoop) { [weak self] in
                self?.rightUp = false
            }
        }
    }
    
    func triggerLeftPad() {
        if startMode { return }
        
        if !leftUp {
            leftPad.physicsBody?.applyAngularImpulse(7)
            leftUp = true
            leftPad.run(padSound)
        } else {
            leftPad.run(leftDownLoop) { [weak self] in
                self?.leftUp = false
            }
        }
    }
    
    func triggerRightPad() {
        if startMode { return }
        
        if !rightUp {
            rightPad.physicsBody?.applyAngularImpulse(7)
            rightUp = true
            rightPad.run(padSound)
        } else {
            rightPad.run(rightDownLoop) { [weak self] in
                self?.rightUp = false
            }
        }
    }
    
    // MARK: - physics contacts
    
    func didBegin(_ contact: SKPhysicsContact) {
        let sum = (contact.bodyA.node?.physicsBody?.categoryBitMask)! + (contact.bodyB.node?.physicsBody?.categoryBitMask)!
        
        switch sum {
        case upperStopCategory + leftpad_rightpadCategory:
            if contact.bodyA.node?.name == "leftPad" {
                leftUp = true
                padStop(node: contact.bodyA.node!)
            } else if contact.bodyB.node?.name == "leftPad" {
                leftUp = true
                padStop(node: contact.bodyB.node!)
            } else if contact.bodyA.node?.name == "rightPad" {
                rightUp = true
                padStop(node: contact.bodyA.node!)
            } else if contact.bodyB.node?.name == "rightPad" {
                rightUp = true
                padStop(node: contact.bodyB.node!)
            }
            
        case outLimitCategory + ballCategory:
            ball.run(loseSound)
            ball.run(SKAction.move(to: startMarker.position, duration: 0))
            startMode = true
            leftUp = false
            rightUp = false
            star0.isHidden = false
            circleA.physicsBody?.categoryBitMask = circleA_1Category
            
        case circle0Category + ballCategory:
            scManager.incScore(points: 10)
            circle0.run(circle0Blink)
            
        case circle1Category + ballCategory:
            let node = (contact.bodyA.node?.physicsBody?.categoryBitMask == circle1Category) ? contact.bodyA.node : contact.bodyB.node
            scManager.incScore(points: 20)
            node?.run(circle1Blink)
            
        case circle2Category + ballCategory:
            let node = (contact.bodyA.node?.physicsBody?.categoryBitMask == circle2Category) ? contact.bodyA.node : contact.bodyB.node
            scManager.incScore(points: 30)
            node?.run(circle2Blink)
            
        case star0_star5Category + ballCategory:
            let node = (contact.bodyA.node?.physicsBody?.categoryBitMask == star0_star5Category) ? contact.bodyA.node : contact.bodyB.node
            if node?.name != "star0" {
                node?.isHidden = true
                scManager.incScore(points: 100)
                ball.run(dingSound)
            }
            
        case circleA_2Category + ballCategory:
            scManager.incScore(points: 40)
            circleA.run(circle0Blink)
            
        default:
            print("no action")
        }
        
        score.text = String(scManager.getScore())
    }
    
    func didEnd(_ contact: SKPhysicsContact) {
        let sum = (contact.bodyA.node?.physicsBody?.categoryBitMask)! + (contact.bodyB.node?.physicsBody?.categoryBitMask)!
        
        if sum == star0_star5Category + ballCategory {
            let node = (contact.bodyA.node?.physicsBody?.categoryBitMask == star0_star5Category) ? contact.bodyA.node : contact.bodyB.node
            if node?.name == "star0" {
                node?.isHidden = true
                if circleA.physicsBody?.categoryBitMask != circleA_2Category {
                    circleA.physicsBody?.categoryBitMask = circleA_2Category
                }
            }
        }
    }
    
    func padStop(node: SKNode) {
        node.physicsBody?.angularVelocity = 0
        node.physicsBody?.velocity = CGVector(dx: 0, dy: 0)
    }
    
    // MARK: - frame update
    
    override func update(_ currentTime: TimeInterval) {
        guard let body = ball.physicsBody else { return }
        
        let dx = body.velocity.dx
        let dy = body.velocity.dy
        let speed = sqrt(dx * dx + dy * dy)
        
        if speed > maxBallVelocity {
            let factor = maxBallVelocity / speed
            body.velocity = CGVector(dx: dx * factor, dy: dy * factor)
        }
    }
}

extension SKAction {
    static func animate(with: [String], timePerFrame: Double) -> SKAction {
        var textureArray = [SKTexture]()
        
        for im in with {
            textureArray.append(SKTexture(imageNamed: im))
        }
        
        return SKAction.animate(with: textureArray, timePerFrame: timePerFrame)
    }
}

class scoreManager {
    var score = 0
    
    func resetScore() {
        score = 0
    }
    
    func incScore(points: Int) {
        score += points
    }
    
    func getScore() -> Int {
        return score
    }
}
