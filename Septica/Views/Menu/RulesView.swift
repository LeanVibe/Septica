//
//  RulesView.swift
//  Septica
//
//  Interactive rules explanation for Romanian Septica card game
//  Provides comprehensive guide to gameplay, scoring, and strategy
//

import SwiftUI

/// Interactive view explaining Romanian Septica rules and gameplay
struct RulesView: View {
    @EnvironmentObject var navigationManager: NavigationManager
    @State private var selectedSection: RuleSection = .overview
    @State private var animateContent = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Header with Romanian styling
                RulesHeaderView()
                    .padding(.bottom, 20)
                    .scaleEffect(animateContent ? 1.0 : 0.9)
                    .opacity(animateContent ? 1.0 : 0.0)
                
                // Section selector
                RuleSectionPicker(selectedSection: $selectedSection)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                    .opacity(animateContent ? 1.0 : 0.0)
                    .animation(.easeInOut.delay(0.2), value: animateContent)
                
                // Content based on selected section
                RuleContentView(section: selectedSection)
                    .padding(.horizontal, 20)
                    .opacity(animateContent ? 1.0 : 0.0)
                    .animation(.easeInOut.delay(0.4), value: animateContent)
                
                Spacer(minLength: 30)
            }
        }
        .background(RomanianRulesBackground())
        .navigationTitle("How to Play")
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            animateContent = true
        }
    }
}

// MARK: - Rule Sections

enum RuleSection: String, CaseIterable, Identifiable {
    case overview = "Overview"
    case setup = "Setup"
    case gameplay = "Gameplay"
    case scoring = "Scoring"
    case strategy = "Strategy"
    case examples = "Examples"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .overview:
            return "info.circle.fill"
        case .setup:
            return "square.stack.3d.down.right.fill"
        case .gameplay:
            return "play.circle.fill"
        case .scoring:
            return "target"
        case .strategy:
            return "brain.head.profile"
        case .examples:
            return "lightbulb.fill"
        }
    }
}

// MARK: - Header Views

/// Header with Romanian cultural elements
struct RulesHeaderView: View {
    var body: some View {
        VStack(spacing: 16) {
            // Traditional card design
            HStack(spacing: 16) {
                RomanianCardPreview(suit: "♠", value: "7", color: .black)
                RomanianCardPreview(suit: "♥", value: "A", color: .red)
                RomanianCardPreview(suit: "♦", value: "10", color: .red)
                RomanianCardPreview(suit: "♣", value: "8", color: .black)
            }
            
            // Title and subtitle
            VStack(spacing: 8) {
                Text("Septica Românească")
                    .font(.title.bold())
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.white, .white.opacity(0.8)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                
                Text("Traditional Romanian Card Game")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
                    .italic()
            }
        }
        .padding(.vertical, 20)
    }
}

/// Mini card preview for header
struct RomanianCardPreview: View {
    let suit: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.headline.bold())
                .foregroundColor(color == .black ? .white : color)
            
            Text(suit)
                .font(.title2)
                .foregroundColor(color == .black ? .white : color)
        }
        .frame(width: 50, height: 70)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.3), radius: 4, x: 2, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Section Picker

/// Section picker for different rule topics
struct RuleSectionPicker: View {
    @Binding var selectedSection: RuleSection
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(RuleSection.allCases) { section in
                    RuleSectionButton(
                        section: section,
                        isSelected: selectedSection == section,
                        action: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                selectedSection = section
                            }
                        }
                    )
                }
            }
            .padding(.horizontal)
        }
    }
}

/// Individual section selection button
struct RuleSectionButton: View {
    let section: RuleSection
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: section.icon)
                    .font(.caption)
                
                Text(section.rawValue)
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
                            colors: [.blue, .blue.opacity(0.8)],
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
                        isSelected ? Color.blue : Color.white.opacity(0.2),
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Content Views

/// Main content view for selected rule section
struct RuleContentView: View {
    let section: RuleSection
    
    var body: some View {
        switch section {
        case .overview:
            OverviewContent()
        case .setup:
            SetupContent()
        case .gameplay:
            GameplayContent()
        case .scoring:
            ScoringContent()
        case .strategy:
            StrategyContent()
        case .examples:
            ExamplesContent()
        }
    }
}

/// Overview of the game
struct OverviewContent: View {
    var body: some View {
        RulesCard(title: "What is Septica?", icon: "questionmark.circle.fill") {
            VStack(alignment: .leading, spacing: 16) {
                Text("Septica is a traditional Romanian trick-taking card game played with a standard 52-card deck. The name comes from \"șapte\" (seven in Romanian), as each player receives 7 cards.")
                    .font(.body)
                    .foregroundColor(.white.opacity(0.9))
                
                // Key points
                VStack(alignment: .leading, spacing: 12) {
                    Text("Key Features:")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    ForEach([
                        "2 players (you vs AI opponent)",
                        "7 cards dealt to each player",
                        "Trick-taking with strategic depth",
                        "Point-based scoring system",
                        "First to reach target score wins"
                    ], id: \.self) { feature in
                        HStack(alignment: .top, spacing: 8) {
                            Text("•")
                                .foregroundColor(.blue)
                            Text(feature)
                                .font(.body)
                                .foregroundColor(.white.opacity(0.9))
                        }
                    }
                }
                
                // Cultural note
                VStack(alignment: .leading, spacing: 8) {
                    Text("Romanian Tradition:")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text("This game has been played in Romanian households for generations, often during family gatherings and social events. It combines luck with strategic thinking, making every game exciting.")
                        .font(.body)
                        .foregroundColor(.white.opacity(0.9))
                        .italic()
                }
            }
        }
    }
}

/// Game setup instructions
struct SetupContent: View {
    var body: some View {
        VStack(spacing: 20) {
            RulesCard(title: "Game Setup", icon: "square.stack.3d.down.right.fill") {
                VStack(alignment: .leading, spacing: 16) {
                    // Deck setup
                    VStack(alignment: .leading, spacing: 8) {
                        Text("1. The Deck")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Text("Standard 52-card deck with all suits: ♠ ♥ ♦ ♣")
                            .font(.body)
                            .foregroundColor(.white.opacity(0.9))
                    }
                    
                    // Deal
                    VStack(alignment: .leading, spacing: 8) {
                        Text("2. Dealing")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Text("Each player receives exactly 7 cards. Remaining cards form the draw pile.")
                            .font(.body)
                            .foregroundColor(.white.opacity(0.9))
                    }
                    
                    // Starting player
                    VStack(alignment: .leading, spacing: 8) {
                        Text("3. First Player")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Text("The player with the lowest card (by rank and suit) starts the first trick.")
                            .font(.body)
                            .foregroundColor(.white.opacity(0.9))
                    }
                }
            }
            
            // Visual representation
            RulesCard(title: "Visual Setup", icon: "eye.fill") {
                VStack(spacing: 16) {
                    Text("Your Hand: 7 Cards")
                        .font(.subheadline)
                        .foregroundColor(.white)
                    
                    // Mock hand display
                    HStack(spacing: 8) {
                        ForEach(0..<7) { index in
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.white)
                                .frame(width: 30, height: 45)
                                .overlay(
                                    Text("?")
                                        .font(.caption.bold())
                                        .foregroundColor(.gray)
                                )
                        }
                    }
                    
                    Text("AI Hand: 7 Cards (Hidden)")
                        .font(.subheadline)
                        .foregroundColor(.white)
                        .padding(.top)
                    
                    HStack(spacing: 8) {
                        ForEach(0..<7) { index in
                            RoundedRectangle(cornerRadius: 6)
                                .fill(
                                    LinearGradient(
                                        colors: [.blue.opacity(0.8), .blue.opacity(0.6)],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .frame(width: 30, height: 45)
                        }
                    }
                }
            }
        }
    }
}

/// Gameplay mechanics
struct GameplayContent: View {
    var body: some View {
        VStack(spacing: 20) {
            RulesCard(title: "Playing Tricks", icon: "play.circle.fill") {
                VStack(alignment: .leading, spacing: 16) {
                    // Basic play
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Basic Play")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Text("Players take turns playing one card each to form a \"trick\". The player who plays the highest card wins the trick and collects all cards played.")
                            .font(.body)
                            .foregroundColor(.white.opacity(0.9))
                    }
                    
                    // Following suit
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Following Suit")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Text("You must follow the suit of the first card played if you have cards of that suit. If you don't have the suit, you can play any card.")
                            .font(.body)
                            .foregroundColor(.white.opacity(0.9))
                    }
                    
                    // Winning tricks
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Winning Tricks")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Text("The winner of each trick leads the next trick. The game continues until all cards are played.")
                            .font(.body)
                            .foregroundColor(.white.opacity(0.9))
                    }
                }
            }
            
            // Card hierarchy
            RulesCard(title: "Card Hierarchy", icon: "arrow.up.arrow.down") {
                VStack(alignment: .leading, spacing: 12) {
                    Text("From Highest to Lowest:")
                        .font(.subheadline)
                        .foregroundColor(.white)
                    
                    VStack(spacing: 8) {
                        CardRankRow(rank: "Ace (A)", points: "Highest", color: .red)
                        CardRankRow(rank: "King (K)", points: "High", color: .orange)
                        CardRankRow(rank: "Queen (Q)", points: "High", color: .orange)
                        CardRankRow(rank: "Jack (J)", points: "High", color: .orange)
                        CardRankRow(rank: "10", points: "Medium", color: .yellow)
                        CardRankRow(rank: "9", points: "Low", color: .gray)
                        CardRankRow(rank: "8", points: "Low", color: .gray)
                        CardRankRow(rank: "7", points: "Lowest", color: .gray)
                    }
                }
            }
        }
    }
}

/// Card rank display row
struct CardRankRow: View {
    let rank: String
    let points: String
    let color: Color
    
    var body: some View {
        HStack {
            Text(rank)
                .font(.body.bold())
                .foregroundColor(.white)
                .frame(width: 80, alignment: .leading)
            
            Spacer()
            
            Text(points)
                .font(.caption)
                .foregroundColor(color)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(color.opacity(0.2))
                )
        }
    }
}

/// Scoring system explanation
struct ScoringContent: View {
    var body: some View {
        VStack(spacing: 20) {
            RulesCard(title: "Point Values", icon: "target") {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Points are awarded for specific cards captured in tricks:")
                        .font(.body)
                        .foregroundColor(.white.opacity(0.9))
                    
                    VStack(spacing: 12) {
                        ScoringRow(cards: "All 7s", points: 1, description: "Each 7 is worth 1 point")
                        ScoringRow(cards: "All 8s", points: 1, description: "Each 8 is worth 1 point")
                        ScoringRow(cards: "All 10s", points: 1, description: "Each 10 is worth 1 point")
                        ScoringRow(cards: "All Aces", points: 1, description: "Each Ace is worth 1 point")
                    }
                    
                    Text("Total possible points per round: 16 points")
                        .font(.subheadline.bold())
                        .foregroundColor(.blue)
                        .padding(.top, 8)
                }
            }
            
            RulesCard(title: "Winning the Game", icon: "crown.fill") {
                VStack(alignment: .leading, spacing: 12) {
                    Text("The first player to reach the target score wins!")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text("Common target scores:")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.9))
                    
                    VStack(spacing: 8) {
                        TargetScoreRow(score: 7, description: "Quick game")
                        TargetScoreRow(score: 11, description: "Standard game (default)")
                        TargetScoreRow(score: 15, description: "Long game")
                        TargetScoreRow(score: 21, description: "Extended game")
                    }
                }
            }
        }
    }
}

/// Scoring breakdown row
struct ScoringRow: View {
    let cards: String
    let points: Int
    let description: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(cards)
                    .font(.subheadline.bold())
                    .foregroundColor(.white)
                
                Spacer()
                
                Text("\(points) pt\(points == 1 ? "" : "s") each")
                    .font(.subheadline)
                    .foregroundColor(.green)
            }
            
            Text(description)
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
        }
        .padding(.vertical, 4)
    }
}

/// Target score option row
struct TargetScoreRow: View {
    let score: Int
    let description: String
    
    var body: some View {
        HStack {
            Text("\(score) points")
                .font(.subheadline.bold())
                .foregroundColor(.white)
            
            Spacer()
            
            Text(description)
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
        }
    }
}

/// Strategy tips and advice
struct StrategyContent: View {
    var body: some View {
        VStack(spacing: 20) {
            RulesCard(title: "Basic Strategy", icon: "brain.head.profile") {
                VStack(alignment: .leading, spacing: 16) {
                    ForEach([
                        ("Card Counting", "Keep track of which high-value cards have been played"),
                        ("7s Strategy", "7s are valuable but weak - save them for the right moment"),
                        ("Leading Strong", "Lead with high cards to win tricks and control the game"),
                        ("Suit Control", "Try to exhaust your opponent's strong suits"),
                        ("Timing", "Don't always play your strongest card - sometimes save it")
                    ], id: \.0) { tip in
                        StrategyTipView(title: tip.0, description: tip.1)
                    }
                }
            }
            
            RulesCard(title: "Advanced Tips", icon: "lightbulb.max.fill") {
                VStack(alignment: .leading, spacing: 16) {
                    ForEach([
                        ("Memory Game", "Remember which suits your opponent can't follow"),
                        ("Point Distribution", "Know that 16 points are available each round"),
                        ("Risk Assessment", "Sometimes losing a trick strategically is better"),
                        ("End Game", "Count remaining points to know if you can still win")
                    ], id: \.0) { tip in
                        StrategyTipView(title: tip.0, description: tip.1)
                    }
                }
            }
        }
    }
}

/// Individual strategy tip view
struct StrategyTipView: View {
    let title: String
    let description: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline.bold())
                .foregroundColor(.yellow)
            
            Text(description)
                .font(.body)
                .foregroundColor(.white.opacity(0.9))
        }
    }
}

/// Example scenarios and plays
struct ExamplesContent: View {
    var body: some View {
        VStack(spacing: 20) {
            RulesCard(title: "Example Trick", icon: "lightbulb.fill") {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Scenario: You lead with 7♠")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Your play: 7♠ (1 point value)")
                            .font(.body)
                            .foregroundColor(.blue)
                        
                        Text("AI response: K♠ (stronger spade)")
                            .font(.body)
                            .foregroundColor(.red)
                        
                        Text("Result: AI wins the trick and gets your 7♠")
                            .font(.body.bold())
                            .foregroundColor(.white)
                    }
                    
                    Text("Lesson: Leading with point cards can be risky if the opponent has higher cards in that suit.")
                        .font(.caption)
                        .foregroundColor(.yellow)
                        .italic()
                        .padding(.top, 8)
                }
            }
            
            RulesCard(title: "Smart Play", icon: "checkmark.circle.fill") {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Scenario: AI leads with Q♥")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("AI play: Q♥ (no point value)")
                            .font(.body)
                            .foregroundColor(.red)
                        
                        Text("Your options:")
                            .font(.body)
                            .foregroundColor(.white)
                        
                        Text("• Play A♥ to win (if you have it)")
                            .font(.body)
                            .foregroundColor(.green)
                        
                        Text("• Play 7♥ to lose but keep stronger cards")
                            .font(.body)
                            .foregroundColor(.blue)
                    }
                    
                    Text("Best play: If you have A♥, win the trick. If not, play your lowest heart to minimize loss.")
                        .font(.caption)
                        .foregroundColor(.yellow)
                        .italic()
                        .padding(.top, 8)
                }
            }
        }
    }
}

// MARK: - Supporting Views

/// Common card styling for rules content
struct RulesCard<Content: View>: View {
    let title: String
    let icon: String
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(.blue)
                
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

/// Background for rules view
struct RomanianRulesBackground: View {
    var body: some View {
        ZStack {
            // Base gradient
            LinearGradient(
                colors: [
                    Color(red: 0.08, green: 0.12, blue: 0.18),
                    Color(red: 0.12, green: 0.08, blue: 0.12),
                    Color(red: 0.08, green: 0.12, blue: 0.08)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // Card pattern overlay
            GeometryReader { geometry in
                ForEach(0..<30) { _ in
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.white.opacity(0.02))
                        .frame(width: 40, height: 60)
                        .rotationEffect(.degrees(Double.random(in: -45...45)))
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

// MARK: - Preview

struct RulesView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            RulesView()
                .environmentObject(NavigationManager())
        }
        .preferredColorScheme(.dark)
    }
}