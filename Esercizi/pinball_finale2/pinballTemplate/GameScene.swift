//
//  GameScene.swift
//  pinballTemplate
//

import SpriteKit
#if os(iOS)
import UIKit
#endif

struct PhysicsCategory {
    static let none: UInt32 = 0
    static let all: UInt32 = UInt32.max
    static let ball: UInt32 = 0x1 << 0      // 1
    static let flipper: UInt32 = 0x1 << 1   // 2
    static let wall: UInt32 = 0x1 << 2      // 4
    static let obstacle: UInt32 = 0x1 << 3  // 8
    static let pad: UInt32 = 0x1 << 4       // 16
    static let launcher: UInt32 = 0x1 << 5  // 32
    static let star: UInt32 = 0x1 << 8      // 256
}

class GameScene: SKScene, SKPhysicsContactDelegate {

    var ball: SKSpriteNode?
    var leftFlipper: SKSpriteNode?
    var rightFlipper: SKSpriteNode?
    var launcher: SKSpriteNode?
    var scoreLabel: SKLabelNode?

    var leftFlipperOriginalRotation: CGFloat = 0
    var rightFlipperOriginalRotation: CGFloat = 0

    var isTouchingLauncher = false
    var isLeftFlipperActive = false
    var isRightFlipperActive = false

    var isCharging = false
    var currentLaunchPower: CGFloat = 0
    let maxLaunchPower: CGFloat = 600
    let launchPowerIncrement: CGFloat = 22
    var originalLauncherPosition: CGPoint = .zero

    var ballInitialPosition: CGPoint = .zero
    var ballHasPassedFlippers = false
    var score = 0
    var ballLaunched = false

    override var canBecomeFirstResponder: Bool { true }

    override func didMove(to view: SKView) {
        super.didMove(to: view)

        physicsWorld.contactDelegate = self
        physicsWorld.gravity = CGVector(dx: 0.35, dy: -4.5)

        isUserInteractionEnabled = true

        #if os(iOS)
        view.becomeFirstResponder()
        #endif
        #if os(macOS)
        view.window?.makeFirstResponder(view)
        #endif

        // Barriera superiore
        let topBarrier = SKNode()
        topBarrier.position = CGPoint(x: frame.midX, y: frame.maxY + 10)
        topBarrier.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: frame.width, height: 20))
        topBarrier.physicsBody?.isDynamic = false
        topBarrier.physicsBody?.categoryBitMask = PhysicsCategory.wall
        topBarrier.physicsBody?.collisionBitMask = PhysicsCategory.ball
        addChild(topBarrier)

        // Pallina
        if let ballNode = childNode(withName: "ironBall") as? SKSpriteNode {
            ball = ballNode
            if ball?.physicsBody == nil {
                ball?.physicsBody = SKPhysicsBody(circleOfRadius: max(ballNode.size.width, ballNode.size.height) * 0.45)
            }
            ball?.physicsBody?.categoryBitMask = PhysicsCategory.ball
            ball?.physicsBody?.contactTestBitMask = PhysicsCategory.flipper | PhysicsCategory.star | PhysicsCategory.obstacle
            ball?.physicsBody?.collisionBitMask = PhysicsCategory.all
            ball?.physicsBody?.usesPreciseCollisionDetection = true
            ball?.physicsBody?.restitution = 0.42
            ball?.physicsBody?.friction = 0.15
            ball?.physicsBody?.linearDamping = 0.03
            ball?.physicsBody?.angularDamping = 0.12
            ball?.physicsBody?.allowsRotation = true
            ball?.zPosition = 10
            ballInitialPosition = ballNode.position
        }

        // Launcher
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

        // Flippers
        enumerateChildNodes(withName: "//*") { node, _ in
            guard let pad = node as? SKSpriteNode else { return }
            let raw = pad.name?.lowercased() ?? ""
            guard raw.contains("pad") || raw.contains("flipper") || raw.contains("bar") else { return }

            if pad.physicsBody == nil {
                pad.physicsBody = SKPhysicsBody(rectangleOf: pad.size)
            }
            pad.physicsBody?.categoryBitMask = PhysicsCategory.flipper
            pad.physicsBody?.collisionBitMask = PhysicsCategory.ball
            pad.physicsBody?.contactTestBitMask = PhysicsCategory.ball
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

        // Stelle e ostacoli
        enumerateChildNodes(withName: "//*") { node, _ in
            let raw = node.name?.lowercased() ?? ""
            if raw.contains("star") {
                if node.physicsBody == nil, let s = node as? SKSpriteNode {
                    node.physicsBody = SKPhysicsBody(circleOfRadius: max(s.size.width, s.size.height) * 0.45)
                }
                node.physicsBody?.categoryBitMask = PhysicsCategory.star
                node.physicsBody?.contactTestBitMask = PhysicsCategory.ball
                node.physicsBody?.collisionBitMask = PhysicsCategory.all
                node.physicsBody?.isDynamic = false
            } else if raw.contains("oval") || raw.contains("wall") || raw.contains("obstacle") || raw.contains("border") || raw.contains("stelle") {
                if node.physicsBody == nil, let s = node as? SKSpriteNode {
                    node.physicsBody = SKPhysicsBody(rectangleOf: s.size)
                }
                node.physicsBody?.categoryBitMask = PhysicsCategory.obstacle
                node.physicsBody?.collisionBitMask = PhysicsCategory.ball
                node.physicsBody?.contactTestBitMask = PhysicsCategory.ball
                node.physicsBody?.isDynamic = false
            }
        }

        scoreLabel = SKLabelNode(text: "Score: 0")
        scoreLabel?.fontName = "HelveticaNeue-Bold"
        scoreLabel?.fontSize = 48
        scoreLabel?.fontColor = .white
        scoreLabel?.position = CGPoint(x: frame.midX, y: frame.maxY - 80)
        scoreLabel?.zPosition = 15
        if let scoreLabel = scoreLabel { addChild(scoreLabel) }

        #if os(macOS)
        NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .keyUp]) { [weak self] event in
            guard let self = self else { return event }
            let chars = event.charactersIgnoringModifiers?.lowercased() ?? ""
            let isDown = (event.type == .keyDown)
            if event.keyCode == 123 || chars == "a" {
                self.setLeftFlipper(active: isDown)
            } else if event.keyCode == 124 || chars == "d" {
                self.setRightFlipper(active: isDown)
            } else if event.keyCode == 49 || chars == "w" || chars == "s" {
                if isDown { if !event.isARepeat { self.startCharging() } }
                else { self.launchBall() }
            }
            return event
        }
        #endif
    }

    // MARK: - Update

    override func update(_ currentTime: TimeInterval) {
        if isCharging {
            currentLaunchPower = min(maxLaunchPower, currentLaunchPower + launchPowerIncrement)
            if let launcher = launcher {
                let offset = (currentLaunchPower / maxLaunchPower) * 50
                launcher.position = CGPoint(x: originalLauncherPosition.x,
                                            y: originalLauncherPosition.y - offset)
            }
        }

        if let ball = ball, let left = leftFlipper, let right = rightFlipper, !ballHasPassedFlippers {
            let flipperY = min(left.position.y, right.position.y) - 50
            let leftX   = min(left.position.x, right.position.x)
            let rightX  = max(left.position.x, right.position.x)
            
            if ball.position.y < flipperY && ball.position.x > leftX && ball.position.x < rightX {
                // RESET SCORE QUANDO LA PALLINA CADE
                score = 0
                scoreLabel?.text = "Score: 0"
                
                ball.position = ballInitialPosition
                ball.physicsBody?.velocity = .zero
                ball.physicsBody?.angularVelocity = 0
                ballHasPassedFlippers = true
                ballLaunched = false
                run(SKAction.playSoundFileNamed("error.wav", waitForCompletion: false))
            }
        }
    }

    // MARK: - Contacts

    func didBegin(_ contact: SKPhysicsContact) {
        var first  = contact.bodyA
        var second = contact.bodyB

        if first.categoryBitMask > second.categoryBitMask {
            swap(&first, &second)
        }

        // --- STAR COLLISION ---
        if first.categoryBitMask == PhysicsCategory.ball &&
           second.categoryBitMask == PhysicsCategory.star {

            guard let star = second.node as? SKSpriteNode else { return }
            
            // AGGIUNTA PUNTI (Eseguita per ogni collisione con una stella)
            score += 10
            scoreLabel?.text = "Score: \(score)"
            
            let name = (star.name ?? "").lowercased()
            let isStarGray = star.texture?.description.contains("StarGray") ?? false

            if name.contains("white") || isStarGray {
                // Sparisce immediatamente
                star.physicsBody = nil
                let removeEffect = SKAction.sequence([
                    SKAction.group([
                        SKAction.fadeOut(withDuration: 0.1),
                        SKAction.scale(to: 1.4, duration: 0.1)
                    ]),
                    SKAction.removeFromParent()
                ])
                star.run(removeEffect)
                run(SKAction.playSoundFileNamed("ding.wav", waitForCompletion: false))
            } else {
                // Altre stelle (incluse StarBlueOrange)
                let blink = SKAction.sequence([
                    SKAction.colorize(with: .white, colorBlendFactor: 0.9, duration: 0.05),
                    SKAction.colorize(with: .clear, colorBlendFactor: 0, duration: 0.15)
                ])
                star.run(blink)
                run(SKAction.playSoundFileNamed("ding.wav", waitForCompletion: false))
            }
            return
        }

        // --- FLIPPER HIT ---
        if first.categoryBitMask == PhysicsCategory.ball &&
           second.categoryBitMask == PhysicsCategory.flipper {
            guard let ballBody = first.node?.physicsBody, let flipNode = second.node else { return }
            let isActive = (flipNode == leftFlipper) ? isLeftFlipperActive : isRightFlipperActive
            if isActive {
                let impulse = CGVector(dx: (flipNode == leftFlipper) ? 60 : -60, dy: 220)
                ballBody.applyImpulse(impulse)
                run(SKAction.playSoundFileNamed("pad.wav", waitForCompletion: false))
            }
            return
        }

        // --- OBSTACLE HIT ---
        if first.categoryBitMask == PhysicsCategory.ball &&
           second.categoryBitMask == PhysicsCategory.obstacle {
            guard let sprite = second.node as? SKSpriteNode else { return }

            // Incrementa score solo per ostacoli specifici: name "stelle" e texture "StarBlueOrange"
            let spriteName = (sprite.name ?? "").lowercased()
            let texDesc = sprite.texture?.description ?? ""

            if spriteName.contains("stelle") && texDesc.contains("StarBlueOrange") {
                score += 10
                scoreLabel?.text = "Score: \(score)"

                // Assicuriamoci di salvare le dimensioni originali del nodo dallo Scene Editor in un userData
                if sprite.userData == nil {
                    sprite.userData = NSMutableDictionary()
                    sprite.userData?["origScaleX"] = sprite.xScale
                    sprite.userData?["origScaleY"] = sprite.yScale
                }
                
                let origX = sprite.userData?["origScaleX"] as? CGFloat ?? sprite.xScale
                let origY = sprite.userData?["origScaleY"] as? CGFloat ?? sprite.yScale

                // Animazione di ingrandimento temporaneo basato sulla VERA scala originale
                let scaleUp = SKAction.scaleX(to: origX * 1.3, y: origY * 1.3, duration: 0.05)
                let wait = SKAction.wait(forDuration: 0.15)
                let scaleDown = SKAction.scaleX(to: origX, y: origY, duration: 0.15)
                
                // Annulla eventuali animazioni precedenti per non accavallarle
                sprite.removeAction(forKey: "hitScale")
                sprite.run(SKAction.sequence([scaleUp, wait, scaleDown]), withKey: "hitScale")

                // Fai schizzare via la pallina calcolando la direzione d'uscita
                if let ballBody = first.node?.physicsBody, let ballNode = first.node {
                    let dx = ballNode.position.x - sprite.position.x
                    let dy = ballNode.position.y - sprite.position.y
                    let length = max(sqrt(dx*dx + dy*dy), 0.1)
                    
                    // Applica un forte impulso radiale
                    ballBody.applyImpulse(CGVector(dx: (dx/length) * 400, dy: (dy/length) * 400))
                }
            }

            let blink = SKAction.sequence([
                SKAction.colorize(with: .white, colorBlendFactor: 0.9, duration: 0.05),
                SKAction.colorize(with: .clear, colorBlendFactor: 0.0, duration: 0.15)
            ])
            sprite.run(blink)
            run(SKAction.playSoundFileNamed("circle1.wav", waitForCompletion: false))
        }
    }

    // MARK: - Input & Helpers

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let location = touch.location(in: self)
            if let launcher = launcher, launcher.contains(location) { startCharging() }
            else if location.x < 0 { setLeftFlipper(active: true) }
            else { setRightFlipper(active: true) }
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) { endAllTouchInput() }
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) { endAllTouchInput() }

    #if os(iOS)
    override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        for press in presses {
            guard let key = press.key else { continue }
            switch key.keyCode {
            case .keyboardLeftArrow, .keyboardA:  setLeftFlipper(active: true)
            case .keyboardRightArrow, .keyboardD: setRightFlipper(active: true)
            case .keyboardSpacebar, .keyboardS, .keyboardW: startCharging()
            default: super.pressesBegan(presses, with: event)
            }
        }
    }
    override func pressesEnded(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        for press in presses {
            guard let key = press.key else { continue }
            switch key.keyCode {
            case .keyboardLeftArrow, .keyboardA:  setLeftFlipper(active: false)
            case .keyboardRightArrow, .keyboardD: setRightFlipper(active: false)
            case .keyboardSpacebar, .keyboardS, .keyboardW: launchBall()
            default: super.pressesEnded(presses, with: event)
            }
        }
    }
    #endif

    private func setLeftFlipper(active: Bool) {
        guard isLeftFlipperActive != active else { return }
        isLeftFlipperActive = active
        active ? flip(flipper: leftFlipper, direction: .left) : unflip(flipper: leftFlipper, originalRotation: leftFlipperOriginalRotation)
    }

    private func setRightFlipper(active: Bool) {
        guard isRightFlipperActive != active else { return }
        isRightFlipperActive = active
        active ? flip(flipper: rightFlipper, direction: .right) : unflip(flipper: rightFlipper, originalRotation: rightFlipperOriginalRotation)
    }

    func flip(flipper: SKSpriteNode?, direction: FlipperDirection) {
        guard let flipper = flipper else { return }
        let angle: CGFloat = (direction == .left) ? (leftFlipperOriginalRotation + 0.85) : (rightFlipperOriginalRotation - 0.85)
        flipper.removeAction(forKey: "flipperMove")
        flipper.run(SKAction.rotate(toAngle: angle, duration: 0.07, shortestUnitArc: true), withKey: "flipperMove")
        run(SKAction.playSoundFileNamed("pad.wav", waitForCompletion: false))
    }

    func unflip(flipper: SKSpriteNode?, originalRotation: CGFloat) {
        guard let flipper = flipper else { return }
        flipper.removeAction(forKey: "flipperMove")
        flipper.run(SKAction.rotate(toAngle: originalRotation, duration: 0.09, shortestUnitArc: true), withKey: "flipperMove")
    }

    func launchBall() {
        guard isCharging else { return }
        isCharging = false
        launcher?.run(SKAction.move(to: originalLauncherPosition, duration: 0.06))
        ball?.physicsBody?.applyImpulse(CGVector(dx: 0, dy: max(280, currentLaunchPower)))
        run(SKAction.playSoundFileNamed("ding.wav", waitForCompletion: false))
        currentLaunchPower = 0; ballHasPassedFlippers = false; ballLaunched = true
    }

    private func isBallOnLauncher() -> Bool {
        guard let ball = ball, let launcher = launcher else { return false }
        return launcher.frame.intersects(ball.frame)
    }

    private func startCharging() {
        guard !isCharging, isBallOnLauncher() else { return }
        isCharging = true; currentLaunchPower = 0; isTouchingLauncher = true
    }

    private func endAllTouchInput() {
        setLeftFlipper(active: false); setRightFlipper(active: false)
        if isCharging { launchBall() }
        isTouchingLauncher = false
    }

    enum FlipperDirection { case left, right }
}
