import Foundation
import Combine

@MainActor
final class TraditionalGameplayMilestoneTracker: ObservableObject {
    struct TraditionalMilestone: Identifiable, Hashable {
        let id: UUID
        let title: String
        let progress: Int
    }

    @Published private(set) var recentMilestones: [TraditionalMilestone] = []

    func trackGameEvent(_ event: GameEventType) {
        switch event {
        case .gameStarted:
            recordMilestone(title: "Game Started")
        case .gameWon:
            recordMilestone(title: "Game Won")
        }
    }

    private func recordMilestone(title: String) {
        let milestone = TraditionalMilestone(id: UUID(), title: title, progress: 100)
        recentMilestones.append(milestone)
        if recentMilestones.count > 5 {
            recentMilestones.removeFirst(recentMilestones.count - 5)
        }
    }
}
