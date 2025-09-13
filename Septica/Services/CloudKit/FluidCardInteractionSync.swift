//
//  FluidCardInteractionSync.swift
//  Septica
//
//  Synchronizes fluid card interactions inspired by Shuffle Cats
//  Maintains drag-and-drop state, visual effects, and haptic feedback across devices
//

import Foundation
import CloudKit
import Combine
import SwiftUI

/// Manages synchronization of fluid card interactions for seamless cross-device gameplay
@MainActor
class FluidCardInteractionSync: ObservableObject {
    
    // MARK: - Dependencies
    
    private let cloudKitManager: SepticaCloudKitManager
    private let hapticManager: HapticManager?
    private let cardRenderer: CardRenderer?
    
    // MARK: - Published State
    
    @Published var cardStates: [UUID: CardInteractionState] = [:]
    @Published var activeGestureState: GestureState?
    @Published var ghostCardPosition: CGPoint?
    @Published var validDropZones: [DropZone] = []
    @Published var currentHoverZone: DropZone?
    @Published var interactionHistory: [CardInteraction] = []
    
    // MARK: - Real-time Sync State
    
    @Published var syncConnected: Bool = false
    @Published var pendingSyncs: Int = 0
    private var syncTimer: Timer?
    private let syncInterval: TimeInterval = 0.1 // 100ms for smooth real-time updates
    
    // MARK: - Card Interaction Models
    
    /// Visual effect definition for card interactions
    struct VisualEffect: Codable {
        let type: EffectType
        let intensity: Float
        let duration: TimeInterval
        let startTime: Date
        let color: EffectColor
        
        enum EffectType: String, Codable {
            case glow = "glow"
            case sparkle = "sparkle"
            case trail = "trail"
            case bounce = "bounce"
            case shake = "shake"
            case pulse = "pulse"
            case romanianGold = "romanian_gold" // Cultural theme
            case folkPattern = "folk_pattern"   // Traditional patterns
        }
        
        struct EffectColor: Codable {
            let red: Float
            let green: Float
            let blue: Float
            let alpha: Float
            
            static let romanianRed = EffectColor(red: 0.8, green: 0.1, blue: 0.1, alpha: 1.0)
            static let romanianYellow = EffectColor(red: 1.0, green: 0.8, blue: 0.0, alpha: 1.0)
            static let romanianBlue = EffectColor(red: 0.0, green: 0.3, blue: 0.6, alpha: 1.0)
            static let folkGold = EffectColor(red: 0.9, green: 0.7, blue: 0.2, alpha: 1.0)
        }
    }
    
    /// Individual card's current interaction state (Shuffle Cats inspired)
    struct CardInteractionState: Codable {
        let cardId: UUID
        var position: CGPoint
        var rotation: Double
        var scale: Double
        var opacity: Double
        var zIndex: Int
        var interactionState: InteractionType
        var visualEffects: [VisualEffect]
        var hapticPattern: HapticPattern?
        var lastUpdate: Date
        var masteryLevel: Int // From card mastery system
        var isPlayable: Bool
        var glowIntensity: Float
        
        enum InteractionType: String, Codable {
            case idle = "idle"
            case hovering = "hovering"       // Mouse/finger over card
            case dragging = "dragging"       // Being dragged
            case ghosting = "ghosting"       // Ghost preview in drop zone
            case snapping = "snapping"       // Snapping to valid position
            case playing = "playing"         // Card being played
            case celebrating = "celebrating" // Special effect on successful play
            case returning = "returning"     // Returning to hand
            
            var animationDuration: Double {
                switch self {
                case .idle: return 0.0
                case .hovering: return 0.2
                case .dragging: return 0.0 // Instant response
                case .ghosting: return 0.15
                case .snapping: return 0.3
                case .playing: return 0.5
                case .celebrating: return 1.0
                case .returning: return 0.4
                }
            }
            
            var shouldTriggerHaptic: Bool {
                switch self {
                case .hovering, .snapping, .playing, .celebrating: return true
                default: return false
                }
            }
        }
        
        enum HapticPattern: String, Codable {
            case gentleHover = "gentle_hover"       // Ages 6-8
            case confirmSelection = "confirm_select" // Ages 9-12
            case successfulPlay = "successful_play"
            case invalidMove = "invalid_move"
            case celebration = "celebration"
            case sevenWildCard = "seven_wild"       // Special pattern for 7 cards
            case eightSpecial = "eight_special"     // Special pattern for 8 cards
            
            var intensity: Float {
                switch self {
                case .gentleHover: return 0.3
                case .confirmSelection: return 0.5
                case .successfulPlay: return 0.7
                case .invalidMove: return 0.4
                case .celebration: return 1.0
                case .sevenWildCard: return 0.8
                case .eightSpecial: return 0.6
                }
            }
        }
    }
    
    /// Current gesture state for cross-device sync
    struct GestureState: Codable {
        let gestureId: UUID
        let cardId: UUID
        let startPosition: CGPoint
        let currentPosition: CGPoint
        let velocity: CGVector
        let gestureType: GestureType
        let startTime: Date
        let playerId: String
        
        enum GestureType: String, Codable {
            case drag = "drag"
            case tap = "tap"
            case doubleTap = "double_tap"
            case longPress = "long_press"
            case hover = "hover" // iPad with Apple Pencil or mouse
        }
    }
    
    /// Valid drop zones with Romanian cultural themes
    struct DropZone: Codable, Identifiable {
        let id: UUID
        let type: ZoneType
        let bounds: CGRect
        let isValid: Bool
        let hoverEffect: VisualEffect?
        let culturalTheme: String?
        
        enum ZoneType: String, Codable {
            case playArea = "play_area"           // Main table
            case playerHand = "player_hand"       // Player's hand
            case opponentArea = "opponent_area"   // Opponent side
            case discardPile = "discard_pile"     // Discard area
            case specialZone = "special_zone"     // Cultural themed zones
            
            var romanianName: String {
                switch self {
                case .playArea: return "Masa de Joc"
                case .playerHand: return "Mâna Jucătorului"
                case .opponentArea: return "Zona Adversarului"
                case .discardPile: return "Grămada de Cărți"
                case .specialZone: return "Zona Specială"
                }
            }
        }
    }
    
    /// Individual card interaction record for analytics and learning
    struct CardInteraction: Codable {
        let id: UUID
        let cardId: UUID
        let interactionType: InteractionAnalytics
        let startTime: Date
        let endTime: Date
        let wasSuccessful: Bool
        let contextData: InteractionContext
        
        enum InteractionAnalytics: String, Codable {
            case quickTap = "quick_tap"           // Fast, confident play
            case hesitantDrag = "hesitant_drag"   // Slow, uncertain movement
            case precisePlay = "precise_play"     // Accurate drop zone targeting
            case exploratoryHover = "exploratory_hover" // Learning/exploring
            case masteryPlay = "mastery_play"     // Expert level execution
        }
        
        struct InteractionContext: Codable {
            let gamePhase: String
            let availableCards: Int
            let playerConfidence: Float // 0.0 - 1.0 based on interaction patterns
            let culturalElementsActive: [String]
            let mistakesInTurn: Int
            let helpHintsUsed: Bool
        }
    }
    
    // MARK: - Initialization
    
    init(cloudKitManager: SepticaCloudKitManager, hapticManager: HapticManager?, cardRenderer: CardRenderer?) {
        self.cloudKitManager = cloudKitManager
        self.hapticManager = hapticManager
        self.cardRenderer = cardRenderer
        
        Task {
            await initializeInteractionSync()
        }
    }
    
    // MARK: - Real-time Sync Setup
    
    private func initializeInteractionSync() async {
        // Set up real-time synchronization
        startSyncTimer()
        
        // Initialize drop zones for current game state
        setupDefaultDropZones()
        
        // Connect to CloudKit for real-time updates
        await establishCloudKitSync()
    }
    
    private func startSyncTimer() {
        syncTimer = Timer.scheduledTimer(withTimeInterval: syncInterval, repeats: true) { _ in
            Task { @MainActor in
                await self.syncCardStates()
            }
        }
    }
    
    private func setupDefaultDropZones() {
        validDropZones = [
            DropZone(
                id: UUID(),
                type: .playArea,
                bounds: CGRect(x: 100, y: 200, width: 200, height: 150),
                isValid: true,
                hoverEffect: VisualEffect(
                    type: .glow,
                    intensity: 0.5,
                    duration: 0.2,
                    startTime: Date(),
                    color: .folkGold
                ),
                culturalTheme: "traditional_table"
            ),
            DropZone(
                id: UUID(),
                type: .playerHand,
                bounds: CGRect(x: 50, y: 400, width: 300, height: 80),
                isValid: true,
                hoverEffect: nil,
                culturalTheme: "wooden_hand_area"
            )
        ]
    }
    
    // MARK: - Card Interaction Management
    
    /// Update card state with Shuffle Cats-style fluid interactions
    func updateCardInteraction(cardId: UUID, newState: CardInteractionState.InteractionType, position: CGPoint, additionalData: [String: Any] = [:]) async {
        
        let currentTime = Date()
        
        // Get existing state or create new one
        var cardState = cardStates[cardId] ?? CardInteractionState(
            cardId: cardId,
            position: position,
            rotation: 0,
            scale: 1.0,
            opacity: 1.0,
            zIndex: 0,
            interactionState: .idle,
            visualEffects: [],
            hapticPattern: nil,
            lastUpdate: currentTime,
            masteryLevel: 0,
            isPlayable: true,
            glowIntensity: 0.0
        )
        
        // Update state based on interaction type
        cardState.interactionState = newState
        cardState.position = position
        cardState.lastUpdate = currentTime
        
        // Apply state-specific modifications
        await applyInteractionEffects(&cardState, newState: newState)
        
        // Update local state
        cardStates[cardId] = cardState
        
        // Trigger haptic feedback if appropriate
        if newState.shouldTriggerHaptic, let hapticPattern = cardState.hapticPattern {
            await triggerHapticFeedback(hapticPattern, ageGroup: getCurrentAgeGroup())
        }
        
        // Sync to CloudKit for cross-device updates
        await syncCardStateToCloudKit(cardState)
        
        // Record interaction for analytics
        recordInteraction(cardId: cardId, interactionType: newState, position: position)
    }
    
    private func applyInteractionEffects(_ cardState: inout CardInteractionState, newState: CardInteractionState.InteractionType) async {
        switch newState {
        case .idle:
            cardState.scale = 1.0
            cardState.glowIntensity = 0.0
            cardState.zIndex = 0
            cardState.visualEffects.removeAll()
            
        case .hovering:
            cardState.scale = 1.05
            cardState.glowIntensity = 0.3
            cardState.zIndex = 10
            cardState.hapticPattern = .gentleHover
            
            // Add gentle glow effect
            cardState.visualEffects.append(CardInteractionState.VisualEffect(
                type: .glow,
                intensity: 0.4,
                duration: 0.2,
                startTime: Date(),
                color: .folkGold
            ))
            
        case .dragging:
            cardState.scale = 1.1
            cardState.glowIntensity = 0.6
            cardState.zIndex = 100
            cardState.opacity = 0.9
            
            // Add trail effect for smooth dragging
            cardState.visualEffects.append(CardInteractionState.VisualEffect(
                type: .trail,
                intensity: 0.7,
                duration: 0.1,
                startTime: Date(),
                color: .romanianBlue
            ))
            
        case .ghosting:
            cardState.opacity = 0.5
            cardState.scale = 0.95
            
        case .snapping:
            cardState.hapticPattern = .confirmSelection
            cardState.visualEffects.append(CardInteractionState.VisualEffect(
                type: .bounce,
                intensity: 0.8,
                duration: 0.3,
                startTime: Date(),
                color: .folkGold
            ))
            
        case .playing:
            cardState.scale = 1.2
            cardState.hapticPattern = .successfulPlay
            cardState.visualEffects.append(CardInteractionState.VisualEffect(
                type: .pulse,
                intensity: 1.0,
                duration: 0.5,
                startTime: Date(),
                color: .romanianRed
            ))
            
        case .celebrating:
            // Special celebration for successful plays
            cardState.visualEffects.append(contentsOf: [
                CardInteractionState.VisualEffect(
                    type: .sparkle,
                    intensity: 1.0,
                    duration: 1.0,
                    startTime: Date(),
                    color: .romanianYellow
                ),
                CardInteractionState.VisualEffect(
                    type: .folkPattern,
                    intensity: 0.8,
                    duration: 1.0,
                    startTime: Date(),
                    color: .folkGold
                )
            ])
            cardState.hapticPattern = .celebration
            
        case .returning:
            cardState.scale = 1.0
            cardState.opacity = 1.0
            cardState.zIndex = 5
        }
    }
    
    // MARK: - Gesture Recognition & Sync
    
    func startGesture(cardId: UUID, gestureType: GestureState.GestureType, startPosition: CGPoint) async {
        let gestureState = GestureState(
            gestureId: UUID(),
            cardId: cardId,
            startPosition: startPosition,
            currentPosition: startPosition,
            velocity: .zero,
            gestureType: gestureType,
            startTime: Date(),
            playerId: getCurrentPlayerId()
        )
        
        activeGestureState = gestureState
        
        // Update card state to dragging
        await updateCardInteraction(cardId: cardId, newState: .dragging, position: startPosition)
        
        // Show valid drop zones
        updateValidDropZones(for: cardId)
    }
    
    func updateGesture(currentPosition: CGPoint, velocity: CGVector) async {
        guard var gesture = activeGestureState else { return }
        
        gesture = GestureState(
            gestureId: gesture.gestureId,
            cardId: gesture.cardId,
            startPosition: gesture.startPosition,
            currentPosition: currentPosition,
            velocity: velocity,
            gestureType: gesture.gestureType,
            startTime: gesture.startTime,
            playerId: gesture.playerId
        )
        
        activeGestureState = gesture
        
        // Update ghost card position
        ghostCardPosition = currentPosition
        
        // Check for hover over drop zones
        checkDropZoneHover(position: currentPosition)
        
        // Update card visual state
        await updateCardInteraction(cardId: gesture.cardId, newState: .dragging, position: currentPosition)
    }
    
    func endGesture(finalPosition: CGPoint) async {
        guard let gesture = activeGestureState else { return }
        
        // Check if dropped in valid zone
        let dropZone = validDropZones.first { zone in
            zone.bounds.contains(finalPosition) && zone.isValid
        }
        
        if let zone = dropZone {
            // Snap to drop zone
            await snapToDropZone(cardId: gesture.cardId, zone: zone)
        } else {
            // Return to hand
            await returnCardToHand(cardId: gesture.cardId)
        }
        
        // Clean up gesture state
        activeGestureState = nil
        ghostCardPosition = nil
        currentHoverZone = nil
    }
    
    // MARK: - Drop Zone Management
    
    private func updateValidDropZones(for cardId: UUID) {
        // Update which drop zones are valid for the current card
        // This would be based on game rules and current game state
        for index in validDropZones.indices {
            validDropZones[index] = DropZone(
                id: validDropZones[index].id,
                type: validDropZones[index].type,
                bounds: validDropZones[index].bounds,
                isValid: isValidDropZone(zone: validDropZones[index], for: cardId),
                hoverEffect: validDropZones[index].hoverEffect,
                culturalTheme: validDropZones[index].culturalTheme
            )
        }
    }
    
    private func isValidDropZone(zone: DropZone, for cardId: UUID) -> Bool {
        // Implement game rules logic here
        // For now, return true for play area and false for opponent area
        switch zone.type {
        case .playArea: return true
        case .opponentArea: return false
        case .playerHand: return true
        case .discardPile: return false
        case .specialZone: return true
        }
    }
    
    private func checkDropZoneHover(position: CGPoint) {
        let hoveredZone = validDropZones.first { zone in
            zone.bounds.contains(position) && zone.isValid
        }
        
        if hoveredZone?.id != currentHoverZone?.id {
            currentHoverZone = hoveredZone
            
            if let zone = hoveredZone {
                // Trigger hover effect
                Task {
                    await triggerZoneHoverEffect(zone)
                }
            }
        }
    }
    
    private func triggerZoneHoverEffect(_ zone: DropZone) async {
        // Add visual feedback for drop zone hover
        hapticManager?.trigger(.cardHover)
    }
    
    private func snapToDropZone(cardId: UUID, zone: DropZone) async {
        let snapPosition = CGPoint(x: zone.bounds.midX, y: zone.bounds.midY)
        
        // Animate snap with haptic feedback
        await updateCardInteraction(cardId: cardId, newState: .snapping, position: snapPosition)
        
        // After snap animation, play the card
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            Task {
                await self.playCard(cardId: cardId, in: zone)
            }
        }
    }
    
    private func returnCardToHand(cardId: UUID) async {
        // Return card to original position in hand
        let handPosition = getHandPositionForCard(cardId)
        await updateCardInteraction(cardId: cardId, newState: .returning, position: handPosition)
        
        // Play gentle feedback
        hapticManager?.trigger(.cardInvalid)
    }
    
    private func playCard(cardId: UUID, in zone: DropZone) async {
        // Update to playing state with celebration
        await updateCardInteraction(cardId: cardId, newState: .playing, position: CGPoint(x: zone.bounds.midX, y: zone.bounds.midY))
        
        // After playing animation, celebrate if it was a good move
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            Task {
                await self.celebrateCardPlay(cardId: cardId)
            }
        }
    }
    
    private func celebrateCardPlay(cardId: UUID) async {
        await updateCardInteraction(cardId: cardId, newState: .celebrating, position: cardStates[cardId]?.position ?? .zero)
        
        // Special celebration for culturally significant cards (7s and 8s)
        if let cardState = cardStates[cardId] {
            // Check if this is a 7 (wild card) or 8 (special rules)
            // This would connect to the cultural achievement system
        }
    }
    
    // MARK: - CloudKit Synchronization
    
    private func establishCloudKitSync() async {
        syncConnected = await cloudKitManager.isAvailable
        
        if syncConnected {
            print("✅ Fluid card interaction sync established")
        } else {
            print("⚠️ CloudKit unavailable - using local sync only")
        }
    }
    
    private func syncCardStates() async {
        guard syncConnected && pendingSyncs > 0 else { return }
        
        // Batch sync all pending card state changes
        let statesToSync = cardStates.filter { _, state in
            Date().timeIntervalSince(state.lastUpdate) < 1.0 // Only recent changes
        }
        
        if !statesToSync.isEmpty {
            await syncCardStatesToCloudKit(Array(statesToSync.values))
        }
    }
    
    private func syncCardStateToCloudKit(_ cardState: CardInteractionState) async {
        guard syncConnected else { return }
        
        pendingSyncs += 1
        
        // This would save to CloudKit for cross-device sync
        // Implementation would be similar to game state sync
        
        pendingSyncs = max(0, pendingSyncs - 1)
    }
    
    private func syncCardStatesToCloudKit(_ cardStates: [CardInteractionState]) async {
        // Batch sync implementation
        print("🔄 Syncing \(cardStates.count) card states to CloudKit")
    }
    
    // MARK: - Haptic Feedback Management
    
    private func triggerHapticFeedback(_ pattern: CardInteractionState.HapticPattern, ageGroup: String) async {
        let intensity = adjustIntensityForAge(pattern.intensity, ageGroup: ageGroup)
        
        switch pattern {
        case .gentleHover:
            hapticManager?.trigger(.cardSelect)
        case .confirmSelection:
            hapticManager?.trigger(.cardHover)
        case .successfulPlay:
            hapticManager?.trigger(.cardPlay)
        case .invalidMove:
            hapticManager?.trigger(.cardInvalid)
        case .celebration:
            hapticManager?.trigger(.success)
        case .sevenWildCard, .eightSpecial:
            // Special pattern for Romanian cultural cards
            hapticManager?.trigger(.gameVictory)
        }
    }
    
    private func adjustIntensityForAge(_ baseIntensity: Float, ageGroup: String) -> Float {
        switch ageGroup {
        case "ages6to8": return baseIntensity * 0.6  // Gentler for younger children
        case "ages9to12": return baseIntensity * 0.8 // Moderate
        default: return baseIntensity                // Full intensity for adults
        }
    }
    
    // MARK: - Analytics & Learning
    
    private func recordInteraction(cardId: UUID, interactionType: CardInteractionState.InteractionType, position: CGPoint) {
        let interaction = CardInteraction(
            id: UUID(),
            cardId: cardId,
            interactionType: classifyInteraction(interactionType),
            startTime: Date(),
            endTime: Date(),
            wasSuccessful: interactionType == .playing,
            contextData: CardInteraction.InteractionContext(
                gamePhase: "playing", // Would be dynamic
                availableCards: cardStates.count,
                playerConfidence: calculatePlayerConfidence(),
                culturalElementsActive: getCurrentCulturalElements(),
                mistakesInTurn: 0,
                helpHintsUsed: false
            )
        )
        
        interactionHistory.append(interaction)
        
        // Keep only recent history
        if interactionHistory.count > 100 {
            interactionHistory.removeFirst()
        }
    }
    
    private func classifyInteraction(_ type: CardInteractionState.InteractionType) -> CardInteraction.InteractionAnalytics {
        // Analyze interaction patterns for learning insights
        switch type {
        case .playing: return .precisePlay
        case .dragging: return .hesitantDrag
        case .hovering: return .exploratoryHover
        default: return .quickTap
        }
    }
    
    private func calculatePlayerConfidence() -> Float {
        // Analyze recent interactions to determine player confidence
        let recentInteractions = interactionHistory.suffix(10)
        let successRate = Float(recentInteractions.filter { $0.wasSuccessful }.count) / Float(max(recentInteractions.count, 1))
        return successRate
    }
    
    // MARK: - Utility Methods
    
    private func getCurrentPlayerId() -> String {
        return "current_player_id" // Would be retrieved from player service
    }
    
    private func getCurrentAgeGroup() -> String {
        return "ages9to12" // Would be retrieved from player preferences
    }
    
    private func getHandPositionForCard(_ cardId: UUID) -> CGPoint {
        // Calculate position in player's hand
        return CGPoint(x: 150, y: 450) // Placeholder
    }
    
    private func getCurrentCulturalElements() -> [String] {
        return ["traditional_music", "folk_colors", "romanian_patterns"]
    }
    
    deinit {
        syncTimer?.invalidate()
    }
}