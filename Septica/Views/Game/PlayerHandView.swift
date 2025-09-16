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
    let onDragStateChanged: ((Bool, CGPoint?, Bool) -> Void)?
    
    @State private var dragOffset: CGSize = .zero
    @State private var draggedCard: Card?
    
    var body: some View {
        VStack(spacing: 12) {
            // Player info header with Romanian avatar
            HStack {
                // Romanian Player Avatar (Shuffle Cats inspired)
                RomanianPlayerAvatarView(
                    avatar: player.romanianAvatar,
                    frame: player.avatarFrame,
                    level: player.playerLevel,
                    arena: player.currentArena,
                    isCurrentPlayer: isCurrentPlayer
                )
                .scaleEffect(0.8) // Slightly larger for human player
                
                // Player details
                VStack(alignment: .leading, spacing: 4) {
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
                    
                    // Romanian cultural hand count
                    Text("(\(player.hand.count) cărți)")
                        .font(.caption.weight(.medium))
                        .foregroundColor(Color(hex: player.currentArena.primaryColor).opacity(0.8))
                }
                
                Spacer()
                
                // Romanian cultural score display
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Puncte:")
                        .font(.caption.weight(.medium))
                        .foregroundColor(Color(hex: player.currentArena.primaryColor).opacity(0.9))
                    
                    Text("\(player.score)")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    Color(hex: player.currentArena.accentColor),
                                    Color(hex: player.currentArena.primaryColor)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .shadow(color: .black.opacity(0.4), radius: 1, x: 0, y: 1)
                }
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
                                },
                                onDragChanged: { dragValue in
                                    // Handle drag feedback - will implement drop zone highlighting
                                    handleCardDrag(card: card, dragValue: dragValue)
                                },
                                onDragEnded: { dragValue in
                                    // Handle card drop
                                    handleCardDrop(card: card, dragValue: dragValue)
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
    
    /// Handle drag changed event for visual feedback
    private func handleCardDrag(card: Card, dragValue: DragGesture.Value) {
        guard isInteractionEnabled && isCardPlayable(card) else { 
            // Invalid drag - notify with invalid state
            onDragStateChanged?(true, CGPoint(x: dragValue.location.x, y: dragValue.location.y), false)
            return 
        }
        
        // Select the card being dragged
        if selectedCard?.id != card.id {
            onCardSelected(card)
        }
        
        // Notify drag state change with position and validity
        let isValidDrop = dragValue.translation.height < -30 // Dragging upward toward play area
        onDragStateChanged?(
            true, 
            CGPoint(x: dragValue.location.x, y: dragValue.location.y), 
            isValidDrop && isCardPlayable(card)
        )
    }
    
    /// Handle drag ended event for card drop
    private func handleCardDrop(card: Card, dragValue: DragGesture.Value) {
        // Always notify that dragging has ended
        onDragStateChanged?(false, nil, false)
        
        guard isInteractionEnabled && isCardPlayable(card) else { return }
        
        // Calculate drag distance to determine if it was a deliberate drop
        let dragDistance = sqrt(pow(dragValue.translation.width, 2) + pow(dragValue.translation.height, 2))
        
        // If dragged far enough upward (toward play area), play the card
        if dragDistance > 50 && dragValue.translation.height < -30 {
            onCardPlayed(card)
        }
        // Otherwise, just select the card (short drag/tap behavior)
        else if selectedCard?.id != card.id {
            onCardSelected(card)
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
            isInteractionEnabled: true,
            onDragStateChanged: nil
        )
    }
    .padding()
    .background(Color.green.opacity(0.3))
}
