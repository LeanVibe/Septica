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
            // Romanian cultural table surface
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    RadialGradient(
                        colors: [
                            RomanianColors.tableGreen,
                            RomanianColors.tableGreen.opacity(0.8),
                            Color(red: 0.05, green: 0.25, blue: 0.05)
                        ],
                        center: .center,
                        startRadius: 30,
                        endRadius: 140
                    )
                )
                .overlay(
                    // Traditional Romanian pattern border
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
                            lineWidth: 3
                        )
                )
                .frame(width: 280, height: 180)
                .shadow(color: RomanianColors.primaryBlue.opacity(0.2), radius: 12, x: 0, y: 6)
            
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
                // Romanian cultural empty table placeholder
                VStack(spacing: 10) {
                    // Traditional Romanian card symbol
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
                        .shadow(color: RomanianColors.primaryBlue.opacity(0.3), radius: 2, x: 1, y: 1)
                    
                    // Romanian cultural title
                    Text("Zona de Joc")
                        .font(.headline.weight(.semibold))
                        .foregroundColor(RomanianColors.goldAccent)
                        .shadow(color: Color.black.opacity(0.5), radius: 1, x: 0, y: 1)
                    
                    // Traditional Romanian game instruction
                    Text("Cărțile jucate vor apărea aici")
                        .font(.caption.weight(.medium))
                        .foregroundColor(RomanianColors.primaryYellow.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .shadow(color: Color.black.opacity(0.3), radius: 1, x: 0, y: 1)
                }
            }
            
            // Romanian cultural top card highlight (for beating reference)
            if let topCard = tableCards.last, tableCards.count > 1 {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(
                        LinearGradient(
                            colors: [
                                RomanianColors.goldAccent,
                                RomanianColors.primaryYellow,
                                RomanianColors.goldAccent
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 3
                    )
                    .frame(width: 65, height: 91) // Match .normal card size (65 * 1.4 = 91)
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