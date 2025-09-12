//
//  SepticaGameViewController.swift
//  Septica
//
//  Main view controller hosting the SwiftUI navigation system
//  Entry point for the Septica card game application
//

import UIKit
import SwiftUI

/// Main view controller that hosts the SwiftUI-based Septica application
class SepticaGameViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupMainMenu()
    }
    
    private func setupMainMenu() {
        // Create SwiftUI main menu view with navigation system
        let mainMenuView = MainMenuView()
        
        // Wrap in UIHostingController
        let hostingController = UIHostingController(rootView: mainMenuView)
        
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
        
        // Configure appearance for SwiftUI
        view.backgroundColor = UIColor.systemBackground
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override var preferredScreenEdgesDeferringSystemGestures: UIRectEdge {
        return .all
    }
}