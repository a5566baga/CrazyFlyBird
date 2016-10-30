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
 
    func playFlap() -> Void {
        self.runAction(flapAct)
    }
    
}