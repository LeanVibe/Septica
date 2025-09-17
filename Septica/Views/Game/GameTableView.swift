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
            // Enhanced ornate Romanian table surface with traditional folk art patterns
            OrnateRomanianTableSurface(size: CGSize(width: 280, height: 180))
            
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
                // Enhanced ornate empty table placeholder with traditional Romanian folk art
                VStack(spacing: 12) {
                    // Traditional Romanian decorative pattern
                    HStack(spacing: 8) {
                        RomanianOrnatePatternSystem.RomanianFlowerPattern(
                            size: 20,
                            color: RomanianColors.goldAccent.opacity(0.8)
                        )
                        
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
                        
                        RomanianOrnatePatternSystem.RomanianFlowerPattern(
                            size: 20,
                            color: RomanianColors.goldAccent.opacity(0.8)
                        )
                    }
                    
                    // Ornate separator line
                    RomanianOrnatePatternSystem.RomanianBorderPattern(
                        width: 120,
                        height: 8,
                        color: RomanianColors.primaryBlue.opacity(0.6)
                    )
                    .scaleEffect(0.8)
                    
                    // Romanian cultural title with enhanced styling
                    Text("Zona de Joc")
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
                    
                    // Traditional Romanian game instruction with ornate styling
                    VStack(spacing: 4) {
                        Text("Cărțile jucate vor apărea aici")
                            .font(.caption.weight(.medium))
                            .foregroundColor(RomanianColors.primaryYellow.opacity(0.9))
                            .multilineTextAlignment(.center)
                            .shadow(color: Color.black.opacity(0.4), radius: 1, x: 0, y: 1)
                        
                        // Traditional Romanian decorative element
                        RomanianOrnatePatternSystem.RomanianCrossPattern(
                            size: 12,
                            color: RomanianColors.primaryRed.opacity(0.7)
                        )
                    }
                }
            }
            
            // Enhanced ornate top card highlight with traditional Romanian patterns
            if let topCard = tableCards.last, tableCards.count > 1 {
                ZStack {
                    // Main ornate border
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
                    
                    // Traditional Romanian corner decorations
                    VStack {
                        HStack {
                            RomanianOrnatePatternSystem.RomanianFlowerPattern(
                                size: 8,
                                color: RomanianColors.primaryRed.opacity(0.8)
                            )
                            .offset(x: -2, y: -2)
                            
                            Spacer()
                            
                            RomanianOrnatePatternSystem.RomanianCrossPattern(
                                size: 8,
                                color: RomanianColors.primaryBlue.opacity(0.8)
                            )
                            .offset(x: 2, y: -2)
                        }
                        
                        Spacer()
                        
                        HStack {
                            RomanianOrnatePatternSystem.RomanianDiamondPattern(
                                size: 8,
                                color: RomanianColors.goldAccent.opacity(0.8)
                            )
                            .offset(x: -2, y: 2)
                            
                            Spacer()
                            
                            RomanianOrnatePatternSystem.RomanianFlowerPattern(
                                size: 8,
                                color: RomanianColors.primaryYellow.opacity(0.8)
                            )
                            .offset(x: 2, y: 2)
                        }
                    }
                    .frame(width: 65, height: 91)
                }
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