//
//  SoundManager.swift
//  CrazyFlyBird
//
//  Created by ben on 16/10/29.
//  Copyright © 2016年 张增强. All rights reserved.
//

import SpriteKit
import AVFoundation

class SoundManager: SKNode {
    var bgMusicPlayer:AVAudioPlayer = AVAudioPlayer()
    let flapAct = SKAction.playSoundFileNamed("flapping.wav", waitForCompletion: false)
    let dingAct = SKAction.playSoundFileNamed("ding.wav", waitForCompletion: false)
    let whackAct = SKAction.playSoundFileNamed("whack.wav", waitForCompletion: false)
    let fallAct = SKAction.playSoundFileNamed("falling.wav", waitForCompletion: false)
    let hitAct = SKAction.playSoundFileNamed("hitGround.wav", waitForCompletion: false)
    let popAct = SKAction.playSoundFileNamed("pop.wav", waitForCompletion: false)
    let coinAct = SKAction.playSoundFileNamed("coin.wav", waitForCompletion: false)
    
 
    func playFlap() -> Void {
        self.runAction(flapAct)
    }
    
    func playDing() -> Void {
        self.runAction(dingAct)
    }
    
    func playWhack() -> Void {
        self.runAction(whackAct)
    }
    
    func playFall() -> Void {
        self.runAction(fallAct)
    }
    
    func playHit() -> Void {
        self.runAction(hitAct)
    }
    
    func playPop() -> Void {
        self.runAction(popAct)
    }
    
    func playCoin() -> Void {
        self.runAction(coinAct)
    }
}