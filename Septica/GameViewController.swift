//
//  GameViewController.swift
//  Septica
//
//  Legacy Metal-based view controller (disabled)
//  Replaced by SepticaGameViewController with SwiftUI interface
//

import UIKit

// Legacy iOS view controller (no longer used)
class GameViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // This controller is no longer used
        // The app now uses SepticaGameViewController with SwiftUI
        print("Legacy GameViewController loaded - this should not happen")
        view.backgroundColor = UIColor.systemBackground
        
        // Add a simple label to indicate this is not the active controller
        let label = UILabel()
        label.text = "Legacy Controller\n(Should use SepticaGameViewController)"
        label.numberOfLines = 0
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
}
