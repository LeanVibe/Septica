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
    
    // Trick completion states
    @State private var isTrickComplete = false
    @State private var trickWinner: Player?
    @State private var showingTrickResult = false
    
    init(gameState: GameState) {
        self._gameViewModel = StateObject(wrappedValue: GameViewModel(gameState: gameState))
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Premium Romanian background
                romanianBackground

                // Main game area stacked vertically
                VStack(spacing: 0) {
                    // Top opponent area with avatar
                    opponentAvatarArea
                        .frame(height: geometry.size.height * 0.20)

                    // Game table area
                    gameTableArea
                        .frame(height: geometry.size.height * 0.30)

                    // Player area with avatar and fanned cards
                    playerAvatarArea
                        .frame(height: geometry.size.height * 0.50)
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

                // Trick completion overlay
                if showingTrickResult {
                    trickCompletionOverlay
                }
            }
            .overlay(alignment: .trailing) {
                pointCardProgressBar
                    .padding(.vertical, geometry.size.height * 0.08)
                    .padding(.trailing, 16)
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
            // Enhanced ShuffleCats-inspired vibrant background
            LinearGradient(
                colors: [
                    Color(red: 0.02, green: 0.12, blue: 0.18),
                    RomanianColors.tableGreen.opacity(0.5),
                    Color(red: 0.05, green: 0.18, blue: 0.25)
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
    
    // MARK: - Point Card Meter
    
    private var pointCardProgressBar: some View {
        SleekPointProgressBar(
            humanPoints: humanPointCardsCollected,
            opponentPoints: opponentPointCardsCollected,
            totalPointCards: totalPointCards,
            currentPlayer: gameViewModel.currentPlayer
        )
        .frame(width: 85)  // Sleeker width like ShuffleCats
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
        GeometryReader { geometry in
            ZStack(alignment: .top) {
                if let opponent = primaryOpponent {
                    OpponentCardHandView(cardCount: opponent.hand.count)
                        .frame(maxWidth: geometry.size.width * 0.85)
                        .frame(height: geometry.size.height * 0.75, alignment: .top)
                        .offset(y: geometry.size.height * 0.18)
                        .zIndex(0)

                    VStack(spacing: 8) {
                        ZStack {
                            TurnIndicatorAvatar(
                                character: opponent.romanianAvatar,
                                isActive: isOpponentTurn,
                                glowColorInactive: RomanianColors.primaryRed
                            )
                            .scaleEffect(dialogueSystem.isShowingDialogue ? 1.05 : 1.0)
                            .animation(.easeInOut(duration: 0.3), value: dialogueSystem.isShowingDialogue)
                            .accessibilityLabel(isOpponentTurn ? "Rândul adversarului" : "Adversar")
                            .accessibilityValue(opponent.name)

                            // Only show flag for opponent
                            RomanianFlagView(size: .small)
                                .offset(x: -42, y: -20)
                                .shadow(color: .black.opacity(0.25), radius: 2, x: 0, y: 1)
                        }

                        VStack(spacing: 2) {
                            Text(opponent.name)
                                .font(.caption.weight(.bold))
                                .foregroundColor(RomanianColors.primaryRed)

                            Text("\(opponent.score) puncte")
                                .font(.caption2.weight(.semibold))
                                .foregroundColor(RomanianColors.primaryRed.opacity(0.85))
                        }
                    }
                    .padding(.top, geometry.size.height * 0.06)
                    .zIndex(1)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
    
    // MARK: - Game Table Area
    
    private var gameTableArea: some View {
        GeometryReader { geometry in
            ZStack {
                // Elegant table surface with subtle foreshortening
                ElegantTableSurface()
                    .frame(
                        width: geometry.size.width * 0.92,
                        height: geometry.size.height * 1.12
                    )

                VStack(spacing: 18) {
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
                        .frame(height: geometry.size.height * 0.55)
                    } else {
                        EmptyTablePlaceholder()
                            .frame(height: geometry.size.height * 0.4)
                    }
                }
                .padding(.top, geometry.size.height * 0.1)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .rotation3DEffect(
                .degrees(12),
                axis: (x: 1, y: 0, z: 0),
                anchor: .center,
                perspective: 0.55
            )
            .padding(.horizontal, geometry.size.width * 0.04)
        }
    }
    
    // MARK: - Player Avatar Area
    
    private var playerAvatarArea: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottom) {
                if let humanPlayer = gameViewModel.humanPlayer {
                    // Cards fanned around avatar - ShuffleCats style
                    ShuffleCatsPlayerHandView(
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
                    .frame(width: geometry.size.width, height: geometry.size.height * 0.85)
                    .zIndex(0)

                    // Avatar positioned at the center bottom
                    VStack(spacing: 8) {
                        TurnIndicatorAvatar(
                            character: humanPlayer.romanianAvatar,
                            isActive: isHumanTurn,
                            glowColorInactive: RomanianColors.primaryBlue
                        )
                        .allowsHitTesting(false)

                        VStack(spacing: 2) {
                            Text(humanPlayer.name)
                                .font(.caption.weight(.bold))
                                .foregroundColor(RomanianColors.primaryBlue)

                            Text("\(humanPlayer.score) puncte")
                                .font(.caption2.weight(.semibold))
                                .foregroundColor(RomanianColors.primaryBlue.opacity(0.85))
                        }
                        .allowsHitTesting(false)
                    }
                    .padding(.bottom, geometry.safeAreaInsets.bottom + 15)
                    .zIndex(1)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel(isHumanTurn ? "Rândul tău" : "Jucător")
                    .accessibilityValue("\(humanPlayer.name), \(humanPlayer.score) puncte")
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
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
    
    private var trickCompletionOverlay: some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                // Trick winner announcement
                Text("Mâna câștigată!")
                    .font(.title.weight(.bold))
                    .foregroundColor(.white)
                
                if let winner = trickWinner {
                    Text("\(winner.name) câștigă mâna")
                        .font(.title2.weight(.semibold))
                        .foregroundColor(RomanianColors.goldAccent)
                }
                
                // Cards played in this trick
                HStack(spacing: 12) {
                    ForEach(gameViewModel.gameState.tableCards.suffix(4), id: \.id) { card in
                        CardView(
                            card: card,
                            isSelected: false,
                            isPlayable: false,
                            isAnimating: false,
                            cardSize: .compact
                        )
                        .scaleEffect(0.8)
                        .shadow(
                            color: .black.opacity(0.3),
                            radius: 4,
                            x: 0,
                            y: 2
                        )
                    }
                }
                
                Text("Se continuă...")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
            .padding(30)
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
        
        // Play the card with animation
        withAnimation(.easeInOut(duration: 0.4)) {
            gameViewModel.playCard(card)
        }
        
        // Check if trick is complete after card is played
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            checkTrickCompletion()
        }
    }
    
    private func checkTrickCompletion() {
        // Check if all players have played a card (4 cards on table for trick completion)
        if gameViewModel.gameState.tableCards.count >= gameViewModel.gameState.players.count {
            isTrickComplete = true
            
            // Determine trick winner using GameRules
            let winnerIndex = GameRules.determineTrickWinner(tableCards: gameViewModel.gameState.tableCards)
            if winnerIndex < gameViewModel.gameState.players.count {
                trickWinner = gameViewModel.gameState.players[winnerIndex]
            }
            
            // Show trick result with animation
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                showingTrickResult = true
            }
            
            // Wait for user to see the result, then clear the trick
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                clearTrickWithAnimation()
            }
        }
    }
    
    private func clearTrickWithAnimation() {
        withAnimation(.easeInOut(duration: 0.8)) {
            showingTrickResult = false
            isTrickComplete = false
        }
        
        // Clear the table cards after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            gameViewModel.gameState.tableCards.removeAll()
            trickWinner = nil
        }
    }
    
    // MARK: - Computed Properties
    
    private var totalPointCards: Int { 8 }

    private var humanPointCardsCollected: Int {
        min(gameViewModel.humanPlayer?.score ?? 0, totalPointCards)
    }

    private var opponentPointCardsCollected: Int {
        let opponentScores = gameViewModel.players
            .filter { !$0.isHuman }
            .map { $0.score }
            .reduce(0, +)
        let availableAfterHuman = max(0, totalPointCards - humanPointCardsCollected)
        return min(opponentScores, availableAfterHuman)
    }

    private var primaryOpponent: Player? {
        gameViewModel.players.first(where: { !$0.isHuman })
    }

    private var isHumanTurn: Bool {
        gameViewModel.currentPlayer?.isHuman == true
    }

    private var isOpponentTurn: Bool {
        guard let opponent = primaryOpponent else { return false }
        return gameViewModel.currentPlayer?.id == opponent.id
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

/// Combined avatar + turn indicator halo for active player clarity
struct TurnIndicatorAvatar: View {
    let character: RomanianCharacterAvatar
    let isActive: Bool
    let glowColorInactive: Color

    var body: some View {
        ZStack {
            RomanianCharacterAvatarView(
                character: character,
                size: .medium,
                showBorder: true,
                glowColor: isActive ? RomanianColors.countrysideGreen : glowColorInactive
            )

            if isActive {
                // Enhanced green glow for current player
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [
                                RomanianColors.countrysideGreen,
                                RomanianColors.countrysideGreen.opacity(0.8),
                                RomanianColors.countrysideGreen
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 8
                    )
                    .blur(radius: 2)
                    .scaleEffect(1.2)
                    .shadow(color: RomanianColors.countrysideGreen.opacity(0.8), radius: 15)
                    .shadow(color: RomanianColors.countrysideGreen.opacity(0.6), radius: 25)
                    .opacity(0.9)
                    .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: UUID())
                    .transition(.opacity)
                
                // Additional pulsing ring
                Circle()
                    .stroke(RomanianColors.countrysideGreen.opacity(0.4), lineWidth: 3)
                    .scaleEffect(1.35)
                    .opacity(0.6)
                    .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: UUID())
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isActive)
        .accessibilityAddTraits(isActive ? .isSelected : [])
    }
}

/// Sleek ShuffleCats-style vertical progress bar
struct SleekPointProgressBar: View {
    let humanPoints: Int
    let opponentPoints: Int
    let totalPointCards: Int
    let currentPlayer: Player?

    private var clampedHumanPoints: Int {
        clamp(humanPoints)
    }

    private var clampedOpponentPoints: Int {
        let remainingAfterHuman = max(0, totalPointCards - clampedHumanPoints)
        return max(0, min(opponentPoints, remainingAfterHuman))
    }

    private var remainingPoints: Int {
        max(totalPointCards - clampedHumanPoints - clampedOpponentPoints, 0)
    }

    private var humanSegments: Range<Int> {
        0..<clampedHumanPoints
    }

    private var opponentSegments: Range<Int> {
        (totalPointCards - clampedOpponentPoints)..<totalPointCards
    }

    var body: some View {
        VStack(spacing: 6) {
            // Minimal icon indicator like ShuffleCats
            Image(systemName: "star.fill")
                .font(.caption2)
                .foregroundColor(RomanianColors.goldAccent.opacity(0.8))

            ZStack(alignment: .bottom) {
                // Sleek minimal background like ShuffleCats
                Capsule()
                    .fill(Color.black.opacity(0.25))
                    .frame(width: 30, height: 180)
                    .overlay(
                        Capsule()
                            .stroke(Color.white.opacity(0.06), lineWidth: 0.5)
                    )

                // Clean segment stack without gaps
                VStack(spacing: 0) {
                    ForEach((0..<totalPointCards).reversed(), id: \.self) { index in
                        Rectangle()
                            .fill(colorForSegment(at: index))
                            .frame(width: 22, height: 20)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .padding(.vertical, 8)
                
                // Active player glow indicator
                if let player = currentPlayer {
                    let isHuman = player.isHuman
                    let points = isHuman ? clampedHumanPoints : clampedOpponentPoints
                    let glowHeight = CGFloat(points) * 20
                    
                    VStack {
                        if !isHuman && points > 0 { 
                            Rectangle()
                                .fill(RomanianColors.countrysideGreen.opacity(0.35))
                                .frame(width: 26, height: min(glowHeight, 160))
                                .blur(radius: 5)
                                .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: UUID())
                        }
                        Spacer()
                        if isHuman && points > 0 {
                            Rectangle()
                                .fill(RomanianColors.countrysideGreen.opacity(0.35))
                                .frame(width: 26, height: min(glowHeight, 160))
                                .blur(radius: 5)
                                .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: UUID())
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .padding(.vertical, 8)
                }
            }

            // Minimal legend
            HStack(spacing: 10) {
                VStack(spacing: 2) {
                    Circle()
                        .fill(RomanianColors.primaryBlue)
                        .frame(width: 6, height: 6)
                    Text("\(clampedHumanPoints)")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.white.opacity(0.8))
                }
                VStack(spacing: 2) {
                    Circle()
                        .fill(RomanianColors.primaryRed)
                        .frame(width: 6, height: 6)
                    Text("\(clampedOpponentPoints)")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.white.opacity(0.8))
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Progres puncte")
        .accessibilityValue("Tu \(clampedHumanPoints), adversar \(clampedOpponentPoints)")
    }

    private func clamp(_ value: Int) -> Int {
        max(0, min(value, totalPointCards))
    }

    private func colorForSegment(at reversedIndex: Int) -> Color {
        // reversedIndex: totalPointCards-1 is bottom, 0 is top
        let bottomIndex = totalPointCards - 1 - reversedIndex
        if humanSegments.contains(bottomIndex) {
            return RomanianColors.primaryBlue
        }
        if opponentSegments.contains(bottomIndex) {
            return RomanianColors.primaryRed
        }
        return Color.white.opacity(0.25)
    }

    /// Small labelled swatch used in the legend row
    private struct LegendSwatch: View {
        let color: Color
        let label: String

        var body: some View {
            HStack(spacing: 4) {
                Circle()
                    .fill(color)
                    .frame(width: 8, height: 8)
                Text(label)
            }
        }
    }
}

/// Opponent card hand view inspired by Shuffle Cats
struct OpponentCardHandView: View {
    let cardCount: Int
    
    // Refined values for ShuffleCats-style tight fan
    private let maxFanAngle: Double = 55    // Wider angle for better spread
    private let fanRadius: CGFloat = 90     // Tighter radius around avatar
    
    var body: some View {
        ZStack {
            ForEach(0..<cardCount, id: \.self) { index in
                let normalizedPosition = cardCount > 1 ?
                    Double(index) / Double(cardCount - 1) : 0.5
                let fanAngle = (normalizedPosition - 0.5) * maxFanAngle
                let angleRadians = fanAngle * .pi / 180
                let xOffset = fanRadius * CGFloat(sin(angleRadians))
                let yOffset = fanRadius * CGFloat(cos(angleRadians) * -0.4) - 10  // Better positioning
                let depthTilt = 16 - abs(normalizedPosition - 0.5) * 10
                let scale = 0.9 + CGFloat(abs(normalizedPosition - 0.5) * -0.08)
                
                RoundedRectangle(cornerRadius: 6)
                    .fill(
                        LinearGradient(
                            colors: [
                                RomanianColors.cardBack,
                                RomanianColors.primaryBlue.opacity(0.85)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 50, height: 62.5)  // Match new card proportions
                    .overlay(
                        RomanianOrnatePatternSystem.RomanianCrossPattern(
                            size: 12,
                            color: RomanianColors.goldAccent.opacity(0.35)
                        )
                    )
                    .scaleEffect(scale)
                    .rotationEffect(.degrees(fanAngle))
                    .rotation3DEffect(
                        .degrees(depthTilt),
                        axis: (x: 1, y: 0, z: 0),
                        anchor: .center,
                        perspective: 0.7
                    )
                    .offset(x: xOffset, y: yOffset)
                    .shadow(color: RomanianColors.primaryBlue.opacity(0.4), radius: 5, x: 0, y: 4)
                    .zIndex(Double(index))
            }
        }
        .frame(height: fanRadius * 0.85)
        .animation(.spring(response: 0.45, dampingFraction: 0.85), value: cardCount)
        .accessibilityHidden(true)
    }
}

/// Enhanced table surface with ShuffleCats vibrant style
struct ElegantTableSurface: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 20)
            .fill(
                LinearGradient(
                    colors: [
                        RomanianColors.tableGreen,
                        RomanianColors.tableGreen.opacity(0.85),
                        Color(red: 0.1, green: 0.35, blue: 0.25).opacity(0.6)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.white.opacity(0.12), lineWidth: 1)
            )
            .overlay(
                LinearGradient(
                    colors: [Color.white.opacity(0.25), Color.clear],
                    startPoint: .top,
                    endPoint: .center
                )
                .clipShape(
                    RoundedRectangle(cornerRadius: 20)
                )
                .opacity(0.6)
            )
            .shadow(color: .black.opacity(0.5), radius: 12, x: 0, y: 8)
            .shadow(color: Color.black.opacity(0.3), radius: 20, x: 0, y: 18)
    }
}

/// Enhanced table cards view with ShuffleCats-style perspective
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
                    
                    // Enhanced positioning for ShuffleCats-style perspective
                    let position = getCardPosition(for: index, total: cardCount, in: geometry)
                    let perspective = getCardPerspective(for: index, total: cardCount)
                    
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
                    .scaleEffect(isLastPlayed ? 1.05 : perspective.scale)
                    .rotationEffect(.degrees(perspective.rotation))
                    .rotation3DEffect(
                        .degrees(perspective.xTilt),
                        axis: (x: 1, y: 0, z: 0),
                        anchor: .center,
                        perspective: 0.6
                    )
                    .rotation3DEffect(
                        .degrees(perspective.yTilt),
                        axis: (x: 0, y: 1, z: 0),
                        anchor: .center,
                        perspective: 0.4
                    )
                    .position(x: position.x, y: position.y)
                    .shadow(
                        color: isLastPlayed ? RomanianColors.goldAccent.opacity(0.4) : Color.black.opacity(0.3),
                        radius: isLastPlayed ? 8 : 5,
                        x: 0,
                        y: isLastPlayed ? 8 : 6
                    )
                    .overlay(
                        // Subtle highlight for last played card
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(
                                isLastPlayed ? RomanianColors.goldAccent.opacity(0.7) : Color.clear,
                                lineWidth: isLastPlayed ? 2 : 0
                            )
                            .scaleEffect(1.02)
                            .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: isLastPlayed)
                    )
                    .zIndex(Double(index) + (isLastPlayed ? 100 : 0))
                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isLastPlayed)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
    
    private func getCardPosition(for index: Int, total: Int, in geometry: GeometryProxy) -> CGPoint {
        let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
        
        if total == 1 {
            return center
        }
        
        // Cascade cards with top-left visible (like dealer dealing cards)
        let baseX = center.x - 20  // Start slightly left of center
        let baseY = center.y - 20  // Start slightly above center
        
        // Each card offset to show top-left corner
        let xOffset = CGFloat(index) * 18  // Horizontal cascade
        let yOffset = CGFloat(index) * 12  // Vertical cascade
        
        // Add slight rotation variation for natural look
        let rotationOffset = Double(index - total/2) * 3
        
        return CGPoint(
            x: baseX + xOffset + CGFloat(sin(rotationOffset * .pi / 180) * 5),
            y: baseY + yOffset
        )
    }
    
    private func getCardPerspective(for index: Int, total: Int) -> (scale: CGFloat, rotation: Double, xTilt: Double, yTilt: Double) {
        if total == 1 {
            return (scale: 0.95, rotation: 0, xTilt: 8, yTilt: 0)
        }
        
        // Natural dealing rotation for cascaded cards
        let baseRotation = Double(index - total/2) * 4  // Slight rotation variance
        let randomRotation = Double.random(in: -2...2)  // Natural variation
        
        // Cards on top are slightly larger (more recent)
        let scale: CGFloat = 0.9 + CGFloat(index) * 0.02
        
        // Consistent perspective for stacked look
        let xTilt = 10.0  // Consistent tilt for all cards
        let yTilt = 3.0   // Slight y-tilt for depth
        
        return (scale: min(scale, 1.0), rotation: baseRotation + randomRotation, xTilt: xTilt, yTilt: yTilt)
    }
}

/// ShuffleCats-style player hand view with cards fanned around avatar
struct ShuffleCatsPlayerHandView: View {
    let cards: [Card]
    let selectedCard: Card?
    let validMoves: [Card]
    let onCardTapped: (Card) -> Void
    
    // Refined ShuffleCats-style parameters for tighter card grouping
    private let fanRadius: CGFloat = 110.0     // Tighter radius for closer cards
    private let maximumFanSpan: Double = 65.0  // Tighter span for better overlap
    private let avatarOffset: CGFloat = 75.0   // Closer to avatar
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(Array(cards.enumerated()), id: \.element.id) { index, card in
                    let cardCount = cards.count
                    let isSelected = selectedCard?.id == card.id
                    let isPlayable = validMoves.contains(card)
                    
                    // Calculate position around avatar (bottom center)
                    let avatarCenterX = geometry.size.width / 2
                    let avatarCenterY = geometry.size.height - avatarOffset
                    
                    // Fan angle calculations
                    let span = cardCount > 1 ? maximumFanSpan : 0
                    let step = cardCount > 1 ? span / Double(cardCount - 1) : 0
                    let offsetFromCenter = Double(index) - Double(cardCount - 1) / 2
                    let fanAngle = offsetFromCenter * step
                    
                    // Position calculations with better arc (cards behind avatar)
                    let angleRadians = (fanAngle + 90) * .pi / 180  // +90 to position behind avatar
                    let xOffset = fanRadius * CGFloat(sin(angleRadians)) * 0.9  // Slightly tighter X
                    let yOffset = fanRadius * CGFloat(cos(angleRadians)) * 0.7  // Flatter arc like ShuffleCats
                    
                    // 3D perspective for depth
                    let depthTilt = 15 - abs(offsetFromCenter) * 3
                    let perspectiveRotation = offsetFromCenter * 8
                    
                    CardView(
                        card: card,
                        isSelected: isSelected,
                        isPlayable: isPlayable,
                        isAnimating: false,
                        cardSize: .small,
                        onTap: { onCardTapped(card) },
                        onDragChanged: nil,
                        onDragEnded: nil
                    )
                    .scaleEffect(isSelected ? 1.1 : 0.85)
                    .rotationEffect(.degrees(fanAngle))
                    .rotation3DEffect(
                        .degrees(depthTilt),
                        axis: (x: 1, y: 0, z: 0),
                        anchor: .center,
                        perspective: 0.6
                    )
                    .rotation3DEffect(
                        .degrees(perspectiveRotation),
                        axis: (x: 0, y: 1, z: 0),
                        anchor: .center,
                        perspective: 0.4
                    )
                    .position(
                        x: avatarCenterX + xOffset,
                        y: isSelected ? avatarCenterY + yOffset - 20 : avatarCenterY + yOffset
                    )
                    .shadow(
                        color: .black.opacity(0.3),
                        radius: 6,
                        x: 0,
                        y: 4
                    )
                    .shadow(
                        color: isSelected ? RomanianColors.goldAccent.opacity(0.4) : .clear,
                        radius: isSelected ? 12 : 0,
                        x: 0,
                        y: isSelected ? 8 : 0
                    )
                    .zIndex(isSelected ? 100 : Double(cardCount - index))  // Cards further from center on top
                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isSelected)
                    .animation(.spring(response: 0.5, dampingFraction: 0.9), value: isPlayable)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
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
        
        // Add some cards to make the preview more interesting
        if !gameState.players.isEmpty {
            gameState.players[0].hand = [
                Card(suit: .hearts, value: 7),
                Card(suit: .clubs, value: 11),
                Card(suit: .diamonds, value: 10),
                Card(suit: .spades, value: 1),
                Card(suit: .hearts, value: 11)
            ]
        }
        
        // Add table cards
        gameState.tableCards = [
            Card(suit: .clubs, value: 7),
            Card(suit: .hearts, value: 10),
            Card(suit: .diamonds, value: 1)
        ]
        
        return Group {
            // Main preview with full functionality 
            ShuffleCatsInspiredGameScreen(gameState: gameState)
                .environmentObject(NavigationManager())
                .environmentObject(AccessibilityManager())
                .environmentObject(HapticManager()) 
                .environmentObject(AudioManager())
                .environmentObject(AnimationManager())
                .previewDisplayName("iPad - Full Game Screen")
            
            // iPhone preview
            ShuffleCatsInspiredGameScreen(gameState: gameState)
                .environmentObject(NavigationManager())
                .environmentObject(AccessibilityManager())
                .environmentObject(HapticManager()) 
                .environmentObject(AudioManager())
                .environmentObject(AnimationManager())
                .previewDisplayName("iPhone - Portrait")
        }
    }
}

#if DEBUG
// MARK: - Quick Iteration Previews 

/// Lightweight preview for rapid UI iteration without complex dependencies
struct QuickGameScreenPreview: View {
    var body: some View {
        // Mock card data for quick preview
        let mockCards = [
            Card(suit: .hearts, value: 7),
            Card(suit: .clubs, value: 11),
            Card(suit: .diamonds, value: 10)
        ]
        
        ZStack {
            // Romanian theme background
            LinearGradient(
                colors: [
                    RomanianColors.primaryRed.opacity(0.3),
                    RomanianColors.primaryBlue.opacity(0.2),
                    RomanianColors.countrysideGreen.opacity(0.1)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack {
                // Quick table cards preview
                HStack(spacing: -12) {
                    ForEach(mockCards, id: \.id) { card in
                        CardView(card: card, cardSize: .compact)
                            .scaleEffect(0.85)
                    }
                }
                .padding()
                
                Spacer()
                
                // Quick player hand preview  
                HStack(spacing: -20) {
                    ForEach(mockCards, id: \.id) { card in
                        CardView(card: card, cardSize: .normal)
                            .scaleEffect(0.90)
                    }
                }
                .padding()
            }
        }
        .previewDisplayName("Quick Layout Preview")
    }
}

struct QuickGameScreenPreview_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            QuickGameScreenPreview()
                .previewDevice("iPad Pro (11-inch)")
                .preferredColorScheme(.dark)
                .previewDisplayName("iPad - Quick Preview")
            
            QuickGameScreenPreview()
                .previewDevice("iPhone 15 Pro")
                .preferredColorScheme(.dark)
                .previewDisplayName("iPhone - Quick Preview")
        }
    }
}
#endif
