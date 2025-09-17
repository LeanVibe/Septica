
//
//  GameResultView.swift
//  Septica
//
//  Enhanced view for displaying game results with comprehensive celebrations
//  Includes victory celebrations, defeat encouragement, and Romanian cultural elements
//

import SwiftUI

/// Enhanced view with comprehensive celebrations and feedback
struct GameResultView: View {
    let result: GameResult
    let playerNames: [String]
    let gameState: GameState
    let onNewGame: () -> Void
    let onMainMenu: () -> Void
    
    @StateObject private var celebrationSystem = GameEndCelebrationSystem()
    @State private var characterAnimator = RomanianCharacterAnimator()
    @State private var celebrationPhase: ResultCelebrationPhase = .initial
    @State private var showParticles = false
    @State private var showExperience = false
    @State private var showAchievements = false
    @State private var experienceGained: Int = 0
    @State private var newAchievements: [Achievement] = []
    @State private var celebrationData: GameEndCelebration?
    
    private var isPlayerVictory: Bool {
        guard let winnerId = result.winnerId else { return false }
        return gameState.players.first(where: { $0.id == winnerId })?.isHuman == true
    }
    
    private var isDraw: Bool {
        result.winnerId == nil
    }
    
    private var winnerName: String? {
        guard let winnerId = result.winnerId else { return nil }
        if gameState.players.first(where: { $0.id == winnerId })?.isHuman == true {
            return "You"
        } else {
            return playerNames.first { _ in true } ?? "Opponent"
        }
    }
    
    var body: some View {
        ZStack {
            // Background with celebration effects
            backgroundView()
            
            // Romanian character for game end reactions
            VStack {
                HStack {
                    Spacer()
                    RomanianCharacterView(
                        animator: characterAnimator,
                        size: CGSize(width: 100, height: 120)
                    )
                }
                .padding(.top, 20)
                .padding(.trailing, 20)
                Spacer()
            }
            
            // Main content with celebration overlay
            VStack(spacing: 24) {
                // Dynamic celebration header
                celebrationHeaderView()
                
                // Experience and achievements section
                if showExperience {
                    experienceGainView()
                        .transition(.scale.combined(with: .opacity))
                }
                
                if showAchievements && !newAchievements.isEmpty {
                    achievementsView()
                        .transition(.slide.combined(with: .opacity))
                }
                
                // Enhanced scores section
                enhancedScoresView()
                
                // Cultural wisdom section (for draws and defeats)
                if let celebration = celebrationData,
                   (celebration.type == .draw || celebration.type == .defeat) {
                    culturalWisdomView(celebration: celebration)
                        .transition(.opacity)
                }
                
                // Game statistics
                gameStatsView()
                
                // Action buttons
                actionButtonsView()
            }
            .padding(24)
            .background(celebrationBackgroundView())
            .padding()
            
            // Particle effects overlay
            if showParticles {
                ParticleEffectView()
                    .allowsHitTesting(false)
            }
        }
        .onAppear {
            startCelebrationSequence()
            triggerGameEndCharacterReaction()
        }
    }
    
    // MARK: - Celebration Sequence
    
    private func startCelebrationSequence() {
        Task {
            do {
                let celebrationResult = self.convertToCelebrationGameResult(result)
                
                // Safely call celebration system with error handling
                if isPlayerVictory {
                    await celebrationSystem.celebrateVictory(gameResult: celebrationResult, gameState: gameState)
                } else if isDraw {
                    await celebrationSystem.showDrawFeedback(gameResult: celebrationResult, gameState: gameState)
                } else {
                    await celebrationSystem.showDefeatFeedback(gameResult: celebrationResult, gameState: gameState)
                }
                
                // Update UI based on celebration data - ensure main thread
                await MainActor.run {
                    if let celebration = celebrationSystem.currentCelebration {
                        Task {
                            await updateCelebrationUI(celebration: celebration)
                        }
                    }
                }
            } catch {
                // Handle any celebration errors gracefully
                print("⚠️ Celebration system error: \(error)")
                // Fall back to basic celebration phase without crashing
                await MainActor.run {
                    celebrationPhase = .celebration
                }
            }
        }
    }
    
    @MainActor
    private func updateCelebrationUI(celebration: GameEndCelebration) async {
        celebrationData = celebration
        celebrationPhase = .celebration
        
        // Trigger particle effects for victories
        if celebration.type == .victory {
            withAnimation(.easeInOut(duration: 0.5)) {
                showParticles = true
            }
            
            // Add haptic feedback
            let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
            impactFeedback.impactOccurred()
        }
        
        // Show experience gain after 1 second
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            showExperience = true
            experienceGained = celebration.statistics.strategicMoves * 10
        }
        
        // Show achievements after another 1.5 seconds
        try? await Task.sleep(nanoseconds: 1_500_000_000)
        if !newAchievements.isEmpty {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) {
                showAchievements = true
            }
        }
        
        celebrationPhase = .complete
    }
    
    /// Trigger appropriate character reaction for game end
    private func triggerGameEndCharacterReaction() {
        let context: GameContext
        let reaction: CharacterReaction
        let intensity: AnimationIntensity
        
        if isPlayerVictory {
            context = .celebration
            reaction = .victory
            intensity = .celebration
        } else if isDraw {
            context = .learning
            reaction = .encouragement
            intensity = .normal
        } else {
            context = .encouragement
            reaction = .defeat
            intensity = .subtle
        }
        
        // Delay character reaction to sync with celebration
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            characterAnimator.triggerReaction(reaction, context: context, intensity: intensity)
        }
    }
    
    // MARK: - View Components
    
    @ViewBuilder
    private func backgroundView() -> some View {
        if let celebration = celebrationData {
            switch celebration.type {
            case .victory:
                // Golden celebration background
                LinearGradient(
                    colors: [.yellow.opacity(0.3), .orange.opacity(0.2), .clear],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
            case .defeat:
                // Gentle encouragement background
                LinearGradient(
                    colors: [.blue.opacity(0.2), .purple.opacity(0.1), .clear],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
            case .draw:
                // Balanced wisdom background
                LinearGradient(
                    colors: [.green.opacity(0.2), .teal.opacity(0.1), .clear],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            }
        } else {
            Color.clear
        }
    }
    
    @ViewBuilder
    private func celebrationHeaderView() -> some View {
        VStack(spacing: 16) {
            if let celebration = celebrationData {
                // Cultural greeting
                if let victoryPhrase = celebration.culturalElements.victoryPhrase {
                    Text(victoryPhrase.text)
                        .font(.title2.bold())
                        .foregroundColor(.yellow)
                        .multilineTextAlignment(.center)
                        .scaleEffect(celebrationPhase == .celebration ? 1.1 : 1.0)
                        .animation(.spring(response: 0.5, dampingFraction: 0.6), value: celebrationPhase)
                }
                
                // Main result text
                switch celebration.type {
                case .victory:
                    Text("🎉 Felicitări! 🎉")
                        .font(.largeTitle.bold())
                        .foregroundColor(.yellow)
                        .scaleEffect(showParticles ? 1.2 : 1.0)
                        .animation(.spring(response: 0.6, dampingFraction: 0.7), value: showParticles)
                    
                    Text("Ai câștigat cu măiestrie!")
                        .font(.title2)
                        .foregroundColor(.white)
                        .opacity(0.9)
                    
                case .defeat:
                    Text("🎯 Încercare Valoroasă")
                        .font(.title.bold())
                        .foregroundColor(.cyan)
                    
                    Text("Fiecare înfrângere e o lecție!")
                        .font(.title2)
                        .foregroundColor(.white.opacity(0.8))
                    
                case .draw:
                    Text("⚖️ Echilibru Perfect")
                        .font(.title.bold())
                        .foregroundColor(.green)
                    
                    Text("Înțelepciune în egalitate")
                        .font(.title2)
                        .foregroundColor(.white.opacity(0.8))
                }
                
            } else {
                // Fallback header while loading celebration
                if isPlayerVictory {
                    Text("🎉 Victory! 🎉")
                        .font(.title.bold())
                        .foregroundColor(.yellow)
                } else if isDraw {
                    Text("⚖️ Draw")
                        .font(.title.bold())
                        .foregroundColor(.green)
                } else {
                    Text("Game Over")
                        .font(.title.bold())
                        .foregroundColor(.white)
                }
            }
        }
    }
    
    @ViewBuilder
    private func experienceGainView() -> some View {
        if experienceGained > 0 {
            VStack(spacing: 8) {
                Text("Experiență Câștigată")
                    .font(.headline)
                    .foregroundColor(.yellow.opacity(0.9))
                
                HStack {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                    
                    Text("+\(experienceGained) XP")
                        .font(.title3.bold())
                        .foregroundColor(.yellow)
                    
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.yellow.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.yellow.opacity(0.3), lineWidth: 1)
                    )
            )
        }
    }
    
    @ViewBuilder
    private func achievementsView() -> some View {
        VStack(spacing: 12) {
            Text("Realizări Noi!")
                .font(.headline)
                .foregroundColor(.purple.opacity(0.9))
            
            ForEach(newAchievements, id: \.id) { achievement in
                HStack {
                    Image(systemName: "trophy.fill")
                        .foregroundColor(.purple)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(achievement.title)
                            .font(.body.bold())
                            .foregroundColor(.white)
                        
                        Text(achievement.description)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    
                    Spacer()
                }
                .padding(.horizontal)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.purple.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.purple.opacity(0.3), lineWidth: 1)
                )
        )
    }
    
    @ViewBuilder
    private func culturalWisdomView(celebration: GameEndCelebration) -> some View {
        if !celebration.culturalElements.culturalWisdom.isEmpty {
            let wisdom = celebration.culturalElements.culturalWisdom
            VStack(spacing: 8) {
                Image(systemName: "quote.bubble.fill")
                    .font(.title2)
                    .foregroundColor(.teal)
                
                Text(wisdom)
                    .font(.body.italic())
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                Text("— Înțelepciune românească")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.teal.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.teal.opacity(0.3), lineWidth: 1)
                    )
            )
        }
    }
    
    @ViewBuilder
    private func enhancedScoresView() -> some View {
        VStack(spacing: 16) {
            Text("Scoruri Finale")
                .font(.headline)
                .foregroundColor(.white.opacity(0.9))
            
            VStack(spacing: 8) {
                ForEach(result.finalScores.sorted(by: { $0.value > $1.value }), id: \.key) { playerId, score in
                    HStack {
                        // Player name with enhanced styling
                        let isHumanPlayer = gameState.players.first(where: { $0.id == playerId })?.isHuman == true
                        Text(isHumanPlayer ? "Tu" : "Adversar")
                            .font(.body.bold())
                            .foregroundColor(isHumanPlayer ? .yellow : .white)
                        
                        Spacer()
                        
                        // Score with winner highlighting
                        Text("\(score)")
                            .font(.title3.bold())
                            .foregroundColor(score == result.winningScore ? .yellow : .white)
                        
                        if score == result.winningScore {
                            Image(systemName: "crown.fill")
                                .foregroundColor(.yellow)
                                .font(.caption)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 4)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.black.opacity(0.4))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
            )
        }
    }
    
    @ViewBuilder
    private func gameStatsView() -> some View {
        VStack(spacing: 8) {
            HStack {
                Text("Levate Jucate:")
                    .foregroundColor(.white.opacity(0.8))
                Spacer()
                Text("\(result.totalTricks)")
                    .foregroundColor(.white)
            }
            
            HStack {
                Text("Durata Jocului:")
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
    }
    
    @ViewBuilder
    private func actionButtonsView() -> some View {
        VStack(spacing: 12) {
            Button("Joc Nou", action: onNewGame)
                .buttonStyle(EnhancedResultButtonStyle(color: .green, isProminent: true))
            
            Button("Meniul Principal", action: onMainMenu)
                .buttonStyle(EnhancedResultButtonStyle(color: .blue, isProminent: false))
        }
    }
    
    @ViewBuilder
    private func celebrationBackgroundView() -> some View {
        RoundedRectangle(cornerRadius: 20)
            .fill(Color.black.opacity(0.85))
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(
                        LinearGradient(
                            colors: celebrationPhase == .celebration ? 
                                [.yellow.opacity(0.6), .orange.opacity(0.4)] : 
                                [.white.opacity(0.2), .clear],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2
                    )
                    .animation(.easeInOut(duration: 1.0), value: celebrationPhase)
            )
            .shadow(color: .black.opacity(0.5), radius: 15, x: 0, y: 8)
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    // MARK: - Helper Functions
    
    /// Convert GameResult to CelebrationGameResult for celebration system
    private func convertToCelebrationGameResult(_ gameResult: GameResult) -> CelebrationGameResult {
        // Safely get player and opponent scores
        let scores = Array(gameResult.finalScores.values)
        let playerScore = scores.max() ?? 0
        let opponentScore = scores.min() ?? 0
        
        // Safely calculate tricks won - use defensive programming
        let humanPlayerId = self.gameState.players.first(where: { $0.isHuman })?.id
        let tricksWon = humanPlayerId != nil ? 
            self.gameState.trickHistory.filter { $0.winnerPlayerId == humanPlayerId }.count : 0
        
        let pointsCaptured = scores.reduce(0, +)
        
        // Ensure we have reasonable values
        let safeTricksWon = max(0, tricksWon)
        let strategicMoves = max(1, safeTricksWon * 2) // At least 1 to avoid zero
        let culturalMoments = max(1, safeTricksWon) // At least 1 to avoid zero
        
        return CelebrationGameResult(
            playerScore: max(0, playerScore),
            opponentScore: max(0, opponentScore),
            tricksWon: safeTricksWon,
            pointsCaptured: max(0, pointsCaptured),
            duration: max(0.0, gameResult.gameDuration),
            strategicMoves: strategicMoves,
            culturalMoments: culturalMoments
        )
    }
}

// MARK: - Supporting Types

/// Phases of the celebration sequence
enum ResultCelebrationPhase {
    case initial
    case celebration
    case complete
}

// MARK: - Supporting Views

/// Particle effect overlay for victory celebrations
struct ParticleEffectView: View {
    @State private var animate = false
    
    var body: some View {
        ZStack {
            ForEach(0..<20, id: \.self) { index in
                Circle()
                    .fill(Color.yellow.opacity(0.8))
                    .frame(width: CGFloat.random(in: 4...12))
                    .position(
                        x: CGFloat.random(in: 0...UIScreen.main.bounds.width),
                        y: animate ? CGFloat.random(in: -50...0) : UIScreen.main.bounds.height + 50
                    )
                    .animation(
                        .easeOut(duration: Double.random(in: 1.5...3.0))
                        .delay(Double.random(in: 0...1.5))
                        .repeatForever(autoreverses: false),
                        value: animate
                    )
            }
            
            ForEach(0..<15, id: \.self) { index in
                Image(systemName: "star.fill")
                    .font(.caption)
                    .foregroundColor(.yellow)
                    .position(
                        x: CGFloat.random(in: 0...UIScreen.main.bounds.width),
                        y: animate ? CGFloat.random(in: -30...0) : UIScreen.main.bounds.height + 30
                    )
                    .animation(
                        .easeOut(duration: Double.random(in: 2.0...4.0))
                        .delay(Double.random(in: 0...2.0))
                        .repeatForever(autoreverses: false),
                        value: animate
                    )
            }
        }
        .onAppear {
            animate = true
        }
    }
}

// MARK: - Button Styles

/// Enhanced button style for result view actions
struct EnhancedResultButtonStyle: ButtonStyle {
    let color: Color
    let isProminent: Bool
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(maxWidth: .infinity)
            .frame(height: isProminent ? 50 : 44)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(color)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                isProminent ? Color.white.opacity(0.3) : Color.clear,
                                lineWidth: 1
                            )
                    )
            )
            .foregroundColor(.white)
            .font(isProminent ? .headline.bold() : .headline)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
            .shadow(
                color: isProminent ? color.opacity(0.4) : Color.clear,
                radius: isProminent ? 6 : 0,
                x: 0,
                y: 3
            )
    }
}

/// Legacy button style for backwards compatibility
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
        let playerId = UUID()
        let opponentId = UUID()
        
        let victoryResult = GameResult(
            winnerId: playerId,
            finalScores: [playerId: 7, opponentId: 4],
            totalTricks: 11,
            gameDuration: 285.0
        )
        
        let defeatResult = GameResult(
            winnerId: opponentId,
            finalScores: [playerId: 3, opponentId: 7],
            totalTricks: 10,
            gameDuration: 320.0
        )
        
        let drawResult = GameResult(
            winnerId: nil,
            finalScores: [playerId: 5, opponentId: 5],
            totalTricks: 10,
            gameDuration: 300.0
        )
        
        let gameState = GameState()
        let player1 = Player(name: "Player")
        let player2 = Player(name: "Opponent")
        gameState.players = [player1, player2]
        gameState.phase = .finished
        
        return Group {
            // Victory preview
            GameResultView(
                result: victoryResult,
                playerNames: ["Tu", "Adversar AI"],
                gameState: gameState,
                onNewGame: {},
                onMainMenu: {}
            )
            .preferredColorScheme(.dark)
            .background(Color.green.opacity(0.3))
            .previewDisplayName("Victory Celebration")
            
            // Defeat preview
            GameResultView(
                result: defeatResult,
                playerNames: ["Tu", "Adversar AI"],
                gameState: gameState,
                onNewGame: {},
                onMainMenu: {}
            )
            .preferredColorScheme(.dark)
            .background(Color.blue.opacity(0.3))
            .previewDisplayName("Defeat Encouragement")
            
            // Draw preview
            GameResultView(
                result: drawResult,
                playerNames: ["Tu", "Adversar AI"],
                gameState: gameState,
                onNewGame: {},
                onMainMenu: {}
            )
            .preferredColorScheme(.dark)
            .background(Color.teal.opacity(0.3))
            .previewDisplayName("Draw Wisdom")
        }
    }
}
