//
//  GameTableView.swift
//  Septica
//
//  Central game table view showing played cards and trick area
//  Displays current trick cards with animations
//

import SwiftUI

/// View for the central game table where cards are played
struct GameTableView: View {
    let tableCards: [Card]
    let validMoves: [Card]
    let onCardTapped: (Card) -> Void
    let animatingCard: Card?
    
    @State private var cardAnimations: [UUID: Bool] = [:]
    
    var body: some View {
        ZStack {
            // Table surface
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    RadialGradient(
                        colors: [
                            Color(red: 0.2, green: 0.4, blue: 0.2),
                            Color(red: 0.1, green: 0.3, blue: 0.1)
                        ],
                        center: .center,
                        startRadius: 50,
                        endRadius: 150
                    )
                )
                .stroke(Color.white.opacity(0.3), lineWidth: 2)
                .frame(width: 280, height: 180)
                .shadow(color: Color.black.opacity(0.3), radius: 10, x: 0, y: 5)
            
            // Table cards
            if !tableCards.isEmpty {
                ZStack {
                    ForEach(Array(tableCards.enumerated()), id: \.element.id) { index, card in
                        CardView(
                            card: card,
                            isSelected: false,
                            isPlayable: false,
                            isAnimating: animatingCard?.id == card.id,
                            cardSize: .normal
                        )
                        .offset(
                            x: CGFloat(index * 15) - CGFloat(tableCards.count * 7),
                            y: CGFloat(index * 3) - CGFloat(tableCards.count * 1)
                        )
                        .rotationEffect(.degrees(Double(index * 5) - Double(tableCards.count * 2)))
                        .scaleEffect(cardAnimations[card.id] == true ? 1.1 : 1.0)
                        .animation(
                            .spring(response: 0.5, dampingFraction: 0.7),
                            value: cardAnimations[card.id]
                        )
                        .onAppear {
                            // Animate card entrance
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                cardAnimations[card.id] = true
                            }
                        }
                        .zIndex(Double(index))
                    }
                }
                .transition(.asymmetric(
                    insertion: .scale.combined(with: .opacity),
                    removal: .move(edge: .bottom).combined(with: .opacity)
                ))
            } else {
                // Empty table placeholder
                VStack(spacing: 8) {
                    Image(systemName: "rectangle.dashed")
                        .font(.largeTitle)
                        .foregroundColor(.white.opacity(0.3))
                    
                    Text("Play Area")
                        .font(.headline)
                        .foregroundColor(.white.opacity(0.5))
                    
                    Text("Cards played will appear here")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.3))
                        .multilineTextAlignment(.center)
                }
            }
            
            // Top card highlight (for beating reference)
            if let topCard = tableCards.last, tableCards.count > 1 {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.yellow.opacity(0.8), lineWidth: 3)
                    .frame(width: 75, height: 117) // Match new .normal card size
                    .offset(
                        x: CGFloat((tableCards.count - 1) * 15) - CGFloat(tableCards.count * 7),
                        y: CGFloat((tableCards.count - 1) * 3) - CGFloat(tableCards.count * 1)
                    )
                    .rotationEffect(.degrees(Double((tableCards.count - 1) * 5) - Double(tableCards.count * 2)))
                    .animation(.easeInOut(duration: 0.3), value: topCard.id)
            }
        }
        .frame(width: 320, height: 200)
    }
}

// MARK: - Game Result View
// Note: GameResultView is defined in GameResultView.swift

// Note: ResultButtonStyle is defined in GameResultView.swift

// MARK: - Preview

struct GameTableView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 40) {
            // Empty table
            GameTableView(
                tableCards: [],
                validMoves: [],
                onCardTapped: { _ in },
                animatingCard: nil
            )
            
            // Table with cards
            GameTableView(
                tableCards: [
                    Card(suit: .hearts, value: 10),
                    Card(suit: .spades, value: 7),
                    Card(suit: .diamonds, value: 14)
                ],
                validMoves: [],
                onCardTapped: { _ in },
                animatingCard: nil
            )
        }
        .padding()
        .background(Color.green.opacity(0.3))
        .previewLayout(.sizeThatFits)
    }
}