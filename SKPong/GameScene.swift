//
//  GameScene.swift
//  SKPong
//
//  Created by Albertino Padin on 3/20/20.
//  Copyright © 2020 Albertino Padin. All rights reserved.
//

import SpriteKit
import GameplayKit

class GameScene: SKScene, SKPhysicsContactDelegate {
    
//    private var label : SKLabelNode?
    
    // TODO: Use SKSpriteNode instead?
    private var topPalletNode: SKShapeNode?
    private var bottomPalletNode: SKShapeNode?
    private var ballNode: SKShapeNode?
    private var ballRadius: CGFloat = 0
    
    private var border: SKPhysicsBody!
    
    private var previousTouchPoint: CGPoint?
    
    private let palletSeparation: CGFloat = 20.0
    private var topPalletNodeY: CGFloat?
    private var bottomPalletNodeY: CGFloat?
    private var palletNodeXMinBound: CGFloat?
    private var palletNodeXMaxBound: CGFloat?
    
    private let ballCategory: UInt32    = 0x1 << 0
    private let palletCategory: UInt32  = 0x1 << 1
    
    private let minimumBallVelocity: CGFloat = 300.0
    private let initialBallVelocity: CGFloat = -300.0
    private let ballVelocityVectorNudge: CGFloat = 20.0
    private let minimumVelocityVectorDelta: CGFloat = 0.01
    
    private var gameStarted: Bool = false
    private var zeroVector = CGVector(dx: 0, dy: 0)
    
    private var scorePlayer1: Int = 0
    private var scorePlayer2: Int = 0
    
    private var scoreLabelPlayer1: SKLabelNode?
    private var scoreLabelPlayer2: SKLabelNode?
    private let scoreString = "Score:"
    private let scoreLabelOffset: CGFloat = 20
    
    override func didMove(to view: SKView) {
        // Debugging:
        print("Frame: \(self.frame)")
        
        let palletNodeSize = CGSize(width: self.size.width/5, height: self.size.height/40)
        initPalletNodes(palletNodeSize: palletNodeSize)
        
        ballRadius = palletNodeSize.width / 8
        initBallNode(radius: ballRadius)
        
        initBorder()
        initPhysicsWorld()
        initScoreLabels()
        
        // TODO: Implement more realistic, last minute movement of top pallet
    }
    
    func initPhysicsWorld() {
        self.physicsWorld.gravity = zeroVector
        self.physicsWorld.contactDelegate = self
    }
    
    func initBorder() {
        border = SKPhysicsBody(edgeLoopFrom: self.frame)
        border.friction = 0
        border.restitution = 1
        self.physicsBody = border
    }
    
    func initPalletNodes(palletNodeSize: CGSize) {
        palletNodeXMinBound = palletNodeSize.width  // How does this even work, should be /2...
        palletNodeXMaxBound = self.frame.width - palletNodeXMinBound!
        
        topPalletNodeY = self.frame.height - (palletSeparation * 2)
        let initialTopPalletPosition = CGPoint(x: self.frame.midX, y: topPalletNodeY!)
        topPalletNode = createPalletNode(size: palletNodeSize, position: initialTopPalletPosition)
        self.addChild(topPalletNode!)
        
        bottomPalletNodeY = palletNodeSize.height + palletSeparation
        let initialBottomPalletPosition = CGPoint(x: self.frame.midX, y: bottomPalletNodeY!)
        bottomPalletNode = createPalletNode(size: palletNodeSize, position: initialBottomPalletPosition)
        self.addChild(bottomPalletNode!)
    }
    
    func initBallNode(radius: CGFloat) {
        let initialBallPosition = CGPoint(x: self.frame.midX, y: self.frame.midY)
        ballNode = createBallNode(radius: radius, position: initialBallPosition)
        self.addChild(ballNode!)
    }
    
    func initScoreLabels() {
        let initialScore = getScoreText(score: 0)
        
        let scoreLabelP1Position = CGPoint(x: self.frame.minX, y: self.frame.minY + scoreLabelOffset)
        scoreLabelPlayer1 = initLabelNode(text: initialScore, fontColor: .blue, position: scoreLabelP1Position)
        self.addChild(scoreLabelPlayer1!)
        
        let scoreLabelP2Position = CGPoint(x: self.frame.minX, y: self.frame.maxY - scoreLabelOffset * 3)
        scoreLabelPlayer2 = initLabelNode(text: initialScore, fontColor: .red, position: scoreLabelP2Position)
        self.addChild(scoreLabelPlayer2!)
    }
    
    func getScoreText(score: Int) -> String {
        return "\(scoreString) \(score)"
    }
    
    func initLabelNode(text: String, fontColor: UIColor, position: CGPoint) -> SKLabelNode {
        let labelNode = SKLabelNode(text: text)
        labelNode.fontColor = fontColor
        let labelSize = labelNode.frame.size
        let calibratedPosition = CGPoint(x: position.x + labelSize.width, y: position.y)
        labelNode.position = calibratedPosition
        return labelNode
    }
    
    func createPalletNode(size: CGSize, position: CGPoint) -> SKShapeNode {
        let pallet = SKShapeNode(rectOf: size, cornerRadius: 10.0)
        pallet.position = position
        pallet.fillColor = .blue
        pallet.strokeColor = .white
        pallet.physicsBody = SKPhysicsBody(rectangleOf: size)
        pallet.physicsBody?.isDynamic = false
        pallet.physicsBody?.restitution = 1
        pallet.physicsBody?.linearDamping = 0
        pallet.physicsBody?.categoryBitMask = palletCategory
        pallet.physicsBody?.contactTestBitMask = ballCategory
        return pallet
    }
    
    func createBallNode(radius: CGFloat, position: CGPoint) -> SKShapeNode {
        let ball = SKShapeNode(circleOfRadius: radius)
        ball.position = position
        ball.fillColor = .yellow
        ball.strokeColor = .white
        ball.physicsBody = SKPhysicsBody(circleOfRadius: radius)
        ball.physicsBody?.isDynamic = true
        ball.physicsBody?.restitution = 1
        ball.physicsBody?.linearDamping = 0
        ball.physicsBody?.angularDamping = 0
        ball.physicsBody?.categoryBitMask = ballCategory
        ball.physicsBody?.contactTestBitMask = palletCategory
        return ball
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
//        var firstBody: SKPhysicsBody
//        var secondBody: SKPhysicsBody
//
//        if contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask {
//            firstBody = contact.bodyA
//            secondBody = contact.bodyB
//        } else {
//            firstBody = contact.bodyB
//            secondBody = contact.bodyA
//        }
//
//        if (firstBody.categoryBitMask & ballCategory) != 0 {
//            if (secondBody.categoryBitMask & sideWallCategory) != 0 {
//                ballDidCollideWithSideWall(ball: firstBody.node as! SKShapeNode,
//                                           wall: secondBody.node as! SKShapeNode)
//            } else if (secondBody.categoryBitMask & topBottomWallCategory) != 0 {
//                ballDidCollideWithTopBottomWall(wall: secondBody.node as! SKShapeNode)
//            }
//        }
    }
    
    func isAbsoluteVelocityBelowLimit(velocity: CGFloat, minLimit: CGFloat) -> Bool {
        return abs(velocity) < minLimit
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches { self.touchDown(atPoint: t.location(in: self)) }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches { self.touchMoved(toPoint: t.location(in: self)) }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches { self.touchUp(atPoint: t.location(in: self)) }
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches { self.touchUp(atPoint: t.location(in: self)) }
    }
    
     func touchDown(atPoint pos : CGPoint) {
        previousTouchPoint = pos
        
        if let ball = ballNode {
            if ball.physicsBody?.velocity.dx == 0.0 && ball.physicsBody?.velocity.dy == 0.0 {
//                ball.physicsBody?.velocity = CGVector(dx: 0.0, dy: initialBallVelocity)
                ball.physicsBody?.applyImpulse(CGVector(dx: 10, dy: 10))
                gameStarted.toggle()
            }
        }
    }
    
    func touchMoved(toPoint pos : CGPoint) {
        if let bottomPallet = bottomPalletNode {
            bottomPallet.position.x += calculateTouchMoveChange(touchPoint: pos)
        }
    }
    
    func touchUp(atPoint pos : CGPoint) {
        
    }
    
    func calculateTouchMoveChange(touchPoint: CGPoint) -> CGFloat {
        guard let previous = previousTouchPoint else {
            previousTouchPoint = touchPoint
            return 0.0
        }
        
        let change = touchPoint.x - previous.x
        previousTouchPoint = touchPoint
        return change
    }
    
    func calculatePalletNodeXPosition(touchPosition: CGPoint) -> CGFloat {
        if touchPosition.x < palletNodeXMinBound! {
            return palletNodeXMinBound!
        } else if touchPosition.x > palletNodeXMaxBound! {
            return palletNodeXMaxBound!
        } else {
            return touchPosition.x
        }
    }
    
    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
        if gameStarted {
            ensureBallHasMinimumVelocity()
            moveTopPalletToBallXPosition()
            
            // If ball has no vertical movement, nudge so we can continue playing:
                            // This may not be needed...
            //                if isAbsoluteVelocityBelowLimit(velocity: verticalVelocityVector,
            //                                                minLimit: minimumVelocityVectorDelta) {
            //                    nudgeBallVertically(ball: ball, nudge: ballVelocityVectorNudge)
            //                }
        }
    }
    
    func ensureBallHasMinimumVelocity() {
        if let ball = ballNode {
            let ballVelocity = ball.physicsBody!.velocity.length
            if ballVelocity < minimumBallVelocity {
                ball.physicsBody?.velocity = convertVectorToLength(ball.physicsBody!.velocity,
                                                                   length: minimumBallVelocity)
            }
        }
    }
    
    func moveTopPalletToBallXPosition() {
        if let ball = ballNode, let topPallet = topPalletNode {
            topPallet.run(SKAction.moveTo(x: ball.position.x, duration: 1.0))
        }
    }
    
    func nudgeBallVertically(ball: SKShapeNode, nudge: CGFloat) {
        ball.physicsBody?.velocity.dy += nudge
    }
    
    func convertVectorToLength(_ vector: CGVector, length: CGFloat) -> CGVector {
        let originalVectorLength = vector.length
        let dx = vector.dx * length / originalVectorLength
        let dy = vector.dy * length / originalVectorLength
        return CGVector(dx: dx, dy: dy)
    }
    
}
