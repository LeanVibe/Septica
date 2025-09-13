//
//  GameResultView.swift
//  Septica
//
//  View for displaying game results and final scores
//  Shows winner, final scores, and game actions
//

import SwiftUI

/// View displaying final game results
struct GameResultView: View {
    let result: GameResult
    let playerNames: [String]
    let onNewGame: () -> Void
    let onMainMenu: () -> Void
    
    private var winnerName: String? {
        guard let winnerId = result.winnerId,
              let _ = playerNames.firstIndex(where: { _ in true }) else {
            return nil
        }
        return playerNames.first // Simplified for now
    }
    
    var body: some View {
        VStack(spacing: 24) {
            // Result header
            VStack(spacing: 12) {
                // Winner announcement or tie
                if let winner = winnerName {
                    Text("🎉 Game Over! 🎉")
                        .font(.title.bold())
                        .foregroundColor(.yellow)
                    
                    Text("\(winner) Wins!")
                        .font(.title2)
                        .foregroundColor(.white)
                } else {
                    Text("Game Over")
                        .font(.title.bold())
                        .foregroundColor(.white)
                    
                    Text("It's a Tie!")
                        .font(.title2)
                        .foregroundColor(.gray)
                }
            }
            
            // Scores section
            VStack(spacing: 16) {
                Text("Final Scores")
                    .font(.headline)
                    .foregroundColor(.white.opacity(0.9))
                
                VStack(spacing: 8) {
                    ForEach(result.finalScores.sorted(by: { $0.value > $1.value }), id: \.key) { playerId, score in
                        HStack {
                            // Player name (simplified - would need proper lookup)
                            Text("Player")
                                .font(.body)
                                .foregroundColor(.white)
                            
                            Spacer()
                            
                            Text("\(score)")
                                .font(.body.bold())
                                .foregroundColor(score == result.winningScore ? .yellow : .white)
                        }
                        .padding(.horizontal)
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.black.opacity(0.4))
                )
            }
            
            // Game stats
            VStack(spacing: 8) {
                HStack {
                    Text("Tricks Played:")
                        .foregroundColor(.white.opacity(0.8))
                    Spacer()
                    Text("\(result.totalTricks)")
                        .foregroundColor(.white)
                }
                
                HStack {
                    Text("Game Duration:")
                        .foregroundColor(.white.opacity(0.8))
                    Spacer()
                    Text(formatDuration(result.gameDuration))
                        .foregroundColor(.white)
                }
            }
            .font(.caption)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.black.opacity(0.3))
            )
            
            // Action buttons
            VStack(spacing: 12) {
                Button("New Game", action: onNewGame)
                    .buttonStyle(ResultButtonStyle(color: .green))
                
                Button("Main Menu", action: onMainMenu)
                    .buttonStyle(ResultButtonStyle(color: .blue))
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.black.opacity(0.9))
                .shadow(color: .black.opacity(0.5), radius: 10, x: 0, y: 5)
        )
        .padding()
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

/// Button style for result view actions
struct ResultButtonStyle: ButtonStyle {
    let color: Color
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .background(color)
            .foregroundColor(.white)
            .font(.headline)
            .cornerRadius(12)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Preview

struct GameResultView_Previews: PreviewProvider {
    static var previews: some View {
        let result = GameResult(
            winnerId: UUID(),
            finalScores: [UUID(): 5, UUID(): 3],
            totalTricks: 8,
            gameDuration: 245.0
        )
        
        return GameResultView(
            result: result,
            playerNames: ["Player 1", "AI Player"],
            onNewGame: {},
            onMainMenu: {}
        )
        .preferredColorScheme(.dark)
        .background(Color.green.opacity(0.3))
    }
}