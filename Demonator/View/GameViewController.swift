//
//  GameViewController.swift
//
//  Created by Adwitiya Chakraborty & Stefano Gatto.
//  Trinity College Dublin
//  CS7GV4 - Augmented Reality Game

import UIKit
import ARKit
import SpriteKit
import ReplayKit
import AVFoundation

struct PhysicsMask {
    static let playerBullet = 0
    static let enemyBullet = 1
    static let enemy = 2
}

enum LaserType  {
    case player
    case enemy
}

class GameViewController: UIViewController, GameDelegate{

    
    @IBOutlet var sceneView : ARSCNView!
    var demons = [DemonNode]()
    var bossLife = 15
    var lasers = [LaserNode]()
    var game = Game()
    var flarePlayer = AVAudioPlayer()
    var magicPlayer = AVAudioPlayer()
    
    // Next 3 variables define how the score and such should be displayed on the screen
    
    lazy var paragraphStyle : NSParagraphStyle = {
        let style = NSMutableParagraphStyle()
        style.alignment = NSTextAlignment.left
        return style
    }()
    
    lazy var stringAttributes : [NSAttributedStringKey : Any] = [.strokeColor : UIColor.black, .strokeWidth : -4, .foregroundColor: UIColor.white, .font : UIFont.systemFont(ofSize: 20, weight: .bold), .paragraphStyle : paragraphStyle]
    
    lazy var titleAttributes : [NSAttributedStringKey : Any] = [.strokeColor : UIColor.black, .strokeWidth : -4, .foregroundColor: UIColor.white, .font : UIFont.systemFont(ofSize: 50, weight: .bold), .paragraphStyle : paragraphStyle]
    
     lazy var levelAttributers : [NSAttributedStringKey : Any] = [.strokeColor : UIColor.black, .strokeWidth : -4, .foregroundColor: UIColor.white, .font : UIFont.systemFont(ofSize: 40, weight: .bold), .paragraphStyle : paragraphStyle]
    
    // Nodes for the scene itself
    var scoreNode : SKLabelNode!
    var livesNode : SKLabelNode!
    var bossLifeNode: SKLabelNode!
    var winNode : SKLabelNode!
    var radarNode : SKShapeNode!
    
    let topPadding : CGFloat = 20
    let sidePadding : CGFloat = 5
    

    var isRecording = false // Used to toggle screen recording

    
    //MARK: GameDelegate Functions
    
    func scoreDidChange() {
        scoreNode.attributedText = NSMutableAttributedString(string: "Points: \(game.score)", attributes: stringAttributes)
        if game.score == game.level1_Score && game.current_level == 1 {
            game.current_level = 2
            game.winLoseFlag = true
            showFinish()
        }
        if game.score == game.level2_Score && game.current_level == 2 {
            game.current_level = 3
            game.winLoseFlag = true
            showFinish()
        }
        if game.score == game.level3_Score && game.current_level == 3 {
            game.current_level = 4
            game.winLoseFlag = true
            showFinish()
        }
        if game.score == game.levelf_Score && game.current_level == 4 {
            game.current_level = 5
            game.winLoseFlag = true
            showFinish()
        }
        
    }
    
    func healthDidChange() {
        livesNode.attributedText = NSAttributedString(string: "Life: \(game.health)", attributes: stringAttributes)
        if game.health <= 0 {
            game.winLoseFlag = false
            game.current_level = 5
            showFinish()
        }
    }

    
    //MARK: View Controller Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupScene()
        setupGestureRecognizers()
        game.delegate = self
        do{
            flarePlayer = try AVAudioPlayer(contentsOf: URL.init(fileURLWithPath: Bundle.main.path(forResource: "fireball", ofType: "mp3")!))
            flarePlayer.prepareToPlay()
            magicPlayer = try AVAudioPlayer(contentsOf: URL.init(fileURLWithPath: Bundle.main.path(forResource: "magic", ofType: "mp3")!))
            magicPlayer.prepareToPlay()
            
        }
        catch{
            print(error)
        }
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        configureScene()
    }
    
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sceneView.session.pause()
    }
    
    //Mark: UI Setup
    
    private func setupScene(){
        sceneView.delegate = self
        sceneView.scene = SCNScene()
        sceneView.scene.physicsWorld.contactDelegate = self
        sceneView.overlaySKScene = SKScene(size: sceneView.bounds.size)
        sceneView.overlaySKScene?.scaleMode = .resizeFill
        setupLabels()
        setupRadar()
    }

    
    private func configureScene(){
        let config = ARWorldTrackingConfiguration()
        sceneView.session.run(config)
    }
    
    private func setupGestureRecognizers(){
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap(recognizer:)))
        let threeTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleThreeFingerTap(sender:)))
        
        threeTapRecognizer.numberOfTouchesRequired = 3
        tapRecognizer.numberOfTouchesRequired = 1
        
        sceneView.addGestureRecognizer(tapRecognizer)
        sceneView.addGestureRecognizer(threeTapRecognizer)
    }
    
    private func setupRadar(){
        let size = sceneView.bounds.size

        radarNode = SKShapeNode(circleOfRadius: 40)
        radarNode.position = CGPoint(x: (size.width - 40) - sidePadding, y: 50 + sidePadding)
        radarNode.strokeColor = .black
        radarNode.glowWidth = 5
        radarNode.fillColor = .white
        sceneView.overlaySKScene?.addChild(radarNode)

        for i in (1...3){
            let ringNode = SKShapeNode(circleOfRadius: CGFloat(i * 10))
            ringNode.strokeColor = .black
            ringNode.glowWidth = 0.2
            ringNode.name = "Ring"
            ringNode.position = radarNode.position
            sceneView.overlaySKScene?.addChild(ringNode)
        }
        
        for _ in (0..<(game.maxDemons)){
            let blip = SKShapeNode(circleOfRadius: 5)
            blip.fillColor = .red
            blip.strokeColor = .clear
            blip.alpha = 0
            radarNode.addChild(blip)
        }
        
    }
    
    private func setupLabels(){
        let size = sceneView.bounds.size

        scoreNode = SKLabelNode(attributedText: NSAttributedString(string: "Points: \(game.score)", attributes: stringAttributes))
        livesNode = SKLabelNode(attributedText: NSAttributedString(string: "Life: \(game.health)", attributes: stringAttributes))
        bossLifeNode = SKLabelNode(attributedText: NSAttributedString(string: "Boss Life: \(bossLife)", attributes: stringAttributes))
        bossLifeNode.alpha = 0
        winNode = SKLabelNode(text: "Default")
        winNode.alpha = 0
    
        
        scoreNode.position = CGPoint(x: (size.width - scoreNode.frame.width/2) - sidePadding, y: (size.height - scoreNode.frame.height) - topPadding)
        livesNode.position = CGPoint(x: sidePadding + livesNode.frame.width/2, y: (size.height - livesNode.frame.height) - topPadding )
        bossLifeNode.position = CGPoint(x: size.width/2 , y: 4 * size.height / 5)
        winNode.position = CGPoint(x: size.width/2, y: size.height/2)
        
        sceneView.overlaySKScene?.addChild(scoreNode)
        sceneView.overlaySKScene?.addChild(livesNode)
        sceneView.overlaySKScene?.addChild(winNode)
        sceneView.overlaySKScene?.addChild(bossLifeNode)
    }
    
    private func showFinish(){
        guard let hasWon = game.winLoseFlag else { return }
        winNode.alpha = 1
        if game.current_level == 2 {
            winNode.attributedText = NSAttributedString(string: hasWon ? "Level 1 completed!" : "You Lose!", attributes: levelAttributers)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0, execute: {
                self.winNode.alpha = 0
                self.game.winLoseFlag = nil
                self.game.maxDemons = 15
            })
            
        }
        else if game.current_level == 3 {
            winNode.attributedText = NSAttributedString(string: hasWon ? "Level 2 completed!" : "You Lose!", attributes: levelAttributers)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0, execute: {
                self.winNode.alpha = 0
                self.game.winLoseFlag = nil
                self.game.maxDemons = 30
            })
            
        }
        else if game.current_level == 4 {
            winNode.attributedText = NSAttributedString(string: hasWon ? "Prepare for boss" : "You Lose!", attributes: levelAttributers)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0, execute: {
                self.bossLifeNode.alpha = 1
                self.winNode.alpha = 0
                self.game.winLoseFlag = nil
                self.game.maxDemons = 31
            })
            
        }
        else if game.current_level == 5 {
            winNode.attributedText = NSAttributedString(string: hasWon ? "You Win!" : "You Lose!", attributes: titleAttributes)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0, execute: {
                if self.isRecording {
                    self.handleThreeFingerTap(sender: UITapGestureRecognizer())
                }
                self.performSegue(withIdentifier: "unwind", sender: self)
            })
        }
    }
    
    //Mark: UI Gesture Actions

    @objc func handleTap(recognizer: UITapGestureRecognizer){
        if game.playerCanShoot() {
            fireLaser(fromNode: sceneView.pointOfView!, type: .player)
        }
    }
    
    @objc func handleThreeFingerTap(sender: UITapGestureRecognizer){
       
    }
    
    //MARK: Game Actions
    
    func fireLaser(fromNode node: SCNNode, type: LaserType){
        guard game.winLoseFlag == nil else { return }
        let pov = sceneView.pointOfView!
        var position: SCNVector3
        var convertedPosition: SCNVector3
        var direction : SCNVector3
        switch type {
            
        case .enemy:
            // If enemy, shoot in the direction of the player
            position = SCNVector3Make(0, 0, 0.05)
            convertedPosition = node.convertPosition(position, to: nil)
            direction = pov.position - node.position
            if flarePlayer.isPlaying{
                flarePlayer.currentTime = 0
            }
            flarePlayer.play()
        default:
            // If player, shoot straight ahead
            position = SCNVector3Make(0, 0, -0.05)
            convertedPosition = node.convertPosition(position, to: nil)
            direction = convertedPosition - pov.position
            if magicPlayer.isPlaying{
                magicPlayer.currentTime = 0
            }
            magicPlayer.play()
        }
        let laser = LaserNode(initialPosition: convertedPosition, direction: direction, type: type)
        lasers.append(laser)
        sceneView.scene.rootNode.addChildNode(laser.node)
        
    }
    
    private func spawnDemon(demon: Demon){
        let pov = sceneView.pointOfView!
        let y = (Float(arc4random_uniform(60)) - 29) * 0.01 // Random Y Value between -0.3 and 0.3
        
        //Random X and Z value around the circle
        let xRad = ((Float(arc4random_uniform(361)) - 180)/180) * Float.pi
        let zRad = ((Float(arc4random_uniform(361)) - 180)/180) * Float.pi
        let length = Float(arc4random_uniform(6) + 4) * -0.3
        let x = length * sin(xRad)
        let z = length * cos(zRad)
        let position = SCNVector3Make(x, y, z)
        let worldPosition = pov.convertPosition(position, to: nil)
        let demonNode = DemonNode(demon: demon, position: worldPosition, cameraPosition: pov.position)
        //let particleNode = SCNNode()
        //let particleSystem = SCNParticleSystem(named: "fire", inDirectory: "")
        //particleNode.addParticleSystem(particleSystem!)
        //demonNode.node.addChildNode(particleNode)
        demons.append(demonNode)
        sceneView.scene.rootNode.addChildNode(demonNode.node)
    }

}

//MARK: Scene Physics Contact Delegate

extension GameViewController : SCNPhysicsContactDelegate {
    
    func physicsWorld(_ world: SCNPhysicsWorld, didBegin contact: SCNPhysicsContact) {
        let maskA = contact.nodeA.physicsBody!.contactTestBitMask
        let maskB = contact.nodeB.physicsBody!.contactTestBitMask

        switch(maskA, maskB){
        case (PhysicsMask.enemy, PhysicsMask.playerBullet):
            hitEnemy(bullet: contact.nodeB, enemy: contact.nodeA)
        case (PhysicsMask.playerBullet, PhysicsMask.enemy):
            hitEnemy(bullet: contact.nodeA, enemy: contact.nodeB)
        default:
            break
        }
    }
    
    func hitEnemy(bullet: SCNNode, enemy: SCNNode){
        bullet.physicsBody = nil
        DispatchQueue.main.async(execute: {
            bullet.removeFromParentNode()
        })
        if game.current_level == 4 {
            bossLife -= 5
            game.score += 5
            bossLifeNode.attributedText = NSMutableAttributedString(string: "Boss Life: \(bossLife)", attributes: stringAttributes)
            if bossLife <= 0 {
                enemy.physicsBody = nil
                DispatchQueue.main.async(execute: {
                    enemy.removeFromParentNode()
                })
            }
        }
        else{
            enemy.physicsBody = nil
            DispatchQueue.main.async(execute: {
                enemy.removeFromParentNode()
            })
            game.score += 1
        }
    }
}

//MARK: AR SceneView Delegate
extension GameViewController : ARSCNViewDelegate{
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        guard game.winLoseFlag == nil else { return }

        // Lets the game object give an demon to spawn
        if let demon = game.spawnDemon(){
            spawnDemon(demon: demon)
        }
        
        for (i, demon) in demons.enumerated().reversed() {
            
            // If demon isn't in the world any more, then remove it from our demon list
            guard demon.node.parent != nil else {
                demons.remove(at: i)
                continue
            }
            
            // Move demon closer to where they need to go
            if demon.move(towardsPosition: sceneView.pointOfView!.position) == false {
                // If move function returned false, assume a crash and remove demon from world.
               // for particle in demon.node.childNodes{
                //    DispatchQueue.main.async(execute: {
               //         particle.removeFromParentNode()
               //     })
              //  }
                demon.node.physicsBody = nil
                DispatchQueue.main.async(execute: {
                    demon.node.removeFromParentNode()
                })
                demons.remove(at: i)
                game.health -= demon.demon.health
                if game.current_level == 1 {
                    let newDemon = Demon(health: 1, power: 1, shotFreq: 60, shotProbHigh: 10, shotProbLow: 2, type: .small)
                    spawnDemon(demon: newDemon)
                }
                else if game.current_level == 2 {
                     let newDemon = Demon(health: 3, power: 3, shotFreq: 55, shotProbHigh: 10, shotProbLow: 2, type: .medium)
                    spawnDemon(demon: newDemon)
                }
                else if game.current_level == 3 {
                    let newDemon = Demon(health: 5, power: 5, shotFreq: 55, shotProbHigh: 10, shotProbLow: 2, type: .large)
                    spawnDemon(demon: newDemon)
                }
                else {
                     let newDemon = Demon(health: 15, power: 5, shotFreq: 55, shotProbHigh: 10, shotProbLow: 2, type: .boss)
                    spawnDemon(demon: newDemon)
                }
            }else {
            
                if demon.demon.shouldShoot() {
                    fireLaser(fromNode: demon.node, type: .enemy)
                }
            }
        }
        
        // Draw demons on the radar as an XZ Plane
        for (i, blip) in radarNode.children.enumerated() {
            if i < demons.count {
                let demon = demons[i]
                blip.alpha = 1
                let relativePosition = sceneView.pointOfView!.convertPosition(demon.node.position, from: nil)
                var x = relativePosition.x * 10
                var y = relativePosition.z * -10
                if x >= 0 { x = min(x, 35) } else { x = max(x, -35)}
                if y >= 0 { y = min(y, 35) } else { y = max(y, -35)}
                blip.position = CGPoint(x: CGFloat(x), y: CGFloat(y))
            }else{
                // If there are less demons than the max amount, hide the extra blips.
                // Note: SceneKit seemed to have a problem with dynmically adding and
                // removing blips so I removed that feature and stuck with a static maximum.
                blip.alpha = 0
            }
            
        }
        
        for (i, laser) in lasers.enumerated().reversed() {
            if laser.node.parent == nil {
                // If laser is no longer in the world, remove it from our list
                lasers.remove(at: i)
                continue
            }
            // Move the lasers and remove if necessary
            if laser.move() == false {
                for particle in laser.node.childNodes{
                    particle.removeFromParentNode()
                }
                laser.node.physicsBody = nil
                DispatchQueue.main.async(execute: {
                    laser.node.removeFromParentNode()
                })
                self.lasers.remove(at: i)
                //laser.node.removeFromParentNode()
                //lasers.remove(at: i)
            }else{
                // Check for a hit against the player
                if laser.node.physicsBody?.contactTestBitMask == PhysicsMask.enemyBullet
                    && laser.node.position.distance(vector: sceneView.pointOfView!.position) < 0.1 {
                    for particle in laser.node.childNodes{
                        particle.removeFromParentNode()
                    }
                    laser.node.physicsBody = nil
                    DispatchQueue.main.async(execute: {
                        laser.node.removeFromParentNode()
                    })
                    self.lasers.remove(at: i)
              //      laser.node.physicsBody = nil
             //       if (laser.node == nil ) {print ("laser node")}
              //      if (laser == nil ) {print (" laser")}
              //      if (laser.node.parent == nil ) {print ("parent node")}
               //     laser.node.removeFromParentNode()
               //     lasers.remove(at: i)
                    if game.current_level == 1{
                        game.health -= 1
                    }
                    if game.current_level == 2{
                        game.health -= 3
                    }
                    if game.current_level == 3{
                        game.health -= 5
                    }
                    if game.current_level == 4{
                        game.health -= 5
                    }
                }
            }
        }
    }
    
    
    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        switch camera.trackingState {
        case .notAvailable:
            print("Camera Not Available")
        case .limited(let reason):
            switch reason {
            case .excessiveMotion:
                print("Camera Tracking State Limited Due to Excessive Motion")
            case .initializing:
                print("Camera Tracking State Limited Due to Initalization")
            case .insufficientFeatures:
                print("Camera Tracking State Limited Due to Insufficient Features")
            case .relocalizing:
                print("Camera Tracking State Limited Due to Insufficient Features")
            }
        case .normal:
            print("Camera Tracking State Normal")
        }
    }
    func session(_ session: ARSession, didFailWithError error: Error) {
        print("Session Failed with error: \(error.localizedDescription)")
        // Present an error message to the user
        
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        print("Session Interrupted")
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        print("Session no longer being interrupted")
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        
    }

}


