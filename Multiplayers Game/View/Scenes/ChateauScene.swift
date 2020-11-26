//
//  GameScene.swift
//  castle
//
//  Created by Titouan Blossier on 03/02/2020.
//  Copyright © 2020 Titouan Blossier. All rights reserved.
//
import UIKit
import SpriteKit
import GameplayKit

class ChateauScene: SKScene {
    
    var numberOfPlayer : Int!
    private var game : Game!
    private var ways : Array<Way> {
        get {
            return MapData.shared.ways
        }
        set {
            MapData.shared.ways = newValue
        }
    }
    private var bases : Array<Base> {
        get {
            return MapData.shared.bases
        }
    }
    private var basesSprite : Array<SKSpriteNode>!
    private var waysSprite : Array<SKShapeNode>!
    private var arrowSprite : Array<SKSpriteNode>!
    private var unitSprites : Array<Unit>!
    var timer : Timer!
    var playersTeam : Array<Teams>!
    
    override func didMove(to view: SKView) {
        
        self.physicsWorld.contactDelegate = self as SKPhysicsContactDelegate
        self.backgroundColor = UIColor(red: 1, green: 231/255, blue: 200/255, alpha: 1)
        game = Game()
        waysSprite = []
        basesSprite = []
        unitSprites = []
        loadMap()
        startGame()
    }
    
    
    //MARk: - Load map
    
    private func loadMap() {
        LoadManager.shared.loadMapFor(player: self.numberOfPlayer, size: self.size, team : self.playersTeam)
        setupWays()
        setupBases()
        setupArrows()
    }
    
    private func setupBases() {
        for base in basesSprite {
            base.removeFromParent()
        }
        for base in bases {
            
            let baseShape = SKSpriteNode(imageNamed: "hexagone\(base.team!)")
            baseShape.position = base.position
            baseShape.zPosition = ChateauLayer.base
            baseShape.size = CGSize(width: CGFloat(5 * Float(base.poid + 2)), height: CGFloat(4.5 * CGFloat(base.poid + 2)))
            
            self.addChild(baseShape)
            
            basesSprite.append(baseShape)
        }
    }
    
    private func setupWays() {
        for way in ways {
            let xb = way.beginPoint.x
            let xe = way.endPoint.x
            let yb = way.beginPoint.y
            let ye = way.endPoint.y
            
            let a = (xb - xe) * (xb - xe)
            let b = (yb - ye) * (yb - ye)
            let sum = a + b
            let radius = sqrt(Float(sum))
            
            let firstPointX = Float(xb)
            let firstPointY = Float(yb) + radius
            
            let center = CGPoint(x : (xb + xe) / 2, y : (ye + yb) / 2)
            
            
            let angle = atan2(Float(firstPointY) - Float(ye), firstPointX - Float(xe)) * 2
            
            let distanceBetweenPoint = sqrt((xe-xb) * (xe - xb) + (ye - yb) * (ye - yb))
            
            let shapePath = UIBezierPath(rect: CGRect(
                origin: CGPoint(x: xb, y: yb),
                size: CGSize(width: 35, height: distanceBetweenPoint)))
            
            let wayShape = SKShapeNode(path: shapePath.cgPath, centered: true)
            wayShape.position = center//Définis le centre
            wayShape.fillColor = Function.getColorFor(team: way.wayTeam)
            wayShape.alpha = 0.5
            wayShape.lineWidth = 0
            wayShape.zPosition = ChateauLayer.normalWay
            if way.wayTeam == .neutral {
                wayShape.zPosition = ChateauLayer.neutralWay
            }
            ways[waysSprite.count].angle = CGFloat(angle)
            let rotate = SKAction.rotate(toAngle: CGFloat(angle), duration: 0)
            wayShape.run(rotate)
            wayShape.name = String(waysSprite.count)
            //wayShape.zRotation = CGFloat(angle)
            self.addChild(wayShape)
            
            waysSprite.append(wayShape)
        }
    }
    
    private func setupArrows() {
        arrowSprite = []
        for way in waysSprite {
            let arrow = SKSpriteNode(imageNamed: "arrow")
            arrow.position = way.position
            arrow.zPosition = ChateauLayer.arrow
            arrow.size = CGSize(width: 50, height: 20)
            arrow.run(SKAction.rotate(toAngle: ways[Int(way.name!)!].angle! + CGFloat(Float.pi / 2), duration: 0))
            arrowSprite.append(arrow)
            self.addChild(arrow)
        }
        showArrows()
    }
    
    private func showArrows() {
        for arrow in arrowSprite { //Hiding arrow
            let sprites = self.nodes(at: arrow.position)
            for sprite in sprites {
                if let name = sprite.name {
                    if let number = Int(name){
                        if ways[number].wayTeam == .neutral {
                            arrow.isHidden = true
                        } else {
                            arrow.isHidden = false
                        }
                        break
                    }
                }
            }
        }
    }
    
    //MARK: - Start map
    private func startGame() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: { _ in
            self.game.second()
            self.reloadGraphical()
        })
    }
    
    private func reloadWaysColor() {
        for i in 0...ways.count - 1 {
            waysSprite[i].fillColor = Function.getColorFor(team: ways[i].wayTeam)
        }
    }
    
    private func reloadGraphical() {
        for i in basesSprite {
            i.removeFromParent()
        }
        basesSprite = []
        setupBases()
        showArrows()
        reloadWaysColor()
    }
    
    private func getAnimationDuration(way : Way) -> CGFloat{
        let xb = way.beginPoint.x
        let xe = way.endPoint.x
        let yb = way.beginPoint.y
        let ye = way.endPoint.y
        let animationDuration = sqrt((xe-xb) * (xe - xb) + (ye - yb) * (ye - yb)) / 75
        return animationDuration
    }
    
    //MARK: - End of game

    private func win() {
        NotificationCenter.default.post(Notification(name: Notification.Name(rawValue: "chateauWin")))
    }
    
    private func checkWin() {
        let result = game.checkWin()
        if result.0{
            var win = true
            for i in self.unitSprites { //Checking if a unit is not on it way to a base
                if i.team != result.1 {
                    win = false
                }
            }
            if win {
                self.win()
            }
        }
    }
}

extension ChateauScene {
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        guard let touch = touches.first else {
            return
        }
        
        for i in nodes(at: touch.location(in: self)){
            guard let name = i.name else{
                continue
            }
            let way = ways[Int(name)!]
            let beginId = way.beginId
            let result = game.sendUnit(beginId : beginId, way : way) //First element is if the transfer is accepted or not
            //Second element is the weight of the new unit
            //Third element is the destination point
            
            guard result.0 else { //Transfer not accepted
                return
            }
            showArrows()
            reloadGraphical()
            
            let unit = Unit(imageNamed: "unit")
            unit.poid = result.1
            
            let size = CGFloat(result.1) * 6.5
            unit.size = CGSize(width: size, height: size)
            
            var maxDimensions = self.view!.frame.width
            if self.view!.frame.height > maxDimensions {
                maxDimensions = self.view!.frame.height
            }
            
            let ye = unit.position.y
            let yb = result.2.y
            let distanceBetweenPoint = abs(ye - yb)
            unit.destinationPoint = CGPoint(x: result.2.x, y: result.2.y + 25)
            
            unit.position = game.base(id: beginId).position
            unit.zPosition = ChateauLayer.unit
            unit.color = Function.getColorFor(team: way.wayTeam)
            unit.colorBlendFactor = 1.0
            unit.team = way.wayTeam
            unit.alpha = 0.8
            let borderBody = SKPhysicsBody(circleOfRadius: CGFloat(unit.poid))
            unit.physicsBody = borderBody
            
            unit.physicsBody?.contactTestBitMask = ChateauBitMask.unitCategory //Whith wich category do he send a notification
            unit.physicsBody?.categoryBitMask = ChateauBitMask.unitCategory //which category do he belong to
            unit.physicsBody?.collisionBitMask = 0
            
            
            let animationDuration = getAnimationDuration(way: way)
            
            let path = UIBezierPath()
            path.move(to: unit.position)
            path.addLine(to: unit.destinationPoint)
            let moveAnimation = SKAction.follow(path.cgPath, asOffset: false, orientToPath: false, duration: TimeInterval(animationDuration))
            unitSprites.append(unit)
            self.addChild(unit)
            
            let endAnimation = SKAction.run {
                self.game.unitArrived(beginId: beginId, unit: unit, destinationId: way.destinationId)

                self.unitSprites.remove(at: self.unitSprites.firstIndex(of : unit)!)
                self.checkWin()
                
                unit.removeFromParent()
                self.reloadGraphical()
            }
            unit.run(SKAction.sequence([moveAnimation, endAnimation]))
            return
        }
    }
}

extension ChateauScene : SKPhysicsContactDelegate {
    func didBegin(_ contact: SKPhysicsContact) {
        if let first = contact.bodyA.node as? Unit{
            if let second = contact.bodyB.node as? Unit {
                if second.team != first.team {
                    if first.poid > second.poid {
                        first.poid -= second.poid
                        let size = CGFloat(first.poid) * 6.5
                        first.size = CGSize(width: size, height: size)
                        second.removeFromParent()
                    } else if second.poid > first.poid{
                        second.poid -= first.poid
                        let size = CGFloat(second.poid) * 6.5
                        second.size = CGSize(width: size, height: size)
                        first.removeFromParent()
                    } else {
                        first.removeFromParent()
                        second.removeFromParent()
                    }
                }
            }
        }
    }
}


