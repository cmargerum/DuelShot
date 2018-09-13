//
//  GameScene.swift
//  DuelShot
//
//  Created by Cole Margerum on 8/8/18.
//  Copyright © 2018 Cole Margerum. All rights reserved.
//

import SpriteKit
import GameplayKit

protocol GameSceneDelegate {
    func sendUserState(isFiring: Bool, isHit: Bool)
}

enum Direction: CGFloat {
    case LEFT = -1
    case RIGHT = 1
}

class GameScene: SKScene, SKPhysicsContactDelegate {
    var gameSceneDelegate: GameSceneDelegate?
    var isTwoPlayer = true
    
    var user: SKSpriteNode!
    var enemy: SKSpriteNode!
    var leftButton: SKSpriteNode!
    var rightButton: SKSpriteNode!
    var jumpButton: SKSpriteNode!
    var shootButton: SKSpriteNode!
    var stopLeftAndRight: SKSpriteNode!
    
    var canJump = true
    var currentSecond: Int?
    var userActions = Set<String>()
    
    override func didMove(to view: SKView) {
        user = self.childNode(withName: "user") as! SKSpriteNode
        enemy = self.childNode(withName: "enemy") as! SKSpriteNode
        leftButton = self.childNode(withName: "left") as! SKSpriteNode
        rightButton = self.childNode(withName: "right") as! SKSpriteNode
        jumpButton = self.childNode(withName: "jump") as! SKSpriteNode
        shootButton = self.childNode(withName: "shoot") as! SKSpriteNode
        stopLeftAndRight = self.childNode(withName: "stopLeftAndRight") as! SKSpriteNode
        
        let border = SKPhysicsBody(edgeLoopFrom: frame)
        border.categoryBitMask = 1
        border.collisionBitMask = 1
        border.contactTestBitMask = 0
        border.friction = 0
        border.restitution = 0
        
        self.physicsBody = border
        self.physicsWorld.contactDelegate = self
    }
    
    func fireGun(from player: SKSpriteNode, toThe direction: Direction) {
        let bulletNode = SKSpriteNode(imageNamed: "bullet")
        
        bulletNode.position = player.position
        bulletNode.position.x += 25.0 * direction.rawValue
        
        bulletNode.physicsBody = SKPhysicsBody(circleOfRadius: bulletNode.size.width / 2)
        bulletNode.physicsBody?.isDynamic = true
        bulletNode.physicsBody?.affectedByGravity = false
        
        bulletNode.physicsBody?.categoryBitMask = 4
        bulletNode.physicsBody?.collisionBitMask = 3
        bulletNode.physicsBody?.contactTestBitMask = 2
        bulletNode.physicsBody?.usesPreciseCollisionDetection = true
        
        self.addChild(bulletNode)
        
        let animationDuration:TimeInterval = 2.5
        var actionArray = [SKAction]()
        actionArray.append(SKAction.move(to: CGPoint(x: frame.width * direction.rawValue, y: player.position.y), duration: animationDuration))
        actionArray.append(SKAction.removeFromParent())
        
        bulletNode.run(SKAction.sequence(actionArray))
    }
    
    func moveUser(moveXBy: CGFloat, moveYBy: CGFloat, forTheKey: String) {
        if forTheKey == "jump" {
            let moveAction = SKAction.applyImpulse(CGVector(dx: moveXBy, dy: moveYBy), duration: 0.25)
            user.run(moveAction, withKey: forTheKey)
        } else {
            let moveAction = SKAction.moveBy(x: moveXBy, y: moveYBy, duration: 0.5)
            let repeatForEver = SKAction.repeatForever(moveAction)
            let seq = SKAction.sequence([moveAction, repeatForEver])
            user.run(seq, withKey: forTheKey)
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch: AnyObject in touches {
            let pointTouched = touch.location(in: self)
            
            if leftButton.contains(pointTouched) {
                user.removeAction(forKey: "right")
                userActions.insert("left")
                moveUser(moveXBy: -150, moveYBy: 0, forTheKey: "left")
            } else if rightButton.contains(pointTouched) {
                user.removeAction(forKey: "left")
                userActions.insert("right")
                moveUser(moveXBy: 150, moveYBy: 0, forTheKey: "right")
            } else if jumpButton.contains(pointTouched), canJump {
                moveUser(moveXBy: 0, moveYBy: 40, forTheKey: "jump")
            } else if jumpButton.contains(pointTouched), !canJump {
                print("can't jump")
            } else if shootButton.contains(pointTouched) {
                gameSceneDelegate?.sendUserState(isFiring: true, isHit: false)
                fireGun(from: user, toThe: .RIGHT)
            }
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch: AnyObject in touches {
            let pointTouched = touch.location(in: self)
            if leftButton.contains(pointTouched) {
                user.removeAction(forKey: "right")
                if !userActions.contains("left") {
                    userActions.insert("left")
                    userActions.remove("right")
                    moveUser(moveXBy: -150, moveYBy: 0, forTheKey: "left")
                }
            } else if rightButton.contains(pointTouched) {
                user.removeAction(forKey: "left")
                if !userActions.contains("right") {
                    userActions.insert("right")
                    userActions.remove("left")
                    moveUser(moveXBy: 150, moveYBy: 0, forTheKey: "right")
                }
            } else if stopLeftAndRight.contains(pointTouched) {
                userActions.remove("left")
                userActions.remove("right")
                user.removeAction(forKey: "left")
                user.removeAction(forKey: "right")
            }
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch: AnyObject in touches {
            let pointTouched = touch.location(in: self)
            if leftButton.contains(pointTouched) {
                user.removeAction(forKey: "left")
                userActions.remove("left")
            } else if rightButton.contains(pointTouched) {
                user.removeAction(forKey: "right")
                userActions.remove("right")
            } else if jumpButton.contains(pointTouched) {
                user.removeAction(forKey: "jump")
            }
        }
    }
    
    public func didBegin(_ contact: SKPhysicsContact) {
        print("contact start")
        
        if contact.bodyA.node?.name == "user",
            contact.bodyB.categoryBitMask != 4,
            let user = contact.bodyA.node,
            let other = contact.bodyB.node
        {
            if user.position.y + user.calculateAccumulatedFrame().height / 2 > other.position.y + other.calculateAccumulatedFrame().height / 2 {
                canJump = true
            }
        } else if contact.bodyB.node?.name == "user",
            contact.bodyA.categoryBitMask != 4,
            let user = contact.bodyB.node,
            let other = contact.bodyA.node
        {
            if user.position.y + user.calculateAccumulatedFrame().height / 2 > other.position.y + other.calculateAccumulatedFrame().height / 2 {
                canJump = true
            }
        } else if contact.bodyA.categoryBitMask == 4, contact.bodyB.categoryBitMask == 2 {
            if let bulletNode = contact.bodyA.node {
                bulletNode.removeFromParent()
            }
        } else if contact.bodyB.categoryBitMask == 4, contact.bodyA.categoryBitMask == 2 {
            if let bulletNode = contact.bodyB.node {
                bulletNode.removeFromParent()
            }
        } else if contact.bodyA.categoryBitMask == 4, contact.bodyB.categoryBitMask == 6 {
            if let bulletNode = contact.bodyA.node {
                print("Hit!")
                bulletNode.removeFromParent()
            }
        } else if contact.bodyB.categoryBitMask == 4, contact.bodyA.categoryBitMask == 6 {
            if let bulletNode = contact.bodyB.node {
                print("Hit!")
                bulletNode.removeFromParent()
            }
        }
    }
    public func didEnd(_ contact: SKPhysicsContact) {
        print("contact end")
        if contact.bodyA.node?.name == "user" || contact.bodyB.node?.name == "user" {
            canJump = false
        }
    }
    
    override func update(_ currentTime: TimeInterval) {
        if isTwoPlayer {
            gameSceneDelegate?.sendUserState(isFiring: false, isHit: false)
        }
    }
    
    func updateEnemyState(x: Double, y: Double, isFiring: Bool, isHit: Bool) {
        enemy.position = CGPoint(x: x, y: y)
        
        if isFiring {
            fireGun(from: enemy, toThe: .LEFT)
        }
    }
    
    private func printPlayerPosition(for player: SKSpriteNode, at currentTime: TimeInterval) {
        if currentSecond == 0 {
            currentSecond = Int(currentTime)
        } else if currentSecond != Int(currentTime) {
            currentSecond = Int(currentTime)
            print(player.position)
        }
    }
}
