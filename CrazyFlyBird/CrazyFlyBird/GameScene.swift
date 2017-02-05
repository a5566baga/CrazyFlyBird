//
//  GameScene.swift
//  CrazyFlyBird
//
//  Created by ben on 16/10/28.
//  Copyright (c) 2016年 张增强. All rights reserved.
//

import SpriteKit
import AVFoundation

enum sceneView:CGFloat {
    case bgView
    case obstructionView
    case foreView
    case roleView
    case UI
}

struct PhysicsView {
    static let noView:UInt32 = 0
    static let NPC:UInt32 = 0b1 //1
    static let obstructionView:UInt32 = 0b10 //2
    static let floorView:UInt32 = 0b100 //4
}

enum GameStatus {
    case mainMenu
    case lesson
    case gaming
    case fallDown
    case showScore
    case gameOver
}

class GameScene: SKScene, SKPhysicsContactDelegate {
    
//    添加音效
    lazy var sounds = SoundManager()
    
//    鸟飞的normalSpeed和重力
    let kGravity:CGFloat = -1500.0
    let kUpSpeed:CGFloat = 400.0
    var normalSpeed = CGPoint.zero
    
//    底部障碍的倍数
    let kBottomMinNum:CGFloat = 0.1
    let kBottomMaxNum:CGFloat = 0.6
    let kLackNum:CGFloat = 3.5
    let kFirstTimeSec:NSTimeInterval = 1.75
    let kEveryTimeSec:NSTimeInterval = 1.5
    var knockFloorView = false
    var knockObstructionView = false
    var NowGameStatus:GameStatus = .gaming
    
//    gaming分数
    let kTopLeft:CGFloat = 20.0
    let kFontName = "AmericanTypewriter-Bold"
    var resultLabel:SKLabelNode!
    var nowScore:Int = 0
    let kDelayTimeSec = 0.3
    let kNPCAllNum = 4
    

//    foreView页面的移动
    let kforeViewPageNum = 2
    let kfloorViewMoveNormalSpeed:CGFloat = -150.0
    
//    基本单位
    let worldNode = SKNode()
    var gamingStartPoint:CGFloat = 0
    var gamingHeight:CGFloat = 0
    let mainUser = SKSpriteNode(imageNamed: "Bird0")
    let hat = SKSpriteNode(imageNamed: "Sombrero")
    
    var lastUpdateTime:NSTimeInterval = 0
    var dt:NSTimeInterval = 0
    
//    MARK:初始视图
    override func didMoveToView(view: SKView) {
       
//        关掉重力
        physicsWorld.gravity = CGVector(dx: 0, dy: 0)
        physicsWorld.contactDelegate = self
        
        addChild(worldNode)
        addChild(sounds)
//        切换到lesson状态()
        changeMainMenu()
    }
//    MARK: 设置内容相关
    func settingMainMenu() -> Void {
//        logo
        let logo = SKSpriteNode(imageNamed: "Logo")
        logo.position = CGPoint(x: size.width/2, y: size.height * 0.8)
        logo.zPosition = sceneView.UI.rawValue
        logo.name = "mainMenu"
        worldNode.addChild(logo)
        
//        开始游戏按钮
        let startGameButton = SKSpriteNode(imageNamed: "Button")
        startGameButton.position = CGPoint(x: size.width * 0.5, y: size.height * 0.5)
        startGameButton.zPosition = sceneView.UI.rawValue
        startGameButton.name = "mainMenu"
        worldNode.addChild(startGameButton)
        
        let gaming = SKSpriteNode(imageNamed: "Play")
        gaming.position = CGPoint.zero
        gaming.zPosition = sceneView.UI.rawValue
        startGameButton.addChild(gaming)
        
    }
    
    func settingLesson() -> Void{
        let lesson = SKSpriteNode(imageNamed: "Tutorial")
        lesson.position = CGPoint(x: size.width/2, y: gamingHeight*0.4 + gamingStartPoint)
        lesson.zPosition = sceneView.UI.rawValue
        lesson.name = "lesson"
        worldNode.addChild(lesson)
        
        let prepare = SKSpriteNode(imageNamed: "Ready")
        prepare.position = CGPoint(x: size.width/2, y: gamingHeight*0.7 + gamingStartPoint)
        prepare.zPosition = sceneView.UI.rawValue
        prepare.name = "lesson"
        worldNode.addChild(prepare)
        
//        MARK: 让主角能startFly状态
        let upMove = SKAction.moveByX(0, y: 50, duration: 0.5)
        upMove.timingMode = .EaseInEaseOut
        let downMove = upMove.reversedAction()
        
        mainUser.runAction(SKAction.repeatActionForever(SKAction.sequence([
            upMove,
            downMove
            ])), withKey: "startFly")
        var userPicGroup: Array<SKTexture> = []
        
        for i in 0..<kNPCAllNum {
            userPicGroup.append(SKTexture(imageNamed: "Bird\(i)"))
        }
        
        for i in (kNPCAllNum-1).stride(through: 0, by: -1) {
            userPicGroup.append(SKTexture(imageNamed: "Bird\(i)"))
        }
        
        let flyMovie = SKAction.animateWithTextures(userPicGroup, timePerFrame: 0.07)
        mainUser.runAction(SKAction.repeatActionForever(flyMovie))
        
    }
    
    func settingMusic() -> Void {
        sounds.playFlap()
    }
    
    func settingBgView() -> Void {
        let bgView = SKSpriteNode(imageNamed: "Background")
        bgView.anchorPoint = CGPoint(x: 0.5, y: 1)
        bgView.position = CGPoint(x: size.width/2, y: size.height)
        bgView.zPosition = sceneView.bgView.rawValue
        gamingStartPoint = size.height - bgView.size.height
        gamingHeight = bgView.size.height
        worldNode.addChild(bgView)
        
        let leftDown = CGPoint(x: 0, y: gamingStartPoint)
        let rightDown = CGPoint(x: size.width, y: gamingStartPoint)
        self.physicsBody = SKPhysicsBody(edgeFromPoint: leftDown, toPoint: rightDown)
        self.physicsBody?.categoryBitMask = PhysicsView.floorView
        self.physicsBody?.collisionBitMask = 0
        self.physicsBody?.contactTestBitMask = PhysicsView.NPC
        
    }
    
    func settingMainUser() -> Void {
        mainUser.position = CGPoint(x: size.width*0.2, y: size.height*0.4+gamingStartPoint)
        mainUser.zPosition = sceneView.foreView.rawValue
        
        let offsetX = mainUser.size.width * mainUser.anchorPoint.x
        let offsetY = mainUser.size.height * mainUser.anchorPoint.y
        
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
        
        mainUser.physicsBody = SKPhysicsBody(polygonFromPath: path)
        
        mainUser.physicsBody?.categoryBitMask = PhysicsView.NPC
        mainUser.physicsBody?.collisionBitMask = 0
        mainUser.physicsBody?.contactTestBitMask = PhysicsView.floorView | PhysicsView.obstructionView
        
        worldNode.addChild(mainUser)
    }
    
    func settingHat() -> Void {
        hat.position = CGPoint(x: 25 - hat.size.width/2, y: 29 - hat.size.height/2)
        mainUser.addChild(hat)
    }
    
    func settingResultLabel() -> Void {
        resultLabel = SKLabelNode(fontNamed: kFontName)
        resultLabel.color = SKColor(red: 101.0/255.0, green: 71.0/255.0, blue: 73.0/255.0, alpha: 1.0)
        resultLabel.position = CGPoint(x: size.width/2, y: size.height - kTopLeft)
        resultLabel.verticalAlignmentMode = .Top
        resultLabel.text = "0"
        resultLabel.zPosition = sceneView.UI.rawValue
        worldNode.addChild(resultLabel)
    }
    
    func settingForeView() -> Void {
        for i in 0..<kforeViewPageNum {
            let foreView = SKSpriteNode(imageNamed: "Ground")
            foreView.anchorPoint = CGPoint(x: 0, y: 1.0)
            foreView.position = CGPoint(x: CGFloat(i) * foreView.size.width, y: gamingStartPoint)
            foreView.zPosition = sceneView.foreView.rawValue
            foreView.name = "foreView"
            worldNode.addChild(foreView)
        }
    }
    
//    MARK:游戏开玩
    func mainUserFlying() -> Void {
        normalSpeed = CGPoint(x: 0, y: kUpSpeed)
        settingMusic()
//        移动帽子
        let upMove = SKAction.moveByX(0, y: 10, duration: 0.15)
        upMove.timingMode = .EaseInEaseOut
        
        let downMove = upMove.reversedAction()
        hat.runAction(SKAction.sequence([upMove, downMove]))
        
        
    }
    
    func initObstructionView(picName:String) -> SKSpriteNode {
        let obstructionView = SKSpriteNode(imageNamed: picName);
        obstructionView.zPosition = sceneView.obstructionView.rawValue
        obstructionView.userData = NSMutableDictionary()
        
        let offsetX = obstructionView.size.width * obstructionView.anchorPoint.x
        let offsetY = obstructionView.size.height * obstructionView.anchorPoint.y
        
        let path = CGPathCreateMutable()
        
        CGPathMoveToPoint(path, nil, 6 - offsetX, 1 - offsetY)
        CGPathAddLineToPoint(path, nil, 7 - offsetX, 311 - offsetY)
        CGPathAddLineToPoint(path, nil, 48 - offsetX, 311 - offsetY)
        CGPathAddLineToPoint(path, nil, 46 - offsetX, 1 - offsetY)
        
        CGPathCloseSubpath(path)
        
        obstructionView.physicsBody = SKPhysicsBody(polygonFromPath: path)
        obstructionView.physicsBody?.categoryBitMask = PhysicsView.obstructionView
        obstructionView.physicsBody?.collisionBitMask = 0
        obstructionView.physicsBody?.contactTestBitMask = PhysicsView.NPC
        
        return obstructionView
    }
    
    func 生成障碍() -> Void {
        let 底部障碍 = initObstructionView("CactusBottom")
        let 起始X坐标 = self.size.width + 底部障碍.size.width/2
        
        let Y坐标最小值 = (gamingStartPoint - 底部障碍.size.height/2) + gamingHeight * kBottomMinNum
        let Y坐标最大值 = (gamingStartPoint - 底部障碍.size.height/2) + gamingHeight * kBottomMaxNum
        
        底部障碍.position = CGPointMake(起始X坐标, CGFloat.random(min: Y坐标最小值, max: Y坐标最大值))
        底部障碍.name = "底部障碍"
        worldNode.addChild(底部障碍)
        
        let 顶部障碍 = initObstructionView("CactusTop")
        顶部障碍.zRotation = CGFloat(180).degreesToRadians()
        顶部障碍.position = CGPoint(x: 起始X坐标, y: 底部障碍.position.y + 底部障碍.size.height/2 + 顶部障碍.size.height/2 + mainUser.size.height * kLackNum)
        顶部障碍.name = "顶部障碍"
        worldNode.addChild(顶部障碍)
        
        let X移动距离 = -(size.width + 底部障碍.size.width)
        let 移动持续时间 = X移动距离 / kfloorViewMoveNormalSpeed
        let 移动的队列 = SKAction.sequence([
            SKAction.moveByX(X移动距离, y: 0, duration: NSTimeInterval(移动持续时间)),
            SKAction.removeFromParent()
            ])
        
        底部障碍.runAction(移动的队列)
        顶部障碍.runAction(移动的队列)
        
    }
    
    func noView限重生障碍() -> Void {
        let 首次延迟 = SKAction.waitForDuration(kFirstTimeSec)
        let 重生障碍 = SKAction.runBlock(生成障碍)
        let 每次的重生间隔 = SKAction.waitForDuration(kEveryTimeSec)
        let 重生的动作队列 = SKAction.sequence([重生障碍, 每次的重生间隔])
        let noView限重生 = SKAction.repeatActionForever(重生的动作队列)
        let 总的队列 = SKAction.sequence([首次延迟, noView限重生])
        runAction(总的队列, withKey: "重生")
    }
    
    func 停止生成障碍() -> Void {
        removeActionForKey("重生")
        worldNode.enumerateChildNodesWithName("顶部障碍", usingBlock: { 匹配单位, _ in
            匹配单位.removeAllActions()
        })
        worldNode.enumerateChildNodesWithName("底部障碍", usingBlock: { 匹配单位, _ in
            匹配单位.removeAllActions()
        })
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
//        print("\(NowGameStatus)")
        guard let 点击 = touches.first else{
            return
        }
        let 点击位置 = 点击.locationInNode(self)
        
        switch NowGameStatus {
        case .mainMenu:
            if 点击位置.y > size.height * 0.4 || 点击位置.y < size.height * 0.6 {
                切换到lesson状态()
            }
            break
        case .lesson:
            切换到GameStatus()
            break
        case .showScore:
            break
        case .gaming:
            mainUserFlying()
            break
        case .gameOver:
            if 点击位置.x < size.width/2 {
                切换到新gaming()
            }
            break
        case .fallDown:
            break
        }
    }
    
    
//   每一帧都会调用
    override func update(currentTime: CFTimeInterval) {
        if lastUpdateTime > 0 {
            dt = currentTime - lastUpdateTime
        }else{
            dt = 0
        }
        lastUpdateTime = currentTime
        
//        更新mainUser()
//        更新foreView()
//        撞击obstructionView检查()
//        print("\(NowGameStatus)")
        switch NowGameStatus {
        case .mainMenu:
            settingMainMenu()
            break
        case .lesson:
            break
        case .showScore:
            break
        case .gaming:
            更新mainUser()
            更新foreView()
            撞击obstructionView检查()
            撞击floorView检查()
            更新得分()
            break
        case .gameOver:
            break
        case .fallDown:
            更新mainUser()
            撞击floorView检查()
            break
        }
    }
    

    func 更新mainUser() -> Void {
        let 加normalSpeed = CGPoint(x: 0, y: kGravity)
        normalSpeed = normalSpeed + 加normalSpeed * CGFloat(dt)
        mainUser.position = mainUser.position + normalSpeed * CGFloat(dt)
//        让mainUser停在floorView上
        if mainUser.position.y - mainUser.size.height/2 < gamingStartPoint {
            mainUser.position = CGPoint(x: mainUser.position.x, y: mainUser.size.height/2 + gamingStartPoint)
        }
    }
    func 更新foreView() -> Void {
        worldNode.enumerateChildNodesWithName("foreView") {匹配单位, _ in
            if let foreView = 匹配单位 as? SKSpriteNode{
                let floorView移动normalSpeed = CGPoint(x: self.kfloorViewMoveNormalSpeed, y: 0)
                foreView.position += floorView移动normalSpeed * CGFloat(self.dt)
                
                if foreView.position.x < -foreView.size.width{
                    foreView.position += CGPoint(x: foreView.size.width * CGFloat(self.kforeViewPageNum), y: 0)
                }
            }
        }
    }
    
    func 撞击obstructionView检查() -> Void {
        if knockObstructionView {
            knockObstructionView = false
            切换到fallDown状态()
        }
    }
    
    func 撞击floorView检查() -> Void {
        if knockFloorView {
            knockFloorView = false
            normalSpeed = CGPoint.zero
            mainUser.zRotation = CGFloat(-60).degreesToRadians()
            mainUser.position = CGPoint(x: mainUser.position.x, y: gamingStartPoint + mainUser.size.width*0.5)
            runAction(sounds.hitAct)
            切换到showScore状态()
        }
    }
    
    func 更新得分() -> Void {
        worldNode.enumerateChildNodesWithName("顶部障碍", usingBlock: { 匹配单位, _ in
            if let obstructionView = 匹配单位 as? SKSpriteNode{
                if let 已通过 = obstructionView.userData?["已通过"] as? NSNumber{
                    if 已通过.boolValue{
                        return
                    }
                }
                if self.mainUser.position.x > obstructionView.position.x + obstructionView.size.width/2{
                    self.nowScore += 1
                    self.resultLabel.text = "\(self.nowScore)"
                    self.runAction(self.sounds.coinAct)
                    obstructionView.userData?["已通过"] = NSNumber(bool: true)
                }
            }
        })
    }
    
    
//    MARK: GameStatus方法
    func changeMainMenu() -> Void {
        NowGameStatus = .mainMenu
        settingBgView()
        settingForeView()
        settingMainUser()
        settingHat()
        settingMainMenu()
    }
    
    func 切换到lesson状态() -> Void {
        runAction(sounds.popAct)
        NowGameStatus = .lesson
        worldNode.enumerateChildNodesWithName("mainMenu", usingBlock: {
            匹配单位, _ in
            匹配单位.runAction(SKAction.sequence([
                SKAction.fadeInWithDuration(0.05),
                SKAction.removeFromParent()
                ]))
        })
        settingResultLabel()
        settingLesson()
    }
    
    func 切换到GameStatus() -> Void {
        NowGameStatus = .gaming
        worldNode.enumerateChildNodesWithName("lesson", usingBlock: {
            匹配单位, _ in
            匹配单位.runAction(SKAction.sequence([
                SKAction.fadeInWithDuration(0.05),
                SKAction.removeFromParent()
                ]))
        })
        mainUser.removeActionForKey("startFly")
        noView限重生障碍()
        mainUserFlying()
    }
    
    func 切换到新gaming() -> Void {
        runAction(sounds.popAct)
        let 新的gaming场景 = GameScene.init(size: size)
        let 切换特效 = SKTransition.fadeWithColor(SKColor.blackColor(), duration: 0.05)
        view?.presentScene(新的gaming场景, transition: 切换特效)
    }
    
    func 切换到fallDown状态() ->  Void{
        NowGameStatus = .fallDown
        runAction(SKAction.sequence([sounds.dingAct,
            SKAction.waitForDuration(0.1), sounds.fallAct]))
        mainUser.removeAllActions()
        停止生成障碍()
    }
    
    func 切换到showScore状态() -> Void {
        NowGameStatus = .showScore
        mainUser.removeAllActions()
        停止生成障碍()
        设置计分板()
    }
    
    func 切换GameStatus() -> Void {
        NowGameStatus = .gameOver
    }
    
//    MARK:分数处理
    func 最高分() -> Int {
        return NSUserDefaults.standardUserDefaults().integerForKey("最高分")
    }
    func 设置最高分(最高分:Int) -> Void {
        NSUserDefaults.standardUserDefaults().setInteger(最高分, forKey: "最高分")
        NSUserDefaults.standardUserDefaults().synchronize()
    }
    func 设置计分板() -> Void {
//        print("\(最高分())")
        if nowScore > 最高分() {
            设置最高分(nowScore)
        }
        let 计分板 = SKSpriteNode(imageNamed: "Scorecard")
        计分板.position = CGPoint(x: size.width/2, y: size.height/2)
        计分板.zPosition = sceneView.UI.rawValue
        worldNode.addChild(计分板)
        
        let nowScore标签 = SKLabelNode(fontNamed: kFontName)
        nowScore标签.color = SKColor(red: 101.0/255.0, green: 71.0/255.0, blue: 73.0/255.0, alpha: 1.0)
        nowScore标签.position = CGPoint(x: -计分板.size.width/4, y: -计分板.size.height/3)
        nowScore标签.text = "\(nowScore)"
        nowScore标签.zPosition = sceneView.UI.rawValue
        计分板.addChild(nowScore标签)
        
        let 对高分标签 = SKLabelNode(fontNamed: kFontName)
        对高分标签.color = SKColor(red: 101.0/255.0, green: 71.0/255.0, blue: 73.0/255.0, alpha: 1.0)
        对高分标签.position = CGPoint(x: 计分板.size.width/4, y: -计分板.size.height/3)
        对高分标签.text = "\(最高分())"
        对高分标签.zPosition = sceneView.UI.rawValue
        计分板.addChild(对高分标签)
        
        let gaminggameOver = SKSpriteNode(imageNamed: "GameOver")
        gaminggameOver.position = CGPoint(x: size.width/2, y: size.height/2 + 计分板.size.height/2 + 2*kTopLeft + gaminggameOver.size.height/2)
        gaminggameOver.zPosition = sceneView.UI.rawValue
        worldNode.addChild(gaminggameOver)
        
        let ok按钮 = SKSpriteNode(imageNamed: "Button")
        ok按钮.position = CGPoint(x: size.width/4, y: size.height/2 - 计分板.size.height/2 - kTopLeft - ok按钮.size.width/2)
        ok按钮.zPosition = sceneView.UI.rawValue
        worldNode.addChild(ok按钮)
        
        let OK = SKSpriteNode(imageNamed: "OK")
        OK.position = CGPoint.zero
        OK.zPosition = sceneView.UI.rawValue
        ok按钮.addChild(OK)
        
        let 分享按钮 = SKSpriteNode(imageNamed: "ButtonRight")
        分享按钮.position = CGPoint(x: size.width/4*3, y: size.height/2 - 计分板.size.height/2 - kTopLeft - ok按钮.size.width/2)
        分享按钮.zPosition = sceneView.UI.rawValue
        worldNode.addChild(分享按钮)
        
        let 分享 = SKSpriteNode(imageNamed: "Share")
        分享.position = CGPoint.zero
        分享.zPosition = sceneView.UI.rawValue
        分享按钮.addChild(分享)
        
        gaminggameOver.setScale(0)
        gaminggameOver.alpha = 0
        let 动画组 = SKAction.group([
            SKAction.fadeInWithDuration(kDelayTimeSec),
            SKAction.scaleTo(1.0, duration: kDelayTimeSec)
            ])
        动画组.timingMode = .EaseInEaseOut
        gaminggameOver.runAction(SKAction.sequence([
            SKAction.waitForDuration(kDelayTimeSec),
            动画组
            ]))
        
        计分板.position = CGPoint(x: size.width/2, y: -计分板.size.height/2)
        let upMove画 = SKAction.moveTo(CGPoint(x: size.width/2, y: size.height/2), duration: kDelayTimeSec)
        upMove画.timingMode = .EaseInEaseOut
        计分板.runAction(SKAction.sequence([
            SKAction.waitForDuration(kDelayTimeSec * 2),
            upMove画
            ]))
        
        ok按钮.alpha = 0
        分享按钮.alpha = 0
        let 渐变动画 = SKAction.sequence([
            SKAction.waitForDuration(kDelayTimeSec * 3),
            SKAction.fadeInWithDuration(kDelayTimeSec)
            ])
        ok按钮.runAction(渐变动画)
        分享按钮.runAction(渐变动画)
        
        let 声音特效 = SKAction.sequence([
            SKAction.waitForDuration(kDelayTimeSec),
            sounds.popAct,
            SKAction.waitForDuration(kDelayTimeSec),
            sounds.popAct,
            SKAction.waitForDuration(kDelayTimeSec),
            sounds.popAct,
            SKAction.runBlock(切换GameStatus)
            ])
        
        runAction(声音特效)
    }
    
//    碰撞处理
    func didBeginContact(碰撞双方: SKPhysicsContact) {
        let 被撞对象 = 碰撞双方.bodyA.categoryBitMask == PhysicsView.NPC ? 碰撞双方.bodyB : 碰撞双方.bodyA
        if 被撞对象.categoryBitMask == PhysicsView.floorView {
            knockFloorView = true
        }
        if 被撞对象.categoryBitMask == PhysicsView.obstructionView {
            knockObstructionView = true
        }
        
    }
    
//    MARK:跳转到个人Git部分
    func 网页() -> Void {
        let net = NSURL(string: "https://github.com/a5566baga/CrazyFlyBird")
        UIApplication.sharedApplication().openURL(net!)
    }
}
