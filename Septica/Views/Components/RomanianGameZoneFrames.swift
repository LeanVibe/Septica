//
//  RomanianGameZoneFrames.swift
//  Septica
//
//  Visual zone separation system inspired by Shuffle Cats
//  Romanian ornate borders and frames for game areas
//

import SwiftUI

/// Romanian-styled game zone frames for visual separation
struct RomanianGameZoneFrames {
    
    /// Player hand zone frame with Romanian folk art styling
    struct PlayerHandFrame<Content: View>: View {
        let content: Content
        
        init(@ViewBuilder content: () -> Content) {
            self.content = content()
        }
        
        var body: some View {
            VStack(spacing: 8) {
                // Romanian ornate top border
                RomanianOrnatePatternSystem.RomanianBorderPattern(
                    width: 350,
                    height: 8,
                    color: RomanianColors.goldAccent
                )
                
                content
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        RomanianColors.primaryBlue.opacity(0.1),
                                        RomanianColors.primaryYellow.opacity(0.05)
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(
                                        LinearGradient(
                                            colors: [
                                                RomanianColors.goldAccent,
                                                RomanianColors.primaryYellow
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 2
                                    )
                            )
                    )
                
                // Romanian decorative bottom elements
                HStack(spacing: 20) {
                    RomanianOrnatePatternSystem.RomanianFlowerPattern(
                        size: 12,
                        color: RomanianColors.primaryRed.opacity(0.8)
                    )
                    
                    Text("Mâna Jucătorului")
                        .font(.caption.weight(.medium))
                        .foregroundColor(RomanianColors.goldAccent)
                        .shadow(color: .black.opacity(0.3), radius: 1, x: 0, y: 1)
                    
                    RomanianOrnatePatternSystem.RomanianFlowerPattern(
                        size: 12,
                        color: RomanianColors.primaryRed.opacity(0.8)
                    )
                }
            }
        }
    }
    
    /// Game table zone frame with elaborate Romanian styling
    struct GameTableFrame<Content: View>: View {
        let content: Content
        let isActive: Bool
        
        init(isActive: Bool = false, @ViewBuilder content: () -> Content) {
            self.isActive = isActive
            self.content = content()
        }
        
        var body: some View {
            VStack(spacing: 12) {
                // Ornate top frame with Romanian patterns
                HStack {
                    RomanianOrnatePatternSystem.RomanianCrossPattern(
                        size: 16,
                        color: RomanianColors.goldAccent
                    )
                    
                    Spacer()
                    
                    Text("Masa de Joc")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    RomanianColors.goldAccent,
                                    RomanianColors.primaryYellow
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .shadow(color: .black.opacity(0.5), radius: 2, x: 1, y: 1)
                    
                    Spacer()
                    
                    RomanianOrnatePatternSystem.RomanianCrossPattern(
                        size: 16,
                        color: RomanianColors.goldAccent
                    )
                }
                
                content
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        RomanianColors.primaryRed.opacity(0.15),
                                        RomanianColors.primaryYellow.opacity(0.1),
                                        RomanianColors.primaryBlue.opacity(0.05)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .overlay(
                                // Ornate border with Romanian patterns
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(
                                        LinearGradient(
                                            colors: isActive ? [
                                                RomanianColors.goldAccent,
                                                RomanianColors.primaryYellow,
                                                RomanianColors.goldAccent
                                            ] : [
                                                RomanianColors.primaryBlue.opacity(0.6),
                                                RomanianColors.primaryYellow.opacity(0.4)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: isActive ? 3 : 2
                                    )
                            )
                            .overlay(
                                // Corner decorations
                                VStack {
                                    HStack {
                                        RomanianOrnatePatternSystem.RomanianDiamondPattern(
                                            size: 10,
                                            color: RomanianColors.goldAccent.opacity(0.7)
                                        )
                                        .offset(x: -8, y: -8)
                                        
                                        Spacer()
                                        
                                        RomanianOrnatePatternSystem.RomanianFlowerPattern(
                                            size: 10,
                                            color: RomanianColors.primaryRed.opacity(0.7)
                                        )
                                        .offset(x: 8, y: -8)
                                    }
                                    
                                    Spacer()
                                    
                                    HStack {
                                        RomanianOrnatePatternSystem.RomanianFlowerPattern(
                                            size: 10,
                                            color: RomanianColors.primaryBlue.opacity(0.7)
                                        )
                                        .offset(x: -8, y: 8)
                                        
                                        Spacer()
                                        
                                        RomanianOrnatePatternSystem.RomanianDiamondPattern(
                                            size: 10,
                                            color: RomanianColors.goldAccent.opacity(0.7)
                                        )
                                        .offset(x: 8, y: 8)
                                    }
                                }
                            )
                    )
                    .scaleEffect(isActive ? 1.02 : 1.0)
                    .animation(.easeInOut(duration: 0.3), value: isActive)
                
                // Bottom decorative elements
                RomanianOrnatePatternSystem.RomanianBorderPattern(
                    width: 200,
                    height: 6,
                    color: RomanianColors.primaryBlue.opacity(0.6)
                )
            }
        }
    }
    
    /// Opponent area frame with Romanian styling
    struct OpponentAreaFrame<Content: View>: View {
        let content: Content
        
        init(@ViewBuilder content: () -> Content) {
            self.content = content()
        }
        
        var body: some View {
            VStack(spacing: 8) {
                // Romanian decorative top elements
                HStack(spacing: 20) {
                    RomanianOrnatePatternSystem.RomanianCrossPattern(
                        size: 12,
                        color: RomanianColors.primaryBlue.opacity(0.8)
                    )
                    
                    Text("Adversarul")
                        .font(.caption.weight(.medium))
                        .foregroundColor(RomanianColors.primaryBlue.opacity(0.9))
                        .shadow(color: .black.opacity(0.3), radius: 1, x: 0, y: 1)
                    
                    RomanianOrnatePatternSystem.RomanianCrossPattern(
                        size: 12,
                        color: RomanianColors.primaryBlue.opacity(0.8)
                    )
                }
                
                content
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        RomanianColors.primaryRed.opacity(0.1),
                                        RomanianColors.primaryBlue.opacity(0.05)
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(
                                        LinearGradient(
                                            colors: [
                                                RomanianColors.primaryBlue,
                                                RomanianColors.primaryRed.opacity(0.7)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 2
                                    )
                            )
                    )
                
                // Romanian ornate bottom border
                RomanianOrnatePatternSystem.RomanianBorderPattern(
                    width: 350,
                    height: 8,
                    color: RomanianColors.primaryBlue.opacity(0.6)
                )
            }
        }
    }
    
    /// Side panel frame for score/deck areas
    struct SidePanelFrame<Content: View>: View {
        let content: Content
        let title: String
        
        init(title: String, @ViewBuilder content: () -> Content) {
            self.title = title
            self.content = content()
        }
        
        var body: some View {
            VStack(spacing: 8) {
                // Panel title with Romanian styling
                Text(title)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                RomanianColors.goldAccent,
                                RomanianColors.primaryYellow
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .shadow(color: .black.opacity(0.4), radius: 1, x: 0, y: 1)
                
                content
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        RomanianColors.primaryYellow.opacity(0.1),
                                        RomanianColors.goldAccent.opacity(0.05)
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(
                                        RomanianColors.goldAccent.opacity(0.6),
                                        lineWidth: 1.5
                                    )
                            )
                    )
                
                // Small decorative element
                RomanianOrnatePatternSystem.RomanianDiamondPattern(
                    size: 8,
                    color: RomanianColors.primaryRed.opacity(0.6)
                )
            }
        }
    }
}

// MARK: - Preview

struct RomanianGameZoneFrames_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            // Opponent area example
            RomanianGameZoneFrames.OpponentAreaFrame {
                HStack {
                    Text("Opponent Cards")
                    Spacer()
                    Text("Score: 5")
                }
            }
            
            // Game table example
            RomanianGameZoneFrames.GameTableFrame(isActive: true) {
                Text("Game Table Area")
                    .frame(width: 300, height: 150)
            }
            
            // Player hand example
            RomanianGameZoneFrames.PlayerHandFrame {
                HStack {
                    Text("Player Cards")
                    Spacer()
                    Text("Score: 3")
                }
            }
        }
        .padding()
        .background(Color.green.opacity(0.3))
        .previewLayout(.sizeThatFits)
    }
}