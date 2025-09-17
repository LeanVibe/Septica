//
//  OrganizedGameTableView.swift
//  Septica
//
//  Shuffle Cats-style card column organization system
//  Clean vertical columns with proper spacing and visual hierarchy
//

import SwiftUI

/// Shuffle Cats-inspired organized game table with clean card columns
struct OrganizedGameTableView: View {
    let tableCards: [Card]
    let validMoves: [Card]
    let onCardTapped: (Card) -> Void
    let animatingCard: Card?
    
    @State private var cardAnimations: [UUID: Bool] = [:]
    
    // Romanian cultural table configuration
    private let columnSpacing: CGFloat = 20
    private let cardSpacing: CGFloat = 8
    private let maxColumns = 5
    
    var body: some View {
        ZStack {
            // Enhanced ornate Romanian table surface with traditional folk art patterns
            OrnateRomanianTableSurface(size: CGSize(width: 350, height: 220))
            
            if !tableCards.isEmpty {
                // Clean card column organization (Shuffle Cats style)
                HStack(spacing: columnSpacing) {
                    ForEach(Array(organizedCardColumns.enumerated()), id: \.offset) { columnIndex, column in
                        VStack(spacing: cardSpacing) {
                            ForEach(Array(column.enumerated()), id: \.element.id) { cardIndex, card in
                                CardView(
                                    card: card,
                                    isSelected: false,
                                    isPlayable: validMoves.contains(card),
                                    isAnimating: animatingCard?.id == card.id,
                                    cardSize: .compact
                                )
                                .scaleEffect(cardAnimations[card.id] == true ? 1.05 : 1.0)
                                .animation(
                                    .spring(response: 0.4, dampingFraction: 0.8),
                                    value: cardAnimations[card.id]
                                )
                                .onAppear {
                                    // Staggered animation entrance
                                    let delay = Double(columnIndex) * 0.1 + Double(cardIndex) * 0.05
                                    DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                                        cardAnimations[card.id] = true
                                    }
                                }
                                .onTapGesture {
                                    if validMoves.contains(card) {
                                        onCardTapped(card)
                                    }
                                }
                                .zIndex(Double(cardIndex))
                            }
                        }
                        .frame(minHeight: 100) // Ensure consistent column height
                    }
                }
                .transition(.asymmetric(
                    insertion: .scale.combined(with: .opacity),
                    removal: .move(edge: .bottom).combined(with: .opacity)
                ))
            } else {
                // Enhanced ornate empty table placeholder
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
                        width: 140,
                        height: 8,
                        color: RomanianColors.primaryBlue.opacity(0.6)
                    )
                    .scaleEffect(0.8)
                    
                    // Romanian cultural title with enhanced styling
                    Text("Masa de Joc Organizată")
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
                    
                    // Traditional Romanian game instruction
                    VStack(spacing: 4) {
                        Text("Cărțile vor fi organizate în coloane")
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
            
            // Visual zone highlight for active column
            if let activeColumn = findActiveColumn() {
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        LinearGradient(
                            colors: [
                                RomanianColors.goldAccent.opacity(0.8),
                                RomanianColors.primaryYellow.opacity(0.6)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 2
                    )
                    .frame(width: 70, height: 120)
                    .offset(x: activeColumnOffset(activeColumn))
                    .animation(.easeInOut(duration: 0.3), value: activeColumn)
            }
        }
        .frame(width: 380, height: 240)
    }
    
    // MARK: - Card Organization Logic
    
    /// Organize cards into clean columns based on suit or strategic grouping
    private var organizedCardColumns: [[Card]] {
        guard !tableCards.isEmpty else { return [] }
        
        // Group cards by suit for better organization (Shuffle Cats style)
        let suitGroups = Dictionary(grouping: tableCards) { $0.suit }
        
        // Convert to ordered columns, ensuring max column limit
        var columns: [[Card]] = []
        let suits: [Suit] = [.hearts, .diamonds, .clubs, .spades]
        
        for suit in suits {
            if let cards = suitGroups[suit], !cards.isEmpty {
                // Sort cards by value within each suit
                let sortedCards = cards.sorted { $0.value < $1.value }
                columns.append(sortedCards)
                
                if columns.count >= maxColumns {
                    break
                }
            }
        }
        
        // If we have too few columns, group differently
        if columns.count < 2 && tableCards.count > 2 {
            // Fallback: Split cards into balanced columns
            let cardsPerColumn = max(1, tableCards.count / 2)
            let sortedCards = tableCards.sorted { $0.value < $1.value }
            
            columns = []
            for i in stride(from: 0, to: sortedCards.count, by: cardsPerColumn) {
                let endIndex = min(i + cardsPerColumn, sortedCards.count)
                columns.append(Array(sortedCards[i..<endIndex]))
            }
        }
        
        return columns
    }
    
    /// Find the active column based on current game state
    private func findActiveColumn() -> Int? {
        guard !organizedCardColumns.isEmpty else { return nil }
        
        // Highlight the column with the most recent card
        if let lastCard = tableCards.last {
            for (index, column) in organizedCardColumns.enumerated() {
                if column.contains(where: { $0.id == lastCard.id }) {
                    return index
                }
            }
        }
        
        return nil
    }
    
    /// Calculate offset for active column highlight
    private func activeColumnOffset(_ columnIndex: Int) -> CGFloat {
        let totalColumns = organizedCardColumns.count
        let centerOffset = CGFloat(columnIndex - totalColumns / 2) * (70 + columnSpacing)
        return centerOffset
    }
}

// MARK: - Romanian Cultural Table Configuration

extension OrganizedGameTableView {
    /// Romanian cultural configuration for card organization
    private var romanianTableConfiguration: (columnSpacing: CGFloat, cardSpacing: CGFloat, maxColumns: Int) {
        return (columnSpacing: 20, cardSpacing: 8, maxColumns: 5)
    }
}

// MARK: - Preview

struct OrganizedGameTableView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 40) {
            // Empty table
            OrganizedGameTableView(
                tableCards: [],
                validMoves: [],
                onCardTapped: { _ in },
                animatingCard: nil
            )
            
            // Table with organized cards
            OrganizedGameTableView(
                tableCards: [
                    Card(suit: .hearts, value: 10),
                    Card(suit: .hearts, value: 7),
                    Card(suit: .spades, value: 7),
                    Card(suit: .diamonds, value: 14),
                    Card(suit: .clubs, value: 8)
                ],
                validMoves: [Card(suit: .hearts, value: 7)],
                onCardTapped: { _ in },
                animatingCard: nil
            )
        }
        .padding()
        .background(Color.green.opacity(0.3))
        .previewLayout(.sizeThatFits)
    }
}