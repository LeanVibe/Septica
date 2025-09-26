import SwiftUI

struct CulturalInsightsView: View {
    @StateObject private var analytics = CulturalAuthenticityScoring()
    let gameState: GameState

    var body: some View {
        VStack(spacing: 16) {
            Text("Cultural Insights")
                .font(.title)
            Text("Authenticity score: \(analytics.score(for: gameState), specifier: "%.2f")")
        }
        .padding()
    }
}
