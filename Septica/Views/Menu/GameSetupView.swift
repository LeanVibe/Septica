//
//  GameSetupView.swift
//  Septica
//
//  Game setup view for configuring new games
//  Allows player name input, AI difficulty selection, and game options
//

import SwiftUI

/// Game setup view for configuring new single-player games
struct GameSetupView: View {
    @EnvironmentObject var navigationManager: NavigationManager
    @StateObject var userSettings = UserSettings.shared
    @State private var playerName = ""
    @State private var selectedDifficulty: AIDifficulty = .medium
    @State private var targetScore = 11
    @State private var showingDifficultyInfo = false
    @State private var animateContent = false
    
    let targetScoreOptions = [7, 11, 15, 21]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                // Title section
                TitleHeaderView()
                    .padding(.top, 20)
                    .scaleEffect(animateContent ? 1.0 : 0.9)
                    .opacity(animateContent ? 1.0 : 0.0)
                
                // Player setup section
                PlayerSetupSection(playerName: $playerName)
                    .opacity(animateContent ? 1.0 : 0.0)
                    .animation(.easeInOut.delay(0.2), value: animateContent)
                
                // AI difficulty selection
                AISpicicultySection(
                    selectedDifficulty: $selectedDifficulty,
                    showingInfo: $showingDifficultyInfo
                )
                .opacity(animateContent ? 1.0 : 0.0)
                .animation(.easeInOut.delay(0.4), value: animateContent)
                
                // Game options
                GameOptionsSection(targetScore: $targetScore)
                    .opacity(animateContent ? 1.0 : 0.0)
                    .animation(.easeInOut.delay(0.6), value: animateContent)
                
                // Start game button
                StartGameButton(
                    playerName: playerName.isEmpty ? "Player" : playerName,
                    difficulty: selectedDifficulty,
                    targetScore: targetScore
                )
                .opacity(animateContent ? 1.0 : 0.0)
                .animation(.easeInOut.delay(0.8), value: animateContent)
                
                Spacer(minLength: 30)
            }
            .padding(.horizontal, 20)
        }
        .background(RomanianGameBackground())
        .navigationTitle("New Game")
        .navigationBarTitleDisplayMode(.large)
        .navigationBarBackButtonHidden(false)
        .sheet(isPresented: $showingDifficultyInfo) {
            DifficultyInfoSheet()
        }
        .onAppear {
            setupInitialValues()
            animateContent = true
        }
    }
    
    private func setupInitialValues() {
        playerName = userSettings.playerName
        selectedDifficulty = userSettings.preferredDifficulty
    }
}

// MARK: - Setup Sections

/// Title header for game setup
struct TitleHeaderView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "gamecontroller.fill")
                .font(.system(size: 40))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            Text("Setup Your Game")
                .font(.title2.bold())
                .foregroundColor(.white)
            
            Text("Configure your Septica experience")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.7))
        }
        .padding(.bottom, 10)
    }
}

/// Player name and setup section
struct PlayerSetupSection: View {
    @Binding var playerName: String
    
    var body: some View {
        GameSetupCard(title: "Player Setup", icon: "person.fill") {
            VStack(alignment: .leading, spacing: 16) {
                Text("Player Name")
                    .font(.headline)
                    .foregroundColor(.white)
                
                TextField("Enter your name", text: $playerName)
                    .textFieldStyle(RomanianTextFieldStyle())
                    .submitLabel(.done)
                
                Text("Your name will be displayed during the game and in statistics.")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
            }
        }
    }
}

/// AI difficulty selection section
struct AISpicicultySection: View {
    @Binding var selectedDifficulty: AIDifficulty
    @Binding var showingInfo: Bool
    
    var body: some View {
        GameSetupCard(title: "AI Opponent", icon: "cpu.fill") {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("Difficulty Level")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Button(action: { showingInfo = true }) {
                        Image(systemName: "info.circle")
                            .foregroundColor(.blue)
                    }
                }
                
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 12) {
                    ForEach(AIDifficulty.allCases, id: \.self) { difficulty in
                        DifficultyButton(
                            difficulty: difficulty,
                            isSelected: selectedDifficulty == difficulty,
                            action: {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    selectedDifficulty = difficulty
                                }
                            }
                        )
                    }
                }
                
                // Selected difficulty info
                DifficultyInfoView(difficulty: selectedDifficulty)
            }
        }
    }
}

/// Individual difficulty selection button
struct DifficultyButton: View {
    let difficulty: AIDifficulty
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: difficulty.iconName)
                    .font(.title2)
                    .foregroundColor(isSelected ? .white : .white.opacity(0.7))
                
                Text(difficulty.displayName)
                    .font(.headline)
                    .foregroundColor(isSelected ? .white : .white.opacity(0.7))
            }
            .frame(height: 80)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        isSelected ?
                        LinearGradient(
                            colors: [.blue, .blue.opacity(0.8)],
                            startPoint: .top,
                            endPoint: .bottom
                        ) :
                        LinearGradient(
                            colors: [Color.white.opacity(0.1), Color.white.opacity(0.05)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .stroke(
                        isSelected ? Color.blue : Color.white.opacity(0.2),
                        lineWidth: isSelected ? 2 : 1
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

/// Display info about selected difficulty
struct DifficultyInfoView: View {
    let difficulty: AIDifficulty
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: difficulty.iconName)
                .foregroundColor(.blue)
                .font(.title3)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(difficulty.displayName)
                    .font(.subheadline.bold())
                    .foregroundColor(.white)
                
                Text(difficulty.description)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
            
            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.blue.opacity(0.1))
                .stroke(Color.blue.opacity(0.3), lineWidth: 1)
        )
    }
}

/// Game options section
struct GameOptionsSection: View {
    @Binding var targetScore: Int
    let targetScoreOptions = [7, 11, 15, 21]
    
    var body: some View {
        GameSetupCard(title: "Game Rules", icon: "target") {
            VStack(alignment: .leading, spacing: 16) {
                Text("Target Score")
                    .font(.headline)
                    .foregroundColor(.white)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(targetScoreOptions, id: \.self) { score in
                            TargetScoreButton(
                                score: score,
                                isSelected: targetScore == score,
                                action: {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        targetScore = score
                                    }
                                }
                            )
                        }
                    }
                    .padding(.horizontal)
                }
                
                Text("First player to reach \(targetScore) points wins the game.")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
            }
        }
    }
}

/// Target score selection button
struct TargetScoreButton: View {
    let score: Int
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text("\(score)")
                .font(.title2.bold())
                .foregroundColor(isSelected ? .white : .white.opacity(0.7))
                .frame(width: 60, height: 60)
                .background(
                    Circle()
                        .fill(
                            isSelected ?
                            LinearGradient(
                                colors: [.green, .green.opacity(0.8)],
                                startPoint: .top,
                                endPoint: .bottom
                            ) :
                            LinearGradient(
                                colors: [Color.white.opacity(0.1), Color.white.opacity(0.05)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .stroke(
                            isSelected ? Color.green : Color.white.opacity(0.2),
                            lineWidth: isSelected ? 2 : 1
                        )
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

/// Start game button
struct StartGameButton: View {
    @EnvironmentObject var navigationManager: NavigationManager
    let playerName: String
    let difficulty: AIDifficulty
    let targetScore: Int
    
    var body: some View {
        Button(action: startGame) {
            HStack(spacing: 16) {
                Image(systemName: "play.fill")
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Start Game")
                        .font(.headline)
                    
                    Text("\(playerName) vs AI (\(difficulty.displayName))")
                        .font(.caption)
                        .opacity(0.8)
                }
                
                Spacer()
                
                Image(systemName: "arrow.right.circle.fill")
                    .font(.title2)
            }
            .foregroundColor(.white)
            .padding(20)
            .background(
                LinearGradient(
                    colors: [.green, .green.opacity(0.8)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(16)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func startGame() {
        // Save user preferences
        UserSettings.shared.playerName = playerName
        UserSettings.shared.preferredDifficulty = difficulty
        UserSettings.shared.saveSettings()
        
        // Start the game
        navigationManager.startNewGame(
            playerName: playerName,
            difficulty: difficulty
        )
    }
}

// MARK: - Supporting Views

/// Common card styling for setup sections
struct GameSetupCard<Content: View>: View {
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

/// Romanian-themed text field style
struct RomanianTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.black.opacity(0.3))
                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
            )
            .foregroundColor(.white)
            .accentColor(.blue)
    }
}

/// Background for game setup
struct RomanianGameBackground: View {
    var body: some View {
        ZStack {
            // Base gradient
            LinearGradient(
                colors: [
                    Color(red: 0.05, green: 0.1, blue: 0.2),
                    Color(red: 0.1, green: 0.05, blue: 0.1),
                    Color(red: 0.05, green: 0.1, blue: 0.05)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // Subtle pattern
            GeometryReader { geometry in
                ForEach(0..<20) { _ in
                    Circle()
                        .fill(Color.white.opacity(0.02))
                        .frame(width: CGFloat.random(in: 30...80))
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

/// Difficulty information sheet
struct DifficultyInfoSheet: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("AI Difficulty Levels")
                            .font(.title.bold())
                        
                        Text("Choose your preferred challenge level")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.bottom)
                    
                    // Difficulty explanations
                    ForEach(AIDifficulty.allCases, id: \.self) { difficulty in
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: difficulty.iconName)
                                    .font(.title2)
                                    .foregroundColor(.blue)
                                
                                Text(difficulty.displayName)
                                    .font(.headline)
                            }
                            
                            Text(difficulty.description)
                                .font(.body)
                                .foregroundColor(.secondary)
                            
                            if difficulty != AIDifficulty.allCases.last {
                                Divider()
                            }
                        }
                        .padding(.vertical, 8)
                    }
                    
                    // Strategy tips
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Strategy Tips")
                            .font(.headline)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("• Save your 7s for key moments")
                            Text("• Count cards to track what's left")
                            Text("• Watch for your opponent's patterns")
                            Text("• Control the game tempo with strategic plays")
                        }
                        .font(.body)
                        .foregroundColor(.secondary)
                    }
                    .padding(.top)
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Preview

struct GameSetupView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            GameSetupView()
                .environmentObject(NavigationManager())
        }
        .preferredColorScheme(.dark)
    }
}