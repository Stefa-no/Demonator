//
//  Demon.swift
//
//  Created by Adwitiya Chakraborty & Stefano Gatto.
//  Trinity College Dublin
//  CS7GV4 - Augmented Reality Game

import ARKit
import UIKit

class DemonNode : SCNNodeContainer{
    
    
    var node : SCNNode!
    var demon : Demon
    var lastAxis = SCNVector3Make(0, 0, 0)
    
    var spawnCount = 0
    
    
    init(demon: Demon, position: SCNVector3, cameraPosition: SCNVector3) {

        self.demon = demon
        self.node = createNode()
        self.node.position = position
        self.node.rotation = SCNVector4Make(0, 1, 0, 0)
        
        let deltaRotation = getXZRotation(towardsPosition: cameraPosition)
        if deltaRotation > 0 {
            node.rotation.w -= deltaRotation
        }else if deltaRotation < 0 {
            node.rotation.w -= deltaRotation
        }
    }
    
    /// Returns: the angle in the XZ plane that the demon must rotate to face the position passed in
    func getXZRotation(towardsPosition toPosition: SCNVector3) -> Float {
        
        // Creates the normalized XZ Distance vector
        var unitDistance = (toPosition - node.position).negate()
        unitDistance.y = 0
        unitDistance = unitDistance.normalized()
        
        // Creates the normalized XZ Direction vector for the demon (which way it is facing)
        var unitDirection = self.node.convertPosition(SCNVector3Make(0, 0, -1), to: nil) - self.node.position
        unitDirection.y = 0
        unitDirection = unitDirection.normalized()
        
        // Finds the angle between the two vectors and uses the direction of the cross product to decide it's sign
        let axis = unitDistance.cross(vector: unitDirection).normalized()
        let angle = acos(unitDistance.dot(vector: unitDirection))
        return angle * axis.y
    }
    
    private func createNode() -> SCNNode{
        // Set the general scale for the demon image. 
        // In the future we should really change the images
        var scaleFactor = demon.frontImage.size.width/0.2
        if demon.type == DemonType.boss {
            scaleFactor = demon.frontImage.size.width/0.8
        }
        let width = demon.frontImage.size.width/scaleFactor
        let height = demon.frontImage.size.height/scaleFactor
        
        
        
        // Creates a Plane Geometry object to represent the front of the demon
        let geometryFront = SCNPlane(width: width, height: height)
        let materialFront = SCNMaterial()
        materialFront.diffuse.contents = demon.frontImage
        geometryFront.materials = [materialFront]
        
        // Creates a Plane Geometry object to represent the back of the demon
        let geometryBack = SCNPlane(width: width, height: height)
        let materialBack = SCNMaterial()
        materialBack.diffuse.contents = demon.backImage
        geometryBack.materials = [materialBack]
        
        // Creates nodes for both and sets the backNode's position to be directly
        // behind the main node
        let mainNode = SCNNode(geometry: geometryFront)
        let backNode = SCNNode(geometry: geometryBack)
        backNode.position = SCNVector3Make(0,0,0)
        backNode.rotation = SCNVector4Make(0, 1, 0, Float.pi)
        
        // Main Node has a static physics body so that we can control it's
        // motion by changing it's position. Then we can still use it's contactTestBitMask
        // property without having to worry about forces.
        mainNode.physicsBody = SCNPhysicsBody(type: .static, shape: nil)
        mainNode.physicsBody?.contactTestBitMask = PhysicsMask.enemy
        mainNode.physicsBody?.isAffectedByGravity = false
        //mainNode.addChildNode(backNode)
        
        let formatter = DateFormatter()
        // initially set the format based on your datepicker date
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let myString = formatter.string(from: Date())
        mainNode.name = myString
        
        return mainNode
    }
    
    
    /**
     Note: This function will be run every frame—typically 60 fps.
     If it returns false, the demon will be removed from the world
     and a life will be deducted
    */
    func move(towardsPosition toPosition : SCNVector3) -> Bool{
        
        // Finds the distance vector between demon and player and normalizes it
        let deltaPos = (toPosition - node.position)
        
        // If demon is effectively in contact with the player, return false to tell the Controller to remove it.
        guard deltaPos.length() > 0.05 else { return false }
        let normDeltaPos = deltaPos.normalized()
        
        // Always shift the y position closer towards the player
        node.position.y += normDeltaPos.y/50

        // consider the distance in the XY Plane
        let length = deltaPos.xzLength()
        
        // If we're in the "goldilocks zone" then don't move, otherwise get closer to the player
        // If demon is really close to the player, then the demon will simply go in for the kill
        if length > 0.5 || length < 0.1 {
            node.position.x += normDeltaPos.x/250
            node.position.z += normDeltaPos.z/250
            demon.closeQuarters = false
        }else{
            demon.closeQuarters = true
        }
        
        // Find the angle we must rotate by to face the player
        let goalRotation = getXZRotation(towardsPosition: toPosition)
        
        // Rotate by a small fraction of that angle
        if goalRotation > 0 {
            node.rotation.w -= min(Float.pi/180, goalRotation)
        }else if goalRotation < 0 {
            node.rotation.w -= max(-Float.pi/180, goalRotation)
        }
        
        return true
    }
    
    
}


