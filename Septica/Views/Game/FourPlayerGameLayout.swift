//
//  FourPlayerGameLayout.swift
//  Septica
//
//  4-player team mode layout for Romanian Septica (2v2 team play)
//  Partners sit opposite: Player 0 + Player 2 vs Player 1 + Player 3
//

import SwiftUI

/// Four-player team mode game layout with square arrangement
struct FourPlayerGameLayout: View {
    @ObservedObject var gameViewModel: GameViewModel
    @Binding var selectedCard: Card?
    let onCardPlayed: (Card) -> Void
    let onPass: () -> Void

    // Team configuration (2v2)
    private var teamAIndices: [Int] { [0, 2] } // Human (bottom) + AI partner (top)
    private var teamBIndices: [Int] { [1, 3] } // Opponent 1 (right) + Opponent 2 (left)

    private var teamAScore: Int {
        teamAIndices.reduce(0) { total, index in
            guard index < gameViewModel.players.count else { return total }
            return total + gameViewModel.players[index].score
        }
    }

    private var teamBScore: Int {
        teamBIndices.reduce(0) { total, index in
            guard index < gameViewModel.players.count else { return total }
            return total + gameViewModel.players[index].score
        }
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Romanian cultural background
                romanianBackground

                VStack(spacing: 0) {
                    // Top: Partner (Player 2 - Team A)
                    topPlayerArea
                        .frame(height: geometry.size.height * 0.2)

                    // Middle: Left opponent + Game table + Right opponent
                    HStack(spacing: 0) {
                        // Left: Opponent 2 (Player 3 - Team B)
                        leftPlayerArea
                            .frame(width: geometry.size.width * 0.2)

                        // Center: Game table
                        centerGameTableArea
                            .frame(maxWidth: .infinity)

                        // Right: Opponent 1 (Player 1 - Team B)
                        rightPlayerArea
                            .frame(width: geometry.size.width * 0.2)
                    }
                    .frame(maxHeight: .infinity)

                    // Bottom: Human player (Player 0 - Team A)
                    bottomPlayerArea
                        .frame(height: geometry.size.height * 0.3)
                }

                // Team score overlay
                teamScoreOverlay
                    .zIndex(100)
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

            // Warm café ambiance overlay
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
        }
    }

    // MARK: - Player Areas

    private var topPlayerArea: some View {
        VStack(spacing: 8) {
            playerInfoHeader(playerIndex: 2, position: .top)

            if gameViewModel.players.count > 2 {
                playerHandView(playerIndex: 2, position: .top)
            }
        }
        .padding(.top, 8)
    }

    private var leftPlayerArea: some View {
        VStack(spacing: 8) {
            playerInfoHeader(playerIndex: 3, position: .left)

            if gameViewModel.players.count > 3 {
                playerHandView(playerIndex: 3, position: .left)
            }
        }
        .padding(.leading, 8)
    }

    private var rightPlayerArea: some View {
        VStack(spacing: 8) {
            playerInfoHeader(playerIndex: 1, position: .right)

            if gameViewModel.players.count > 1 {
                playerHandView(playerIndex: 1, position: .right)
            }
        }
        .padding(.trailing, 8)
    }

    private var bottomPlayerArea: some View {
        VStack(spacing: 8) {
            // Human player hand
            if let humanPlayer = gameViewModel.humanPlayer {
                FannedCardHandView(
                    cards: humanPlayer.hand,
                    selectedCard: selectedCard,
                    validMoves: gameViewModel.validMoves,
                    onCardTapped: { card in
                        if gameViewModel.validMoves.contains(card) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                selectedCard = card
                            }
                        }
                    }
                )
                .frame(height: 180)

                playerInfoHeader(playerIndex: 0, position: .bottom)
            }
        }
        .padding(.bottom, 8)
        .padding(.horizontal)
    }

    // MARK: - Player Info Header

    private func playerInfoHeader(playerIndex: Int, position: PlayerPosition) -> some View {
        guard playerIndex < gameViewModel.players.count else {
            return AnyView(EmptyView())
        }

        let player = gameViewModel.players[playerIndex]
        let isCurrentPlayer = gameViewModel.gameState.currentPlayerIndex == playerIndex
        let isPartner = teamAIndices.contains(playerIndex)

        return AnyView(
            HStack(spacing: 8) {
                // Team indicator circle
                Circle()
                    .fill(isPartner ? RomanianColors.countrysideGreen : RomanianColors.primaryRed)
                    .frame(width: 12, height: 12)
                    .overlay(
                        Circle()
                            .stroke(isCurrentPlayer ? RomanianColors.goldAccent : Color.clear, lineWidth: 2)
                    )

                VStack(alignment: position == .right ? .trailing : .leading, spacing: 2) {
                    Text(player.name)
                        .font(.caption.weight(.semibold))
                        .foregroundColor(isPartner ? RomanianColors.countrysideGreen : .white)

                    Text("\(player.score) puncte")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.7))
                }

                if position == .bottom {
                    Spacer()
                    Text("Tu")
                        .font(.caption2.weight(.bold))
                        .foregroundColor(RomanianColors.goldAccent)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.black.opacity(0.4))
                        )
                } else if playerIndex == 2 {
                    Spacer()
                    Text("Partener")
                        .font(.caption2.weight(.bold))
                        .foregroundColor(RomanianColors.countrysideGreen)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.black.opacity(0.4))
                        )
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.black.opacity(0.5))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(
                                isPartner ? RomanianColors.countrysideGreen.opacity(0.5) : RomanianColors.primaryRed.opacity(0.3),
                                lineWidth: 1.5
                            )
                    )
            )
        )
    }

    // MARK: - Player Hand View

    private func playerHandView(playerIndex: Int, position: PlayerPosition) -> some View {
        let player = gameViewModel.players[playerIndex]
        let cardCount = player.hand.count

        return HStack(spacing: -8) {
            ForEach(0..<min(cardCount, 4), id: \.self) { index in
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
                    .frame(width: 40, height: 56)
                    .overlay(
                        Text("♦")
                            .font(.body)
                            .foregroundColor(RomanianColors.goldAccent.opacity(0.3))
                    )
                    .shadow(color: RomanianColors.primaryBlue.opacity(0.3), radius: 3, x: 0, y: 2)
                    .rotationEffect(rotationForPosition(position))
                    .offset(y: CGFloat(index % 2) * -3)
                    .zIndex(Double(index))
            }
        }
    }

    private func rotationForPosition(_ position: PlayerPosition) -> Angle {
        switch position {
        case .top: return .degrees(180)
        case .left: return .degrees(90)
        case .right: return .degrees(-90)
        case .bottom: return .degrees(0)
        }
    }

    // MARK: - Center Game Table

    private var centerGameTableArea: some View {
        VStack(spacing: 12) {
            // Game table with Romanian ornate frame
            ZStack {
                // Romanian ornate table surface
                OrnateRomanianTableSurface(size: CGSize(width: 300, height: 150))

                if !gameViewModel.tableCards.isEmpty {
                    FannedTableCardsView(
                        cards: gameViewModel.tableCards,
                        validMoves: gameViewModel.validMoves,
                        onCardTapped: { card in
                            if gameViewModel.validMoves.contains(card) {
                                onCardPlayed(card)
                            }
                        }
                    )
                } else {
                    // Empty table placeholder
                    VStack(spacing: 8) {
                        Text("♠♥♣♦")
                            .font(.title2)
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

                        Text("Masă de Joc")
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
            .frame(width: 320, height: 140)
        }
    }

    // MARK: - Team Score Overlay

    private var teamScoreOverlay: some View {
        VStack {
            HStack(spacing: 20) {
                // Team A score (Human + Partner)
                teamScoreCard(
                    teamName: "Echipa Ta",
                    score: teamAScore,
                    color: RomanianColors.countrysideGreen,
                    isLeading: teamAScore > teamBScore
                )

                // VS separator
                Text("VS")
                    .font(.caption.weight(.black))
                    .foregroundColor(RomanianColors.goldAccent)
                    .padding(8)
                    .background(
                        Circle()
                            .fill(Color.black.opacity(0.6))
                    )

                // Team B score (Opponents)
                teamScoreCard(
                    teamName: "Adversari",
                    score: teamBScore,
                    color: RomanianColors.primaryRed,
                    isLeading: teamBScore > teamAScore
                )
            }
            .padding(.horizontal)
            .padding(.top, 8)

            Spacer()
        }
    }

    private func teamScoreCard(teamName: String, score: Int, color: Color, isLeading: Bool) -> some View {
        VStack(spacing: 4) {
            Text(teamName)
                .font(.caption2.weight(.semibold))
                .foregroundColor(.white.opacity(0.8))

            Text("\(score)")
                .font(.title2.weight(.bold))
                .foregroundColor(color)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.6))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            isLeading ? RomanianColors.goldAccent : color.opacity(0.5),
                            lineWidth: isLeading ? 2 : 1
                        )
                )
        )
        .shadow(
            color: isLeading ? RomanianColors.goldAccent.opacity(0.4) : color.opacity(0.2),
            radius: isLeading ? 8 : 4,
            x: 0,
            y: 2
        )
    }
}

// MARK: - Supporting Types

enum PlayerPosition {
    case top, right, bottom, left
}

// MARK: - Preview Provider

#if DEBUG
struct FourPlayerGameLayout_Previews: PreviewProvider {
    static var previews: some View {
        FourPlayerPreview()
    }

    struct FourPlayerPreview: View {
        @StateObject private var viewModel: GameViewModel

        init() {
            let humanPlayer = Player(name: "Tu")
            let opponent1 = AIPlayer(name: "Adversar 1", difficulty: .medium)
            let partner = AIPlayer(name: "Partener", difficulty: .medium)
            let opponent2 = AIPlayer(name: "Adversar 2", difficulty: .medium)

            let gameState = GameState(players: [humanPlayer, opponent1, partner, opponent2])
            gameState.gameMode = .fourPlayers
            self._viewModel = StateObject(wrappedValue: GameViewModel(gameState: gameState))
        }

        var body: some View {
            FourPlayerGameLayout(
                gameViewModel: viewModel,
                selectedCard: .constant(nil),
                onCardPlayed: { _ in },
                onPass: { }
            )
        }
    }
}
#endif
