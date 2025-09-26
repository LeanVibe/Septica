import SwiftUI

struct GameBoardView: View {
    let gameState: GameState

    var body: some View {
        WorkingGameScreen(gameState: gameState)
    }
}
