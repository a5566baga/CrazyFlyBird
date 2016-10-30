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
        
        if let sk视图 = self.view as? SKView  {
            if sk视图.scene == nil {
//                创建视图
                let 长宽比 = sk视图.bounds.size.height / sk视图.bounds.size.width
                let 场景 = GameScene(size: CGSize(width: 320, height: 320 * 长宽比))
                sk视图.showsFPS = true //显示帧数
                sk视图.showsPhysics = true //显示物理模型边框
                sk视图.showsNodeCount = true //显示节点数
                sk视图.ignoresSiblingOrder = true //忽略元素的添加顺序
                场景.scaleMode = .AspectFill //场景的拉伸是等比例缩放
                
                sk视图.presentScene(场景) //添加到视图中
            }
        }
    }
}
