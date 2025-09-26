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
    @EnvironmentObject private var navigationManager: SimpleNavigationManager
    
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

                    // Game Action Controls - Professional Romanian interface
                    gameActionControlsArea
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
                            .frame(width: 55, height: 77) // 55 * 1.4 = 77 (traditional card proportions)
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
            .frame(width: 380, height: 150) // Adjusted for proper compact card height (126) + fanning space
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
            
            // Dynamic instructions based on game state
            if selectedCard != nil {
                Text("Cartea selectată • Folosește butoanele de jos pentru a juca")
                    .font(.caption2)
                    .foregroundColor(RomanianColors.goldAccent.opacity(0.9))
                    .multilineTextAlignment(.center)
            } else {
                Text("Selectează o carte din mâna ta")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
            }
            
            // Player cards with proper fanning and tap-to-select-tap-to-play
            if let humanPlayer = gameViewModel.humanPlayer {
                FannedCardHandView(
                    cards: humanPlayer.hand,
                    selectedCard: selectedCard,
                    validMoves: gameViewModel.validMoves,
                    onCardTapped: { card in
                        if gameViewModel.validMoves.contains(card) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                // Tap to select card (use action buttons to play)
                                selectedCard = card
                            }
                        }
                    }
                )
                .frame(height: 180) // Increased to accommodate proper card height (154) + fanning space
            }
        }
    }
    
    // MARK: - Game Action Controls

    private var gameActionControlsArea: some View {
        VStack(spacing: 12) {
            // Action buttons area
            if gameViewModel.isHumanPlayerTurn {
                HStack(spacing: 16) {
                    // Play Selected Card button
                    Button(action: {
                        if let card = selectedCard {
                            playCard(card)
                        }
                    }) {
                        HStack(spacing: 10) {
                            Image(systemName: selectedCard != nil ? "hand.draw" : "hand.raised.slash")
                            Text(selectedCard != nil ? "Joacă Cartea" : "Selectează Cartea")
                                .font(.headline.weight(.semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            LinearGradient(
                                colors: selectedCard != nil ? [
                                    RomanianColors.countrysideGreen,
                                    RomanianColors.countrysideGreen.opacity(0.8)
                                ] : [
                                    Color.gray.opacity(0.6),
                                    Color.gray.opacity(0.4)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .shadow(
                            color: selectedCard != nil ? RomanianColors.countrysideGreen.opacity(0.4) : Color.gray.opacity(0.2),
                            radius: selectedCard != nil ? 6 : 3,
                            x: 0,
                            y: 3
                        )
                    }
                    .disabled(selectedCard == nil)

                    // Pass Turn button (always available during player's turn)
                    if shouldShowPassButton {
                        Button(action: {
                            selectedCard = nil // Clear selection
                            gameViewModel.gameState.skipCurrentPlayer()
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "arrow.turn.down.right")
                                Text("Treci")
                                    .font(.headline.weight(.semibold))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
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
                    }
                }
                .padding(.horizontal, 20)

                // Selected card indicator with Romanian styling
                if let card = selectedCard {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(RomanianColors.goldAccent)
                        Text("Cartea selectată: \(card.displayValue)\(card.suit.symbol)")
                            .font(.caption.weight(.medium))
                            .foregroundColor(RomanianColors.goldAccent)
                        Spacer()
                        Button("Anulează") {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                selectedCard = nil
                            }
                        }
                        .font(.caption.weight(.medium))
                        .foregroundColor(RomanianColors.primaryRed.opacity(0.8))
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.black.opacity(0.4))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(RomanianColors.goldAccent.opacity(0.3), lineWidth: 1)
                            )
                    )
                    .padding(.horizontal, 20)
                }
            } else {
                // Opponent's turn indicator
                HStack(spacing: 8) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: RomanianColors.goldAccent))
                        .scaleEffect(0.8)
                    Text("Rândul adversarului...")
                        .font(.headline.weight(.medium))
                        .foregroundColor(.white.opacity(0.8))
                }
                .padding(.vertical, 16)
            }
        }
        .padding(.bottom, 20)
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
        case .finished:
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
            // Professional playing card design
            ZStack {
                // Card background with premium look
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white,
                                Color.white.opacity(0.98),
                                Color.white.opacity(0.95),
                                Color.white.opacity(0.97)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                    .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)

                // Card content with proper playing card layout
                VStack(spacing: 2) {
                    HStack {
                        VStack(spacing: 1) {
                            Text(card.displayValue)
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .foregroundColor(card.suit.color)
                            Text(card.suit.symbol)
                                .font(.system(size: 10))
                                .foregroundColor(card.suit.color)
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 4)
                    .padding(.top, 4)

                    Spacer()

                    // Center suit symbol
                    Text(card.suit.symbol)
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(card.suit.color.opacity(0.8))

                    Spacer()

                    HStack {
                        Spacer()
                        VStack(spacing: 1) {
                            Text(card.suit.symbol)
                                .font(.system(size: 10))
                                .foregroundColor(card.suit.color)
                                .rotationEffect(.degrees(180))
                            Text(card.displayValue)
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .foregroundColor(card.suit.color)
                                .rotationEffect(.degrees(180))
                        }
                    }
                    .padding(.horizontal, 4)
                    .padding(.bottom, 4)
                }

                // Professional border
                RoundedRectangle(cornerRadius: 8)
                    .stroke(
                        isSelected
                            ? LinearGradient(colors: [RomanianColors.goldAccent, RomanianColors.primaryYellow], startPoint: .topLeading, endPoint: .bottomTrailing)
                            : LinearGradient(colors: [Color.gray.opacity(0.3), Color.gray.opacity(0.2)], startPoint: .topLeading, endPoint: .bottomTrailing),
                        lineWidth: isSelected ? 2.5 : 1
                    )
            }
            .frame(width: 75, height: 105) // 75 * 1.4 = 105 (proper traditional card aspect ratio)
            .scaleEffect(isSelected ? 1.05 : 1.0)
            .shadow(
                color: isSelected ? RomanianColors.goldAccent.opacity(0.4) : Color.black.opacity(0.15),
                radius: isSelected ? 6 : 3,
                x: 0,
                y: isSelected ? 3 : 2
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
    private let baseCardSpacing: CGFloat = 48.0 // Desired spacing between cards before fitting to width
    private let minimumSpacing: CGFloat = 26.0
    
    var body: some View {
        GeometryReader { geometry in
            let cardCount = cards.count
            let spacing = spacingForCards(
                count: cardCount,
                availableWidth: geometry.size.width,
                cardWidth: CardSize.compact.width,
                baseSpacing: baseCardSpacing,
                minimumSpacing: minimumSpacing
            )
            let centerIndex = Double(cardCount - 1) / 2.0
            
            ZStack(alignment: .bottom) {
                ForEach(Array(cards.enumerated()), id: \.element.id) { index, card in
                    let isPlayable = validMoves.contains(card)
                    let normalizedPosition = cardCount > 1 ?
                        Double(index) / Double(cardCount - 1) : 0.5
                    let fanAngle = (normalizedPosition - 0.5) * 2 * maxFanAngle
                    let verticalOffset = abs(normalizedPosition - 0.5) * 12.0
                    let horizontalOffset = CGFloat(Double(index) - centerIndex) * spacing
                    
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
                    .offset(x: horizontalOffset, y: verticalOffset)
                    .zIndex(Double(index))
                }
            }
            .frame(maxWidth: .infinity, alignment: .bottom) // Removed maxHeight to prevent card stretching
        }
    }
}

// MARK: - Fanned Card Hand View

struct FannedCardHandView: View {
    let cards: [Card]
    let selectedCard: Card?
    let validMoves: [Card]
    let onCardTapped: (Card) -> Void
    
    private let maxFanAngle: Double = 15.0 // Maximum rotation for edge cards
    private let baseCardSpacing: CGFloat = 64.0 // Desired spacing before fitting to width
    private let minimumSpacing: CGFloat = 32.0
    
    var body: some View {
        GeometryReader { geometry in
            let cardCount = cards.count
            let spacing = spacingForCards(
                count: cardCount,
                availableWidth: geometry.size.width,
                cardWidth: CardSize.normal.width,
                baseSpacing: baseCardSpacing,
                minimumSpacing: minimumSpacing
            )
            let centerIndex = Double(cardCount - 1) / 2.0
            
            ZStack(alignment: .bottom) {
                ForEach(Array(cards.enumerated()), id: \.element.id) { index, card in
                    let isSelected = selectedCard?.id == card.id
                    let isPlayable = validMoves.contains(card)
                    let normalizedPosition = cardCount > 1 ?
                        Double(index) / Double(cardCount - 1) : 0.5
                    let fanAngle = (normalizedPosition - 0.5) * 2 * maxFanAngle
                    let verticalOffset = abs(normalizedPosition - 0.5) * 10.0
                    let horizontalOffset = CGFloat(Double(index) - centerIndex) * spacing
                    let liftOffset: CGFloat = isSelected ? -28 : verticalOffset
                    
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
                    .offset(x: horizontalOffset, y: liftOffset)
                    .scaleEffect(isSelected ? 1.1 : 1.0)
                    .zIndex(isSelected ? 100 : Double(index))
                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isSelected)
                }
            }
            .frame(maxWidth: .infinity, alignment: .bottom) // Removed maxHeight to prevent card stretching
        }
    }
}

private extension FannedTableCardsView {
    func spacingForCards(count: Int, availableWidth: CGFloat, cardWidth: CGFloat, baseSpacing: CGFloat, minimumSpacing: CGFloat) -> CGFloat {
        guard count > 1 else { return 0 }
        let availableSpan = max(availableWidth - cardWidth, 0)
        let fittedSpacing = availableSpan / CGFloat(count - 1)
        return max(minimumSpacing, min(baseSpacing, fittedSpacing))
    }
}

private extension FannedCardHandView {
    func spacingForCards(count: Int, availableWidth: CGFloat, cardWidth: CGFloat, baseSpacing: CGFloat, minimumSpacing: CGFloat) -> CGFloat {
        guard count > 1 else { return 0 }
        let availableSpan = max(availableWidth - cardWidth, 0)
        let fittedSpacing = availableSpan / CGFloat(count - 1)
        return max(minimumSpacing, min(baseSpacing, fittedSpacing))
    }
}
