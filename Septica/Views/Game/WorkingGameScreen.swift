//
//  WorkingGameScreen.swift
//  Septica
//
//  Simplified working game screen focusing on core functionality
//  Romanian cultural features integrated gradually for stability
//

import SwiftUI

/// Simplified working game screen with core functionality and Romanian styling
struct WorkingGameScreen: View {
    @StateObject private var gameViewModel: GameViewModel
    @State private var selectedCard: Card?
    @State private var showingGameMenu = false
    
    // Romanian Dialogue System Integration
    @StateObject private var dialogueSystem = RomanianDialogueSystem()
    
    // Navigation manager for proper menu navigation
    @EnvironmentObject private var navigationManager: NavigationManager
    
    init(gameState: GameState) {
        self._gameViewModel = StateObject(wrappedValue: GameViewModel(gameState: gameState))
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Romanian cultural background
                romanianBackground
                
                VStack(spacing: 16) {
                    // Top status bar
                    gameStatusBar
                    
                    Spacer()
                    
                    // Opponent area with Romanian styling
                    opponentArea
                    
                    Spacer()
                    
                    // Game table with Romanian ornate frame
                    gameTableArea
                    
                    Spacer()
                    
                    // Player hand with Romanian styling
                    playerHandArea
                    
                    Spacer(minLength: 20)
                }
                .padding()
                
                // Romanian dialogue overlay
                if dialogueSystem.isShowingDialogue,
                   let dialogue = dialogueSystem.currentDialogue {
                    VStack {
                        HStack {
                            Spacer()
                            RomanianDialogueBubbleView(
                                dialogue: dialogue,
                                character: gameViewModel.currentOpponentAvatar
                            )
                            .frame(maxWidth: 280)
                        }
                        Spacer()
                    }
                    .padding()
                    .zIndex(100)
                }
                
                // Game menu overlay
                if showingGameMenu {
                    gameMenuOverlay
                }
            }
        }
        .navigationBarHidden(true)
        .preferredColorScheme(.dark)
        .onAppear {
            setupGame()
        }
        .onChange(of: gameViewModel.gamePhase) { _, newPhase in
            handleGamePhaseChange(newPhase)
        }
    }
    
    // MARK: - Background
    
    private var romanianBackground: some View {
        ZStack {
            // Romanian cultural gradient background
            LinearGradient(
                colors: [
                    Color(red: 0.05, green: 0.15, blue: 0.05),
                    RomanianColors.tableGreen.opacity(0.3),
                    Color(red: 0.08, green: 0.20, blue: 0.08)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // Subtle Romanian pattern overlay
            RadialGradient(
                colors: [
                    RomanianColors.goldAccent.opacity(0.05),
                    Color.clear,
                    RomanianColors.primaryYellow.opacity(0.03)
                ],
                center: .center,
                startRadius: 100,
                endRadius: 400
            )
        }
    }
    
    // MARK: - Game Status Bar
    
    private var gameStatusBar: some View {
        HStack {
            // Game info
            VStack(alignment: .leading, spacing: 4) {
                Text("Rândul lui \(gameViewModel.currentPlayer?.name ?? "Jucător")")
                    .font(.headline.weight(.semibold))
                    .foregroundColor(.white)
                
                Text("Rundă \(gameViewModel.gameState.roundNumber) • Mână \(gameViewModel.gameState.trickNumber)")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
            }
            
            Spacer()
            
            // Scores
            HStack(spacing: 16) {
                ForEach(gameViewModel.playerScores.sorted(by: { $0.key < $1.key }), id: \.key) { playerName, score in
                    VStack(spacing: 2) {
                        Text(playerName)
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.7))
                        Text("\(score)")
                            .font(.headline.weight(.bold))
                            .foregroundColor(RomanianColors.goldAccent)
                    }
                }
            }
            
            Spacer()
            
            // Menu button
            Button(action: { showingGameMenu.toggle() }) {
                Image(systemName: "line.horizontal.3")
                    .font(.title2)
                    .foregroundColor(.white)
                    .padding(8)
                    .background(Color.black.opacity(0.6))
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }
    
    // MARK: - Opponent Area
    
    private var opponentArea: some View {
        VStack(spacing: 8) {
            // Opponent title with Romanian styling
            Text("Adversar")
                .font(.caption.weight(.semibold))
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            RomanianColors.primaryYellow.opacity(0.8),
                            RomanianColors.goldAccent.opacity(0.6)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
            
            // Opponent cards (face down)
            if gameViewModel.players.count > 1 {
                let opponent = gameViewModel.players[1]
                HStack(spacing: -8) {
                    ForEach(0..<opponent.hand.count, id: \.self) { index in
                        RoundedRectangle(cornerRadius: 8)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        RomanianColors.cardBack,
                                        RomanianColors.primaryBlue.opacity(0.8)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 45, height: 63)
                            .overlay(
                                Text("♦")
                                    .font(.title2)
                                    .foregroundColor(RomanianColors.goldAccent.opacity(0.3))
                            )
                            .shadow(color: RomanianColors.primaryBlue.opacity(0.3), radius: 4, x: 0, y: 2)
                            .offset(y: CGFloat(index % 2) * -4)
                            .zIndex(Double(index))
                    }
                }
            }
        }
    }
    
    // MARK: - Game Table Area
    
    private var gameTableArea: some View {
        VStack(spacing: 12) {
            // Romanian ornate frame title
            HStack {
                RomanianOrnatePatternSystem.RomanianCrossPattern(
                    size: 16,
                    color: RomanianColors.goldAccent
                )
                
                Spacer()
                
                Text("Masa de Joc")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                RomanianColors.goldAccent,
                                RomanianColors.primaryYellow
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .shadow(color: .black.opacity(0.5), radius: 2, x: 1, y: 1)
                
                Spacer()
                
                RomanianOrnatePatternSystem.RomanianCrossPattern(
                    size: 16,
                    color: RomanianColors.goldAccent
                )
            }
            
            // Game table content
            ZStack {
                // Romanian ornate table surface
                OrnateRomanianTableSurface(size: CGSize(width: 350, height: 180))
                
                if !gameViewModel.tableCards.isEmpty {
                    // Fanned table card display
                    FannedTableCardsView(
                        cards: gameViewModel.tableCards,
                        validMoves: gameViewModel.validMoves,
                        onCardTapped: { card in
                            if gameViewModel.validMoves.contains(card) {
                                playCard(card)
                            }
                        }
                    )
                } else {
                    // Empty table placeholder
                    VStack(spacing: 8) {
                        Text("♠♥♣♦")
                            .font(.title)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [
                                        RomanianColors.goldAccent,
                                        RomanianColors.primaryYellow,
                                        RomanianColors.goldAccent
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .shadow(color: RomanianColors.primaryBlue.opacity(0.4), radius: 3, x: 1, y: 1)
                        
                        Text("Masa de Joc Organizată")
                            .font(.headline.weight(.bold))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [
                                        RomanianColors.goldAccent,
                                        RomanianColors.primaryYellow.opacity(0.9)
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .shadow(color: Color.black.opacity(0.6), radius: 2, x: 1, y: 1)
                    }
                }
            }
            .frame(width: 380, height: 200)
        }
    }
    
    // MARK: - Player Hand Area
    
    private var playerHandArea: some View {
        VStack(spacing: 8) {
            // Player title with Romanian styling
            Text("Mâna Ta")
                .font(.caption.weight(.semibold))
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            RomanianColors.goldAccent,
                            RomanianColors.primaryYellow.opacity(0.8)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
            
            // Instructions
            Text("Apasă pentru a selecta • Apasă din nou pentru a juca")
                .font(.caption2)
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
            
            // Player cards with proper fanning and tap-to-select-tap-to-play
            if let humanPlayer = gameViewModel.humanPlayer {
                FannedCardHandView(
                    cards: humanPlayer.hand,
                    selectedCard: selectedCard,
                    validMoves: gameViewModel.validMoves,
                    onCardTapped: { card in
                        if gameViewModel.validMoves.contains(card) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                if selectedCard?.id == card.id {
                                    // Tap again to play - classic card game interaction
                                    playCard(card)
                                } else {
                                    // First tap to select
                                    selectedCard = card
                                }
                            }
                        }
                    }
                )
                .frame(height: 140)
            }
            
            // Pass button for skipping turn - only when no playable moves or specific game conditions
            if shouldShowPassButton {
                HStack {
                    Spacer()
                    
                    Button(action: {
                        // Handle pass action - skip turn in Romanian Septica
                        gameViewModel.gameState.skipCurrentPlayer()
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "hand.raised.fill")
                            Text("Treci")
                                .font(.headline.weight(.semibold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(
                            LinearGradient(
                                colors: [
                                    RomanianColors.primaryRed.opacity(0.8),
                                    RomanianColors.primaryRed
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .shadow(color: RomanianColors.primaryRed.opacity(0.4), radius: 6, x: 0, y: 3)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal)
            }
        }
    }
    
    // MARK: - Game Menu Overlay
    
    private var gameMenuOverlay: some View {
        ZStack {
            // Background overlay
            Color.black.opacity(0.7)
                .ignoresSafeArea()
                .onTapGesture {
                    showingGameMenu = false
                }
            
            // Menu content
            VStack(spacing: 20) {
                Text("Meniu Joc")
                    .font(.largeTitle.weight(.bold))
                    .foregroundColor(.white)
                
                VStack(spacing: 16) {
                    Button("Continuă Jocul") {
                        showingGameMenu = false
                    }
                    .buttonStyle(RomanianMenuButtonStyle())
                    
                    Button("Joc Nou") {
                        showingGameMenu = false
                        gameViewModel.startNewGame()
                    }
                    .buttonStyle(RomanianMenuButtonStyle())
                    
                    Button("Meniu Principal") {
                        showingGameMenu = false
                        // Navigate back to main menu
                        navigationManager.popToRoot()
                    }
                    .buttonStyle(RomanianMenuButtonStyle())
                }
            }
            .padding(40)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.black.opacity(0.8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(RomanianColors.goldAccent.opacity(0.6), lineWidth: 2)
                    )
            )
        }
        .transition(.scale.combined(with: .opacity))
    }
    
    // MARK: - Helper Methods
    
    private func setupGame() {
        gameViewModel.startGame()
        
        // Initialize Romanian dialogue system with welcome message
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            dialogueSystem.triggerDialogue(for: .gameStart, character: gameViewModel.currentOpponentAvatar)
        }
    }
    
    private func handleGamePhaseChange(_ newPhase: GameViewModel.GamePhase) {
        switch newPhase {
        case .gameOver:
            dialogueSystem.triggerDialogue(for: .victory, character: gameViewModel.currentOpponentAvatar)
        default:
            break
        }
    }
    
    private func playCard(_ card: Card) {
        guard gameViewModel.canPlayCard(card) else { return }
        
        selectedCard = nil
        
        // Trigger Romanian dialogue for good moves
        if card.value == 7 {
            dialogueSystem.triggerDialogue(for: .sevenPlayed, character: gameViewModel.currentOpponentAvatar)
        } else if card.isPointCard {
            dialogueSystem.triggerDialogue(for: .strategicMove, character: gameViewModel.currentOpponentAvatar)
        } else {
            dialogueSystem.triggerDialogue(for: .goodPlay, character: gameViewModel.currentOpponentAvatar)
        }
        
        // Play the card
        gameViewModel.playCard(card)
    }
    
    // MARK: - Card Organization
    
    private var organizedCardColumns: [[Card]] {
        guard !gameViewModel.tableCards.isEmpty else { return [] }
        
        // Group cards by suit for better organization
        let suitGroups = Dictionary(grouping: gameViewModel.tableCards) { $0.suit }
        var columns: [[Card]] = []
        let suits: [Suit] = [.hearts, .diamonds, .clubs, .spades]
        
        for suit in suits {
            if let cards = suitGroups[suit], !cards.isEmpty {
                let sortedCards = cards.sorted { $0.value < $1.value }
                columns.append(sortedCards)
                if columns.count >= 4 { break }
            }
        }
        
        return columns
    }
    
    // MARK: - Pass Button Logic
    
    /// Determines when the Pass button should be visible in Romanian Septica
    private var shouldShowPassButton: Bool {
        // Show pass button when:
        // 1. It's the human player's turn
        // 2. No valid moves available, OR
        // 3. Specific Romanian Septica rule conditions (e.g., when objecting to cuts)
        
        guard gameViewModel.isHumanPlayerTurn else { return false }
        
        // If no valid moves, pass is the only option
        if gameViewModel.validMoves.isEmpty {
            return true
        }
        
        // In Romanian Septica, passing can be strategic when:
        // - There are table cards but player chooses not to take them
        // - Player wants to let opponent collect low-value cards
        // For now, show it when there are table cards (cards have been played)
        return !gameViewModel.tableCards.isEmpty
    }
}

// MARK: - Simple Card View Component

struct SimpleCardView: View {
    let card: Card
    let isSelected: Bool
    let isPlayable: Bool
    let onTap: () -> Void
    let onLongPress: () -> Void
    
    var body: some View {
        VStack(spacing: 4) {
            // Simplified card view for better interaction
            RoundedRectangle(cornerRadius: 8)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white,
                            Color.white.opacity(0.95)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 60, height: 84)
                .overlay(
                    VStack(spacing: 2) {
                        Text(card.displayValue)
                            .font(.headline.weight(.bold))
                            .foregroundColor(card.suit.color)
                        
                        Text(card.suit.symbol)
                            .font(.title2)
                            .foregroundColor(card.suit.color)
                    }
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(
                            isSelected ? RomanianColors.goldAccent : Color.gray.opacity(0.3),
                            lineWidth: isSelected ? 3 : 1
                        )
                )
                .scaleEffect(isSelected ? 1.1 : 1.0)
                .shadow(
                    color: isSelected ? RomanianColors.goldAccent.opacity(0.5) : Color.black.opacity(0.2),
                    radius: isSelected ? 8 : 4,
                    x: 0,
                    y: isSelected ? 4 : 2
                )
                .onTapGesture {
                    onTap()
                }
                .onLongPressGesture(minimumDuration: 0.1) {
                    onLongPress()
                }
            
            // Card playability indicator
            Circle()
                .fill(isPlayable ? RomanianColors.countrysideGreen : Color.gray.opacity(0.5))
                .frame(width: 8, height: 8)
        }
    }
}

// MARK: - Romanian Menu Button Style

struct RomanianMenuButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(
                LinearGradient(
                    colors: [
                        RomanianColors.primaryBlue.opacity(0.8),
                        RomanianColors.primaryBlue
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .foregroundColor(.white)
            .font(.headline.weight(.semibold))
            .cornerRadius(12)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
            .shadow(color: RomanianColors.primaryBlue.opacity(0.4), radius: 6, x: 0, y: 3)
    }
}

// MARK: - Fanned Table Cards View

struct FannedTableCardsView: View {
    let cards: [Card]
    let validMoves: [Card]
    let onCardTapped: (Card) -> Void
    
    private let maxFanAngle: Double = 25.0 // Wider fan for table cards
    private let cardSpacing: CGFloat = -60.0 // More overlap for table
    
    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                ForEach(Array(cards.enumerated()), id: \.element.id) { index, card in
                    let cardCount = cards.count
                    let isPlayable = validMoves.contains(card)
                    
                    // Calculate fan rotation (center cards straight, edge cards angled)
                    let normalizedPosition = cardCount > 1 ? 
                        Double(index) / Double(cardCount - 1) : 0.5 // 0.0 to 1.0
                    let fanAngle = (normalizedPosition - 0.5) * 2 * maxFanAngle // -25° to +25°
                    
                    // Calculate slight vertical offset for natural spread
                    let verticalOffset = abs(normalizedPosition - 0.5) * 12.0
                    
                    CardView(
                        card: card,
                        isSelected: false,
                        isPlayable: isPlayable,
                        isAnimating: false,
                        cardSize: .compact,
                        onTap: { onCardTapped(card) },
                        onDragChanged: nil,
                        onDragEnded: nil
                    )
                    .rotationEffect(.degrees(fanAngle))
                    .offset(
                        x: CGFloat(index) * cardSpacing,
                        y: verticalOffset
                    )
                    .zIndex(Double(index))
                }
            }
            .frame(maxWidth: .infinity)
            .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
        }
        .clipped()
    }
}

// MARK: - Fanned Card Hand View

struct FannedCardHandView: View {
    let cards: [Card]
    let selectedCard: Card?
    let validMoves: [Card]
    let onCardTapped: (Card) -> Void
    
    private let maxFanAngle: Double = 15.0 // Maximum rotation for edge cards
    private let cardSpacing: CGFloat = -70.0 // Negative spacing for overlap with wider cards
    
    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                ForEach(Array(cards.enumerated()), id: \.element.id) { index, card in
                    let cardCount = cards.count
                    let isSelected = selectedCard?.id == card.id
                    let isPlayable = validMoves.contains(card)
                    
                    // Calculate fan rotation (center cards straight, edge cards angled)
                    let normalizedPosition = cardCount > 1 ? 
                        Double(index) / Double(cardCount - 1) : 0.5 // 0.0 to 1.0
                    let fanAngle = (normalizedPosition - 0.5) * 2 * maxFanAngle // -15° to +15°
                    
                    // Calculate vertical offset for natural hand curve
                    let verticalOffset = abs(normalizedPosition - 0.5) * 8.0
                    
                    CardView(
                        card: card,
                        isSelected: isSelected,
                        isPlayable: isPlayable,
                        isAnimating: false,
                        cardSize: .normal,
                        onTap: { onCardTapped(card) },
                        onDragChanged: nil,
                        onDragEnded: nil
                    )
                    .rotationEffect(.degrees(fanAngle))
                    .offset(
                        x: CGFloat(index) * cardSpacing,
                        y: isSelected ? -20 : verticalOffset
                    )
                    .scaleEffect(isSelected ? 1.1 : 1.0)
                    .zIndex(isSelected ? 100 : Double(index))
                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isSelected)
                }
            }
            .frame(maxWidth: .infinity)
            .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
        }
        .clipped()
    }
}

// MARK: - Preview

struct WorkingGameScreen_Previews: PreviewProvider {
    static var previews: some View {
        let gameState = GameState()
        gameState.players = [
            Player(name: "Jucător"),
            AIPlayer(name: "Computer")
        ]
        gameState.setupNewGame()
        
        return WorkingGameScreen(gameState: gameState)
            .previewDevice("iPhone 14 Pro")
            .preferredColorScheme(.dark)
    }
}