//
//  StatisticsView.swift
//  Septica
//
//  Statistics and achievements view for tracking player progress
//  Displays game history, win/loss ratios, and Romanian-themed achievements
//

import SwiftUI
import Charts

/// Statistics view showing player progress and achievements
struct StatisticsView: View {
    @EnvironmentObject var navigationManager: NavigationManager
    @State private var selectedTab: StatTab = .overview
    @State private var animateContent = false
    @State private var playerStats: PlayerHistoryStats?
    @State private var overallStats: OverallGameStats?
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Header with Romanian styling
                StatisticsHeaderView()
                    .padding(.bottom, 20)
                    .scaleEffect(animateContent ? 1.0 : 0.9)
                    .opacity(animateContent ? 1.0 : 0.0)
                
                // Tab selector
                StatTabPicker(selectedTab: $selectedTab)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                    .opacity(animateContent ? 1.0 : 0.0)
                    .animation(.easeInOut.delay(0.2), value: animateContent)
                
                // Content based on selected tab
                StatContentView(
                    tab: selectedTab,
                    playerStats: playerStats,
                    overallStats: overallStats
                )
                .padding(.horizontal, 20)
                .opacity(animateContent ? 1.0 : 0.0)
                .animation(.easeInOut.delay(0.4), value: animateContent)
                
                Spacer(minLength: 30)
            }
        }
        .background(RomanianStatisticsBackground())
        .navigationTitle("Statistics")
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            loadStatistics()
            animateContent = true
        }
        .refreshable {
            loadStatistics()
        }
    }
    
    private func loadStatistics() {
        // Get player name from settings
        let playerName = UserSettings.shared.playerName
        
        // Load statistics from GameController
        playerStats = navigationManager.gameController.getPlayerStatistics(for: playerName)
        overallStats = navigationManager.gameController.getOverallStatistics()
    }
}

// MARK: - Statistics Tabs

enum StatTab: String, CaseIterable, Identifiable {
    case overview = "Overview"
    case achievements = "Achievements"
    case history = "History"
    case charts = "Charts"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .overview:
            return "chart.bar.fill"
        case .achievements:
            return "trophy.fill"
        case .history:
            return "clock.fill"
        case .charts:
            return "chart.line.uptrend.xyaxis"
        }
    }
}

// MARK: - Header Views

/// Header with statistics overview
struct StatisticsHeaderView: View {
    var body: some View {
        VStack(spacing: 16) {
            // Trophy icon with Romanian colors
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.yellow.opacity(0.3),
                                Color.orange.opacity(0.2),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 20,
                            endRadius: 60
                        )
                    )
                    .frame(width: 120, height: 120)
                
                Image(systemName: "trophy.fill")
                    .font(.system(size: 50))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.yellow, .orange],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            
            // Title
            VStack(spacing: 8) {
                Text("Your Progress")
                    .font(.title.bold())
                    .foregroundColor(.white)
                
                Text("Track your Septica mastery")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
            }
        }
        .padding(.vertical, 20)
    }
}

// MARK: - Tab Picker

/// Tab picker for different statistic views
struct StatTabPicker: View {
    @Binding var selectedTab: StatTab
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(StatTab.allCases) { tab in
                    StatTabButton(
                        tab: tab,
                        isSelected: selectedTab == tab,
                        action: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                selectedTab = tab
                            }
                        }
                    )
                }
            }
            .padding(.horizontal)
        }
    }
}

/// Individual tab selection button
struct StatTabButton: View {
    let tab: StatTab
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: tab.icon)
                    .font(.caption)
                
                Text(tab.rawValue)
                    .font(.subheadline)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .foregroundColor(isSelected ? .white : .white.opacity(0.7))
            .background(
                Capsule()
                    .fill(
                        isSelected ?
                        LinearGradient(
                            colors: [.purple, .purple.opacity(0.8)],
                            startPoint: .top,
                            endPoint: .bottom
                        ) :
                        LinearGradient(
                            colors: [Color.white.opacity(0.1), Color.white.opacity(0.05)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .stroke(
                        isSelected ? Color.purple : Color.white.opacity(0.2),
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Content Views

/// Main content view for selected statistics tab
struct StatContentView: View {
    let tab: StatTab
    let playerStats: PlayerHistoryStats?
    let overallStats: OverallGameStats?
    
    var body: some View {
        switch tab {
        case .overview:
            OverviewStatsContent(playerStats: playerStats, overallStats: overallStats)
        case .achievements:
            AchievementsContent(playerStats: playerStats)
        case .history:
            HistoryContent()
        case .charts:
            ChartsContent(playerStats: playerStats)
        }
    }
}

/// Overview statistics content
struct OverviewStatsContent: View {
    let playerStats: PlayerHistoryStats?
    let overallStats: OverallGameStats?
    
    var body: some View {
        VStack(spacing: 20) {
            // Quick stats
            if let stats = playerStats {
                QuickStatsCard(stats: stats)
            } else {
                NoStatsCard()
            }
            
            // Overall performance
            if let overall = overallStats {
                OverallStatsCard(stats: overall)
            }
            
            // Recent performance (placeholder)
            RecentPerformanceCard()
        }
    }
}

/// Quick statistics overview card
struct QuickStatsCard: View {
    let stats: PlayerHistoryStats
    
    var body: some View {
        StatisticsCard(title: "Your Record", icon: "person.fill") {
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                StatMetric(
                    value: "\(stats.totalGames)",
                    label: "Games Played",
                    color: .blue
                )
                
                StatMetric(
                    value: "\(stats.wins)",
                    label: "Wins",
                    color: .green
                )
                
                StatMetric(
                    value: String(format: "%.1f%%", stats.winRate),
                    label: "Win Rate",
                    color: stats.winRate >= 50 ? .green : .orange
                )
                
                StatMetric(
                    value: String(format: "%.1f", stats.averagePointsPerGame),
                    label: "Avg Points",
                    color: .purple
                )
            }
        }
    }
}

/// No statistics available card
struct NoStatsCard: View {
    var body: some View {
        StatisticsCard(title: "No Games Yet", icon: "gamecontroller") {
            VStack(spacing: 16) {
                Image(systemName: "gamecontroller")
                    .font(.system(size: 40))
                    .foregroundColor(.gray)
                
                Text("Start playing to see your statistics!")
                    .font(.body)
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                
                Text("Your wins, losses, and achievements will appear here.")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.5))
                    .multilineTextAlignment(.center)
            }
        }
    }
}

/// Overall game statistics card
struct OverallStatsCard: View {
    let stats: OverallGameStats
    
    var body: some View {
        StatisticsCard(title: "Game Summary", icon: "chart.bar") {
            VStack(spacing: 16) {
                HStack {
                    StatMetric(
                        value: "\(stats.totalGames)",
                        label: "Total Games",
                        color: .blue
                    )
                    
                    Spacer()
                    
                    StatMetric(
                        value: "\(stats.completedGames)",
                        label: "Completed",
                        color: .green
                    )
                }
                
                if stats.averageGameDuration > 0 {
                    HStack {
                        StatMetric(
                            value: formatDuration(stats.averageGameDuration),
                            label: "Avg Duration",
                            color: .orange
                        )
                        
                        Spacer()
                        
                        if let difficulty = stats.mostPlayedDifficulty {
                            VStack(spacing: 4) {
                                Text(difficulty.displayName)
                                    .font(.headline)
                                    .foregroundColor(.purple)
                                
                                Text("Favorite AI")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.7))
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration / 60)
        let seconds = Int(duration.truncatingRemainder(dividingBy: 60))
        return String(format: "%d:%02d", minutes, seconds)
    }
}

/// Recent performance trends card
struct RecentPerformanceCard: View {
    var body: some View {
        StatisticsCard(title: "Recent Performance", icon: "chart.line.uptrend.xyaxis") {
            VStack(spacing: 12) {
                Text("Last 7 Days")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
                
                // Placeholder for recent performance chart
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.white.opacity(0.1))
                    .frame(height: 80)
                    .overlay(
                        Text("Performance chart coming soon")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.5))
                    )
            }
        }
    }
}

/// Achievements content with Romanian cultural elements
struct AchievementsContent: View {
    let playerStats: PlayerHistoryStats?
    
    var body: some View {
        VStack(spacing: 20) {
            // Achievement categories
            AchievementCategoryCard(
                title: "Beginner Achievements",
                achievements: beginnerAchievements,
                playerStats: playerStats
            )
            
            AchievementCategoryCard(
                title: "Master Achievements",
                achievements: masterAchievements,
                playerStats: playerStats
            )
            
            AchievementCategoryCard(
                title: "Romanian Master",
                achievements: romanianMasterAchievements,
                playerStats: playerStats
            )
        }
    }
    
    private var beginnerAchievements: [Achievement] {
        [
            Achievement(
                id: "first_win",
                title: "Prima Victorie",
                subtitle: "First Victory",
                description: "Win your first game of Septica",
                icon: "trophy",
                requirement: 1
            ),
            Achievement(
                id: "five_games",
                title: "Jucător Dedicat",
                subtitle: "Dedicated Player",
                description: "Play 5 games",
                icon: "gamecontroller",
                requirement: 5
            ),
            Achievement(
                id: "first_perfect",
                title: "Joc Perfect",
                subtitle: "Perfect Game",
                description: "Win without losing a single point",
                icon: "star",
                requirement: 1
            )
        ]
    }
    
    private var masterAchievements: [Achievement] {
        [
            Achievement(
                id: "win_streak_5",
                title: "Seria Victoriilor",
                subtitle: "Victory Streak",
                description: "Win 5 games in a row",
                icon: "flame",
                requirement: 5
            ),
            Achievement(
                id: "beat_expert",
                title: "Învingătorul Expertului",
                subtitle: "Expert Defeater",
                description: "Defeat Expert AI difficulty",
                icon: "crown",
                requirement: 1
            ),
            Achievement(
                id: "master_of_sevens",
                title: "Maestrul Septelor",
                subtitle: "Master of Sevens",
                description: "Collect all four 7s in a single game",
                icon: "7.circle",
                requirement: 1
            )
        ]
    }
    
    private var romanianMasterAchievements: [Achievement] {
        [
            Achievement(
                id: "centurion",
                title: "Centurionul Septicii",
                subtitle: "Septica Centurion",
                description: "Play 100 games",
                icon: "100.circle",
                requirement: 100
            ),
            Achievement(
                id: "romanian_champion",
                title: "Campionul Român",
                subtitle: "Romanian Champion",
                description: "Achieve 80% win rate over 50 games",
                icon: "medal",
                requirement: 80
            ),
            Achievement(
                id: "master_strategist",
                title: "Marele Strateg",
                subtitle: "Grand Strategist",
                description: "Win 50 games with different strategies",
                icon: "brain",
                requirement: 50
            )
        ]
    }
}

/// Achievement category card
struct AchievementCategoryCard: View {
    let title: String
    let achievements: [Achievement]
    let playerStats: PlayerHistoryStats?
    
    var body: some View {
        StatisticsCard(title: title, icon: "trophy.fill") {
            VStack(spacing: 12) {
                ForEach(achievements) { achievement in
                    AchievementRow(
                        achievement: achievement,
                        isUnlocked: isAchievementUnlocked(achievement),
                        progress: getAchievementProgress(achievement)
                    )
                    
                    if achievement != achievements.last {
                        Divider()
                            .background(Color.white.opacity(0.2))
                    }
                }
            }
        }
    }
    
    private func isAchievementUnlocked(_ achievement: Achievement) -> Bool {
        guard let stats = playerStats else { return false }
        
        switch achievement.id {
        case "first_win":
            return stats.wins >= 1
        case "five_games":
            return stats.totalGames >= 5
        case "centurion":
            return stats.totalGames >= 100
        case "romanian_champion":
            return stats.totalGames >= 50 && stats.winRate >= 80
        default:
            return false // Placeholder for more complex achievements
        }
    }
    
    private func getAchievementProgress(_ achievement: Achievement) -> Double {
        guard let stats = playerStats else { return 0.0 }
        
        switch achievement.id {
        case "first_win":
            return min(Double(stats.wins) / 1.0, 1.0)
        case "five_games":
            return min(Double(stats.totalGames) / 5.0, 1.0)
        case "centurion":
            return min(Double(stats.totalGames) / 100.0, 1.0)
        case "romanian_champion":
            let gamesProgress = min(Double(stats.totalGames) / 50.0, 1.0)
            let winRateProgress = min(stats.winRate / 80.0, 1.0)
            return min(gamesProgress * winRateProgress, 1.0)
        default:
            return 0.0
        }
    }
}

/// Individual achievement row
struct AchievementRow: View {
    let achievement: Achievement
    let isUnlocked: Bool
    let progress: Double
    
    var body: some View {
        HStack(spacing: 16) {
            // Achievement icon
            ZStack {
                Circle()
                    .fill(isUnlocked ? Color.yellow.opacity(0.2) : Color.gray.opacity(0.2))
                    .frame(width: 50, height: 50)
                
                Image(systemName: achievement.icon)
                    .font(.title2)
                    .foregroundColor(isUnlocked ? .yellow : .gray)
            }
            
            // Achievement info
            VStack(alignment: .leading, spacing: 4) {
                Text(achievement.title)
                    .font(.subheadline.bold())
                    .foregroundColor(isUnlocked ? .white : .white.opacity(0.6))
                
                Text(achievement.subtitle)
                    .font(.caption)
                    .foregroundColor(isUnlocked ? .yellow.opacity(0.8) : .gray)
                    .italic()
                
                Text(achievement.description)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                
                // Progress bar for locked achievements
                if !isUnlocked && progress > 0 {
                    ProgressView(value: progress)
                        .progressViewStyle(LinearProgressViewStyle(tint: .yellow))
                        .scaleEffect(x: 1, y: 0.5)
                }
            }
            
            Spacer()
            
            // Unlocked indicator
            if isUnlocked {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.title3)
            }
        }
        .padding(.vertical, 4)
    }
}

/// Game history content (simplified)
struct HistoryContent: View {
    var body: some View {
        VStack(spacing: 20) {
            StatisticsCard(title: "Recent Games", icon: "clock.fill") {
                VStack(spacing: 12) {
                    Text("Game history feature coming soon")
                        .font(.body)
                        .foregroundColor(.white.opacity(0.7))
                    
                    Text("Here you'll see your recent games, opponents faced, and detailed match statistics.")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.5))
                        .multilineTextAlignment(.center)
                }
                .frame(minHeight: 100)
            }
        }
    }
}

/// Charts and analytics content (placeholder)
struct ChartsContent: View {
    let playerStats: PlayerHistoryStats?
    
    var body: some View {
        VStack(spacing: 20) {
            StatisticsCard(title: "Performance Analytics", icon: "chart.line.uptrend.xyaxis") {
                VStack(spacing: 16) {
                    Text("Detailed charts coming soon")
                        .font(.body)
                        .foregroundColor(.white.opacity(0.7))
                    
                    // Placeholder for future charts
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.white.opacity(0.1))
                        .frame(height: 120)
                        .overlay(
                            VStack(spacing: 8) {
                                Image(systemName: "chart.bar")
                                    .font(.title)
                                    .foregroundColor(.white.opacity(0.3))
                                
                                Text("Win/Loss trends, difficulty progression, and more")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.5))
                                    .multilineTextAlignment(.center)
                            }
                        )
                }
            }
        }
    }
}

// MARK: - Supporting Views

/// Common card styling for statistics content
struct StatisticsCard<Content: View>: View {
    let title: String
    let icon: String
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(.purple)
                
                Text(title)
                    .font(.title3.bold())
                    .foregroundColor(.white)
                
                Spacer()
            }
            
            // Content
            content
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.1),
                            Color.white.opacity(0.05)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
        )
    }
}

/// Individual statistic metric display
struct StatMetric: View {
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title.bold())
                .foregroundColor(color)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
        }
    }
}

/// Background for statistics view
struct RomanianStatisticsBackground: View {
    var body: some View {
        ZStack {
            // Base gradient with Romanian-inspired colors
            LinearGradient(
                colors: [
                    Color(red: 0.06, green: 0.08, blue: 0.15),
                    Color(red: 0.08, green: 0.04, blue: 0.08),
                    Color(red: 0.04, green: 0.08, blue: 0.06)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // Trophy pattern overlay
            GeometryReader { geometry in
                ForEach(0..<20) { _ in
                    Image(systemName: "trophy")
                        .font(.system(size: CGFloat.random(in: 20...40)))
                        .foregroundColor(.white.opacity(0.02))
                        .rotationEffect(.degrees(Double.random(in: -30...30)))
                        .position(
                            x: CGFloat.random(in: 0...geometry.size.width),
                            y: CGFloat.random(in: 0...geometry.size.height)
                        )
                }
            }
        }
        .ignoresSafeArea()
    }
}

// MARK: - Data Models

/// Achievement model for tracking player progress
struct Achievement: Identifiable, Equatable {
    let id: String
    let title: String
    let subtitle: String
    let description: String
    let icon: String
    let requirement: Int
    
    static func == (lhs: Achievement, rhs: Achievement) -> Bool {
        return lhs.id == rhs.id
    }
}

// MARK: - Preview

struct StatisticsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            StatisticsView()
                .environmentObject(NavigationManager())
        }
        .preferredColorScheme(.dark)
    }
}