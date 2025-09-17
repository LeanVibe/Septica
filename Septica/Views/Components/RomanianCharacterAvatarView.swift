//
//  RomanianCharacterAvatarView.swift
//  Septica
//
//  Romanian character avatar view component for Shuffle Cats-inspired UI
//  Features authentic Romanian cultural character representations
//

import SwiftUI

/// Romanian character avatar view with Shuffle Cats-inspired styling
struct RomanianCharacterAvatarView: View {
    let character: RomanianCharacterAvatar
    let size: AvatarSize
    let showBorder: Bool
    let glowColor: Color
    
    enum AvatarSize {
        case small, medium, large
        
        var diameter: CGFloat {
            switch self {
            case .small: return 40
            case .medium: return 80
            case .large: return 120
            }
        }
        
        var borderWidth: CGFloat {
            switch self {
            case .small: return 2
            case .medium: return 3
            case .large: return 4
            }
        }
    }
    
    init(character: RomanianCharacterAvatar, size: AvatarSize = .medium, showBorder: Bool = true, glowColor: Color = RomanianColors.goldAccent) {
        self.character = character
        self.size = size
        self.showBorder = showBorder
        self.glowColor = glowColor
    }
    
    var body: some View {
        ZStack {
            // Avatar background with Romanian pattern
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            character.backgroundColor.opacity(0.8),
                            character.backgroundColor.opacity(0.6),
                            Color.black.opacity(0.2)
                        ],
                        center: .center,
                        startRadius: 10,
                        endRadius: size.diameter / 2
                    )
                )
            
            // Character representation
            characterContent
            
            // Border and glow effects
            if showBorder {
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [
                                glowColor,
                                glowColor.opacity(0.6),
                                glowColor
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: size.borderWidth
                    )
                    .shadow(color: glowColor.opacity(0.6), radius: 8, x: 0, y: 0)
            }
        }
        .frame(width: size.diameter, height: size.diameter)
    }
    
    @ViewBuilder
    private var characterContent: some View {
        switch character {
        case .traditionalPlayer:
            traditionalPlayerAvatar
        case .villageElder:
            villageElderAvatar
        case .folkMusician:
            folkMusicianAvatar
        case .carpathianShepherd:
            carpathianShepherdAvatar
        case .transylvanianNoble:
            transylvanianNobleAvatar
        case .moldovanScholar:
            moldovanScholarAvatar
        case .wallachianWarrior:
            wallachianWarriorAvatar
        case .danubianFisherman:
            danubianFishermanAvatar
        case .bucovinianArtisan:
            bucovinianArtisanAvatar
        case .dobrudjanMerchant:
            dobrudjanMerchantAvatar
        }
    }
    
    // MARK: - Character Avatars
    
    private var traditionalPlayerAvatar: some View {
        VStack(spacing: 2) {
            Text("🎭")
                .font(.system(size: size.diameter * 0.35))
            if size != .small {
                Text("JUC")
                    .font(.system(size: size.diameter * 0.12, weight: .bold))
                    .foregroundColor(.white)
            }
        }
    }
    
    private var villageElderAvatar: some View {
        VStack(spacing: 2) {
            Text("👴🏻")
                .font(.system(size: size.diameter * 0.35))
            if size != .small {
                Text("MOȘ")
                    .font(.system(size: size.diameter * 0.12, weight: .bold))
                    .foregroundColor(.white)
            }
        }
    }
    
    private var folkMusicianAvatar: some View {
        VStack(spacing: 2) {
            Text("🎻")
                .font(.system(size: size.diameter * 0.35))
            if size != .small {
                Text("MUZ")
                    .font(.system(size: size.diameter * 0.12, weight: .bold))
                    .foregroundColor(.white)
            }
        }
    }
    
    private var carpathianShepherdAvatar: some View {
        VStack(spacing: 2) {
            Text("🐑")
                .font(.system(size: size.diameter * 0.35))
            if size != .small {
                Text("CIO")
                    .font(.system(size: size.diameter * 0.12, weight: .bold))
                    .foregroundColor(.white)
            }
        }
    }
    
    private var transylvanianNobleAvatar: some View {
        VStack(spacing: 2) {
            Text("👑")
                .font(.system(size: size.diameter * 0.35))
            if size != .small {
                Text("NOB")
                    .font(.system(size: size.diameter * 0.12, weight: .bold))
                    .foregroundColor(.white)
            }
        }
    }
    
    private var moldovanScholarAvatar: some View {
        VStack(spacing: 2) {
            Text("📚")
                .font(.system(size: size.diameter * 0.35))
            if size != .small {
                Text("SCH")
                    .font(.system(size: size.diameter * 0.12, weight: .bold))
                    .foregroundColor(.white)
            }
        }
    }
    
    private var wallachianWarriorAvatar: some View {
        VStack(spacing: 2) {
            Text("⚔️")
                .font(.system(size: size.diameter * 0.35))
            if size != .small {
                Text("WAR")
                    .font(.system(size: size.diameter * 0.12, weight: .bold))
                    .foregroundColor(.white)
            }
        }
    }
    
    private var danubianFishermanAvatar: some View {
        VStack(spacing: 2) {
            Text("🎣")
                .font(.system(size: size.diameter * 0.35))
            if size != .small {
                Text("FIS")
                    .font(.system(size: size.diameter * 0.12, weight: .bold))
                    .foregroundColor(.white)
            }
        }
    }
    
    private var bucovinianArtisanAvatar: some View {
        VStack(spacing: 2) {
            Text("🎨")
                .font(.system(size: size.diameter * 0.35))
            if size != .small {
                Text("ART")
                    .font(.system(size: size.diameter * 0.12, weight: .bold))
                    .foregroundColor(.white)
            }
        }
    }
    
    private var dobrudjanMerchantAvatar: some View {
        VStack(spacing: 2) {
            Text("🏪")
                .font(.system(size: size.diameter * 0.35))
            if size != .small {
                Text("MER")
                    .font(.system(size: size.diameter * 0.12, weight: .bold))
                    .foregroundColor(.white)
            }
        }
    }
}

// MARK: - Character Avatar Extensions

extension RomanianCharacterAvatar {
    var backgroundColor: Color {
        switch self {
        case .traditionalPlayer:
            return RomanianColors.primaryBlue
        case .villageElder:
            return RomanianColors.primaryRed
        case .folkMusician:
            return RomanianColors.primaryYellow
        case .carpathianShepherd:
            return Color.brown
        case .transylvanianNoble:
            return RomanianColors.goldAccent
        case .moldovanScholar:
            return Color.purple
        case .wallachianWarrior:
            return Color.red
        case .danubianFisherman:
            return Color.blue
        case .bucovinianArtisan:
            return Color.orange
        case .dobrudjanMerchant:
            return Color.green
        }
    }
}

// MARK: - Preview

struct RomanianCharacterAvatarView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            HStack(spacing: 15) {
                RomanianCharacterAvatarView(
                    character: .traditionalPlayer,
                    size: .small,
                    glowColor: RomanianColors.primaryBlue
                )
                
                RomanianCharacterAvatarView(
                    character: .villageElder,
                    size: .medium,
                    glowColor: RomanianColors.primaryRed
                )
                
                RomanianCharacterAvatarView(
                    character: .folkMusician,
                    size: .large,
                    glowColor: RomanianColors.primaryYellow
                )
            }
            
            HStack(spacing: 15) {
                RomanianCharacterAvatarView(
                    character: .carpathianShepherd,
                    size: .medium,
                    glowColor: Color.brown
                )
                
                RomanianCharacterAvatarView(
                    character: .transylvanianNoble,
                    size: .medium,
                    glowColor: RomanianColors.goldAccent
                )
                
                RomanianCharacterAvatarView(
                    character: .moldovanScholar,
                    size: .medium,
                    glowColor: Color.purple
                )
            }
        }
        .padding()
        .background(Color.black)
        .previewLayout(.sizeThatFits)
    }
}