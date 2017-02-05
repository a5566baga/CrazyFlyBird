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
    
//    bottomBlock的倍数
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
//        changeLessonStatus()
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
    
    func createBlock() -> Void {
        let bottomBlock = initObstructionView("CactusBottom")
        let startXPos = self.size.width + bottomBlock.size.width/2
        
        let YPosMin = (gamingStartPoint - bottomBlock.size.height/2) + gamingHeight * kBottomMinNum
        let YPosMax = (gamingStartPoint - bottomBlock.size.height/2) + gamingHeight * kBottomMaxNum
        
        bottomBlock.position = CGPointMake(startXPos, CGFloat.random(min: YPosMin, max: YPosMax))
        bottomBlock.name = "bottomBlock"
        worldNode.addChild(bottomBlock)
        
        let TopBlock = initObstructionView("CactusTop")
        TopBlock.zRotation = CGFloat(180).degreesToRadians()
        TopBlock.position = CGPoint(x: startXPos, y: bottomBlock.position.y + bottomBlock.size.height/2 + TopBlock.size.height/2 + mainUser.size.height * kLackNum)
        TopBlock.name = "TopBlock"
        worldNode.addChild(TopBlock)
        
        let moveXDistance = -(size.width + bottomBlock.size.width)
        let moveDuringTime = moveXDistance / kfloorViewMoveNormalSpeed
        let moveQueue = SKAction.sequence([
            SKAction.moveByX(moveXDistance, y: 0, duration: NSTimeInterval(moveDuringTime)),
            SKAction.removeFromParent()
            ])
        
        bottomBlock.runAction(moveQueue)
        TopBlock.runAction(moveQueue)
        
    }
    
    func noViewRelifeBlock() -> Void {
        let firstDuring = SKAction.waitForDuration(kFirstTimeSec)
        let reLifeBlock = SKAction.runBlock(createBlock)
        let eveRelifeTime = SKAction.waitForDuration(kEveryTimeSec)
        let eveRelifeQueue = SKAction.sequence([reLifeBlock, eveRelifeTime])
        let noViewRelife = SKAction.repeatActionForever(eveRelifeQueue)
        let totalQueue = SKAction.sequence([firstDuring, noViewRelife])
        runAction(totalQueue, withKey: "reBorn")
    }
    
    func stopCreateBlock() -> Void {
        removeActionForKey("reBorn")
        worldNode.enumerateChildNodesWithName("TopBlock", usingBlock: { marthUnit, _ in
            marthUnit.removeAllActions()
        })
        worldNode.enumerateChildNodesWithName("bottomBlock", usingBlock: { marthUnit, _ in
            marthUnit.removeAllActions()
        })
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
//        print("\(NowGameStatus)")
        guard let clickTap = touches.first else{
            return
        }
        let clickTapPos = clickTap.locationInNode(self)
        
        switch NowGameStatus {
        case .mainMenu:
            if clickTapPos.y > size.height * 0.4 || clickTapPos.y < size.height * 0.6 {
                changeLessonStatus()
            }
            break
        case .lesson:
            changeGameStatus()
            break
        case .showScore:
            break
        case .gaming:
            mainUserFlying()
            break
        case .gameOver:
            if clickTapPos.x < size.width/2 {
                changeNewGaming()
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
        

        switch NowGameStatus {
        case .mainMenu:
            settingMainMenu()
            break
        case .lesson:
            break
        case .showScore:
            break
        case .gaming:
            updateMainUser()
            updateForeView()
            knockObstructionViewCheck()
            knockFloorViewCheck()
            updateScores()
            break
        case .gameOver:
            break
        case .fallDown:
            updateMainUser()
            knockFloorViewCheck()
            break
        }
    }
    

    func updateMainUser() -> Void {
        let addNormalSpeed = CGPoint(x: 0, y: kGravity)
        normalSpeed = normalSpeed + addNormalSpeed * CGFloat(dt)
        mainUser.position = mainUser.position + normalSpeed * CGFloat(dt)
//        让玩家停留在地板上
        if mainUser.position.y - mainUser.size.height/2 < gamingStartPoint {
            mainUser.position = CGPoint(x: mainUser.position.x, y: mainUser.size.height/2 + gamingStartPoint)
        }
    }
    func updateForeView() -> Void {
        worldNode.enumerateChildNodesWithName("foreView") {marthUnit, _ in
            if let foreView = marthUnit as? SKSpriteNode{
                let floorViewMoveNormalSpeed = CGPoint(x: self.kfloorViewMoveNormalSpeed, y: 0)
                foreView.position += floorViewMoveNormalSpeed * CGFloat(self.dt)
                
                if foreView.position.x < -foreView.size.width{
                    foreView.position += CGPoint(x: foreView.size.width * CGFloat(self.kforeViewPageNum), y: 0)
                }
            }
        }
    }
    
    func knockObstructionViewCheck() -> Void {
        if knockObstructionView {
            knockObstructionView = false
            changeFallDownStatus()
        }
    }
    
    func knockFloorViewCheck() -> Void {
        if knockFloorView {
            knockFloorView = false
            normalSpeed = CGPoint.zero
            mainUser.zRotation = CGFloat(-60).degreesToRadians()
            mainUser.position = CGPoint(x: mainUser.position.x, y: gamingStartPoint + mainUser.size.width*0.5)
            runAction(sounds.hitAct)
            changeShowScoreStatus()
        }
    }
    
    func updateScores() -> Void {
        worldNode.enumerateChildNodesWithName("TopBlock", usingBlock: { marthUnit, _ in
            if let obstructionView = marthUnit as? SKSpriteNode{
                if let passed = obstructionView.userData?["passed"] as? NSNumber{
                    if passed.boolValue{
                        return
                    }
                }
                if self.mainUser.position.x > obstructionView.position.x + obstructionView.size.width/2{
                    self.nowScore += 1
                    self.resultLabel.text = "\(self.nowScore)"
                    self.runAction(self.sounds.coinAct)
                    obstructionView.userData?["passed"] = NSNumber(bool: true)
                }
            }
        })
    }
    
    
//    MARK: 游戏状态方法
    func changeMainMenu() -> Void {
        NowGameStatus = .mainMenu
        settingBgView()
        settingForeView()
        settingMainUser()
        settingHat()
        settingMainMenu()
    }
    
    func changeLessonStatus() -> Void {
        runAction(sounds.popAct)
        NowGameStatus = .lesson
        worldNode.enumerateChildNodesWithName("mainMenu", usingBlock: {
            marthUnit, _ in
            marthUnit.runAction(SKAction.sequence([
                SKAction.fadeInWithDuration(0.05),
                SKAction.removeFromParent()
                ]))
        })
        settingResultLabel()
        settingLesson()
    }
    
    func changeGameStatus() -> Void {
        NowGameStatus = .gaming
        worldNode.enumerateChildNodesWithName("lesson", usingBlock: {
            marthUnit, _ in
            marthUnit.runAction(SKAction.sequence([
                SKAction.fadeInWithDuration(0.05),
                SKAction.removeFromParent()
                ]))
        })
        mainUser.removeActionForKey("startFly")
        noViewRelifeBlock()
        mainUserFlying()
    }
    
    func changeNewGaming() -> Void {
        runAction(sounds.popAct)
        let newGamingSence = GameScene.init(size: size)
        let changeEffects = SKTransition.fadeWithColor(SKColor.blackColor(), duration: 0.05)
        view?.presentScene(newGamingSence, transition: changeEffects)
    }
    
    func changeFallDownStatus() ->  Void{
        NowGameStatus = .fallDown
        runAction(SKAction.sequence([sounds.dingAct,
            SKAction.waitForDuration(0.1), sounds.fallAct]))
        mainUser.removeAllActions()
        stopCreateBlock()
    }
    
    func changeShowScoreStatus() -> Void {
        NowGameStatus = .showScore
        mainUser.removeAllActions()
        stopCreateBlock()
        settingCountsBoard()
    }
    
    func changeNowGameStatus() -> Void {
        NowGameStatus = .gameOver
    }
    
//    MARK:分数处理
    func highScore() -> Int {
        return NSUserDefaults.standardUserDefaults().integerForKey("highScore")
    }
    func settingHighScore(highScore:Int) -> Void {
        NSUserDefaults.standardUserDefaults().setInteger(highScore, forKey: "highScore")
        NSUserDefaults.standardUserDefaults().synchronize()
    }
    func settingCountsBoard() -> Void {
//        print("\(highScore())")
        if nowScore > highScore() {
            settingHighScore(nowScore)
        }
        let countsBoard = SKSpriteNode(imageNamed: "Scorecard")
        countsBoard.position = CGPoint(x: size.width/2, y: size.height/2)
        countsBoard.zPosition = sceneView.UI.rawValue
        worldNode.addChild(countsBoard)
        
        let nowScoreLabel = SKLabelNode(fontNamed: kFontName)
        nowScoreLabel.color = SKColor(red: 101.0/255.0, green: 71.0/255.0, blue: 73.0/255.0, alpha: 1.0)
        nowScoreLabel.position = CGPoint(x: -countsBoard.size.width/4, y: -countsBoard.size.height/3)
        nowScoreLabel.text = "\(nowScore)"
        nowScoreLabel.zPosition = sceneView.UI.rawValue
        countsBoard.addChild(nowScoreLabel)
        
        let topScoreLabel = SKLabelNode(fontNamed: kFontName)
        topScoreLabel.color = SKColor(red: 101.0/255.0, green: 71.0/255.0, blue: 73.0/255.0, alpha: 1.0)
        topScoreLabel.position = CGPoint(x: countsBoard.size.width/4, y: -countsBoard.size.height/3)
        topScoreLabel.text = "\(highScore())"
        topScoreLabel.zPosition = sceneView.UI.rawValue
        countsBoard.addChild(topScoreLabel)
        
        let gaminggameOver = SKSpriteNode(imageNamed: "GameOver")
        gaminggameOver.position = CGPoint(x: size.width/2, y: size.height/2 + countsBoard.size.height/2 + 2*kTopLeft + gaminggameOver.size.height/2)
        gaminggameOver.zPosition = sceneView.UI.rawValue
        worldNode.addChild(gaminggameOver)
        
        let okButton = SKSpriteNode(imageNamed: "Button")
        okButton.position = CGPoint(x: size.width/4, y: size.height/2 - countsBoard.size.height/2 - kTopLeft - okButton.size.width/2)
        okButton.zPosition = sceneView.UI.rawValue
        worldNode.addChild(okButton)
        
        let OK = SKSpriteNode(imageNamed: "OK")
        OK.position = CGPoint.zero
        OK.zPosition = sceneView.UI.rawValue
        okButton.addChild(OK)
        
        let shareButton = SKSpriteNode(imageNamed: "ButtonRight")
        shareButton.position = CGPoint(x: size.width/4*3, y: size.height/2 - countsBoard.size.height/2 - kTopLeft - okButton.size.width/2)
        shareButton.zPosition = sceneView.UI.rawValue
        worldNode.addChild(shareButton)
        
        let share = SKSpriteNode(imageNamed: "Share")
        share.position = CGPoint.zero
        share.zPosition = sceneView.UI.rawValue
        shareButton.addChild(share)
        
        gaminggameOver.setScale(0)
        gaminggameOver.alpha = 0
        let animalArray = SKAction.group([
            SKAction.fadeInWithDuration(kDelayTimeSec),
            SKAction.scaleTo(1.0, duration: kDelayTimeSec)
            ])
        animalArray.timingMode = .EaseInEaseOut
        gaminggameOver.runAction(SKAction.sequence([
            SKAction.waitForDuration(kDelayTimeSec),
            animalArray
            ]))
        
        countsBoard.position = CGPoint(x: size.width/2, y: -countsBoard.size.height/2)
        let upMoveAnim = SKAction.moveTo(CGPoint(x: size.width/2, y: size.height/2), duration: kDelayTimeSec)
        upMoveAnim.timingMode = .EaseInEaseOut
        countsBoard.runAction(SKAction.sequence([
            SKAction.waitForDuration(kDelayTimeSec * 2),
            upMoveAnim
            ]))
        
        okButton.alpha = 0
        shareButton.alpha = 0
        let gradientAnim = SKAction.sequence([
            SKAction.waitForDuration(kDelayTimeSec * 3),
            SKAction.fadeInWithDuration(kDelayTimeSec)
            ])
        okButton.runAction(gradientAnim)
        shareButton.runAction(gradientAnim)
        
        let soundsEffect = SKAction.sequence([
            SKAction.waitForDuration(kDelayTimeSec),
            sounds.popAct,
            SKAction.waitForDuration(kDelayTimeSec),
            sounds.popAct,
            SKAction.waitForDuration(kDelayTimeSec),
            sounds.popAct,
            SKAction.runBlock(changeNowGameStatus)
            ])
        
        runAction(soundsEffect)
    }
    
//    碰撞处理
    func didBeginContact(kickBoth: SKPhysicsContact) {
        let beKicked = kickBoth.bodyA.categoryBitMask == PhysicsView.NPC ? kickBoth.bodyB : kickBoth.bodyA
        if beKicked.categoryBitMask == PhysicsView.floorView {
            knockFloorView = true
        }
        if beKicked.categoryBitMask == PhysicsView.obstructionView {
            knockObstructionView = true
        }
        
    }
    
//    MARK:跳转到个人Git部分
    func netWorking() -> Void {
        let net = NSURL(string: "https://github.com/a5566baga/CrazyFlyBird")
        UIApplication.sharedApplication().openURL(net!)
    }
}
