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
    @StateObject private var dragCoordinator = ShuffleCatsDragCoordinator()
    @StateObject private var characterAnimator = RomanianCharacterAnimator()
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
                // Top player area with character reactions
                HStack {
                    // Opponent hand
                    if gameViewModel.players.count > 1 {
                        OpponentHandView(
                            player: gameViewModel.players[1],
                            isCurrentPlayer: gameViewModel.currentPlayerIndex == 1
                        )
                        .rotationEffect(.degrees(180))
                    }
                    
                    Spacer()
                    
                    // Romanian character for opponent reactions
                    RomanianCharacterView(
                        animator: characterAnimator,
                        size: CGSize(width: 80, height: 100)
                    )
                    .scaleEffect(0.8)
                }
                
                Spacer()
                
                // Game table (center area) with enhanced Shuffle Cats-style drop zones
                ZStack {
                    GameTableView(
                        tableCards: gameViewModel.tableCards,
                        validMoves: gameViewModel.validMoves,
                        onCardTapped: playCard,
                        animatingCard: animatingCard
                    )
                    
                    // Enhanced drop zones with magnetic snapping
                    ForEach(dragCoordinator.dropZones) { zone in
                        EnhancedDropZoneView(
                            zone: zone,
                            coordinator: dragCoordinator
                        )
                        .transition(.scale.combined(with: .opacity))
                    }
                    
                    // Ghost card for Shuffle Cats-style drag preview
                    if dragCoordinator.showGhostCard,
                       let draggedCard = dragCoordinator.draggedCard {
                        GhostCardView(
                            card: draggedCard,
                            position: dragCoordinator.ghostCardPosition,
                            opacity: dragCoordinator.ghostCardOpacity,
                            isSnapping: dragCoordinator.magneticSnappingActive
                        )
                        .transition(.asymmetric(
                            insertion: .scale.combined(with: .opacity),
                            removal: .scale.combined(with: .opacity)
                        ))
                        .zIndex(1000) // Always on top
                    }
                }
                
                Spacer()
                
                // Bottom player area (human player) with enhanced Shuffle Cats-style interactions
                if let currentPlayer = gameViewModel.humanPlayer {
                    PlayerHandView(
                        player: currentPlayer,
                        selectedCard: selectedCard,
                        validMoves: gameViewModel.validMoves,
                        onCardSelected: { card in
                            selectedCard = card
                            updateDropZones(for: card)
                        },
                        onCardPlayed: playCard,
                        isCurrentPlayer: gameViewModel.isHumanPlayerTurn,
                        isInteractionEnabled: gameViewModel.canHumanPlayerMove,
                        onDragStateChanged: { isActive, position, isValid in
                            // Use enhanced drag coordinator for Shuffle Cats-style interactions
                            if isActive, let pos = position, let selected = selectedCard {
                                if !dragCoordinator.isDragActive {
                                    // Start drag with ghost card
                                    dragCoordinator.startDrag(card: selected, at: pos)
                                } else {
                                    // Update drag position with magnetic snapping
                                    dragCoordinator.updateDrag(position: pos)
                                }
                            } else if !isActive && dragCoordinator.isDragActive {
                                // End drag and check for successful drop
                                if let dropZone = dragCoordinator.endDrag(at: dragCoordinator.dragPosition) {
                                    // Successful drop in valid zone
                                    if dropZone.isValid {
                                        playCard(dragCoordinator.draggedCard ?? selectedCard!)
                                    }
                                }
                            }
                        }
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
            setupDropZones()
        }
    }
    
    /// Play a card with animation and character reactions
    private func playCard(_ card: Card) {
        guard gameViewModel.canPlayCard(card) else { 
            // Invalid move - trigger disappointed character reaction
            characterAnimator.triggerReaction(
                .badMove,
                context: .encouragement,
                intensity: .subtle
            )
            return 
        }
        
        selectedCard = nil
        animatingCard = card
        
        // Determine move quality for character reaction
        let moveQuality = evaluateMoveQuality(card)
        triggerMoveReaction(moveQuality, card: card)
        
        // Animate card to table
        withAnimation(.easeInOut(duration: 0.5)) {
            gameViewModel.playCard(card)
        }
        
        // Clear animation after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            animatingCard = nil
        }
    }
    
    /// Evaluate move quality for appropriate character reactions
    private func evaluateMoveQuality(_ card: Card) -> MoveQuality {
        // Check if this is a strategic seven play
        if card.value == 7 {
            return .excellent // Seven is always a strong move
        }
        
        // Check if this wins the trick
        if gameViewModel.validMoves.count == 1 && gameViewModel.validMoves.contains(card) {
            return .good // Only valid move available
        }
        
        // Check if this is a point card play
        if card.isPointCard {
            return .strategic // Playing point cards requires strategy
        }
        
        // Check if this is an 8 when table count % 3 == 0
        if card.value == 8 && gameViewModel.tableCards.count % 3 == 0 {
            return .excellent // Perfect timing for 8
        }
        
        return .average
    }
    
    /// Trigger appropriate character reaction based on move quality
    private func triggerMoveReaction(_ quality: MoveQuality, card: Card) {
        let context: GameContext = determineGameContext()
        
        switch quality {
        case .excellent:
            characterAnimator.triggerReaction(
                .goodMove,
                context: context,
                intensity: .dramatic
            )
        case .good:
            characterAnimator.triggerReaction(
                .goodMove,
                context: context,
                intensity: .normal
            )
        case .strategic:
            characterAnimator.triggerReaction(
                .wisdom,
                context: .strategic_thinking,
                intensity: .normal
            )
        case .average:
            characterAnimator.triggerReaction(
                .encouragement,
                context: context,
                intensity: .subtle
            )
        case .poor:
            characterAnimator.triggerReaction(
                .badMove,
                context: .encouragement,
                intensity: .subtle
            )
        }
    }
    
    /// Determine current game context for character selection
    private func determineGameContext() -> GameContext {
        // Check if this is early in the game (learning phase)
        if gameViewModel.gameState.trickNumber <= 2 {
            return .learning
        }
        
        // Check if this is end game (expert play)
        if gameViewModel.tableCards.count >= 6 {
            return .expert_play
        }
        
        // Check if player is winning (celebration context)
        if let humanPlayer = gameViewModel.humanPlayer,
           humanPlayer.score > (gameViewModel.players.first { $0.id != humanPlayer.id }?.score ?? 0) {
            return .celebration
        }
        
        // Default to strategic thinking
        return .strategic_thinking
    }
    
    /// Setup drop zones for Shuffle Cats-style drag interactions
    private func setupDropZones() {
        let screenBounds = UIScreen.main.bounds
        let centerX = screenBounds.width / 2
        let centerY = screenBounds.height / 2
        
        // Main play area drop zone (center of screen)
        let playAreaZone = DropZoneInfo(
            center: CGPoint(x: centerX, y: centerY - 50),
            size: CGSize(width: 200, height: 120),
            type: .playArea,
            isValid: true,
            isActive: true
        )
        
        // Special move zone for 7s (wild cards)
        let specialMoveZone = DropZoneInfo(
            center: CGPoint(x: centerX + 120, y: centerY - 50),
            size: CGSize(width: 140, height: 100),
            type: .specialMove,
            isValid: false, // Will be determined dynamically based on selected card
            isActive: false // Will be activated when dragging a 7
        )
        
        dragCoordinator.setDropZones([playAreaZone, specialMoveZone])
    }
    
    /// Update drop zones based on current game state and selected card
    private func updateDropZones(for card: Card?) {
        guard var zones = dragCoordinator.dropZones as [DropZoneInfo]? else { return }
        
        // Update main play area validity
        if let selectedCard = card {
            let canPlay = gameViewModel.canPlayCard(selectedCard)
            zones[0] = DropZoneInfo(
                center: zones[0].center,
                size: zones[0].size,
                type: .playArea,
                isValid: canPlay,
                isActive: true
            )
            
            // Update special move zone for wild cards (7s)
            if selectedCard.value == 7 && zones.count > 1 {
                zones[1] = DropZoneInfo(
                    center: zones[1].center,
                    size: zones[1].size,
                    type: .specialMove,
                    isValid: canPlay,
                    isActive: true
                )
            }
        }
        
        dragCoordinator.setDropZones(zones)
    }
}

/// Move quality assessment for character reactions
enum MoveQuality {
    case excellent  // Seven plays, perfect timing moves
    case good       // Valid strategic moves
    case strategic  // Point card plays, thoughtful moves
    case average    // Standard legal moves
    case poor       // Suboptimal but legal moves
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