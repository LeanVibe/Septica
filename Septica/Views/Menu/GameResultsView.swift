//
//  GameResultsView.swift
//  Septica
//
//  Game results view displayed after game completion
//  Shows final scores, winner, and options for next actions
//

import SwiftUI

/// Game results view shown when a game is completed
struct GameResultsView: View {
    @EnvironmentObject var navigationManager: NavigationManager
    let result: GameResult
    let session: GameSession
    @State private var animateResults = false
    @State private var showConfetti = false
    
    private var isPlayerWinner: Bool {
        guard let humanPlayer = session.gameState.players.first(where: { $0.isHuman }) else {
            return false
        }
        return result.winnerId == humanPlayer.id
    }
    
    private var winnerName: String {
        guard let winner = session.gameState.players.first(where: { $0.id == result.winnerId }) else {
            return "Unknown"
        }
        return winner.name
    }
    
    var body: some View {
        ZStack {
            // Romanian-themed background
            GameResultsBackground(isWinner: isPlayerWinner)
            
            VStack(spacing: 30) {
                Spacer(minLength: 40)
                
                // Main result display
                ResultHeaderView(
                    isWinner: isPlayerWinner,
                    winnerName: winnerName,
                    animated: $animateResults
                )
                
                // Score breakdown
                ScoreBreakdownView(
                    result: result,
                    players: session.gameState.players,
                    animated: $animateResults
                )
                
                // Game statistics
                GameStatsView(
                    session: session,
                    animated: $animateResults
                )
                
                // Action buttons
                ActionButtonsView()
                    .opacity(animateResults ? 1.0 : 0.0)
                    .animation(.easeInOut.delay(1.5), value: animateResults)
                
                Spacer(minLength: 40)
            }
            .padding(.horizontal, 20)
            
            // Confetti effect for wins
            if showConfetti && isPlayerWinner {
                ConfettiView()
                    .allowsHitTesting(false)
            }
        }
        .navigationBarHidden(true)
        .preferredColorScheme(.dark)
        .onAppear {
            animateResults = true
            if isPlayerWinner {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    showConfetti = true
                }
            }
        }
    }
}

// MARK: - Result Components

/// Header showing win/loss result
struct ResultHeaderView: View {
    let isWinner: Bool
    let winnerName: String
    @Binding var animated: Bool
    
    var body: some View {
        VStack(spacing: 16) {
            // Trophy or defeat icon
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: isWinner ? [
                                Color.yellow.opacity(0.3),
                                Color.orange.opacity(0.2),
                                Color.clear
                            ] : [
                                Color.gray.opacity(0.3),
                                Color.gray.opacity(0.1),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 30,
                            endRadius: 80
                        )
                    )
                    .frame(width: 160, height: 160)
                
                Image(systemName: isWinner ? "trophy.fill" : "flag.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(
                        LinearGradient(
                            colors: isWinner ? [.yellow, .orange] : [.gray, .gray.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .scaleEffect(animated ? 1.0 : 0.3)
                    .animation(.spring(response: 0.8, dampingFraction: 0.6), value: animated)
            }
            
            // Result text
            VStack(spacing: 8) {
                Text(isWinner ? "VICTORIE!" : "ÎNFRÂNGERE")
                    .font(.largeTitle.bold())
                    .foregroundColor(isWinner ? .yellow : .gray)
                    .opacity(animated ? 1.0 : 0.0)
                    .animation(.easeInOut.delay(0.3), value: animated)
                
                Text(isWinner ? "Victory!" : "Defeat")
                    .font(.title2)
                    .foregroundColor(isWinner ? .yellow.opacity(0.8) : .gray.opacity(0.8))
                    .italic()
                    .opacity(animated ? 1.0 : 0.0)
                    .animation(.easeInOut.delay(0.5), value: animated)
                
                Text("\(winnerName) wins!")
                    .font(.headline)
                    .foregroundColor(.white.opacity(0.9))
                    .opacity(animated ? 1.0 : 0.0)
                    .animation(.easeInOut.delay(0.7), value: animated)
            }
        }
    }
}

/// Score breakdown display
struct ScoreBreakdownView: View {
    let result: GameResult
    let players: [Player]
    @Binding var animated: Bool
    
    var body: some View {
        GameResultCard(title: "Final Scores", icon: "target") {
            VStack(spacing: 16) {
                ForEach(players, id: \.id) { player in
                    let finalScore = result.finalScores[player.id] ?? 0
                    let isWinner = player.id == result.winnerId
                    
                    HStack {
                        // Player info
                        HStack(spacing: 12) {
                            Circle()
                                .fill(isWinner ? Color.yellow.opacity(0.3) : Color.gray.opacity(0.2))
                                .frame(width: 40, height: 40)
                                .overlay(
                                    Image(systemName: player.isHuman ? "person.fill" : "cpu")
                                        .foregroundColor(isWinner ? .yellow : .white.opacity(0.7))
                                )
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(player.name)
                                    .font(.headline)
                                    .foregroundColor(isWinner ? .yellow : .white)
                                
                                Text(player.isHuman ? "Human" : "AI Player")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.6))
                            }
                        }
                        
                        Spacer()
                        
                        // Score
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("\(finalScore)")
                                .font(.title.bold())
                                .foregroundColor(isWinner ? .yellow : .white)
                            
                            Text("points")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.6))
                        }
                        
                        // Winner crown
                        if isWinner {
                            Image(systemName: "crown.fill")
                                .foregroundColor(.yellow)
                                .font(.title2)
                        }
                    }
                    .padding(.vertical, 8)
                    .opacity(animated ? 1.0 : 0.0)
                    .animation(.easeInOut.delay(0.9 + Double(players.firstIndex(where: { $0.id == player.id }) ?? 0) * 0.2), value: animated)
                    
                    if player != players.last {
                        Divider()
                            .background(Color.white.opacity(0.2))
                    }
                }
            }
        }
        .opacity(animated ? 1.0 : 0.0)
        .animation(.easeInOut.delay(0.9), value: animated)
    }
}

/// Game statistics display
struct GameStatsView: View {
    let session: GameSession
    @Binding var animated: Bool
    
    private var gameDuration: TimeInterval {
        if let endTime = session.endTime {
            return endTime.timeIntervalSince(session.startTime)
        }
        return Date().timeIntervalSince(session.startTime)
    }
    
    private var formattedDuration: String {
        let minutes = Int(gameDuration / 60)
        let seconds = Int(gameDuration.truncatingRemainder(dividingBy: 60))
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    var body: some View {
        GameResultCard(title: "Game Statistics", icon: "chart.bar.fill") {
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                StatMetricCard(
                    value: "\(session.gameState.trickHistory.count)",
                    label: "Total Tricks",
                    color: .blue
                )
                
                StatMetricCard(
                    value: formattedDuration,
                    label: "Duration",
                    color: .green
                )
                
                StatMetricCard(
                    value: "\(session.gameState.roundNumber)",
                    label: "Rounds",
                    color: .orange
                )
                
                StatMetricCard(
                    value: session.gameType.displayName.components(separatedBy: " ").last ?? "Unknown",
                    label: "AI Difficulty",
                    color: .purple
                )
            }
        }
        .opacity(animated ? 1.0 : 0.0)
        .animation(.easeInOut.delay(1.2), value: animated)
    }
}

/// Individual statistic metric
struct StatMetricCard: View {
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Text(value)
                .font(.title2.bold())
                .foregroundColor(color)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.1))
                .stroke(color.opacity(0.3), lineWidth: 1)
        )
    }
}

/// Action buttons for post-game options
struct ActionButtonsView: View {
    @EnvironmentObject var navigationManager: NavigationManager
    
    var body: some View {
        VStack(spacing: 16) {
            // Primary actions
            HStack(spacing: 16) {
                // Play again
                ActionButton(
                    title: "Play Again",
                    subtitle: "Same settings",
                    icon: "arrow.clockwise.circle.fill",
                    color: .green,
                    isPrimary: true
                ) {
                    navigationManager.showGameSetup()
                }
                
                // New game
                ActionButton(
                    title: "New Game",
                    subtitle: "Different setup",
                    icon: "plus.circle.fill",
                    color: .blue,
                    isPrimary: true
                ) {
                    navigationManager.showGameSetup()
                }
            }
            
            // Secondary actions
            HStack(spacing: 16) {
                // View statistics
                ActionButton(
                    title: "Statistics",
                    subtitle: "View progress",
                    icon: "chart.bar.circle.fill",
                    color: .purple,
                    isPrimary: false
                ) {
                    navigationManager.showStatistics()
                }
                
                // Main menu
                ActionButton(
                    title: "Main Menu",
                    subtitle: "Home screen",
                    icon: "house.circle.fill",
                    color: .gray,
                    isPrimary: false
                ) {
                    navigationManager.returnToMainMenu()
                }
            }
        }
    }
}

/// Individual action button
struct ActionButton: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let isPrimary: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(isPrimary ? .white : color)
                
                VStack(spacing: 2) {
                    Text(title)
                        .font(.subheadline.bold())
                        .foregroundColor(isPrimary ? .white : color)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(isPrimary ? .white.opacity(0.8) : color.opacity(0.8))
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 80)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        isPrimary ?
                        LinearGradient(
                            colors: [color, color.opacity(0.8)],
                            startPoint: .top,
                            endPoint: .bottom
                        ) :
                        LinearGradient(
                            colors: [color.opacity(0.1), color.opacity(0.05)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .stroke(color, lineWidth: isPrimary ? 0 : 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Supporting Views

/// Common card styling for game result content
struct GameResultCard<Content: View>: View {
    let title: String
    let icon: String
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(.blue)
                
                Text(title)
                    .font(.title3.bold())
                    .foregroundColor(.white)
                
                Spacer()
            }
            
            // Content
            content
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.1),
                            Color.white.opacity(0.05)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
        )
    }
}

/// Background with win/loss theming
struct GameResultsBackground: View {
    let isWinner: Bool
    
    var body: some View {
        ZStack {
            // Base gradient
            LinearGradient(
                colors: isWinner ? [
                    Color(red: 0.1, green: 0.15, blue: 0.05),
                    Color(red: 0.15, green: 0.1, blue: 0.05),
                    Color(red: 0.05, green: 0.1, blue: 0.05)
                ] : [
                    Color(red: 0.1, green: 0.05, blue: 0.05),
                    Color(red: 0.08, green: 0.08, blue: 0.12),
                    Color(red: 0.05, green: 0.05, blue: 0.1)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // Celebratory or somber pattern
            GeometryReader { geometry in
                let count = isWinner ? 20 : 10
                ForEach(0..<count, id: \.self) { _ in
                    Image(systemName: isWinner ? "star.fill" : "circle")
                        .font(.system(size: CGFloat.random(in: 15...30)))
                        .foregroundColor(
                            isWinner ?
                            Color.yellow.opacity(0.1) :
                            Color.gray.opacity(0.05)
                        )
                        .position(
                            x: CGFloat.random(in: 0...geometry.size.width),
                            y: CGFloat.random(in: 0...geometry.size.height)
                        )
                }
            }
        }
        .ignoresSafeArea()
    }
}

/// Confetti animation for wins
struct ConfettiView: View {
    @State private var animate = false
    
    var body: some View {
        GeometryReader { geometry in
            ForEach(0..<50, id: \.self) { index in
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.random)
                    .frame(width: 8, height: 8)
                    .position(
                        x: CGFloat.random(in: 0...geometry.size.width),
                        y: animate ? geometry.size.height + 50 : -50
                    )
                    .animation(
                        .linear(duration: Double.random(in: 2...4))
                        .repeatForever(autoreverses: false)
                        .delay(Double.random(in: 0...2)),
                        value: animate
                    )
            }
        }
        .onAppear {
            animate = true
        }
    }
}

// MARK: - Extensions

extension Color {
    static var random: Color {
        Color(
            red: Double.random(in: 0...1),
            green: Double.random(in: 0...1),
            blue: Double.random(in: 0...1)
        )
    }
}

// MARK: - Preview

struct GameResultsView_Previews: PreviewProvider {
    static var previews: some View {
        let gameState = GameState()
        let players = [
            Player(name: "Player"),
            AIPlayer(name: "Computer")
        ]
        gameState.players = players
        
        let result = GameResult(
            winnerId: players[0].id,
            finalScores: [
                players[0].id: 11,
                players[1].id: 8
            ],
            totalTricks: 14,
            gameDuration: 300
        )
        
        let session = GameSession(
            id: UUID(),
            gameState: gameState,
            gameType: .singlePlayer(difficulty: .medium),
            startTime: Date().addingTimeInterval(-300)
        )
        session.endTime = Date()
        
        return GameResultsView(result: result, session: session)
            .environmentObject(NavigationManager())
            .preferredColorScheme(.dark)
    }
}