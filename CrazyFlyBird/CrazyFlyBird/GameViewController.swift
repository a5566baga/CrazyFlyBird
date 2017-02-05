//
//  GameViewController.swift
//  CrazyFlyBird
//
//  Created by ben on 16/10/28.
//  Copyright (c) 2016年 张增强. All rights reserved.
//

import UIKit
import SpriteKit

class GameViewController: UIViewController {
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        if let skView = self.view as? SKView  {
            if skView.scene == nil {
//                创建视图
                let lenAndWidth = skView.bounds.size.height / skView.bounds.size.width
                let scence = GameScene(size: CGSize(width: 320, height: 320 * lenAndWidth))
                skView.showsFPS = false //显示帧数
                skView.showsPhysics = false //显示物理模型边框
                skView.showsNodeCount = false //显示节点数
                skView.ignoresSiblingOrder = true //忽略元素的添加顺序
                scence.scaleMode = .AspectFill //scence的拉伸是等比例缩放
                
                skView.presentScene(scence) //添加到视图中
            }
        }
    }
}
