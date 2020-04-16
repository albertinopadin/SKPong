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
    
    private var leftWallNode: SKShapeNode?
    private var rightWallNode: SKShapeNode?
    
    // For testing only
    private var topWallNode: SKShapeNode?
    private var bottomWallNode: SKShapeNode?
    
    private let palletSeparation: CGFloat = 20.0
    private var topPalletNodeY: CGFloat?
    private var bottomPalletNodeY: CGFloat?
    private var palletNodeXMinBound: CGFloat?
    private var palletNodeXMaxBound: CGFloat?
    
    private let ballCategory: UInt32            = 0x1 << 0
    private let palletCategory: UInt32          = 0x1 << 1
    private let sideWallCategory: UInt32        = 0x1 << 2
    private let topBottomWallCategory: UInt32   = 0x1 << 3
    
    private let minimumBallVelocity: CGFloat = 300.0
    private let initialBallVelocity: CGFloat = -300.0
    private let ballVelocityVectorNudge: CGFloat = 20.0
    private let minimumVelocityVectorDelta: CGFloat = 0.01
    
    private var gameStarted: Bool = false
    private var sideWallCorrection: CGFloat = 40  // TODO: Should fix the core issue, shouldn't need this...
    private var topBottomWallOffset: CGFloat = 20  // Wall should be offscreen
    private var zeroVector = CGVector(dx: 0, dy: 0)
    
    private var scorePlayer1: Int = 0
    private var scorePlayer2: Int = 0
    
    private var scoreLabelPlayer1: SKLabelNode?
    private var scoreLabelPlayer2: SKLabelNode?
    private let scoreString = "Score:"
    
    override func didMove(to view: SKView) {
        // Debugging:
        print("Frame: \(self.frame)")
        
        let palletNodeSize = CGSize(width: self.size.width/5, height: self.size.height/40)
        initPalletNodes(palletNodeSize: palletNodeSize)
        
        ballRadius = palletNodeSize.width / 8
        initBallNode(radius: ballRadius)
        
        initWallNodes()
        initPhysicsWorld()
        initScoreLabels()
        
        // TODO: Figure out why side walls are not where they should be
        // TODO: Implement more realistic, last minute movement of top pallet
    }
    
    func initPhysicsWorld() {
        self.physicsWorld.gravity = zeroVector
        self.physicsWorld.contactDelegate = self
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
    
    func initWallNodes() {
        let sideWallSize = CGSize(width: 10.0, height: self.size.height)
        let leftSideWallPosition = CGPoint(x: self.frame.minX + sideWallCorrection, y: self.frame.midY)
        leftWallNode = createWallNode(size: sideWallSize,
                                      position: leftSideWallPosition,
                                      category: sideWallCategory)
        self.addChild(leftWallNode!)
        
        let rightSideWallPosition = CGPoint(x: self.frame.maxX - sideWallCorrection, y: self.frame.midY)
        rightWallNode = createWallNode(size: sideWallSize,
                                       position: rightSideWallPosition,
                                       category: sideWallCategory)
        self.addChild(rightWallNode!)
        
        let topBottomWallSize = CGSize(width: self.size.width, height: 10.0)
        let topWallPosition = CGPoint(x: self.frame.midX, y: self.frame.maxY + topBottomWallOffset)
        topWallNode = createWallNode(size: topBottomWallSize,
                                     position: topWallPosition,
                                     category: topBottomWallCategory)
        self.addChild(topWallNode!)
        
        let bottomWallPosition = CGPoint(x: self.frame.midX, y: self.frame.minY - topBottomWallOffset)
        bottomWallNode = createWallNode(size: topBottomWallSize,
                                        position: bottomWallPosition,
                                        category: topBottomWallCategory)
        self.addChild(bottomWallNode!)
    }
    
    func initScoreLabels() {
        let initialScore = getScoreText(score: 0)
        
        let scoreLabelP1Position = CGPoint(x: self.frame.minX, y: self.frame.minY + topBottomWallOffset)
        scoreLabelPlayer1 = initLabelNode(text: initialScore, fontColor: .blue, position: scoreLabelP1Position)
        self.addChild(scoreLabelPlayer1!)
        
        let scoreLabelP2Position = CGPoint(x: self.frame.minX, y: self.frame.maxY - topBottomWallOffset * 3)
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
        pallet.physicsBody?.restitution = 1.0
        pallet.physicsBody?.linearDamping = 0.0
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
        ball.physicsBody?.restitution = 1.0
        ball.physicsBody?.linearDamping = 0.0
        ball.physicsBody?.categoryBitMask = ballCategory
        ball.physicsBody?.contactTestBitMask = palletCategory
        return ball
    }
    
    func createWallNode(size: CGSize, position: CGPoint, category: UInt32) -> SKShapeNode {
        let wall = SKShapeNode(rectOf: size)
        wall.position = position
        wall.fillColor = .cyan
        wall.strokeColor = .lightGray
        wall.physicsBody = SKPhysicsBody(rectangleOf: size)
        wall.physicsBody?.isDynamic = false
        wall.physicsBody?.restitution = 1.0
        wall.physicsBody?.friction = 0.0
        wall.physicsBody?.categoryBitMask = category
        wall.physicsBody?.contactTestBitMask = ballCategory
        return wall
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
    
    func didBegin(_ contact: SKPhysicsContact) {
        var firstBody: SKPhysicsBody
        var secondBody: SKPhysicsBody
        
        if contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask {
            firstBody = contact.bodyA
            secondBody = contact.bodyB
        } else {
            firstBody = contact.bodyB
            secondBody = contact.bodyA
        }
        
        if (firstBody.categoryBitMask & ballCategory) != 0 {
            if (secondBody.categoryBitMask & sideWallCategory) != 0 {
                ballDidCollideWithSideWall(ball: firstBody.node as! SKShapeNode,
                                           wall: secondBody.node as! SKShapeNode)
            } else if (secondBody.categoryBitMask & topBottomWallCategory) != 0 {
                ballDidCollideWithTopBottomWall(wall: secondBody.node as! SKShapeNode)
            }
        }
    }
    
    func ballDidCollideWithTopBottomWall(wall: SKShapeNode) {
        if wall == topWallNode {
            scorePlayer1 += 1
            scoreLabelPlayer1?.text = getScoreText(score: scorePlayer1)
        } else if wall == bottomWallNode {
            scorePlayer2 += 1
            scoreLabelPlayer2?.text = getScoreText(score: scorePlayer2)
        }
        
        gameStarted = false
        ballNode?.removeFromParent()
        initBallNode(radius: ballRadius)
    }

    func ballDidCollideWithSideWall(ball: SKShapeNode, wall: SKShapeNode) {
        let ballVelocityVector = ball.physicsBody!.velocity
        if isAbsoluteVelocityBelowLimit(velocity: ballVelocityVector.dx, minLimit: minimumVelocityVectorDelta) ||
            isAbsoluteVelocityBelowLimit(velocity: ballVelocityVector.dy, minLimit: minimumVelocityVectorDelta) {
            nudgeWallBall(ball: ball, wall: wall, ballVelocity: ballVelocityVector)
        }
    }
    
    func isAbsoluteVelocityBelowLimit(velocity: CGFloat, minLimit: CGFloat) -> Bool {
        return abs(velocity) < minLimit
    }
    
    func nudgeWallBall(ball: SKShapeNode, wall: SKShapeNode, ballVelocity: CGVector) {
        switch wall {
        case leftWallNode:
            ball.physicsBody?.velocity = CGVector(dx: ballVelocity.dx + ballVelocityVectorNudge,
                                                  dy: ballVelocity.dy)
        case rightWallNode:
            ball.physicsBody?.velocity = CGVector(dx: ballVelocity.dx - ballVelocityVectorNudge,
                                                  dy: ballVelocity.dy)
        case topWallNode:
            ball.physicsBody?.velocity = CGVector(dx: ballVelocity.dx,
                                                  dy: ballVelocity.dy - ballVelocityVectorNudge)
        case bottomWallNode:
            ball.physicsBody?.velocity = CGVector(dx: ballVelocity.dx,
                                                  dy: ballVelocity.dy + ballVelocityVectorNudge)
        default:
            // This should never happen... Nudge in both directions?
            ball.physicsBody?.velocity = CGVector(dx: ballVelocity.dx + ballVelocityVectorNudge,
                                                  dy: ballVelocity.dy + ballVelocityVectorNudge)
        }
    }
    
    func touchDown(atPoint pos : CGPoint) {
        if let ball = ballNode {
            if ball.physicsBody?.velocity.dx == 0.0 && ball.physicsBody?.velocity.dy == 0.0 {
                ball.physicsBody?.velocity = CGVector(dx: 0.0, dy: initialBallVelocity)
                gameStarted.toggle()
            }
        }
    }
    
    func touchMoved(toPoint pos : CGPoint) {
        if let bottomPallet = bottomPalletNode {
            bottomPallet.position.x = calculatePalletNodeXPosition(touchPosition: pos)
        }
    }
    
    func touchUp(atPoint pos : CGPoint) {
        if let bottomPallet = bottomPalletNode {
            bottomPallet.position.x = calculatePalletNodeXPosition(touchPosition: pos)
        }
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
            topPallet.position.x = ball.position.x
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
