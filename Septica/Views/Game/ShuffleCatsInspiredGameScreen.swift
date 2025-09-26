import SwiftUI

struct ShuffleCatsInspiredGameScreen: View {
    let gameState: GameState

    var body: some View {
        WorkingGameScreen(gameState: gameState)
    }
}
