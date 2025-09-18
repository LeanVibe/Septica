//
//  RomanianTournamentManager.swift
//  Septica
//
//  Romanian Tournament System - Sprint 3 Week 9
//  Multi-game tournament system with Romanian cultural progression
//

import Foundation
import CloudKit
import Combine
import os.log

/// Romanian cultural tournament system with authentic arena progression
@MainActor
class RomanianTournamentManager: ObservableObject {
    
    // MARK: - Dependencies
    
    private let cloudKitManager: SepticaCloudKitManager
    private let playerProfileService: PlayerProfileService
    private let logger = Logger(subsystem: "dev.leanvibe.game.Septica", category: "RomanianTournamentManager")
    
    // MARK: - Published Tournament State
    
    @Published var activeTournaments: [RomanianTournament] = []
    @Published var currentTournament: RomanianTournament?
    @Published var playerTournamentProfile: TournamentPlayerProfile?
    @Published var tournamentHistory: [CompletedTournament] = []
    @Published var seasonalLeaderboard: [LeaderboardEntry] = []
    
    // MARK: - Romanian Cultural Tournament Features
    
    @Published var currentArenaChampionship: ArenaChampionship?
    @Published var culturalSeasonProgress: CulturalSeasonProgress = CulturalSeasonProgress()
    @Published var romanianCelebrationTournaments: [CelebrationTournament] = []
    @Published var localFolkFestivalEvents: [FolkFestivalEvent] = []
    
    // MARK: - Sprint 3: Regional Tournament System
    
    @Published var regionalTournaments: [RomanianRegionalTournament] = []
    @Published var playerRegionalProgress: RegionalTournamentProgress = RegionalTournamentProgress()
    @Published var unlockedRegions: Set<TournamentRegion> = [.wallachia] // Start with Wallachia
    @Published var culturalRewards: [CulturalReward] = []
    @Published var currentRegionalTournament: RomanianRegionalTournament?
    
    // MARK: - Tournament Management State
    
    @Published var isSearchingForTournament: Bool = false
    @Published var tournamentSyncStatus: TournamentSyncStatus = .idle
    @Published var availableTournamentTypes: [TournamentType] = []
    @Published var upcomingCulturalEvents: [CulturalEvent] = []
    
    // MARK: - Initialization
    
    init(cloudKitManager: SepticaCloudKitManager, playerProfileService: PlayerProfileService) {
        self.cloudKitManager = cloudKitManager
        self.playerProfileService = playerProfileService
        
        Task {
            await initializeTournamentSystem()
            await loadPlayerTournamentProfile()
            await initializeSeasonalRomanianEvents()
        }
    }
    
    // MARK: - Tournament System Initialization
    
    private func initializeTournamentSystem() async {
        do {
            // Load available tournament types based on player's Romanian cultural level
            availableTournamentTypes = await generateAvailableTournamentTypes()
            
            // Load active Romanian cultural tournaments
            activeTournaments = try await loadActiveTournaments()
            
            // Initialize seasonal Romanian cultural events
            await initializeSeasonalRomanianEvents()
            
            // Initialize regional tournaments for Sprint 3
            await initializeRegionalTournaments()
            
            logger.info("Romanian tournament system initialized with \(self.activeTournaments.count) active tournaments and \(self.regionalTournaments.count) regional tournaments")
            
        } catch {
            logger.error("Failed to initialize tournament system: \(error.localizedDescription)")
        }
    }
    
    private func loadPlayerTournamentProfile() async {
        guard let currentProfile = playerProfileService.currentProfile else {
            await createNewTournamentProfile()
            return
        }
        
        // Create tournament profile from existing player data
        playerTournamentProfile = TournamentPlayerProfile(
            playerID: currentProfile.playerID,
            displayName: currentProfile.displayName,
            currentArena: currentProfile.currentArena,
            tournamentRating: calculateInitialTournamentRating(from: currentProfile),
            tournamentsPlayed: 0,
            tournamentsWon: 0,
            culturalKnowledgeLevel: Int(currentProfile.heritageEngagementLevel * 10),
            preferredTournamentTypes: [.romanianVillageChampionship, .folkFestivalTournament],
            seasonalAchievements: [],
            folkMusicPreferences: currentProfile.folkMusicListened,
            culturalMilestones: currentProfile.achievements.map { $0.rawValue }
        )
    }
    
    // MARK: - Tournament Creation & Management
    
    /// Create a new Romanian cultural tournament
    func createTournament(type: TournamentType, theme: TournamentCulturalTheme) async throws -> RomanianTournament {
        guard let profile = playerTournamentProfile else {
            throw TournamentError.playerProfileNotFound
        }
        
        let tournament = RomanianTournament(
            id: UUID().uuidString,
            type: type,
            culturalTheme: theme,
            arenaLocation: profile.currentArena,
            createdBy: profile.playerID,
            maxParticipants: type.maxParticipants,
            entryRequirements: type.entryRequirements,
            culturalRewards: generateCulturalRewards(for: type, theme: theme),
            folkMusicPlaylist: generateFolkMusicPlaylist(for: theme),
            educationalContent: generateEducationalContent(for: theme),
            startTime: Date().addingTimeInterval(type.waitingPeriod),
            estimatedDuration: type.estimatedDuration
        )
        
        // Save tournament to CloudKit
        try await saveTournamentToCloudKit(tournament)
        
        // Add to active tournaments
        activeTournaments.append(tournament)
        
        logger.info("Created Romanian tournament: \(type.displayName) with theme: \(theme.romanianName)")
        
        return tournament
    }
    
    /// Join an existing Romanian tournament
    func joinTournament(_ tournament: RomanianTournament) async throws {
        guard let profile = playerTournamentProfile else {
            throw TournamentError.playerProfileNotFound
        }
        
        // Validate entry requirements
        try validateTournamentEntry(tournament: tournament, player: profile)
        
        // Add player to tournament
        var updatedTournament = tournament
        updatedTournament.participants.append(TournamentParticipant(
            playerID: profile.playerID,
            displayName: profile.displayName,
            currentArena: profile.currentArena,
            tournamentRating: profile.tournamentRating,
            culturalLevel: profile.culturalKnowledgeLevel,
            joinedAt: Date(),
            isReady: false
        ))
        
        // Update in CloudKit
        try await updateTournamentInCloudKit(updatedTournament)
        
        // Update local state
        if let index = activeTournaments.firstIndex(where: { $0.id == tournament.id }) {
            activeTournaments[index] = updatedTournament
        }
        
        currentTournament = updatedTournament
        
        logger.info("Joined tournament: \(tournament.culturalTheme.romanianName)")
    }
    
    /// Start tournament when conditions are met
    func startTournament(_ tournament: RomanianTournament) async throws {
        guard tournament.canStart else {
            throw TournamentError.insufficientParticipants
        }
        
        var updatedTournament = tournament
        updatedTournament.status = .inProgress
        updatedTournament.actualStartTime = Date()
        
        // Generate tournament bracket with Romanian cultural significance
        updatedTournament.bracket = generateRomanianCulturalBracket(participants: tournament.participants)
        
        // Update tournament
        try await updateTournamentInCloudKit(updatedTournament)
        
        // Update local state
        if let index = activeTournaments.firstIndex(where: { $0.id == tournament.id }) {
            activeTournaments[index] = updatedTournament
        }
        
        currentTournament = updatedTournament
        
        logger.info("Started Romanian tournament with \(tournament.participants.count) participants")
    }
    
    // MARK: - Romanian Cultural Seasonal Events
    
    private func initializeSeasonalRomanianEvents() async {
        let currentDate = Date()
        let calendar = Calendar.current
        
        // March 1st - Mărțișor Tournament
        if calendar.component(.month, from: currentDate) == 3 {
            await createMartisorTournament()
        }
        
        // December 1st - Romania National Day Tournament
        if calendar.component(.month, from: currentDate) == 12 && calendar.component(.day, from: currentDate) == 1 {
            await createNationalDayTournament()
        }
        
        // Summer Folk Festival Tournaments (June-August)
        let summerMonths = [6, 7, 8]
        if summerMonths.contains(calendar.component(.month, from: currentDate)) {
            await createFolkFestivalTournaments()
        }
        
        // Winter Heritage Tournaments (December-February)
        let winterMonths = [12, 1, 2]
        if winterMonths.contains(calendar.component(.month, from: currentDate)) {
            await createWinterHeritageTournaments()
        }
    }
    
    private func createMartisorTournament() async {
        let martisorTournament = CelebrationTournament(
            id: "martisor_2025",
            celebrationType: TournamentCelebration.martisor,
            title: "Turneu de Mărțișor 2025",
            description: "Celebrate the arrival of spring with traditional Romanian Septica in the spirit of Mărțișor",
            culturalEducation: "Mărțișor is celebrated on March 1st, marking the beginning of spring and new life in Romanian tradition",
            specialRewards: [
                "Mărțișor card back design with traditional red and white threads",
                "Spring folk music collection",
                "Special March cultural achievement badge"
            ],
            startDate: Calendar.current.date(from: DateComponents(year: 2025, month: 3, day: 1))!,
            endDate: Calendar.current.date(from: DateComponents(year: 2025, month: 3, day: 8))!,
            isActive: true
        )
        
        romanianCelebrationTournaments.append(martisorTournament)
    }
    
    private func createNationalDayTournament() async {
        let nationalDayTournament = CelebrationTournament(
            id: "national_day_2025",
            celebrationType: TournamentCelebration.nationalDay,
            title: "Turneu Ziua României 2025",
            description: "Honor Romania's Great Union with a special championship tournament",
            culturalEducation: "December 1st commemorates the unification of all Romanian provinces in 1918, creating modern Romania",
            specialRewards: [
                "Tricolor Romanian flag card effects",
                "National anthem folk arrangement",
                "Great Union historical achievement badge"
            ],
            startDate: Calendar.current.date(from: DateComponents(year: 2025, month: 12, day: 1))!,
            endDate: Calendar.current.date(from: DateComponents(year: 2025, month: 12, day: 1))!,
            isActive: true
        )
        
        romanianCelebrationTournaments.append(nationalDayTournament)
    }
    
    // MARK: - Sprint 3: Regional Tournament System Implementation
    
    private func initializeRegionalTournaments() async {
        logger.info("Initializing Romanian regional tournaments - Sprint 3")
        
        // Create regional tournaments for all five Romanian regions
        regionalTournaments = [
            createTransilvaniaTournament(),
            createMoldovaTournament(),
            createWallachiaTournament(),
            createBanatTournament(),
            createDobrudjaTournament()
        ]
        
        logger.info("Created \(self.regionalTournaments.count) regional tournaments")
    }
    
    private func createTransilvaniaTournament() -> RomanianRegionalTournament {
        return RomanianRegionalTournament(
            id: "transilvania_cup",
            region: .transilvania,
            displayName: "Cupa Transilvaniei",
            englishName: "Transilvania Cup",
            culturalTheme: RegionalCulturalTheme(
                name: "Mountain Wisdom",
                folklore: "Ancient strategies passed down through Carpathian valleys",
                traditionalColors: ["#2B5F3F", "#4A5D68", "#D4AF37"], // Forest Green, Mountain Gray, Gold
                folkPattern: .carpathianMotif
            ),
            difficulty: .beginner,
            unlockRequirements: RegionalUnlockRequirements(
                requiredRegions: [.wallachia],
                minimumAchievements: 3,
                culturalKnowledgeLevel: 1
            ),
            opponents: [
                RegionalOpponent(name: "Mihai Munteanul", personality: .wiseSage, difficulty: .easy),
                RegionalOpponent(name: "Ana Păstorița", personality: .patientScholar, difficulty: .medium),
                RegionalOpponent(name: "Ștefan Carpatin", personality: .mountainHunter, difficulty: .hard)
            ],
            culturalChallenges: [
                CulturalChallenge(
                    type: .traditionalStrategy,
                    description: "Play like a Transilvanian shepherd - patient and observant",
                    requirement: "Use traditional Carpathian defensive strategy",
                    bonus: 50
                )
            ],
            rewards: RegionalTournamentRewards(
                culturalSymbols: [.carpathianCross, .moldavianTradition],
                achievementPoints: 100,
                folkloreStories: ["The Wise Shepherd of Bucegi"],
                unlocksRegion: .transilvania
            ),
            folklore: RegionalFolklore(
                openingStory: "In the shadow of the Carpathians, where ancient wisdom flows like mountain streams...",
                victoryTale: "Your strategic wisdom echoes through the valleys, earning the respect of mountain folk.",
                traditionExplanation: "Transilvanian Septica emphasizes patience and careful observation, like shepherds watching their flocks."
            )
        )
    }
    
    private func createMoldovaTournament() -> RomanianRegionalTournament {
        return RomanianRegionalTournament(
            id: "moldova_league",
            region: .moldova,
            displayName: "Liga Moldovei",
            englishName: "Moldova League",
            culturalTheme: RegionalCulturalTheme(
                name: "Scholarly Tradition",
                folklore: "The wisdom of Moldavian scholars and their strategic minds",
                traditionalColors: ["#1B4B8C", "#D4AF37", "#F5F5DC"], // Monastery Blue, Scholar Gold, Wisdom White
                folkPattern: .moldavianScroll
            ),
            difficulty: .intermediate,
            unlockRequirements: RegionalUnlockRequirements(
                requiredRegions: [.wallachia, .transilvania],
                minimumAchievements: 8,
                culturalKnowledgeLevel: 3
            ),
            opponents: [
                RegionalOpponent(name: "Învățătorul Radu", personality: .patientScholar, difficulty: .medium),
                RegionalOpponent(name: "Maica Teodora", personality: .wiseSage, difficulty: .hard),
                RegionalOpponent(name: "Domnu' Bogdan", personality: .scholarlyWisdom, difficulty: .expert)
            ],
            culturalChallenges: [
                CulturalChallenge(
                    type: .scholarlyWisdom,
                    description: "Channel the wisdom of Moldavian scholars",
                    requirement: "Make thoughtful, calculated moves (minimum 5 seconds thinking time)",
                    bonus: 75
                )
            ],
            rewards: RegionalTournamentRewards(
                culturalSymbols: [.moldavianScroll, .scholarSeal],
                achievementPoints: 200,
                folkloreStories: ["The Scholar's Strategic Mind", "Monastery Games"],
                unlocksRegion: .moldova
            ),
            folklore: RegionalFolklore(
                openingStory: "In the monasteries of Moldova, where scholars pondered both faith and strategy...",
                victoryTale: "Your thoughtful play honors the scholarly tradition of Moldavian masters.",
                traditionExplanation: "Moldavian strategy values deep thinking and careful planning, like monks illuminating manuscripts."
            )
        )
    }
    
    private func createWallachiaTournament() -> RomanianRegionalTournament {
        return RomanianRegionalTournament(
            id: "wallachia_championship",
            region: .wallachia,
            displayName: "Campionatul Țării Românești",
            englishName: "Wallachia Championship",
            culturalTheme: RegionalCulturalTheme(
                name: "Royal Court",
                folklore: "Strategic games of the Wallachian royal court",
                traditionalColors: ["#6A0DAD", "#D4AF37", "#8B0000"], // Royal Purple, Court Gold, Velvet Red
                folkPattern: .wallachianCrown
            ),
            difficulty: .beginner,
            unlockRequirements: RegionalUnlockRequirements(
                requiredRegions: [], // Starting region
                minimumAchievements: 0,
                culturalKnowledgeLevel: 0
            ),
            opponents: [
                RegionalOpponent(name: "Boierul Matei", personality: .boldWarrior, difficulty: .easy),
                RegionalOpponent(name: "Doamna Ecaterina", personality: .craftyCunning, difficulty: .medium),
                RegionalOpponent(name: "Principele Alexandru", personality: .royalStrategist, difficulty: .hard)
            ],
            culturalChallenges: [
                CulturalChallenge(
                    type: .royalBoldness,
                    description: "Play with the boldness of Wallachian princes",
                    requirement: "Make decisive, confident moves",
                    bonus: 60
                )
            ],
            rewards: RegionalTournamentRewards(
                culturalSymbols: [.wallachianEagle, .courtScepter],
                achievementPoints: 50,
                folkloreStories: ["The Prince's Favorite Game"],
                unlocksRegion: nil // Already unlocked
            ),
            folklore: RegionalFolklore(
                openingStory: "In the grand halls of Curtea de Argeș, where princes played games of wit and strategy...",
                victoryTale: "Your noble play would have impressed the greatest Wallachian princes.",
                traditionExplanation: "Wallachian style emphasizes bold moves and decisive action, like the great princes of old."
            )
        )
    }
    
    private func createBanatTournament() -> RomanianRegionalTournament {
        return RomanianRegionalTournament(
            id: "banat_festival",
            region: .banat,
            displayName: "Festivalul Banatului",
            englishName: "Banat Festival",
            culturalTheme: RegionalCulturalTheme(
                name: "Community Celebration",
                folklore: "Joyful games during Banat harvest festivals",
                traditionalColors: ["#DAA520", "#DC143C", "#228B22"], // Harvest Gold, Festival Red, Community Green
                folkPattern: .banatWheat
            ),
            difficulty: .intermediate,
            unlockRequirements: RegionalUnlockRequirements(
                requiredRegions: [.wallachia, .transilvania],
                minimumAchievements: 6,
                culturalKnowledgeLevel: 2
            ),
            opponents: [
                RegionalOpponent(name: "Vasile Agricultorul", personality: .communityLeader, difficulty: .medium),
                RegionalOpponent(name: "Maria Sărbătorilor", personality: .festivalSpirit, difficulty: .hard),
                RegionalOpponent(name: "Ion Secerișul", personality: .harvestMaster, difficulty: .expert)
            ],
            culturalChallenges: [
                CulturalChallenge(
                    type: .communitySpirit,
                    description: "Play with the joy of Banat harvest festivals",
                    requirement: "Maintain positive cultural authenticity throughout the game",
                    bonus: 80
                )
            ],
            rewards: RegionalTournamentRewards(
                culturalSymbols: [.banatWheat, .harvestCrown],
                achievementPoints: 150,
                folkloreStories: ["The Great Harvest Game", "Festival of Strategy"],
                unlocksRegion: .banat
            ),
            folklore: RegionalFolklore(
                openingStory: "During the golden harvest of Banat, when communities gathered to celebrate abundance...",
                victoryTale: "Your spirited play brings joy to the festival, like the best harvest celebrations.",
                traditionExplanation: "Banat strategy is social and adaptive, reflecting the region's diverse cultural heritage."
            )
        )
    }
    
    private func createDobrudjaTournament() -> RomanianRegionalTournament {
        return RomanianRegionalTournament(
            id: "dobrudja_classic",
            region: .dobrudja,
            displayName: "Clasicul Dobrogei",
            englishName: "Dobrudja Classic",
            culturalTheme: RegionalCulturalTheme(
                name: "Coastal Heritage",
                folklore: "Strategic games by the Danube Delta and Black Sea",
                traditionalColors: ["#1E90FF", "#2E8B57", "#DAA520"], // Sea Blue, Delta Green, Coastal Gold
                folkPattern: .danubeWave
            ),
            difficulty: .advanced,
            unlockRequirements: RegionalUnlockRequirements(
                requiredRegions: [.wallachia, .transilvania, .moldova, .banat],
                minimumAchievements: 15,
                culturalKnowledgeLevel: 4
            ),
            opponents: [
                RegionalOpponent(name: "Pescaru' Gheorghe", personality: .fluidAdaptation, difficulty: .hard),
                RegionalOpponent(name: "Elena Deltaică", personality: .naturalFlow, difficulty: .expert),
                RegionalOpponent(name: "Căpitanul Dunării", personality: .riverMaster, difficulty: .expert)
            ],
            culturalChallenges: [
                CulturalChallenge(
                    type: .fluidAdaptation,
                    description: "Adapt like the Danube Delta waters",
                    requirement: "Show strategic flexibility and adaptability",
                    bonus: 100
                )
            ],
            rewards: RegionalTournamentRewards(
                culturalSymbols: [.danubeWave, .blackSeaPearl],
                achievementPoints: 300,
                folkloreStories: ["The Fisherman's Strategy", "Songs of the Delta"],
                unlocksRegion: .dobrudja
            ),
            folklore: RegionalFolklore(
                openingStory: "Where the mighty Danube meets the Black Sea, ancient strategies flow like river currents...",
                victoryTale: "Your strategic mastery flows like the great river, connecting all Romanian lands.",
                traditionExplanation: "Dobrudja strategy is fluid and adaptable, like the ever-changing delta waters."
            )
        )
    }
    
    // MARK: - Regional Tournament Management
    
    func enterRegionalTournament(_ tournament: RomanianRegionalTournament) async throws {
        logger.info("Entering regional tournament: \(tournament.displayName)")
        
        // Check unlock requirements
        guard canEnterRegionalTournament(tournament) else {
            throw TournamentError.arenaRequirementNotMet
        }
        
        currentRegionalTournament = tournament
        
        // Track achievement
        // achievementManager?.trackGameEvent(type: .regionalTournamentEntered, value: 1)
        
        logger.info("Successfully entered regional tournament: \(tournament.displayName)")
    }
    
    func canEnterRegionalTournament(_ tournament: RomanianRegionalTournament) -> Bool {
        // Check required regions are unlocked
        for requiredRegion in tournament.unlockRequirements.requiredRegions {
            if !unlockedRegions.contains(requiredRegion) {
                return false
            }
        }
        
        // Check minimum achievements
        let currentAchievements = playerTournamentProfile?.tournamentsWon ?? 0
        if currentAchievements < tournament.unlockRequirements.minimumAchievements {
            return false
        }
        
        // Check cultural knowledge level
        let culturalLevel = playerTournamentProfile?.culturalKnowledgeLevel ?? 0
        if culturalLevel < tournament.unlockRequirements.culturalKnowledgeLevel {
            return false
        }
        
        return true
    }
    
    func completeRegionalMatch(_ opponent: RegionalOpponent, playerWon: Bool, culturalChallengeCompleted: Bool) async {
        logger.info("Completed regional match against \(opponent.name), victory: \(playerWon)")
        
        if playerWon {
            playerRegionalProgress.matchesWon += 1
            
            if culturalChallengeCompleted {
                playerRegionalProgress.culturalChallengesCompleted += 1
                logger.info("Cultural challenge completed!")
            }
        } else {
            playerRegionalProgress.matchesLost += 1
        }
        
        // Check if tournament is complete
        if let tournament = currentRegionalTournament {
            await checkRegionalTournamentCompletion(tournament)
        }
    }
    
    private func checkRegionalTournamentCompletion(_ tournament: RomanianRegionalTournament) async {
        let victories = playerRegionalProgress.matchesWon
        let totalOpponents = tournament.opponents.count
        
        if victories >= (totalOpponents / 2) + 1 { // Majority wins
            await completeRegionalTournament(tournament, with: .victory)
        } else if (playerRegionalProgress.matchesWon + playerRegionalProgress.matchesLost) >= totalOpponents {
            await completeRegionalTournament(tournament, with: .defeat)
        }
    }
    
    private func completeRegionalTournament(_ tournament: RomanianRegionalTournament, with result: RegionalTournamentResult) async {
        logger.info("Regional tournament completed with result: \(String(describing: result))")
        
        if result == .victory {
            // Award rewards
            await awardRegionalTournamentRewards(tournament.rewards)
            
            // Unlock region if applicable
            if let regionToUnlock = tournament.rewards.unlocksRegion {
                await unlockRegion(regionToUnlock)
            }
            
            // Track achievement
            playerRegionalProgress.tournamentsWon += 1
            
            // Trigger regional celebration
            NotificationCenter.default.post(
                name: .regionalTournamentVictory,
                object: RegionalTournamentVictoryNotification(tournament: tournament, rewards: tournament.rewards)
            )
        } else {
            playerRegionalProgress.tournamentsLost += 1
        }
        
        // Reset current tournament
        currentRegionalTournament = nil
        
        // Reset match progress for next tournament
        playerRegionalProgress.matchesWon = 0
        playerRegionalProgress.matchesLost = 0
    }
    
    func unlockRegion(_ region: TournamentRegion) async {
        logger.info("Unlocking Romanian region: \(String(describing: region))")
        
        unlockedRegions.insert(region)
        
        // Create regional unlock achievement
        let _ = createRegionalUnlockAchievement(for: region)
        
        // Track regional unlock
        // achievementManager?.unlockAchievement(regionAchievement)
        
        logger.info("Region unlocked: \(region.displayName)")
    }
    
    private func awardRegionalTournamentRewards(_ rewards: RegionalTournamentRewards) async {
        logger.info("Awarding regional tournament rewards")
        
        // Add cultural symbols to collection
        for symbol in rewards.culturalSymbols {
            culturalRewards.append(CulturalReward(
                id: UUID().uuidString,
                type: .culturalBadge,
                title: symbol.rawValue,
                romanianTitle: symbol.rawValue,
                description: "Regional symbol for \(symbol.rawValue)",
                culturalSignificance: "Traditional Romanian symbol",
                rarity: .common,
                visualEffects: [],
                educationalContent: nil
            ))
        }
        
        // Add achievement points
        playerRegionalProgress.totalAchievementPoints += rewards.achievementPoints
        
        // Unlock folklore stories
        for storyTitle in rewards.folkloreStories {
            culturalRewards.append(CulturalReward(
                id: UUID().uuidString,
                type: .culturalStory,
                title: storyTitle,
                romanianTitle: storyTitle,
                description: "Traditional Romanian folklore story",
                culturalSignificance: "Romanian cultural heritage",
                rarity: .rare,
                visualEffects: [],
                educationalContent: storyTitle
            ))
        }
    }
    
    private func createRegionalUnlockAchievement(for region: TournamentRegion) -> RegionalAchievement {
        return RegionalAchievement(
            id: UUID().uuidString,
            region: region,
            title: "Master of \(region.displayName)",
            description: "Unlocked the \(region.displayName) region through tournament victory",
            points: 100,
            culturalSymbol: getRegionalSymbol(for: region)
        )
    }
    
    private func getRegionalSymbol(for region: TournamentRegion) -> TournamentCardSymbol {
        switch region {
        case .transilvania: return .carpathianCross
        case .moldova: return .moldavianScroll
        case .wallachia: return .wallachianEagle
        case .banat: return .banatWheat
        case .dobrudja: return .danubeWave
        }
    }
    
    // MARK: - Arena Championship System
    
    /// Create arena-specific championship tournaments
    func createArenaChampionship(for arena: RomanianArena) async throws -> ArenaChampionship {
        let championship = ArenaChampionship(
            id: "championship_\(arena.rawValue)_\(Int(Date().timeIntervalSince1970))",
            arena: arena,
            title: "Campionatul \(arena.displayName)",
            description: arena.culturalDescription,
            minParticipants: arena.championshipMinParticipants,
            maxParticipants: arena.championshipMaxParticipants,
            entryFee: arena.championshipEntryFee,
            prizePool: arena.championshipPrizePool,
            culturalPrizes: arena.championshipCulturalPrizes,
            registrationStart: Date(),
            registrationEnd: Date().addingTimeInterval(arena.championshipRegistrationPeriod),
            championshipStart: Date().addingTimeInterval(arena.championshipRegistrationPeriod + 3600),
            status: .registration
        )
        
        currentArenaChampionship = championship
        
        // Save to CloudKit
        try await saveArenaChampionshipToCloudKit(championship)
        
        logger.info("Created arena championship for \(arena.displayName)")
        
        return championship
    }
    
    // MARK: - Tournament Progression & Rewards
    
    /// Process tournament match result and update progression
    func processMatchResult(_ result: TournamentMatchResult) async throws {
        guard let tournament = currentTournament else {
            throw TournamentError.noActiveTournament
        }
        
        // Update tournament bracket
        var updatedTournament = tournament
        try updatedTournament.updateBracketWithResult(result)
        
        // Update player tournament profile
        await updatePlayerTournamentStats(result: result)
        
        // Check if tournament is complete
        if updatedTournament.isComplete {
            await completeTournament(updatedTournament)
        } else {
            // Update tournament in CloudKit
            try await updateTournamentInCloudKit(updatedTournament)
            currentTournament = updatedTournament
        }
        
        logger.info("Processed tournament match result: \(result.winnerID) defeated \(result.loserID)")
    }
    
    private func completeTournament(_ tournament: RomanianTournament) async {
        // Generate final results and rewards
        let completedTournament = CompletedTournament(
            originalTournament: tournament,
            finalStandings: tournament.bracket?.finalStandings ?? [],
            culturalMomentsGenerated: tournament.totalCulturalMoments,
            educationalContentEngagement: tournament.educationalEngagementScore,
            completedAt: Date()
        )
        
        // Add to tournament history
        tournamentHistory.insert(completedTournament, at: 0)
        
        // Award prizes and cultural achievements
        await awardTournamentRewards(completedTournament)
        
        // Clear current tournament
        currentTournament = nil
        
        // Remove from active tournaments
        activeTournaments.removeAll { $0.id == tournament.id }
        
        logger.info("Completed tournament: \(tournament.culturalTheme.romanianName)")
    }
    
    // MARK: - Cultural Education Integration
    
    /// Generate educational content based on tournament theme
    private func generateEducationalContent(for theme: TournamentCulturalTheme) -> [EducationalContentItem] {
        switch theme {
        case .transylvanianTraditions:
            return [
                EducationalContentItem(
                    id: "transylvania_history",
                    title: "History of Transylvanian Card Games",
                    content: "Discover how Septica evolved in the Carpathian Mountains, influenced by Saxon, Hungarian, and Romanian traditions.",
                    culturalSignificance: "Transylvania's multicultural heritage created unique card game variations that preserve centuries of shared traditions.",
                    interactiveElements: ["mountain-village-map", "historical-timeline", "folk-music-samples"]
                ),
                EducationalContentItem(
                    id: "transylvania_folklore",
                    title: "Transylvanian Folk Tales and Card Wisdom",
                    content: "Learn about the legendary card players of Brașov and Sibiu, whose strategic wisdom became part of regional folklore.",
                    culturalSignificance: "These stories teach values of patience, wisdom, and community that remain central to Romanian culture.",
                    interactiveElements: ["folklore-audio", "character-gallery", "moral-lessons"]
                )
            ]
            
        case .moldavianHeritage:
            return [
                EducationalContentItem(
                    id: "moldavia_traditions",
                    title: "Moldavian Card Game Rituals",
                    content: "Explore the ceremonial aspects of card playing in Moldavian villages, where games marked important life events.",
                    culturalSignificance: "Card games served as social bonding activities during harvest festivals and winter celebrations.",
                    interactiveElements: ["seasonal-calendar", "ritual-explanations", "celebration-music"]
                ),
                EducationalContentItem(
                    id: "moldavia_music",
                    title: "Moldavian Folk Music and Card Rhythms",
                    content: "Learn how the timing of Moldavian folk dances influences the pace and rhythm of traditional card games.",
                    culturalSignificance: "Music and games share common cultural roots, both preserving the spirit of Moldavian community life.",
                    interactiveElements: ["rhythm-exercises", "dance-demonstrations", "music-theory"]
                )
            ]
            
        case .wallachianWisdom:
            return [
                EducationalContentItem(
                    id: "wallachia_strategy",
                    title: "Wallachian Strategic Thinking",
                    content: "Discover the analytical approach to card games developed in Wallachia's merchant and scholarly traditions.",
                    culturalSignificance: "Wallachia's position as a trade crossroads fostered strategic thinking and cultural exchange.",
                    interactiveElements: ["strategy-puzzles", "trade-route-maps", "merchant-stories"]
                )
            ]
            
        case .dobrudjanSea:
            return [
                EducationalContentItem(
                    id: "dobrudja_maritime",
                    title: "Maritime Card Traditions of Dobrudja",
                    content: "Learn how Black Sea sailors and fishermen adapted card games for life on ships and in coastal villages.",
                    culturalSignificance: "Maritime communities developed unique game variations suited to their seafaring lifestyle.",
                    interactiveElements: ["ship-simulations", "coastal-maps", "sailor-songs"]
                )
            ]
        }
    }
    
    /// Generate folk music playlist for tournament theme
    private func generateFolkMusicPlaylist(for theme: TournamentCulturalTheme) -> [FolkMusicTrack] {
        switch theme {
        case .transylvanianTraditions:
            return [
                FolkMusicTrack(id: "hora_brasov", title: "Hora de la Brașov", region: "Transylvania", culturalContext: "Traditional circle dance from Brașov region"),
                FolkMusicTrack(id: "batuta_sibiu", title: "Bătuta din Sibiu", region: "Transylvania", culturalContext: "Energetic folk dance from Sibiu area"),
                FolkMusicTrack(id: "sarba_tara_fagarasului", title: "Sârba Țării Făgărașului", region: "Transylvania", culturalContext: "Mountain dance from Făgăraș region")
            ]
            
        case .moldavianHeritage:
            return [
                FolkMusicTrack(id: "hora_moldovei", title: "Hora Moldovei", region: "Moldova", culturalContext: "Classical Moldavian hora celebrating regional identity"),
                FolkMusicTrack(id: "jocul_de_la_iasi", title: "Jocul de la Iași", region: "Moldova", culturalContext: "Traditional dance from the cultural capital of Moldova"),
                FolkMusicTrack(id: "cantecul_codrilor", title: "Cântecul Codrilor", region: "Moldova", culturalContext: "Song of the forests, celebrating Moldova's natural beauty")
            ]
            
        case .wallachianWisdom:
            return [
                FolkMusicTrack(id: "calusa_bucuresti", title: "Căluș de la București", region: "Wallachia", culturalContext: "Ritual dance from Bucharest tradition"),
                FolkMusicTrack(id: "brau_oltenesc", title: "Brâu Oltenesc", region: "Wallachia", culturalContext: "Belt dance from Oltenia region"),
                FolkMusicTrack(id: "hora_mare", title: "Hora Mare", region: "Wallachia", culturalContext: "Great hora dance celebrating unity")
            ]
            
        case .dobrudjanSea:
            return [
                FolkMusicTrack(id: "joc_dobrogean", title: "Joc Dobrogean", region: "Dobrudja", culturalContext: "Traditional dance from Dobrudja region"),
                FolkMusicTrack(id: "cantec_de_mare", title: "Cântec de Mare", region: "Dobrudja", culturalContext: "Sea song from Black Sea coastal communities"),
                FolkMusicTrack(id: "hora_pescarilor", title: "Hora Pescarilor", region: "Dobrudja", culturalContext: "Fishermen's hora from Danube Delta")
            ]
        }
    }
}

// MARK: - Supporting Extensions

extension RomanianTournamentManager {
    
    private func generateAvailableTournamentTypes() async -> [TournamentType] {
        guard let profile = playerTournamentProfile else {
            return [.quickMatch, .romanianVillageChampionship]
        }
        
        var types: [TournamentType] = [.quickMatch, .romanianVillageChampionship]
        
        // Unlock tournament types based on arena progression
        if profile.currentArena.rawValue >= 3 {
            types.append(.folkFestivalTournament)
        }
        
        if profile.currentArena.rawValue >= 6 {
            types.append(.culturalHeritageChampionship)
        }
        
        if profile.currentArena.rawValue >= 9 {
            types.append(.grandRomanianMasters)
        }
        
        return types
    }
    
    private func calculateInitialTournamentRating(from profile: CloudKitPlayerProfile) -> Int {
        let baseRating = 1000
        let trophyBonus = profile.trophies / 10
        let experienceBonus = min(profile.totalGamesPlayed * 2, 200)
        let culturalBonus = Int(profile.heritageEngagementLevel * 100)
        
        return baseRating + trophyBonus + experienceBonus + culturalBonus
    }
    
    private func createNewTournamentProfile() async {
        playerTournamentProfile = TournamentPlayerProfile(
            playerID: "new_player_\(UUID().uuidString)",
            displayName: "New Player",
            currentArena: .sateImarica,
            tournamentRating: 1000,
            tournamentsPlayed: 0,
            tournamentsWon: 0,
            culturalKnowledgeLevel: 1,
            preferredTournamentTypes: [.quickMatch, .romanianVillageChampionship],
            seasonalAchievements: [],
            folkMusicPreferences: [],
            culturalMilestones: []
        )
    }
    
    // CloudKit operations (placeholder implementations)
    private func loadActiveTournaments() async throws -> [RomanianTournament] {
        // Implementation would load from CloudKit
        return []
    }
    
    private func saveTournamentToCloudKit(_ tournament: RomanianTournament) async throws {
        // Implementation would save to CloudKit
    }
    
    private func updateTournamentInCloudKit(_ tournament: RomanianTournament) async throws {
        // Implementation would update in CloudKit
    }
    
    private func saveArenaChampionshipToCloudKit(_ championship: ArenaChampionship) async throws {
        // Implementation would save to CloudKit
    }
    
    private func validateTournamentEntry(tournament: RomanianTournament, player: TournamentPlayerProfile) throws {
        // Validate arena level requirements
        if tournament.entryRequirements.minimumArena.rawValue > player.currentArena.rawValue {
            throw TournamentError.arenaRequirementNotMet
        }
        
        // Validate cultural knowledge level
        if tournament.entryRequirements.minimumCulturalLevel > player.culturalKnowledgeLevel {
            throw TournamentError.culturalLevelRequirementNotMet
        }
        
        // Check if tournament is full
        if tournament.participants.count >= tournament.maxParticipants {
            throw TournamentError.tournamentFull
        }
    }
    
    private func generateRomanianCulturalBracket(participants: [TournamentParticipant]) -> TournamentBracket {
        // Implementation would generate culturally-themed tournament bracket
        return TournamentBracket(participants: participants, culturalSeed: Date().timeIntervalSince1970)
    }
    
    private func updatePlayerTournamentStats(result: TournamentMatchResult) async {
        guard var profile = playerTournamentProfile else { return }
        
        if result.winnerID == profile.playerID {
            // Player won - increase rating
            profile.tournamentRating += 25
            profile.tournamentsWon += 1
        } else {
            // Player lost - decrease rating slightly
            profile.tournamentRating = max(800, profile.tournamentRating - 15)
        }
        
        profile.tournamentsPlayed += 1
        playerTournamentProfile = profile
    }
    
    private func awardTournamentRewards(_ tournament: CompletedTournament) async {
        // Implementation would award cultural prizes and achievements
        logger.info("Awarded tournament rewards for \(tournament.originalTournament.culturalTheme.romanianName)")
    }
    
    private func generateCulturalRewards(for type: TournamentType, theme: TournamentCulturalTheme) -> [CulturalReward] {
        // Implementation would generate theme-appropriate rewards
        return []
    }
    
    private func createFolkFestivalTournaments() async {
        // Implementation would create summer folk festival tournaments
    }
    
    private func createWinterHeritageTournaments() async {
        // Implementation would create winter heritage tournaments
    }
}

// MARK: - Sprint 3 Regional Tournament Data Structures

// MARK: - Romanian Regions

enum TournamentRegion: String, CaseIterable {
    case transilvania = "transilvania"
    case moldova = "moldova" 
    case wallachia = "wallachia"
    case banat = "banat"
    case dobrudja = "dobrudja"
    
    var displayName: String {
        switch self {
        case .transilvania: return "Transilvania"
        case .moldova: return "Moldova"
        case .wallachia: return "Țara Românească"
        case .banat: return "Banat"
        case .dobrudja: return "Dobrogea"
        }
    }
}

// MARK: - Regional Tournament Structures

struct RomanianRegionalTournament {
    let id: String
    let region: TournamentRegion
    let displayName: String
    let englishName: String
    let culturalTheme: RegionalCulturalTheme
    let difficulty: TournamentDifficulty
    let unlockRequirements: RegionalUnlockRequirements
    let opponents: [RegionalOpponent]
    let culturalChallenges: [CulturalChallenge]
    let rewards: RegionalTournamentRewards
    let folklore: RegionalFolklore
}

struct RegionalCulturalTheme {
    let name: String
    let folklore: String
    let traditionalColors: [String] // Hex color codes
    let folkPattern: FolkPattern
}

struct RegionalUnlockRequirements {
    let requiredRegions: [TournamentRegion]
    let minimumAchievements: Int
    let culturalKnowledgeLevel: Int
}

struct RegionalOpponent {
    let name: String
    let personality: RomanianAIPersonality
    let difficulty: AIDifficulty
}

struct CulturalChallenge {
    let type: CulturalChallengeType
    let description: String
    let requirement: String
    let bonus: Int
}

enum CulturalChallengeType {
    case traditionalStrategy
    case scholarlyWisdom
    case royalBoldness
    case communitySpirit
    case fluidAdaptation
}

struct RegionalTournamentRewards {
    let culturalSymbols: [TournamentCardSymbol]
    let achievementPoints: Int
    let folkloreStories: [String]
    let unlocksRegion: TournamentRegion?
}

struct RegionalFolklore {
    let openingStory: String
    let victoryTale: String
    let traditionExplanation: String
}

struct RegionalTournamentProgress {
    var tournamentsWon: Int = 0
    var tournamentsLost: Int = 0
    var matchesWon: Int = 0
    var matchesLost: Int = 0
    var culturalChallengesCompleted: Int = 0
    var totalAchievementPoints: Int = 0
}

enum RegionalTournamentResult {
    case victory
    case defeat
}

struct RegionalAchievement {
    let id: String
    let region: TournamentRegion
    let title: String
    let description: String
    let points: Int
    let culturalSymbol: TournamentCardSymbol
}

// CulturalReward and CulturalRewardType are now defined in TournamentDataModels.swift

// MARK: - Romanian Card Symbols

enum TournamentCardSymbol: String, CaseIterable {
    case carpathianCross = "carpathian_cross"
    case moldavianTradition = "moldavian_tradition"
    case moldavianScroll = "moldavian_scroll"
    case scholarSeal = "scholar_seal"
    case wallachianEagle = "wallachian_eagle"
    case courtScepter = "court_scepter"
    case banatWheat = "banat_wheat"
    case harvestCrown = "harvest_crown"
    case danubeWave = "danube_wave"
    case blackSeaPearl = "black_sea_pearl"
}

// MARK: - Folk Patterns

enum FolkPattern: String, CaseIterable {
    case carpathianMotif = "carpathian_motif"
    case moldavianScroll = "moldavian_scroll"
    case wallachianCrown = "wallachian_crown"
    case banatWheat = "banat_wheat"
    case danubeWave = "danube_wave"
}

// MARK: - AI Personalities

enum RomanianAIPersonality: String, CaseIterable {
    case wiseSage = "wise_sage"
    case boldWarrior = "bold_warrior"
    case patientScholar = "patient_scholar"
    case craftyCunning = "crafty_cunning"
    case mountainHunter = "mountain_hunter"
    case scholarlyWisdom = "scholarly_wisdom"
    case royalStrategist = "royal_strategist"
    case communityLeader = "community_leader"
    case festivalSpirit = "festival_spirit"
    case harvestMaster = "harvest_master"
    case fluidAdaptation = "fluid_adaptation"
    case naturalFlow = "natural_flow"
    case riverMaster = "river_master"
    
    var displayName: String {
        switch self {
        case .wiseSage: return "Înțeleptul Satului"
        case .boldWarrior: return "Războinicul Curajos"
        case .patientScholar: return "Învățatul Răbdător"
        case .craftyCunning: return "Vicleanul Isteț"
        case .mountainHunter: return "Vânătorul Munților"
        case .scholarlyWisdom: return "Înțelepciunea Monastirilor"
        case .royalStrategist: return "Strategul Curții"
        case .communityLeader: return "Liderul Comunității"
        case .festivalSpirit: return "Spiritul Sărbătorii"
        case .harvestMaster: return "Maestrul Secerișului"
        case .fluidAdaptation: return "Adaptarea Fluvială"
        case .naturalFlow: return "Curgerea Naturală"
        case .riverMaster: return "Maestrul Râului"
        }
    }
}

// MARK: - Tournament Difficulties

enum TournamentDifficulty {
    case beginner
    case intermediate
    case advanced
    case expert
}

// MARK: - Tournament Victory Notification

struct RegionalTournamentVictoryNotification {
    let tournament: RomanianRegionalTournament
    let rewards: RegionalTournamentRewards
}

// MARK: - Notification Names Extension

extension Notification.Name {
    static let regionalTournamentVictory = Notification.Name("regionalTournamentVictory")
}
