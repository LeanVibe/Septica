//
//  PlayerHandView.swift
//  Septica
//
//  View for displaying a player's hand of cards
//  Supports card selection, drag interactions, and turn indicators
//

import SwiftUI

/// View displaying a player's hand with interactive cards
struct PlayerHandView: View {
    let player: Player
    let selectedCard: Card?
    let validMoves: [Card]
    let onCardSelected: (Card) -> Void
    let onCardPlayed: (Card) -> Void
    let isCurrentPlayer: Bool
    let isInteractionEnabled: Bool
    
    @State private var dragOffset: CGSize = .zero
    @State private var draggedCard: Card?
    
    var body: some View {
        VStack(spacing: 12) {
            // Player info header
            HStack {
                // Player name with turn indicator
                HStack(spacing: 8) {
                    if isCurrentPlayer {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 8, height: 8)
                            .scaleEffect(1.2)
                            .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: isCurrentPlayer)
                    }
                    
                    Text(player.name)
                        .font(.headline)
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                // Score display
                HStack(spacing: 4) {
                    Text("Score:")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                    
                    Text("\(player.score)")
                        .font(.headline)
                        .foregroundColor(.yellow)
                }
                
                // Hand count
                Text("(\(player.hand.count))")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
            }
            
            // Cards in hand
            if !player.hand.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: -10) {
                        ForEach(Array(player.hand.enumerated()), id: \.element.id) { index, card in
                            CardView(
                                card: card,
                                isSelected: selectedCard?.id == card.id,
                                isPlayable: isCardPlayable(card),
                                cardSize: .normal,
                                onTap: {
                                    handleCardTap(card)
                                }
                            )
                            .offset(y: selectedCard?.id == card.id ? -10 : 0)
                            .zIndex(selectedCard?.id == card.id ? 1 : 0)
                            .rotation3DEffect(
                                .degrees(Double(index - player.hand.count/2) * 5),
                                axis: (x: 0, y: 0, z: 1)
                            )
                            .offset(y: CGFloat(abs(index - player.hand.count/2)) * -2)
                        }
                    }
                    .padding(.horizontal, 20)
                }
            } else {
                // Empty hand placeholder
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.white.opacity(0.3), style: StrokeStyle(lineWidth: 2, dash: [5]))
                    .frame(height: 84)
                    .overlay(
                        Text("No cards")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.5))
                    )
            }
            
            // Action hint
            if isCurrentPlayer && isInteractionEnabled {
                Text("Tap a card to select, tap again to play")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.7))
                    .transition(.opacity)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.black.opacity(0.4))
                .stroke(
                    isCurrentPlayer ? Color.green.opacity(0.8) : Color.clear,
                    lineWidth: 2
                )
        )
        .animation(.easeInOut(duration: 0.3), value: isCurrentPlayer)
    }
    
    // MARK: - Helper Methods
    
    /// Check if a card can be played
    private func isCardPlayable(_ card: Card) -> Bool {
        return isInteractionEnabled && validMoves.contains { validCard in
            validCard.suit == card.suit && validCard.value == card.value
        }
    }
    
    /// Handle card tap interaction
    private func handleCardTap(_ card: Card) {
        guard isInteractionEnabled else { return }
        
        if selectedCard?.id == card.id {
            // Card already selected - play it
            if isCardPlayable(card) {
                onCardPlayed(card)
            }
        } else {
            // Select the card
            if isCardPlayable(card) {
                onCardSelected(card)
            }
        }
    }
}

/// View for displaying opponent's hand (cards face down)
struct OpponentHandView: View {
    let player: Player
    let isCurrentPlayer: Bool
    
    var body: some View {
        VStack(spacing: 8) {
            // Player info
            HStack {
                HStack(spacing: 8) {
                    if isCurrentPlayer {
                        Circle()
                            .fill(Color.orange)
                            .frame(width: 6, height: 6)
                            .scaleEffect(1.2)
                            .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: isCurrentPlayer)
                    }
                    
                    Text(player.name)
                        .font(.subheadline)
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                Text("Score: \(player.score)")
                    .font(.caption)
                    .foregroundColor(.yellow)
                
                Text("(\(player.hand.count))")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.6))
            }
            
            // Face-down cards
            if !player.hand.isEmpty {
                HStack(spacing: -8) {
                    ForEach(0..<Swift.min(player.hand.count, 8), id: \.self) { index in
                        CardBackView(cardSize: .small)
                            .rotation3DEffect(
                                .degrees(Double(index - player.hand.count/2) * 3),
                                axis: (x: 0, y: 0, z: 1)
                            )
                            .offset(y: CGFloat(abs(index - player.hand.count/2)) * -1)
                    }
                    
                    // Show count if more than 8 cards
                    if player.hand.count > 8 {
                        Text("+\(player.hand.count - 8)")
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.7))
                            .padding(.horizontal, 8)
                    }
                }
            } else {
                // Empty hand
                Text("No cards")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.5))
                    .padding(.vertical, 8)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.3))
                .stroke(
                    isCurrentPlayer ? Color.orange.opacity(0.6) : Color.clear,
                    lineWidth: 1.5
                )
        )
        .animation(.easeInOut(duration: 0.3), value: isCurrentPlayer)
    }
}

// MARK: - Preview

struct PlayerHandView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 40) {
            // Human player hand
            PlayerHandView(
                player: {
                    let player = Player(name: "Player 1")
                    player.hand = [
                        Card(suit: .hearts, value: 10),
                        Card(suit: .spades, value: 7),
                        Card(suit: .diamonds, value: 14),
                        Card(suit: .clubs, value: 11)
                    ]
                    player.score = 3
                    return player
                }(),
                selectedCard: Card(suit: .spades, value: 7),
                validMoves: [
                    Card(suit: .spades, value: 7),
                    Card(suit: .hearts, value: 10)
                ],
                onCardSelected: { _ in },
                onCardPlayed: { _ in },
                isCurrentPlayer: true,
                isInteractionEnabled: true
            )
            
            // Opponent hand
            OpponentHandView(
                player: {
                    let player = AIPlayer(name: "AI Player")
                    player.hand = [
                        Card(suit: .hearts, value: 8),
                        Card(suit: .spades, value: 9),
                        Card(suit: .diamonds, value: 12)
                    ]
                    player.score = 2
                    return player
                }(),
                isCurrentPlayer: false
            )
        }
        .padding()
        .background(Color.green.opacity(0.3))
        .previewLayout(.sizeThatFits)
    }
}