import SwiftUI

struct GameSetupView: View {
    let onStart: (GameState) -> Void

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

                NavigationLink(destination: WorkingGameScreen(gameState: createGameState())) {
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

    private func createGameState() -> GameState {
        // Create proper game state for Romanian Septica
        let humanPlayer = Player(name: "Jucătorul")
        let aiPlayer = AIPlayer(name: "Adversar")
        return GameState(players: [humanPlayer, aiPlayer])
    }
}
