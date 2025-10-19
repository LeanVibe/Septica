//
//  SoundManager.swift
//  Septica
//
//  Elegant sound and haptic feedback manager for emotes and game events
//  Provides multimodal sensory feedback for enhanced user experience
//

import Foundation
import AVFoundation
import UIKit

// MARK: - Sound Manager

/// Manages sound effects and haptic feedback for game events and emotes
@MainActor
class SoundManager {

    // MARK: - Singleton

    static let shared = SoundManager()

    // MARK: - Properties

    private(set) var isSoundEnabled: Bool = true
    private(set) var soundVolume: Float = 0.7

    // MARK: - Private Properties

    private var audioPlayers: [SoundType: AVAudioPlayer] = [:]
    private let hapticManager = HapticManager.shared
    private let soundQueue = DispatchQueue(label: "com.septica.sounds", qos: .userInteractive)

    // MARK: - Sound Types

    enum SoundType: String, CaseIterable {
        // Emote sounds
        case emoteGreeting = "emote_greeting"
        case emoteGoodMove = "emote_good_move"
        case emoteBadMove = "emote_bad_move"
        case emoteThinking = "emote_thinking"
        case emoteTaunt = "emote_taunt"
        case emoteVictory = "emote_victory"
        case emoteDefeat = "emote_defeat"

        // Game sounds
        case cardPlay = "card_play"
        case cardSelect = "card_select"
        case cardShuffle = "card_shuffle"
        case trickcomplete = "trick_complete"
        case gameWin = "game_win"
        case gameLose = "game_lose"

        var filename: String {
            return rawValue
        }

        var fileExtension: String {
            return "mp3"
        }
    }

    // MARK: - Initialization

    private init() {
        setupAudioSession()
        loadUserPreferences()
    }

    // MARK: - Public Interface

    /// Play emote sound for specific emote type
    /// - Parameters:
    ///   - emote: The emote type to play sound for
    ///   - withHaptics: Whether to include haptic feedback (default: true)
    func playEmoteSound(for emote: EmoteType, withHaptics: Bool = true) {
        guard isSoundEnabled else { return }

        let soundType = mapEmoteToSound(emote)
        playSound(soundType, volume: soundVolume)

        // Coordinate with haptic feedback
        if withHaptics {
            playEmoteHaptic(for: emote)
        }
    }

    /// Play game event sound
    /// - Parameters:
    ///   - soundType: The sound type to play
    ///   - volume: Volume level (0.0 to 1.0)
    ///   - withHaptics: Whether to include haptic feedback
    func playSound(
        _ soundType: SoundType,
        volume: Float? = nil,
        withHaptics: Bool = true
    ) {
        guard isSoundEnabled else { return }

        soundQueue.async { [weak self] in
            guard let self = self else { return }

            DispatchQueue.main.async {
                // Use system sounds for now (proper audio files would be loaded here)
                self.playSystemSound(for: soundType)

                // Trigger haptics if requested
                if withHaptics {
                    self.playGameHaptic(for: soundType)
                }
            }
        }
    }

    /// Enable or disable sound
    func setSoundEnabled(_ enabled: Bool) {
        isSoundEnabled = enabled
        saveUserPreferences()
    }

    /// Set sound volume
    /// - Parameter volume: Volume level (0.0 to 1.0)
    func setVolume(_ volume: Float) {
        soundVolume = max(0.0, min(1.0, volume))
        saveUserPreferences()

        // Update all active players
        for (_, player) in audioPlayers {
            player.volume = soundVolume
        }
    }

    /// Stop all currently playing sounds
    func stopAllSounds() {
        for (_, player) in audioPlayers {
            player.stop()
        }
    }

    // MARK: - Private Methods

    private func setupAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.ambient, mode: .default, options: [.mixWithOthers])
            try audioSession.setActive(true)
        } catch {
            print("⚠️ Failed to setup audio session: \(error)")
        }
    }

    private func playSystemSound(for soundType: SoundType) {
        // Map sound types to system sound IDs
        // In production, this would load actual audio files
        let systemSoundId: SystemSoundID = mapToSystemSound(soundType)
        AudioServicesPlaySystemSound(systemSoundId)
    }

    private func mapToSystemSound(_ soundType: SoundType) -> SystemSoundID {
        // Map to appropriate system sounds
        // These are iOS system sounds that provide immediate feedback
        switch soundType {
        case .cardSelect:
            return 1104 // Tock sound
        case .cardPlay:
            return 1105 // Tock sound
        case .emoteGreeting:
            return 1053 // Soft notification
        case .emoteGoodMove:
            return 1057 // Success sound
        case .emoteBadMove:
            return 1073 // Alert sound
        case .emoteThinking:
            return 1104 // Subtle tock
        case .emoteTaunt:
            return 1106 // Playful sound
        case .emoteVictory:
            return 1054 // Triumphant
        case .emoteDefeat:
            return 1074 // Somber
        case .trickcomplete:
            return 1103 // Complete sound
        case .gameWin:
            return 1054 // Victory
        case .gameLose:
            return 1074 // Defeat
        case .cardShuffle:
            return 1155 // Shuffle
        }
    }

    private func mapEmoteToSound(_ emote: EmoteType) -> SoundType {
        switch emote {
        case .greeting:
            return .emoteGreeting
        case .goodMove:
            return .emoteGoodMove
        case .badMove:
            return .emoteBadMove
        case .thinking:
            return .emoteThinking
        case .taunt:
            return .emoteTaunt
        case .victory:
            return .emoteVictory
        case .defeat:
            return .emoteDefeat
        }
    }

    private func playEmoteHaptic(for emote: EmoteType) {
        // Map emotes to appropriate haptic feedback
        switch emote {
        case .greeting, .thinking:
            hapticManager.lightImpact()

        case .goodMove, .victory:
            hapticManager.trigger(.cardSelect)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                self?.hapticManager.trigger(.cardSelect)
            }

        case .badMove, .defeat:
            hapticManager.trigger(.cardInvalid)

        case .taunt:
            hapticManager.mediumImpact()
        }
    }

    private func playGameHaptic(for soundType: SoundType) {
        switch soundType {
        case .cardSelect:
            hapticManager.lightImpact()

        case .cardPlay:
            hapticManager.trigger(.cardPlay)

        case .trickcomplete:
            hapticManager.trigger(.trickWon)

        case .gameWin:
            hapticManager.trigger(.gameVictory)

        case .gameLose:
            hapticManager.trigger(.gameDefeat)

        default:
            break
        }
    }

    private func loadUserPreferences() {
        if let enabled = UserDefaults.standard.object(forKey: "soundEnabled") as? Bool {
            isSoundEnabled = enabled
        }

        if let volume = UserDefaults.standard.object(forKey: "soundVolume") as? Float {
            soundVolume = volume
        }
    }

    private func saveUserPreferences() {
        UserDefaults.standard.set(isSoundEnabled, forKey: "soundEnabled")
        UserDefaults.standard.set(soundVolume, forKey: "soundVolume")
    }

    // MARK: - Convenience Methods

    /// Play card selection sound with haptics
    func playCardSelectSound() {
        playSound(.cardSelect, withHaptics: true)
    }

    /// Play card play sound with haptics
    func playCardPlaySound() {
        playSound(.cardPlay, withHaptics: true)
    }

    /// Play trick complete sound with celebration haptics
    func playTrickCompleteSound() {
        playSound(.trickcomplete, withHaptics: true)
    }

    /// Play victory sound with celebration haptics
    func playVictorySound() {
        playSound(.gameWin, withHaptics: true)
    }

    /// Play defeat sound with subtle haptics
    func playDefeatSound() {
        playSound(.gameLose, withHaptics: true)
    }
}

// MARK: - Audio Session Extensions

extension SoundManager {
    /// Reset audio session (useful after interruptions)
    func resetAudioSession() {
        setupAudioSession()
    }

    /// Handle audio interruption
    func handleAudioInterruption() {
        stopAllSounds()
        resetAudioSession()
    }
}
