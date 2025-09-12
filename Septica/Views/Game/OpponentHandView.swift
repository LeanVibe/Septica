//
//  OpponentHandView.swift
//  Septica
//
//  View for displaying opponent's hand (back of cards)
//  Shows card count and current player indicator
//

import SwiftUI

/// View displaying opponent's hand with card backs only
struct OpponentHandView: View {
    let player: Player
    let isCurrentPlayer: Bool
    
    var body: some View {
        VStack(spacing: 8) {
            // Player info header
            HStack {
                // Player name with turn indicator
                HStack(spacing: 8) {
                    if isCurrentPlayer {
                        Circle()
                            .fill(Color.red)
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
                        .font(.caption.bold())
                        .foregroundColor(.white)
                }
            }
            .padding(.horizontal)
            
            // Card backs display
            HStack(spacing: -10) {
                ForEach(0..<player.hand.count, id: \.self) { index in
                    CardBackView()
                        .frame(width: 50, height: 70)
                        .offset(x: CGFloat(index * 2), y: CGFloat(index % 2 == 0 ? 0 : -2))
                        .zIndex(Double(index))
                }
            }
            .frame(height: 80)
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.3))
        )
        .padding(.horizontal)
    }
}

/// Simple card back view
struct CardBackView: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(
                LinearGradient(
                    colors: [
                        Color.blue.opacity(0.8),
                        Color.blue.opacity(0.6)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.3), radius: 2, x: 1, y: 1)
    }
}

// MARK: - Preview

struct OpponentHandView_Previews: PreviewProvider {
    static var previews: some View {
        let aiPlayer = AIPlayer(name: "AI Opponent")
        aiPlayer.hand = [
            Card(suit: .hearts, value: 7),
            Card(suit: .spades, value: 10),
            Card(suit: .clubs, value: 8),
            Card(suit: .diamonds, value: 12)
        ]
        aiPlayer.score = 3
        
        return OpponentHandView(player: aiPlayer, isCurrentPlayer: true)
            .preferredColorScheme(.dark)
            .background(Color.green.opacity(0.3))
    }
}