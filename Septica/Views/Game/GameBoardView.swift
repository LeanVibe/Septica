//
//  GameBoardView.swift
//  Septica
//
//  Main game board view for Septica card game
//  Displays the game table, player hands, and game controls
//

import SwiftUI

/// Main game board view that displays the complete Septica game interface
struct GameBoardView: View {
    @StateObject private var gameViewModel: GameViewModel
    @State private var selectedCard: Card?
    @State private var showingGameMenu = false
    @State private var animatingCard: Card?
    
    init(gameState: GameState) {
        self._gameViewModel = StateObject(wrappedValue: GameViewModel(gameState: gameState))
    }
    
    var body: some View {
        ZStack {
            // Background
            GameTableBackground()
            
            VStack(spacing: 20) {
                // Top player area (opponent)
                if gameViewModel.players.count > 1 {
                    OpponentHandView(
                        player: gameViewModel.players[1],
                        isCurrentPlayer: gameViewModel.currentPlayerIndex == 1
                    )
                    .rotationEffect(.degrees(180))
                }
                
                Spacer()
                
                // Game table (center area)
                GameTableView(
                    tableCards: gameViewModel.tableCards,
                    validMoves: gameViewModel.validMoves,
                    onCardTapped: playCard,
                    animatingCard: animatingCard
                )
                
                Spacer()
                
                // Bottom player area (human player)
                if let currentPlayer = gameViewModel.humanPlayer {
                    PlayerHandView(
                        player: currentPlayer,
                        selectedCard: selectedCard,
                        validMoves: gameViewModel.validMoves,
                        onCardSelected: { card in
                            selectedCard = card
                        },
                        onCardPlayed: playCard,
                        isCurrentPlayer: gameViewModel.isHumanPlayerTurn,
                        isInteractionEnabled: gameViewModel.canHumanPlayerMove
                    )
                }
            }
            .padding()
            
            // Game controls overlay
            VStack {
                HStack {
                    // Game info
                    GameInfoView(
                        currentPlayer: gameViewModel.currentPlayer?.name ?? "",
                        scores: gameViewModel.playerScores,
                        trickNumber: gameViewModel.gameState.trickNumber,
                        roundNumber: gameViewModel.gameState.roundNumber
                    )
                    
                    Spacer()
                    
                    // Menu button
                    Button(action: { showingGameMenu.toggle() }) {
                        Image(systemName: "line.horizontal.3")
                            .font(.title2)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.black.opacity(0.6))
                            .clipShape(Circle())
                    }
                }
                
                Spacer()
                
                // Game status messages
                if let statusMessage = gameViewModel.statusMessage {
                    GameStatusMessageView(message: statusMessage)
                        .transition(.opacity)
                }
            }
            .padding()
            
            // Game result overlay
            if let gameResult = gameViewModel.gameState.gameResult {
                GameResultView(
                    result: gameResult,
                    playerNames: gameViewModel.players.map { $0.name },
                    onNewGame: {
                        gameViewModel.startNewGame()
                    },
                    onMainMenu: {
                        // TODO: Navigate to main menu
                    }
                )
                .transition(.scale.combined(with: .opacity))
                .zIndex(1000)
            }
        }
        .navigationBarHidden(true)
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showingGameMenu) {
            GameMenuView(
                onResume: { showingGameMenu = false },
                onNewGame: {
                    showingGameMenu = false
                    gameViewModel.startNewGame()
                },
                onMainMenu: {
                    // TODO: Navigate to main menu
                }
            )
        }
        .onAppear {
            gameViewModel.startGame()
        }
    }
    
    /// Play a card with animation
    private func playCard(_ card: Card) {
        guard gameViewModel.canPlayCard(card) else { return }
        
        selectedCard = nil
        animatingCard = card
        
        // Animate card to table
        withAnimation(.easeInOut(duration: 0.5)) {
            gameViewModel.playCard(card)
        }
        
        // Clear animation after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            animatingCard = nil
        }
    }
}

/// Background view for the game table
struct GameTableBackground: View {
    var body: some View {
        Rectangle()
            .fill(
                RadialGradient(
                    colors: [
                        Color(red: 0.1, green: 0.3, blue: 0.1),
                        Color(red: 0.05, green: 0.15, blue: 0.05)
                    ],
                    center: .center,
                    startRadius: 100,
                    endRadius: 400
                )
            )
            .ignoresSafeArea()
    }
}

/// Game information display (scores, turn info)
struct GameInfoView: View {
    let currentPlayer: String
    let scores: [String: Int]
    let trickNumber: Int
    let roundNumber: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Current player
            HStack {
                Circle()
                    .fill(Color.green)
                    .frame(width: 8, height: 8)
                Text("Rândul lui \(currentPlayer)")
                    .font(.headline)
                    .foregroundColor(.white)
            }
            
            // Scores
            VStack(alignment: .leading, spacing: 4) {
                ForEach(scores.sorted(by: { $0.key < $1.key }), id: \.key) { playerName, score in
                    HStack {
                        Text(playerName)
                            .font(.caption)
                        Spacer()
                        Text("\(score)")
                            .font(.caption.bold())
                    }
                }
            }
            .foregroundColor(.white.opacity(0.9))
            
            // Game progress
            Text("Rundă \(roundNumber) • Mână \(trickNumber)")
                .font(.caption2)
                .foregroundColor(.white.opacity(0.7))
        }
        .padding()
        .background(Color.black.opacity(0.6))
        .cornerRadius(12)
    }
}

/// Status message display
struct GameStatusMessageView: View {
    let message: String
    
    var body: some View {
        Text(message)
            .font(.headline)
            .foregroundColor(.white)
            .padding()
            .background(Color.black.opacity(0.8))
            .cornerRadius(12)
            .shadow(radius: 10)
    }
}

/// Game menu sheet
struct GameMenuView: View {
    let onResume: () -> Void
    let onNewGame: () -> Void
    let onMainMenu: () -> Void
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Spacer()
                
                VStack(spacing: 16) {
                    Button("Continuă Jocul", action: onResume)
                        .buttonStyle(GameMenuButtonStyle())
                    
                    Button("Joc Nou", action: onNewGame)
                        .buttonStyle(GameMenuButtonStyle())
                    
                    Button("Meniu Principal", action: onMainMenu)
                        .buttonStyle(GameMenuButtonStyle())
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Meniu Joc")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

/// Button style for game menu
struct GameMenuButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(Color.blue)
            .foregroundColor(.white)
            .font(.headline)
            .cornerRadius(12)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Preview

struct GameBoardView_Previews: PreviewProvider {
    static var previews: some View {
        let gameState = GameState()
        gameState.players = [
            Player(name: "Player 1"),
            AIPlayer(name: "AI Player")
        ]
        gameState.setupNewGame()
        
        return GameBoardView(gameState: gameState)
            .previewDevice("iPhone 14 Pro")
            .preferredColorScheme(.dark)
    }
}