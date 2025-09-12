//
//  NavigationManager.swift
//  Septica
//
//  Navigation coordinator for managing app-wide navigation flow
//  Implements coordinator pattern for clean separation of navigation logic
//

import SwiftUI
import Foundation
import Combine

/// Main navigation coordinator managing app flow and screen transitions
@MainActor
final class NavigationManager: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var currentScreen: AppScreen = .mainMenu
    @Published var navigationPath = NavigationPath()
    @Published var presentedSheet: PresentedSheet?
    @Published var gameSession: GameSession?
    
    // MARK: - Public Properties
    
    let gameController: GameController
    
    // MARK: - Private Properties
    
    private let userSettings: UserSettings
    
    // MARK: - Initialization
    
    init() {
        self.gameController = GameController()
        self.userSettings = UserSettings.shared
        
        // Check for saved game on launch
        if gameController.hasSavedGame() {
            // Could present option to resume saved game
        }
    }
    
    // MARK: - Navigation Methods
    
    /// Navigate to a specific screen
    func navigateTo(_ screen: AppScreen) {
        withAnimation(.easeInOut(duration: 0.3)) {
            currentScreen = screen
        }
    }
    
    /// Push a screen onto the navigation stack
    func push(_ screen: AppScreen) {
        withAnimation(.easeInOut(duration: 0.3)) {
            navigationPath.append(screen)
        }
    }
    
    /// Pop back to previous screen
    func pop() {
        withAnimation(.easeInOut(duration: 0.3)) {
            navigationPath.removeLast()
        }
    }
    
    /// Pop to root (main menu)
    func popToRoot() {
        withAnimation(.easeInOut(duration: 0.3)) {
            navigationPath = NavigationPath()
            currentScreen = .mainMenu
        }
    }
    
    /// Present a sheet
    func presentSheet(_ sheet: PresentedSheet) {
        presentedSheet = sheet
    }
    
    /// Dismiss current sheet
    func dismissSheet() {
        presentedSheet = nil
    }
    
    // MARK: - Game Flow Methods
    
    /// Start a new single-player game with specified difficulty
    func startNewGame(playerName: String = "Player", difficulty: AIDifficulty) {
        let session = gameController.startSinglePlayerGame(
            playerName: playerName,
            difficulty: difficulty
        )
        gameSession = session
        navigateTo(.gamePlay(session))
    }
    
    /// Resume a saved game if available
    func resumeSavedGame() {
        do {
            let session = try gameController.loadSavedGame()
            gameSession = session
            navigateTo(.gamePlay(session))
        } catch {
            // Handle error - could show alert
            print("Failed to resume saved game: \(error)")
        }
    }
    
    /// Handle game completion
    func handleGameCompleted(with result: GameResult) {
        // Update current screen to show results
        if let session = gameSession {
            navigateTo(.gameResults(result, session))
        }
    }
    
    /// Return to main menu from any screen
    func returnToMainMenu() {
        // End current game if active
        if gameController.isGameActive {
            gameController.endCurrentGame()
        }
        
        gameSession = nil
        popToRoot()
    }
    
    /// Save current game and return to menu
    func saveAndReturnToMenu() {
        do {
            try gameController.saveCurrentGame()
            returnToMainMenu()
        } catch {
            // Handle save error
            print("Failed to save game: \(error)")
            returnToMainMenu() // Still return to menu
        }
    }
    
    // MARK: - Settings Management
    
    /// Show settings screen
    func showSettings() {
        presentSheet(.settings)
    }
    
    /// Show game rules
    func showRules() {
        push(.rules)
    }
    
    /// Show statistics
    func showStatistics() {
        push(.statistics)
    }
    
    /// Show game setup for new game
    func showGameSetup() {
        push(.gameSetup)
    }
}

// MARK: - Navigation Types

/// Represents all possible screens in the app
enum AppScreen: Hashable {
    case mainMenu
    case gameSetup
    case gamePlay(GameSession)
    case gameResults(GameResult, GameSession)
    case settings
    case rules
    case statistics
    
    var title: String {
        switch self {
        case .mainMenu:
            return "Septica"
        case .gameSetup:
            return "New Game"
        case .gamePlay:
            return "Playing"
        case .gameResults:
            return "Game Over"
        case .settings:
            return "Settings"
        case .rules:
            return "How to Play"
        case .statistics:
            return "Statistics"
        }
    }
    
    var showsBackButton: Bool {
        switch self {
        case .mainMenu, .gamePlay:
            return false
        default:
            return true
        }
    }
    
    // Implement Hashable for NavigationPath
    func hash(into hasher: inout Hasher) {
        switch self {
        case .mainMenu:
            hasher.combine("mainMenu")
        case .gameSetup:
            hasher.combine("gameSetup")
        case .gamePlay(let session):
            hasher.combine("gamePlay")
            hasher.combine(session.id)
        case .gameResults(let result, let session):
            hasher.combine("gameResults")
            hasher.combine(result.winnerId)
            hasher.combine(session.id)
        case .settings:
            hasher.combine("settings")
        case .rules:
            hasher.combine("rules")
        case .statistics:
            hasher.combine("statistics")
        }
    }
    
    static func == (lhs: AppScreen, rhs: AppScreen) -> Bool {
        switch (lhs, rhs) {
        case (.mainMenu, .mainMenu),
             (.gameSetup, .gameSetup),
             (.settings, .settings),
             (.rules, .rules),
             (.statistics, .statistics):
            return true
        case (.gamePlay(let lhsSession), .gamePlay(let rhsSession)):
            return lhsSession.id == rhsSession.id
        case (.gameResults(let lhsResult, let lhsSession), .gameResults(let rhsResult, let rhsSession)):
            return lhsResult.winnerId == rhsResult.winnerId && lhsSession.id == rhsSession.id
        default:
            return false
        }
    }
}

/// Represents sheets that can be presented
enum PresentedSheet: Identifiable {
    case settings
    case gameMenu
    case pauseMenu
    
    var id: String {
        switch self {
        case .settings:
            return "settings"
        case .gameMenu:
            return "gameMenu"
        case .pauseMenu:
            return "pauseMenu"
        }
    }
}

/// User settings and preferences
final class UserSettings: ObservableObject {
    static let shared = UserSettings()
    
    @Published var soundEnabled = true
    @Published var animationSpeed: AnimationSpeed = .normal
    @Published var cardTheme: CardTheme = .classic
    @Published var playerName = "Player"
    @Published var preferredDifficulty: AIDifficulty = .medium
    
    private init() {
        loadSettings()
    }
    
    /// Load settings from UserDefaults
    private func loadSettings() {
        soundEnabled = UserDefaults.standard.bool(forKey: "soundEnabled")
        animationSpeed = AnimationSpeed(rawValue: UserDefaults.standard.string(forKey: "animationSpeed") ?? "normal") ?? .normal
        cardTheme = CardTheme(rawValue: UserDefaults.standard.string(forKey: "cardTheme") ?? "classic") ?? .classic
        playerName = UserDefaults.standard.string(forKey: "playerName") ?? "Player"
        
        if let difficultyString = UserDefaults.standard.object(forKey: "preferredDifficulty") as? String,
           let difficulty = AIDifficulty(rawValue: difficultyString) {
            preferredDifficulty = difficulty
        }
    }
    
    /// Save settings to UserDefaults
    func saveSettings() {
        UserDefaults.standard.set(soundEnabled, forKey: "soundEnabled")
        UserDefaults.standard.set(animationSpeed.rawValue, forKey: "animationSpeed")
        UserDefaults.standard.set(cardTheme.rawValue, forKey: "cardTheme")
        UserDefaults.standard.set(playerName, forKey: "playerName")
        UserDefaults.standard.set(preferredDifficulty.rawValue, forKey: "preferredDifficulty")
    }
}

// MARK: - Settings Types

/// Animation speed options
enum AnimationSpeed: String, CaseIterable, Identifiable {
    case slow = "slow"
    case normal = "normal"
    case fast = "fast"
    case instant = "instant"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .slow:
            return "Slow"
        case .normal:
            return "Normal"
        case .fast:
            return "Fast"
        case .instant:
            return "Instant"
        }
    }
    
    var duration: Double {
        switch self {
        case .slow:
            return 0.8
        case .normal:
            return 0.5
        case .fast:
            return 0.3
        case .instant:
            return 0.1
        }
    }
}

/// Card theme options
enum CardTheme: String, CaseIterable, Identifiable {
    case classic = "classic"
    case modern = "modern"
    case romanian = "romanian"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .classic:
            return "Classic"
        case .modern:
            return "Modern"
        case .romanian:
            return "Romanian"
        }
    }
    
    var description: String {
        switch self {
        case .classic:
            return "Traditional playing card design"
        case .modern:
            return "Clean, minimalist design"
        case .romanian:
            return "Traditional Romanian card style"
        }
    }
}

// MARK: - AI Difficulty Extension

extension AIDifficulty {
    var displayName: String {
        switch self {
        case .easy:
            return "Easy"
        case .medium:
            return "Medium"
        case .hard:
            return "Hard"
        case .expert:
            return "Expert"
        }
    }
    
    var description: String {
        switch self {
        case .easy:
            return "Perfect for beginners learning Septica"
        case .medium:
            return "Good balance of challenge and fun"
        case .hard:
            return "Strategic play with advanced tactics"
        case .expert:
            return "Master-level AI with perfect play"
        }
    }
    
    var iconName: String {
        switch self {
        case .easy:
            return "1.circle"
        case .medium:
            return "2.circle"
        case .hard:
            return "3.circle"
        case .expert:
            return "crown.fill"
        }
    }
}