//
//  Game.swift
//
//  Created by Adwitiya Chakraborty & Stefano Gatto.
//  Trinity College Dublin
//  CS7GV4 - Augmented Reality Game

import Foundation

class Game {
    
    var delegate : GameDelegate?
    
    let cooldown = 0.3 // Player shot cooldown in number of seconds
    let power = 5 // How much power a player bullet has
    var health = 100  { // How much health the player has
        didSet{
            delegate?.healthDidChange()
        }
    }
    
    var lastShot : TimeInterval = 0 // Stores the last time user shot
    
    func playerCanShoot() -> Bool { // runs 60 fps
        let curTime = Date().timeIntervalSince1970
        if(curTime - lastShot > cooldown){
            lastShot = curTime
            return true
        }
        return false
    }
    
    var spawnCount = 0 // Counter to trigger the spawn
    let spawnFreq = 60 // How often it will try to spawn an alien
    let spawnProb : UInt32 = 2 // Gives a 1 in (n + 1) chance it will spawn an alien when it tries.
    
    var maxAliens = 5 // Max number of aliens that can be spawned.
    var spawnedAliens = 0
    let alienPower = 3 // How much health an alien bullet takes away
    let alienHealth = 5 // How much health an alien has
        
    var winLoseFlag : Bool? // optional for whether player has win, lost, or neither
    
    var level1_Score = 5
    var level2_Score = 15
    var levelf_Score = 30
    var current_level = 1

    var score = 0 { // Stores the current score
        didSet{
            delegate?.scoreDidChange()
        }
    }
    
    func spawnAlien() -> Alien?{ // Decides whether an alien should be spawned
        guard spawnedAliens < maxAliens else { return nil }
        spawnCount += 1
        if(spawnCount == spawnFreq){
            spawnCount = 0
            if(arc4random_uniform(spawnProb) == 0){
                spawnedAliens = spawnedAliens + 1
                if current_level == 1 {
                    return Alien(health: 1, power: 1, shotFreq: 60, shotProbHigh: 10, shotProbLow: 2, type: .small)
                }
                if current_level == 2 {
                    return Alien(health: 3, power: 3, shotFreq: 55, shotProbHigh: 10, shotProbLow: 2, type: .medium)
                }
                if current_level == 3 {
                    return Alien(health: 5, power: 5, shotFreq: 55, shotProbHigh: 10, shotProbLow: 2, type: .large)
                }
            }
        }
        return nil
    }
    
    
    

}

protocol GameDelegate {

    func scoreDidChange()
    func healthDidChange()
}

