//
//  AchievementView.swift
//  Septica
//
//  Romanian cultural achievement display system
//  Shows unlocked achievements with cultural context and stories
//

import SwiftUI

/// Main achievement gallery view displaying all Romanian cultural achievements
struct AchievementView: View {
    @StateObject private var achievementManager = AchievementManager.shared
    @State private var selectedCategory: RomanianAchievementCategory = .cardMastery
    @State private var selectedAchievement: RomanianAchievement?
    @State private var showingAchievementDetails = false
    
    private let columns = [
        GridItem(.adaptive(minimum: 160), spacing: 16)
    ]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Romanian cultural header
                achievementHeaderView
                
                // Category selector with traditional Romanian design
                categorySelector
                    .padding(.horizontal)
                
                // Achievement grid
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(filteredAchievements) { achievement in
                            AchievementCardView(
                                achievement: achievement,
                                isUnlocked: achievementManager.isUnlocked(achievement.id),
                                progress: achievementManager.getProgress(for: achievement.id)
                            )
                            .onTapGesture {
                                selectedAchievement = achievement
                                showingAchievementDetails = true
                            }
                        }
                    }
                    .padding()
                }
            }
            .background(
                LinearGradient(
                    colors: [
                        RomanianColors.primaryBlue.opacity(0.1),
                        RomanianColors.countrysideGreen.opacity(0.1)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
            )
            .navigationTitle("Realizări Românești")
            .navigationBarTitleDisplayMode(.inline)
        }
        .sheet(isPresented: $showingAchievementDetails) {
            if let achievement = selectedAchievement {
                AchievementDetailView(
                    achievement: achievement,
                    isUnlocked: achievementManager.isUnlocked(achievement.id),
                    progress: achievementManager.getProgress(for: achievement.id)
                )
            }
        }
    }
    
    @ViewBuilder
    private var achievementHeaderView: some View {
        VStack(spacing: 8) {
            // Romanian cultural elements
            HStack {
                Image(systemName: "crown.fill")
                    .foregroundColor(RomanianColors.goldAccent)
                    .font(.title2)
                
                Text("Moștenirea Culturală")
                    .font(.title2.bold())
                    .foregroundColor(RomanianColors.primaryBlue)
                
                Image(systemName: "crown.fill")
                    .foregroundColor(RomanianColors.goldAccent)
                    .font(.title2)
            }
            
            Text("Descoperă tradițiile românești prin jocul de Septică")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(Color(.systemBackground))
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
    
    @ViewBuilder
    private var categorySelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(RomanianAchievementCategory.allCases, id: \.self) { category in
                    CategoryButton(
                        category: category,
                        isSelected: selectedCategory == category
                    ) {
                        selectedCategory = category
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
    }
    
    private var filteredAchievements: [RomanianAchievement] {
        achievementManager.achievements.filter { $0.category == selectedCategory }
    }
}

/// Individual achievement card with Romanian cultural styling
struct AchievementCardView: View {
    let achievement: RomanianAchievement
    let isUnlocked: Bool
    let progress: Double
    
    var body: some View {
        VStack(spacing: 12) {
            // Achievement icon with cultural background
            ZStack {
                Circle()
                    .fill(isUnlocked ? achievementGradient : lockedGradient)
                    .frame(width: 80, height: 80)
                    .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                
                Image(systemName: achievement.iconName)
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)
                    .opacity(isUnlocked ? 1.0 : 0.5)
            }
            
            VStack(spacing: 4) {
                // Achievement name
                Text(achievement.name)
                    .font(.headline.bold())
                    .foregroundColor(isUnlocked ? .primary : .secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                
                // Rarity indicator
                HStack(spacing: 4) {
                    ForEach(0..<achievement.rarity.starCount, id: \.self) { _ in
                        Image(systemName: "star.fill")
                            .foregroundColor(rarityColor)
                            .font(.caption2)
                    }
                }
                
                // Progress bar for locked achievements
                if !isUnlocked && progress > 0 {
                    VStack(spacing: 2) {
                        ProgressView(value: progress)
                            .progressViewStyle(RomanianProgressViewStyle())
                            .frame(height: 4)
                        
                        Text("\(Int(progress * 100))%")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Cultural context
                Text(achievement.culturalContext)
                    .font(.caption2)
                    .foregroundColor(RomanianColors.primaryBlue)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        .opacity(isUnlocked ? 1.0 : 0.7)
        .scaleEffect(isUnlocked ? 1.0 : 0.95)
    }
    
    private var achievementGradient: LinearGradient {
        LinearGradient(
            colors: [
                rarityColor,
                rarityColor.opacity(0.8)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    private var lockedGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color.gray,
                Color.gray.opacity(0.6)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    private var rarityColor: Color {
        switch achievement.rarity {
        case .common:
            return .gray
        case .uncommon:
            return .green
        case .rare:
            return .blue
        case .epic:
            return .purple
        case .legendary:
            return RomanianColors.goldAccent
        case .mythic:
            return RomanianColors.embroideryRed
        }
    }
}

/// Category selection button with Romanian styling
struct CategoryButton: View {
    let category: RomanianAchievementCategory
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: categoryIcon)
                    .font(.title3.bold())
                    .foregroundColor(isSelected ? .white : RomanianColors.primaryBlue)
                
                Text(category.displayName)
                    .font(.caption.bold())
                    .foregroundColor(isSelected ? .white : RomanianColors.primaryBlue)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? RomanianColors.primaryBlue : Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(RomanianColors.primaryBlue, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var categoryIcon: String {
        switch category {
        case .cardMastery:
            return "suit.spade.fill"
        case .strategicPlay:
            return "brain.head.profile"
        case .culturalKnowledge:
            return "book.fill"
        case .socialConnection:
            return "person.2.fill"
        case .dedication:
            return "flame.fill"
        case .exploration:
            return "map.fill"
        case .mastery:
            return "crown.fill"
        case .legacy:
            return "star.fill"
        }
    }
}

/// Achievement detail view with full cultural story
struct AchievementDetailView: View {
    let achievement: RomanianAchievement
    let isUnlocked: Bool
    let progress: Double
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Achievement header
                    achievementHeader
                    
                    // Cultural story
                    if isUnlocked {
                        culturalStorySection
                    } else {
                        lockedContentSection
                    }
                    
                    // Requirements
                    requirementsSection
                    
                    // Historical context
                    if isUnlocked {
                        historicalContextSection
                    }
                }
                .padding()
            }
            .navigationTitle(achievement.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Închide") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private var achievementHeader: some View {
        HStack(alignment: .center, spacing: 20) {
            // Large achievement icon
            ZStack {
                Circle()
                    .fill(isUnlocked ? achievementGradient : lockedGradient)
                    .frame(width: 120, height: 120)
                    .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
                
                Image(systemName: achievement.iconName)
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(.white)
                    .opacity(isUnlocked ? 1.0 : 0.5)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                // Achievement name
                Text(achievement.name)
                    .font(.title.bold())
                    .foregroundColor(.primary)
                
                // Rarity with stars
                HStack(spacing: 4) {
                    ForEach(0..<achievement.rarity.starCount, id: \.self) { _ in
                        Image(systemName: "star.fill")
                            .foregroundColor(rarityColor)
                            .font(.title3)
                    }
                    
                    Text(achievement.rarity.displayName)
                        .font(.headline)
                        .foregroundColor(rarityColor)
                }
                
                // Cultural context
                Text(achievement.culturalContext)
                    .font(.subheadline)
                    .foregroundColor(RomanianColors.primaryBlue)
                    .italic()
                
                // Progress if not unlocked
                if !isUnlocked && progress > 0 {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Progres: \(Int(progress * 100))%")
                            .font(.caption.bold())
                            .foregroundColor(.secondary)
                        
                        ProgressView(value: progress)
                            .progressViewStyle(RomanianProgressViewStyle())
                            .frame(height: 6)
                    }
                }
            }
            
            Spacer()
        }
    }
    
    @ViewBuilder
    private var culturalStorySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Povestea Culturală")
                .font(.title2.bold())
                .foregroundColor(RomanianColors.primaryBlue)
            
            Text(achievement.culturalStory)
                .font(.body)
                .lineSpacing(4)
                .foregroundColor(.primary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
    
    @ViewBuilder
    private var lockedContentSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "lock.fill")
                .font(.largeTitle)
                .foregroundColor(.secondary)
            
            Text("Realizare Blocată")
                .font(.headline.bold())
                .foregroundColor(.secondary)
            
            Text("Îndeplinește cerințele pentru a debloca povestea culturală și contextul istoric.")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
        }
        .padding(20)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    @ViewBuilder
    private var requirementsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Cerințe")
                .font(.title2.bold())
                .foregroundColor(RomanianColors.primaryRed)
            
            Text(achievement.description)
                .font(.body)
                .foregroundColor(.primary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
    
    @ViewBuilder
    private var historicalContextSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Context Istoric")
                .font(.title2.bold())
                .foregroundColor(RomanianColors.countrysideGreen)
            
            Text(achievement.historicalContext)
                .font(.body)
                .lineSpacing(4)
                .foregroundColor(.primary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
    
    private var achievementGradient: LinearGradient {
        LinearGradient(
            colors: [rarityColor, rarityColor.opacity(0.8)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    private var lockedGradient: LinearGradient {
        LinearGradient(
            colors: [Color.gray, Color.gray.opacity(0.6)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    private var rarityColor: Color {
        switch achievement.rarity {
        case .common:
            return .gray
        case .uncommon:
            return .green
        case .rare:
            return .blue
        case .epic:
            return .purple
        case .legendary:
            return RomanianColors.goldAccent
        case .mythic:
            return RomanianColors.embroideryRed
        }
    }
}

/// Custom progress view style with Romanian colors
struct RomanianProgressViewStyle: ProgressViewStyle {
    func makeBody(configuration: Configuration) -> some View {
        ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: 2)
                .fill(Color(.systemGray5))
            
            RoundedRectangle(cornerRadius: 2)
                .fill(
                    LinearGradient(
                        colors: [
                            RomanianColors.primaryBlue,
                            RomanianColors.primaryRed
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .scaleEffect(x: CGFloat(configuration.fractionCompleted ?? 0), y: 1, anchor: .leading)
        }
    }
}

// MARK: - Achievement Notification Overlay

/// Overlay that appears when an achievement is unlocked
struct AchievementUnlockedOverlay: View {
    let achievement: RomanianAchievement
    @Binding var isVisible: Bool
    
    @State private var animationProgress: CGFloat = 0
    @State private var celebrationScale: CGFloat = 0
    
    var body: some View {
        if isVisible {
            ZStack {
                // Semi-transparent background
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .onTapGesture {
                        dismissOverlay()
                    }
                
                // Achievement unlock card
                VStack(spacing: 20) {
                    // "Realizare Deblocată" title
                    Text("🏆 Realizare Deblocată! 🏆")
                        .font(.title.bold())
                        .foregroundColor(RomanianColors.goldAccent)
                        .scaleEffect(celebrationScale)
                    
                    // Achievement icon
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [rarityColor, rarityColor.opacity(0.8)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 120, height: 120)
                            .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
                        
                        Image(systemName: achievement.iconName)
                            .font(.system(size: 48, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .scaleEffect(animationProgress * 1.2)
                    
                    VStack(spacing: 8) {
                        // Achievement name
                        Text(achievement.name)
                            .font(.title2.bold())
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.center)
                        
                        // Cultural context
                        Text(achievement.culturalContext)
                            .font(.subheadline)
                            .foregroundColor(RomanianColors.primaryBlue)
                            .italic()
                            .multilineTextAlignment(.center)
                    }
                    
                    // Dismiss button
                    Button("Minunat!") {
                        dismissOverlay()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(RomanianColors.primaryBlue)
                }
                .padding(30)
                .background(Color(.systemBackground))
                .cornerRadius(20)
                .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
                .opacity(animationProgress)
                .offset(y: (1 - animationProgress) * 50)
            }
            .transition(.asymmetric(
                insertion: .scale.combined(with: .opacity),
                removal: .opacity
            ))
            .onAppear {
                appearAnimation()
                
                // Auto-dismiss after 5 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                    dismissOverlay()
                }
            }
        }
    }
    
    private var rarityColor: Color {
        switch achievement.rarity {
        case .common:
            return .gray
        case .uncommon:
            return .green
        case .rare:
            return .blue
        case .epic:
            return .purple
        case .legendary:
            return RomanianColors.goldAccent
        case .mythic:
            return RomanianColors.embroideryRed
        }
    }
    
    private func appearAnimation() {
        withAnimation(.spring(response: 0.8, dampingFraction: 0.6)) {
            animationProgress = 1.0
        }
        
        withAnimation(.spring(response: 0.6, dampingFraction: 0.5).delay(0.2)) {
            celebrationScale = 1.0
        }
    }
    
    private func dismissOverlay() {
        withAnimation(.easeOut(duration: 0.3)) {
            animationProgress = 0
            celebrationScale = 0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            isVisible = false
        }
    }
}

// MARK: - Preview

struct AchievementView_Previews: PreviewProvider {
    static var previews: some View {
        AchievementView()
            .previewDevice("iPhone 14 Pro")
    }
}