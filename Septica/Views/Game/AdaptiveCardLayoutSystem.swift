//
//  AdaptiveCardLayoutSystem.swift
//  Septica
//
//  Advanced adaptive card placement and orientation system
//  Supports variable hand sizes, multiplayer, and premium visual quality
//

import SwiftUI

/// Comprehensive card layout system inspired by reference game design
struct AdaptiveCardLayoutSystem {

    // MARK: - Layout Configuration

    /// Card placement configuration based on hand size
    static func cardPlacementConfiguration(for handSize: Int) -> CardPlacementConfig {
        switch handSize {
        case 1...3:
            return CardPlacementConfig(
                baseRotation: 0,
                rotationSpread: 3,
                verticalOffset: 8,
                horizontalSpacing: 45,
                fanCurve: 0.3,
                scaleCenterCard: 1.08,
                scaleOuterCards: 0.96
            )
        case 4...6:
            return CardPlacementConfig(
                baseRotation: 0,
                rotationSpread: 5,
                verticalOffset: 12,
                horizontalSpacing: 38,
                fanCurve: 0.5,
                scaleCenterCard: 1.06,
                scaleOuterCards: 0.98
            )
        case 7...9:
            return CardPlacementConfig(
                baseRotation: 0,
                rotationSpread: 7,
                verticalOffset: 16,
                horizontalSpacing: 32,
                fanCurve: 0.7,
                scaleCenterCard: 1.04,
                scaleOuterCards: 0.99
            )
        case 10...12:
            return CardPlacementConfig(
                baseRotation: 0,
                rotationSpread: 9,
                verticalOffset: 20,
                horizontalSpacing: 28,
                fanCurve: 0.9,
                scaleCenterCard: 1.02,
                scaleOuterCards: 1.0
            )
        default:
            return CardPlacementConfig(
                baseRotation: 0,
                rotationSpread: 11,
                verticalOffset: 24,
                horizontalSpacing: 24,
                fanCurve: 1.1,
                scaleCenterCard: 1.0,
                scaleOuterCards: 0.98
            )
        }
    }

    /// Calculate card position and transformation for human player
    static func humanPlayerCardTransform(
        for index: Int,
        in handSize: Int,
        isSelected: Bool,
        cardSize: CGSize
    ) -> CardTransform {
        let config = cardPlacementConfiguration(for: handSize)

        // Calculate position in fan layout
        let centerIndex = Double(handSize - 1) / 2.0
        let offsetFromCenter = Double(index) - centerIndex

        // Rotation calculation (fan effect)
        let rotation = offsetFromCenter * config.rotationSpread

        // Vertical offset for curve
        let yOffset = abs(offsetFromCenter) * config.verticalOffset

        // Scale based on position
        let normalizedDistance = abs(offsetFromCenter) / centerIndex
        let scale = config.scaleCenterCard - (normalizedDistance * (config.scaleCenterCard - config.scaleOuterCards))

        // Horizontal spacing
        let xOffset = offsetFromCenter * config.horizontalSpacing

        // Selection enhancement
        let selectionScale = isSelected ? 1.12 : 1.0
        let selectionOffset = isSelected ? -15 : 0

        return CardTransform(
            position: CGPoint(
                x: xOffset,
                y: selectionOffset - yOffset
            ),
            rotation: Angle.degrees(rotation),
            scale: scale * selectionScale,
            zOffset: isSelected ? 20 : Double(index)
        )
    }

    /// Calculate card position and transformation for opponent
    static func opponentCardTransform(
        for index: Int,
        in handSize: Int,
        cardSize: CGSize
    ) -> CardTransform {
        let config = cardPlacementConfiguration(for: handSize)

        // Opponent cards have tighter spacing and less dramatic fan
        let centerIndex = Double(handSize - 1) / 2.0
        let offsetFromCenter = Double(index) - centerIndex

        let rotation = offsetFromCenter * (config.rotationSpread * 0.4)
        let xOffset = offsetFromCenter * (config.horizontalSpacing * 0.7)
        let yOffset = abs(offsetFromCenter) * (config.verticalOffset * 0.3)

        return CardTransform(
            position: CGPoint(x: xOffset, y: -yOffset),
            rotation: Angle.degrees(rotation),
            scale: 0.85, // Opponent cards are smaller
            zOffset: Double(index)
        )
    }

    /// Table position calculation for circular layout
    static func tableCardTransform(
        for card: TableCard,
        at position: TablePosition,
        tableSize: CGSize
    ) -> CardTransform {
        let cardSize = CGSize(width: 60, height: 84) // Smaller for table

        switch position {
        case .center:
            return CardTransform(
                position: .zero,
                rotation: .zero,
                scale: 1.0,
                zOffset: card.playOrder * 10
            )
        case .playerSide(let playerIndex):
            // Position cards around the table based on player position
            let angle = calculateTableAngle(for: playerIndex)
            let radius = min(tableSize.width, tableSize.height) * 0.15

            return CardTransform(
                position: CGPoint(
                    x: cos(angle) * radius,
                    y: sin(angle) * radius
                ),
                rotation: Angle.degrees(angle * 180 / .pi),
                scale: 0.9,
                zOffset: card.playOrder * 10
            )
        case .leftSide(let index):
            return CardTransform(
                position: CGPoint(x: -80 - CGFloat(index) * 65, y: 0),
                rotation: Angle.degrees(-5),
                scale: 0.85,
                zOffset: index
            )
        case .rightSide(let index):
            return CardTransform(
                position: CGPoint(x: 80 + CGFloat(index) * 65, y: 0),
                rotation: Angle.degrees(5),
                scale: 0.85,
                zOffset: index
            )
        }
    }

    // MARK: - Helper Methods

    private static func calculateTableAngle(for playerIndex: Int) -> Double {
        switch playerIndex {
        case 0: return 0           // Bottom (human player)
        case 1: return .pi         // Top
        case 2: return .pi * 1.5   // Left
        case 3: return .pi * 0.5   // Right
        default: return 0
        }
    }
}

// MARK: - Supporting Types

struct CardPlacementConfig {
    let baseRotation: Double
    let rotationSpread: Double
    let verticalOffset: Double
    let horizontalSpacing: Double
    let fanCurve: Double
    let scaleCenterCard: Double
    let scaleOuterCards: Double
}

struct CardTransform {
    let position: CGPoint
    let rotation: Angle
    let scale: Double
    let zOffset: Double
}

struct TableCard {
    let card: Card
    let playOrder: Int
    let isWinning: Bool
}

enum TablePosition {
    case center
    case playerSide(Int)
    case leftSide(Int)
    case rightSide(Int)
}

// MARK: - Adaptive Player Hand View

struct AdaptivePlayerHandView: View {
    let player: Player
    let selectedCard: Card?
    let validMoves: [Card]
    let onCardSelected: (Card) -> Void
    let onCardPlayed: (Card) -> Void
    let isCurrentPlayer: Bool
    let isInteractionEnabled: Bool
    let playerType: PlayerType

    @State private var dragOffset: CGSize = .zero
    @State private var draggedCard: Card?

    var body: some View {
        VStack(spacing: 0) {
            // Player header with avatar and emote system
            playerHeader

            // Adaptive card layout
            if !player.hand.isEmpty {
                adaptiveCardLayout
            } else {
                emptyHandPlaceholder
            }

            // Action hints for current player
            if isCurrentPlayer && isInteractionEnabled && playerType == .human {
                actionHints
            }
        }
    }

    // MARK: - Player Header with Avatar System

    private var playerHeader: some View {
        HStack(spacing: 12) {
            // Avatar with emote system
            AvatarWithEmotesView(
                player: player,
                playerType: playerType,
                isCurrentPlayer: isCurrentPlayer
            )
            .scaleEffect(playerType == .human ? 1.0 : 0.8)

            // Player info
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    if isCurrentPlayer {
                        turnIndicator
                    }

                    Text(player.name)
                        .font(.headline.weight(.semibold))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 1)

                    if playerType != .human {
                        PlayerTypeBadge(type: playerType)
                    }
                }

                // Card count and score
                HStack(spacing: 12) {
                    Label("\(player.hand.count)", systemImage: "rectangle.stack.fill")
                        .font(.caption.weight(.medium))
                        .foregroundColor(.white.opacity(0.9))

                    Label("\(player.score)", systemImage: "star.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [RomanianColors.goldAccent, RomanianColors.primaryYellow],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                }
            }

            Spacer()

            // Multiplayer connection status
            if playerType != .human {
                ConnectionStatusView(player: player)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private var turnIndicator: some View {
        Circle()
            .fill(playerType == .human ? RomanianColors.countrysideGreen : RomanianColors.embroideryRed)
            .frame(width: 8, height: 8)
            .scaleEffect(1.2)
            .shadow(color: .white.opacity(0.8), radius: 4)
            .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: isCurrentPlayer)
    }

    // MARK: - Adaptive Card Layout

    private var adaptiveCardLayout: some View {
        GeometryReader { geometry in
            ZStack(alignment: .center) {
                // Background tray
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.08),
                                Color.white.opacity(0.03)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.white.opacity(0.12), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.4), radius: 12, x: 0, y: 6)

                // Cards in adaptive fan layout
                HStack(spacing: 0) {
                    ForEach(Array(player.hand.enumerated()), id: \.element.id) { index, card in
                        let transform = playerType == .human ?
                            AdaptiveCardLayoutSystem.humanPlayerCardTransform(
                                for: index,
                                in: player.hand.count,
                                isSelected: selectedCard?.id == card.id,
                                cardSize: CGSize(width: 70, height: 98)
                            ) :
                            AdaptiveCardLayoutSystem.opponentCardTransform(
                                for: index,
                                in: player.hand.count,
                                cardSize: CGSize(width: 70, height: 98)
                            )

                        CardView(
                            card: playerType == .human ? card : Card(suit: .clubs, value: 7), // Show back for opponents
                            isSelected: selectedCard?.id == card.id,
                            isPlayable: playerType == .human ? isCardPlayable(card) : false,
                            isAnimating: false,
                            cardSize: playerType == .human ? .normal : .small,
                            onTap: {
                                if playerType == .human {
                                    handleCardTap(card)
                                }
                            },
                            onDragChanged: playerType == .human ? handleCardDrag : nil,
                            onDragEnded: playerType == .human ? handleCardDrop : nil
                        )
                        .offset(transform.position)
                        .rotationEffect(transform.rotation)
                        .scaleEffect(transform.scale)
                        .zIndex(transform.zOffset)
                        .shadow(color: .black.opacity(0.3), radius: 6, x: 0, y: 4)
                    }
                }
                .frame(width: geometry.size.width - 60)
            }
        }
        .frame(height: playerType == .human ? 160 : 120)
    }

    private var emptyHandPlaceholder: some View {
        RoundedRectangle(cornerRadius: 12)
            .stroke(Color.white.opacity(0.3), style: StrokeStyle(lineWidth: 2, dash: [6]))
            .frame(height: 100)
            .overlay(
                Text("Fără cărți")
                    .font(.caption.weight(.medium))
                    .foregroundColor(.white.opacity(0.6))
            )
    }

    private var actionHints: some View {
        Text("Atinge o carte pentru a o selecta • Trage în sus pentru a juca")
            .font(.caption2.weight(.medium))
            .foregroundStyle(
                LinearGradient(
                    colors: [
                        RomanianColors.primaryYellow.opacity(0.9),
                        RomanianColors.goldAccent.opacity(0.7)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .shadow(color: .black.opacity(0.3), radius: 1, x: 0, y: 1)
            .multilineTextAlignment(.center)
            .transition(.opacity.combined(with: .move(edge: .bottom)))
    }

    // MARK: - Card Interaction Methods

    private func isCardPlayable(_ card: Card) -> Bool {
        return isInteractionEnabled && validMoves.contains { validCard in
            validCard.suit == card.suit && validCard.value == card.value
        }
    }

    private func handleCardTap(_ card: Card) {
        guard isInteractionEnabled else { return }

        if selectedCard?.id == card.id {
            if isCardPlayable(card) {
                onCardPlayed(card)
            }
        } else {
            if isCardPlayable(card) {
                onCardSelected(card)
            }
        }
    }

    private func handleCardDrag(card: Card, dragValue: DragGesture.Value) {
        guard isInteractionEnabled && isCardPlayable(card) else { return }

        if selectedCard?.id != card.id {
            onCardSelected(card)
        }

        draggedCard = card
        dragOffset = dragValue.translation
    }

    private func handleCardDrop(card: Card, dragValue: DragGesture.Value) {
        dragOffset = .zero

        guard isInteractionEnabled && isCardPlayable(card) else { return }

        let dragDistance = sqrt(pow(dragValue.translation.width, 2) + pow(dragValue.translation.height, 2))

        if dragDistance > 40 && dragValue.translation.height < -25 {
            onCardPlayed(card)
        }
    }
}

// MARK: - Supporting Views

enum PlayerType {
    case human
    case ai
    case remote
}

struct PlayerTypeBadge: View {
    let type: PlayerType

    var body: some View {
        Group {
            switch type {
            case .ai:
                Label("AI", systemImage: "cpu.fill")
                    .font(.caption2.weight(.bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        Capsule()
                            .fill(RomanianColors.primaryBlue)
                    )
            case .remote:
                Label("Online", systemImage: "wifi")
                    .font(.caption2.weight(.bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        Capsule()
                            .fill(RomanianColors.embroideryRed)
                    )
            case .human:
                EmptyView()
            }
        }
    }
}

struct ConnectionStatusView: View {
    let player: Player

    var body: some View {
        VStack(spacing: 4) {
            Circle()
                .fill(Color.green)
                .frame(width: 8, height: 8)
                .overlay(
                    Circle()
                        .stroke(Color.white, lineWidth: 1)
                )
                .shadow(color: .green.opacity(0.5), radius: 4)

            Text("🇷🇴")
                .font(.caption2)
        }
    }
}

// MARK: - Preview

struct AdaptiveCardLayoutSystem_Previews: PreviewProvider {
    static var previews: some View {
        let player = Player(name: "Player 1")
        player.hand = [
            Card(suit: .hearts, value: 10),
            Card(suit: .spades, value: 7),
            Card(suit: .diamonds, value: 14),
            Card(suit: .clubs, value: 11),
            Card(suit: .hearts, value: 8),
            Card(suit: .spades, value: 9)
        ]
        player.score = 2

        return VStack(spacing: 20) {
            AdaptivePlayerHandView(
                player: player,
                selectedCard: Card(suit: .spades, value: 7),
                validMoves: player.hand,
                onCardSelected: { _ in },
                onCardPlayed: { _ in },
                isCurrentPlayer: true,
                isInteractionEnabled: true,
                playerType: .human
            )

            AdaptivePlayerHandView(
                player: player,
                selectedCard: nil,
                validMoves: [],
                onCardSelected: { _ in },
                onCardPlayed: { _ in },
                isCurrentPlayer: false,
                isInteractionEnabled: false,
                playerType: .ai
            )
        }
        .padding()
        .background(
            LinearGradient(
                colors: [RomanianColors.primaryBlue, RomanianColors.cardBack],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
}