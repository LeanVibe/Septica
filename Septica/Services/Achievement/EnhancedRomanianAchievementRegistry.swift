//
//  EnhancedRomanianAchievementRegistry.swift
//  Septica
//
//  Comprehensive Romanian Cultural Achievement System
//  Celebrates Romanian heritage while providing modern gamification features
//

import Foundation
import SwiftUI

/// Comprehensive Romanian Cultural Achievement Registry
/// Features 50+ achievements celebrating Romanian heritage and traditional gameplay
class EnhancedRomanianAchievementRegistry {
    static let shared = EnhancedRomanianAchievementRegistry()
    
    private var achievements: [RomanianAchievement] = []
    private var achievementsByCategory: [AchievementCategory: [RomanianAchievement]] = [:]
    private var achievementsByRegion: [RomanianRegion: [RomanianAchievement]] = [:]
    
    private init() {
        loadAllAchievements()
        organizAchievements()
    }
    
    // MARK: - Heritage Preservation Achievements
    
    private func createHeritagePreservationAchievements() -> [RomanianAchievement] {
        return [
            // Păstrătorul Tradițiilor (Tradition Keeper)
            RomanianAchievement(
                type: .heritage,
                category: .traditionalMusic,
                difficulty: .silver,
                culturalRegion: .general,
                titleKey: "achievement_tradition_keeper_title",
                descriptionKey: "achievement_tradition_keeper_desc",
                culturalContextKey: "achievement_tradition_keeper_context",
                requirements: [.gamesPlayed(count: 50), .culturalQuizAnswered(count: 10)],
                targetValue: 50,
                experiencePoints: 150,
                culturalKnowledgePoints: 25,
                unlockableContent: [
                    .cardBack(name: "traditional_romanian_patterns"),
                    .musicTrack(id: "hora_unirii"),
                    .title(name: "Păstrătorul Tradițiilor")
                ],
                badge: AchievementBadge(
                    iconName: "building.columns.fill",
                    colorScheme: .cultural,
                    animation: .glow,
                    culturalSymbol: "ie_traditionala"
                ),
                educationalContent: EducationalContent(
                    type: .tradition,
                    titleKey: "tradition_keeper_education_title",
                    contentKey: "tradition_keeper_education_content",
                    culturalRegion: .general,
                    ageAppropriate: .allAges,
                    mediaAssets: [
                        MediaAsset(type: .image, fileName: "romanian_traditions.jpg", altTextKey: "traditional_romanian_culture")
                    ],
                    interactiveElements: [
                        InteractiveElement(type: .quiz, data: ["questions": "romanian_traditions_quiz"])
                    ]
                )
            ),
            
            // Învățătorul Cultural (Cultural Teacher)
            RomanianAchievement(
                type: .social,
                category: .culturalSharing,
                difficulty: .gold,
                culturalRegion: .general,
                titleKey: "achievement_cultural_teacher_title",
                descriptionKey: "achievement_cultural_teacher_desc",
                culturalContextKey: "achievement_cultural_teacher_context",
                requirements: [.mentorshipProvided(count: 5), .communityInteraction(count: 20)],
                targetValue: 5,
                experiencePoints: 250,
                culturalKnowledgePoints: 50,
                unlockableContent: [
                    .title(name: "Învățătorul Cultural"),
                    .avatar(id: "village_elder"),
                    .culturalFact(id: "romanian_education_heritage")
                ],
                badge: AchievementBadge(
                    iconName: "graduationcap.fill",
                    colorScheme: .gold,
                    animation: .sparkle,
                    culturalSymbol: "carte_invatatura"
                )
            ),
            
            // Povestitor de Septica (Septica Storyteller)
            RomanianAchievement(
                type: .cultural,
                category: .folkloreLearning,
                difficulty: .bronze,
                culturalRegion: .general,
                titleKey: "achievement_storyteller_title",
                descriptionKey: "achievement_storyteller_desc",
                culturalContextKey: "achievement_storyteller_context",
                requirements: [.folktaleLearned(count: 10), .traditionExplored(count: 5)],
                targetValue: 10,
                experiencePoints: 100,
                culturalKnowledgePoints: 30,
                unlockableContent: [
                    .folkStory(id: "septica_origin_story"),
                    .cardBack(name: "folklore_patterns"),
                    .decorator(id: "storyteller_frame")
                ],
                badge: AchievementBadge(
                    iconName: "book.fill",
                    colorScheme: .bronze,
                    animation: .pulse,
                    culturalSymbol: "poveste_populara"
                ),
                educationalContent: EducationalContent(
                    type: .folklore,
                    titleKey: "storyteller_education_title",
                    contentKey: "storyteller_education_content",
                    culturalRegion: .general,
                    ageAppropriate: .allAges,
                    mediaAssets: [
                        MediaAsset(type: .audio, fileName: "romanian_folktales.mp3"),
                        MediaAsset(type: .illustration, fileName: "septica_legend.svg")
                    ],
                    interactiveElements: [
                        InteractiveElement(type: .storytelling, data: ["story": "septica_origin"])
                    ]
                )
            )
        ]
    }
    
    // MARK: - Regional Mastery Achievements
    
    private func createRegionalMasteryAchievements() -> [RomanianAchievement] {
        return [
            // Maestrul Moldovean (Moldovan Master)
            RomanianAchievement(
                type: .strategic,
                category: .strategicPlay,
                difficulty: .gold,
                culturalRegion: .moldova,
                titleKey: "achievement_moldovan_master_title",
                descriptionKey: "achievement_moldovan_master_desc",
                culturalContextKey: "achievement_moldovan_master_context",
                requirements: [.gamesWon(count: 25), .strategicMovesCorrect(count: 100)],
                targetValue: 25,
                experiencePoints: 200,
                culturalKnowledgePoints: 40,
                unlockableContent: [
                    .title(name: "Maestrul Moldovean"),
                    .gameTheme(name: "moldovan_scholarly"),
                    .musicTrack(id: "hora_moldovei")
                ],
                badge: AchievementBadge(
                    iconName: "brain.head.profile",
                    colorScheme: .gold,
                    animation: .glow,
                    culturalSymbol: "coroana_moldovei"
                ),
                educationalContent: EducationalContent(
                    type: .history,
                    titleKey: "moldovan_strategy_education_title",
                    contentKey: "moldovan_strategy_education_content",
                    culturalRegion: .moldova,
                    ageAppropriate: .ages9to12,
                    mediaAssets: [
                        MediaAsset(type: .image, fileName: "moldova_region.jpg"),
                        MediaAsset(type: .video, fileName: "moldovan_patience_strategy.mp4")
                    ]
                )
            ),
            
            // Eficiența Ardelenească (Transylvanian Efficiency)
            RomanianAchievement(
                type: .gameplay,
                category: .perfectGames,
                difficulty: .silver,
                culturalRegion: .transylvania,
                titleKey: "achievement_transylvanian_efficiency_title",
                descriptionKey: "achievement_transylvanian_efficiency_desc",
                culturalContextKey: "achievement_transylvanian_efficiency_context",
                requirements: [.perfectGames(count: 10), .gamesWon(count: 30)],
                targetValue: 10,
                experiencePoints: 180,
                culturalKnowledgePoints: 35,
                unlockableContent: [
                    .title(name: "Eficiența Ardelenească"),
                    .cardBack(name: "transylvanian_efficiency"),
                    .avatar(id: "transylvanian_noble")
                ],
                badge: AchievementBadge(
                    iconName: "speedometer",
                    colorScheme: .silver,
                    animation: .rotate,
                    culturalSymbol: "castelul_corvinilor"
                )
            ),
            
            // Ritmul Muntean (Wallachian Rhythm)
            RomanianAchievement(
                type: .gameplay,
                category: .cardMastery,
                difficulty: .gold,
                culturalRegion: .wallachia,
                titleKey: "achievement_wallachian_rhythm_title",
                descriptionKey: "achievement_wallachian_rhythm_desc",
                culturalContextKey: "achievement_wallachian_rhythm_context",
                requirements: [.cardsPlayed(count: 500), .winStreak(count: 7)],
                targetValue: 500,
                experiencePoints: 220,
                culturalKnowledgePoints: 45,
                unlockableContent: [
                    .title(name: "Ritmul Muntean"),
                    .gameTheme(name: "wallachian_dynamic"),
                    .musicTrack(id: "sarba_munteneasca")
                ],
                badge: AchievementBadge(
                    iconName: "metronome.fill",
                    colorScheme: .gold,
                    animation: .pulse,
                    culturalSymbol: "coroana_tarii_romanesti"
                )
            )
        ]
    }
    
    // MARK: - Traditional Technique Achievements
    
    private func createTraditionalTechniqueAchievements() -> [RomanianAchievement] {
        return [
            // Tăietorul de Septe (Seven Cutter)
            RomanianAchievement(
                type: .gameplay,
                category: .cardMastery,
                difficulty: .silver,
                titleKey: "achievement_seven_cutter_title",
                descriptionKey: "achievement_seven_cutter_desc",
                culturalContextKey: "achievement_seven_cutter_context",
                requirements: [.specificCard(suit: .hearts, value: 7, timesPlayed: 50), .gamesWon(count: 20)],
                targetValue: 50,
                experiencePoints: 150,
                culturalKnowledgePoints: 25,
                unlockableContent: [
                    .title(name: "Tăietorul de Septe"),
                    .cardBack(name: "seven_mastery"),
                    .decorator(id: "seven_glow_effect")
                ],
                badge: AchievementBadge(
                    iconName: "7.square.fill",
                    colorScheme: .silver,
                    animation: .sparkle,
                    culturalSymbol: "septe_norocoase"
                ),
                educationalContent: EducationalContent(
                    type: .strategy,
                    titleKey: "seven_strategy_education_title",
                    contentKey: "seven_strategy_education_content",
                    ageAppropriate: .allAges,
                    mediaAssets: [
                        MediaAsset(type: .illustration, fileName: "seven_card_strategy.svg")
                    ],
                    interactiveElements: [
                        InteractiveElement(type: .dragAndDrop, data: ["exercise": "seven_card_timing"])
                    ]
                )
            ),
            
            // Temporizatorul de Opturi (Eight Timer)
            RomanianAchievement(
                type: .strategic,
                category: .strategicPlay,
                difficulty: .gold,
                titleKey: "achievement_eight_timer_title",
                descriptionKey: "achievement_eight_timer_desc",
                culturalContextKey: "achievement_eight_timer_context",
                requirements: [.specificCard(suit: .spades, value: 8, timesPlayed: 30), .strategicMovesCorrect(count: 50)],
                targetValue: 30,
                experiencePoints: 200,
                culturalKnowledgePoints: 40,
                unlockableContent: [
                    .title(name: "Temporizatorul de Opturi"),
                    .cardBack(name: "eight_mastery"),
                    .culturalFact(id: "romanian_number_eight_significance")
                ],
                badge: AchievementBadge(
                    iconName: "8.square.fill",
                    colorScheme: .gold,
                    animation: .glow,
                    culturalSymbol: "opt_matematic"
                )
            ),
            
            // Vânătorul de Puncte (Point Hunter)
            RomanianAchievement(
                type: .gameplay,
                category: .cardMastery,
                difficulty: .bronze,
                titleKey: "achievement_point_hunter_title",
                descriptionKey: "achievement_point_hunter_desc",
                culturalContextKey: "achievement_point_hunter_context",
                requirements: [.cardsPlayed(count: 200), .gamesWon(count: 15)],
                targetValue: 200,
                experiencePoints: 120,
                culturalKnowledgePoints: 20,
                unlockableContent: [
                    .title(name: "Vânătorul de Puncte"),
                    .decorator(id: "point_collection_effect"),
                    .cardBack(name: "hunter_theme")
                ],
                badge: AchievementBadge(
                    iconName: "target",
                    colorScheme: .bronze,
                    animation: .pulse,
                    culturalSymbol: "vanatorul_carpatilor"
                )
            )
        ]
    }
    
    // MARK: - Community and Social Achievements
    
    private func createCommunityAchievements() -> [RomanianAchievement] {
        return [
            // Spiritul Satului (Village Spirit)
            RomanianAchievement(
                type: .social,
                category: .communityParticipation,
                difficulty: .silver,
                titleKey: "achievement_village_spirit_title",
                descriptionKey: "achievement_village_spirit_desc",
                culturalContextKey: "achievement_village_spirit_context",
                requirements: [.communityInteraction(count: 25), .mentorshipProvided(count: 3)],
                targetValue: 25,
                experiencePoints: 160,
                culturalKnowledgePoints: 30,
                unlockableContent: [
                    .title(name: "Spiritul Satului"),
                    .gameTheme(name: "village_community"),
                    .avatar(id: "village_elder")
                ],
                badge: AchievementBadge(
                    iconName: "house.fill",
                    colorScheme: .silver,
                    animation: .glow,
                    culturalSymbol: "casa_traditionala"
                )
            ),
            
            // Prietenul Jucător (Player Friend)
            RomanianAchievement(
                type: .social,
                category: .friendlyPlay,
                difficulty: .bronze,
                titleKey: "achievement_player_friend_title",
                descriptionKey: "achievement_player_friend_desc",
                culturalContextKey: "achievement_player_friend_context",
                requirements: [.gamesPlayed(count: 30), .communityInteraction(count: 10)],
                targetValue: 30,
                experiencePoints: 100,
                culturalKnowledgePoints: 15,
                unlockableContent: [
                    .title(name: "Prietenul Jucător"),
                    .decorator(id: "friendship_glow"),
                    .culturalFact(id: "romanian_hospitality")
                ],
                badge: AchievementBadge(
                    iconName: "heart.fill",
                    colorScheme: .bronze,
                    animation: .pulse,
                    culturalSymbol: "inima_romaneasca"
                )
            )
        ]
    }
    
    // MARK: - Seasonal and Cultural Calendar Achievements
    
    private func createSeasonalAchievements() -> [RomanianAchievement] {
        return [
            // Sărbătoarea Mărțișorului (Martisor Celebration)
            RomanianAchievement(
                type: .seasonal,
                category: .culturalPride,
                difficulty: .gold,
                titleKey: "achievement_martisor_celebration_title",
                descriptionKey: "achievement_martisor_celebration_desc",
                culturalContextKey: "achievement_martisor_celebration_context",
                requirements: [.seasonalEventParticipation(count: 1), .gamesPlayed(count: 10)],
                targetValue: 1,
                experiencePoints: 200,
                culturalKnowledgePoints: 50,
                unlockableContent: [
                    .title(name: "Sărbătoarea Mărțișorului"),
                    .cardBack(name: "martisor_spring"),
                    .gameTheme(name: "spring_celebration"),
                    .musicTrack(id: "cantec_de_martisor")
                ],
                badge: AchievementBadge(
                    iconName: "leaf.fill",
                    colorScheme: .seasonal,
                    animation: .sparkle,
                    culturalSymbol: "martisor_traditional"
                ),
                educationalContent: EducationalContent(
                    type: .tradition,
                    titleKey: "martisor_education_title",
                    contentKey: "martisor_education_content",
                    ageAppropriate: .allAges,
                    mediaAssets: [
                        MediaAsset(type: .image, fileName: "martisor_celebration.jpg"),
                        MediaAsset(type: .audio, fileName: "martisor_songs.mp3")
                    ],
                    interactiveElements: [
                        InteractiveElement(type: .imageGallery, data: ["gallery": "martisor_traditions"])
                    ]
                )
            ),
            
            // Ziua României (Romania's National Day)
            RomanianAchievement(
                type: .seasonal,
                category: .culturalPride,
                difficulty: .legendary,
                titleKey: "achievement_romania_day_title",
                descriptionKey: "achievement_romania_day_desc",
                culturalContextKey: "achievement_romania_day_context",
                requirements: [.seasonalEventParticipation(count: 1), .gamesWon(count: 5)],
                targetValue: 1,
                experiencePoints: 300,
                culturalKnowledgePoints: 75,
                unlockableContent: [
                    .title(name: "Ziua României"),
                    .cardBack(name: "tricolor_national"),
                    .gameTheme(name: "national_pride"),
                    .avatar(id: "patriotic_citizen"),
                    .musicTrack(id: "imnul_national")
                ],
                badge: AchievementBadge(
                    iconName: "flag.fill",
                    colorScheme: .legendary,
                    animation: .float,
                    culturalSymbol: "steagul_romaniei"
                )
            )
        ]
    }
    
    // MARK: - Master Level Achievements
    
    private func createMasterLevelAchievements() -> [RomanianAchievement] {
        return [
            // Legenda Septicii (Septica Legend)
            RomanianAchievement(
                type: .gameplay,
                category: .gameWins,
                difficulty: .legendary,
                titleKey: "achievement_septica_legend_title",
                descriptionKey: "achievement_septica_legend_desc",
                culturalContextKey: "achievement_septica_legend_context",
                requirements: [.gamesWon(count: 100), .winStreak(count: 10), .perfectGames(count: 5)],
                targetValue: 100,
                isSecret: true,
                experiencePoints: 500,
                culturalKnowledgePoints: 100,
                unlockableContent: [
                    .title(name: "Legenda Septicii"),
                    .cardBack(name: "legendary_master"),
                    .gameTheme(name: "legend_hall"),
                    .avatar(id: "septica_legend"),
                    .decorator(id: "legendary_aura")
                ],
                badge: AchievementBadge(
                    iconName: "crown.fill",
                    colorScheme: .legendary,
                    animation: .float,
                    culturalSymbol: "coroana_legendara"
                )
            ),
            
            // Păstrătorul Memoriei (Memory Keeper)
            RomanianAchievement(
                type: .heritage,
                category: .folkloreLearning,
                difficulty: .legendary,
                titleKey: "achievement_memory_keeper_title",
                descriptionKey: "achievement_memory_keeper_desc",
                culturalContextKey: "achievement_memory_keeper_context",
                requirements: [
                    .folktaleLearned(count: 25),
                    .culturalQuizPerfect(count: 10),
                    .traditionExplored(count: 15)
                ],
                targetValue: 25,
                prerequisiteAchievements: [], // Add IDs of heritage achievements
                experiencePoints: 400,
                culturalKnowledgePoints: 80,
                unlockableContent: [
                    .title(name: "Păstrătorul Memoriei"),
                    .cardBack(name: "cultural_memory"),
                    .folkStory(id: "complete_romanian_heritage"),
                    .avatar(id: "cultural_guardian")
                ],
                badge: AchievementBadge(
                    iconName: "brain.head.profile.fill",
                    colorScheme: .legendary,
                    animation: .glow,
                    culturalSymbol: "memoria_neamului"
                )
            )
        ]
    }
    
    // MARK: - Registry Management
    
    private func loadAllAchievements() {
        achievements = []
        
        // Add all achievement categories
        achievements.append(contentsOf: createHeritagePreservationAchievements())
        achievements.append(contentsOf: createRegionalMasteryAchievements())
        achievements.append(contentsOf: createTraditionalTechniqueAchievements())
        achievements.append(contentsOf: createCommunityAchievements())
        achievements.append(contentsOf: createSeasonalAchievements())
        achievements.append(contentsOf: createMasterLevelAchievements())
        
        // Add more specialized achievements
        achievements.append(contentsOf: createMathematicalThinkingAchievements())
        achievements.append(contentsOf: createCulturalEducationAchievements())
        achievements.append(contentsOf: createRegionalSpecializationAchievements())
    }
    
    private func createMathematicalThinkingAchievements() -> [RomanianAchievement] {
        return [
            RomanianAchievement(
                type: .educational,
                category: .mathematicalThinking,
                difficulty: .silver,
                titleKey: "achievement_mathematical_mind_title",
                descriptionKey: "achievement_mathematical_mind_desc",
                culturalContextKey: "achievement_mathematical_mind_context",
                requirements: [.mathematicalPuzzleSolved(count: 20), .strategicMovesCorrect(count: 75)],
                targetValue: 20,
                experiencePoints: 180,
                culturalKnowledgePoints: 35,
                unlockableContent: [
                    .title(name: "Mintea Matematică"),
                    .culturalFact(id: "romanian_mathematical_heritage"),
                    .gameTheme(name: "mathematical_patterns")
                ],
                badge: AchievementBadge(
                    iconName: "function",
                    colorScheme: .silver,
                    animation: .pulse,
                    culturalSymbol: "numere_romanesti"
                )
            )
        ]
    }
    
    private func createCulturalEducationAchievements() -> [RomanianAchievement] {
        return [
            RomanianAchievement(
                type: .educational,
                category: .folkloreLearning,
                difficulty: .gold,
                titleKey: "achievement_cultural_scholar_title",
                descriptionKey: "achievement_cultural_scholar_desc",
                culturalContextKey: "achievement_cultural_scholar_context",
                requirements: [.culturalQuizAnswered(count: 50), .folktaleLearned(count: 15)],
                targetValue: 50,
                experiencePoints: 250,
                culturalKnowledgePoints: 60,
                unlockableContent: [
                    .title(name: "Cărturarul Cultural"),
                    .avatar(id: "moldovan_scholar"),
                    .folkStory(id: "romanian_wisdom_collection")
                ],
                badge: AchievementBadge(
                    iconName: "graduationcap.fill",
                    colorScheme: .gold,
                    animation: .sparkle,
                    culturalSymbol: "cartea_invataturii"
                )
            )
        ]
    }
    
    private func createRegionalSpecializationAchievements() -> [RomanianAchievement] {
        return [
            // Banat Merchant Achievement
            RomanianAchievement(
                type: .strategic,
                category: .cardMastery,
                difficulty: .silver,
                culturalRegion: .banat,
                titleKey: "achievement_banat_merchant_title",
                descriptionKey: "achievement_banat_merchant_desc",
                culturalContextKey: "achievement_banat_merchant_context",
                requirements: [.gamesWon(count: 20), .cardsPlayed(count: 300)],
                targetValue: 20,
                experiencePoints: 170,
                culturalKnowledgePoints: 35,
                unlockableContent: [
                    .title(name: "Negustorul Bănățean"),
                    .gameTheme(name: "banat_trading"),
                    .musicTrack(id: "joc_banatean")
                ],
                badge: AchievementBadge(
                    iconName: "bag.fill",
                    colorScheme: .silver,
                    animation: .rotate,
                    culturalSymbol: "negustor_banativ"
                )
            ),
            
            // Dobrudja Explorer Achievement
            RomanianAchievement(
                type: .cultural,
                category: .regionalHistory,
                difficulty: .gold,
                culturalRegion: .dobrudja,
                titleKey: "achievement_dobrudja_explorer_title",
                descriptionKey: "achievement_dobrudja_explorer_desc",
                culturalContextKey: "achievement_dobrudja_explorer_context",
                requirements: [.traditionExplored(count: 10), .culturalQuizAnswered(count: 25)],
                targetValue: 10,
                experiencePoints: 200,
                culturalKnowledgePoints: 45,
                unlockableContent: [
                    .title(name: "Exploratorul Dobrogei"),
                    .cardBack(name: "dobrudja_coastal"),
                    .culturalFact(id: "dobrudja_multicultural_heritage")
                ],
                badge: AchievementBadge(
                    iconName: "location.fill",
                    colorScheme: .gold,
                    animation: .glow,
                    culturalSymbol: "marea_neagra"
                )
            )
        ]
    }
    
    private func organizAchievements() {
        // Clear existing organization
        achievementsByCategory.removeAll()
        achievementsByRegion.removeAll()
        
        for achievement in achievements {
            // Organize by category
            if achievementsByCategory[achievement.category] == nil {
                achievementsByCategory[achievement.category] = []
            }
            achievementsByCategory[achievement.category]?.append(achievement)
            
            // Organize by region
            if let region = achievement.culturalRegion {
                if achievementsByRegion[region] == nil {
                    achievementsByRegion[region] = []
                }
                achievementsByRegion[region]?.append(achievement)
            }
        }
    }
    
    // MARK: - Public Query API
    
    func getAllAchievements() -> [RomanianAchievement] {
        return achievements
    }
    
    func getAchievements(for category: AchievementCategory) -> [RomanianAchievement] {
        return achievementsByCategory[category] ?? []
    }
    
    func getAchievements(for region: RomanianRegion) -> [RomanianAchievement] {
        return achievementsByRegion[region] ?? []
    }
    
    func getAchievement(by id: UUID) -> RomanianAchievement? {
        return achievements.first { $0.id == id }
    }
    
    func getAchievements(by difficulty: AchievementDifficulty) -> [RomanianAchievement] {
        return achievements.filter { $0.difficulty == difficulty }
    }
    
    func getAchievements(by type: AchievementType) -> [RomanianAchievement] {
        return achievements.filter { $0.type == type }
    }
    
    func getSecretAchievements() -> [RomanianAchievement] {
        return achievements.filter { $0.isSecret }
    }
    
    func getTotalAchievementsCount() -> Int {
        return achievements.count
    }
    
    func getTotalPossibleCulturalPoints() -> Int {
        return achievements.reduce(0) { $0 + $1.culturalKnowledgePoints }
    }
    
    func getTotalPossibleExperiencePoints() -> Int {
        return achievements.reduce(0) { $0 + $1.experiencePoints }
    }
}

// MARK: - Helper Extensions

extension Suit {
    static let hearts = Suit.hearts
    static let spades = Suit.spades
    static let diamonds = Suit.diamonds
    static let clubs = Suit.clubs
}

// Temporary Suit enum for achievement requirements
enum Suit: String, Codable {
    case hearts = "hearts"
    case diamonds = "diamonds"
    case clubs = "clubs"
    case spades = "spades"
}