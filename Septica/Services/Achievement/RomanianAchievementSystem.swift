//
//  RomanianAchievementSystem.swift
//  Septica
//
//  Meta-game progression system with Romanian cultural achievements
//  Celebrates mastery of traditional Septica strategies and cultural knowledge
//

import SwiftUI
import Foundation
import Combine

/// Romanian cultural achievement categories
enum RomanianAchievementCategory: String, CaseIterable {
    case cardMastery = "Măiestria Cărților"        // Card Mastery
    case traditionalPlay = "Jocul Tradițional"     // Traditional Play
    case culturalWisdom = "Înțelepciunea Culturală" // Cultural Wisdom
    case strategicThinking = "Gândirea Strategică"  // Strategic Thinking
    case communitySpirit = "Spiritul Comunității"  // Community Spirit
    case heritageKeeper = "Păstrător de Moștenire" // Heritage Keeper
    case gameExpertise = "Expertiza în Joc"        // Game Expertise
    case culturalAmbassador = "Ambasador Cultural" // Cultural Ambassador
    
    var icon: String {
        switch self {
        case .cardMastery: return "suit.spade.fill"
        case .traditionalPlay: return "figure.2.and.child.holdinghands"
        case .culturalWisdom: return "brain.head.profile"
        case .strategicThinking: return "lightbulb.fill"
        case .communitySpirit: return "heart.fill"
        case .heritageKeeper: return "building.columns.fill"
        case .gameExpertise: return "star.fill"
        case .culturalAmbassador: return "globe.europe.africa.fill"
        }
    }
    
    var culturalDescription: String {
        switch self {
        case .cardMastery:
            return "Stăpânește arta jocului de cărți cu îndemânarea unui meșter roman"
        case .traditionalPlay:
            return "Păstrează spiritul tradițional al jocului românesc"
        case .culturalWisdom:
            return "Dobândește înțelepciunea culturală transmisă din generație în generație"
        case .strategicThinking:
            return "Dezvoltă gândirea strategică specifică mentalității românești"
        case .communitySpirit:
            return "Cultivă spiritul de comunitate caracteristic satului românesc"
        case .heritageKeeper:
            return "Păstrează și transmite moștenirea culturală românească"
        case .gameExpertise:
            return "Atinge nivelul de expert în jocul de Septica"
        case .culturalAmbassador:
            return "Devine ambasador al culturii românești prin joc"
        }
    }
}

/// Achievement rarity levels with Romanian cultural significance
enum AchievementRarity: String, CaseIterable {
    case common = "Obișnuit"        // Common
    case uncommon = "Neobișnuit"    // Uncommon
    case rare = "Rar"               // Rare
    case epic = "Epic"              // Epic
    case legendary = "Legendar"     // Legendary
    case mythic = "Mitic"           // Mythic
    
    var color: Color {
        switch self {
        case .common: return .gray
        case .uncommon: return .green
        case .rare: return .blue
        case .epic: return .purple
        case .legendary: return .orange
        case .mythic: return .yellow
        }
    }
    
    var culturalValue: Int {
        switch self {
        case .common: return 10
        case .uncommon: return 25
        case .rare: return 50
        case .epic: return 100
        case .legendary: return 250
        case .mythic: return 500
        }
    }
}

/// Romanian cultural achievement with heritage significance
struct RomanianAchievement: Identifiable, Codable {
    let id: UUID
    let category: RomanianAchievementCategory
    let rarity: AchievementRarity
    let titleRomanian: String
    let titleEnglish: String
    let descriptionRomanian: String
    let descriptionEnglish: String
    let culturalStory: String
    let historicalContext: String
    let requirement: AchievementRequirement
    let reward: AchievementReward
    let culturalPoints: Int
    let unlockLevel: Int
    let isHidden: Bool
    
    var isUnlocked: Bool {
        AchievementManager.shared.isAchievementUnlocked(id)
    }
    
    var progress: Float {
        AchievementManager.shared.getAchievementProgress(id)
    }
    
    init(
        category: RomanianAchievementCategory,
        rarity: AchievementRarity,
        titleRomanian: String,
        titleEnglish: String,
        descriptionRomanian: String,
        descriptionEnglish: String,
        culturalStory: String,
        historicalContext: String,
        requirement: AchievementRequirement,
        reward: AchievementReward,
        unlockLevel: Int = 1,
        isHidden: Bool = false
    ) {
        self.id = UUID()
        self.category = category
        self.rarity = rarity
        self.titleRomanian = titleRomanian
        self.titleEnglish = titleEnglish
        self.descriptionRomanian = descriptionRomanian
        self.descriptionEnglish = descriptionEnglish
        self.culturalStory = culturalStory
        self.historicalContext = historicalContext
        self.requirement = requirement
        self.reward = reward
        self.culturalPoints = rarity.culturalValue
        self.unlockLevel = unlockLevel
        self.isHidden = isHidden
    }
}

/// Achievement requirements with cultural context
enum AchievementRequirement: Codable {
    case playGames(count: Int)
    case winGames(count: Int)
    case playSevenCards(count: Int)
    case playEightAtRightTime(count: Int)
    case capturePointCards(count: Int)
    case winWithoutLosingTricks(count: Int)
    case playConsecutiveGames(count: Int)
    case achieveWinStreak(count: Int)
    case completeGamesInTime(count: Int, seconds: Int)
    case learnCulturalFacts(count: Int)
    case masterDifficulty(difficulty: AIDifficulty, games: Int)
    case exhibitSportsmanship(count: Int)
    case teachNewPlayers(count: Int)
    case preserveCulturalTraditions(count: Int)
    
    var progressDescription: String {
        switch self {
        case .playGames(let count):
            return "Joacă \(count) jocuri"
        case .winGames(let count):
            return "Câștigă \(count) jocuri"
        case .playSevenCards(let count):
            return "Joacă \(count) cărți de șapte"
        case .playEightAtRightTime(let count):
            return "Joacă \(count) cărți de opt la momentul potrivit"
        case .capturePointCards(let count):
            return "Capturează \(count) cărți cu puncte"
        case .winWithoutLosingTricks(let count):
            return "Câștigă \(count) jocuri fără să pierzi levate"
        case .playConsecutiveGames(let count):
            return "Joacă \(count) jocuri consecutive"
        case .achieveWinStreak(let count):
            return "Obține o serie de \(count) victorii"
        case .completeGamesInTime(let count, let seconds):
            return "Completează \(count) jocuri în sub \(seconds) secunde"
        case .learnCulturalFacts(let count):
            return "Învață \(count) fapte culturale"
        case .masterDifficulty(let difficulty, let games):
            return "Stăpânește dificultatea \(difficulty.rawValue) în \(games) jocuri"
        case .exhibitSportsmanship(let count):
            return "Demonstrează sportivitate în \(count) jocuri"
        case .teachNewPlayers(let count):
            return "Învață \(count) jucători noi"
        case .preserveCulturalTraditions(let count):
            return "Păstrează \(count) tradiții culturale"
        }
    }
}

/// Achievement rewards with Romanian cultural value
enum AchievementReward: Codable {
    case culturalPoints(Int)
    case cardBack(String)
    case characterUnlock(RomanianCharacterType)
    case musicUnlock(String)
    case storyUnlock(String)
    case titleUnlock(String)
    case specialAnimation(String)
    case culturalInsight(String)
    case heritageContent(String)
    
    var displayName: String {
        switch self {
        case .culturalPoints(let points):
            return "\(points) Puncte Culturale"
        case .cardBack(let name):
            return "Verso de carte: \(name)"
        case .characterUnlock(let character):
            return "Personaj: \(character.rawValue)"
        case .musicUnlock(let track):
            return "Muzică: \(track)"
        case .storyUnlock(let story):
            return "Poveste: \(story)"
        case .titleUnlock(let title):
            return "Titlu: \(title)"
        case .specialAnimation(let animation):
            return "Animație: \(animation)"
        case .culturalInsight(let insight):
            return "Perspective culturală: \(insight)"
        case .heritageContent(let content):
            return "Conținut patrimonial: \(content)"
        }
    }
}

/// Main achievement manager with Romanian cultural focus
@Observable
class AchievementManager: ObservableObject {
    static let shared = AchievementManager()
    
    @Published var unlockedAchievements: Set<UUID> = []
    @Published var achievementProgress: [UUID: Float] = [:]
    @Published var totalCulturalPoints: Int = 0
    @Published var playerLevel: Int = 1
    @Published var playerTitle: String = "Începător" // Beginner
    @Published var recentlyUnlocked: [RomanianAchievement] = []
    
    private var gameStatistics: [String: Int] = [:]
    
    // MARK: - Cultural Achievements Database
    
    lazy var allAchievements: [RomanianAchievement] = createRomanianAchievements()
    
    private init() {
        loadProgress()
    }
    
    /// Create comprehensive Romanian cultural achievements
    private func createRomanianAchievements() -> [RomanianAchievement] {
        return [
            // MARK: - Card Mastery Achievements
            RomanianAchievement(
                category: .cardMastery,
                rarity: .common,
                titleRomanian: "Primul Șapte",
                titleEnglish: "First Seven",
                descriptionRomanian: "Joacă prima carte de șapte",
                descriptionEnglish: "Play your first seven card",
                culturalStory: "În tradiția românească, șapte este numărul norocului și al înțelepciunii.",
                historicalContext: "Carta de șapte în jocurile românești reprezintă puterea de a învinge orice adversitate.",
                requirement: .playSevenCards(count: 1),
                reward: .culturalPoints(25)
            ),
            
            RomanianAchievement(
                category: .cardMastery,
                rarity: .rare,
                titleRomanian: "Stăpânul Șeptelor",
                titleEnglish: "Master of Sevens",
                descriptionRomanian: "Joacă 100 de cărți de șapte",
                descriptionEnglish: "Play 100 seven cards",
                culturalStory: "Cine stăpânește șapte-le, stăpânește jocul - spunea un bătrân cărturar din Maramureș.",
                historicalContext: "Maestria cu șapte-le era semnul unui jucător adevărat în cafenelele românești.",
                requirement: .playSevenCards(count: 100),
                reward: .cardBack("Șapte de Aur Românesc")
            ),
            
            RomanianAchievement(
                category: .cardMastery,
                rarity: .epic,
                titleRomanian: "Cronometrarea Perfectă",
                titleEnglish: "Perfect Timing",
                descriptionRomanian: "Joacă 50 de cărți de opt la momentul perfect",
                descriptionEnglish: "Play 50 eight cards at the perfect moment",
                culturalStory: "Așa cum ciobanul știe când să-și mute turma, jucătorul înțelept știe când să joace opt-ul.",
                historicalContext: "Timing-ul cu opt-ul era considerat artă în jocurile de cărți din Transilvania.",
                requirement: .playEightAtRightTime(count: 50),
                reward: .specialAnimation("Cronometru de Aur")
            ),
            
            // MARK: - Traditional Play Achievements
            RomanianAchievement(
                category: .traditionalPlay,
                rarity: .uncommon,
                titleRomanian: "Păstrătorul Tradițiilor",
                titleEnglish: "Keeper of Traditions",
                descriptionRomanian: "Joacă 50 de jocuri menținând stilul tradițional",
                descriptionEnglish: "Play 50 games maintaining traditional style",
                culturalStory: "Fiecare joc păstrat în stilul tradițional este o punte către strămoșii noștri.",
                historicalContext: "Stilul tradițional de joc era transmis din tată în fiu în familiile româneşti.",
                requirement: .playGames(count: 50),
                reward: .characterUnlock(.oldWiseMan)
            ),
            
            RomanianAchievement(
                category: .traditionalPlay,
                rarity: .legendary,
                titleRomanian: "Marele Păstrător",
                titleEnglish: "The Great Keeper",
                descriptionRomanian: "Păstrează toate tradițiile culturale disponibile",
                descriptionEnglish: "Preserve all available cultural traditions",
                culturalStory: "Cel care păstrează toate tradițiile devine legenda satului.",
                historicalContext: "Marii păstrători erau respectați ca biblioteci vii ale culturii românești.",
                requirement: .preserveCulturalTraditions(count: 25),
                reward: .titleUnlock("Marele Păstrător de Tradiții")
            ),
            
            // MARK: - Cultural Wisdom Achievements
            RomanianAchievement(
                category: .culturalWisdom,
                rarity: .common,
                titleRomanian: "Student al Culturii",
                titleEnglish: "Student of Culture",
                descriptionRomanian: "Învață primele 5 fapte culturale românești",
                descriptionEnglish: "Learn your first 5 Romanian cultural facts",
                culturalStory: "Învățarea începe cu primul pas pe calea înțelepciunii.",
                historicalContext: "Educația culturală era fundamentul societății românești tradiționale.",
                requirement: .learnCulturalFacts(count: 5),
                reward: .culturalInsight("Începutul Înțelepciunii")
            ),
            
            RomanianAchievement(
                category: .culturalWisdom,
                rarity: .epic,
                titleRomanian: "Biblioteca Vie",
                titleEnglish: "Living Library",
                descriptionRomanian: "Acumulează cunoștințe despre toate aspectele culturii românești",
                descriptionEnglish: "Accumulate knowledge about all aspects of Romanian culture",
                culturalStory: "Cel ce cunoaște toate poveștile devine el însuși o poveste vie.",
                historicalContext: "Bibliotecile vii erau oameni care păstrau memoria comunității.",
                requirement: .learnCulturalFacts(count: 100),
                reward: .heritageContent("Colecția Completă de Folclor")
            ),
            
            // MARK: - Strategic Thinking Achievements
            RomanianAchievement(
                category: .strategicThinking,
                rarity: .rare,
                titleRomanian: "Mintea Strategică",
                titleEnglish: "Strategic Mind",
                descriptionRomanian: "Câștigă 25 de jocuri cu strategii complexe",
                descriptionEnglish: "Win 25 games with complex strategies",
                culturalStory: "Gândirea strategică românească combină înțelepciunea străbună cu inovația modernă.",
                historicalContext: "Strategia în jocurile de cărți reflecta tactici folosite în diplomația românească.",
                requirement: .winGames(count: 25),
                reward: .musicUnlock("Hora Strategilor")
            ),
            
            RomanianAchievement(
                category: .strategicThinking,
                rarity: .mythic,
                titleRomanian: "Marele Strateg",
                titleEnglish: "Grand Strategist",
                descriptionRomanian: "Demonstrează măiestrie strategică legendară",
                descriptionEnglish: "Demonstrate legendary strategic mastery",
                culturalStory: "Marii strategi sunt amintiti în cântecele populare pentru generații întregi.",
                historicalContext: "Strategii legendari ca Ștefan cel Mare foloseau gândirea tactică în toate aspectele vieții.",
                requirement: .achieveWinStreak(count: 20),
                reward: .titleUnlock("Marele Strateg al Patriei"),
                isHidden: true
            ),
            
            // MARK: - Community Spirit Achievements
            RomanianAchievement(
                category: .communitySpirit,
                rarity: .uncommon,
                titleRomanian: "Spirit de Echipă",
                titleEnglish: "Team Spirit",
                descriptionRomanian: "Demonstrează sportivitate în 10 jocuri",
                descriptionEnglish: "Demonstrate sportsmanship in 10 games",
                culturalStory: "Spiritul de echipă este fundamentul comunității românești tradiționale.",
                historicalContext: "Claca și șezătoarea demonstrau puterea muncii în echipă românească.",
                requirement: .exhibitSportsmanship(count: 10),
                reward: .culturalPoints(100)
            ),
            
            RomanianAchievement(
                category: .communitySpirit,
                rarity: .legendary,
                titleRomanian: "Inima Comunității",
                titleEnglish: "Heart of the Community",
                descriptionRomanian: "Învață și sprijină alți jucători",
                descriptionEnglish: "Teach and support other players",
                culturalStory: "Cei care dăruiesc din înțelepciunea lor devin inima comunității.",
                historicalContext: "Învățătorii satelor erau pilonii comunităților românești.",
                requirement: .teachNewPlayers(count: 10),
                reward: .characterUnlock(.villageTeacher)
            ),
            
            // MARK: - Heritage Keeper Achievements
            RomanianAchievement(
                category: .heritageKeeper,
                rarity: .epic,
                titleRomanian: "Gardianul Moștenirii",
                titleEnglish: "Guardian of Heritage",
                descriptionRomanian: "Păstrează și promovează cultura românească",
                descriptionEnglish: "Preserve and promote Romanian culture",
                culturalStory: "Gardienii moștenirii sunt legătura între trecut și viitor.",
                historicalContext: "Păstrarea culturii era responsabilitatea sacră a fiecărei generații.",
                requirement: .preserveCulturalTraditions(count: 15),
                reward: .storyUnlock("Legendele Dacilor")
            ),
            
            // MARK: - Game Expertise Achievements
            RomanianAchievement(
                category: .gameExpertise,
                rarity: .legendary,
                titleRomanian: "Maestru Absolut",
                titleEnglish: "Absolute Master",
                descriptionRomanian: "Atinge perfecțiunea în toate aspectele jocului",
                descriptionEnglish: "Achieve perfection in all aspects of the game",
                culturalStory: "Maestrul absolut este cel care a înțeles esența profundă a jocului tradițional.",
                historicalContext: "Maeștrii absoluti erau invitați să joace la curțile domnitorilor.",
                requirement: .masterDifficulty(difficulty: .expert, games: 50),
                reward: .titleUnlock("Maestru Absolut al Septica")
            ),
            
            // MARK: - Cultural Ambassador Achievements
            RomanianAchievement(
                category: .culturalAmbassador,
                rarity: .mythic,
                titleRomanian: "Ambasador Cultural Global",
                titleEnglish: "Global Cultural Ambassador",
                descriptionRomanian: "Răspândește cultura românească în întreaga lume",
                descriptionEnglish: "Spread Romanian culture throughout the world",
                culturalStory: "Adevărații ambasadori culturali fac ca România să fie cunoscută și respectată pretutindeni.",
                historicalContext: "România și-a câștigat respectul mondial prin ambasadorii culturali.",
                requirement: .preserveCulturalTraditions(count: 50),
                reward: .titleUnlock("Ambasador Cultural al României"),
                unlockLevel: 50,
                isHidden: true
            )
        ]
    }
    
    // MARK: - Achievement Tracking
    
    /// Check if achievement is unlocked
    func isAchievementUnlocked(_ achievementId: UUID) -> Bool {
        return unlockedAchievements.contains(achievementId)
    }
    
    /// Get achievement progress (0.0 to 1.0)
    func getAchievementProgress(_ achievementId: UUID) -> Float {
        return achievementProgress[achievementId] ?? 0.0
    }
    
    /// Update achievement progress based on game event
    func updateProgress(for event: GameEvent, with data: [String: Any] = [:]) {
        for achievement in allAchievements {
            guard !isAchievementUnlocked(achievement.id) else { continue }
            
            let currentProgress = getAchievementProgress(achievement.id)
            let newProgress = calculateProgress(for: achievement, event: event, data: data, current: currentProgress)
            
            if newProgress > currentProgress {
                achievementProgress[achievement.id] = newProgress
                
                // Check if achievement is completed
                if newProgress >= 1.0 {
                    unlockAchievement(achievement)
                }
            }
        }
        
        saveProgress()
    }
    
    /// Calculate progress for specific achievement
    private func calculateProgress(
        for achievement: RomanianAchievement,
        event: GameEvent,
        data: [String: Any],
        current: Float
    ) -> Float {
        
        switch (achievement.requirement, event) {
        case (.playGames(let required), .gameCompleted):
            let played = gameStatistics["gamesPlayed"] ?? 0
            return min(Float(played + 1) / Float(required), 1.0)
            
        case (.winGames(let required), .gameWon):
            let won = gameStatistics["gamesWon"] ?? 0
            return min(Float(won + 1) / Float(required), 1.0)
            
        case (.playSevenCards(let required), .sevenCardPlayed):
            let sevens = gameStatistics["sevensPlayed"] ?? 0
            return min(Float(sevens + 1) / Float(required), 1.0)
            
        case (.playEightAtRightTime(let required), .eightPlayedAtRightTime):
            let eights = gameStatistics["eightsAtRightTime"] ?? 0
            return min(Float(eights + 1) / Float(required), 1.0)
            
        case (.capturePointCards(let required), .pointCardCaptured):
            let points = gameStatistics["pointCardsCaptured"] ?? 0
            return min(Float(points + 1) / Float(required), 1.0)
            
        case (.achieveWinStreak(let required), .winStreakUpdated):
            if let streak = data["currentStreak"] as? Int {
                return min(Float(streak) / Float(required), 1.0)
            }
            
        case (.learnCulturalFacts(let required), .culturalFactLearned):
            let facts = gameStatistics["culturalFactsLearned"] ?? 0
            return min(Float(facts + 1) / Float(required), 1.0)
            
        case (.exhibitSportsmanship(let required), .sportsmanshipShown):
            let instances = gameStatistics["sportsmanshipInstances"] ?? 0
            return min(Float(instances + 1) / Float(required), 1.0)
            
        default:
            return current
        }
        
        return current
    }
    
    /// Unlock achievement and grant rewards
    private func unlockAchievement(_ achievement: RomanianAchievement) {
        unlockedAchievements.insert(achievement.id)
        totalCulturalPoints += achievement.culturalPoints
        recentlyUnlocked.append(achievement)
        
        // Grant rewards
        grantReward(achievement.reward)
        
        // Update player level and title
        updatePlayerStatus()
        
        // Trigger achievement notification
        NotificationCenter.default.post(
            name: .achievementUnlocked,
            object: achievement
        )
    }
    
    /// Grant achievement reward
    private func grantReward(_ reward: AchievementReward) {
        switch reward {
        case .culturalPoints(let points):
            totalCulturalPoints += points
        case .cardBack(let cardBack):
            // Unlock card back in card collection
            CardCollectionManager.shared.unlockCardBack(cardBack)
        case .characterUnlock(let character):
            // Unlock character in character system
            CharacterUnlockManager.shared.unlockCharacter(character)
        case .musicUnlock(let track):
            // Unlock music track
            MusicLibraryManager.shared.unlockTrack(track)
        case .titleUnlock(let title):
            // Unlock player title
            PlayerTitleManager.shared.unlockTitle(title)
        default:
            break
        }
    }
    
    /// Update player level and title based on cultural points
    private func updatePlayerStatus() {
        let newLevel = calculatePlayerLevel(totalCulturalPoints)
        if newLevel > playerLevel {
            playerLevel = newLevel
            playerTitle = getPlayerTitle(for: newLevel)
        }
    }
    
    /// Calculate player level from cultural points
    private func calculatePlayerLevel(_ points: Int) -> Int {
        switch points {
        case 0..<100: return 1
        case 100..<300: return 2
        case 300..<600: return 3
        case 600..<1000: return 4
        case 1000..<1500: return 5
        case 1500..<2500: return 6
        case 2500..<4000: return 7
        case 4000..<6000: return 8
        case 6000..<9000: return 9
        case 9000..<13000: return 10
        default: return min(10 + (points - 13000) / 2000, 50)
        }
    }
    
    /// Get Romanian cultural title for player level
    private func getPlayerTitle(for level: Int) -> String {
        switch level {
        case 1: return "Începător"           // Beginner
        case 2: return "Ucenic"              // Apprentice
        case 3: return "Jucător"             // Player
        case 4: return "Priceput"            // Skilled
        case 5: return "Experimentat"        // Experienced
        case 6: return "Meșter"              // Master
        case 7: return "Mare Meșter"         // Grand Master
        case 8: return "Expert"              // Expert
        case 9: return "Maestru"             // Maestro
        case 10: return "Legendă"            // Legend
        default: return "Păstrător Etern de Tradiții" // Eternal Keeper of Traditions
        }
    }
    
    // MARK: - Persistence
    
    private func saveProgress() {
        // Save to UserDefaults or Core Data
        let encoder = JSONEncoder()
        if let data = try? encoder.encode(Array(unlockedAchievements)) {
            UserDefaults.standard.set(data, forKey: "unlockedAchievements")
        }
        if let data = try? encoder.encode(achievementProgress) {
            UserDefaults.standard.set(data, forKey: "achievementProgress")
        }
        UserDefaults.standard.set(totalCulturalPoints, forKey: "totalCulturalPoints")
        UserDefaults.standard.set(playerLevel, forKey: "playerLevel")
        UserDefaults.standard.set(playerTitle, forKey: "playerTitle")
    }
    
    private func loadProgress() {
        let decoder = JSONDecoder()
        
        if let data = UserDefaults.standard.data(forKey: "unlockedAchievements"),
           let achievements = try? decoder.decode([UUID].self, from: data) {
            unlockedAchievements = Set(achievements)
        }
        
        if let data = UserDefaults.standard.data(forKey: "achievementProgress"),
           let progress = try? decoder.decode([UUID: Float].self, from: data) {
            achievementProgress = progress
        }
        
        totalCulturalPoints = UserDefaults.standard.integer(forKey: "totalCulturalPoints")
        playerLevel = UserDefaults.standard.integer(forKey: "playerLevel")
        playerTitle = UserDefaults.standard.string(forKey: "playerTitle") ?? "Începător"
    }
}

/// Achievement-related game events
enum GameEvent {
    case gameCompleted
    case gameWon
    case sevenCardPlayed
    case eightPlayedAtRightTime
    case pointCardCaptured
    case winStreakUpdated
    case culturalFactLearned
    case sportsmanshipShown
    case traditionalStyleMaintained
    case expertLevelReached
}

// MARK: - Notification Extensions

extension Notification.Name {
    static let achievementUnlocked = Notification.Name("achievementUnlocked")
}

// MARK: - Supporting Managers (Stubs for Integration)

class CardCollectionManager {
    static let shared = CardCollectionManager()
    private init() {}
    
    func unlockCardBack(_ cardBack: String) {
        // Implementation for unlocking card backs
    }
}

class CharacterUnlockManager {
    static let shared = CharacterUnlockManager()
    private init() {}
    
    func unlockCharacter(_ character: RomanianCharacterType) {
        // Implementation for unlocking characters
    }
}

class MusicLibraryManager {
    static let shared = MusicLibraryManager()
    private init() {}
    
    func unlockTrack(_ track: String) {
        // Implementation for unlocking music tracks
    }
}

class PlayerTitleManager {
    static let shared = PlayerTitleManager()
    private init() {}
    
    func unlockTitle(_ title: String) {
        // Implementation for unlocking player titles
    }
}