import Foundation
import Combine

enum DialogueEvent {
    case gameStart
    case victory
    case sevenPlayed
    case strategicMove
    case goodPlay
}

@MainActor
final class RomanianDialogueSystem: ObservableObject {
    @Published private(set) var currentDialogue: String?

    var isShowingDialogue: Bool {
        currentDialogue != nil
    }

    func triggerDialogue(for event: DialogueEvent, character: RomanianCharacterAvatar) {
        switch event {
        case .gameStart:
            currentDialogue = "Bun venit la o nouă rundă!"
        case .victory:
            currentDialogue = "Felicitări pentru victorie!"
        case .sevenPlayed:
            currentDialogue = "Șeptarul a schimbat jocul!"
        case .strategicMove:
            currentDialogue = "Mișcare inspirată!"
        case .goodPlay:
            currentDialogue = "Frumos jucat!"
        }
        Task { [weak self] in
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            await self?.clearDialogue()
        }
    }

    private func clearDialogue() {
        currentDialogue = nil
    }
}
