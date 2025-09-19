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
    let gamePhase: SepticaGamePhase
    
    @State private var pulseAnimation = false
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.black.opacity(0.55),
                            RomanianColors.primaryBlue.opacity(0.25),
                            Color.black.opacity(0.6)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    RomanianColors.goldAccent.opacity(0.7),
                                    RomanianColors.primaryYellow.opacity(0.4),
                                    RomanianColors.goldAccent.opacity(0.7)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                )
                .shadow(color: RomanianColors.primaryBlue.opacity(0.3), radius: 12, x: 0, y: 6)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            Color.white.opacity(0.08),
                            lineWidth: 0.5
                        )
                )
            
            HStack(alignment: .center, spacing: 18) {
                ScoreBadgeView(
                    player: opponentPlayer,
                    alignment: .leading,
                    isHighlighted: false,
                    pulse: $pulseAnimation
                )
                
                Spacer(minLength: 12)
                
                RoundStatusBadge(
                    gameRound: gameRound,
                    totalRounds: totalRounds,
                    turnTimeRemaining: turnTimeRemaining,
                    totalTurnTime: totalTurnTime,
                    gamePhaseText: gamePhaseText
                )
                .frame(width: 130)
                
                Spacer(minLength: 12)
                
                ScoreBadgeView(
                    player: currentPlayer,
                    alignment: .trailing,
                    isHighlighted: true,
                    pulse: $pulseAnimation
                )
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
        }
        .onAppear { pulseAnimation = true }
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

// MARK: - Supporting Views

private enum ScoreBadgeAlignment {
    case leading
    case trailing
}

private struct ScoreBadgeView: View {
    let player: Player
    let alignment: ScoreBadgeAlignment
    let isHighlighted: Bool
    @Binding var pulse: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            if alignment == .leading {
                avatar
                infoStack(alignment: .leading)
            } else {
                infoStack(alignment: .trailing)
                avatar
            }
        }
    }
    
    private var avatar: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color(hex: player.currentArena.primaryColor).opacity(0.75),
                            Color(hex: player.currentArena.accentColor).opacity(0.4)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 68, height: 68)
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.25), lineWidth: 1.5)
                )
                .shadow(color: .black.opacity(0.4), radius: 6, x: 0, y: 4)
                .scaleEffect(isHighlighted ? (pulse ? 1.05 : 1.0) : 1.0)
                .animation(
                    isHighlighted ? .easeInOut(duration: 1.0).repeatForever(autoreverses: true) : .default,
                    value: pulse
                )
                .overlay(
                    RomanianPlayerAvatarView(
                        avatar: player.romanianAvatar,
                        frame: player.avatarFrame,
                        level: player.playerLevel,
                        arena: player.currentArena,
                        isCurrentPlayer: isHighlighted
                    )
                    .frame(width: 68, height: 68)
                )
        }
    }
    
    private func infoStack(alignment: HorizontalAlignment) -> some View {
        VStack(alignment: alignment, spacing: 8) {
            HStack(spacing: 6) {
                if alignment == .trailing { Spacer() }
                Text(player.name)
                    .font(.headline.weight(.semibold))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.4), radius: 2, x: 0, y: 1)
                Spacer(minLength: 0)
                HStack(spacing: 6) {
                    Text("🇷🇴")
                        .font(.subheadline)
                    Image(systemName: "wifi")
                        .font(.caption)
                        .foregroundColor(RomanianColors.primaryYellow.opacity(0.85))
                }
                if alignment == .leading { Spacer() }
            }
            
            HStack(spacing: 6) {
                if alignment == .trailing { Spacer() }
                Label("\(player.score)", systemImage: "star.fill")
                    .font(.subheadline.weight(.semibold))
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
                Text("puncte")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                if alignment == .leading { Spacer() }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.08),
                                Color.white.opacity(0.03)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.12), lineWidth: 1)
                    )
            )
        }
        .frame(maxWidth: 170)
    }
}

private struct RoundStatusBadge: View {
    let gameRound: Int
    let totalRounds: Int
    let turnTimeRemaining: TimeInterval
    let totalTurnTime: TimeInterval
    let gamePhaseText: String
    
    private var roundProgress: Double {
        guard totalRounds > 0 else { return 0 }
        return min(max(Double(gameRound - 1) / Double(totalRounds), 0), 1)
    }
    
    private var turnProgress: Double {
        guard totalTurnTime > 0 else { return 0 }
        return max(min(turnTimeRemaining / totalTurnTime, 1), 0)
    }
    
    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.black.opacity(0.45),
                                Color.black.opacity(0.75)
                            ],
                            center: .center,
                            startRadius: 4,
                            endRadius: 60
                        )
                    )
                    .frame(width: 82, height: 82)
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.08), lineWidth: 1)
                    )
                
                Circle()
                    .trim(from: 0, to: roundProgress)
                    .stroke(
                        LinearGradient(
                            colors: [
                                RomanianColors.primaryYellow,
                                RomanianColors.goldAccent
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        style: StrokeStyle(lineWidth: 6, lineCap: .round)
                    )
                    .frame(width: 82, height: 82)
                    .rotationEffect(.degrees(-90))
                
                Circle()
                    .trim(from: 0, to: turnProgress)
                    .stroke(
                        LinearGradient(
                            colors: [
                                RomanianColors.countrysideGreen,
                                RomanianColors.primaryYellow
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        style: StrokeStyle(lineWidth: 3, lineCap: .round)
                    )
                    .frame(width: 60, height: 60)
                    .rotationEffect(.degrees(-90))
                
                VStack(spacing: 2) {
                    Text("\(Int(max(turnTimeRemaining, 0)))s")
                        .font(.headline.weight(.bold))
                        .foregroundColor(.white)
                    Text("Timp")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            
            Text("Runda \(gameRound)/\(totalRounds)")
                .font(.footnote.weight(.semibold))
                .foregroundColor(.white)
            
            Text(gamePhaseText)
                .font(.caption2)
                .foregroundColor(.white.opacity(0.7))
        }
    }
}

// MARK: - Game Phase Enum

enum SepticaGamePhase {
    case dealing
    case playing
    case roundEnd
    case gameEnd
}

// MARK: - Preview

struct GameStatusView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            GameStatusView(
                currentPlayer: {
                    let player = Player(name: "Jucător")
                    player.score = 2
                    return player
                }(),
                opponentPlayer: {
                    let opponent = Player(name: "Computer")
                    opponent.score = 1
                    return opponent
                }(),
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
