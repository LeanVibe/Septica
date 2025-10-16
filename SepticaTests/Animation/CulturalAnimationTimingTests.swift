//
//  CulturalAnimationTimingTests.swift
//  SepticaTests
//
//  Comprehensive tests for Romanian cultural animation timing
//  Validates folk dance timing integration and character-specific animations
//

import XCTest
@testable import Septica

final class CulturalAnimationTimingTests: XCTestCase {

    // MARK: - Test Properties

    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
    }

    // MARK: - Folk Dance Timing Constants Tests

    func testHoraDanceTimingConstants() {
        // THEN
        XCTAssertEqual(CulturalAnimationTiming.horaBeatInterval, 0.5, accuracy: 0.001)
        XCTAssertEqual(CulturalAnimationTiming.horaMeasureDuration, 4.0, accuracy: 0.001)
        XCTAssertEqual(CulturalAnimationTiming.horaCircleCompleteDuration, 16.0, accuracy: 0.001)

        // Verify mathematical relationships
        XCTAssertEqual(
            CulturalAnimationTiming.horaMeasureDuration,
            CulturalAnimationTiming.horaBeatInterval * 8.0,
            "Measure should be 8 beats"
        )
        XCTAssertEqual(
            CulturalAnimationTiming.horaCircleCompleteDuration,
            CulturalAnimationTiming.horaMeasureDuration * 4.0,
            "Circle should be 4 measures"
        )
    }

    func testCalusariDanceTimingConstants() {
        // THEN
        XCTAssertEqual(CulturalAnimationTiming.calusariBeatInterval, 0.43, accuracy: 0.001)
        XCTAssertEqual(CulturalAnimationTiming.calusariSequenceDuration, 2.6, accuracy: 0.001)

        // Verify sequence contains appropriate number of beats
        let expectedBeats = CulturalAnimationTiming.calusariSequenceDuration / CulturalAnimationTiming.calusariBeatInterval
        XCTAssertEqual(expectedBeats, 6.05, accuracy: 0.1, "Should be approximately 6 beats")
    }

    func testBrauDanceTimingConstants() {
        // THEN
        XCTAssertEqual(CulturalAnimationTiming.brauBeatInterval, 0.55, accuracy: 0.001)
        XCTAssertEqual(CulturalAnimationTiming.brauPhraseDuration, 4.4, accuracy: 0.001)

        // Verify phrase contains appropriate number of beats
        let expectedBeats = CulturalAnimationTiming.brauPhraseDuration / CulturalAnimationTiming.brauBeatInterval
        XCTAssertEqual(expectedBeats, 8.0, accuracy: 0.1, "Should be 8 beats per phrase")
    }

    func testSarbaDanceTimingConstants() {
        // THEN
        XCTAssertEqual(CulturalAnimationTiming.sarbaSlowInterval, 0.6, accuracy: 0.001)
        XCTAssertEqual(CulturalAnimationTiming.sarbaFastInterval, 0.4, accuracy: 0.001)

        // Fast should be faster than slow
        XCTAssertLessThan(
            CulturalAnimationTiming.sarbaFastInterval,
            CulturalAnimationTiming.sarbaSlowInterval,
            "Fast interval should be shorter than slow interval"
        )
    }

    func testGameSongTimingConstants() {
        // THEN
        XCTAssertEqual(CulturalAnimationTiming.gameSongIntroDuration, 2.0, accuracy: 0.001)
        XCTAssertEqual(CulturalAnimationTiming.gameSongVerseDuration, 4.0, accuracy: 0.001)
        XCTAssertEqual(CulturalAnimationTiming.gameSongChorusDuration, 2.5, accuracy: 0.001)

        // Verse should be longest
        XCTAssertGreaterThan(
            CulturalAnimationTiming.gameSongVerseDuration,
            CulturalAnimationTiming.gameSongIntroDuration
        )
        XCTAssertGreaterThan(
            CulturalAnimationTiming.gameSongVerseDuration,
            CulturalAnimationTiming.gameSongChorusDuration
        )
    }

    // MARK: - Card Game Timing Tests

    func testCardGameTimingConstants() {
        // THEN
        XCTAssertEqual(CulturalAnimationTiming.CardGameTiming.quickPlay, 0.8, accuracy: 0.001)
        XCTAssertEqual(CulturalAnimationTiming.CardGameTiming.thoughtfulPlay, 1.5, accuracy: 0.001)
        XCTAssertEqual(CulturalAnimationTiming.CardGameTiming.dramaticPlay, 2.0, accuracy: 0.001)
        XCTAssertEqual(CulturalAnimationTiming.CardGameTiming.victoryPlay, 1.2, accuracy: 0.001)
        XCTAssertEqual(CulturalAnimationTiming.CardGameTiming.passingPlay, 0.5, accuracy: 0.001)

        // Verify timing relationships
        XCTAssertLessThan(CulturalAnimationTiming.CardGameTiming.passingPlay, CulturalAnimationTiming.CardGameTiming.quickPlay)
        XCTAssertLessThan(CulturalAnimationTiming.CardGameTiming.quickPlay, CulturalAnimationTiming.CardGameTiming.victoryPlay)
        XCTAssertLessThan(CulturalAnimationTiming.CardGameTiming.victoryPlay, CulturalAnimationTiming.CardGameTiming.thoughtfulPlay)
        XCTAssertLessThan(CulturalAnimationTiming.CardGameTiming.thoughtfulPlay, CulturalAnimationTiming.CardGameTiming.dramaticPlay)
    }

    func testCharacterTimingConstants() {
        // THEN - Pacala timing
        XCTAssertEqual(CulturalAnimationTiming.CharacterTiming.pacalaQuick, 0.7, accuracy: 0.001)
        XCTAssertEqual(CulturalAnimationTiming.CharacterTiming.pacalaThoughtful, 1.8, accuracy: 0.001)

        // THEN - Iele timing
        XCTAssertEqual(CulturalAnimationTiming.CharacterTiming.ieleGraceful, 1.2, accuracy: 0.001)
        XCTAssertEqual(CulturalAnimationTiming.CharacterTiming.ieleMysterious, 2.0, accuracy: 0.001)

        // THEN - Strigoi timing
        XCTAssertEqual(CulturalAnimationTiming.CharacterTiming.strigoiDramatic, 1.0, accuracy: 0.001)
        XCTAssertEqual(CulturalAnimationTiming.CharacterTiming.strigoiMenacing, 1.5, accuracy: 0.001)

        // THEN - Făt-Frumos timing
        XCTAssertEqual(CulturalAnimationTiming.CharacterTiming.fatFrumosHeroic, 0.9, accuracy: 0.001)
        XCTAssertEqual(CulturalAnimationTiming.CharacterTiming.fatFrumosVictorious, 1.6, accuracy: 0.001)

        // THEN - Baba Cloanța timing
        XCTAssertEqual(CulturalAnimationTiming.CharacterTiming.babaCloantzaWise, 1.4, accuracy: 0.001)
        XCTAssertEqual(CulturalAnimationTiming.CharacterTiming.babaCloantzaGrumpy, 0.8, accuracy: 0.001)

        // THEN - Zmeu timing
        XCTAssertEqual(CulturalAnimationTiming.CharacterTiming.zmeuEnergetic, 0.6, accuracy: 0.001)
        XCTAssertEqual(CulturalAnimationTiming.CharacterTiming.zmeuVictorious, 1.3, accuracy: 0.001)
    }

    // MARK: - Card Play Timing Tests

    func testTimingForCardPlayQuickStyle() {
        // GIVEN
        let characterType = RomanianCharacterType.pacala
        let playStyle = CardPlayStyle.quick
        let isWinning = false

        // WHEN
        let timing = CulturalAnimationTiming.timingForCardPlay(
            characterType: characterType,
            playStyle: playStyle,
            isWinning: isWinning
        )

        // THEN
        let expectedTiming = CulturalAnimationTiming.CharacterTiming.pacalaQuick * 0.8
        XCTAssertEqual(timing, expectedTiming, accuracy: 0.001)
    }

    func testTimingForCardPlayThoughtfulStyle() {
        // GIVEN
        let characterType = RomanianCharacterType.iele
        let playStyle = CardPlayStyle.thoughtful
        let isWinning = false

        // WHEN
        let timing = CulturalAnimationTiming.timingForCardPlay(
            characterType: characterType,
            playStyle: playStyle,
            isWinning: isWinning
        )

        // THEN
        let expectedTiming = CulturalAnimationTiming.CharacterTiming.ieleGraceful * 1.5
        XCTAssertEqual(timing, expectedTiming, accuracy: 0.001)
    }

    func testTimingForCardPlayDramaticStyle() {
        // GIVEN
        let characterType = RomanianCharacterType.strigoi
        let playStyle = CardPlayStyle.dramatic
        let isWinning = false

        // WHEN
        let timing = CulturalAnimationTiming.timingForCardPlay(
            characterType: characterType,
            playStyle: playStyle,
            isWinning: isWinning
        )

        // THEN
        let expectedTiming = CulturalAnimationTiming.CharacterTiming.strigoiDramatic * 2.0
        XCTAssertEqual(timing, expectedTiming, accuracy: 0.001)
    }

    func testTimingForCardPlayStrategicStyle() {
        // GIVEN
        let characterType = RomanianCharacterType.fatFrumos
        let playStyle = CardPlayStyle.strategic
        let isWinning = false

        // WHEN
        let timing = CulturalAnimationTiming.timingForCardPlay(
            characterType: characterType,
            playStyle: playStyle,
            isWinning: isWinning
        )

        // THEN
        let expectedTiming = CulturalAnimationTiming.CharacterTiming.fatFrumosHeroic * 1.2
        XCTAssertEqual(timing, expectedTiming, accuracy: 0.001)
    }

    func testTimingForCardPlayWinningBonus() {
        // GIVEN
        let characterType = RomanianCharacterType.zmeu
        let playStyle = CardPlayStyle.quick
        let isWinning = true

        // WHEN
        let timing = CulturalAnimationTiming.timingForCardPlay(
            characterType: characterType,
            playStyle: playStyle,
            isWinning: isWinning
        )

        // THEN
        let expectedTiming = CulturalAnimationTiming.CharacterTiming.zmeuEnergetic * 0.8 + 0.3
        XCTAssertEqual(timing, expectedTiming, accuracy: 0.001)
    }

    func testTimingForCardPlayAllCharacters() {
        // GIVEN
        let characterTypes: [RomanianCharacterType] = [
            .pacala, .iele, .strigoi, .fatFrumos, .babaCloantza, .zmeu
        ]
        let playStyles: [CardPlayStyle] = [.quick, .thoughtful, .dramatic, .strategic]

        for characterType in characterTypes {
            for playStyle in playStyles {
                // WHEN
                let timing = CulturalAnimationTiming.timingForCardPlay(
                    characterType: characterType,
                    playStyle: playStyle,
                    isWinning: false
                )

                // THEN
                XCTAssertGreaterThan(timing, 0, "Timing should be positive for \(characterType) - \(playStyle)")
                XCTAssertLessThan(timing, 10.0, "Timing should be reasonable (< 10s)")
            }
        }
    }

    // MARK: - Card Selection Timing Tests

    func testTimingForCardSelectionInstant() {
        // GIVEN
        let characterType = RomanianCharacterType.pacala
        let selectionSpeed = SelectionSpeed.instant

        // WHEN
        let timing = CulturalAnimationTiming.timingForCardSelection(
            characterType: characterType,
            selectionSpeed: selectionSpeed
        )

        // THEN
        let expectedTiming = 0.8 * 0.3 // Pacala timing * instant multiplier
        XCTAssertEqual(timing, expectedTiming, accuracy: 0.001)
    }

    func testTimingForCardSelectionHesitant() {
        // GIVEN
        let characterType = RomanianCharacterType.babaCloantza
        let selectionSpeed = SelectionSpeed.hesitant

        // WHEN
        let timing = CulturalAnimationTiming.timingForCardSelection(
            characterType: characterType,
            selectionSpeed: selectionSpeed
        )

        // THEN
        let expectedTiming = 1.3 * 2.0 // Baba timing * hesitant multiplier
        XCTAssertEqual(timing, expectedTiming, accuracy: 0.001)
    }

    func testTimingForCardSelectionAllCharactersAndSpeeds() {
        // GIVEN
        let characterTypes: [RomanianCharacterType] = [
            .pacala, .iele, .strigoi, .fatFrumos, .babaCloantza, .zmeu
        ]
        let selectionSpeeds: [SelectionSpeed] = [
            .instant, .quick, .normal, .considered, .hesitant
        ]

        for characterType in characterTypes {
            for selectionSpeed in selectionSpeeds {
                // WHEN
                let timing = CulturalAnimationTiming.timingForCardSelection(
                    characterType: characterType,
                    selectionSpeed: selectionSpeed
                )

                // THEN
                XCTAssertGreaterThan(timing, 0, "Timing should be positive")
                XCTAssertLessThan(timing, 5.0, "Timing should be reasonable (< 5s)")
            }
        }
    }

    // MARK: - Victory Timing Tests

    func testTimingForVictoryDecisive() {
        // GIVEN
        let characterType = RomanianCharacterType.fatFrumos
        let victoryType = VictoryType.decisive

        // WHEN
        let timing = CulturalAnimationTiming.timingForVictory(
            characterType: characterType,
            victoryType: victoryType
        )

        // THEN
        let expectedTiming = CulturalAnimationTiming.CharacterTiming.fatFrumosVictorious * 1.0
        XCTAssertEqual(timing, expectedTiming, accuracy: 0.001)
    }

    func testTimingForVictoryDramatic() {
        // GIVEN
        let characterType = RomanianCharacterType.strigoi
        let victoryType = VictoryType.dramatic

        // WHEN
        let timing = CulturalAnimationTiming.timingForVictory(
            characterType: characterType,
            victoryType: victoryType
        )

        // THEN
        let expectedTiming = CulturalAnimationTiming.CharacterTiming.strigoiDramatic * 1.3
        XCTAssertEqual(timing, expectedTiming, accuracy: 0.001)
    }

    func testTimingForVictoryPerfect() {
        // GIVEN
        let characterType = RomanianCharacterType.pacala
        let victoryType = VictoryType.perfect

        // WHEN
        let timing = CulturalAnimationTiming.timingForVictory(
            characterType: characterType,
            victoryType: victoryType
        )

        // THEN
        let expectedTiming = 1.4 * 2.0 // Pacala victory * perfect multiplier
        XCTAssertEqual(timing, expectedTiming, accuracy: 0.001)
    }

    func testTimingForVictoryAllCharacters() {
        // GIVEN
        let characterTypes: [RomanianCharacterType] = [
            .pacala, .iele, .strigoi, .fatFrumos, .babaCloantza, .zmeu
        ]
        let victoryTypes: [VictoryType] = [
            .decisive, .dramatic, .upset, .perfect
        ]

        for characterType in characterTypes {
            for victoryType in victoryTypes {
                // WHEN
                let timing = CulturalAnimationTiming.timingForVictory(
                    characterType: characterType,
                    victoryType: victoryType
                )

                // THEN
                XCTAssertGreaterThan(timing, 0, "Victory timing should be positive")
                XCTAssertLessThan(timing, 10.0, "Victory timing should be reasonable (< 10s)")
            }
        }
    }

    // MARK: - Emote Timing Tests

    func testTimingForEmoteBasic() {
        // GIVEN
        let emoteType = EmoteType.greeting
        let characterType = RomanianCharacterType.pacala

        // WHEN
        let timing = CulturalAnimationTiming.timingForEmote(
            emoteType: emoteType,
            characterType: characterType
        )

        // THEN
        let expectedTiming = 1.0 * 1.0 // Greeting base * Pacala multiplier
        XCTAssertEqual(timing, expectedTiming, accuracy: 0.001)
    }

    func testTimingForEmoteWithDifferentMultipliers() {
        // GIVEN
        let characterTypes: [RomanianCharacterType] = [.iele, .strigoi, .zmeu]
        let emoteType = EmoteType.thinking

        for characterType in characterTypes {
            // WHEN
            let timing = CulturalAnimationTiming.timingForEmote(
                emoteType: emoteType,
                characterType: characterType
            )

            // THEN
            XCTAssertGreaterThan(timing, 0, "Emote timing should be positive")
        }
    }

    func testTimingForEmoteAllCombinations() {
        // GIVEN
        let characterTypes: [RomanianCharacterType] = [
            .pacala, .iele, .strigoi, .fatFrumos, .babaCloantza, .zmeu
        ]
        let emoteTypes: [EmoteType] = [
            .greeting, .goodMove, .badMove, .thinking, .taunt, .victory, .defeat
        ]

        for characterType in characterTypes {
            for emoteType in emoteTypes {
                // WHEN
                let timing = CulturalAnimationTiming.timingForEmote(
                    emoteType: emoteType,
                    characterType: characterType
                )

                // THEN
                XCTAssertGreaterThan(timing, 0, "Emote timing should be positive for \(characterType) - \(emoteType)")
                XCTAssertLessThan(timing, 5.0, "Emote timing should be reasonable (< 5s)")
            }
        }
    }

    // MARK: - Shuffle Timing Tests

    func testTimingForShuffleDefaultParameters() {
        // GIVEN
        let deckSize = 20

        // WHEN
        let timing = CulturalAnimationTiming.timingForShuffle(deckSize: deckSize)

        // THEN
        let expectedTiming = 2.0 * 1.0 * (Double(deckSize) / 20.0)
        XCTAssertEqual(timing, expectedTiming, accuracy: 0.001)
    }

    func testTimingForShuffleDifferentStyles() {
        // GIVEN
        let deckSize = 32
        let shuffleStyles: [ShuffleStyle] = [.smooth, .quick, .magical, .professional]

        for shuffleStyle in shuffleStyles {
            // WHEN
            let timing = CulturalAnimationTiming.timingForShuffle(
                shuffleStyle: shuffleStyle,
                deckSize: deckSize
            )

            // THEN
            XCTAssertGreaterThan(timing, 0, "Shuffle timing should be positive for \(shuffleStyle)")
        }
    }

    func testTimingForShuffleDifferentDeckSizes() {
        // GIVEN
        let deckSizes = [10, 20, 32, 52, 100]

        for deckSize in deckSizes {
            // WHEN
            let timing = CulturalAnimationTiming.timingForShuffle(deckSize: deckSize)

            // THEN
            XCTAssertGreaterThan(timing, 0, "Shuffle timing should be positive for deck size \(deckSize)")
            // Timing should scale with deck size
            let expectedTiming = 2.0 * 1.0 * (Double(deckSize) / 20.0)
            XCTAssertEqual(timing, expectedTiming, accuracy: 0.001)
        }
    }

    // MARK: - Dance Timing Tests

    func testTimingForDanceHora() {
        // GIVEN
        let danceType = RomanianDanceType.hora
        let measureCount = 2

        // WHEN
        let timing = CulturalAnimationTiming.timingForDance(
            danceType: danceType,
            measureCount: measureCount
        )

        // THEN
        let expectedTiming = CulturalAnimationTiming.horaMeasureDuration * Double(measureCount)
        XCTAssertEqual(timing, expectedTiming, accuracy: 0.001)
    }

    func testTimingForDanceCalusari() {
        // GIVEN
        let danceType = RomanianDanceType.calusari
        let measureCount = 3

        // WHEN
        let timing = CulturalAnimationTiming.timingForDance(
            danceType: danceType,
            measureCount: measureCount
        )

        // THEN
        let expectedTiming = CulturalAnimationTiming.calusariSequenceDuration * Double(measureCount)
        XCTAssertEqual(timing, expectedTiming, accuracy: 0.001)
    }

    func testTimingForDanceBrau() {
        // GIVEN
        let danceType = RomanianDanceType.brau
        let measureCount = 1

        // WHEN
        let timing = CulturalAnimationTiming.timingForDance(
            danceType: danceType,
            measureCount: measureCount
        )

        // THEN
        let expectedTiming = CulturalAnimationTiming.brauPhraseDuration
        XCTAssertEqual(timing, expectedTiming, accuracy: 0.001)
    }

    func testTimingForDanceSarba() {
        // GIVEN
        let danceType = RomanianDanceType.sarba
        let measureCount = 2

        // WHEN
        let timing = CulturalAnimationTiming.timingForDance(
            danceType: danceType,
            measureCount: measureCount
        )

        // THEN
        let expectedTiming = CulturalAnimationTiming.sarbaSlowInterval * 8.0 * Double(measureCount)
        XCTAssertEqual(timing, expectedTiming, accuracy: 0.001)
    }

    func testTimingForDanceAllTypes() {
        // GIVEN
        let danceTypes: [RomanianDanceType] = [.hora, .calusari, .brau, .sarba]

        for danceType in danceTypes {
            // WHEN
            let timing = CulturalAnimationTiming.timingForDance(danceType: danceType)

            // THEN
            XCTAssertGreaterThan(timing, 0, "Dance timing should be positive for \(danceType)")
            XCTAssertLessThan(timing, 20.0, "Dance timing should be reasonable (< 20s)")
        }
    }

    // MARK: - Dealing Timing Tests

    func testTimingForDealingBasicParameters() {
        // GIVEN
        let playerCount = 4
        let cardsPerPlayer = 5

        // WHEN
        let timing = CulturalAnimationTiming.timingForDealing(
            playerCount: playerCount,
            cardsPerPlayer: cardsPerPlayer
        )

        // THEN
        let expectedTiming = 0.5 * (Double(playerCount) / 4.0) * (Double(cardsPerPlayer) / 5.0) * 1.0
        XCTAssertEqual(timing, expectedTiming, accuracy: 0.001)
    }

    func testTimingForDealingDifferentStyles() {
        // GIVEN
        let playerCount = 2
        let cardsPerPlayer = 7
        let dealingStyles: [DealingStyle] = [.smooth, .quick, .dramatic, .circular]

        for dealingStyle in dealingStyles {
            // WHEN
            let timing = CulturalAnimationTiming.timingForDealing(
                playerCount: playerCount,
                cardsPerPlayer: cardsPerPlayer,
                dealingStyle: dealingStyle
            )

            // THEN
            XCTAssertGreaterThan(timing, 0, "Dealing timing should be positive for \(dealingStyle)")
        }
    }

    func testTimingForDealingVariousGameSizes() {
        // GIVEN
        let gameConfigs = [
            (players: 2, cards: 10),
            (players: 3, cards: 7),
            (players: 4, cards: 5),
            (players: 6, cards: 4)
        ]

        for (players, cards) in gameConfigs {
            // WHEN
            let timing = CulturalAnimationTiming.timingForDealing(
                playerCount: players,
                cardsPerPlayer: cards
            )

            // THEN
            XCTAssertGreaterThan(timing, 0, "Dealing timing should be positive for \(players) players, \(cards) cards")
        }
    }

    // MARK: - Performance Tests

    func testTimingCalculationPerformance() {
        // WHEN & THEN
        measure {
            for _ in 0..<10000 {
                let timing = CulturalAnimationTiming.timingForCardPlay(
                    characterType: .pacala,
                    playStyle: .quick,
                    isWinning: false
                )
                _ = timing
            }
        }
    }

    func testEmoteTimingPerformance() {
        let characterTypes: [RomanianCharacterType] = [.pacala, .iele, .strigoi, .fatFrumos, .babaCloantza, .zmeu]
        let emoteTypes: [EmoteType] = [.greeting, .goodMove, .badMove, .thinking, .taunt, .victory, .defeat]

        // WHEN & THEN
        measure {
            for characterType in characterTypes {
                for emoteType in emoteTypes {
                    let timing = CulturalAnimationTiming.timingForEmote(
                        emoteType: emoteType,
                        characterType: characterType
                    )
                    _ = timing
                }
            }
        }
    }
}