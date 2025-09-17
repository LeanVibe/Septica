//
//  ShuffleCatsInspiredGameScreen.swift
//  Septica
//
//  Enhanced game screen inspired by Shuffle Cats with Romanian cultural authenticity
//  Features player avatars, Romanian flags, progress bars, and elegant card fanning
//

import SwiftUI

/// Shuffle Cats-inspired game screen with Romanian cultural elements
struct ShuffleCatsInspiredGameScreen: View {
    @StateObject private var gameViewModel: GameViewModel
    @State private var selectedCard: Card?
    @State private var showingGameMenu = false
    
    // Romanian Dialogue System Integration
    @StateObject private var dialogueSystem = RomanianDialogueSystem()
    
    // Navigation manager for proper menu navigation
    @EnvironmentObject private var navigationManager: NavigationManager
    
    // Animation states
    @State private var backgroundPulse = false
    @State private var cardAnimationOffset: CGFloat = 0
    
    init(gameState: GameState) {
        self._gameViewModel = StateObject(wrappedValue: GameViewModel(gameState: gameState))
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Premium Romanian background
                romanianBackground
                
                HStack(spacing: 0) {
                    // Left progress bar
                    leftProgressBar
                        .frame(width: 40)
                    
                    // Main game area
                    VStack(spacing: 0) {
                        // Top opponent area with avatar
                        opponentAvatarArea
                            .frame(height: geometry.size.height * 0.20)
                        
                        // Game table area
                        gameTableArea
                            .frame(height: geometry.size.height * 0.50)
                        
                        // Player area with avatar and fanned cards
                        playerAvatarArea
                            .frame(height: geometry.size.height * 0.30)
                    }
                    
                    // Right progress bar
                    rightProgressBar
                        .frame(width: 40)
                }
                
                // Game status and menu (simplified top bar)
                gameStatusAndMenu
                
                // Romanian dialogue overlay
                if dialogueSystem.isShowingDialogue,
                   let dialogue = dialogueSystem.currentDialogue {
                    dialogueOverlay(dialogue)
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
            // Shuffle Cats-inspired gradient background
            LinearGradient(
                colors: [
                    Color(red: 0.02, green: 0.1, blue: 0.15),
                    RomanianColors.tableGreen.opacity(0.4),
                    Color(red: 0.05, green: 0.15, blue: 0.20)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // Romanian cultural pattern overlay
            RadialGradient(
                colors: [
                    RomanianColors.goldAccent.opacity(0.08),
                    Color.clear,
                    RomanianColors.primaryYellow.opacity(0.05)
                ],
                center: .center,
                startRadius: 100,
                endRadius: 500
            )
            .scaleEffect(backgroundPulse ? 1.05 : 1.0)
            .animation(.easeInOut(duration: 3).repeatForever(autoreverses: true), value: backgroundPulse)
            .onAppear { backgroundPulse = true }
        }
    }
    
    // MARK: - Progress Bars
    
    private var leftProgressBar: some View {
        VStack {
            // Opponent cards remaining
            RomanianProgressBar(
                current: opponentCardsRemaining,
                total: totalCardsDealt,
                color: RomanianColors.primaryRed,
                direction: .vertical,
                label: "ADV"
            )
        }
        .padding(.vertical)
    }
    
    private var rightProgressBar: some View {
        VStack {
            // Player cards remaining  
            RomanianProgressBar(
                current: playerCardsRemaining,
                total: totalCardsDealt,
                color: RomanianColors.primaryBlue,
                direction: .vertical,
                label: "TU"
            )
        }
        .padding(.vertical)
    }
    
    // MARK: - Game Status and Menu
    
    private var gameStatusAndMenu: some View {
        VStack {
            HStack {
                Spacer()
                
                // Game status indicator (centered)
                VStack(spacing: 4) {
                    Text("Rundă \(gameViewModel.gameState.roundNumber)")
                        .font(.caption.weight(.bold))
                        .foregroundColor(RomanianColors.goldAccent)
                    
                    Text("Mână \(gameViewModel.gameState.trickNumber)")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.8))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.black.opacity(0.6))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(RomanianColors.goldAccent.opacity(0.5), lineWidth: 1)
                        )
                )
                
                Spacer()
                
                // Menu button with Romanian styling
                Button(action: { showingGameMenu.toggle() }) {
                    Image(systemName: "line.horizontal.3")
                        .font(.title3)
                        .foregroundColor(RomanianColors.goldAccent)
                        .frame(width: 32, height: 32)
                        .background(
                            Circle()
                                .fill(Color.black.opacity(0.6))
                                .overlay(
                                    Circle()
                                        .stroke(RomanianColors.goldAccent.opacity(0.5), lineWidth: 1)
                                )
                        )
                }
            }
            .padding(.horizontal)
            .padding(.top, 8)
            
            Spacer()
        }
    }
    
    // MARK: - Opponent Avatar Area
    
    private var opponentAvatarArea: some View {
        VStack(spacing: 12) {
            // Opponent avatar with flag (Shuffle Cats style)
            HStack(spacing: 12) {
                RomanianFlagView(size: .small)
                    .shadow(color: .black.opacity(0.3), radius: 3, x: 0, y: 2)
                
                RomanianCharacterAvatarView(
                    character: gameViewModel.currentOpponentAvatar,
                    size: .medium,
                    showBorder: true,
                    glowColor: RomanianColors.primaryRed
                )
                .scaleEffect(dialogueSystem.isShowingDialogue ? 1.1 : 1.0)
                .animation(.easeInOut(duration: 0.3), value: dialogueSystem.isShowingDialogue)
                
                RomanianFlagView(size: .small)
                    .shadow(color: .black.opacity(0.3), radius: 3, x: 0, y: 2)
            }
            
            // Opponent name and score
            VStack(spacing: 4) {
                Text(gameViewModel.players.count > 1 ? gameViewModel.players[1].name : "Computer")
                    .font(.headline.weight(.bold))
                    .foregroundColor(.white)
                
                Text("\(gameViewModel.playerScores.values.first(where: { _ in true }) ?? 0) puncte")
                    .font(.caption)
                    .foregroundColor(RomanianColors.goldAccent)
            }
            
            // Opponent cards (face down, Shuffle Cats style)
            if gameViewModel.players.count > 1 {
                let opponent = gameViewModel.players[1]
                OpponentCardHandView(cardCount: opponent.hand.count)
            }
        }
    }
    
    // MARK: - Game Table Area
    
    private var gameTableArea: some View {
        ZStack {
            // Elegant table surface
            ElegantTableSurface()
            
            VStack(spacing: 16) {
                // Table title with Romanian ornate styling
                HStack {
                    RomanianOrnatePatternSystem.RomanianCrossPattern(
                        size: 14,
                        color: RomanianColors.goldAccent.opacity(0.8)
                    )
                    
                    Text("Masa de Joc")
                        .font(.title3.weight(.bold))
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
                    
                    RomanianOrnatePatternSystem.RomanianCrossPattern(
                        size: 14,
                        color: RomanianColors.goldAccent.opacity(0.8)
                    )
                }
                
                // Table cards with elegant arrangement
                if !gameViewModel.tableCards.isEmpty {
                    ElegantTableCardsView(
                        cards: gameViewModel.tableCards,
                        validMoves: gameViewModel.validMoves,
                        onCardTapped: { card in
                            if gameViewModel.validMoves.contains(card) {
                                playCard(card)
                            }
                        }
                    )
                } else {
                    EmptyTablePlaceholder()
                }
            }
        }
    }
    
    // MARK: - Player Avatar Area
    
    private var playerAvatarArea: some View {
        VStack(spacing: 8) {
            // Player cards with Shuffle Cats-inspired fanning
            if let humanPlayer = gameViewModel.humanPlayer {
                ElegantPlayerHandView(
                    cards: humanPlayer.hand,
                    selectedCard: selectedCard,
                    validMoves: gameViewModel.validMoves,
                    onCardTapped: { card in
                        if gameViewModel.validMoves.contains(card) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                if selectedCard?.id == card.id {
                                    playCard(card)
                                } else {
                                    selectedCard = card
                                }
                            }
                        }
                    }
                )
                .frame(height: 160)
            }
            
            // Player info and avatar row (Shuffle Cats style)
            HStack(spacing: 16) {
                // Player name and score
                VStack(spacing: 4) {
                    Text(gameViewModel.humanPlayer?.name ?? "Jucător")
                        .font(.headline.weight(.bold))
                        .foregroundColor(.white)
                    
                    Text("\(gameViewModel.playerScores.values.first(where: { _ in true }) ?? 0) puncte")
                        .font(.caption)
                        .foregroundColor(RomanianColors.goldAccent)
                }
                
                Spacer()
                
                // Player avatar with flags (Shuffle Cats style)
                HStack(spacing: 12) {
                    RomanianFlagView(size: .small)
                        .shadow(color: .black.opacity(0.3), radius: 3, x: 0, y: 2)
                    
                    RomanianCharacterAvatarView(
                        character: .traditionalPlayer,
                        size: .medium,
                        showBorder: true,
                        glowColor: RomanianColors.primaryBlue
                    )
                    
                    RomanianFlagView(size: .small)
                        .shadow(color: .black.opacity(0.3), radius: 3, x: 0, y: 2)
                }
                
                Spacer()
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
        }
    }
    
    // MARK: - Helper Views
    
    private func dialogueOverlay(_ dialogue: RomanianDialogue) -> some View {
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
    
    private var gameMenuOverlay: some View {
        ZStack {
            Color.black.opacity(0.7)
                .ignoresSafeArea()
                .onTapGesture { showingGameMenu = false }
            
            VStack(spacing: 20) {
                Text("Meniu Joc")
                    .font(.largeTitle.weight(.bold))
                    .foregroundColor(.white)
                
                VStack(spacing: 16) {
                    Button("Continuă Jocul") { showingGameMenu = false }
                        .buttonStyle(RomanianMenuButtonStyle())
                    
                    Button("Joc Nou") {
                        showingGameMenu = false
                        gameViewModel.startNewGame()
                    }
                    .buttonStyle(RomanianMenuButtonStyle())
                    
                    Button("Meniu Principal") {
                        showingGameMenu = false
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
        
        // Trigger Romanian dialogue
        if card.value == 7 {
            dialogueSystem.triggerDialogue(for: .sevenPlayed, character: gameViewModel.currentOpponentAvatar)
        } else if card.isPointCard {
            dialogueSystem.triggerDialogue(for: .strategicMove, character: gameViewModel.currentOpponentAvatar)
        } else {
            dialogueSystem.triggerDialogue(for: .goodPlay, character: gameViewModel.currentOpponentAvatar)
        }
        
        gameViewModel.playCard(card)
    }
    
    // MARK: - Computed Properties
    
    private var opponentCardsRemaining: Int {
        gameViewModel.players.count > 1 ? gameViewModel.players[1].hand.count : 0
    }
    
    private var playerCardsRemaining: Int {
        gameViewModel.humanPlayer?.hand.count ?? 0
    }
    
    private var totalCardsDealt: Int {
        8 // Standard Septica hand size
    }
}

// MARK: - Supporting Views

/// Romanian flag view with cultural authenticity
struct RomanianFlagView: View {
    enum Size {
        case small, medium, large
        
        var dimensions: CGSize {
            switch self {
            case .small: return CGSize(width: 30, height: 20)
            case .medium: return CGSize(width: 45, height: 30)
            case .large: return CGSize(width: 60, height: 40)
            }
        }
    }
    
    let size: Size
    
    var body: some View {
        HStack(spacing: 0) {
            Rectangle()
                .fill(RomanianColors.primaryBlue)
                .frame(width: size.dimensions.width / 3)
            
            Rectangle()
                .fill(RomanianColors.primaryYellow)
                .frame(width: size.dimensions.width / 3)
            
            Rectangle()
                .fill(RomanianColors.primaryRed)
                .frame(width: size.dimensions.width / 3)
        }
        .frame(width: size.dimensions.width, height: size.dimensions.height)
        .clipShape(RoundedRectangle(cornerRadius: 4))
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(Color.black.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
    }
}

/// Progress bar with Romanian styling
struct RomanianProgressBar: View {
    let current: Int
    let total: Int
    let color: Color
    let direction: Direction
    let label: String
    
    enum Direction {
        case horizontal, vertical
    }
    
    private var progress: Double {
        guard total > 0 else { return 0 }
        return Double(current) / Double(total)
    }
    
    var body: some View {
        VStack(spacing: 8) {
            Text(label)
                .font(.caption2.weight(.bold))
                .foregroundColor(.white.opacity(0.8))
            
            if direction == .vertical {
                VStack(spacing: 4) {
                    ForEach(0..<total, id: \.self) { index in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(index < current ? color : Color.gray.opacity(0.3))
                            .frame(width: 16, height: 12)
                            .animation(.easeInOut(duration: 0.3), value: current)
                    }
                }
            } else {
                HStack(spacing: 4) {
                    ForEach(0..<total, id: \.self) { index in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(index < current ? color : Color.gray.opacity(0.3))
                            .frame(width: 12, height: 16)
                            .animation(.easeInOut(duration: 0.3), value: current)
                    }
                }
            }
            
            Text("\(current)")
                .font(.caption.weight(.bold))
                .foregroundColor(color)
        }
    }
}

/// Opponent card hand view inspired by Shuffle Cats
struct OpponentCardHandView: View {
    let cardCount: Int
    
    var body: some View {
        HStack(spacing: -25) {
            ForEach(0..<cardCount, id: \.self) { index in
                RoundedRectangle(cornerRadius: 6)
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
                    .frame(width: 35, height: 50)
                    .overlay(
                        RomanianOrnatePatternSystem.RomanianCrossPattern(
                            size: 12,
                            color: RomanianColors.goldAccent.opacity(0.3)
                        )
                    )
                    .shadow(color: RomanianColors.primaryBlue.opacity(0.3), radius: 3, x: 0, y: 2)
                    .rotationEffect(.degrees(Double(index - cardCount/2) * 5))
                    .offset(y: CGFloat(abs(index - cardCount/2)) * -2)
                    .zIndex(Double(index))
            }
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: cardCount)
    }
}

/// Elegant table surface inspired by Shuffle Cats
struct ElegantTableSurface: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 20)
            .fill(
                RadialGradient(
                    colors: [
                        RomanianColors.tableGreen.opacity(0.8),
                        RomanianColors.tableGreen.opacity(0.6),
                        Color.black.opacity(0.3)
                    ],
                    center: .center,
                    startRadius: 50,
                    endRadius: 200
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(
                        LinearGradient(
                            colors: [
                                RomanianColors.goldAccent.opacity(0.6),
                                RomanianColors.primaryYellow.opacity(0.4),
                                RomanianColors.goldAccent.opacity(0.6)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2
                    )
            )
            .shadow(color: .black.opacity(0.4), radius: 8, x: 0, y: 4)
    }
}

/// Elegant table cards view with clear last-played visibility
struct ElegantTableCardsView: View {
    let cards: [Card]
    let validMoves: [Card]
    let onCardTapped: (Card) -> Void
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(Array(cards.enumerated()), id: \.element.id) { index, card in
                    let isLastPlayed = index == cards.count - 1
                    let isPlayable = validMoves.contains(card)
                    let cardCount = cards.count
                    
                    // Fan layout calculation
                    let normalizedPosition = cardCount > 1 ? 
                        Double(index) / Double(cardCount - 1) : 0.5
                    let fanAngle = (normalizedPosition - 0.5) * 40.0 // Spread cards in 40° fan
                    let fanRadius: CGFloat = 80 // Radius of the fan
                    let xOffset = fanRadius * sin(fanAngle * .pi / 180)
                    let yOffset = fanRadius * cos(fanAngle * .pi / 180) * 0.3 // Slight vertical curve
                    
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
                    .scaleEffect(isLastPlayed ? 0.95 : 0.85)
                    .rotationEffect(.degrees(fanAngle))
                    .offset(x: xOffset, y: yOffset)
                    .shadow(
                        color: isLastPlayed ? RomanianColors.goldAccent.opacity(0.4) : Color.black.opacity(0.15),
                        radius: isLastPlayed ? 4 : 2,
                        x: 0,
                        y: isLastPlayed ? 2 : 1
                    )
                    .overlay(
                        // Elegant highlight for last played card
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(
                                isLastPlayed ? RomanianColors.goldAccent.opacity(0.6) : Color.clear,
                                lineWidth: isLastPlayed ? 2 : 0
                            )
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(isLastPlayed ? RomanianColors.goldAccent.opacity(0.08) : Color.clear)
                            )
                            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isLastPlayed)
                    )
                    .zIndex(Double(index) + (isLastPlayed ? 100 : 0))
                    .animation(.spring(response: 0.3, dampingFraction: 0.9), value: isLastPlayed)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

/// Elegant player hand view with Shuffle Cats-inspired fanning
struct ElegantPlayerHandView: View {
    let cards: [Card]
    let selectedCard: Card?
    let validMoves: [Card]
    let onCardTapped: (Card) -> Void
    
    private let maxFanAngle: Double = 8.0
    private let cardSpacing: CGFloat = -80.0
    
    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                ForEach(Array(cards.enumerated()), id: \.element.id) { index, card in
                    let cardCount = cards.count
                    let isSelected = selectedCard?.id == card.id
                    let isPlayable = validMoves.contains(card)
                    
                    let normalizedPosition = cardCount > 1 ? 
                        Double(index) / Double(cardCount - 1) : 0.5
                    let fanAngle = (normalizedPosition - 0.5) * 2 * maxFanAngle
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
                    .scaleEffect(isSelected ? 1.1 : 0.90)
                    .rotationEffect(.degrees(fanAngle))
                    .offset(
                        x: CGFloat(index) * cardSpacing,
                        y: isSelected ? -25 : verticalOffset
                    )
                    .shadow(
                        color: isSelected ? RomanianColors.goldAccent.opacity(0.4) : Color.black.opacity(0.1),
                        radius: isSelected ? 6 : 2,
                        x: 0,
                        y: isSelected ? 4 : 1
                    )
                    .overlay(
                        // Elegant selection and playable highlighting
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(
                                isSelected ? RomanianColors.goldAccent.opacity(0.7) : 
                                (isPlayable ? RomanianColors.goldAccent.opacity(0.3) : Color.clear),
                                lineWidth: isSelected ? 2 : (isPlayable ? 1 : 0)
                            )
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(isSelected ? RomanianColors.goldAccent.opacity(0.1) : Color.clear)
                            )
                            .animation(.easeInOut(duration: 0.25), value: isPlayable)
                            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
                    )
                    .zIndex(isSelected ? 100 : Double(index))
                    .animation(.spring(response: 0.3, dampingFraction: 0.9), value: isSelected)
                }
            }
            .frame(maxWidth: .infinity)
            .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
        }
        .clipped()
    }
}

/// Empty table placeholder with Romanian styling
struct EmptyTablePlaceholder: View {
    var body: some View {
        VStack(spacing: 12) {
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
            
            Text("Primul jucător începe")
                .font(.headline.weight(.semibold))
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

// MARK: - Preview

struct ShuffleCatsInspiredGameScreen_Previews: PreviewProvider {
    static var previews: some View {
        let gameState = GameState()
        gameState.players = [
            Player(name: "Jucător"),
            AIPlayer(name: "Computer")
        ]
        gameState.setupNewGame()
        
        return ShuffleCatsInspiredGameScreen(gameState: gameState)
            .previewDevice("iPhone 14 Pro")
            .preferredColorScheme(.dark)
    }
}