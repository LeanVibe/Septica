//
//  SepticaErrorHandling.swift
//  Septica
//
//  Standardized error handling patterns for Romanian Septica card game
//  Provides consistent error types, reporting, and recovery patterns
//

import SwiftUI
import Foundation

// MARK: - Core Error Protocol

/// Base protocol for all Septica errors
/// Provides standardized error handling across the application
protocol SepticaError: Error, LocalizedError {
    var code: String { get }
    var severity: ErrorSeverity { get }
    var context: String? { get }
    var recoveryOptions: [ErrorRecoveryOption] { get }
    var userMessage: String { get }
    var debugInfo: String? { get }
}

// MARK: - Error Severity Levels

enum ErrorSeverity: String, CaseIterable, Comparable {
    case info = "Info"
    case warning = "Warning"
    case error = "Error"
    case critical = "Critical"
    case fatal = "Fatal"
    
    static func < (lhs: ErrorSeverity, rhs: ErrorSeverity) -> Bool {
        let order: [ErrorSeverity] = [.info, .warning, .error, .critical, .fatal]
        guard let lhsIndex = order.firstIndex(of: lhs),
              let rhsIndex = order.firstIndex(of: rhs) else {
            return false
        }
        return lhsIndex < rhsIndex
    }
    
    var icon: String {
        switch self {
        case .info: return "info.circle"
        case .warning: return "exclamationmark.triangle"
        case .error: return "xmark.circle"
        case .critical: return "exclamationmark.octagon"
        case .fatal: return "multiply.circle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .info: return .blue
        case .warning: return .orange
        case .error: return .red
        case .critical: return .red
        case .fatal: return .red
        }
    }
}

// MARK: - Error Recovery Options

enum ErrorRecoveryOption: String, CaseIterable {
    case retry = "Retry"
    case ignore = "Ignore"
    case restart = "Restart Game"
    case reset = "Reset to Menu"
    case reportBug = "Report Bug"
    case none = "None"
    
    var isUserActionRequired: Bool {
        switch self {
        case .retry, .restart, .reset, .reportBug:
            return true
        case .ignore, .none:
            return false
        }
    }
}

// MARK: - Standard Error Categories

/// Game logic errors
enum GameLogicError: SepticaError {
    case invalidMove(reason: String)
    case invalidCard(cardDescription: String)
    case gameStateCorruption
    case ruleViolation(rule: String)
    case aiDecisionFailure
    
    var code: String {
        switch self {
        case .invalidMove: return "GAME_001"
        case .invalidCard: return "GAME_002"
        case .gameStateCorruption: return "GAME_003"
        case .ruleViolation: return "GAME_004"
        case .aiDecisionFailure: return "GAME_005"
        }
    }
    
    var severity: ErrorSeverity {
        switch self {
        case .invalidMove, .invalidCard: return .warning
        case .gameStateCorruption, .aiDecisionFailure: return .critical
        case .ruleViolation: return .error
        }
    }
    
    var context: String? {
        return "Game Logic"
    }
    
    var recoveryOptions: [ErrorRecoveryOption] {
        switch self {
        case .invalidMove, .invalidCard: return [.ignore]
        case .gameStateCorruption: return [.restart, .reset]
        case .ruleViolation: return [.retry, .reportBug]
        case .aiDecisionFailure: return [.retry, .restart]
        }
    }
    
    var userMessage: String {
        switch self {
        case .invalidMove(let reason): return "Invalid move: \(reason)"
        case .invalidCard(let card): return "Cannot play \(card)"
        case .gameStateCorruption: return "Game state error - please restart"
        case .ruleViolation(let rule): return "Rule violation: \(rule)"
        case .aiDecisionFailure: return "AI opponent encountered an error"
        }
    }
    
    var debugInfo: String? {
        switch self {
        case .invalidMove(let reason): return "Move validation failed: \(reason)"
        case .invalidCard(let card): return "Card validation failed for: \(card)"
        case .gameStateCorruption: return "Game state consistency check failed"
        case .ruleViolation(let rule): return "Rule engine violation: \(rule)"
        case .aiDecisionFailure: return "AI decision tree execution failed"
        }
    }
    
    var errorDescription: String? { return userMessage }
}

/// System and performance errors
enum SystemError: SepticaError {
    case memoryExhausted(currentUsage: Double)
    case performanceDegraded(metric: String, value: Double)
    case metalRenderingFailed(details: String)
    case audioSystemFailure
    case storageError(operation: String)
    
    var code: String {
        switch self {
        case .memoryExhausted: return "SYS_001"
        case .performanceDegraded: return "SYS_002"
        case .metalRenderingFailed: return "SYS_003"
        case .audioSystemFailure: return "SYS_004"
        case .storageError: return "SYS_005"
        }
    }
    
    var severity: ErrorSeverity {
        switch self {
        case .memoryExhausted, .metalRenderingFailed: return .critical
        case .performanceDegraded, .audioSystemFailure: return .warning
        case .storageError: return .error
        }
    }
    
    var context: String? {
        return "System"
    }
    
    var recoveryOptions: [ErrorRecoveryOption] {
        switch self {
        case .memoryExhausted: return [.restart, .reset]
        case .performanceDegraded: return [.ignore, .restart]
        case .metalRenderingFailed: return [.restart, .reportBug]
        case .audioSystemFailure: return [.ignore]
        case .storageError: return [.retry, .reportBug]
        }
    }
    
    var userMessage: String {
        switch self {
        case .memoryExhausted: return "Device memory is full"
        case .performanceDegraded: return "Performance has been reduced"
        case .metalRenderingFailed: return "Graphics system error"
        case .audioSystemFailure: return "Audio system unavailable"
        case .storageError: return "Failed to save game data"
        }
    }
    
    var debugInfo: String? {
        switch self {
        case .memoryExhausted(let usage): return "Memory usage: \(usage)MB"
        case .performanceDegraded(let metric, let value): return "\(metric): \(value)"
        case .metalRenderingFailed(let details): return "Metal error: \(details)"
        case .audioSystemFailure: return "AVAudioEngine initialization failed"
        case .storageError(let operation): return "Storage operation failed: \(operation)"
        }
    }
    
    var errorDescription: String? { return userMessage }
}

/// Network and external service errors (for future use)
enum NetworkError: SepticaError {
    case connectionFailed
    case timeout
    case serverError(statusCode: Int)
    case dataCorrupted
    
    var code: String {
        switch self {
        case .connectionFailed: return "NET_001"
        case .timeout: return "NET_002"
        case .serverError: return "NET_003"
        case .dataCorrupted: return "NET_004"
        }
    }
    
    var severity: ErrorSeverity {
        switch self {
        case .connectionFailed, .timeout: return .warning
        case .serverError, .dataCorrupted: return .error
        }
    }
    
    var context: String? {
        return "Network"
    }
    
    var recoveryOptions: [ErrorRecoveryOption] {
        return [.retry, .ignore]
    }
    
    var userMessage: String {
        switch self {
        case .connectionFailed: return "Connection failed"
        case .timeout: return "Request timed out"
        case .serverError: return "Server error"
        case .dataCorrupted: return "Data corrupted"
        }
    }
    
    var debugInfo: String? {
        switch self {
        case .connectionFailed: return "Network connection unavailable"
        case .timeout: return "Request exceeded timeout limit"
        case .serverError(let code): return "HTTP status code: \(code)"
        case .dataCorrupted: return "Response data failed validation"
        }
    }
    
    var errorDescription: String? { return userMessage }
}

// MARK: - Error Handler Protocol

/// Standard interface for error handling components
protocol ErrorHandler {
    func handle<T: SepticaError>(_ error: T, context: String?)
    func canRecover<T: SepticaError>(from error: T) -> Bool
    func attemptRecovery<T: SepticaError>(from error: T, option: ErrorRecoveryOption) async -> Bool
}

// MARK: - Error Result Type

/// Standard Result type for consistent error handling
typealias SepticaResult<Success, Failure: SepticaError> = Result<Success, Failure>

// MARK: - Error Extension Utilities

extension SepticaError {
    /// Default description implementation
    var debugDescription: String {
        return "\(code): \(userMessage)"
    }
}

extension SepticaError {
    /// Check if error should be logged
    var shouldLog: Bool {
        return severity >= .warning
    }
    
    /// Check if error should be reported to user
    var shouldShowToUser: Bool {
        return severity >= .error
    }
    
    /// Check if error should trigger haptic feedback
    var shouldTriggerHaptic: Bool {
        return severity >= .warning
    }
    
    /// Get accessibility announcement for error
    var accessibilityAnnouncement: String {
        return "Error: \(userMessage)"
    }
}

// MARK: - Error Handling Utilities

enum ErrorHandlingUtils {
    
    /// Handle error with full manager coordination
    static func handle<T: SepticaError>(
        _ error: T,
        coordinator: ManagerCoordinator,
        context: String? = nil
    ) {
        // Log error
        if error.shouldLog {
            print("🔴 [\(error.code)] \(error.debugDescription)")
            if let debug = error.debugInfo {
                print("   Debug: \(debug)")
            }
        }
        
        // Report to ErrorManager (convert to compatible type)
        if let gameError = convertToGameError(error) {
            coordinator.errorManager.reportError(gameError, context: context ?? error.context ?? "Unknown")
        }
        
        // Trigger haptic feedback
        if error.shouldTriggerHaptic {
            let feedback: HapticManager.HapticFeedback = error.severity >= .critical ? .error : .warning
            coordinator.hapticManager.trigger(feedback)
        }
        
        // Accessibility announcement
        if error.shouldShowToUser {
            coordinator.accessibilityManager.announceGameState(error.accessibilityAnnouncement)
        }
        
        // Performance impact tracking
        if error.severity >= .error {
            coordinator.performanceMonitor.recordMetric(
                name: "ErrorOccurred",
                value: 1,
                unit: "errors"
            )
        }
    }
    
    /// Convert SepticaError to ErrorManager.GameError for compatibility
    private static func convertToGameError<T: SepticaError>(_ error: T) -> ErrorManager.GameError? {
        switch error {
        case let gameLogic as GameLogicError:
            switch gameLogic {
            case .invalidMove(let reason): return .invalidMove(reason: reason)
            case .gameStateCorruption: return .gameStateCorruption(details: "Game state corruption detected")
            case .aiDecisionFailure: return .criticalSystemError(error: "AI decision failure")
            default: return .criticalSystemError(error: "Unknown game logic error")
            }
        case let system as SystemError:
            switch system {
            case .memoryExhausted(let usage): return .insufficientMemory(currentUsage: usage)
            case .performanceDegraded(let metric, let value): 
                return .performanceWarning(metric: metric, value: value)
            case .metalRenderingFailed(let details): 
                return .criticalSystemError(error: details)
            case .audioSystemFailure: 
                return .audioSystemError(error: "Audio system failure")
            case .storageError(let operation): 
                return .criticalSystemError(error: "Storage error: \(operation)")
            }
        default:
            return .criticalSystemError(error: "Unknown error type")
        }
    }
    
    /// Execute operation with standardized error handling
    static func executeWithErrorHandling<T>(
        operation: () throws -> T,
        coordinator: ManagerCoordinator,
        context: String = "Operation",
        fallback: T? = nil
    ) -> T? {
        do {
            return try operation()
        } catch let septicaError as SepticaError {
            handle(septicaError, coordinator: coordinator, context: context)
            return fallback
        } catch {
            // Convert generic error to SystemError
            let systemError = SystemError.storageError(operation: error.localizedDescription)
            handle(systemError, coordinator: coordinator, context: context)
            return fallback
        }
    }
    
    /// Execute async operation with standardized error handling
    static func executeAsyncWithErrorHandling<T>(
        operation: () async throws -> T,
        coordinator: ManagerCoordinator,
        context: String = "Async Operation",
        fallback: T? = nil
    ) async -> T? {
        do {
            return try await operation()
        } catch let septicaError as SepticaError {
            handle(septicaError, coordinator: coordinator, context: context)
            return fallback
        } catch {
            // Convert generic error to SystemError
            let systemError = SystemError.storageError(operation: error.localizedDescription)
            handle(systemError, coordinator: coordinator, context: context)
            return fallback
        }
    }
}

// MARK: - SwiftUI Error Display Components

struct StandardizedErrorView: View {
    let error: any SepticaError
    let onDismiss: () -> Void
    let onRecovery: (ErrorRecoveryOption) -> Void
    @State private var showingAlert = true
    
    var body: some View {
        EmptyView()
            .alert(error.severity.rawValue, isPresented: $showingAlert) {
                Button("OK") {
                    onDismiss()
                }
                
                if let primaryRecovery = error.recoveryOptions.first,
                   primaryRecovery.isUserActionRequired {
                    Button(primaryRecovery.rawValue) {
                        onRecovery(primaryRecovery)
                    }
                }
            } message: {
                Text(error.userMessage)
            }
    }
}

// MARK: - Error Logging Extensions

extension SepticaError {
    /// Create structured log entry
    var logEntry: String {
        var components = [
            "[\(code)]",
            severity.rawValue.uppercased(),
            userMessage
        ]
        
        if let context = context {
            components.append("Context: \(context)")
        }
        
        if let debug = debugInfo {
            components.append("Debug: \(debug)")
        }
        
        return components.joined(separator: " | ")
    }
    
    /// Create dictionary for analytics/crash reporting
    var analyticsData: [String: Any] {
        var data: [String: Any] = [
            "error_code": code,
            "severity": severity.rawValue,
            "user_message": userMessage,
            "recovery_options": recoveryOptions.map { $0.rawValue }
        ]
        
        if let context = context {
            data["context"] = context
        }
        
        if let debug = debugInfo {
            data["debug_info"] = debug
        }
        
        return data
    }
}

// MARK: - Global Error Constants

enum SepticaErrorConstants {
    static let maxErrorHistorySize = 100
    static let errorDisplayDuration: TimeInterval = 5.0
    static let criticalErrorDisplayDuration: TimeInterval = 10.0
    static let maxRetryAttempts = 3
    static let retryDelay: TimeInterval = 1.0
}

// MARK: - Preview Support

#if DEBUG
extension GameLogicError {
    static let previewError = GameLogicError.invalidMove(reason: "Preview error for testing")
}

extension SystemError {
    static let previewError = SystemError.performanceDegraded(metric: "FPS", value: 30.0)
}
#endif