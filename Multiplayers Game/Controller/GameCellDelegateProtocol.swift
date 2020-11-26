//
//  Game.swift
//  Multiplayers Game
//
//  Created by Titouan Blossier on 13/05/2020.
//  Copyright © 2020 Titouan Blossier. All rights reserved.
//

import Foundation

protocol UICollectionViewGameCellDelegate {
    func gameButtonPressed(for gameName : String) -> ()
    func infoButtonPressed(for segue : String) -> ()
}