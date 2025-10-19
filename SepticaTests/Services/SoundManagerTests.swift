//
//  SoundManagerTests.swift
//  SepticaTests
//
//  Tests for SoundManager multimodal feedback system
//

import XCTest
@testable import Septica

@MainActor
final class SoundManagerTests: XCTestCase {

    var soundManager: SoundManager!

    override func setUp() async throws {
        try await super.setUp()
        soundManager = SoundManager.shared
        // Reset to defaults
        soundManager.setSoundEnabled(true)
        soundManager.setVolume(0.7)
    }

    override func tearDown() async throws {
        soundManager.stopAllSounds()
        try await super.tearDown()
    }

    // MARK: - Initialization Tests

    func testSingletonInitialization() {
        // Given/When
        let instance1 = SoundManager.shared
        let instance2 = SoundManager.shared

        // Then
        XCTAssertTrue(instance1 === instance2, "Should return same singleton instance")
    }

    func testDefaultInitialState() {
        // Then
        XCTAssertTrue(soundManager.isSoundEnabled, "Sound should be enabled by default")
        XCTAssertEqual(soundManager.soundVolume, 0.7, accuracy: 0.01, "Default volume should be 0.7")
    }

    // MARK: - Sound Enable/Disable Tests

    func testSoundEnabling() {
        // Given
        soundManager.setSoundEnabled(false)

        // When
        soundManager.setSoundEnabled(true)

        // Then
        XCTAssertTrue(soundManager.isSoundEnabled, "Sound should be enabled")
    }

    func testSoundDisabling() {
        // Given
        soundManager.setSoundEnabled(true)

        // When
        soundManager.setSoundEnabled(false)

        // Then
        XCTAssertFalse(soundManager.isSoundEnabled, "Sound should be disabled")
    }

    // MARK: - Volume Control Tests

    func testVolumeSettingInRange() {
        // When
        soundManager.setVolume(0.5)

        // Then
        XCTAssertEqual(soundManager.soundVolume, 0.5, accuracy: 0.01)
    }

    func testVolumeClampingMax() {
        // When: Try to set volume above 1.0
        soundManager.setVolume(1.5)

        // Then: Should clamp to 1.0
        XCTAssertEqual(soundManager.soundVolume, 1.0, accuracy: 0.01, "Volume should clamp to 1.0")
    }

    func testVolumeClampingMin() {
        // When: Try to set volume below 0.0
        soundManager.setVolume(-0.5)

        // Then: Should clamp to 0.0
        XCTAssertEqual(soundManager.soundVolume, 0.0, accuracy: 0.01, "Volume should clamp to 0.0")
    }

    func testVolumeEdgeCases() {
        // Test zero
        soundManager.setVolume(0.0)
        XCTAssertEqual(soundManager.soundVolume, 0.0, accuracy: 0.01)

        // Test maximum
        soundManager.setVolume(1.0)
        XCTAssertEqual(soundManager.soundVolume, 1.0, accuracy: 0.01)

        // Test mid-range
        soundManager.setVolume(0.5)
        XCTAssertEqual(soundManager.soundVolume, 0.5, accuracy: 0.01)
    }

    // MARK: - Emote Sound Tests

    func testPlayEmoteSoundWhenEnabled() {
        // Given
        soundManager.setSoundEnabled(true)

        // When/Then: Should not crash
        XCTAssertNoThrow(soundManager.playEmoteSound(for: .greeting))
        XCTAssertNoThrow(soundManager.playEmoteSound(for: .victory))
        XCTAssertNoThrow(soundManager.playEmoteSound(for: .defeat))
    }

    func testPlayEmoteSoundWhenDisabled() {
        // Given
        soundManager.setSoundEnabled(false)

        // When/Then: Should not crash (should just return early)
        XCTAssertNoThrow(soundManager.playEmoteSound(for: .greeting))
    }

    func testAllEmoteTypesHaveSound() {
        // Given
        soundManager.setSoundEnabled(true)

        // When/Then: All emote types should be playable
        for emoteType in EmoteType.allCases {
            XCTAssertNoThrow(soundManager.playEmoteSound(for: emoteType),
                           "Should handle \(emoteType) without crashing")
        }
    }

    func testEmoteSoundWithoutHaptics() {
        // Given
        soundManager.setSoundEnabled(true)

        // When/Then: Should support disabling haptics
        XCTAssertNoThrow(soundManager.playEmoteSound(for: .greeting, withHaptics: false))
    }

    // MARK: - Game Sound Tests

    func testCardSelectSound() {
        // Given
        soundManager.setSoundEnabled(true)

        // When/Then
        XCTAssertNoThrow(soundManager.playCardSelectSound())
    }

    func testCardPlaySound() {
        // Given
        soundManager.setSoundEnabled(true)

        // When/Then
        XCTAssertNoThrow(soundManager.playCardPlaySound())
    }

    func testTrickCompleteSound() {
        // Given
        soundManager.setSoundEnabled(true)

        // When/Then
        XCTAssertNoThrow(soundManager.playTrickCompleteSound())
    }

    func testVictorySound() {
        // Given
        soundManager.setSoundEnabled(true)

        // When/Then
        XCTAssertNoThrow(soundManager.playVictorySound())
    }

    func testDefeatSound() {
        // Given
        soundManager.setSoundEnabled(true)

        // When/Then
        XCTAssertNoThrow(soundManager.playDefeatSound())
    }

    // MARK: - Sound Type Tests

    func testAllSoundTypesAvailable() {
        // Given
        soundManager.setSoundEnabled(true)

        // When/Then: All sound types should be playable
        for soundType in SoundManager.SoundType.allCases {
            XCTAssertNoThrow(soundManager.playSound(soundType, withHaptics: false),
                           "Should handle \(soundType) without crashing")
        }
    }

    func testSoundTypeMapping() {
        // Given
        let soundTypes = SoundManager.SoundType.allCases

        // Then: Each sound type should have a filename
        for soundType in soundTypes {
            XCTAssertFalse(soundType.filename.isEmpty, "\(soundType) should have a filename")
        }
    }

    // MARK: - Haptic Integration Tests

    func testEmoteSoundWithHapticsEnabled() {
        // Given
        soundManager.setSoundEnabled(true)

        // When/Then: Should trigger haptics along with sound
        XCTAssertNoThrow(soundManager.playEmoteSound(for: .victory, withHaptics: true))
    }

    func testGameSoundWithHapticsEnabled() {
        // Given
        soundManager.setSoundEnabled(true)

        // When/Then: Should trigger haptics along with sound
        XCTAssertNoThrow(soundManager.playSound(.cardPlay, withHaptics: true))
    }

    // MARK: - Stop All Sounds Tests

    func testStopAllSounds() {
        // Given
        soundManager.setSoundEnabled(true)
        soundManager.playCardPlaySound()
        soundManager.playVictorySound()

        // When
        soundManager.stopAllSounds()

        // Then: Should not crash
        XCTAssertNoThrow(soundManager.stopAllSounds())
    }

    // MARK: - Audio Session Tests

    func testResetAudioSession() {
        // When/Then: Should not crash
        XCTAssertNoThrow(soundManager.resetAudioSession())
    }

    func testHandleAudioInterruption() {
        // Given
        soundManager.playCardPlaySound()

        // When/Then: Should handle interruption gracefully
        XCTAssertNoThrow(soundManager.handleAudioInterruption())
    }

    // MARK: - Persistence Tests

    func testSoundEnabledPersistence() {
        // Given
        soundManager.setSoundEnabled(false)

        // When: Create new instance (in real app, would be after restart)
        let newManager = SoundManager.shared

        // Then: Should remember setting (singleton shares state)
        XCTAssertFalse(newManager.isSoundEnabled, "Sound enabled state should persist")

        // Cleanup
        soundManager.setSoundEnabled(true)
    }

    func testVolumePersistence() {
        // Given
        soundManager.setVolume(0.3)

        // When: Access shared instance
        let newManager = SoundManager.shared

        // Then: Should remember volume (singleton shares state)
        XCTAssertEqual(newManager.soundVolume, 0.3, accuracy: 0.01, "Volume should persist")

        // Cleanup
        soundManager.setVolume(0.7)
    }

    // MARK: - Concurrent Sound Tests

    func testMultipleSimultaneousSounds() {
        // Given
        soundManager.setSoundEnabled(true)

        // When: Play multiple sounds rapidly
        soundManager.playCardSelectSound()
        soundManager.playEmoteSound(for: .greeting)
        soundManager.playCardPlaySound()

        // Then: Should handle concurrent sounds without crashing
        XCTAssertNoThrow(soundManager.stopAllSounds())
    }

    // MARK: - Performance Tests

    func testEmoteSoundPerformance() {
        // Measure performance of playing emote sounds
        measure {
            for _ in 0..<100 {
                soundManager.playEmoteSound(for: .greeting, withHaptics: false)
            }
        }
    }

    func testGameSoundPerformance() {
        // Measure performance of playing game sounds
        measure {
            for _ in 0..<100 {
                soundManager.playCardSelectSound()
            }
        }
    }

    // MARK: - Edge Case Tests

    func testRapidEnableDisableToggling() {
        // When: Rapidly toggle sound enabled
        for _ in 0..<10 {
            soundManager.setSoundEnabled(false)
            soundManager.setSoundEnabled(true)
        }

        // Then: Should end in consistent state
        XCTAssertTrue(soundManager.isSoundEnabled)
    }

    func testRapidVolumeChanges() {
        // When: Rapidly change volume
        for i in 0..<10 {
            soundManager.setVolume(Float(i) / 10.0)
        }

        // Then: Should end with last value
        XCTAssertEqual(soundManager.soundVolume, 0.9, accuracy: 0.01)
    }
}
