//
//  FluidCardInteractionVisuals.swift
//  Septica
//
//  Shuffle Cats-inspired fluid card interactions with Romanian cultural flair
//  Creates the tactile, satisfying card play experience with visual feedback
//

import SwiftUI
import Combine

/// Manages the fluid, tactile card interactions inspired by Shuffle Cats
/// Every interaction feels satisfying and provides clear visual feedback
@MainActor
class FluidCardInteractionVisuals: ObservableObject {
    
    // MARK: - Visual State
    
    @Published var draggedCard: DraggedCardState?
    @Published var ghostCardPositions: [String: CGPoint] = [:] // cardID -> position
    @Published var playableCardGlow: Set<String> = [] // Card IDs that should glow
    @Published var cardHoverStates: [String: HoverState] = [:]
    @Published var dropZoneHighlights: [DropZoneState] = []
    
    // MARK: - Animation State
    
    @Published var cardAnimations: [String: CardAnimation] = [:]
    @Published var sevenCardEffect: SevenCardEffectState?
    @Published var trickWinAnimation: TrickWinAnimation?
    @Published var lastTrickCelebration: LastTrickCelebration?
    
    // MARK: - Romanian Cultural Visuals
    
    @Published var culturalGlowEffect: CulturalGlowEffect?
    @Published var folkPatternOverlay: FolkPatternOverlay?
    @Published var romanianCelebration: RomanianCelebration?
    
    // MARK: - Dependencies
    
    private let hapticManager: HapticManager?
    private let audioManager: AudioManager?
    private let culturalSystem: CulturalAchievementSystem
    
    // MARK: - Initialization
    
    init(hapticManager: HapticManager? = nil, 
         audioManager: AudioManager? = nil,
         culturalSystem: CulturalAchievementSystem) {
        self.hapticManager = hapticManager
        self.audioManager = audioManager
        self.culturalSystem = culturalSystem
    }
    
    // MARK: - Shuffle Cats-Style Drag & Drop
    
    /// Start dragging a card with Shuffle Cats-style visual feedback
    func startDragGesture(cardID: String, startPosition: CGPoint, cardType: SepticaCardType) {
        // Immediate haptic feedback for tactile satisfaction
        hapticManager?.trigger(.cardSelect)
        audioManager?.playSound(.cardSelect)
        
        draggedCard = DraggedCardState(
            cardID: cardID,
            startPosition: startPosition,
            currentPosition: startPosition,
            cardType: cardType,
            dragStartTime: Date(),
            initialScale: 1.0
        )
        
        // Remove glow since card is now being dragged
        playableCardGlow.remove(cardID)
        
        // Start subtle scale animation for "lifted" feel
        animateCardLift(cardID: cardID)
    }
    
    /// Update drag position with ghost card preview
    func updateDragGesture(cardID: String, newPosition: CGPoint, validDropZones: [DropZone]) {
        guard var dragState = draggedCard, dragState.cardID == cardID else { return }
        
        dragState.currentPosition = newPosition
        draggedCard = dragState
        
        // Update ghost card position for valid drop zones
        let nearestDropZone = findNearestValidDropZone(position: newPosition, validZones: validDropZones)
        
        if let dropZone = nearestDropZone {
            // Show ghost card in drop zone
            ghostCardPositions[cardID] = dropZone.center
            
            // Highlight valid drop zone with Romanian-inspired glow
            updateDropZoneHighlight(dropZone: dropZone, isValid: true)
            
            // Subtle haptic feedback when entering valid zone
            if cardHoverStates[cardID]?.isInValidZone != true {
                hapticManager?.trigger(.cardPlay)
            }
            
            cardHoverStates[cardID] = HoverState(
                isHovering: true,
                isInValidZone: true,
                hoveredZone: dropZone.id
            )
        } else {
            // Clear ghost card if not in valid zone
            ghostCardPositions.removeValue(forKey: cardID)
            clearDropZoneHighlights()
            
            cardHoverStates[cardID] = HoverState(
                isHovering: true,
                isInValidZone: false
            )
        }
    }
    
    /// Complete drag gesture with satisfying snap animation
    func completeDragGesture(cardID: String, finalPosition: CGPoint, isValidPlay: Bool) {
        defer {
            // Clean up drag state
            draggedCard = nil
            ghostCardPositions.removeValue(forKey: cardID)
            cardHoverStates.removeValue(forKey: cardID)
            clearDropZoneHighlights()
        }
        
        if isValidPlay {
            // Successful card play with satisfying feedback
            hapticManager?.trigger(.success)
            audioManager?.playSound(.cardPlace)
            
            // Animate card snapping into place
            animateCardSnap(cardID: cardID, targetPosition: finalPosition)
            
            // Check for special Septica effects
            if let dragState = draggedCard {
                handleSpecialCardEffects(cardType: dragState.cardType, cardID: cardID)
            }
        } else {
            // Invalid play - bounce back with error feedback
            hapticManager?.trigger(.cardInvalid)
            audioManager?.playSound(.cardInvalid)
            
            // Animate card bouncing back to hand
            animateCardBounceBack(cardID: cardID)
        }
    }
    
    // MARK: - Septica-Specific Visual Effects
    
    /// Handle special visual effects for Septica cards
    private func handleSpecialCardEffects(cardType: SepticaCardType, cardID: String) {
        switch cardType {
        case .seven:
            // "Seven" card gets fiery Romanian folk art effect
            triggerSevenCardEffect(cardID: cardID)
            
        case .eight:
            // "Eight" card gets traditional Romanian geometric pattern
            triggerEightCardEffect(cardID: cardID)
            
        case .ace:
            // High-value cards get golden Romanian ornament effect
            triggerHighValueCardEffect(cardID: cardID)
            
        default:
            break
        }
    }
    
    /// Trigger the special "Seven" card effect with Romanian fire motifs
    private func triggerSevenCardEffect(cardID: String) {
        sevenCardEffect = SevenCardEffectState(
            cardID: cardID,
            effectStartTime: Date(),
            intensity: 1.0,
            visualStyle: .romanianFire // Traditional Romanian fire patterns
        )
        
        // Cultural significance feedback
        culturalSystem.recordCulturalAction("seven_wild_played")
        
        // Remove effect after animation duration
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            if self.sevenCardEffect?.cardID == cardID {
                self.sevenCardEffect = nil
            }
        }
    }
    
    /// Trigger trick win animation with Romanian celebration
    func triggerTrickWinAnimation(winningCards: [String], playerName: String, isLastTrick: Bool = false) {
        if isLastTrick {
            // Special "Last Trick" celebration with Romanian folk dance
            triggerLastTrickCelebration(winningCards: winningCards, playerName: playerName)
        } else {
            // Standard trick win with satisfying card collection
            trickWinAnimation = TrickWinAnimation(
                winningCards: winningCards,
                playerName: playerName,
                animationStartTime: Date(),
                visualStyle: .traditionalCollection
            )
            
            // Enhanced haptic sequence for trick win
            hapticManager?.trigger(.trickWon)
            audioManager?.playSound(.trickWon)
        }
    }
    
    /// Celebrate last trick with Romanian folk celebration
    private func triggerLastTrickCelebration(winningCards: [String], playerName: String) {
        lastTrickCelebration = LastTrickCelebration(
            winningCards: winningCards,
            playerName: playerName,
            celebrationStartTime: Date(),
            folkDanceAnimation: true,
            traditionalMusicTrack: "hora_de_la_odobesti",
            confettiStyle: .romanianTricolor
        )
        
        // Epic celebration feedback
        hapticManager?.trigger(.gameVictory)
        audioManager?.playSound(.gameVictory)
        audioManager?.startBackgroundMusic(.horaUnirii, fadeIn: true)
        
        // Record cultural engagement
        culturalSystem.recordCulturalAction("last_trick_celebration")
    }
    
    // MARK: - Clash Royale-Style Glow Effects
    
    /// Update playable cards with Clash Royale-style glow
    func updatePlayableCardGlow(playableCardIDs: [String], currentTurn: String) {
        playableCardGlow = Set(playableCardIDs)
        
        // Add subtle pulsing animation for playable cards
        for cardID in playableCardIDs {
            cardAnimations[cardID] = CardAnimation(
                type: .playableGlow,
                startTime: Date(),
                duration: 1.5, // Gentle pulsing
                isRepeating: true,
                glowColor: currentTurn == "player" ? .romanianGold : .romanianBlue
            )
        }
    }
    
    /// Clear all glow effects when turn changes
    func clearPlayableCardGlow() {
        let previousGlowCards = playableCardGlow
        playableCardGlow.removeAll()
        
        // Remove glow animations
        for cardID in previousGlowCards {
            cardAnimations.removeValue(forKey: cardID)
        }
    }
    
    // MARK: - Romanian Cultural Visual Enhancements
    
    /// Add Romanian folk pattern overlay for cultural achievements
    func showRomanianCulturalEffect(achievementType: CulturalAchievement, intensity: Float) {
        culturalGlowEffect = CulturalGlowEffect(
            achievementType: achievementType,
            intensity: intensity,
            startTime: Date(),
            pattern: selectFolkPattern(for: achievementType),
            colors: getRomanianTraditionalColors(for: achievementType)
        )
        
        // Play traditional Romanian sound using AudioManager's existing system
        if let soundTrack = getCulturalSoundTrack(for: achievementType) {
            playCulturalSound(soundTrack)
        }
    }
    
    /// Show arena progression celebration with Romanian city themes
    func showArenaProgressionCelebration(newArena: RomanianArena, previousArena: RomanianArena) {
        romanianCelebration = RomanianCelebration(
            celebrationType: .arenaProgression,
            newArena: newArena,
            previousArena: previousArena,
            startTime: Date(),
            visualElements: getArenaVisualElements(for: newArena),
            culturalMessage: newArena.culturalDescription
        )
        
        // Epic progression feedback
        hapticManager?.trigger(.gameVictory)
        audioManager?.playSound(.gameVictory)
        
        // Play arena-specific traditional music
        if let arenaMusic = getArenaMusic(for: newArena) {
            audioManager?.startBackgroundMusic(arenaMusic)
        }
    }
    
    // MARK: - Helper Methods
    
    private func animateCardLift(cardID: String) {
        cardAnimations[cardID] = CardAnimation(
            type: .lift,
            startTime: Date(),
            duration: 0.2,
            targetScale: 1.1,
            shadowOpacity: 0.3
        )
    }
    
    private func animateCardSnap(cardID: String, targetPosition: CGPoint) {
        cardAnimations[cardID] = CardAnimation(
            type: .snapIntoPlace,
            startTime: Date(),
            duration: 0.3,
            targetPosition: targetPosition,
            easeType: .easeOut,
            includesHapticFeedback: true
        )
    }
    
    private func animateCardBounceBack(cardID: String) {
        cardAnimations[cardID] = CardAnimation(
            type: .bounceBack,
            startTime: Date(),
            duration: 0.4,
            easeType: .elasticOut,
            includesHapticFeedback: true
        )
    }
    
    private func findNearestValidDropZone(position: CGPoint, validZones: [DropZone]) -> DropZone? {
        return validZones.min { zone1, zone2 in
            distance(from: position, to: zone1.center) < distance(from: position, to: zone2.center)
        }
    }
    
    private func distance(from: CGPoint, to: CGPoint) -> CGFloat {
        return sqrt(pow(from.x - to.x, 2) + pow(from.y - to.y, 2))
    }
    
    private func updateDropZoneHighlight(dropZone: DropZone, isValid: Bool) {
        dropZoneHighlights = [DropZoneState(
            zoneID: dropZone.id,
            isHighlighted: true,
            isValid: isValid,
            glowColor: isValid ? .romanianGreen : .romanianRed,
            pulseDuration: 0.8
        )]
    }
    
    private func clearDropZoneHighlights() {
        dropZoneHighlights.removeAll()
    }
    
    private func triggerEightCardEffect(cardID: String) {
        // Romanian geometric pattern effect for "8" cards
        folkPatternOverlay = FolkPatternOverlay(
            cardID: cardID,
            patternType: .geometricRomanian,
            startTime: Date(),
            duration: 1.5,
            colors: [.romanianRed, .romanianYellow, .romanianBlue]
        )
    }
    
    private func triggerHighValueCardEffect(cardID: String) {
        // Golden Romanian ornament for high-value cards
        cardAnimations[cardID] = CardAnimation(
            type: .goldenOrnament,
            startTime: Date(),
            duration: 1.0,
            glowColor: .romanianGold,
            includesParticles: true
        )
    }
    
    private func selectFolkPattern(for achievement: CulturalAchievement) -> FolkPattern {
        switch achievement {
        case .septicaMaster:
            return .traditionalCross
        case .sevenWild:
            return .spiralDesign
        case .folkMusicLover:
            return .floralBorder
        default:
            return .geometricMotif
        }
    }
    
    private func getRomanianTraditionalColors(for achievement: CulturalAchievement) -> [RomanianColor] {
        switch achievement {
        case .septicaMaster:
            return [.romanianRed, .romanianYellow, .romanianBlue]
        case .traditionalColors:
            return [.romanianGold, .romanianRed]
        default:
            return [.romanianBlue, .romanianYellow]
        }
    }
    
    private func getCulturalSoundTrack(for achievement: CulturalAchievement) -> CulturalSoundType? {
        switch achievement {
        case .folkMusicLover:
            return .traditionalFolk
        case .culturalAmbassador:
            return .nationalHymn
        default:
            return .bellChime
        }
    }
    
    /// Map cultural sounds to AudioManager's Romanian sound system
    private func playCulturalSound(_ soundType: CulturalSoundType) {
        switch soundType {
        case .traditionalFolk:
            audioManager?.playRomanianSound(.gameVictory)
        case .nationalHymn:
            audioManager?.playRomanianSound(.gameVictory)
        case .bellChime:
            audioManager?.playRomanianSound(.trickComplete)
        case .folkDance:
            audioManager?.playRomanianSound(.gameStart)
        }
    }
    
    private func getArenaVisualElements(for arena: RomanianArena) -> [ArenaVisualElement] {
        switch arena {
        case .sateImarica:
            return [.woodenHouse, .folkFence, .traditionalWell]
        case .orasulBrasov:
            return [.gothicArchitecture, .medievalTowers, .carpathianMountains]
        case .marealeBucuresti:
            return [.parliamentPalace, .oldTownSquare, .romanianFlag, .crownJewels]
        default:
            return [.traditionalRooftops, .cobblestoneStreets, .folkArt]
        }
    }
    
    private func getArenaMusic(for arena: RomanianArena) -> AudioManager.BackgroundMusic? {
        switch arena {
        case .sateImarica:
            return .traditionalFolk
        case .orasulCluj:
            return .jocMuntesc
        case .marealeBucuresti:
            return .horaUnirii
        default:
            return .traditionalFolk
        }
    }
}

// MARK: - Supporting Data Models

struct DraggedCardState {
    let cardID: String
    let startPosition: CGPoint
    var currentPosition: CGPoint
    let cardType: SepticaCardType
    let dragStartTime: Date
    var initialScale: CGFloat
}

struct HoverState {
    let isHovering: Bool
    let isInValidZone: Bool
    let hoveredZone: String?
    
    init(isHovering: Bool, isInValidZone: Bool, hoveredZone: String? = nil) {
        self.isHovering = isHovering
        self.isInValidZone = isInValidZone
        self.hoveredZone = hoveredZone
    }
}

struct DropZone {
    let id: String
    let center: CGPoint
    let bounds: CGRect
}

struct DropZoneState {
    let zoneID: String
    let isHighlighted: Bool
    let isValid: Bool
    let glowColor: RomanianColor
    let pulseDuration: TimeInterval
}

struct CardAnimation {
    let type: AnimationType
    let startTime: Date
    let duration: TimeInterval
    var targetScale: CGFloat = 1.0
    var targetPosition: CGPoint?
    var shadowOpacity: CGFloat = 0.0
    var easeType: EaseType = .linear
    var includesHapticFeedback: Bool = false
    var isRepeating: Bool = false
    var glowColor: RomanianColor?
    var includesParticles: Bool = false
    
    enum AnimationType {
        case lift, snapIntoPlace, bounceBack, playableGlow, goldenOrnament
    }
    
    enum EaseType {
        case linear, easeIn, easeOut, elasticOut
    }
}

struct SevenCardEffectState {
    let cardID: String
    let effectStartTime: Date
    let intensity: Float
    let visualStyle: SevenEffectStyle
    
    enum SevenEffectStyle {
        case romanianFire, goldenFlame, traditionalSparkle
    }
}

struct TrickWinAnimation {
    let winningCards: [String]
    let playerName: String
    let animationStartTime: Date
    let visualStyle: TrickWinStyle
    
    enum TrickWinStyle {
        case traditionalCollection, modernSwipe, folkloreGather
    }
}

struct LastTrickCelebration {
    let winningCards: [String]
    let playerName: String
    let celebrationStartTime: Date
    let folkDanceAnimation: Bool
    let traditionalMusicTrack: String
    let confettiStyle: ConfettiStyle
    
    enum ConfettiStyle {
        case romanianTricolor, traditionalFlowers, folklorePatterns
    }
}

struct CulturalGlowEffect {
    let achievementType: CulturalAchievement
    let intensity: Float
    let startTime: Date
    let pattern: FolkPattern
    let colors: [RomanianColor]
}

struct FolkPatternOverlay {
    let cardID: String
    let patternType: PatternType
    let startTime: Date
    let duration: TimeInterval
    let colors: [RomanianColor]
    
    enum PatternType {
        case geometricRomanian, floralTraditional, spiralAncient
    }
}

struct RomanianCelebration {
    let celebrationType: CelebrationType
    let newArena: RomanianArena?
    let previousArena: RomanianArena?
    let startTime: Date
    let visualElements: [ArenaVisualElement]
    let culturalMessage: String
    
    enum CelebrationType {
        case arenaProgression, culturalAchievement, seasonalEvent
    }
}

// MARK: - Romanian Cultural Enums

enum SepticaCardType {
    case seven, eight, nine, ten, jack, queen, king, ace
}

enum RomanianColor {
    case romanianRed, romanianYellow, romanianBlue, romanianGold, romanianGreen
}

enum FolkPattern {
    case traditionalCross, spiralDesign, floralBorder, geometricMotif
}

enum CulturalSoundType {
    case traditionalFolk, nationalHymn, bellChime, folkDance
}

enum ArenaVisualElement {
    case woodenHouse, folkFence, traditionalWell
    case gothicArchitecture, medievalTowers, carpathianMountains
    case parliamentPalace, oldTownSquare, romanianFlag, crownJewels
    case traditionalRooftops, cobblestoneStreets, folkArt
}