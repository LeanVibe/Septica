//
//  GameStatusView.swift
//  Septica
//
//  Professional game status bar for high production value gameplay
//  Shows game state, turn indicators, and Romanian cultural elements
//

import SwiftUI

/// High production value game status bar with Romanian cultural elements
struct GameStatusView: View {
    let currentPlayer: Player
    let opponentPlayer: Player
    let gameRound: Int
    let totalRounds: Int
    let turnTimeRemaining: TimeInterval
    let totalTurnTime: TimeInterval
    let gamePhase: GamePhase
    
    @State private var pulseAnimation = false
    
    var body: some View {
        HStack {
            // Opponent status with Romanian styling
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    // Romanian-style player indicator
                    Circle()
                        .fill(
                            currentPlayer.name != opponentPlayer.name ? 
                                RomanianColors.goldAccent : 
                                RomanianColors.primaryBlue.opacity(0.3)
                        )
                        .frame(width: 8, height: 8)
                        .scaleEffect(currentPlayer.name != opponentPlayer.name ? (pulseAnimation ? 1.3 : 1.0) : 1.0)
                        .animation(
                            currentPlayer.name != opponentPlayer.name ? 
                                .easeInOut(duration: 0.8).repeatForever(autoreverses: true) : 
                                .easeInOut(duration: 0.3),
                            value: pulseAnimation
                        )
                    
                    Text(opponentPlayer.name)
                        .font(.caption.weight(.semibold))
                        .foregroundColor(RomanianColors.primaryYellow.opacity(0.9))
                }
                
                // Romanian score display
                HStack(spacing: 4) {
                    Text("Puncte:")
                        .font(.caption2)
                        .foregroundColor(RomanianColors.primaryYellow.opacity(0.7))
                    
                    Text("\(opponentPlayer.score)")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [RomanianColors.goldAccent, RomanianColors.primaryYellow],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                }
            }
            
            Spacer()
            
            // Center - Romanian game information
            VStack(spacing: 6) {
                // Traditional Romanian game title
                Text("SEPTICA")
                    .font(.headline.weight(.black))
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
                    .shadow(color: RomanianColors.primaryBlue.opacity(0.4), radius: 2, x: 0, y: 1)
                
                // Game phase with Romanian context
                HStack(spacing: 4) {
                    Text(gamePhaseText)
                        .font(.caption2.weight(.medium))
                        .foregroundColor(RomanianColors.primaryYellow.opacity(0.8))
                    
                    Text("•")
                        .foregroundColor(RomanianColors.goldAccent.opacity(0.6))
                    
                    Text("Runda \(gameRound)/\(totalRounds)")
                        .font(.caption2.weight(.medium))
                        .foregroundColor(RomanianColors.primaryYellow.opacity(0.8))
                }
            }
            
            Spacer()
            
            // Turn timer with Romanian styling
            VStack(alignment: .trailing, spacing: 4) {
                // Circular timer indicator
                ZStack {
                    Circle()
                        .stroke(RomanianColors.primaryBlue.opacity(0.3), lineWidth: 3)
                        .frame(width: 32, height: 32)
                    
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(
                            progress > 0.5 ? RomanianColors.countrysideGreen :
                            progress > 0.2 ? RomanianColors.primaryYellow : RomanianColors.primaryRed,
                            lineWidth: 3
                        )
                        .frame(width: 32, height: 32)
                        .rotationEffect(.degrees(-90))
                        .animation(.linear(duration: 1), value: progress)
                    
                    Text("\(Int(turnTimeRemaining))")
                        .font(.caption.weight(.bold))
                        .foregroundColor(
                            progress > 0.2 ? RomanianColors.goldAccent : RomanianColors.primaryRed
                        )
                }
                
                // Turn indicator text
                Text("Timpul")
                    .font(.caption2)
                    .foregroundColor(RomanianColors.primaryYellow.opacity(0.7))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.black.opacity(0.4),
                            RomanianColors.primaryBlue.opacity(0.15),
                            Color.black.opacity(0.5)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    RomanianColors.goldAccent.opacity(0.4),
                                    RomanianColors.primaryYellow.opacity(0.2),
                                    RomanianColors.goldAccent.opacity(0.4)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
        .shadow(color: RomanianColors.primaryBlue.opacity(0.2), radius: 6, x: 0, y: 3)
        .onAppear {
            pulseAnimation = true
        }
    }
    
    // MARK: - Helper Properties
    
    private var progress: Double {
        turnTimeRemaining / totalTurnTime
    }
    
    private var gamePhaseText: String {
        switch gamePhase {
        case .dealing:
            return "Împărțirea cărților"
        case .playing:
            return "Joc activ"
        case .roundEnd:
            return "Sfârșitul rundei"
        case .gameEnd:
            return "Joc terminat"
        }
    }
}

// MARK: - Game Phase Enum

enum GamePhase {
    case dealing
    case playing
    case roundEnd
    case gameEnd
}

// MARK: - Preview

struct GameStatusView_Previews: PreviewProvider {
    static var previews: some View {
        let player = Player(name: "Jucător")
        player.score = 2
        
        let opponent = Player(name: "Computer")
        opponent.score = 1
        
        VStack(spacing: 20) {
            GameStatusView(
                currentPlayer: player,
                opponentPlayer: opponent,
                gameRound: 3,
                totalRounds: 5,
                turnTimeRemaining: 25,
                totalTurnTime: 30,
                gamePhase: .playing
            )
            
            Spacer()
        }
        .padding()
        .background(Color.green.opacity(0.3))
    }
}