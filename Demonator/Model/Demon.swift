//
//  Demon.swift
//
//  Created by Adwitiya Chakraborty & Stefano Gatto.
//  Trinity College Dublin
//  CS7GV4 - Augmented Reality Game

import UIKit

enum DemonType {
    case small
    case medium
    case large
    case boss
    
    func getImages() -> (front: UIImage, back: UIImage){
        switch self {
        case .small: return (#imageLiteral(resourceName: "Flying_Fire_Monster"), #imageLiteral(resourceName: "Flying_Fire_Monster"))
        case .medium: return ( #imageLiteral(resourceName: "PirosFFVIII"), #imageLiteral(resourceName: "PirosFFVIII"))
        case .large: return (#imageLiteral(resourceName: "golem3-512"), #imageLiteral(resourceName: "golem3-512"))
        case .boss: return (#imageLiteral(resourceName: "boi2"),#imageLiteral(resourceName: "boi2"))
        }
    }
}


class Demon {
    
    var health : Int
    let power : Int
    let scoreReward : Int
    var shotCount = 0
    let shotFreq : Int // How often it tries to shoot
    var shotProb : Int { //What's the chance it succeeds in shooting (Chance = 1/shotProb)
        return closeQuarters ? shotProbHigh : shotProbLow
    }
    private let shotProbHigh : Int
    private let shotProbLow : Int
    
    var closeQuarters = false // Whether it is in the goldilocks zone
    let frontImage : UIImage
    let backImage : UIImage
    
    init(health: Int, power: Int, shotFreq: Int, shotProbHigh: Int, shotProbLow: Int, type: DemonType){
        
        self.health = health
        self.scoreReward = health * 10
        self.power = power
        self.shotFreq = shotFreq
        self.shotProbLow = shotProbLow
        self.shotProbHigh = shotProbHigh
        
        let images = type.getImages()
        self.frontImage = images.front
        self.backImage = images.back
        
    }
    
    func shouldShoot() -> Bool { // runs 60 fps
        shotCount += 1
        if(shotCount == shotFreq){
            shotCount = 0
            return arc4random_uniform(UInt32(shotProb)) == 0
        }
        return false
    }
}
