import SwiftUI

struct GameSetupView: View {
    let onStart: (GameState) -> Void

    var body: some View {
        Button("Start Game") {
            onStart(GameState(players: [Player(name: "Jucător"), AIPlayer(name: "Adversar")]))
        }
        .buttonStyle(.borderedProminent)
        .padding()
    }
}
