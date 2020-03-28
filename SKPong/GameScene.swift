//
//  GameScene.swift
//  SKPong
//
//  Created by Albertino Padin on 3/20/20.
//  Copyright © 2020 Albertino Padin. All rights reserved.
//

import SpriteKit
import GameplayKit

class GameScene: SKScene {
    
    private var label : SKLabelNode?
    private var palletNode: SKShapeNode?
    private var ballNode: SKShapeNode?
    
    private var palletNodeY: CGFloat?
    private var palletNodeXMinBound: CGFloat?
    private var palletNodeXMaxBound: CGFloat?
    
    override func didMove(to view: SKView) {
        // Instantiate Pallet Node:
        let palletNodeSize = CGSize.init(width: self.size.width/5, height: self.size.height/40)
        self.palletNode = SKShapeNode.init(rectOf: palletNodeSize, cornerRadius: 10.0)
        self.palletNode?.fillColor = .blue
        self.palletNode?.strokeColor = .white
        palletNodeY = palletNodeSize.height + 20
        palletNodeXMinBound = palletNodeSize.width  // How does this even work, should be /2...
        palletNodeXMaxBound = self.frame.width - palletNodeXMinBound!
        let initialPalletPosition = CGPoint(x: self.frame.midX, y: palletNodeY!)
        self.palletNode?.position = initialPalletPosition
        self.addChild(self.palletNode!)
        
        // Instantiate Ball Node:
        let ballRadius = palletNodeSize.width / 8
        self.ballNode = SKShapeNode.init(circleOfRadius: ballRadius)
        self.ballNode?.fillColor = .yellow
        self.ballNode?.strokeColor = .white
        let initialBallPosition = CGPoint.init(x: self.frame.midX, y: self.frame.midY)
        self.ballNode?.position = initialBallPosition
        self.addChild(self.ballNode!)
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
    
    
    func touchDown(atPoint pos : CGPoint) {
//        if let n = self.palletNode {
//            n.position = pos
//            n.strokeColor = SKColor.green
//        }
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
