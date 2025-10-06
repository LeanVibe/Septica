import SwiftUI

struct GameSetupView: View {
    let onStart: (GameState) -> Void
    @State private var selectedGameMode: GameMode = .twoPlayers

    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                Text("Septica Românească")
                    .font(.largeTitle.weight(.bold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.yellow, Color.red, Color.blue],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )

                Text("Joc tradițional de cărți")
                    .font(.headline)
                    .foregroundColor(.secondary)

                // Game mode selection
                VStack(spacing: 16) {
                    Text("Alege modul de joc")
                        .font(.headline)
                        .foregroundColor(.primary)

                    // 2-player mode button
                    Button(action: { selectedGameMode = .twoPlayers }) {
                        HStack {
                            Image(systemName: "person.2.fill")
                            VStack(alignment: .leading, spacing: 4) {
                                Text("2 Jucători")
                                    .font(.headline.weight(.semibold))
                                Text("Mod clasic 1 vs 1")
                                    .font(.caption)
                                    .opacity(0.8)
                            }
                            Spacer()
                            if selectedGameMode == .twoPlayers {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(selectedGameMode == .twoPlayers ? Color.blue.opacity(0.2) : Color.gray.opacity(0.1))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(selectedGameMode == .twoPlayers ? Color.blue : Color.clear, lineWidth: 2)
                                )
                        )
                    }
                    .buttonStyle(.plain)

                    // 3-player mode button
                    Button(action: { selectedGameMode = .threePlayers }) {
                        HStack {
                            Image(systemName: "person.3.fill")
                            VStack(alignment: .leading, spacing: 4) {
                                Text("3 Jucători")
                                    .font(.headline.weight(.semibold))
                                Text("30 cărți • 7 & 8 sunt wild")
                                    .font(.caption)
                                    .opacity(0.8)
                            }
                            Spacer()
                            if selectedGameMode == .threePlayers {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(selectedGameMode == .threePlayers ? Color.purple.opacity(0.2) : Color.gray.opacity(0.1))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(selectedGameMode == .threePlayers ? Color.purple : Color.clear, lineWidth: 2)
                                )
                        )
                    }
                    .buttonStyle(.plain)

                    // 4-player team mode button
                    Button(action: { selectedGameMode = .fourPlayers }) {
                        HStack {
                            Image(systemName: "person.3.sequence.fill")
                            VStack(alignment: .leading, spacing: 4) {
                                Text("4 Jucători (Echipe)")
                                    .font(.headline.weight(.semibold))
                                Text("2 vs 2 - Joc în echipă")
                                    .font(.caption)
                                    .opacity(0.8)
                            }
                            Spacer()
                            if selectedGameMode == .fourPlayers {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(selectedGameMode == .fourPlayers ? Color.blue.opacity(0.2) : Color.gray.opacity(0.1))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(selectedGameMode == .fourPlayers ? Color.blue : Color.clear, lineWidth: 2)
                                )
                        )
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal)

                // Start game button
                NavigationLink(destination:
                    WorkingGameScreen(gameState: createGameState(mode: selectedGameMode))
                        .environmentObject(SimpleNavigationManager())
                        .environmentObject(AccessibilityManager())
                        .environmentObject(HapticManager())
                        .environmentObject(AudioManager())
                        .environmentObject(AnimationManager())
                ) {
                    HStack {
                        Image(systemName: "play.fill")
                        Text("Începe Jocul")
                            .font(.headline.weight(.semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        LinearGradient(
                            colors: [Color.blue, Color.purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(radius: 8)
                }
                .padding(.horizontal)

                Spacer()
            }
            .padding()
            .navigationTitle("Configurare Joc")
        }
    }

    private func createGameState(mode: GameMode) -> GameState {
        let players: [Player]

        switch mode {
        case .twoPlayers:
            // Traditional 2-player mode
            let humanPlayer = Player(name: "Jucătorul")
            let aiPlayer = AIPlayer(name: "Adversar", difficulty: .medium)
            players = [humanPlayer, aiPlayer]

        case .fourPlayers:
            // 4-player team mode (2v2)
            let humanPlayer = Player(name: "Tu")
            let opponent1 = AIPlayer(name: "Adversar 1", difficulty: .medium)
            let partner = AIPlayer(name: "Partenerul Tău", difficulty: .medium)
            let opponent2 = AIPlayer(name: "Adversar 2", difficulty: .medium)
            players = [humanPlayer, opponent1, partner, opponent2]

        case .threePlayers:
            // 3-player mode (not yet fully implemented)
            let humanPlayer = Player(name: "Jucătorul")
            let aiPlayer1 = AIPlayer(name: "Adversar 1", difficulty: .medium)
            let aiPlayer2 = AIPlayer(name: "Adversar 2", difficulty: .medium)
            players = [humanPlayer, aiPlayer1, aiPlayer2]
        }

        let gameState = GameState(players: players)
        gameState.gameMode = mode
        return gameState
    }
}
