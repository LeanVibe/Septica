//
//  RewardChestService.swift
//  Septica
//
//  Clash Royale-inspired chest & reward system with Romanian cultural unlockables
//  Integrates with CloudKit for cross-device progression synchronization
//

import CloudKit
import Foundation
import Combine

/// Romanian-themed reward chest system inspired by Clash Royale progression
/// Combines traditional folk art with modern gamification mechanics
@MainActor
class RewardChestService: ObservableObject {
    
    // MARK: - Dependencies
    
    private let cloudKitManager: SepticaCloudKitManager
    private let culturalSystem: CulturalAchievementSystem
    
    // MARK: - Published State
    
    @Published var chestQueue: [RewardChest] = []
    @Published var openingChest: RewardChest?
    @Published var chestSlots: [ChestSlot] = []
    @Published var dailyChestAvailable: Bool = true
    @Published var nextFreeChestTime: Date?
    
    // MARK: - Romanian Cultural Chest System
    
    /// Romanian-themed chest types with cultural significance
    enum ChestType: String, CaseIterable, Codable {
        case wooden = "wooden"           // Basic village chest
        case folk = "folk"               // Romanian folk art themed
        case cultural = "cultural"       // Special Romanian heritage chest
        case seasonal = "seasonal"       // Holiday-themed (Martisor, etc.)
        case legendary = "legendary"     // Great Romanian masters
        case daily = "daily"             // Daily folk blessing
        
        var displayName: String {
            switch self {
            case .wooden: return "Lada de Lemn"
            case .folk: return "Lada Populară"
            case .cultural: return "Lada Culturală"
            case .seasonal: return "Lada Sărbătorii"
            case .legendary: return "Lada Legendară"
            case .daily: return "Binecuvântarea Zilnică"
            }
        }
        
        var culturalDescription: String {
            switch self {
            case .wooden: return "Traditional wooden chest from Romanian villages"
            case .folk: return "Decorated with authentic Romanian folk art patterns"
            case .cultural: return "Contains treasures of Romanian heritage"
            case .seasonal: return "Special celebration chest with holiday themes"
            case .legendary: return "Honors great Romanian cultural figures"
            case .daily: return "Daily blessing with folk wisdom"
            }
        }
        
        var openDuration: TimeInterval {
            switch self {
            case .wooden: return 4 * 3600      // 4 hours
            case .folk: return 8 * 3600        // 8 hours
            case .cultural: return 12 * 3600   // 12 hours
            case .seasonal: return 24 * 3600   // 24 hours
            case .legendary: return 48 * 3600  // 48 hours
            case .daily: return 0               // Instant
            }
        }
        
        var gemCost: Int {
            switch self {
            case .wooden: return 25
            case .folk: return 50
            case .cultural: return 100
            case .seasonal: return 200
            case .legendary: return 500
            case .daily: return 0
            }
        }
        
        var rarity: ChestRarity {
            switch self {
            case .wooden, .daily: return .common
            case .folk: return .rare
            case .cultural: return .epic
            case .seasonal, .legendary: return .legendary
            }
        }
    }
    
    enum ChestRarity: String, Codable {
        case common = "common"
        case rare = "rare"
        case epic = "epic"
        case legendary = "legendary"
        
        var glowColor: String {
            switch self {
            case .common: return "#8B4513"      // Wood brown
            case .rare: return "#4169E1"        // Romanian blue
            case .epic: return "#FFD700"        // Romanian gold
            case .legendary: return "#DC143C"   // Romanian red
            }
        }
    }
    
    /// Individual reward chest with Romanian cultural theming
    struct RewardChest: Codable, Identifiable {
        let id: String
        let type: ChestType
        let earnedDate: Date
        var isOpening: Bool = false
        var openStartTime: Date?
        var rewards: [ChestReward] = []
        
        // Romanian cultural metadata
        let culturalTheme: String       // e.g., "transylvania_folk", "moldovan_traditions"
        let folkPattern: String         // Visual pattern identifier
        let seasonalBonus: Bool         // Extra rewards for Romanian holidays
        
        var timeUntilOpen: TimeInterval? {
            guard let startTime = openStartTime else { return nil }
            let elapsed = Date().timeIntervalSince(startTime)
            let remaining = type.openDuration - elapsed
            return max(0, remaining)
        }
        
        var isReadyToOpen: Bool {
            timeUntilOpen == 0
        }
        
        var progressPercentage: Float {
            guard let startTime = openStartTime else { return 0 }
            let elapsed = Date().timeIntervalSince(startTime)
            return Float(elapsed / type.openDuration).clamped(to: 0...1)
        }
    }
    
    /// Romanian-themed rewards with cultural education value
    enum RewardType: String, CaseIterable, Codable {
        case trophies = "trophies"
        case cards = "cards"
        case cardBacks = "card_backs"
        case folkMusic = "folk_music"
        case colorThemes = "color_themes"
        case culturalStories = "cultural_stories"
        case traditionalPatterns = "traditional_patterns"
        case achievements = "achievements"
        case gems = "gems"
        
        var displayName: String {
            switch self {
            case .trophies: return "Trofee"
            case .cards: return "Cărți de Joc"
            case .cardBacks: return "Modele de Cărți"
            case .folkMusic: return "Muzică Populară"
            case .colorThemes: return "Teme Tradiționale"
            case .culturalStories: return "Povești Culturale"
            case .traditionalPatterns: return "Modele Populare"
            case .achievements: return "Realizări"
            case .gems: return "Pietre Prețioase"
            }
        }
    }
    
    struct ChestReward: Codable, Identifiable {
        let id: String
        let type: RewardType
        let quantity: Int
        let itemKey: String         // Specific item identifier
        let displayName: String
        let culturalSignificance: String
        let rarity: ChestRarity
        
        // Educational content for cultural rewards
        let educationalContent: String?
        let folkTaleReference: String?
        let historicalContext: String?
    }
    
    /// Chest slot for queue management (4 slots like Clash Royale)
    struct ChestSlot: Identifiable {
        let id: Int
        var chest: RewardChest?
        var isUnlocked: Bool
        
        var isEmpty: Bool { chest == nil }
    }
    
    // MARK: - Initialization
    
    init(cloudKitManager: SepticaCloudKitManager, culturalSystem: CulturalAchievementSystem) {
        self.cloudKitManager = cloudKitManager
        self.culturalSystem = culturalSystem
        
        // Initialize 4 chest slots (Clash Royale style)
        self.chestSlots = (0..<4).map { index in
            ChestSlot(id: index, chest: nil, isUnlocked: index == 0)
        }
        
        Task {
            await loadChestProgress()
            await checkDailyChestAvailability()
        }
    }
    
    // MARK: - Chest Management
    
    /// Award chest based on game performance and cultural engagement
    func awardChest(for gameResult: GameResult, culturalEngagement: Float) async throws {
        let chestType = determineChestType(gameResult: gameResult, culturalEngagement: culturalEngagement)
        let culturalTheme = selectCulturalTheme(for: chestType)
        
        let chest = RewardChest(
            id: UUID().uuidString,
            type: chestType,
            earnedDate: Date(),
            culturalTheme: culturalTheme,
            folkPattern: selectFolkPattern(for: culturalTheme),
            seasonalBonus: isRomanianHoliday()
        )
        
        try await addChestToQueue(chest)
        await saveChestProgress()
        
        print("🎁 Chest awarded: \(chest.type.displayName) with \(culturalTheme) theme")
    }
    
    /// Start opening a chest from the queue
    func startOpeningChest(at slotIndex: Int) async throws {
        guard slotIndex < chestSlots.count,
              let chest = chestSlots[slotIndex].chest,
              !chest.isOpening else {
            throw ChestError.invalidSlot
        }
        
        var updatedChest = chest
        updatedChest.isOpening = true
        updatedChest.openStartTime = Date()
        
        chestSlots[slotIndex].chest = updatedChest
        
        // Generate rewards immediately for instant feedback
        let rewards = await generateRewards(for: updatedChest)
        chestSlots[slotIndex].chest?.rewards = rewards
        
        await saveChestProgress()
        
        print("⏰ Opening chest: \(chest.type.displayName) - Duration: \(formatDuration(chest.type.openDuration))")
    }
    
    /// Speed up chest opening with gems
    func speedUpChest(at slotIndex: Int, useGems: Bool) async throws {
        guard slotIndex < chestSlots.count,
              let chest = chestSlots[slotIndex].chest,
              chest.isOpening else {
            throw ChestError.chestNotOpening
        }
        
        if useGems {
            let gemCost = calculateSpeedUpCost(for: chest)
            // TODO: Integrate with gem system
            print("💎 Speed up cost: \(gemCost) gems")
        }
        
        // Complete chest opening immediately
        var completedChest = chest
        completedChest.openStartTime = Date().addingTimeInterval(-chest.type.openDuration)
        chestSlots[slotIndex].chest = completedChest
        
        await saveChestProgress()
    }
    
    /// Collect rewards from opened chest
    func collectChest(at slotIndex: Int) async throws -> [ChestReward] {
        guard slotIndex < chestSlots.count,
              let chest = chestSlots[slotIndex].chest,
              chest.isReadyToOpen else {
            throw ChestError.chestNotReady
        }
        
        let rewards = chest.rewards
        
        // Apply rewards to player profile
        await applyRewards(rewards)
        
        // Clear chest slot
        chestSlots[slotIndex].chest = nil
        
        await saveChestProgress()
        
        print("🎉 Collected \(rewards.count) rewards from \(chest.type.displayName)")
        return rewards
    }
    
    /// Check for daily chest availability
    func claimDailyChest() async throws -> RewardChest? {
        guard dailyChestAvailable else {
            throw ChestError.dailyChestNotAvailable
        }
        
        let dailyChest = RewardChest(
            id: UUID().uuidString,
            type: .daily,
            earnedDate: Date(),
            culturalTheme: "daily_blessing",
            folkPattern: "traditional_motifs",
            seasonalBonus: isRomanianHoliday()
        )
        
        let rewards = await generateRewards(for: dailyChest)
        var completedChest = dailyChest
        completedChest.rewards = rewards
        
        // Apply rewards immediately (daily chests open instantly)
        await applyRewards(rewards)
        
        // Set next daily chest time
        dailyChestAvailable = false
        nextFreeChestTime = Calendar.current.date(byAdding: .day, value: 1, to: Date())
        
        await saveChestProgress()
        
        print("☀️ Daily chest claimed with \(rewards.count) rewards")
        return completedChest
    }
    
    // MARK: - Reward Generation
    
    private func generateRewards(for chest: RewardChest) async -> [ChestReward] {
        var rewards: [ChestReward] = []
        
        // Base rewards based on chest type
        let baseRewardCount = getBaseRewardCount(for: chest.type)
        let guaranteedTypes = getGuaranteedRewards(for: chest.type)
        
        // Always include guaranteed rewards
        for rewardType in guaranteedTypes {
            let reward = generateReward(type: rewardType, chest: chest, isGuaranteed: true)
            rewards.append(reward)
        }
        
        // Add random rewards to reach base count
        let remainingSlots = max(0, baseRewardCount - rewards.count)
        for _ in 0..<remainingSlots {
            let randomType = selectRandomRewardType(for: chest)
            let reward = generateReward(type: randomType, chest: chest, isGuaranteed: false)
            rewards.append(reward)
        }
        
        // Seasonal bonus rewards for Romanian holidays
        if chest.seasonalBonus {
            let bonusReward = generateSeasonalReward(chest: chest)
            rewards.append(bonusReward)
        }
        
        return rewards
    }
    
    private func generateReward(type: RewardType, chest: RewardChest, isGuaranteed: Bool) -> ChestReward {
        let baseQuantity = getBaseQuantity(for: type, chestType: chest.type)
        let quantity = isGuaranteed ? Int(Float(baseQuantity) * 1.2) : baseQuantity
        
        return ChestReward(
            id: UUID().uuidString,
            type: type,
            quantity: quantity,
            itemKey: generateItemKey(for: type, theme: chest.culturalTheme),
            displayName: generateDisplayName(for: type, theme: chest.culturalTheme),
            culturalSignificance: getCulturalSignificance(for: type, theme: chest.culturalTheme),
            rarity: determineRewardRarity(type: type, chestType: chest.type),
            educationalContent: generateEducationalContent(for: type, theme: chest.culturalTheme),
            folkTaleReference: getFolkTaleReference(for: type, theme: chest.culturalTheme),
            historicalContext: getHistoricalContext(for: type, theme: chest.culturalTheme)
        )
    }
    
    // MARK: - Helper Methods
    
    private func determineChestType(gameResult: GameResult, culturalEngagement: Float) -> ChestType {
        // Higher cultural engagement = better chests
        if culturalEngagement > 0.8 {
            return Bool.random() ? .cultural : .folk
        } else if culturalEngagement > 0.5 {
            return .folk
        } else {
            return .wooden
        }
    }
    
    private func selectCulturalTheme(for chestType: ChestType) -> String {
        let themes: [String]
        
        switch chestType {
        case .wooden:
            themes = ["village_life", "rural_traditions", "wooden_crafts"]
        case .folk:
            themes = ["transylvania_folk", "moldovan_traditions", "wallachian_art", "dobrogea_heritage"]
        case .cultural:
            themes = ["romanian_poets", "classical_music", "traditional_dance", "folk_festivals"]
        case .seasonal:
            themes = ["martisor_spring", "dragobete_love", "romania_national", "winter_customs"]
        case .legendary:
            themes = ["mihai_viteazul", "stefan_cel_mare", "romanian_legends", "cultural_heroes"]
        case .daily:
            themes = ["daily_blessing", "morning_wisdom", "folk_sayings"]
        }
        
        return themes.randomElement() ?? themes[0]
    }
    
    private func selectFolkPattern(for theme: String) -> String {
        let patterns = [
            "geometric_motifs", "floral_borders", "traditional_crosses",
            "spiral_designs", "animal_totems", "harvest_symbols"
        ]
        return patterns.randomElement() ?? "geometric_motifs"
    }
    
    private func isRomanianHoliday() -> Bool {
        let calendar = Calendar.current
        let today = Date()
        let month = calendar.component(.month, from: today)
        let day = calendar.component(.day, from: today)
        
        // Check for major Romanian holidays
        return (month == 3 && day == 1) ||  // Martisor
               (month == 12 && day == 1) ||  // Romania National Day
               (month == 2 && day == 24)     // Dragobete
    }
    
    private func getBaseRewardCount(for chestType: ChestType) -> Int {
        switch chestType {
        case .wooden, .daily: return 3
        case .folk: return 4
        case .cultural: return 5
        case .seasonal: return 6
        case .legendary: return 8
        }
    }
    
    private func getGuaranteedRewards(for chestType: ChestType) -> [RewardType] {
        switch chestType {
        case .wooden, .daily:
            return [.trophies]
        case .folk:
            return [.trophies, .folkMusic]
        case .cultural:
            return [.trophies, .culturalStories, .traditionalPatterns]
        case .seasonal:
            return [.trophies, .colorThemes, .achievements]
        case .legendary:
            return [.trophies, .culturalStories, .folkMusic, .achievements]
        }
    }
    
    private func addChestToQueue(_ chest: RewardChest) async throws {
        // Find first available slot
        guard let emptySlotIndex = chestSlots.firstIndex(where: { $0.isEmpty && $0.isUnlocked }) else {
            throw ChestError.noAvailableSlots
        }
        
        chestSlots[emptySlotIndex].chest = chest
    }
    
    private func calculateSpeedUpCost(for chest: RewardChest) -> Int {
        guard let timeRemaining = chest.timeUntilOpen else { return 0 }
        let hoursRemaining = Int(ceil(timeRemaining / 3600))
        return hoursRemaining * 10 // 10 gems per hour
    }
    
    private func applyRewards(_ rewards: [ChestReward]) async {
        for reward in rewards {
            switch reward.type {
            case .trophies:
                // TODO: Add to player trophy count
                print("🏆 +\(reward.quantity) trophies")
            case .folkMusic:
                // TODO: Unlock music track
                print("🎵 Unlocked: \(reward.displayName)")
            case .culturalStories:
                // TODO: Add to story library
                print("📚 Unlocked: \(reward.displayName)")
            case .achievements:
                // TODO: Award achievement
                print("🎖️ Achievement unlocked: \(reward.displayName)")
            default:
                print("🎁 Received: \(reward.quantity)x \(reward.displayName)")
            }
        }
    }
    
    private func loadChestProgress() async {
        // TODO: Load from CloudKit
        print("📦 Loading chest progress from CloudKit...")
    }
    
    private func saveChestProgress() async {
        // TODO: Save to CloudKit
        print("💾 Saving chest progress to CloudKit...")
    }
    
    private func checkDailyChestAvailability() async {
        // TODO: Check last daily chest claim time
        if let nextTime = nextFreeChestTime {
            dailyChestAvailable = Date() >= nextTime
        }
    }
    
    // MARK: - Content Generation Helpers
    
    private func getBaseQuantity(for rewardType: RewardType, chestType: ChestType) -> Int {
        let multiplier: Int
        switch chestType {
        case .wooden, .daily: multiplier = 1
        case .folk: multiplier = 2
        case .cultural: multiplier = 3
        case .seasonal: multiplier = 4
        case .legendary: multiplier = 5
        }
        
        switch rewardType {
        case .trophies: return 25 * multiplier
        case .gems: return 10 * multiplier
        case .cards: return 5 * multiplier
        default: return 1 * multiplier
        }
    }
    
    private func generateItemKey(for type: RewardType, theme: String) -> String {
        return "\(type.rawValue)_\(theme)_\(UUID().uuidString.prefix(8))"
    }
    
    private func generateDisplayName(for type: RewardType, theme: String) -> String {
        switch (type, theme) {
        case (.folkMusic, "transylvania_folk"):
            return "Cântec Transilvan"
        case (.colorThemes, "romanian_poets"):
            return "Culorile lui Eminescu"
        case (.culturalStories, "romanian_legends"):
            return "Legenda Meșterului Manole"
        default:
            return type.displayName
        }
    }
    
    private func getCulturalSignificance(for type: RewardType, theme: String) -> String {
        switch (type, theme) {
        case (.folkMusic, "transylvania_folk"):
            return "Traditional Transylvanian melodies passed down through generations"
        case (.culturalStories, "romanian_legends"):
            return "Ancient Romanian legends that shaped our cultural identity"
        default:
            return "Part of Romania's rich cultural heritage"
        }
    }
    
    private func determineRewardRarity(type: RewardType, chestType: ChestType) -> ChestRarity {
        switch (type, chestType) {
        case (.achievements, .legendary), (.culturalStories, .legendary):
            return .legendary
        case (.folkMusic, .cultural), (.traditionalPatterns, .cultural):
            return .epic
        case (.colorThemes, .folk):
            return .rare
        default:
            return .common
        }
    }
    
    private func generateEducationalContent(for type: RewardType, theme: String) -> String? {
        switch (type, theme) {
        case (.folkMusic, "transylvania_folk"):
            return "Learn about the unique musical traditions of Transylvania and their cultural significance."
        case (.culturalStories, "romanian_legends"):
            return "Discover the moral lessons and cultural values embedded in this traditional story."
        default:
            return nil
        }
    }
    
    private func getFolkTaleReference(for type: RewardType, theme: String) -> String? {
        switch theme {
        case "romanian_legends":
            return "legenda_mesterul_manole"
        case "transylvania_folk":
            return "povestea_ileana_cosanzeana"
        default:
            return nil
        }
    }
    
    private func getHistoricalContext(for type: RewardType, theme: String) -> String? {
        switch theme {
        case "mihai_viteazul":
            return "Michael the Brave (1593-1601) unified the Romanian principalities for the first time."
        case "stefan_cel_mare":
            return "Stephen the Great (1457-1504) defended Moldova against Ottoman expansion."
        default:
            return nil
        }
    }
    
    private func selectRandomRewardType(for chest: RewardChest) -> RewardType {
        let availableTypes = RewardType.allCases.filter { type in
            // Exclude guaranteed types to avoid duplicates
            !getGuaranteedRewards(for: chest.type).contains(type)
        }
        return availableTypes.randomElement() ?? .cards
    }
    
    private func generateSeasonalReward(chest: RewardChest) -> ChestReward {
        return ChestReward(
            id: UUID().uuidString,
            type: .achievements,
            quantity: 1,
            itemKey: "seasonal_\(chest.culturalTheme)_bonus",
            displayName: "Bonus Sărbătoresc",
            culturalSignificance: "Special reward for celebrating Romanian traditions",
            rarity: .epic,
            educationalContent: "Learn about the significance of Romanian seasonal celebrations",
            folkTaleReference: nil,
            historicalContext: "Romanian holidays connect us to our ancestral traditions"
        )
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration / 3600)
        return hours > 0 ? "\(hours)h" : "Instant"
    }
    
    // MARK: - Error Types
    
    enum ChestError: LocalizedError {
        case invalidSlot
        case chestNotOpening
        case chestNotReady
        case noAvailableSlots
        case dailyChestNotAvailable
        case insufficientGems
        
        var errorDescription: String? {
            switch self {
            case .invalidSlot:
                return "Invalid chest slot."
            case .chestNotOpening:
                return "Chest is not currently opening."
            case .chestNotReady:
                return "Chest is not ready to collect."
            case .noAvailableSlots:
                return "No available chest slots."
            case .dailyChestNotAvailable:
                return "Daily chest not available yet."
            case .insufficientGems:
                return "Not enough gems to speed up chest."
            }
        }
    }
}

// MARK: - Supporting Types

struct GameResult {
    let isWin: Bool
    let score: Int
    let opponentType: String
    let culturalEngagement: Float
}

// MARK: - Extensions

extension Float {
    func clamped(to range: ClosedRange<Float>) -> Float {
        return Swift.max(range.lowerBound, Swift.min(range.upperBound, self))
    }
}