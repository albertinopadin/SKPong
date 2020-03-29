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
    
    private var label : SKLabelNode?
    private var palletNode: SKShapeNode?
    private var ballNode: SKShapeNode?
    
    private var palletNodeY: CGFloat?
    private var palletNodeXMinBound: CGFloat?
    private var palletNodeXMaxBound: CGFloat?
    
    private let palletCategory: UInt32 = 0x1 << 1
    private let ballCategory: UInt32 = 0x1 << 0
    
    override func didMove(to view: SKView) {
        // Instantiate Pallet Node:
        let palletNodeSize = CGSize(width: self.size.width/5, height: self.size.height/40)
        self.palletNode = self.createPalletNode(size: palletNodeSize)
        self.addChild(self.palletNode!)
        
        // Instantiate Ball Node:
        let ballRadius = palletNodeSize.width / 8
        self.ballNode = self.createBallNode(radius: ballRadius)
        self.addChild(self.ballNode!)
        
        self.physicsWorld.gravity = CGVector(dx: 0, dy: 0)
        self.physicsWorld.contactDelegate = self
    }
    
    func createPalletNode(size: CGSize) -> SKShapeNode {
        let pallet = SKShapeNode(rectOf: size, cornerRadius: 10.0)
        pallet.fillColor = .blue
        pallet.strokeColor = .white
        palletNodeY = size.height + 20
        palletNodeXMinBound = size.width  // How does this even work, should be /2...
        palletNodeXMaxBound = self.frame.width - palletNodeXMinBound!
        let initialPalletPosition = CGPoint(x: self.frame.midX, y: palletNodeY!)
        pallet.position = initialPalletPosition
        pallet.physicsBody = SKPhysicsBody(rectangleOf: size)
        pallet.physicsBody?.isDynamic = false
        pallet.physicsBody?.restitution = 1.0
        pallet.physicsBody?.linearDamping = 0.0
        pallet.physicsBody?.categoryBitMask = palletCategory
        pallet.physicsBody?.contactTestBitMask = ballCategory
        return pallet
    }
    
    func createBallNode(radius: CGFloat) -> SKShapeNode {
        let ball = SKShapeNode.init(circleOfRadius: radius)
        ball.fillColor = .yellow
        ball.strokeColor = .white
        let initialBallPosition = CGPoint(x: self.frame.midX, y: self.frame.midY)
        ball.position = initialBallPosition
        ball.physicsBody = SKPhysicsBody(circleOfRadius: radius)
        ball.physicsBody?.isDynamic = true
        ball.physicsBody?.restitution = 1.0
        ball.physicsBody?.linearDamping = 0.0
        ball.physicsBody?.categoryBitMask = ballCategory
        ball.physicsBody?.contactTestBitMask = palletCategory
        return ball
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
        // TODO
    }
    
    func touchDown(atPoint pos : CGPoint) {
        if let ball = self.ballNode {
            if ball.physicsBody?.velocity.dx == 0.0 && ball.physicsBody?.velocity.dy == 0.0 {
                ball.physicsBody?.velocity = CGVector(dx: 0.0, dy: -200.0)
            }
        }
    }
    
    func touchMoved(toPoint pos : CGPoint) {
        if let n = self.palletNode {
            n.position.x = calculatePalletNodeXPosition(touchPosition: pos)
        }
    }
    
    func touchUp(atPoint pos : CGPoint) {
        if let n = self.palletNode {
            n.position.x = calculatePalletNodeXPosition(touchPosition: pos)
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
    }
}
