//
//  AchievementNotificationView.swift
//  Septica
//
//  Romanian Cultural Achievement Notification System - Sprint 2
//  Beautiful achievement celebrations with authentic Romanian heritage design
//

import SwiftUI

/// Romanian cultural achievement notification with heritage-inspired animations
struct AchievementNotificationView: View {
    let achievement: RomanianAchievement
    let onDismiss: () -> Void
    
    @State private var isVisible = false
    @State private var celebrationScale: CGFloat = 0.1
    @State private var badgeRotation: Double = 0
    @State private var particleOpacity: Double = 0
    @State private var folklorePattern: Double = 0
    @State private var culturalGlow: Double = 0.3
    
    var body: some View {
        ZStack {
            // Romanian cultural background
            RomanianCulturalBackground()
            
            // Main achievement notification card
            achievementCard
                .scaleEffect(celebrationScale)
                .opacity(isVisible ? 1.0 : 0.0)
                .onAppear {
                    performCulturalCelebration()
                }
            
            // Romanian folk pattern overlay
            FolkPatternOverlay(intensity: folklorePattern)
            
            // Cultural celebration particles
            CulturalCelebrationParticles(opacity: particleOpacity)
        }
        .background(Color.black.opacity(0.6))
        .ignoresSafeArea()
        .onTapGesture {
            dismissWithCelebration()
        }
    }
    
    private var achievementCard: some View {
        VStack(spacing: 20) {
            // Romanian heritage badge
            achievementBadge
            
            // Achievement details with Romanian cultural context
            achievementDetails
            
            // Cultural significance explanation
            culturalSignificance
            
            // Celebration actions
            celebrationActions
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        colors: [
                            RomanianColors.primaryBlue.opacity(0.95),
                            RomanianColors.primaryYellow.opacity(0.90),
                            RomanianColors.primaryRed.opacity(0.85)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(
                    color: RomanianColors.goldAccent.opacity(culturalGlow),
                    radius: 15,
                    x: 0,
                    y: 8
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(
                    RomanianColors.goldAccent.opacity(0.8),
                    lineWidth: 2
                )
        )
        .frame(maxWidth: 320)
    }
    
    private var achievementBadge: some View {
        ZStack {
            // Romanian folk art pattern background
            RomanianFolkBadgeBackground(
                colorScheme: achievement.badge.colorScheme,
                animation: achievement.badge.animation
            )
            
            // Achievement icon with cultural symbol
            Image(systemName: achievement.badge.iconName)
                .font(.system(size: 48, weight: .bold))
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.3), radius: 2, x: 1, y: 1)
                .rotationEffect(.degrees(badgeRotation))
            
            // Cultural symbol overlay if available
            if let culturalSymbol = achievement.badge.culturalSymbol {
                Text(culturalSymbol)
                    .font(.system(size: 24))
                    .offset(x: 25, y: -25)
                    .scaleEffect(1.2)
            }
        }
        .frame(width: 80, height: 80)
    }
    
    private var achievementDetails: some View {
        VStack(spacing: 12) {
            // Achievement title with Romanian translation
            VStack(spacing: 4) {
                Text(achievement.titleKey)
                    .font(.title2.bold())
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                // Romanian cultural category
                Text(achievement.category.rawValue.replacingOccurrences(of: "_", with: " ").capitalized)
                    .font(.caption.weight(.medium))
                    .foregroundColor(RomanianColors.goldAccent)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color.white.opacity(0.2))
                    )
            }
            
            // Achievement description
            Text(achievement.descriptionKey)
                .font(.body)
                .foregroundColor(.white.opacity(0.9))
                .multilineTextAlignment(.center)
                .lineLimit(3)
        }
    }
    
    private var culturalSignificance: some View {
        VStack(spacing: 8) {
            // Cultural context header
            HStack {
                Image(systemName: "book.fill")
                    .foregroundColor(RomanianColors.goldAccent)
                Text("Context Cultural Românesc")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(RomanianColors.goldAccent)
            }
            
            // Cultural explanation
            Text(achievement.culturalContextKey)
                .font(.caption)
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
                .lineLimit(4)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.1))
        )
    }
    
    private var celebrationActions: some View {
        HStack(spacing: 16) {
            // Experience points reward
            rewardBadge(
                icon: "star.fill",
                value: "\(achievement.experiencePoints)",
                label: "XP",
                color: RomanianColors.goldAccent
            )
            
            // Cultural knowledge points
            rewardBadge(
                icon: "brain.head.profile.fill",
                value: "\(achievement.culturalKnowledgePoints)",
                label: "Cunoștințe",
                color: RomanianColors.folkBlue
            )
            
            // Difficulty indicator
            difficultyBadge
        }
    }
    
    private func rewardBadge(icon: String, value: String, label: String, color: Color) -> some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                Text(value)
                    .font(.caption.bold())
            }
            .foregroundColor(color)
            
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(color.opacity(0.2))
        )
    }
    
    private var difficultyBadge: some View {
        VStack(spacing: 4) {
            difficultyIcon
            
            Text(achievement.difficulty.rawValue.capitalized)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(difficultyColor.opacity(0.2))
        )
    }
    
    private var difficultyIcon: some View {
        HStack(spacing: 2) {
            ForEach(0..<difficultyStars, id: \.self) { _ in
                Image(systemName: "star.fill")
                    .font(.system(size: 8))
                    .foregroundColor(difficultyColor)
            }
        }
    }
    
    private var difficultyStars: Int {
        switch achievement.difficulty {
        case .bronze: return 1
        case .silver: return 2
        case .gold: return 3
        case .legendary: return 4
        }
    }
    
    private var difficultyColor: Color {
        switch achievement.difficulty {
        case .bronze: return .brown
        case .silver: return .gray
        case .gold: return RomanianColors.goldAccent
        case .legendary: return RomanianColors.byzantineGold
        }
    }
    
    // MARK: - Romanian Cultural Animations
    
    private func performCulturalCelebration() {
        // Romanian folk-inspired celebration sequence
        
        // 1. Initial cultural reveal with heritage timing
        withAnimation(.easeOut(duration: 0.8)) {
            isVisible = true
            celebrationScale = 1.0
        }
        
        // 2. Badge celebration with folk dance rhythm
        withAnimation(
            .easeInOut(duration: 1.2)
            .repeatCount(3, autoreverses: true)
            .delay(0.3)
        ) {
            badgeRotation = 15
        }
        
        // 3. Romanian cultural glow effect
        withAnimation(
            .easeInOut(duration: 2.0)
            .repeatCount(2, autoreverses: true)
            .delay(0.5)
        ) {
            culturalGlow = 0.9
        }
        
        // 4. Folk pattern animation
        withAnimation(
            .linear(duration: 3.0)
            .delay(0.7)
        ) {
            folklorePattern = 1.0
        }
        
        // 5. Cultural celebration particles
        withAnimation(
            .easeIn(duration: 1.5)
            .delay(1.0)
        ) {
            particleOpacity = 0.8
        }
        
        // Auto-dismiss after cultural celebration
        DispatchQueue.main.asyncAfter(deadline: .now() + 6.0) {
            dismissWithCelebration()
        }
    }
    
    private func dismissWithCelebration() {
        withAnimation(.easeIn(duration: 0.5)) {
            isVisible = false
            celebrationScale = 0.1
            particleOpacity = 0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            onDismiss()
        }
    }
}

// MARK: - Romanian Cultural Background Components

struct RomanianCulturalBackground: View {
    @State private var backgroundAnimation: Double = 0
    
    var body: some View {
        ZStack {
            // Traditional Romanian colors gradient
            LinearGradient(
                colors: [
                    RomanianColors.primaryBlue.opacity(0.3),
                    RomanianColors.primaryYellow.opacity(0.2),
                    RomanianColors.primaryRed.opacity(0.3)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // Subtle folk pattern overlay
            Image(systemName: "star.fill")
                .font(.system(size: 100))
                .foregroundColor(RomanianColors.goldAccent.opacity(0.1))
                .rotationEffect(.degrees(backgroundAnimation))
                .onAppear {
                    withAnimation(.linear(duration: 20).repeatForever(autoreverses: false)) {
                        backgroundAnimation = 360
                    }
                }
        }
    }
}

struct FolkPatternOverlay: View {
    let intensity: Double
    
    var body: some View {
        // Romanian folk art pattern simulation
        VStack(spacing: 20) {
            ForEach(0..<5, id: \.self) { row in
                HStack(spacing: 20) {
                    ForEach(0..<6, id: \.self) { col in
                        folkPatternElement
                            .opacity(intensity * 0.3)
                            .scaleEffect(intensity * 0.5 + 0.3)
                            .rotationEffect(.degrees(Double(row * col) * 45))
                    }
                }
            }
        }
        .opacity(intensity)
    }
    
    private var folkPatternElement: some View {
        Image(systemName: "diamond.fill")
            .font(.system(size: 8))
            .foregroundColor(RomanianColors.goldAccent.opacity(0.4))
    }
}

struct CulturalCelebrationParticles: View {
    let opacity: Double
    @State private var particlePositions: [CGPoint] = []
    @State private var particleAnimation: Double = 0
    
    var body: some View {
        ZStack {
            ForEach(0..<20, id: \.self) { index in
                Circle()
                    .fill(
                        [RomanianColors.goldAccent, RomanianColors.primaryYellow, RomanianColors.byzantineGold]
                            .randomElement() ?? RomanianColors.goldAccent
                    )
                    .frame(width: CGFloat.random(in: 4...12))
                    .position(particlePosition(for: index))
                    .opacity(opacity)
                    .scaleEffect(sin(particleAnimation + Double(index)) * 0.5 + 0.5)
            }
        }
        .onAppear {
            generateParticlePositions()
            withAnimation(.linear(duration: 2.0).repeatForever(autoreverses: false)) {
                particleAnimation = .pi * 2
            }
        }
    }
    
    private func generateParticlePositions() {
        particlePositions = (0..<20).map { _ in
            CGPoint(
                x: CGFloat.random(in: 50...350),
                y: CGFloat.random(in: 100...700)
            )
        }
    }
    
    private func particlePosition(for index: Int) -> CGPoint {
        guard index < particlePositions.count else {
            return CGPoint(x: 200, y: 400)
        }
        return particlePositions[index]
    }
}

struct RomanianFolkBadgeBackground: View {
    let colorScheme: BadgeColorScheme
    let animation: BadgeAnimation
    
    @State private var animationValue: Double = 0
    
    var body: some View {
        ZStack {
            // Base cultural background
            Circle()
                .fill(
                    RadialGradient(
                        colors: backgroundColors,
                        center: .center,
                        startRadius: 10,
                        endRadius: 40
                    )
                )
            
            // Romanian folk pattern
            Circle()
                .stroke(
                    RomanianColors.goldAccent,
                    lineWidth: 3
                )
                .scaleEffect(folkloreScale)
                .opacity(folkloreOpacity)
            
            // Inner cultural circle
            Circle()
                .fill(backgroundColors.first?.opacity(0.8) ?? .clear)
                .frame(width: 60, height: 60)
        }
        .onAppear {
            performBadgeAnimation()
        }
    }
    
    private var backgroundColors: [Color] {
        switch colorScheme {
        case .bronze:
            return [.brown, .orange.opacity(0.7)]
        case .silver:
            return [.gray, .white.opacity(0.8)]
        case .gold:
            return [RomanianColors.goldAccent, RomanianColors.byzantineGold]
        case .legendary:
            return [RomanianColors.primaryBlue, RomanianColors.primaryRed, RomanianColors.primaryYellow]
        case .cultural:
            return [RomanianColors.folkloreBlue, RomanianColors.countrysideGreen]
        case .seasonal:
            return [RomanianColors.primaryYellow, RomanianColors.goldAccent]
        }
    }
    
    private var folkloreScale: CGFloat {
        switch animation {
        case .glow, .sparkle: return 1.0 + animationValue * 0.2
        case .pulse: return 0.8 + animationValue * 0.4
        case .float: return 1.0 + sin(animationValue) * 0.1
        default: return 1.0
        }
    }
    
    private var folkloreOpacity: Double {
        switch animation {
        case .glow: return 0.3 + animationValue * 0.5
        case .sparkle, .pulse: return 0.5 + sin(animationValue) * 0.3
        default: return 0.6
        }
    }
    
    private func performBadgeAnimation() {
        switch animation {
        case .glow:
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                animationValue = 1.0
            }
        case .sparkle:
            withAnimation(.linear(duration: 0.8).repeatForever(autoreverses: false)) {
                animationValue = .pi * 2
            }
        case .pulse:
            withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                animationValue = 1.0
            }
        case .float:
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                animationValue = .pi * 2
            }
        default:
            break
        }
    }
}

// MARK: - Preview

#Preview("Romanian Achievement") {
    let sampleAchievement = RomanianAchievement(
        type: .cultural,
        category: .folkloreLearning,
        difficulty: .gold,
        culturalRegion: .transylvania,
        titleKey: "Maestru al Tradițiilor",
        descriptionKey: "Ai demonstrat o înțelegere profundă a tradițiilor românești prin jocul autentic de Septica",
        culturalContextKey: "În cultura română, maestria la cărți nu înseamnă doar să câștigi, ci să înțelegi înțelepciunea strămoșilor noștri",
        requirements: [.folktaleLearned(count: 15)],
        targetValue: 15,
        experiencePoints: 100,
        culturalKnowledgePoints: 75,
        badge: AchievementBadge(
            iconName: "crown.fill",
            colorScheme: .cultural,
            animation: .glow,
            culturalSymbol: "🏰"
        )
    )
    
    AchievementNotificationView(
        achievement: sampleAchievement,
        onDismiss: { }
    )
}
