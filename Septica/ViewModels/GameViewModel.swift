import Foundation
import Combine
import os.log

private typealias CoreGamePhase = GamePhase

@MainActor
final class GameViewModel: ObservableObject {
    enum Phase {
        case setup
        case playing
        case finished
    }

    typealias GamePhase = Phase

    @Published var gamePhase: Phase
    @Published private(set) var gameState: GameState
    @Published var currentArena: RomanianArena

    private let logger = Logger(subsystem: "dev.leanvibe.game.Septica", category: "GameViewModel")
    private var cancellable: AnyCancellable?

    init(gameState: GameState? = nil) {
        let resolvedState: GameState
        if let providedState = gameState {
            resolvedState = providedState
        } else {
            let human = Player(name: "Jucător")
            let opponent = AIPlayer(name: "Adversar", difficulty: .easy)
            resolvedState = GameState(players: [human, opponent])
        }
        self.gameState = resolvedState
        self.gamePhase = Self.convertPhase(resolvedState.phase)
        self.currentArena = resolvedState.players.first?.currentArena ?? .sateImarica

        cancellable = resolvedState.objectWillChange
            .sink { [weak self] _ in self?.objectWillChange.send() }
    }

    var players: [Player] {
        gameState.players
    }

    var currentPlayer: Player? {
        gameState.currentPlayer
    }

    var humanPlayer: Player? {
        players.first(where: { $0.isHuman })
    }

    var tableCards: [Card] {
        gameState.tableCards
    }

    var validMoves: [Card] {
        guard let human = humanPlayer else { return [] }
        return GameRules.validMoves(
            from: human.hand,
            against: gameState.topTableCard,
            tableCardsCount: gameState.tableCards.count
        )
    }

    var playerScores: [String: Int] {
        Dictionary(uniqueKeysWithValues: players.map { ($0.name, $0.score) })
    }

    var currentOpponentAvatar: RomanianCharacterAvatar {
        players.dropFirst().first?.romanianAvatar ?? .villageElder
    }

    var isHumanPlayerTurn: Bool {
        gameState.currentPlayer?.isHuman ?? false
    }

    func startGame() {
        gameState.setupNewGame()
        gamePhase = .playing
        currentArena = players.first?.currentArena ?? .sateImarica
        logger.info("Game started")
        endTurnIfNeeded()
    }

    func startNewGame() {
        startGame()
    }

    func canPlayCard(_ card: Card) -> Bool {
        validMoves.contains(card)
    }

    func playCard(_ card: Card) {
        guard let human = humanPlayer else { return }
        let result = gameState.playCard(card, by: human.id)
        if case .failure = result {
            logger.error("Invalid move attempted by human player")
            return
        }

        gamePhase = Self.convertPhase(gameState.phase)

        endTurnIfNeeded()
    }

    func endTurnIfNeeded() {
        guard !isHumanPlayerTurn, gamePhase == .playing else { return }
        Task { await performAIMove() }
    }

    func passCurrentTurn() {
        guard let human = humanPlayer else { return }

        // Clear objection state
        gameState.waitingForObjection = false
        gameState.objectionDeadline = nil
        gameState.validObjectionCards = []

        // Notify players of the pass action
        let event = GameEvent.playerPassed(playerId: human.id)
        players.forEach { $0.handleGameEvent(event) }

        logger.info("Player passed objection opportunity")

        // Continue with AI turn if needed
        endTurnIfNeeded()
    }

    private func performAIMove() async {
        guard let opponent = players.first(where: { !$0.isHuman }), gamePhase == .playing else { return }
        let moves = GameRules.validMoves(
            from: opponent.hand,
            against: gameState.topTableCard,
            tableCardsCount: gameState.tableCards.count
        )
        guard let card = await opponent.chooseCard(gameState: gameState, validMoves: moves) else { return }
        _ = gameState.playCard(card, by: opponent.id)
        gamePhase = Self.convertPhase(gameState.phase)
    }
    private static func convertPhase(_ statePhase: CoreGamePhase) -> Phase {
        switch statePhase {
        case .setup: return .setup
        case .playing: return .playing
        case .finished: return .finished
        case .paused: return .setup
        }
    }

}
