//
//  SepticaGameViewController.swift
//  Septica
//
//  SwiftUI host controller for Septica card game
//  Replaces the Metal-based GameViewController with SwiftUI game interface
//

import UIKit
import SwiftUI

/// Main view controller that hosts the SwiftUI-based Septica game interface
class SepticaGameViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupSepticaGame()
    }
    
    private func setupSepticaGame() {
        // Create game state with initial setup
        let gameController = GameController()
        let gameSession = gameController.startSinglePlayerGame(
            playerName: "Player", 
            difficulty: .medium
        )
        
        // Create SwiftUI game board view
        let gameBoardView = GameBoardView(gameState: gameSession.gameState)
        
        // Wrap in UIHostingController
        let hostingController = UIHostingController(rootView: gameBoardView)
        
        // Add as child view controller
        addChild(hostingController)
        view.addSubview(hostingController.view)
        hostingController.didMove(toParent: self)
        
        // Setup constraints
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hostingController.view.topAnchor.constraint(equalTo: view.topAnchor),
            hostingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        // Configure appearance
        view.backgroundColor = UIColor.systemBackground
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override var preferredScreenEdgesDeferringSystemGestures: UIRectEdge {
        return .all
    }
}