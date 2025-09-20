//
//  MultiplayerIntegration.swift
//  Septica
//
//  Integration helpers for adding multiplayer to existing game views
//  Provides convenient SwiftUI modifiers and view model integration
//

import Foundation
import SwiftUI
import Combine

// MARK: - SwiftUI Integration

/// SwiftUI environment key for the network coordinator
struct NetworkCoordinatorKey: EnvironmentKey {
    static let defaultValue: NetworkCoordinator? = nil
}

extension EnvironmentValues {
    var networkCoordinator: NetworkCoordinator? {
        get { self[NetworkCoordinatorKey.self] }
        set { self[NetworkCoordinatorKey.self] = newValue }
    }
}

/// SwiftUI modifier for injecting network coordinator
struct NetworkCoordinatorModifier: ViewModifier {
    let coordinator: NetworkCoordinator
    
    func body(content: Content) -> some View {
        content
            .environment(\.networkCoordinator, coordinator)
    }
}

extension View {
    /// Inject a network coordinator into the environment
    func networkCoordinator(_ coordinator: NetworkCoordinator) -> some View {
        self.modifier(NetworkCoordinatorModifier(coordinator: coordinator))
    }
}

// MARK: - Multiplayer-Aware Game View Model

/// Enhanced game view model that integrates with multiplayer networking
@MainActor
class MultiplayerGameViewModel: ObservableObject {
    
    // MARK: - Properties
    
    /// The game state
    @Published var gameState: GameState
    
    /// Network coordinator for multiplayer functionality
    let networkCoordinator: NetworkCoordinator
    
    /// Whether multiplayer is currently active
    @Published var isMultiplayerActive: Bool = false
    
    /// Current connection status
    @Published var connectionStatus: ConnectionStatus = .disconnected
    
    /// Whether searching for an opponent
    @Published var isSearchingForOpponent: Bool = false
    
    /// Whether currently in a multiplayer game
    @Published var isInMultiplayerGame: Bool = false
    
    /// Connection quality for display
    @Published var connectionQuality: ConnectionQuality = .unknown
    
    /// Latest error message for display
    @Published var errorMessage: String?
    
    // MARK: - Private Properties
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init(gameState: GameState, networkCoordinator: NetworkCoordinator) {
        self.gameState = gameState
        self.networkCoordinator = networkCoordinator
        
        setupObservers()
    }
    
    convenience init(gameState: GameState) {
        let coordinator = NetworkCoordinator()
        self.init(gameState: gameState, networkCoordinator: coordinator)
    }
    
    // MARK: - Public API
    
    /// Enable multiplayer mode
    func enableMultiplayer() {
        networkCoordinator.enableMultiplayer(for: gameState)
        isMultiplayerActive = true
    }
    
    /// Disable multiplayer mode
    func disableMultiplayer() {
        networkCoordinator.disableMultiplayer()
        isMultiplayerActive = false
        resetMultiplayerState()
    }
    
    /// Search for an online opponent
    func findOpponent(mode: GameMode = .casual) {
        guard isMultiplayerActive else {
            errorMessage = "Multiplayer not enabled"
            return
        }
        
        networkCoordinator.findGame(mode: mode)
    }
    
    /// Cancel opponent search
    func cancelOpponentSearch() {
        // Leave any pending game search
        networkCoordinator.leaveCurrentGame()
    }
    
    /// Play a card (handles both single-player and multiplayer)
    func playCard(_ card: Card) {
        if isMultiplayerActive && isInMultiplayerGame {
            // Multiplayer mode: send through network
            let success = networkCoordinator.playCard(card)
            if !success {
                errorMessage = "Failed to send card play to server"
            }
        } else {
            // Single-player mode: direct game state update
            let result = gameState.playCard(card, by: gameState.localPlayerId ?? gameState.currentPlayer?.id ?? UUID())
            
            switch result {
            case .success:
                break
            case .failure(let error):
                errorMessage = error.localizedDescription
            }
        }
    }
    
    /// Send a chat message to opponent
    func sendChatMessage(_ message: String) {
        guard isInMultiplayerGame else { return }
        networkCoordinator.sendChatMessage(message)
    }
    
    /// Get connection statistics
    func getConnectionStats() -> ConnectionStats? {
        guard isMultiplayerActive else { return nil }
        return networkCoordinator.getConnectionStats()
    }
    
    /// Force reconnection
    func reconnect() {
        networkCoordinator.reconnect()
    }
    
    /// Start a new single-player game
    func startSinglePlayerGame() {
        disableMultiplayer()
        gameState.setupNewGame()
    }
    
    /// Leave current multiplayer game
    func leaveMultiplayerGame() {
        networkCoordinator.leaveCurrentGame()
    }
    
    // MARK: - Private Methods
    
    private func setupObservers() {
        // Observe network coordinator properties
        networkCoordinator.$connectionStatus
            .receive(on: DispatchQueue.main)
            .assign(to: \.connectionStatus, on: self)
            .store(in: &cancellables)
        
        networkCoordinator.$sessionState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.updateMultiplayerState(from: state)
            }
            .store(in: &cancellables)
        
        networkCoordinator.$connectionQuality
            .receive(on: DispatchQueue.main)
            .assign(to: \.connectionQuality, on: self)
            .store(in: &cancellables)
        
        // Observe multiplayer errors
        networkCoordinator.multiplayerService.errorPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] error in
                self?.errorMessage = error.localizedDescription
            }
            .store(in: &cancellables)
        
        // Clear error message after a delay
        $errorMessage
            .compactMap { $0 }
            .debounce(for: .seconds(5), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.errorMessage = nil
            }
            .store(in: &cancellables)
    }
    
    private func updateMultiplayerState(from sessionState: MultiplayerSessionState) {
        switch sessionState {
        case .disconnected:
            isSearchingForOpponent = false
            isInMultiplayerGame = false
            
        case .connected:
            isSearchingForOpponent = false
            isInMultiplayerGame = false
            
        case .searchingForGame:
            isSearchingForOpponent = true
            isInMultiplayerGame = false
            
        case .inGame:
            isSearchingForOpponent = false
            isInMultiplayerGame = true
            
        case .reconnecting:
            // Keep current state but show reconnecting status
            break
        }
    }
    
    private func resetMultiplayerState() {
        isSearchingForOpponent = false
        isInMultiplayerGame = false
        connectionStatus = .disconnected
        connectionQuality = .unknown
        errorMessage = nil
    }
}

// MARK: - Connection Status Display Helpers

extension ConnectionStatus {
    /// User-friendly display text
    var displayText: String {
        switch self {
        case .disconnected:
            return "Disconnected"
        case .connecting:
            return "Connecting..."
        case .connected:
            return "Connected"
        case .reconnecting:
            return "Reconnecting..."
        case .error:
            return "Connection Error"
        }
    }
    
    /// Color for status display
    var statusColor: Color {
        switch self {
        case .disconnected, .error:
            return .red
        case .connecting, .reconnecting:
            return .orange
        case .connected:
            return .green
        }
    }
}

extension ConnectionQuality {
    /// Color for quality indicator
    var qualityColor: Color {
        switch self {
        case .unknown:
            return .gray
        case .excellent:
            return .green
        case .good:
            return .green
        case .fair:
            return .orange
        case .poor:
            return .red
        }
    }
    
    /// Icon for quality display
    var qualityIcon: String {
        switch self {
        case .unknown:
            return "questionmark.circle"
        case .excellent:
            return "wifi.circle.fill"
        case .good:
            return "wifi.circle"
        case .fair:
            return "wifi.slash.circle"
        case .poor:
            return "exclamationmark.triangle"
        }
    }
}

// MARK: - Convenience SwiftUI Views

/// Connection status indicator view
struct ConnectionStatusView: View {
    let status: ConnectionStatus
    let quality: ConnectionQuality
    let compact: Bool
    
    init(status: ConnectionStatus, quality: ConnectionQuality = .unknown, compact: Bool = false) {
        self.status = status
        self.quality = quality
        self.compact = compact
    }
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: quality.qualityIcon)
                .foregroundColor(quality.qualityColor)
            
            if !compact {
                Text(status.displayText)
                    .foregroundColor(status.statusColor)
                    .font(.caption)
            }
        }
    }
}

/// Multiplayer game controls view
struct MultiplayerControlsView: View {
    @ObservedObject var viewModel: MultiplayerGameViewModel
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                ConnectionStatusView(
                    status: viewModel.connectionStatus,
                    quality: viewModel.connectionQuality
                )
                
                Spacer()
                
                if viewModel.isMultiplayerActive {
                    Button("Leave Game") {
                        viewModel.leaveMultiplayerGame()
                    }
                    .foregroundColor(.red)
                }
            }
            
            if let error = viewModel.errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .font(.caption)
                    .multilineTextAlignment(.center)
            }
            
            if viewModel.isSearchingForOpponent {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Finding opponent...")
                        .font(.caption)
                }
            }
        }
        .padding(.horizontal)
    }
}

// MARK: - PreviewProvider

#if DEBUG
struct MultiplayerIntegration_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            ConnectionStatusView(status: .connected, quality: .excellent)
            ConnectionStatusView(status: .connecting, quality: .good, compact: true)
            ConnectionStatusView(status: .error, quality: .poor)
            
            MultiplayerControlsView(
                viewModel: MultiplayerGameViewModel(
                    gameState: GameState(),
                    networkCoordinator: NetworkCoordinator()
                )
            )
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
#endif