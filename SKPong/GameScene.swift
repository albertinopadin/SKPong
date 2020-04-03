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
    
    private let initialBallVelocity = -300.0
    private let ballVelocityVectorNudge: CGFloat = 10.0
    private let minimumVelocityVectorDelta: CGFloat = 0.01
    
    private var gameStarted: Bool = false
    
    override func didMove(to view: SKView) {
        // Debugging:
        print("Frame: \(self.frame)")
        
        // Instantiate Pallet Nodes:
        let palletNodeSize = CGSize(width: self.size.width/5, height: self.size.height/40)
        self.palletNodeXMinBound = palletNodeSize.width  // How does this even work, should be /2...
        self.palletNodeXMaxBound = self.frame.width - self.palletNodeXMinBound!
        
        self.topPalletNodeY = self.frame.height - (self.palletSeparation * 2)
        let initialTopPalletPosition = CGPoint(x: self.frame.midX, y: self.topPalletNodeY!)
        self.topPalletNode = self.createPalletNode(size: palletNodeSize, position: initialTopPalletPosition)
        self.addChild(self.topPalletNode!)
        
        self.bottomPalletNodeY = palletNodeSize.height + self.palletSeparation
        let initialBottomPalletPosition = CGPoint(x: self.frame.midX, y: self.bottomPalletNodeY!)
        self.bottomPalletNode = self.createPalletNode(size: palletNodeSize, position: initialBottomPalletPosition)
        self.addChild(self.bottomPalletNode!)
        
        // Instantiate Ball Node:
        let ballRadius = palletNodeSize.width / 8
        let initialBallPosition = CGPoint(x: self.frame.midX, y: self.frame.midY)
        self.ballNode = self.createBallNode(radius: ballRadius, position: initialBallPosition)
        self.addChild(self.ballNode!)
        
        // Instantiate Wall Nodes:
        let sideWallSize = CGSize(width: 10.0, height: self.size.height)
        let leftSideWallPosition = CGPoint(x: self.frame.minX + 40, y: self.frame.midY)
        self.leftWallNode = self.createWallNode(size: sideWallSize, position: leftSideWallPosition)
        self.addChild(self.leftWallNode!)
        
        let rightSideWallPosition = CGPoint(x: self.frame.maxX - 40, y: self.frame.midY)
        self.rightWallNode = self.createWallNode(size: sideWallSize, position: rightSideWallPosition)
        self.addChild(self.rightWallNode!)
        
        let topBottomWallSize = CGSize(width: self.size.width, height: 10.0)
        let topWallPosition = CGPoint(x: self.frame.midX, y: self.frame.maxY)
        self.topWallNode = self.createWallNode(size: topBottomWallSize, position: topWallPosition)
        self.addChild(self.topWallNode!)
        
        let bottomWallPosition = CGPoint(x: self.frame.midX, y: self.frame.minY)
        self.bottomWallNode = self.createWallNode(size: topBottomWallSize, position: bottomWallPosition)
        self.addChild(self.bottomWallNode!)
        
        self.physicsWorld.gravity = CGVector(dx: 0, dy: 0)
        self.physicsWorld.contactDelegate = self
        
        // TODO: Figure out why side walls are not where they should be
        // TODO: If ball is going perfectly horizontal, randomly impart up/down impulse
        // TODO: If ball is going perfectly vertical near a wall, randomly impart left/right impulse.
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
        
        if (firstBody.categoryBitMask & self.ballCategory) != 0 && (secondBody.categoryBitMask & self.wallCategory) != 0 {
            self.ballDidCollideWithWall(ball: firstBody.node as! SKShapeNode,
                                        wall: secondBody.node as! SKShapeNode)
        }
    }
    
    func ballDidCollideWithWall(ball: SKShapeNode, wall: SKShapeNode) {
        let ballVelocityVector = ball.physicsBody!.velocity
        print("Ball Velocity vector at contact: \(ballVelocityVector)")
        
        if wall == self.leftWallNode || wall == self.rightWallNode {
            if abs(ballVelocityVector.dx) < self.minimumVelocityVectorDelta {
                if wall == self.leftWallNode {
                    ball.physicsBody?.velocity = CGVector(dx: self.ballVelocityVectorNudge,
                                                          dy: ballVelocityVector.dy)
                } else {
                    ball.physicsBody?.velocity = CGVector(dx: -self.ballVelocityVectorNudge,
                                                          dy: ballVelocityVector.dy)
                }
            }
        } else {
            // Top or Bottom wall contact:
            if abs(ballVelocityVector.dy) < self.minimumVelocityVectorDelta {
                if wall == self.bottomWallNode {
                    ball.physicsBody?.velocity = CGVector(dx: ballVelocityVector.dx,
                                                      dy: self.ballVelocityVectorNudge)
                } else {
                    ball.physicsBody?.velocity = CGVector(dx: ballVelocityVector.dx,
                                                          dy: -self.ballVelocityVectorNudge)
                }
            }
        }
    }
    
    func touchDown(atPoint pos : CGPoint) {
        if let ball = self.ballNode {
            if ball.physicsBody?.velocity.dx == 0.0 && ball.physicsBody?.velocity.dy == 0.0 {
                ball.physicsBody?.velocity = CGVector(dx: 0.0, dy: self.initialBallVelocity)
                self.gameStarted.toggle()
            }
        }
    }
    
    func touchMoved(toPoint pos : CGPoint) {
        if let bottomPallet = self.bottomPalletNode {
            bottomPallet.position.x = calculatePalletNodeXPosition(touchPosition: pos)
        }
    }
    
    func touchUp(atPoint pos : CGPoint) {
        if let bottomPallet = self.bottomPalletNode {
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
        
        // If ball has no vertical movement, nudge so we can continue playing:
        if self.gameStarted {
            if let ball = self.ballNode {
                let verticalVelocityVector = ball.physicsBody!.velocity.dy
                if abs(verticalVelocityVector) < self.minimumVelocityVectorDelta {
                    if verticalVelocityVector < 0.0 {
                        ball.physicsBody?.velocity.dy -= self.ballVelocityVectorNudge
                    } else {
                        ball.physicsBody?.velocity.dy += self.ballVelocityVectorNudge
                    }
                }
            }
        }
    }
}
