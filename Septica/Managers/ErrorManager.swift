//
//  ErrorManager.swift
//  Septica
//
//  Comprehensive error handling and user-friendly messaging system
//  Provides graceful error recovery and clear user communication
//

import SwiftUI
import Combine

/// Centralized error management for the entire application
@MainActor
class ErrorManager: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var currentError: GameError?
    @Published var errorHistory: [ErrorRecord] = []
    @Published var isShowingError = false
    @Published var errorQueue: [GameError] = []
    @Published var showErrorDetails = false
    
    // MARK: - Error Types
    
    enum GameError: Error, Equatable, Identifiable {
        case invalidMove(reason: String)
        case gameStateCorruption(details: String)
        case aiPlayerError(error: String)
        case saveDataCorruption(message: String)
        case performanceWarning(metric: String, value: Double)
        case networkConnectionLost
        case insufficientMemory(currentUsage: Double)
        case accessibilityServiceFailed(service: String)
        case audioSystemError(error: String)
        case animationSystemFailure
        case criticalSystemError(error: String)
        
        var id: String {
            switch self {
            case .invalidMove: return "invalid_move"
            case .gameStateCorruption: return "game_state_corruption"
            case .aiPlayerError: return "ai_player_error"
            case .saveDataCorruption: return "save_data_corruption"
            case .performanceWarning: return "performance_warning"
            case .networkConnectionLost: return "network_connection_lost"
            case .insufficientMemory: return "insufficient_memory"
            case .accessibilityServiceFailed: return "accessibility_service_failed"
            case .audioSystemError: return "audio_system_error"
            case .animationSystemFailure: return "animation_system_failure"
            case .criticalSystemError: return "critical_system_error"
            }
        }
    }
    
    // MARK: - Error Severity
    
    enum ErrorSeverity {
        case info       // Informational messages
        case warning    // Non-critical issues
        case error      // Recoverable errors
        case critical   // Critical errors requiring attention
        
        var color: Color {
            switch self {
            case .info: return .blue
            case .warning: return .orange
            case .error: return .red
            case .critical: return .red
            }
        }
        
        var icon: String {
            switch self {
            case .info: return "info.circle.fill"
            case .warning: return "exclamationmark.triangle.fill"
            case .error: return "xmark.circle.fill"
            case .critical: return "xmark.octagon.fill"
            }
        }
    }
    
    // MARK: - Error Record
    
    struct ErrorRecord: Identifiable {
        let id = UUID()
        let error: GameError
        let timestamp = Date()
        let severity: ErrorSeverity
        let context: String
        let wasRecovered: Bool
        let userAction: String?
    }
    
    // MARK: - Recovery Actions
    
    enum RecoveryAction {
        case retry
        case skipTurn
        case restartGame
        case returnToMenu
        case clearSaveData
        case reduceAnimations
        case closeApp
        case reportIssue
        
        var title: String {
            switch self {
            case .retry: return "Try Again"
            case .skipTurn: return "Skip Turn"
            case .restartGame: return "Restart Game"
            case .returnToMenu: return "Return to Menu"
            case .clearSaveData: return "Reset Game Data"
            case .reduceAnimations: return "Reduce Animations"
            case .closeApp: return "Close App"
            case .reportIssue: return "Report Issue"
            }
        }
        
        var description: String {
            switch self {
            case .retry: return "Attempt the action again"
            case .skipTurn: return "Skip the current turn and continue"
            case .restartGame: return "Start a new game"
            case .returnToMenu: return "Go back to the main menu"
            case .clearSaveData: return "Clear all saved data and start fresh"
            case .reduceAnimations: return "Turn off animations to improve performance"
            case .closeApp: return "Close the application"
            case .reportIssue: return "Send feedback to developers"
            }
        }
    }
    
    // MARK: - Error Handling
    
    /// Report an error to the manager
    func reportError(_ error: GameError, context: String = "", severity: ErrorSeverity? = nil) {
        let errorSeverity = severity ?? determineSeverity(for: error)
        let record = ErrorRecord(
            error: error,
            severity: errorSeverity,
            context: context,
            wasRecovered: false,
            userAction: nil
        )
        
        errorHistory.append(record)
        
        // Handle based on severity
        switch errorSeverity {
        case .info, .warning:
            // Show brief notification
            showBriefNotification(for: error)
        case .error, .critical:
            // Queue for user attention
            queueErrorForDisplay(error)
        }
        
        // Log for debugging
        logError(record)
    }
    
    /// Determine error severity automatically
    func determineSeverity(for error: GameError) -> ErrorSeverity {
        switch error {
        case .invalidMove:
            return .info
        case .performanceWarning:
            return .warning
        case .gameStateCorruption, .saveDataCorruption, .aiPlayerError, .insufficientMemory:
            return .error
        case .criticalSystemError, .accessibilityServiceFailed:
            return .critical
        case .networkConnectionLost, .audioSystemError, .animationSystemFailure:
            return .warning
        }
    }
    
    /// Queue error for user display
    private func queueErrorForDisplay(_ error: GameError) {
        if !errorQueue.contains(error) {
            errorQueue.append(error)
        }
        
        if currentError == nil {
            showNextError()
        }
    }
    
    /// Show the next error in queue
    private func showNextError() {
        guard !errorQueue.isEmpty else { return }
        
        currentError = errorQueue.removeFirst()
        isShowingError = true
    }
    
    /// Dismiss current error and show next
    func dismissCurrentError(wasRecovered: Bool = false, userAction: String? = nil) {
        // Update error record
        if let error = currentError,
           let index = errorHistory.firstIndex(where: { $0.error == error && !$0.wasRecovered }) {
            errorHistory[index] = ErrorRecord(
                error: error,
                severity: errorHistory[index].severity,
                context: errorHistory[index].context,
                wasRecovered: wasRecovered,
                userAction: userAction
            )
        }
        
        currentError = nil
        isShowingError = false
        
        // Show next error if any
        if !errorQueue.isEmpty {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.showNextError()
            }
        }
    }
    
    // MARK: - User-Friendly Messages
    
    /// Get user-friendly error message
    func getUserMessage(for error: GameError) -> String {
        switch error {
        case .invalidMove(let reason):
            return "That move isn't allowed. \(reason)"
        case .gameStateCorruption:
            return "The game encountered an issue. Please restart for the best experience."
        case .aiPlayerError:
            return "The AI player encountered an issue. The game will continue normally."
        case .saveDataCorruption:
            return "Your saved game data appears to be corrupted. Starting fresh is recommended."
        case .performanceWarning(let metric, let value):
            return "Performance issue detected (\(metric): \(String(format: "%.1f", value))). Consider reducing animations."
        case .networkConnectionLost:
            return "Network connection lost. The game continues offline."
        case .insufficientMemory(let usage):
            return "Low memory detected (\(String(format: "%.1f", usage))MB). Closing other apps may help."
        case .accessibilityServiceFailed(let service):
            return "Accessibility feature '\(service)' is not responding properly."
        case .audioSystemError:
            return "Audio system encountered an issue. Sound may be temporarily disabled."
        case .animationSystemFailure:
            return "Animation system error. Animations have been disabled for stability."
        case .criticalSystemError:
            return "A critical error occurred. Please restart the app."
        }
    }
    
    /// Get detailed error description
    func getDetailedMessage(for error: GameError) -> String {
        switch error {
        case .invalidMove(let reason):
            return "Invalid Move Details:\n\(reason)\n\nIn Septica, you must follow the lead suit if you have cards of that suit. If you don't have the lead suit, you may play any card."
        case .gameStateCorruption(let details):
            return "Game State Issue:\n\(details)\n\nThis can happen due to memory pressure or unexpected interruptions. Restarting will fix the issue."
        case .aiPlayerError(let error):
            return "AI Player Issue:\n\(error)\n\nThe AI encountered an unexpected situation but the game will continue normally."
        case .saveDataCorruption(let message):
            return "Save Data Issue:\n\(message)\n\nThis can happen after app updates or system changes. Your progress will restart but settings are preserved."
        case .performanceWarning(let metric, let value):
            return "Performance Alert:\n\(metric) is at \(String(format: "%.1f", value))\n\nTry closing other apps or reducing animation settings for better performance."
        case .networkConnectionLost:
            return "Network Status:\nConnection to internet lost.\n\nSeptica is fully offline so gameplay is not affected. Network is only used for optional features."
        case .insufficientMemory(let usage):
            return "Memory Usage:\nCurrent usage: \(String(format: "%.1f", usage))MB\n\nClosing other apps will free up memory and improve performance."
        case .accessibilityServiceFailed(let service):
            return "Accessibility Service:\n\(service) is not responding\n\nTry disabling and re-enabling the accessibility feature in Settings > Accessibility."
        case .audioSystemError(let error):
            return "Audio System:\n\(error)\n\nTry adjusting volume settings or restarting the app to restore audio."
        case .animationSystemFailure:
            return "Animation System:\nUnexpected animation error occurred\n\nAnimations have been disabled to maintain stability. You can re-enable them in Settings."
        case .criticalSystemError(let error):
            return "Critical Error:\n\(error)\n\nPlease restart the app. If this continues, please report the issue."
        }
    }
    
    /// Get recovery actions for error
    func getRecoveryActions(for error: GameError) -> [RecoveryAction] {
        switch error {
        case .invalidMove:
            return [.retry]
        case .gameStateCorruption:
            return [.restartGame, .returnToMenu]
        case .aiPlayerError:
            return [.retry, .skipTurn, .restartGame]
        case .saveDataCorruption:
            return [.clearSaveData, .returnToMenu]
        case .performanceWarning:
            return [.reduceAnimations, .closeApp]
        case .networkConnectionLost:
            return [] // No action needed
        case .insufficientMemory:
            return [.reduceAnimations, .closeApp, .restartGame]
        case .accessibilityServiceFailed:
            return [.reportIssue]
        case .audioSystemError:
            return [.retry, .reportIssue]
        case .animationSystemFailure:
            return [.reduceAnimations, .restartGame]
        case .criticalSystemError:
            return [.closeApp, .reportIssue]
        }
    }
    
    // MARK: - Recovery Execution
    
    /// Execute a recovery action
    func executeRecoveryAction(_ action: RecoveryAction, completion: @escaping (Bool) -> Void) {
        switch action {
        case .retry:
            // Signal to retry the last action
            dismissCurrentError(wasRecovered: true, userAction: "retry")
            completion(true)
        case .skipTurn:
            // Signal to skip current turn
            dismissCurrentError(wasRecovered: true, userAction: "skip_turn")
            completion(true)
        case .restartGame:
            // Signal to restart game
            dismissCurrentError(wasRecovered: true, userAction: "restart_game")
            completion(true)
        case .returnToMenu:
            // Signal to return to menu
            dismissCurrentError(wasRecovered: true, userAction: "return_to_menu")
            completion(true)
        case .clearSaveData:
            // Clear saved data
            clearSaveData()
            dismissCurrentError(wasRecovered: true, userAction: "clear_save_data")
            completion(true)
        case .reduceAnimations:
            // Reduce animations
            reduceAnimations()
            dismissCurrentError(wasRecovered: true, userAction: "reduce_animations")
            completion(true)
        case .closeApp:
            // Close app (will be handled by the app)
            dismissCurrentError(wasRecovered: false, userAction: "close_app")
            completion(false)
        case .reportIssue:
            // Open issue reporting (placeholder)
            reportIssue()
            dismissCurrentError(wasRecovered: false, userAction: "report_issue")
            completion(true)
        }
    }
    
    // MARK: - Recovery Implementation
    
    private func clearSaveData() {
        UserDefaults.standard.removeObject(forKey: "saved_game_state")
        UserDefaults.standard.removeObject(forKey: "game_statistics")
    }
    
    private func reduceAnimations() {
        UserDefaults.standard.set(true, forKey: "reduce_animations")
        // Post notification to animation manager
        NotificationCenter.default.post(name: .reduceAnimations, object: nil)
    }
    
    private func reportIssue() {
        // In a real app, this would open the system mail composer or feedback form
        print("Issue reporting would open here")
    }
    
    // MARK: - Utility Functions
    
    private func showBriefNotification(for error: GameError) {
        // Could show a toast notification
        // For now, we'll just log
        print("Brief notification: \(getUserMessage(for: error))")
    }
    
    private func logError(_ record: ErrorRecord) {
        print("🔴 Error logged: \(record.error.id) - \(record.severity) - \(record.context)")
    }
    
    /// Clear error history
    func clearErrorHistory() {
        errorHistory.removeAll()
    }
    
    /// Get error statistics
    func getErrorStatistics() -> (total: Int, byType: [String: Int], bySeverity: [ErrorSeverity: Int]) {
        let total = errorHistory.count
        let byType = Dictionary(grouping: errorHistory) { $0.error.id }
            .mapValues { $0.count }
        let bySeverity = Dictionary(grouping: errorHistory) { $0.severity }
            .mapValues { $0.count }
        
        return (total, byType, bySeverity)
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let reduceAnimations = Notification.Name("reduce_animations")
}

// MARK: - SwiftUI Integration

struct ErrorDisplayView: View {
    @ObservedObject var errorManager: ErrorManager
    
    var body: some View {
        if let error = errorManager.currentError {
            ErrorAlertView(
                error: error,
                manager: errorManager
            )
        }
    }
}

struct ErrorAlertView: View {
    let error: ErrorManager.GameError
    let manager: ErrorManager
    
    @State private var showDetails = false
    
    var body: some View {
        VStack(spacing: 20) {
            // Error icon and title
            HStack {
                Image(systemName: manager.determineSeverity(for: error).icon)
                    .foregroundColor(manager.determineSeverity(for: error).color)
                    .font(.title2)
                
                Text("Oops!")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
            }
            
            // Error message
            Text(manager.getUserMessage(for: error))
                .font(.body)
                .multilineTextAlignment(.leading)
            
            // Details toggle
            Button(action: { showDetails.toggle() }) {
                HStack {
                    Text(showDetails ? "Hide Details" : "Show Details")
                    Image(systemName: showDetails ? "chevron.up" : "chevron.down")
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
            
            // Detailed message (if showing)
            if showDetails {
                ScrollView {
                    Text(manager.getDetailedMessage(for: error))
                        .font(.caption)
                        .multilineTextAlignment(.leading)
                }
                .frame(maxHeight: 100)
            }
            
            // Recovery actions
            VStack(spacing: 12) {
                ForEach(manager.getRecoveryActions(for: error), id: \.self) { action in
                    Button(action: {
                        manager.executeRecoveryAction(action) { success in
                            // Handle completion
                        }
                    }) {
                        HStack {
                            Text(action.title)
                                .fontWeight(.medium)
                            Spacer()
                        }
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                }
            }
            
            // Dismiss button
            Button("Dismiss") {
                manager.dismissCurrentError()
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
        .padding(20)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(radius: 10)
        .padding(.horizontal, 20)
    }
}

// MARK: - Preview Support

#if DEBUG
extension ErrorManager {
    static let preview: ErrorManager = {
        let manager = ErrorManager()
        return manager
    }()
}
#endif