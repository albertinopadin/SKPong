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
    
    private let ballCategory: UInt32    = 0x1 << 0
    private let palletCategory: UInt32  = 0x1 << 1
    private let wallCategory: UInt32    = 0x1 << 2
    
    private let minimumBallVelocity: CGFloat = 300.0
    private let initialBallVelocity: CGFloat = -300.0
    private let ballVelocityVectorNudge: CGFloat = 20.0
    private let minimumVelocityVectorDelta: CGFloat = 0.01
    
    private var gameStarted: Bool = false
    
    override func didMove(to view: SKView) {
        // Debugging:
        print("Frame: \(self.frame)")
        
        // Instantiate Pallet Nodes:
        let palletNodeSize = CGSize(width: self.size.width/5, height: self.size.height/40)
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
        
        // Instantiate Ball Node:
        let ballRadius = palletNodeSize.width / 8
        let initialBallPosition = CGPoint(x: self.frame.midX, y: self.frame.midY)
        ballNode = createBallNode(radius: ballRadius, position: initialBallPosition)
        self.addChild(ballNode!)
        
        // Instantiate Wall Nodes:
        let sideWallSize = CGSize(width: 10.0, height: self.size.height)
        let leftSideWallPosition = CGPoint(x: self.frame.minX + 40, y: self.frame.midY)
        leftWallNode = createWallNode(size: sideWallSize, position: leftSideWallPosition)
        self.addChild(leftWallNode!)
        
        let rightSideWallPosition = CGPoint(x: self.frame.maxX - 40, y: self.frame.midY)
        rightWallNode = createWallNode(size: sideWallSize, position: rightSideWallPosition)
        self.addChild(rightWallNode!)
        
        let topBottomWallSize = CGSize(width: self.size.width, height: 10.0)
        let topWallPosition = CGPoint(x: self.frame.midX, y: self.frame.maxY)
        topWallNode = createWallNode(size: topBottomWallSize, position: topWallPosition)
        self.addChild(topWallNode!)
        
        let bottomWallPosition = CGPoint(x: self.frame.midX, y: self.frame.minY)
        bottomWallNode = createWallNode(size: topBottomWallSize, position: bottomWallPosition)
        self.addChild(bottomWallNode!)
        
        self.physicsWorld.gravity = CGVector(dx: 0, dy: 0)
        self.physicsWorld.contactDelegate = self
        
        // TODO: Figure out why side walls are not where they should be
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
    
    func createWallNode(size: CGSize, position: CGPoint) -> SKShapeNode {
        let wall = SKShapeNode(rectOf: size)
        wall.position = position
        wall.fillColor = .cyan
        wall.strokeColor = .lightGray
        wall.physicsBody = SKPhysicsBody(rectangleOf: size)
        wall.physicsBody?.isDynamic = false
        wall.physicsBody?.restitution = 1.0
        wall.physicsBody?.friction = 0.0
        wall.physicsBody?.categoryBitMask = wallCategory
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
        
        if (firstBody.categoryBitMask & ballCategory) != 0 && (secondBody.categoryBitMask & wallCategory) != 0 {
            ballDidCollideWithWall(ball: firstBody.node as! SKShapeNode,
                                   wall: secondBody.node as! SKShapeNode)
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
    
    func ballDidCollideWithWall(ball: SKShapeNode, wall: SKShapeNode) {
        let ballVelocityVector = ball.physicsBody!.velocity
        if isAbsoluteVelocityBelowLimit(velocity: ballVelocityVector.dx, minLimit: minimumVelocityVectorDelta) ||
            isAbsoluteVelocityBelowLimit(velocity: ballVelocityVector.dy, minLimit: minimumVelocityVectorDelta) {
            nudgeWallBall(ball: ball, wall: wall, ballVelocity: ballVelocityVector)
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
    
    func nudgeBallVertically(ball: SKShapeNode, nudge: CGFloat) {
        ball.physicsBody?.velocity.dy += nudge
    }
    
    func computeVectorLength(_ vector: CGVector) -> CGFloat {
        return hypot(vector.dx, vector.dy)
    }
    
    func convertVectorToLength(_ vector: CGVector, length: CGFloat) -> CGVector {
        let originalVectorLength = computeVectorLength(vector)
        let dx = vector.dx * length / originalVectorLength
        let dy = vector.dy * length / originalVectorLength
        return CGVector(dx: dx, dy: dy)
    }
    
    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
        if gameStarted {
            if let ball = ballNode {
                let ballVelocity = computeVectorLength(ball.physicsBody!.velocity)
                if ballVelocity < minimumBallVelocity {
                    // Always make sure ball has minimum velocity:
                    ball.physicsBody?.velocity = convertVectorToLength(ball.physicsBody!.velocity,
                                                                       length: minimumBallVelocity)
                }
                
                // If ball has no vertical movement, nudge so we can continue playing:
                // This may not be needed...
//                if isAbsoluteVelocityBelowLimit(velocity: verticalVelocityVector,
//                                                minLimit: minimumVelocityVectorDelta) {
//                    nudgeBallVertically(ball: ball, nudge: ballVelocityVectorNudge)
//                }
            }
        }
    }
}
