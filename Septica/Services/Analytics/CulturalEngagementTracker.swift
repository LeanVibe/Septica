import Foundation
import Combine

@MainActor
final class CulturalEngagementTracker: ObservableObject {
    struct EngagementSnapshot: Identifiable {
        let id = UUID()
        let timestamp: Date
        let culturalScore: Float
    }

    @Published private(set) var history: [EngagementSnapshot] = []

    func recordCulturalInteraction(score: Float) {
        let snapshot = EngagementSnapshot(timestamp: Date(), culturalScore: min(1.0, max(0.0, score)))
        history.append(snapshot)
        if history.count > 10 {
            history.removeFirst(history.count - 10)
        }
    }
}
