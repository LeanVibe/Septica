import SwiftUI

struct GameResultView: View {
    let result: GameResult

    var body: some View {
        VStack(spacing: 16) {
            Text("Game Over")
                .font(.largeTitle)
            if let winner = result.winnerId {
                Text("Winner: \(winner.uuidString)")
            } else {
                Text("The game ended in a tie")
            }
        }
        .padding()
    }
}
