//
//  RomanianPlayerAvatarView.swift
//  Septica
//
//  Romanian avatar display component inspired by Shuffle Cats character design
//  Displays circular player avatars with cultural frames and progression indicators
//

import SwiftUI

/// Romanian player avatar view with circular frame design (Inspired by Shuffle Cats)
struct RomanianPlayerAvatarView: View {
    let avatar: RomanianCharacterAvatar
    let frame: AvatarFrame
    let level: Int
    let arena: RomanianArena
    let isCurrentPlayer: Bool
    
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            // Outer glow for current player (Shuffle Cats style)
            if isCurrentPlayer {
                Circle()
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [.blue, .cyan]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 3
                    )
                    .frame(width: 90, height: 90)
                    .scaleEffect(isAnimating ? 1.1 : 1.0)
                    .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: isAnimating)
            }
            
            // Avatar frame with Romanian cultural styling
            Circle()
                .stroke(
                    Color(hex: frame.frameColor),
                    lineWidth: 4
                )
                .frame(width: 80, height: 80)
                .shadow(color: .black.opacity(0.3), radius: 4, x: 2, y: 2)
            
            // Avatar character image
            ZStack {
                // Background circle for character
                Circle()
                    .fill(
                        RadialGradient(
                            gradient: Gradient(colors: [
                                Color(hex: arena.primaryColor).opacity(0.3),
                                Color(hex: arena.primaryColor).opacity(0.1)
                            ]),
                            center: .center,
                            startRadius: 10,
                            endRadius: 40
                        )
                    )
                    .frame(width: 70, height: 70)
                
                // Character avatar (placeholder for now - would be actual images)
                Image(systemName: avatar.systemImageName)
                    .font(.title)
                    .foregroundColor(Color(hex: arena.primaryColor))
                    .frame(width: 50, height: 50)
            }
            
            // Level indicator (Shuffle Cats style)
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Text("\(level)")
                        .font(.caption.bold())
                        .foregroundColor(.white)
                        .padding(6)
                        .background(
                            Circle()
                                .fill(Color(hex: arena.accentColor))
                                .shadow(color: .black.opacity(0.4), radius: 2, x: 1, y: 1)
                        )
                        .offset(x: 15, y: 15)
                }
            }
            .frame(width: 80, height: 80)
            
            // Arena progression indicator
            if level >= 10 {
                VStack {
                    HStack {
                        Spacer()
                        Image(systemName: "crown.fill")
                            .font(.caption2)
                            .foregroundColor(.yellow)
                            .offset(x: 15, y: -15)
                    }
                    Spacer()
                }
                .frame(width: 80, height: 80)
            }
        }
        .onAppear {
            if isCurrentPlayer {
                isAnimating = true
            }
        }
    }
}

// MARK: - Extensions for Avatar System

extension RomanianCharacterAvatar {
    /// System image name for placeholder (until we have custom artwork)
    var systemImageName: String {
        switch self {
        case .traditionalPlayer: return "person.fill"
        case .folkMusician: return "music.note"
        case .villageElder: return "figure.walk"
        case .transylvanianNoble: return "crown.fill"
        case .moldovanScholar: return "book.fill"
        case .wallachianWarrior: return "shield.fill"
        case .carpathianShepherd: return "mountain.2.fill"
        case .danubianFisherman: return "fish.fill"
        case .bucovinianArtisan: return "hammer.fill"
        case .dobrudjanMerchant: return "cart.fill"
        }
    }
}

extension RomanianArena {
    /// Primary color for this arena (hex string)
    var primaryColor: String {
        switch self {
        case .sateImarica: return "#8B4513" // Saddle brown - village wood
        case .satuMihai: return "#228B22" // Forest green - nature
        case .orasulBrara: return "#FF6347" // Tomato red - folk festival
        case .orasulBacau: return "#4169E1" // Royal blue - artisan crafts
        case .orasulCluj: return "#8A2BE2" // Blue violet - Transylvanian noble
        case .orasulConstanta: return "#008B8B" // Dark cyan - Black Sea
        case .orasulIasi: return "#DC143C" // Crimson - cultural center
        case .orasulTimisoara: return "#FFD700" // Gold - historic importance
        case .orasulBrasov: return "#2F4F4F" // Dark slate gray - mountain fortress
        case .orasulSibiu: return "#800080" // Purple - European cultural capital
        case .marealeBucuresti: return "#B22222" // Fire brick - royal capital
        }
    }
    
    /// Accent color for UI elements
    var accentColor: String {
        switch self {
        case .sateImarica: return "#D2691E" // Chocolate
        case .satuMihai: return "#32CD32" // Lime green
        case .orasulBrara: return "#FF7F50" // Coral
        case .orasulBacau: return "#6495ED" // Cornflower blue
        case .orasulCluj: return "#9932CC" // Dark orchid
        case .orasulConstanta: return "#20B2AA" // Light sea green
        case .orasulIasi: return "#FF1493" // Deep pink
        case .orasulTimisoara: return "#FFA500" // Orange
        case .orasulBrasov: return "#708090" // Slate gray
        case .orasulSibiu: return "#9370DB" // Medium purple
        case .marealeBucuresti: return "#CD5C5C" // Indian red
        }
    }
}

extension Color {
    /// Initialize Color from hex string
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Preview Support

#if DEBUG
struct RomanianPlayerAvatarView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            // Traditional player
            RomanianPlayerAvatarView(
                avatar: .traditionalPlayer,
                frame: .woodenFrame,
                level: 5,
                arena: .sateImarica,
                isCurrentPlayer: true
            )
            
            // Advanced player
            RomanianPlayerAvatarView(
                avatar: .transylvanianNoble,
                frame: .goldenFrame,
                level: 25,
                arena: .orasulBrasov,
                isCurrentPlayer: false
            )
            
            // Master player
            RomanianPlayerAvatarView(
                avatar: .wallachianWarrior,
                frame: .legendaryFrame,
                level: 50,
                arena: .marealeBucuresti,
                isCurrentPlayer: false
            )
        }
        .padding()
        .background(Color.gray.opacity(0.1))
    }
}
#endif