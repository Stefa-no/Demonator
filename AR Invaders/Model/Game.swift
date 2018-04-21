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
    var health = 1000  { // How much health the player has
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
    let spawnFreq = 60 // How often it will try to spawn an demon
    let spawnProb : UInt32 = 3 // Gives a 1 in (n + 1) chance it will spawn an demon when it tries.
    
    var maxDemons = 5 // Max number of demons that can be spawned.
    var spawnedDemons = 0
    let demonPower = 3 // How much health an demon bullet takes away
    let demonHealth = 5 // How much health an demon has
        
    var winLoseFlag : Bool? // optional for whether player has win, lost, or neither
    
    var level1_Score = 5
    var level2_Score = 15
    var level3_Score = 30
    var levelf_Score = 45
    var current_level = 1

    var score = 0 { // Stores the current score
        didSet{
            delegate?.scoreDidChange()
        }
    }
    
    func spawnDemon() -> Demon?{ // Decides whether an demon should be spawned
        guard spawnedDemons < maxDemons else { return nil }
        spawnCount += 1
        if(spawnCount == spawnFreq){
            spawnCount = 0
            if(arc4random_uniform(spawnProb) == 0){
                spawnedDemons = spawnedDemons + 1
                if current_level == 1 {
                    return Demon(health: 1, power: 1, shotFreq: 60, shotProbHigh: 10, shotProbLow: 2, type: .small)
                }
                if current_level == 2 {
                    return Demon(health: 3, power: 3, shotFreq: 60, shotProbHigh: 10, shotProbLow: 2, type: .medium)
                }
                if current_level == 3 {
                    return Demon(health: 5, power: 5, shotFreq: 60, shotProbHigh: 10, shotProbLow: 2, type: .large)
                }
                if current_level == 4 {
                    return Demon(health: 15, power: 5, shotFreq: 60, shotProbHigh: 10, shotProbLow: 2, type: .boss)
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

