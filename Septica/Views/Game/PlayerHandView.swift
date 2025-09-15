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
                
                // Romanian cultural score display
                HStack(spacing: 4) {
                    Text("Puncte:")
                        .font(.caption.weight(.medium))
                        .foregroundColor(RomanianColors.primaryYellow.opacity(0.9))
                    
                    Text("\(player.score)")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    RomanianColors.goldAccent,
                                    RomanianColors.primaryYellow
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .shadow(color: RomanianColors.primaryBlue.opacity(0.4), radius: 1, x: 0, y: 1)
                }
                
                // Romanian cultural hand count
                Text("(\(player.hand.count))")
                    .font(.caption.weight(.medium))
                    .foregroundColor(RomanianColors.primaryYellow.opacity(0.8))
            }
            
            // Cards in hand
            if !player.hand.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: -15) {
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
                    .frame(height: 300)
                }
                .frame(height: 300)
            } else {
                // Empty hand placeholder
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.white.opacity(0.3), style: StrokeStyle(lineWidth: 2, dash: [5]))
                    .frame(height: 84)
                    .overlay(
                        Text("Fără cărți")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.5))
                    )
            }
            
            // Romanian cultural action hint
            if isCurrentPlayer && isInteractionEnabled {
                Text("Atinge o carte pentru a o selecta, atinge din nou pentru a juca")
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
                    .shadow(color: Color.black.opacity(0.3), radius: 1, x: 0, y: 1)
                    .transition(.opacity)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.black.opacity(0.3),
                            RomanianColors.primaryBlue.opacity(0.1),
                            Color.black.opacity(0.4)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .stroke(
                    isCurrentPlayer ? 
                        LinearGradient(
                            colors: [
                                RomanianColors.goldAccent,
                                RomanianColors.primaryYellow,
                                RomanianColors.goldAccent
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ) :
                        LinearGradient(
                            colors: [Color.clear],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                    lineWidth: isCurrentPlayer ? 3 : 0
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

// MARK: - Preview

#Preview("Normal Player Hand") {
    let player = Player(name: "Player 1")
    player.hand = [
        Card(suit: .hearts, value: 10),
        Card(suit: .spades, value: 7),
        Card(suit: .diamonds, value: 14),
        Card(suit: .clubs, value: 11)
    ]
    player.score = 3
    return VStack(spacing: 40) {
        PlayerHandView(
            player: player,
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
    }
    .padding()
    .background(Color.green.opacity(0.3))
}
