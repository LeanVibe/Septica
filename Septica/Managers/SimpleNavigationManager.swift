//
//  SimpleNavigationManager.swift
//  Septica
//
//  Simple navigation manager for basic navigation functionality
//  Used when full NavigationManager dependencies are not available
//

import SwiftUI
import Foundation
import Combine

/// Simple navigation manager for basic game navigation
@MainActor
class SimpleNavigationManager: ObservableObject {

    @Published var currentScreen: String = "game"
    @Published var isShowingMainMenu = false

    func popToRoot() {
        isShowingMainMenu = true
    }

    func navigateToMainMenu() {
        isShowingMainMenu = true
    }

    func startNewGame() {
        // Simple implementation for starting new game
        currentScreen = "game"
    }
}