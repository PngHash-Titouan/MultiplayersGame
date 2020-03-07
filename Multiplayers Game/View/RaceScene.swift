//
//  RaceScene.swift
//  Multiplayers Game
//
//  Created by Titouan Blossier on 01/03/2020.
//  Copyright © 2020 Titouan Blossier. All rights reserved.
//

import Foundation
import SpriteKit

class RaceScene : SKScene {
    
    var numberOfPlayer : Int!
    var buttonsSprite : Array<SKSpriteNode>!
    var carsSprite : Array<RaceCar>!
    var intervalle : Double!
    var endLine : SKShapeNode!
    let teams : Array<Teams> = [.orange, .pink, .yellow, .blue, .purple, .orange]
    
    override func didMove(to view: SKView) {
        self.physicsWorld.contactDelegate = self as SKPhysicsContactDelegate
        self.physicsWorld.gravity = CGVector(dx: 0, dy: 0)
        
        intervalle = 0.800 / Double(numberOfPlayer + 1)
        
        buttonsSprite = []
        carsSprite = []
        displayButtons()
        drawRoads()
        loadCars()
        drawEnd()
    }
    
    private func drawEnd() {
        let line = SKShapeNode()
        let pathToDraw = CGMutablePath()
        let y = 0.950 * self.size.height
        pathToDraw.move(to: CGPoint(x: CGFloat(0.100 + (Double(1) * intervalle)) * self.size.width - 30, y: y))
        pathToDraw.addLine(to: CGPoint(x: CGFloat(0.100 + (Double(numberOfPlayer) * intervalle)) * self.size.width + 30, y: y))
        line.lineWidth = 10
        line.path = pathToDraw
        line.strokeColor = SKColor.white
        
        line.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: 0.800 * self.frame.width, height: 10), center: CGPoint(x: 0.500 * self.size.width, y: y))
        line.physicsBody?.categoryBitMask = RaceBitMask.endBitMask
        line.physicsBody?.contactTestBitMask = RaceBitMask.carBitMask
        line.physicsBody?.collisionBitMask = 0
        
        endLine = line
        self.addChild(line)
    }
    
    private func displayButtons() {
        let buttonPosition = [[0.900, 0.100], [0.100, 0.100], [0.100, 0.850], [0.900, 0.850], [0.100, 0.500,], [0.100, 0.500]]
        for i in 0...numberOfPlayer - 1 {
            let button = RaceButton(imageNamed: "\(teams[i])Arrow")
            button.team = teams[i]
            button.position = CGPoint(x: CGFloat(buttonPosition[i][0]) * self.size.width, y: CGFloat(buttonPosition[i][1]) * self.size.height)
            button.size = CGSize(width: 60, height: 60)
            button.name = String(i)
            buttonsSprite.append(button)
            self.addChild(button)
        }
    }
    
    private func drawRoads() {
        for i in 0...numberOfPlayer - 1 {
            let x = CGFloat(0.100 + (Double(i + 1) * intervalle)) * self.frame.size.width
            
            let yourline = SKShapeNode()
            let pathToDraw = CGMutablePath()
            pathToDraw.move(to: CGPoint(x: x, y: 0.100 * self.frame.size.height))
            pathToDraw.addLine(to: CGPoint(x: x, y: 0.950 * self.frame.size.height))
            yourline.path = pathToDraw
            yourline.strokeColor = SKColor.red
            addChild(yourline)
        }
    }
    
    private func loadCars() {
        for i in 0...numberOfPlayer - 1 {
            let car = RaceCar(imageNamed: "\(teams[i])Car")
            car.team = teams[i]
            let x = CGFloat(0.100 + (Double(i + 1) * intervalle)) * self.frame.size.width
            car.position = CGPoint(x: x, y: 0.100 * self.frame.size.height)
            car.size = CGSize(width: 50, height: 50)
            
            car.physicsBody = SKPhysicsBody(circleOfRadius: 25)
            car.physicsBody?.categoryBitMask = RaceBitMask.carBitMask
            car.physicsBody?.contactTestBitMask = RaceBitMask.endBitMask
            car.physicsBody?.collisionBitMask = 0
            
            self.addChild(car)
            carsSprite.append(car)
        }
    }
    
    private func stopGame() {
        for i in buttonsSprite {
            i.isHidden = true
            i.isUserInteractionEnabled = false
        }
        for i in carsSprite {
            i.removeAllActions()
        }
    }
    
    private func win() {
        NotificationCenter.default.post(Notification(name: Notification.Name("raceWin")))
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            let nodes = self.nodes(at: touch.location(in: self))
            if nodes.count > 0 {
                if let button = nodes[0] as? RaceButton {
                    let sprite = carsSprite![Int(button.name!)!]
                    if sprite.actualDestinationPoint == nil {
                        sprite.actualDestinationPoint = sprite.position
                    }
                    let destination = CGPoint(x: sprite.actualDestinationPoint.x,
                                              y: (sprite.actualDestinationPoint.y / self.frame.height + 0.05) * self.frame.height)
                    sprite.actualDestinationPoint = destination
                    sprite.removeAllActions()
                    sprite.run(SKAction.move(to: destination, duration: 0.5))
                }
            }
        }
    }
}

extension RaceScene : SKPhysicsContactDelegate{
    func didBegin(_ contact: SKPhysicsContact) {
        var node = contact.bodyA.node as? RaceCar
        if node == nil {
            node = contact.bodyB.node as? RaceCar
        }
        stopGame()
        let hide = SKAction.hide()
        let show = SKAction.unhide()
        let wait = SKAction.wait(forDuration: 0.4)
        let win = SKAction.run {
            self.win()
        }
        let sequence = SKAction.sequence([hide, wait, show, wait])
        let fullSequence = SKAction.sequence([win, sequence, sequence, sequence, sequence, sequence, sequence])
        node?.run(fullSequence)
    }
}
