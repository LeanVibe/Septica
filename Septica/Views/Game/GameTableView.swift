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
                .frame(width: 250, height: 150)
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
                    .frame(width: 68, height: 92)
                    .offset(
                        x: CGFloat((tableCards.count - 1) * 15) - CGFloat(tableCards.count * 7),
                        y: CGFloat((tableCards.count - 1) * 3) - CGFloat(tableCards.count * 1)
                    )
                    .rotationEffect(.degrees(Double((tableCards.count - 1) * 5) - Double(tableCards.count * 2)))
                    .animation(.easeInOut(duration: 0.3), value: topCard.id)
            }
        }
        .frame(width: 280, height: 180)
    }
}

/// View for displaying the result of a completed trick
struct GameResultView: View {
    let result: GameResult
    let playerNames: [String]
    let onNewGame: () -> Void
    let onMainMenu: () -> Void
    
    var body: some View {
        ZStack {
            // Background overlay
            Color.black.opacity(0.8)
                .ignoresSafeArea()
                .onTapGesture { } // Prevent tap-through
            
            // Result card
            VStack(spacing: 24) {
                // Game Over title
                Text("Game Over!")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                // Winner announcement or tie
                Group {
                    if let winnerId = result.winnerId {
                        VStack(spacing: 8) {
                            Text("🎉 Winner! 🎉")
                                .font(.title2)
                                .foregroundColor(.yellow)
                            
                            if let winnerName = getPlayerName(for: winnerId) {
                                Text(winnerName)
                                    .font(.title)
                                    .fontWeight(.bold)
                                    .foregroundColor(.green)
                            }
                            
                            if let winningScore = result.winningScore {
                                Text("Final Score: \(winningScore) points")
                                    .font(.headline)
                                    .foregroundColor(.white)
                            }
                        }
                    } else {
                        VStack(spacing: 8) {
                            Text("🤝 It's a Tie! 🤝")
                                .font(.title2)
                                .foregroundColor(.orange)
                            
                            Text("Great game!")
                                .font(.headline)
                                .foregroundColor(.white)
                        }
                    }
                }
                
                // Final scores
                VStack(alignment: .leading, spacing: 12) {
                    Text("Final Scores")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    ForEach(result.finalScores.sorted(by: { $0.value > $1.value }), id: \.key) { playerId, score in
                        HStack {
                            // Winner indicator
                            if playerId == result.winnerId {
                                Image(systemName: "crown.fill")
                                    .foregroundColor(.yellow)
                            } else {
                                Image(systemName: "person.fill")
                                    .foregroundColor(.gray)
                            }
                            
                            Text(getPlayerName(for: playerId) ?? "Unknown")
                                .font(.body)
                                .foregroundColor(.white)
                            
                            Spacer()
                            
                            Text("\(score)")
                                .font(.body.bold())
                                .foregroundColor(playerId == result.winnerId ? .yellow : .white)
                        }
                    }
                }
                .padding()
                .background(Color.black.opacity(0.5))
                .cornerRadius(12)
                
                // Game statistics
                VStack(alignment: .leading, spacing: 8) {
                    Text("Game Statistics")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                    
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Tricks Played:")
                            Text("Game Duration:")
                        }
                        .foregroundColor(.white.opacity(0.7))
                        
                        Spacer()
                        
                        VStack(alignment: .trailing) {
                            Text("\(result.totalTricks)")
                            Text(formatDuration(result.gameDuration))
                        }
                        .foregroundColor(.white)
                    }
                    .font(.caption)
                }
                .padding()
                .background(Color.black.opacity(0.3))
                .cornerRadius(8)
                
                // Action buttons
                VStack(spacing: 12) {
                    Button("New Game") {
                        onNewGame()
                    }
                    .buttonStyle(ResultButtonStyle(isPrimary: true))
                    
                    Button("Main Menu") {
                        onMainMenu()
                    }
                    .buttonStyle(ResultButtonStyle(isPrimary: false))
                }
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.black.opacity(0.9))
                    .stroke(Color.white.opacity(0.3), lineWidth: 2)
            )
            .padding(20)
        }
    }
    
    // MARK: - Helper Methods
    
    private func getPlayerName(for playerId: UUID) -> String? {
        // This would need to be passed in or retrieved from the game state
        // For now, return a placeholder
        return "Player"
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

/// Button style for result view buttons
struct ResultButtonStyle: ButtonStyle {
    let isPrimary: Bool
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .background(isPrimary ? Color.blue : Color.gray.opacity(0.6))
            .foregroundColor(.white)
            .font(.headline)
            .cornerRadius(12)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

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