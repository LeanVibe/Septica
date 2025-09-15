//
//  AudioManager.swift
//  Septica
//
//  Comprehensive audio system for Romanian Septica card game
//  Provides game sounds, Romanian cultural music, and accessibility audio cues
//

import AVFoundation
import SwiftUI
import Combine

/// Centralized audio management for the entire application
@MainActor
class AudioManager: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var isSoundEnabled = true
    @Published var isMusicEnabled = true
    @Published var isAccessibilityAudioEnabled = true
    @Published var soundVolume: Float = 0.7
    @Published var musicVolume: Float = 0.4
    @Published var currentlyPlayingMusic: String?
    
    // MARK: - Audio Players
    
    private var audioEngine = AVAudioEngine()
    private var musicPlayer: AVAudioPlayer?
    private var soundEffectPlayers: [String: AVAudioPlayer] = [:]
    private var audioSession = AVAudioSession.sharedInstance()
    
    // MARK: - Audio Types
    
    enum SoundEffect: String, CaseIterable {
        // Card sounds
        case cardShuffle = "card_shuffle"
        case cardPlace = "card_place"
        case cardFlip = "card_flip"
        case cardSelect = "card_select"
        case cardInvalid = "card_invalid"
        
        // Game events
        case scoreIncrease = "score_increase"
        case trickWon = "trick_won"
        case roundComplete = "round_complete"
        case gameVictory = "game_victory"
        case gameDefeat = "game_defeat"
        
        // Menu sounds
        case menuSelect = "menu_select"
        case menuConfirm = "menu_confirm"
        case menuCancel = "menu_cancel"
        case menuTransition = "menu_transition"
        
        // Romanian cultural sounds
        case traditionalBell = "traditional_bell"
        case celebration = "celebration"
        
        // Accessibility sounds
        case focusChange = "focus_change"
        case announcement = "announcement"
        case warning = "warning"
        case error = "error"
    }
    
    enum BackgroundMusic: String, CaseIterable {
        case menuTheme = "romanian_menu_theme"
        case gameplayTheme = "romanian_gameplay_theme"
        case victoryTheme = "victory_celebration"
        case traditionalFolk = "traditional_folk"
        
        // Traditional Romanian cultural music (public domain)
        case horaUnirii = "hora_unirii"           // Traditional Romanian folk dance
        case sarbaIernii = "sarba_iernii"         // Winter celebration music
        case jocMuntesc = "joc_muntesc"           // Mountain folk dance
        case doiDeTeai = "doi_de_teai"            // Traditional linden dance
        
        var culturalDescription: String {
            switch self {
            case .horaUnirii: return "Hora Unirii - Traditional Unity Dance"
            case .sarbaIernii: return "Sărbă Iernii - Winter Celebration"
            case .jocMuntesc: return "Joc Muntesc - Mountain Folk Dance"
            case .doiDeTeai: return "Doi de Tei - Traditional Linden Dance"
            default: return rawValue.replacingOccurrences(of: "_", with: " ").capitalized
            }
        }
    }
    
    // MARK: - Initialization
    
    init() {
        setupAudioSession()
        loadAudioPreferences()
        preloadSoundEffects()
    }
    
    deinit {
        Task { @MainActor in
            stopAllSounds()
        }
        audioEngine.stop()
    }
    
    // MARK: - Audio Session Setup
    
    private func setupAudioSession() {
        do {
            try audioSession.setCategory(.ambient, mode: .default, options: [.mixWithOthers])
            try audioSession.setActive(true)
        } catch {
            print("Failed to setup audio session: \(error)")
        }
    }
    
    // MARK: - Sound Effects
    
    /// Play a sound effect
    func playSound(_ effect: SoundEffect, volume: Float? = nil) {
        guard isSoundEnabled else { return }
        
        // Use system sounds for some effects as fallback
        switch effect {
        case .cardSelect:
            playSystemSound(1519) // Light haptic sound
        case .cardPlace:
            playSystemSound(1520) // Medium haptic sound
        case .cardInvalid:
            playSystemSound(1521) // Error sound
        case .menuSelect:
            playSystemSound(1519)
        case .error:
            playSystemSound(1107) // System error sound
        default:
            playCustomSound(effect, volume: volume)
        }
    }
    
    private func playCustomSound(_ effect: SoundEffect, volume: Float?) {
        // In a real implementation, these would be actual audio files
        // For now, we'll use system sounds and prepare the architecture
        
        let soundName = effect.rawValue
        let effectiveVolume = volume ?? soundVolume
        
        // Try to load and play custom audio file
        guard let player = soundEffectPlayers[soundName] else {
            // Fallback to system sound
            playSystemSound(1519)
            return
        }
        
        player.volume = effectiveVolume
        player.currentTime = 0
        player.play()
    }
    
    private func playSystemSound(_ soundID: UInt32) {
        AudioServicesPlaySystemSound(soundID)
    }
    
    // MARK: - Background Music
    
    /// Start background music
    func startBackgroundMusic(_ music: BackgroundMusic, fadeIn: Bool = true) {
        guard isMusicEnabled else { return }
        
        stopBackgroundMusic(fadeOut: false)
        
        // In a real implementation, load the actual audio file
        // For now, we'll set up the architecture
        currentlyPlayingMusic = music.rawValue
        
        // Simulate loading and playing background music
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            // Background music would start here
            print("Started background music: \(music.rawValue)")
        }
    }
    
    /// Stop background music
    func stopBackgroundMusic(fadeOut: Bool = true) {
        if fadeOut && musicPlayer != nil {
            fadeOutCurrentMusic()
        } else {
            musicPlayer?.stop()
            musicPlayer = nil
            currentlyPlayingMusic = nil
        }
    }
    
    private func fadeOutCurrentMusic() {
        // Implement fade out animation
        guard let player = musicPlayer else { return }
        
        let fadeSteps = 20
        let fadeInterval = 0.05
        let volumeDecrement = player.volume / Float(fadeSteps)
        
        for step in 1...fadeSteps {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(step) * fadeInterval) {
                player.volume = max(0, player.volume - volumeDecrement)
                if step == fadeSteps {
                    player.stop()
                    self.musicPlayer = nil
                    self.currentlyPlayingMusic = nil
                }
            }
        }
    }
    
    // MARK: - Preloading and Caching
    
    private func preloadSoundEffects() {
        // Preload commonly used sound effects
        let commonSounds: [SoundEffect] = [
            .cardPlace, .cardSelect, .menuSelect, .scoreIncrease
        ]
        
        for sound in commonSounds {
            preloadSound(sound)
        }
    }
    
    private func preloadSound(_ effect: SoundEffect) {
        let soundName = effect.rawValue
        
        // In a real implementation, load the actual audio file
        // For now, we'll create placeholder players
        
        // Try to load custom sound file
        guard let url = Bundle.main.url(forResource: soundName, withExtension: "mp3") ??
                        Bundle.main.url(forResource: soundName, withExtension: "wav") else {
            return
        }
        
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.prepareToPlay()
            player.volume = soundVolume
            soundEffectPlayers[soundName] = player
        } catch {
            print("Failed to load sound effect \(soundName): \(error)")
        }
    }
    
    // MARK: - Romanian Cultural Audio
    
    /// Play traditional Romanian card game sounds
    func playRomanianSound(_ type: RomanianSoundType) {
        switch type {
        case .gameStart:
            playSound(.traditionalBell)
        case .trickComplete:
            playSound(.celebration)
        case .gameVictory:
            startBackgroundMusic(.victoryTheme)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                self.playSound(.celebration)
            }
        case .respectfulDefeat:
            playSound(.traditionalBell, volume: 0.3)
        }
    }
    
    enum RomanianSoundType {
        case gameStart
        case trickComplete
        case gameVictory
        case respectfulDefeat
    }
    
    // MARK: - Accessibility Audio
    
    /// Play accessibility-specific audio cues
    func playAccessibilitySound(_ cue: AccessibilityCue) {
        guard isAccessibilityAudioEnabled else { return }
        
        switch cue {
        case .focusChanged:
            playSound(.focusChange, volume: 0.3)
        case .elementSelected:
            playSound(.menuSelect, volume: 0.4)
        case .invalidAction:
            playSound(.cardInvalid)
        case .actionCompleted:
            playSound(.menuConfirm, volume: 0.5)
        case .gameStateChanged:
            playSound(.announcement, volume: 0.4)
        case .warning:
            playSound(.warning)
        case .error:
            playSound(.error)
        }
    }
    
    enum AccessibilityCue {
        case focusChanged
        case elementSelected
        case invalidAction
        case actionCompleted
        case gameStateChanged
        case warning
        case error
    }
    
    // MARK: - Game-Specific Audio
    
    /// Play contextual audio for Septica game events
    func playSepticaGameAudio(for event: SepticaAudioEvent) {
        switch event {
        case .cardPlayValid(let isSpecialCard):
            playSound(isSpecialCard ? .scoreIncrease : .cardPlace)
        case .cardPlayInvalid:
            playSound(.cardInvalid)
        case .sevenPlayed:
            playRomanianSound(.trickComplete)
        case .roundWon:
            playSound(.trickWon)
        case .gameComplete(let won):
            playRomanianSound(won ? .gameVictory : .respectfulDefeat)
        case .newGame:
            playSound(.cardShuffle)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.startBackgroundMusic(.gameplayTheme)
            }
        }
    }
    
    enum SepticaAudioEvent {
        case cardPlayValid(isSpecialCard: Bool)
        case cardPlayInvalid
        case sevenPlayed
        case roundWon
        case gameComplete(won: Bool)
        case newGame
    }
    
    // MARK: - Volume Controls
    
    /// Set sound effects volume
    func setSoundVolume(_ volume: Float) {
        soundVolume = max(0.0, min(1.0, volume))
        
        // Update all preloaded players
        for player in soundEffectPlayers.values {
            player.volume = soundVolume
        }
        
        saveAudioPreferences()
    }
    
    /// Set background music volume
    func setMusicVolume(_ volume: Float) {
        musicVolume = max(0.0, min(1.0, volume))
        musicPlayer?.volume = musicVolume
        saveAudioPreferences()
    }
    
    // MARK: - Settings Management
    
    func setSoundEnabled(_ enabled: Bool) {
        isSoundEnabled = enabled
        if !enabled {
            stopAllSounds()
        }
        saveAudioPreferences()
    }
    
    func setMusicEnabled(_ enabled: Bool) {
        isMusicEnabled = enabled
        if !enabled {
            stopBackgroundMusic()
        }
        saveAudioPreferences()
    }
    
    func setAccessibilityAudioEnabled(_ enabled: Bool) {
        isAccessibilityAudioEnabled = enabled
        saveAudioPreferences()
    }
    
    // MARK: - Game End Celebration Audio
    
    /// Play narration audio file
    func playNarration(_ audioFile: String) {
        guard isSoundEnabled else { return }
        
        // Try to load and play the narration file
        guard let url = Bundle.main.url(forResource: audioFile, withExtension: "mp3") ??
                        Bundle.main.url(forResource: audioFile, withExtension: "wav") else {
            // Fallback to system sound if file not found
            playSystemSound(1519)
            return
        }
        
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.volume = soundVolume * 0.8 // Slightly lower volume for narration
            player.play()
        } catch {
            print("Failed to play narration \(audioFile): \(error)")
            // Fallback to system sound
            playSystemSound(1519)
        }
    }
    
    // MARK: - Utility Functions
    
    /// Stop all currently playing sounds
    private func stopAllSounds() {
        for player in soundEffectPlayers.values {
            player.stop()
        }
        stopBackgroundMusic()
    }
    
    /// Pause all audio for interruptions
    func pauseAllAudio() {
        musicPlayer?.pause()
        for player in soundEffectPlayers.values {
            if player.isPlaying {
                player.pause()
            }
        }
    }
    
    /// Resume all audio after interruption
    func resumeAllAudio() {
        if isMusicEnabled, let _ = currentlyPlayingMusic {
            musicPlayer?.play()
        }
    }
    
    // MARK: - Persistence
    
    private func loadAudioPreferences() {
        let defaults = UserDefaults.standard
        
        isSoundEnabled = defaults.object(forKey: "audio_sound_enabled") as? Bool ?? true
        isMusicEnabled = defaults.object(forKey: "audio_music_enabled") as? Bool ?? true
        isAccessibilityAudioEnabled = defaults.object(forKey: "audio_accessibility_enabled") as? Bool ?? true
        soundVolume = defaults.object(forKey: "audio_sound_volume") as? Float ?? 0.7
        musicVolume = defaults.object(forKey: "audio_music_volume") as? Float ?? 0.4
    }
    
    private func saveAudioPreferences() {
        let defaults = UserDefaults.standard
        
        defaults.set(isSoundEnabled, forKey: "audio_sound_enabled")
        defaults.set(isMusicEnabled, forKey: "audio_music_enabled")
        defaults.set(isAccessibilityAudioEnabled, forKey: "audio_accessibility_enabled")
        defaults.set(soundVolume, forKey: "audio_sound_volume")
        defaults.set(musicVolume, forKey: "audio_music_volume")
    }
}

// MARK: - SwiftUI Integration

extension View {
    /// Add audio feedback to any view interaction
    func audioFeedback(_ sound: AudioManager.SoundEffect, manager: AudioManager) -> some View {
        self.onTapGesture {
            manager.playSound(sound)
        }
    }
    
    /// Add contextual audio feedback
    func contextualAudio(
        success: AudioManager.SoundEffect,
        failure: AudioManager.SoundEffect,
        condition: Bool,
        manager: AudioManager
    ) -> some View {
        self.onTapGesture {
            manager.playSound(condition ? success : failure)
        }
    }
}

// MARK: - Audio Session Management

extension AudioManager {
    
    /// Handle audio interruptions (phone calls, etc.)
    func handleAudioInterruption(_ notification: Notification) {
        guard let info = notification.userInfo,
              let typeValue = info[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
            return
        }
        
        switch type {
        case .began:
            pauseAllAudio()
        case .ended:
            guard let optionsValue = info[AVAudioSessionInterruptionOptionKey] as? UInt else {
                return
            }
            let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
            if options.contains(.shouldResume) {
                resumeAllAudio()
            }
        @unknown default:
            break
        }
    }
}

// MARK: - Preview Support

#if DEBUG
extension AudioManager {
    static let preview: AudioManager = {
        let manager = AudioManager()
        manager.isSoundEnabled = false // Disable for previews
        manager.isMusicEnabled = false
        return manager
    }()
    
    /// Test all sound effects in sequence
    func testAllSounds() {
        let sounds = SoundEffect.allCases
        for (index, sound) in sounds.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.5) {
                self.playSound(sound)
            }
        }
    }
}
#endif