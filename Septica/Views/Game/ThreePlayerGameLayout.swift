//
//  ThreePlayerGameLayout.swift
//  Septica
//
//  3-player triangular layout for Romanian Septica
//  Special rules: 30-card deck (removes 2 eights), remaining 8s become wild cards
//

import SwiftUI

/// Triangular layout for 3-player Romanian Septica
/// Positions: Opponent 1 (top-left), Opponent 2 (top-right), Human (bottom)
struct ThreePlayerGameLayout: View {
    @ObservedObject var gameViewModel: GameViewModel
    @Binding var selectedCard: Card?
    @Binding var showingGameMenu: Bool

    // Romanian Dialogue System Integration
    @StateObject private var dialogueSystem = RomanianDialogueSystem()

    // Navigation manager for proper menu navigation
    @EnvironmentObject private var navigationManager: SimpleNavigationManager

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Romanian cultural background
                romanianBackground

                VStack(spacing: 0) {
                    // Top status bar
                    gameStatusBar
                        .frame(height: geometry.size.height * 0.08)

                    // Top opponents area (triangular arrangement)
                    HStack(spacing: 20) {
                        // Opponent 1 (top-left)
                        opponentArea(
                            player: gameViewModel.players.indices.contains(1) ? gameViewModel.players[1] : nil,
                            geometry: geometry,
                            position: .topLeft
                        )
                        .frame(width: geometry.size.width * 0.35)

                        Spacer()

                        // Opponent 2 (top-right)
                        opponentArea(
                            player: gameViewModel.players.indices.contains(2) ? gameViewModel.players[2] : nil,
                            geometry: geometry,
                            position: .topRight
                        )
                        .frame(width: geometry.size.width * 0.35)
                    }
                    .frame(height: geometry.size.height * 0.20)
                    .padding(.horizontal)

                    Spacer()

                    // Center game table
                    gameTableArea
                        .frame(height: geometry.size.height * 0.25)

                    Spacer()

                    // Bottom human player area
                    VStack(spacing: 8) {
                        playerHandArea
                        gameActionControlsArea
                    }
                    .frame(height: geometry.size.height * 0.40)
                }

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

                // Wild 8s indicator for 3-player mode
                wildCardsIndicator
                    .position(x: geometry.size.width * 0.95, y: geometry.size.height * 0.12)

                // Game menu overlay
                if showingGameMenu {
                    gameMenuOverlay
                }
            }
        }
        .navigationBarHidden(true)
        .preferredColorScheme(.dark)
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

            // Romanian café atmospheric lighting
            RadialGradient(
                colors: [
                    RomanianColors.goldAccent.opacity(0.08),
                    Color.clear,
                    RomanianColors.primaryYellow.opacity(0.04)
                ],
                center: .center,
                startRadius: 80,
                endRadius: 450
            )

            // Warm café ambiance overlay
            LinearGradient(
                colors: [
                    Color(red: 0.8, green: 0.6, blue: 0.3).opacity(0.08),
                    Color.clear,
                    Color(red: 0.9, green: 0.7, blue: 0.4).opacity(0.06)
                ],
                startPoint: .topTrailing,
                endPoint: .bottomLeading
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

            // Scores (3 players)
            HStack(spacing: 12) {
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

    // MARK: - Opponent Areas

    enum OpponentPosition {
        case topLeft, topRight
    }

    private func opponentArea(player: Player?, geometry: GeometryProxy, position: OpponentPosition) -> some View {
        VStack(spacing: 8) {
            // Opponent name and score
            if let player = player {
                HStack(spacing: 8) {
                    // Avatar circle
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    RomanianColors.primaryBlue.opacity(0.6),
                                    RomanianColors.primaryBlue.opacity(0.8)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 32, height: 32)
                        .overlay(
                            Text(String(player.name.prefix(1)))
                                .font(.headline.weight(.bold))
                                .foregroundColor(.white)
                        )

                    VStack(alignment: position == .topLeft ? .leading : .trailing, spacing: 2) {
                        Text(player.name)
                            .font(.caption.weight(.semibold))
                            .foregroundColor(.white)
                        Text("\(player.score) puncte")
                            .font(.caption2)
                            .foregroundColor(RomanianColors.goldAccent)
                    }
                }

                // Opponent cards (face down)
                HStack(spacing: -6) {
                    ForEach(0..<player.hand.count, id: \.self) { index in
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
                            .frame(width: 45, height: 63)
                            .overlay(
                                Text("♦")
                                    .font(.title3)
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

                Text("Masa de Joc (3 Jucători)")
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

                        Text("Masă 3 Jucători")
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
            .frame(width: 380, height: 150)
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
            if gameViewModel.gameState.waitingForObjection {
                if selectedCard != nil {
                    Text("Cartea de obiecție selectată • Apasă Joacă sau Pasează")
                        .font(.caption2)
                        .foregroundColor(RomanianColors.goldAccent)
                        .multilineTextAlignment(.center)
                } else if !gameViewModel.gameState.validObjectionCards.isEmpty {
                    Text("Poți obiecta! Selectează o carte sau apasă Pasează")
                        .font(.caption2)
                        .foregroundColor(RomanianColors.primaryYellow)
                        .multilineTextAlignment(.center)
                } else {
                    Text("Fără cărți de obiecție disponibile • Apasă Pasează")
                        .font(.caption2)
                        .foregroundColor(RomanianColors.primaryRed.opacity(0.8))
                        .multilineTextAlignment(.center)
                }
            } else if selectedCard != nil {
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
                    validMoves: gameViewModel.gameState.waitingForObjection
                        ? gameViewModel.gameState.validObjectionCards
                        : gameViewModel.validMoves,
                    onCardTapped: { card in
                        let movesToCheck = gameViewModel.gameState.waitingForObjection
                            ? gameViewModel.gameState.validObjectionCards
                            : gameViewModel.validMoves

                        if movesToCheck.contains(card) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                selectedCard = card
                            }
                        }
                    }
                )
                .frame(height: 180)
            }
        }
    }

    // MARK: - Game Action Controls

    private var gameActionControlsArea: some View {
        VStack(spacing: 12) {
            // Objection Timer Display (when waiting for objection)
            if gameViewModel.gameState.waitingForObjection,
               let deadline = gameViewModel.gameState.objectionDeadline {
                ObjectionTimerView(deadline: deadline)
                    .transition(.scale.combined(with: .opacity))
            }

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
                    .disabled(selectedCard == nil || gameViewModel.gameState.waitingForObjection)

                    // Pass/Objection button
                    if gameViewModel.gameState.waitingForObjection {
                        Button(action: {
                            selectedCard = nil
                            #if os(iOS)
                            let impact = UIImpactFeedbackGenerator(style: .medium)
                            impact.impactOccurred()
                            #endif
                            gameViewModel.passCurrentTurn()
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "hand.raised.fill")
                                Text("Pasez")
                                    .font(.headline.weight(.bold))
                            }
                            .foregroundColor(.white)
                            .frame(minWidth: 120)
                            .padding(.vertical, 14)
                            .padding(.horizontal, 20)
                            .background(
                                LinearGradient(
                                    colors: [
                                        RomanianColors.primaryRed,
                                        RomanianColors.primaryRed.opacity(0.8)
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .shadow(color: RomanianColors.primaryRed.opacity(0.5), radius: 8, x: 0, y: 4)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(RomanianColors.goldAccent.opacity(0.4), lineWidth: 2)
                            )
                        }
                    } else if shouldShowPassButton {
                        Button(action: {
                            selectedCard = nil
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

                // Selected card indicator
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

    // MARK: - Wild Cards Indicator (3-Player Mode)

    private var wildCardsIndicator: some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Text("7")
                    .font(.caption.weight(.bold))
                    .foregroundColor(RomanianColors.goldAccent)
                Text("&")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.6))
                Text("8")
                    .font(.caption.weight(.bold))
                    .foregroundColor(RomanianColors.primaryYellow)
            }
            Text("Wild")
                .font(.caption2.weight(.semibold))
                .foregroundColor(.white.opacity(0.8))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.black.opacity(0.7))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    RomanianColors.goldAccent.opacity(0.6),
                                    RomanianColors.primaryYellow.opacity(0.4)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            lineWidth: 2
                        )
                )
        )
        .shadow(color: RomanianColors.goldAccent.opacity(0.3), radius: 4, x: 0, y: 2)
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

    private func playCard(_ card: Card) {
        guard gameViewModel.canPlayCard(card) else { return }

        selectedCard = nil

        // Trigger Romanian dialogue for good moves
        if card.value == 7 {
            dialogueSystem.triggerDialogue(for: .sevenPlayed, character: gameViewModel.currentOpponentAvatar)
        } else if card.value == 8 {
            // Special dialogue for wild 8s in 3-player mode
            dialogueSystem.triggerDialogue(for: .strategicMove, character: gameViewModel.currentOpponentAvatar)
        } else if card.isPointCard {
            dialogueSystem.triggerDialogue(for: .strategicMove, character: gameViewModel.currentOpponentAvatar)
        } else {
            dialogueSystem.triggerDialogue(for: .goodPlay, character: gameViewModel.currentOpponentAvatar)
        }

        // Play the card
        gameViewModel.playCard(card)
    }

    private var shouldShowPassButton: Bool {
        guard gameViewModel.isHumanPlayerTurn else { return false }

        if gameViewModel.validMoves.isEmpty {
            return true
        }

        return !gameViewModel.tableCards.isEmpty
    }
}
