//
//  GameScene.swift
//  CrazyFlyBird
//
//  Created by ben on 16/10/28.
//  Copyright (c) 2016年 张增强. All rights reserved.
//

import SpriteKit
import AVFoundation

enum 图层:CGFloat {
    case 背景
    case 障碍物
    case 前景
    case 角色单位
}

struct 物理层 {
    static let 无:UInt32 = 0
    static let 游戏角色:UInt32 = 0b1 //1
    static let 障碍物:UInt32 = 0b10 //2
    static let 地面:UInt32 = 0b100 //4
}

enum 游戏状态 {
    case 主菜单
    case 教程
    case 游戏
    case 跌落
    case 显示分数
    case 结束
}

class GameScene: SKScene, SKPhysicsContactDelegate {
    
//    添加音效
    lazy var sounds = SoundManager()
    
//    鸟飞的速度和重力
    let k重力:CGFloat = -1500.0
    let k上冲速度:CGFloat = 400.0
    var 速度 = CGPoint.zero
    
//    底部障碍的倍数
    let k底部障碍的最小乘数:CGFloat = 0.1
    let k底部障碍的最大乘数:CGFloat = 0.6
    let k缺口乘数:CGFloat = 3.5
    let k首次生成障碍延时:NSTimeInterval = 1.75
    let k每次生成障碍延时:NSTimeInterval = 1.5
    var 撞击了地面 = false
    var 撞击了障碍物 = false
    var 当前游戏状态:游戏状态 = .游戏
    
    

//    前景页面的移动
    let k前景页面数 = 2
    let k地面移动速度:CGFloat = -150.0
    
//    基本单位
    let 世界单位 = SKNode()
    var 游戏区域起始点:CGFloat = 0
    var 游戏区域的高度:CGFloat = 0
    let 主角 = SKSpriteNode(imageNamed: "Bird0")
    let 帽子 = SKSpriteNode(imageNamed: "Sombrero")
    
    var 上一次更新时间:NSTimeInterval = 0
    var dt:NSTimeInterval = 0
    
    override func didMoveToView(view: SKView) {
       
//        关掉重力
        physicsWorld.gravity = CGVector(dx: 0, dy: 0)
        physicsWorld.contactDelegate = self
        
        addChild(世界单位)
        设置背景()
        设置前景()
        设置主角()
        addChild(sounds)
//        生成障碍()
        无限重生障碍()
        设置帽子()
        
    }
//    MARK: 设置内容相关
    
    func 设置音效() -> Void {
        sounds.playFlap()
    }
    
    func 设置背景() -> Void {
        let 背景 = SKSpriteNode(imageNamed: "Background")
        背景.anchorPoint = CGPoint(x: 0.5, y: 1)
        背景.position = CGPoint(x: size.width/2, y: size.height)
        背景.zPosition = 图层.背景.rawValue
        游戏区域起始点 = size.height - 背景.size.height
        游戏区域的高度 = 背景.size.height
        世界单位.addChild(背景)
        
        let 左下 = CGPoint(x: 0, y: 游戏区域起始点)
        let 右下 = CGPoint(x: size.width, y: 游戏区域起始点)
        self.physicsBody = SKPhysicsBody(edgeFromPoint: 左下, toPoint: 右下)
        self.physicsBody?.categoryBitMask = 物理层.地面
        self.physicsBody?.collisionBitMask = 0
        self.physicsBody?.contactTestBitMask = 物理层.游戏角色
        
    }
    
    func 设置主角() -> Void {
        主角.position = CGPoint(x: size.width*0.2, y: size.height*0.4+游戏区域起始点)
        主角.zPosition = 图层.前景.rawValue
        
        let offsetX = 主角.size.width * 主角.anchorPoint.x
        let offsetY = 主角.size.height * 主角.anchorPoint.y
        
        let path = CGPathCreateMutable()
        
        CGPathMoveToPoint(path, nil, 23 - offsetX, 30 - offsetY);
        CGPathAddLineToPoint(path, nil, 33 - offsetX, 30 - offsetY);
        CGPathAddLineToPoint(path, nil, 35 - offsetX, 30 - offsetY);
        CGPathAddLineToPoint(path, nil, 36 - offsetX, 28 - offsetY);
        CGPathAddLineToPoint(path, nil, 39 - offsetX, 23 - offsetY);
        CGPathAddLineToPoint(path, nil, 39 - offsetX, 19 - offsetY);
        CGPathAddLineToPoint(path, nil, 40 - offsetX, 7 - offsetY);
        CGPathAddLineToPoint(path, nil, 40 - offsetX, 5 - offsetY);
        CGPathAddLineToPoint(path, nil, 39 - offsetX, 2 - offsetY);
        CGPathAddLineToPoint(path, nil, 38 - offsetX, 1 - offsetY);
        CGPathAddLineToPoint(path, nil, 20 - offsetX, 1 - offsetY);
        CGPathAddLineToPoint(path, nil, 8 - offsetX, 5 - offsetY);
        CGPathAddLineToPoint(path, nil, 3 - offsetX, 8 - offsetY);
        CGPathAddLineToPoint(path, nil, 1 - offsetX, 10 - offsetY);
        CGPathAddLineToPoint(path, nil, 0 - offsetX, 15 - offsetY);
        CGPathAddLineToPoint(path, nil, 0 - offsetX, 21 - offsetY);
        CGPathAddLineToPoint(path, nil, 1 - offsetX, 23 - offsetY);
        
        CGPathCloseSubpath(path)
        
        主角.physicsBody = SKPhysicsBody(polygonFromPath: path)
        
        主角.physicsBody?.categoryBitMask = 物理层.游戏角色
        主角.physicsBody?.collisionBitMask = 0
        主角.physicsBody?.contactTestBitMask = 物理层.地面 | 物理层.障碍物
        
        世界单位.addChild(主角)
    }
    
    func 设置帽子() -> Void {
        帽子.position = CGPoint(x: 25 - 帽子.size.width/2, y: 29 - 帽子.size.height/2)
        主角.addChild(帽子)
    }
    
    func 设置前景() -> Void {
        for i in 0..<k前景页面数 {
            let 前景 = SKSpriteNode(imageNamed: "Ground")
            前景.anchorPoint = CGPoint(x: 0, y: 1.0)
            前景.position = CGPoint(x: CGFloat(i) * 前景.size.width, y: 游戏区域起始点)
            前景.zPosition = 图层.前景.rawValue
            前景.name = "前景"
            世界单位.addChild(前景)
        }
    }
    
//    MARK:游戏开玩
    func 主角飞一下() -> Void {
        速度 = CGPoint(x: 0, y: k上冲速度)
        设置音效()
//        移动帽子
        let 向上移动 = SKAction.moveByX(0, y: 10, duration: 0.15)
        向上移动.timingMode = .EaseInEaseOut
        
        let 向下移动 = 向上移动.reversedAction()
        帽子.runAction(SKAction.sequence([向上移动, 向下移动]))
    }
    
    func 创建障碍物(图片名:String) -> SKSpriteNode {
        let 障碍物 = SKSpriteNode(imageNamed: 图片名);
        障碍物.zPosition = 图层.障碍物.rawValue
        
        let offsetX = 障碍物.size.width * 障碍物.anchorPoint.x
        let offsetY = 障碍物.size.height * 障碍物.anchorPoint.y
        
        let path = CGPathCreateMutable()
        
        CGPathMoveToPoint(path, nil, 6 - offsetX, 1 - offsetY)
        CGPathAddLineToPoint(path, nil, 7 - offsetX, 311 - offsetY)
        CGPathAddLineToPoint(path, nil, 48 - offsetX, 311 - offsetY)
        CGPathAddLineToPoint(path, nil, 46 - offsetX, 1 - offsetY)
        
        CGPathCloseSubpath(path)
        
        障碍物.physicsBody = SKPhysicsBody(polygonFromPath: path)
        障碍物.physicsBody?.categoryBitMask = 物理层.障碍物
        障碍物.physicsBody?.collisionBitMask = 0
        障碍物.physicsBody?.contactTestBitMask = 物理层.游戏角色
        
        return 障碍物
    }
    
    func 生成障碍() -> Void {
        let 底部障碍 = 创建障碍物("CactusBottom")
        let 起始X坐标 = self.size.width + 底部障碍.size.width/2
        
        let Y坐标最小值 = (游戏区域起始点 - 底部障碍.size.height/2) + 游戏区域的高度 * k底部障碍的最小乘数
        let Y坐标最大值 = (游戏区域起始点 - 底部障碍.size.height/2) + 游戏区域的高度 * k底部障碍的最大乘数
        
        底部障碍.position = CGPointMake(起始X坐标, CGFloat.random(min: Y坐标最小值, max: Y坐标最大值))
        底部障碍.name = "底部障碍"
        世界单位.addChild(底部障碍)
        
        let 顶部障碍 = 创建障碍物("CactusTop")
        顶部障碍.zRotation = CGFloat(180).degreesToRadians()
        顶部障碍.position = CGPoint(x: 起始X坐标, y: 底部障碍.position.y + 底部障碍.size.height/2 + 顶部障碍.size.height/2 + 主角.size.height * k缺口乘数)
        顶部障碍.name = "顶部障碍"
        世界单位.addChild(顶部障碍)
        
        let X移动距离 = -(size.width + 底部障碍.size.width)
        let 移动持续时间 = X移动距离 / k地面移动速度
        let 移动的队列 = SKAction.sequence([
            SKAction.moveByX(X移动距离, y: 0, duration: NSTimeInterval(移动持续时间)),
            SKAction.removeFromParent()
            ])
        
        底部障碍.runAction(移动的队列)
        顶部障碍.runAction(移动的队列)
        
    }
    
    func 无限重生障碍() -> Void {
        let 首次延迟 = SKAction.waitForDuration(k首次生成障碍延时)
        let 重生障碍 = SKAction.runBlock(生成障碍)
        let 每次的重生间隔 = SKAction.waitForDuration(k每次生成障碍延时)
        let 重生的动作队列 = SKAction.sequence([重生障碍, 每次的重生间隔])
        let 无限重生 = SKAction.repeatActionForever(重生的动作队列)
        let 总的队列 = SKAction.sequence([首次延迟, 无限重生])
        runAction(总的队列, withKey: "重生")
    }
    
    func 停止生成障碍() -> Void {
        removeActionForKey("重生")
        世界单位.enumerateChildNodesWithName("顶部障碍", usingBlock: { 匹配单位, _ in
            匹配单位.removeAllActions()
        })
        世界单位.enumerateChildNodesWithName("底部障碍", usingBlock: { 匹配单位, _ in
            匹配单位.removeAllActions()
        })
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        
        switch 当前游戏状态 {
        case .主菜单:
            break
        case .教程:
            break
        case .显示分数:
            break
        case .游戏:
            主角飞一下()
            break
        case .结束:
            break
        case .跌落:
            break
        }
        

        
    }
    
    
//   每一帧都会调用
    override func update(currentTime: CFTimeInterval) {
        if 上一次更新时间 > 0 {
            dt = currentTime - 上一次更新时间
        }else{
            dt = 0
        }
        上一次更新时间 = currentTime
        
//        更新主角()
//        更新前景()
//        撞击障碍物检查()
        switch 当前游戏状态 {
        case .主菜单:
            break
        case .教程:
            break
        case .显示分数:
            break
        case .游戏:
            更新主角()
            更新前景()
            撞击障碍物检查()
            撞击地面检查()
            break
        case .结束:
            break
        case .跌落:
            更新主角()
            撞击地面检查()
            break
        }
    }
    func 更新主角() -> Void {
        let 加速度 = CGPoint(x: 0, y: k重力)
        速度 = 速度 + 加速度 * CGFloat(dt)
        主角.position = 主角.position + 速度 * CGFloat(dt)
//        让主角停在地面上
        if 主角.position.y - 主角.size.height/2 < 游戏区域起始点 {
            主角.position = CGPoint(x: 主角.position.x, y: 主角.size.height/2 + 游戏区域起始点)
        }
    }
    func 更新前景() -> Void {
        世界单位.enumerateChildNodesWithName("前景") {匹配单位, _ in
            if let 前景 = 匹配单位 as? SKSpriteNode{
                let 地面移动速度 = CGPoint(x: self.k地面移动速度, y: 0)
                前景.position += 地面移动速度 * CGFloat(self.dt)
                
                if 前景.position.x < -前景.size.width{
                    前景.position += CGPoint(x: 前景.size.width * CGFloat(self.k前景页面数), y: 0)
                }
            }
        }
    }
    
    func 撞击障碍物检查() -> Void {
        if 撞击了障碍物 {
            撞击了障碍物 = false
            切换到跌落状态()
        }
    }
    
    func 撞击地面检查() -> Void {
        if 撞击了地面 {
            撞击了地面 = false
            速度 = CGPoint.zero
            主角.zRotation = CGFloat(-60).degreesToRadians()
            主角.position = CGPoint(x: 主角.position.x, y: 游戏区域起始点 + 主角.size.width*0.5)
            runAction(sounds.hitAct)
            切换到跌落状态()
        }
    }
    
    
//    MARK: 游戏状态方法
    func 切换到跌落状态() ->  Void{
        当前游戏状态 = .跌落
        runAction(SKAction.sequence([sounds.dingAct,
            SKAction.waitForDuration(0.1), sounds.fallAct]))
        主角.removeAllActions()
        停止生成障碍()
    }
    
    func 显示分数状态() -> Void {
        当前游戏状态 = .显示分数
        主角.removeAllActions()
        停止生成障碍()
    }
    
//    碰撞处理
    func didBeginContact(碰撞双方: SKPhysicsContact) {
        let 被撞对象 = 碰撞双方.bodyA.categoryBitMask == 物理层.游戏角色 ? 碰撞双方.bodyB : 碰撞双方.bodyA
        if 被撞对象.categoryBitMask == 物理层.地面 {
            撞击了地面 = true
        }
        if 被撞对象.categoryBitMask == 物理层.障碍物 {
            撞击了障碍物 = true
        }
        
    }
}
