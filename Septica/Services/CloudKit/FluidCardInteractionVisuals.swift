import Foundation
import Combine

@MainActor
final class FluidCardInteractionVisuals: ObservableObject {
    struct CardAnimation: Identifiable, Equatable {
        let id = UUID()
        let cardID: String
        let duration: TimeInterval
    }

    @Published private(set) var activeAnimations: [CardAnimation] = []

    func playCardAnimation(for card: Card) {
        let animation = CardAnimation(cardID: card.id.uuidString, duration: 0.4)
        activeAnimations.append(animation)
        Task { [weak self] in
            try? await Task.sleep(nanoseconds: 400_000_000)
            await self?.removeAnimation(animation)
        }
    }

    private func removeAnimation(_ animation: CardAnimation) {
        activeAnimations.removeAll { $0.id == animation.id }
    }
}
