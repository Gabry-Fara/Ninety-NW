//
//  GameScene.swift
//  pinballTemplate
//
//  Created by Ignazio Finizio on 16/01/23.
//

import SpriteKit
#if os(iOS)
import UIKit
#endif

// Score


// Define Physics Categories
struct PhysicsCategory {
    static let none: UInt32 = 0
    static let all: UInt32 = UInt32.max
    static let ball: UInt32 = 0x1 << 0
    static let flipper: UInt32 = 0x1 << 1
    static let wall: UInt32 = 0x1 << 2
    static let obstacle: UInt32 = 0x1 << 3
    static let pad: UInt32 = 0x1 << 4
    static let launcher: UInt32 = 0x1 << 5
    static let star: UInt32 = 0x1 << 6
}

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    var ball: SKSpriteNode?
    var leftFlipper: SKSpriteNode?
    var rightFlipper: SKSpriteNode?
    var launcher: SKSpriteNode?
    
    var score: Int = 0
    var scoreLabel: SKLabelNode?
    
    var leftFlipperOriginalRotation: CGFloat = 0
    var rightFlipperOriginalRotation: CGFloat = 0
    
    // Input state (touch + keyboard)
    var isTouchingLauncher = false
    var isLeftFlipperActive = false
    var isRightFlipperActive = false

    // Launcher charging variables
    var isCharging = false
    var currentLaunchPower: CGFloat = 0
    let maxLaunchPower: CGFloat = 600
    let launchPowerIncrement: CGFloat = 22
    var originalLauncherPosition: CGPoint = .zero
    
    var ballInitialPosition: CGPoint = .zero
    var ballHasPassedFlippers = false
    
    // Preload sounds to avoid freezing
    let dingSound = SKAction.playSoundFileNamed("ding.wav", waitForCompletion: false)
    let padSound = SKAction.playSoundFileNamed("pad.wav", waitForCompletion: false)
    let errorSound = SKAction.playSoundFileNamed("error.wav", waitForCompletion: false)
    let circle1Sound = SKAction.playSoundFileNamed("circle1.wav", waitForCompletion: false)
    
    override var canBecomeFirstResponder: Bool { true }
    
    override func didMove(to view: SKView) {
        // Setup Physics World
        physicsWorld.contactDelegate = self
        physicsWorld.gravity = CGVector(dx: 0, dy: -9.8)

        // Ensure this scene can receive keyboard events on macOS/iPad keyboard.
        isUserInteractionEnabled = true

        // Add top barrier to prevent ball from going off screen
        let topBarrier = SKNode()
        topBarrier.position = CGPoint(x: frame.midX, y: frame.maxY + 10)
        topBarrier.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: frame.width, height: 20))
        topBarrier.physicsBody?.isDynamic = false
        topBarrier.physicsBody?.categoryBitMask = PhysicsCategory.wall
        topBarrier.physicsBody?.collisionBitMask = PhysicsCategory.ball
        addChild(topBarrier)

        // Setup Ball
        if let ballNode = childNode(withName: "ironBall") as? SKSpriteNode {
            ball = ballNode
            if ball?.physicsBody == nil {
                ball?.physicsBody = SKPhysicsBody(circleOfRadius: max(ballNode.size.width, ballNode.size.height) * 0.45)
            }
            ball?.physicsBody?.categoryBitMask = PhysicsCategory.ball
            ball?.physicsBody?.contactTestBitMask = PhysicsCategory.star | PhysicsCategory.obstacle | PhysicsCategory.flipper
            ball?.physicsBody?.collisionBitMask = PhysicsCategory.all
            ball?.physicsBody?.usesPreciseCollisionDetection = true
            ball?.physicsBody?.friction = 0.2
            ball?.physicsBody?.restitution = 0.4
            ball?.physicsBody?.linearDamping = 0.1
            ball?.physicsBody?.angularDamping = 0.1
            ball?.zPosition = 10 // Ensure ball is on top
            ballInitialPosition = ballNode.position
        }
        
        // Setup Launcher
        if let launcherNode = childNode(withName: "//launcher") as? SKSpriteNode {
            launcher = launcherNode
            if launcher?.physicsBody == nil {
                launcher?.physicsBody = SKPhysicsBody(rectangleOf: launcherNode.size)
            }
            launcher?.physicsBody?.categoryBitMask = PhysicsCategory.launcher
            launcher?.physicsBody?.collisionBitMask = PhysicsCategory.ball
            launcher?.physicsBody?.isDynamic = false
            launcher?.zPosition = 5
            originalLauncherPosition = launcherNode.position
        }

        // Setup Flippers: accepts nodes named "Pad", "Flipper", or "bar"
        enumerateChildNodes(withName: "//*") { node, _ in
            guard let pad = node as? SKSpriteNode else { return }
            let raw = pad.name?.lowercased() ?? ""
            let looksLikeFlipper = raw.contains("pad") || raw.contains("flipper") || raw.contains("bar")
            guard looksLikeFlipper else { return }

            if pad.physicsBody == nil {
                pad.physicsBody = SKPhysicsBody(rectangleOf: pad.size)
            }
            pad.physicsBody?.categoryBitMask = PhysicsCategory.flipper
            pad.physicsBody?.collisionBitMask = PhysicsCategory.ball
            pad.physicsBody?.isDynamic = false
            pad.zPosition = 5

            if pad.position.x < 0 {
                if self.leftFlipper == nil {
                    self.leftFlipper = pad
                    self.leftFlipperOriginalRotation = pad.zRotation
                }
            } else {
                if self.rightFlipper == nil {
                    self.rightFlipper = pad
                    self.rightFlipperOriginalRotation = pad.zRotation
                }
            }
        }
        
        // Setup stars and obstacles
        let rotateAction = SKAction.repeatForever(SKAction.rotate(byAngle: .pi, duration: 4))
        enumerateChildNodes(withName: "//*") { node, _ in
            let raw = node.name?.lowercased() ?? ""
            if raw.contains("star") {
                if node.physicsBody == nil, let s = node as? SKSpriteNode {
                    node.physicsBody = SKPhysicsBody(circleOfRadius: max(s.size.width, s.size.height) * 0.45)
                }
                node.physicsBody?.categoryBitMask = PhysicsCategory.star
                node.physicsBody?.contactTestBitMask = PhysicsCategory.ball
                node.physicsBody?.isDynamic = false
                if node.action(forKey: "ambientRotate") == nil {
                    node.run(rotateAction, withKey: "ambientRotate")
                }
            } else if raw.contains("bar") || raw.contains("oval") || raw.contains("wall") || raw.contains("obstacle") || raw.contains("border") {
                if node.physicsBody == nil, let s = node as? SKSpriteNode {
                    node.physicsBody = SKPhysicsBody(rectangleOf: s.size)
                }
                node.physicsBody?.categoryBitMask = PhysicsCategory.obstacle
                node.physicsBody?.collisionBitMask = PhysicsCategory.ball
                node.physicsBody?.contactTestBitMask = PhysicsCategory.ball
                node.physicsBody?.isDynamic = false
            }
        }

        // Debug print
        print("Ball found: \(ball != nil)")
        print("Launcher found: \(launcher != nil)")
        print("Left Flipper found: \(leftFlipper != nil)")
        print("Right Flipper found: \(rightFlipper != nil)")
        
        // Setup Score Label
        let label = SKLabelNode(fontNamed: "AvenirNext-Bold")
        label.text = "Score: 0"
        label.fontSize = 28
        label.fontColor = .white
        label.position = CGPoint(x: frame.midX, y: frame.maxY - 60)
        label.zPosition = 20
        addChild(label)
        scoreLabel = label
    }
    
    func addScore(_ points: Int) {
        score += points
        scoreLabel?.text = "Score: \(score)"
        // Pulse animation
        let scaleUp = SKAction.scale(to: 1.3, duration: 0.08)
        let scaleDown = SKAction.scale(to: 1.0, duration: 0.08)
        scoreLabel?.run(SKAction.sequence([scaleUp, scaleDown]))
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let location = touch.location(in: self)
            if let launcher = launcher, launcher.contains(location) {
                startCharging()
            } else if location.x < 0 {
                setLeftFlipper(active: true)
            } else {
                setRightFlipper(active: true)
            }
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        endAllTouchInput()
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        endAllTouchInput()
    }

    // Enable keyboard interactions
    #if os(iOS)
    override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        for press in presses {
            guard let key = press.key else { continue }
            switch key.keyCode {
            case .keyboardLeftArrow:
                setLeftFlipper(active: true)
            case .keyboardRightArrow:
                setRightFlipper(active: true)
            case .keyboardSpacebar:
                startCharging()
            default:
                super.pressesBegan(presses, with: event)
            }
        }
    }

    override func pressesEnded(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        for press in presses {
            guard let key = press.key else { continue }
            switch key.keyCode {
            case .keyboardLeftArrow:
                setLeftFlipper(active: false)
            case .keyboardRightArrow:
                setRightFlipper(active: false)
            case .keyboardSpacebar:
                launchBall()
            default:
                super.pressesEnded(presses, with: event)
            }
        }
    }
    #endif

    #if os(macOS)
    override func keyDown(with event: NSEvent) {
        switch event.keyCode {
        case 123: // left arrow
            setLeftFlipper(active: true)
        case 124: // right arrow
            setRightFlipper(active: true)
        case 49: // space
            startCharging()
        default:
            break
        }
    }

    override func keyUp(with event: NSEvent) {
        switch event.keyCode {
        case 123: // left arrow
            setLeftFlipper(active: false)
        case 124: // right arrow
            setRightFlipper(active: false)
        case 49: // space
            launchBall()
        default:
            break
        }
    }
    #endif
    
    override func update(_ currentTime: TimeInterval) {
        if isCharging {
            currentLaunchPower = min(maxLaunchPower, currentLaunchPower + launchPowerIncrement)
            if let launcher = launcher {
                let offset = (currentLaunchPower / maxLaunchPower) * 50
                launcher.position = CGPoint(x: originalLauncherPosition.x, y: originalLauncherPosition.y - offset)
            }
        }

        // Reset ball if it passes under flippers
        if let ball = ball, let left = leftFlipper, let right = rightFlipper, !ballHasPassedFlippers {
            let flipperY = min(left.position.y, right.position.y) - 50
            let leftX = min(left.position.x, right.position.x)
            let rightX = max(left.position.x, right.position.x)
            if ball.position.y < flipperY && ball.position.x > leftX && ball.position.x < rightX {
                ball.position = ballInitialPosition
                ball.physicsBody?.velocity = .zero
                ball.physicsBody?.angularVelocity = 0
                ballHasPassedFlippers = true
                run(errorSound)
                addScore(-50)
            }
        }
    }
    
    func launchBall() {
        guard isCharging else { return }
        isCharging = false

        if let launcher = launcher {
            let moveAction = SKAction.move(to: originalLauncherPosition, duration: 0.06)
            launcher.run(moveAction)
        }

        if let ball = ball {
            let dx = abs(ball.position.x - originalLauncherPosition.x)
            let dy = ball.position.y - originalLauncherPosition.y
            
            // Allow launching if the ball is inside the launcher lane
            if dx < 50 && dy > -100 && dy < 150 {
                ball.physicsBody?.applyImpulse(CGVector(dx: 0, dy: max(280, currentLaunchPower)))
                run(dingSound)
            }
        }

        currentLaunchPower = 0
        ballHasPassedFlippers = false // Reset flag for new ball
    }
    
    enum FlipperDirection {
        case left, right
    }
    
    func flip(flipper: SKSpriteNode?, direction: FlipperDirection) {
        guard let flipper = flipper else { return }
        let rotationAmount: CGFloat = 0.85

        let newAngle: CGFloat = (direction == .left)
            ? self.leftFlipperOriginalRotation + rotationAmount
            : self.rightFlipperOriginalRotation - rotationAmount

        flipper.removeAction(forKey: "flipperMove")
        let rotateAction = SKAction.rotate(toAngle: newAngle, duration: 0.07, shortestUnitArc: true)
        flipper.run(rotateAction, withKey: "flipperMove")
        run(padSound)
    }
    
    func unflip(flipper: SKSpriteNode?, originalRotation: CGFloat) {
        guard let flipper = flipper else { return }
        flipper.removeAction(forKey: "flipperMove")
        let rotateAction = SKAction.rotate(toAngle: originalRotation, duration: 0.09, shortestUnitArc: true)
        flipper.run(rotateAction, withKey: "flipperMove")
    }

    func didBegin(_ contact: SKPhysicsContact) {
        // Handle collisions
        var firstBody: SKPhysicsBody
        var secondBody: SKPhysicsBody
        
        if contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask {
            firstBody = contact.bodyA
            secondBody = contact.bodyB
        } else {
            firstBody = contact.bodyB
            secondBody = contact.bodyA
        }
        
        // Ball hitting Flipper
        if firstBody.categoryBitMask == PhysicsCategory.ball && secondBody.categoryBitMask == PhysicsCategory.flipper {
            if let ballBody = firstBody.node?.physicsBody {
                ballBody.applyImpulse(CGVector(dx: 0, dy: 800))
                run(padSound)
                addScore(5)
            }
        }

        // Ball hitting Star
        if firstBody.categoryBitMask == PhysicsCategory.ball && secondBody.categoryBitMask == PhysicsCategory.star {
            if let starNode = secondBody.node {
                if starNode.action(forKey: "starHit") == nil {
                    let scaleUp = SKAction.scale(to: 1.2, duration: 0.1)
                    let scaleDown = SKAction.scale(to: 1.0, duration: 0.1)
                    starNode.run(SKAction.sequence([scaleUp, scaleDown]), withKey: "starHit")
                    run(dingSound)
                    addScore(100)
                }
            }
        }

        // Ball hitting Obstacle
        if firstBody.categoryBitMask == PhysicsCategory.ball && secondBody.categoryBitMask == PhysicsCategory.obstacle {
            run(circle1Sound)
            addScore(10)
        }
    }
    
    private func setLeftFlipper(active: Bool) {
        guard isLeftFlipperActive != active else { return }
        isLeftFlipperActive = active
        if active {
            flip(flipper: leftFlipper, direction: .left)
        } else {
            unflip(flipper: leftFlipper, originalRotation: leftFlipperOriginalRotation)
        }
    }

    private func setRightFlipper(active: Bool) {
        guard isRightFlipperActive != active else { return }
        isRightFlipperActive = active
        if active {
            flip(flipper: rightFlipper, direction: .right)
        } else {
            unflip(flipper: rightFlipper, originalRotation: rightFlipperOriginalRotation)
        }
    }

    private func startCharging() {
        guard !isCharging else { return }
        isCharging = true
        currentLaunchPower = 0
        isTouchingLauncher = true
    }

    private func endAllTouchInput() {
        setLeftFlipper(active: false)
        setRightFlipper(active: false)
        if isCharging {
            launchBall()
        }
        isTouchingLauncher = false
    }
}

