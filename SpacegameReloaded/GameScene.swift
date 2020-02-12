//
//  GameScene.swift
//  SpacegameReloaded
//
//  Created by Ashkan Amin on 2/9/20.
//  Copyright © 2020 Ashkan Amin. All rights reserved.
//

import SpriteKit
import GameplayKit
import CoreMotion

class GameScene: SKScene,SKPhysicsContactDelegate {
    var starfield:SKEmitterNode!
    var player:SKSpriteNode!
    var scoreLabel:SKLabelNode!
    var score:Int = 0 {
        didSet{
            scoreLabel.text = "Score: \(score)"
        }
    }
    var gameTimer:Timer!
    var possibleAliens = ["alien","alien2","alien3"]
    let alienCategory:UInt32 = 0x1 << 1
    let photonTorPedOCategory:UInt32 = 0x1 << 0
    let motionManager = CMMotionManager()
    var xAcceleration:CGFloat = 0
    override func didMove(to view: SKView) {
        
        starfield = SKEmitterNode(fileNamed: "Starfield")
        starfield.position = CGPoint(x: 0, y: 1472)
        starfield.advanceSimulationTime(10)
        self.addChild(starfield)
        starfield.zPosition = -1
        player = SKSpriteNode(imageNamed: "shuttle")
        player.position = CGPoint(x: 0.5 , y: -self.frame.height / 2 + 60 )
        
        self.addChild(player)
        self.physicsWorld.gravity = CGVector(dx: 0, dy: 0)
        self.physicsWorld.contactDelegate = self
        scoreLabel = SKLabelNode(text: "Score: 0")
        scoreLabel.position = CGPoint(x: -self.frame.width / 2 + 100, y: self.frame.size.height / 2 - 60)
        scoreLabel.fontName = "AmericanTypewriter-Bold"
        scoreLabel.fontSize = 36
        scoreLabel.fontColor = UIColor.white
        score = 0
        self.addChild(scoreLabel)
        gameTimer = Timer.scheduledTimer(timeInterval: 0.75, target: self, selector: #selector(addAlien), userInfo: nil, repeats: true)
        
        motionManager.accelerometerUpdateInterval = 0.2
        motionManager.startAccelerometerUpdates(to: OperationQueue.current!) { (data, error) in
            if let acceleromterData = data {
                let acceleration = acceleromterData.acceleration
                self.xAcceleration = CGFloat(acceleration.x) * 0.75 + self.xAcceleration * 0.25
            }
        }
        
        
    }
    @objc func addAlien() {
        possibleAliens = GKRandomSource.sharedRandom().arrayByShufflingObjects(in: possibleAliens) as! [String]
        let alien = SKSpriteNode(imageNamed: possibleAliens[0])
        let randomAlienPosition = GKRandomDistribution(lowestValue: -414, highestValue: 414)
        let position = CGFloat(randomAlienPosition.nextInt())
        alien.position = CGPoint(x: position, y: self.frame.size.height)
        alien.physicsBody = SKPhysicsBody(rectangleOf: alien.size)
        alien.physicsBody?.isDynamic = true
        alien.physicsBody?.categoryBitMask = alienCategory
        alien.physicsBody?.contactTestBitMask = photonTorPedOCategory
        alien.physicsBody?.collisionBitMask = 0
        self.addChild(alien)
        let animationDuration:TimeInterval = 12
        
        var actionArray = [SKAction]()
        actionArray.append(SKAction.move(to: CGPoint(x: position, y: -self.frame.height), duration: animationDuration))
        actionArray.append(SKAction.removeFromParent())
        alien.run(SKAction.sequence(actionArray))
    }
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        fireTorpedo()
    }
    
    
    
    func fireTorpedo(){
        self.run(SKAction.playSoundFileNamed("torpedo.mp3", waitForCompletion: false))
        let torpedoNode = SKSpriteNode(imageNamed: "torpedo")
        torpedoNode.position = player.position
        torpedoNode.position.y += 5
        torpedoNode.physicsBody = SKPhysicsBody(circleOfRadius: torpedoNode.size.width / 2)
        torpedoNode.physicsBody?.categoryBitMask = photonTorPedOCategory
        torpedoNode.physicsBody?.contactTestBitMask = alienCategory
        torpedoNode.physicsBody?.collisionBitMask = 0
        torpedoNode.physicsBody?.usesPreciseCollisionDetection = true
        self.addChild(torpedoNode)
        let animationDuration:TimeInterval = 0.3
        var actionArray = [SKAction]()
        actionArray.append(SKAction.move(to: CGPoint(x: player.position.x, y: self.frame.size.height + 10), duration: animationDuration))
        actionArray.append(SKAction.removeFromParent())
        torpedoNode.run(SKAction.sequence(actionArray))
        
    }
    func didBegin(_ contact: SKPhysicsContact) {
        var firstBody:SKPhysicsBody
        var secondBody:SKPhysicsBody
        if contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask {
            firstBody = contact.bodyA
            secondBody = contact.bodyB
        }else{
            firstBody = contact.bodyB
            secondBody = contact.bodyA
        }
        if (firstBody.categoryBitMask & photonTorPedOCategory) != 0 && (secondBody.categoryBitMask & alienCategory) != 0 {
            torpedoDidCollidewithAlie(torpedoNode: firstBody.node as! SKSpriteNode, alienNode: secondBody.node as! SKSpriteNode)
        }
    }
    func torpedoDidCollidewithAlie(torpedoNode:SKSpriteNode, alienNode: SKSpriteNode){
        let explosion = SKEmitterNode(fileNamed: "Explosion")
        explosion?.position = alienNode.position
        self.addChild(explosion!)
        self.run(SKAction.playSoundFileNamed("explosion.mp3", waitForCompletion: false))
        torpedoNode.removeFromParent()
        alienNode.removeFromParent()
        self.run(SKAction.wait(forDuration: 2)) {
            explosion?.removeFromParent()
        }
        score += 5
    }
    
    override func didSimulatePhysics() {
        player.position.x += xAcceleration * 50
        if player.position.x < -20 {
            player.position = CGPoint(x: self.size.width, y: player.position.y)
        }else if player.position.x > self.size.width + 20 {
            player.position = CGPoint(x: -20, y: player.position.y)
        }
    }
    
    
    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
    }
}
