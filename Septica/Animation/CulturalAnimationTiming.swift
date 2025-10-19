//
//  CulturalAnimationTiming.swift
//  Septica
//
//  Romanian folk dance timing integration for authentic animations
//  Preserves cultural heritage in game animations
//

import Foundation

/// Romanian folk dance timing integration for authentic animations
class CulturalAnimationTiming {

    // MARK: - Folk Dance Timing Constants

    /// Hora dance timing (circular, community dance)
    /// Traditional Romanian circle dance where participants hold hands and dance in a circle
    /// Timing: 8 beats per measure, moderate tempo (~120 BPM)
    static let horaBeatInterval: TimeInterval = 0.5
    static let horaMeasureDuration: TimeInterval = 4.0
    static let horaCircleCompleteDuration: TimeInterval = 16.0 // Full circle

    /// Călușari timing (ritual dance, masculine energy)
    /// Traditional men's ritual dance with energetic movements
    /// Timing: Faster tempo (~140 BPM), sharp movements
    static let calusariBeatInterval: TimeInterval = 0.43
    static let calusariSequenceDuration: TimeInterval = 2.6 // 6 beats sequence

    /// Brâu timing (line dance, coordinated movements)
    /// Traditional line dance with synchronized movements
    /// Timing: Steady tempo (~110 BPM), smooth transitions
    static let brauBeatInterval: TimeInterval = 0.55
    static let brauPhraseDuration: TimeInterval = 4.4 // 8 beats phrase

    /// Sârba timing (chain dance, complex formations)
    /// Traditional chain dance with intricate patterns
    /// Timing: Variable tempo, complex rhythm patterns
    static let sarbaSlowInterval: TimeInterval = 0.6
    static let sarbaFastInterval: TimeInterval = 0.4

    /// Inimă de joc timing (game song rhythms)
    /// Traditional game songs with specific timing for different game phases
    /// Timing: Context-dependent, game-specific
    static let gameSongIntroDuration: TimeInterval = 2.0
    static let gameSongVerseDuration: TimeInterval = 4.0
    static let gameSongChorusDuration: TimeInterval = 2.5

    // MARK: - Card Game Specific Timing

    /// Card play timing based on Romanian traditional card games
    struct CardGameTiming {
        static let quickPlay: TimeInterval = 0.8        // Fast, confident play
        static let thoughtfulPlay: TimeInterval = 1.5    // Considered play
        static let dramaticPlay: TimeInterval = 2.0      // Show-off play
        static let victoryPlay: TimeInterval = 1.2       // Winning card play
        static let passingPlay: TimeInterval = 0.5       // Passing turn
    }

    /// Character-specific animation timing
    struct CharacterTiming {
        static let pacalaQuick: TimeInterval = 0.7        // Quick, playful
        static let pacalaThoughtful: TimeInterval = 1.8   // Considered pause
        static let ieleGraceful: TimeInterval = 1.2      // Ethereal, flowing
        static let ieleMysterious: TimeInterval = 2.0      // Mystical pause
        static let strigoiDramatic: TimeInterval = 1.0   // Sharp, intense
        static let strigoiMenacing: TimeInterval = 1.5  // Threatening pause
        static let fatFrumosHeroic: TimeInterval = 0.9   // Confident, proud
        static let fatFrumosVictorious: TimeInterval = 1.6 // Triumphant
        static let babaCloantzaWise: TimeInterval = 1.4    // Considered pause
        static let babaCloantzaGrumpy: TimeInterval = 0.8  // Quick decision
        static let zmeuEnergetic: TimeInterval = 0.6      // Fast, explosive
        static let zmeuVictorious: TimeInterval = 1.3     // Roaring celebration
    }

    // MARK: - Public Interface

    /// Get appropriate timing for card play based on character and context
    /// - Parameters:
    ///   - characterType: The character making the play
    ///   - playStyle: Style of card play (quick, thoughtful, etc.)
    /// - isWinning: Whether this is a winning play
    /// - Returns: Duration for the animation
    static func timingForCardPlay(
        characterType: RomanianCharacterType,
        playStyle: CardPlayStyle = .quick,
        isWinning: Bool = false
    ) -> TimeInterval {
        let baseTiming = getCharacterBaseTiming(characterType: characterType)

        // Adjust for play style
        let styleMultiplier: TimeInterval
        switch playStyle {
        case .quick:
            styleMultiplier = 0.8
        case .thoughtful:
            styleMultiplier = 1.5
        case .dramatic:
            styleMultiplier = 2.0
        case .strategic:
            styleMultiplier = 1.2
        }

        // Adjust for winning play
        let winningBonus = isWinning ? 0.3 : 0

        return baseTiming * styleMultiplier + winningBonus
    }

    /// Get timing for card selection
    /// - Parameters:
    ///   - characterType: The character selecting the card
    ///   - selectionSpeed: Speed of selection (quick, considered, hesitant)
    /// - Returns: Duration for selection animation
    static func timingForCardSelection(
        characterType: RomanianCharacterType,
        selectionSpeed: SelectionSpeed = .normal
    ) -> TimeInterval {
        let baseTiming = CharacterTiming.pacalaQuick // Default

        // Adjust for character type
        let characterTiming = getCharacterTiming(characterType: characterType)

        // Adjust for selection speed
        let speedMultiplier: TimeInterval
        switch selectionSpeed {
        case .instant:
            speedMultiplier = 0.3
        case .quick:
            speedMultiplier = 0.6
        case .normal:
            speedMultiplier = 1.0
        case .considered:
            speedMultiplier = 1.4
        case .hesitant:
            speedMultiplier = 2.0
        }

        return characterTiming * speedMultiplier
    }

    /// Get timing for victory celebration
    /// - Parameters:
    ///   - characterType: The winning character
    ///   - victoryType: Type of victory (decisive, dramatic, etc.)
    /// - Returns: Duration for victory animation
    static func timingForVictory(
        characterType: RomanianCharacterType,
        victoryType: VictoryType = .decisive
    ) -> TimeInterval {
        let baseTiming = getCharacterVictoryTiming(characterType: characterType)

        // Adjust for victory type
        let victoryMultiplier: TimeInterval
        switch victoryType {
        case .decisive:
            victoryMultiplier = 1.0
        case .dramatic:
            victoryMultiplier = 1.3
        case .upset:
            victoryMultiplier = 1.5
        case .perfect:
            victoryMultiplier = 2.0
        }

        return baseTiming * victoryMultiplier
    }

    /// Get timing for emote animations
    /// - Parameters:
    ///   - emoteType: Type of emote being played
    ///   - characterType: Character performing the emote
    /// - Returns: Duration for emote animation
    static func timingForEmote(
        emoteType: EmoteType,
        characterType: RomanianCharacterType
    ) -> TimeInterval {
        // Base emote timing
        let baseEmoteTiming: TimeInterval
        switch emoteType {
        case .greeting:
            baseEmoteTiming = 1.0
        case .goodMove:
            baseEmoteTiming = 0.8
        case .badMove:
            baseEmoteTiming = 1.2
        case .thinking:
            baseEmoteTiming = 2.0
        case .taunt:
            baseEmoteTiming = 1.5
        case .victory:
            baseEmoteTiming = 2.5
        case .defeat:
            baseEmoteTiming = 1.8
        }

        // Character-specific adjustments
        let characterMultiplier: TimeInterval
        switch characterType {
        case .pacala:    // Playful, expressive
            characterMultiplier = 1.0
        case .iele:      // Graceful, ethereal
            characterMultiplier = 1.2
        case .strigoi:    // Dramatic, intense
            characterMultiplier = 0.8
        case .fatFrumos: // Heroic, proud
            characterMultiplier = 0.9
        case .babaCloantza: // Wise, measured
            characterMultiplier = 1.1
        case .zmeu:      // Energetic, explosive
            characterMultiplier = 0.7
        }

        return baseEmoteTiming * characterMultiplier
    }

    /// Get timing for card shuffling
    /// - Parameters:
    ///   - shuffleStyle: Style of shuffling
    ///   - deckSize: Number of cards being shuffled
    ///   Returns: Duration for shuffle animation
    static func timingForShuffle(
        shuffleStyle: ShuffleStyle = .smooth,
        deckSize: Int
    ) -> TimeInterval {
        let baseShuffleTime: TimeInterval = 2.0

        // Adjust for shuffle style
        let styleMultiplier: TimeInterval
        switch shuffleStyle {
        case .smooth:
            styleMultiplier = 1.0
        case .quick:
            styleMultiplier = 0.6
        case .magical:
            styleMultiplier = 1.3
        case .professional:
            styleMultiplier = 0.8
        }

        // Adjust for deck size
        let sizeMultiplier = max(1.0, Double(deckSize) / 20.0)

        return baseShuffleTime * styleMultiplier * sizeMultiplier
    }

    /// Get timing based on Romanian folk dance rhythm
    /// - Parameters:
    ///   - danceType: Type of folk dance
    ///   - measureCount: Number of measures to include
    /// - Returns: Duration synchronized with dance rhythm
    static func timingForDance(
        danceType: RomanianDanceType,
        measureCount: Int = 1
    ) -> TimeInterval {
        switch danceType {
        case .hora:
            return Double(measureCount) * horaMeasureDuration
        case .calusari:
            return Double(measureCount) * calusariSequenceDuration
        case .brau:
            return Double(measureCount) * brauPhraseDuration
        case .sarba:
            return Double(measureCount) * sarbaSlowInterval * 8.0 // 8 beats per phrase
        }
    }

    /// Get timing for card dealing
    /// - Parameters:
    ///   - playerCount: Number of players receiving cards
    ///   - cardsPerPlayer: Cards being dealt to each player
    ///   - dealingStyle: Style of dealing
    /// - Returns: Duration for dealing animation
    static func timingForDealing(
        playerCount: Int,
        cardsPerPlayer: Int,
        dealingStyle: DealingStyle = .smooth
    ) -> TimeInterval {
        let baseDealingTime: TimeInterval = 0.5

        // Adjust for player count
        let playerMultiplier = Double(playerCount) / 4.0

        // Adjust for cards per player
        let cardMultiplier = Double(cardsPerPlayer) / 5.0

        // Adjust for dealing style
        let styleMultiplier: TimeInterval
        switch dealingStyle {
        case .smooth:
            styleMultiplier = 1.0
        case .quick:
            styleMultiplier = 0.7
        case .dramatic:
            styleMultiplier = 1.3
        case .circular:
            styleMultiplier = 1.1
        }

        return baseDealingTime * playerMultiplier * cardMultiplier * styleMultiplier
    }

    // MARK: - Private Helper Methods

    /// Get base timing for character type
    private static func getCharacterBaseTiming(characterType: RomanianCharacterType) -> TimeInterval {
        switch characterType {
        case .pacala:
            return CharacterTiming.pacalaQuick
        case .iele:
            return CharacterTiming.ieleGraceful
        case .strigoi:
            return CharacterTiming.strigoiDramatic
        case .fatFrumos:
            return CharacterTiming.fatFrumosHeroic
        case .babaCloantza:
            return CharacterTiming.babaCloantzaWise
        case .zmeu:
            return CharacterTiming.zmeuEnergetic
        }
    }

    /// Get character-specific timing
    private static func getCharacterTiming(characterType: RomanianCharacterType) -> TimeInterval {
        switch characterType {
        case .pacala:
            return 0.8 // Quick and playful
        case .iele:
            return 1.1 // Graceful and flowing
        case .strigoi:
            return 0.7 // Sharp and dramatic
        case .fatFrumos:
            return 0.9 // Confident and steady
        case .babaCloantza:
            return 1.3 // Wise and considered
        case .zmeu:
            return 0.6 // Energetic and explosive
        }
    }

    /// Get character victory timing
    private static func getCharacterVictoryTiming(characterType: RomanianCharacterType) -> TimeInterval {
        switch characterType {
        case .pacala:
            return 1.4 // Playful celebration
        case .iele:
            return 1.8 // Ethereal celebration
        case .strigoi:
            return 1.2 // Dramatic victory
        case .fatFrumos:
            return 1.6 // Heroic triumph
        case .babaCloantza:
            return 2.0 // Wise satisfaction
        case .zmeu:
            return 1.3 // Energetic roar
        }
    }
}

// MARK: - Supporting Types

/// Style of card play
enum CardPlayStyle {
    case quick         // Fast, confident play
    case thoughtful    // Considered pause
    case dramatic     // Show-off play
    case strategic    // Planned play
}

/// Speed of card selection
enum SelectionSpeed {
    case instant      // Immediate selection
    case quick        // Fast selection
    case normal       // Standard timing
    case considered   // Thoughtful pause
    case hesitant     // Slow consideration
}

/// Type of victory achieved
enum VictoryType {
    case decisive     // Clear win
    case dramatic     // Comeback win
    case upset        // Unexpected win
    case perfect       // Flawless win
}

/// Style of card shuffling
enum ShuffleStyle {
    case smooth       // Professional shuffling
    case quick        // Fast shuffling
    case magical      // Mystical shuffling
    case professional // Casino-style
}

/// Type of Romanian folk dance
enum RomanianDanceType {
    case hora         // Circle dance
    case calusari     // Men's ritual dance
    case brau         // Line dance
    case sarba        // Chain dance
}

/// Style of card dealing
enum DealingStyle {
    case smooth       // Smooth dealing
    case quick        // Fast dealing
    case dramatic     // Showy dealing
    case circular     // Circular dealing
}