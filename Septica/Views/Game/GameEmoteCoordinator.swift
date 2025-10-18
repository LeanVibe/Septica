//
//  GameEmoteCoordinator.swift
//  Septica
//
//  Elegant coordination between emote system and game interface
//  Handles real-time emote display and multiplayer integration
//

import SwiftUI

// MARK: - Game Emote Coordinator

/// Coordinates emote system with game interface for seamless multiplayer experience
@MainActor
class GameEmoteCoordinator: NSObject, ObservableObject, EmoteManagerDelegate {

    // MARK: - Published Properties

    @Published var activeEmotes: [UUID: EmoteDisplayState] = [:]
    @Published var emoteAnimations: [UUID: EmoteAnimationState] = [:]

    // MARK: - Private Properties

    private weak var gameScreen: MultiplayerReadyGameScreen?
    private weak var emoteManager: EmoteManager?
    private let soundManager = SoundManager.shared
    private var players: [Player] = []

    // MARK: - Emote Display State

    struct EmoteDisplayState {
        let emote: EmoteMessage
        let startTime: Date
        let isAnimating: Bool
        var completionTime: Date { startTime.addingTimeInterval(emote.duration) }

        var isActive: Bool {
            Date() < completionTime
        }
    }

    struct EmoteAnimationState {
        var scale: Double = 0.1
        var opacity: Double = 0.0
        var rotation: Double = 0.0
        var position: CGPoint = .zero

        mutating func startAnimation() {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.5)) {
                scale = 1.0
                opacity = 1.0
                rotation = 360.0
            }
        }

        mutating func endAnimation() {
            withAnimation(.easeOut(duration: 0.3)) {
                scale = 0.8
                opacity = 0.0
                rotation = 0.0
            }
        }
    }

    // MARK: - Initialization

    init(gameScreen: MultiplayerReadyGameScreen, emoteManager: EmoteManager, players: [Player]) {
        self.gameScreen = gameScreen
        self.emoteManager = emoteManager
        self.players = players
        super.init()

        // Set self as delegate
        emoteManager.setDelegate(self)
    }

    // MARK: - Emote Manager Delegate

    func emoteManager(_ manager: EmoteManager, didReceiveEmote emote: EmoteMessage) {
        // Create display state
        let displayState = EmoteDisplayState(
            emote: emote,
            startTime: Date(),
            isAnimating: true
        )

        activeEmotes[emote.playerId] = displayState

        // Start animation
        emoteAnimations[emote.playerId] = EmoteAnimationState()
        emoteAnimations[emote.playerId]?.startAnimation()

        // Play sound effect
        playEmoteSound(emote.emoteType, for: emote.characterType)

        // Schedule cleanup
        scheduleEmoteCleanup(for: emote)
    }

    func emoteManager(_ manager: EmoteManager, didUpdatePlayerStatus playerId: UUID, isEmoting: Bool) {
        if !isEmoting {
            // End animation
            emoteAnimations[playerId]?.endAnimation()

            // Schedule removal after animation completes
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                self?.activeEmotes.removeValue(forKey: playerId)
                self?.emoteAnimations.removeValue(forKey: playerId)
            }
        }
    }

    func emoteManager(_ manager: EmoteManager, didEncounterError error: EmoteError) {
        // Handle emote errors gracefully
        print("⚠️ Emote error: \(error.localizedDescription)")

        // Could show user feedback here
        // For now, just log the error
    }

    // MARK: - Public Interface

    /// Send emote from current player
    func sendEmote(_ emoteType: EmoteType, from playerId: UUID, in gameId: String) async {
        let characterType = getPlayerCharacterType(for: playerId)

        let emote = EmoteMessage(
            playerId: playerId,
            emoteType: emoteType,
            gameId: gameId,
            characterType: characterType,
            intensity: 1.0,
            duration: getEmoteDuration(emoteType)
        )

        do {
            // Get emote manager from game screen
            if let emoteManager = getEmoteManager() {
                try await emoteManager.sendEmote(emote)

                // Play local sound immediately for better UX
                playEmoteSound(emoteType, for: characterType)
            }
        } catch {
            print("⚠️ Failed to send emote: \(error)")
        }
    }

    /// Get emote overlay for specific player
    func emoteOverlay(for playerId: UUID) -> some View {
        if let emoteState = activeEmotes[playerId],
           let animationState = emoteAnimations[playerId] {
            return EmoteOverlayView(
                emoteState: emoteState,
                animationState: animationState
            )
        }
        return EmptyView()
    }

    /// Cleanup expired emotes
    func cleanupExpiredEmotes() {
        let now = Date()
        let expiredIds = activeEmotes.compactMap { playerId, state in
            state.completionTime <= now ? playerId : nil
        }

        for playerId in expiredIds {
            activeEmotes.removeValue(forKey: playerId)
            emoteAnimations.removeValue(forKey: playerId)
        }
    }

    // MARK: - Private Methods

    private func playEmoteSound(_ emoteType: EmoteType, for characterType: RomanianCharacterType) {
        let soundName = getSoundName(for: emoteType, characterType: characterType)
        soundManager.playEmoteSound(soundName)
    }

    private func getSoundName(for emoteType: EmoteType, characterType: RomanianCharacterType) -> String {
        switch (characterType, emoteType) {
        case (.pacala, .greeting): return "pacala_greeting"
        case (.pacala, .taunt): return "pacala_taunt"
        case (.pacala, .victory): return "pacala_victory"
        case (.iele, .greeting): return "iele_greeting"
        case (.iele, .thinking): return "iele_thinking"
        case (.strigoi, .taunt): return "strigoi_taunt"
        case (.strigoi, .defeat): return "strigoi_defeat"
        case (.fatFrumos, .victory): return "fat_frumos_victory"
        case (.fatFrumos, .goodMove): return "fat_frumos_good_move"
        case (.babaCloantza, .badMove): return "baba_cloantza_bad_move"
        case (.babaCloantza, .thinking): return "baba_cloantza_thinking"
        case (.zmeu, .victory): return "zmeu_victory"
        case (.zmeu, .taunt): return "zmeu_taunt"
        default: return "default_emote"
        }
    }

    private func getPlayerCharacterType(for playerId: UUID) -> RomanianCharacterType {
        if let player = players.first(where: { $0.id == playerId }) {
            return player.romanianAvatar.characterType
        }
        return .pacala // Fallback default
    }

    private func getEmoteDuration(_ emoteType: EmoteType) -> TimeInterval {
        switch emoteType {
        case .greeting: return 2.0
        case .goodMove: return 1.5
        case .badMove: return 2.0
        case .thinking: return 3.0
        case .taunt: return 2.5
        case .victory: return 4.0
        case .defeat: return 2.0
        }
    }

    private func scheduleEmoteCleanup(for emote: EmoteMessage) {
        DispatchQueue.main.asyncAfter(deadline: .now() + emote.duration + 0.5) { [weak self] in
            self?.activeEmotes.removeValue(forKey: emote.playerId)
        }
    }

    private func getEmoteManager() -> EmoteManager? {
        return emoteManager
    }
}

// MARK: - Emote Overlay View

struct EmoteOverlayView: View {
    let emoteState: GameEmoteCoordinator.EmoteDisplayState
    @State private var animationState: GameEmoteCoordinator.EmoteAnimationState

    init(emoteState: GameEmoteCoordinator.EmoteDisplayState, animationState: GameEmoteCoordinator.EmoteAnimationState) {
        self.emoteState = emoteState
        self._animationState = State(initialValue: animationState)
    }

    var body: some View {
        VStack(spacing: 8) {
            // Character-specific emote display
            characterEmoteView

            // Emote text
            Text(emoteState.emote.emoteType.rawValue)
                .font(.caption.weight(.semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(Color.black.opacity(0.7))
                        .overlay(
                            Capsule()
                                .stroke(Color.white.opacity(0.3), lineWidth: 1)
                        )
                )
        }
        .scaleEffect(animationState.scale)
        .opacity(animationState.opacity)
        .rotationEffect(.degrees(animationState.rotation))
        .offset(animationState.position)
        .animation(.spring(response: 0.6, dampingFraction: 0.5), value: animationState.scale)
        .animation(.easeOut(duration: 0.3), value: animationState.opacity)
    }

    private var characterEmoteView: some View {
        Group {
            switch emoteState.emote.characterType {
            case .pacala:
                PacalaEmoteView(emoteType: emoteState.emote.emoteType)
            case .iele:
                IeleEmoteView(emoteType: emoteState.emote.emoteType)
            case .strigoi:
                StrigoiEmoteView(emoteType: emoteState.emote.emoteType)
            case .fatFrumos:
                FatFrumosEmoteView(emoteType: emoteState.emote.emoteType)
            case .babaCloantza:
                BabaCloantzaEmoteView(emoteType: emoteState.emote.emoteType)
            case .zmeu:
                ZmeuEmoteView(emoteType: emoteState.emote.emoteType)
            }
        }
        .frame(width: 60, height: 60)
    }
}

// MARK: - Character Emote Views

struct PacalaEmoteView: View {
    let emoteType: EmoteType

    var body: some View {
        VStack(spacing: 2) {
            Image(systemName: emoteIcon)
                .font(.title2)
                .foregroundColor(RomanianColors.goldAccent)

            Text("🎭")
                .font(.caption)
        }
    }

    private var emoteIcon: String {
        switch emoteType {
        case .greeting: return "hand.wave.fill"
        case .goodMove: return "hand.thumbsup.fill"
        case .badMove: return "hand.thumbsdown.fill"
        case .thinking: return "brain.head.profile"
        case .taunt: return "face.dashed.fill"
        case .victory: return "trophy.fill"
        case .defeat: return "heart.slash.fill"
        }
    }
}

struct IeleEmoteView: View {
    let emoteType: EmoteType

    var body: some View {
        VStack(spacing: 2) {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color(hex: "#E6E6FA"), Color(hex: "#DDA0DD")],
                        center: .center,
                        startRadius: 5,
                        endRadius: 25
                    )
                )
                .frame(width: 40, height: 40)
                .overlay(
                    Text(emoteEmoji)
                        .font(.title3)
                )

            Text("✨")
                .font(.caption2)
        }
    }

    private var emoteEmoji: String {
        switch emoteType {
        case .greeting: return "👋"
        case .goodMove: return "💫"
        case .badMove: return "💔"
        case .thinking: return "🤔"
        case .taunt: return "😏"
        case .victory: return "🌟"
        case .defeat: return "😢"
        }
    }
}

struct StrigoiEmoteView: View {
    let emoteType: EmoteType

    var body: some View {
        VStack(spacing: 2) {
            ZStack {
                Circle()
                    .fill(Color(hex: "#483D8B"))
                    .frame(width: 40, height: 40)

                Image(systemName: emoteIcon)
                    .font(.title3)
                    .foregroundColor(.white)
            }

            Text("👻")
                .font(.caption2)
        }
    }

    private var emoteIcon: String {
        switch emoteType {
        case .greeting: return "sparkles"
        case .goodMove: return "flame.fill"
        case .badMove: return "xmark.circle.fill"
        case .thinking: return "eye.circle.fill"
        case .taunt: return "theatermasks.fill"
        case .victory: return "crown.fill"
        case .defeat: return "cloud.bolt.fill"
        }
    }
}

struct FatFrumosEmoteView: View {
    let emoteType: EmoteType

    var body: some View {
        VStack(spacing: 2) {
            Image(systemName: emoteIcon)
                .font(.title2)
                .foregroundColor(RomanianColors.goldAccent)

            Text("⚔️")
                .font(.caption2)
        }
    }

    private var emoteIcon: String {
        switch emoteType {
        case .greeting: return "figure.salute"
        case .goodMove: return "star.fill"
        case .badMove: return "xmark.seal.fill"
        case .thinking: return "brain"
        case .taunt: return "figure.fencing"
        case .victory: return "medal.fill"
        case .defeat: return "shield.slash"
        }
    }
}

struct BabaCloantzaEmoteView: View {
    let emoteType: EmoteType

    var body: some View {
        VStack(spacing: 2) {
            Image(systemName: emoteIcon)
                .font(.title2)
                .foregroundColor(Color(hex: "#8B4513"))

            Text("🧙‍♀️")
                .font(.caption2)
        }
    }

    private var emoteIcon: String {
        switch emoteType {
        case .greeting: return "hand.wave"
        case .goodMove: return "checkmark.circle.fill"
        case .badMove: return "xmark.circle.fill"
        case .thinking: return "eye"
        case .taunt: return "exclamationmark.triangle.fill"
        case .victory: return "star.circle"
        case .defeat: return "moon.fill"
        }
    }
}

struct ZmeuEmoteView: View {
    let emoteType: EmoteType

    var body: some View {
        VStack(spacing: 2) {
            Image(systemName: emoteIcon)
                .font(.title2)
                .foregroundColor(RomanianColors.countrysideGreen)

            Text("🐉")
                .font(.caption2)
        }
    }

    private var emoteIcon: String {
        switch emoteType {
        case .greeting: return "flame.fill"
        case .goodMove: return "star.fill"
        case .badMove: return "tornado"
        case .thinking: return "brain"
        case .taunt: return "flame.circle.fill"
        case .victory: return "crown.fill"
        case .defeat: return "smoke.fill"
        }
    }
}

// MARK: - Preview

struct GameEmoteCoordinator_Previews: PreviewProvider {
    static var previews: some View {
        let coordinator = GameEmoteCoordinator(gameScreen: MultiplayerReadyGameScreen())

        return VStack(spacing: 20) {
            EmoteOverlayView(
                emoteState: GameEmoteCoordinator.EmoteDisplayState(
                    emote: EmoteMessage(
                        playerId: UUID(),
                        emoteType: .victory,
                        gameId: "test",
                        characterType: .pacala
                    ),
                    startTime: Date(),
                    isAnimating: true
                ),
                animationState: GameEmoteCoordinator.EmoteAnimationState()
            )

            EmoteOverlayView(
                emoteState: GameEmoteCoordinator.EmoteDisplayState(
                    emote: EmoteMessage(
                        playerId: UUID(),
                        emoteType: .greeting,
                        gameId: "test",
                        characterType: .iele
                    ),
                    startTime: Date(),
                    isAnimating: true
                ),
                animationState: GameEmoteCoordinator.EmoteAnimationState()
            )
        }
        .padding()
        .background(Color.black)
    }
}