//
//  PremiumCardEffects.swift
//  Septica
//
//  High production value card visual effects for premium gaming experience
//  Romanian cultural elements with professional polish
//

import SwiftUI

/// Premium selection glow effect for cards with Romanian cultural styling
struct PremiumSelectionEffect: ViewModifier {
    let isSelected: Bool
    let isPlayable: Bool
    let isSpecialCard: Bool // For 7s and point cards
    
    @State private var glowAnimation = false
    @State private var specialCardPulse = false
    
    func body(content: Content) -> some View {
        content
            .overlay(
                // Premium selection glow
                RoundedRectangle(cornerRadius: 8)
                    .stroke(
                        LinearGradient(
                            colors: isSelected ? [
                                RomanianColors.goldAccent.opacity(0.9),
                                RomanianColors.primaryYellow,
                                RomanianColors.goldAccent.opacity(0.9)
                            ] : [Color.clear],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: isSelected ? 4 : 0
                    )
                    .scaleEffect(isSelected ? (glowAnimation ? 1.05 : 1.02) : 1.0)
                    .opacity(isSelected ? (glowAnimation ? 0.9 : 1.0) : 0)
                    .animation(
                        isSelected ? 
                            .easeInOut(duration: 1.2).repeatForever(autoreverses: true) :
                            .easeInOut(duration: 0.3),
                        value: glowAnimation
                    )
            )
            .overlay(
                // Playable card indicator
                RoundedRectangle(cornerRadius: 8)
                    .stroke(
                        RomanianColors.countrysideGreen.opacity(0.6),
                        lineWidth: isPlayable && !isSelected ? 2 : 0
                    )
                    .opacity(isPlayable && !isSelected ? 0.8 : 0)
            )
            .overlay(
                // Special card (7s) mystical effect
                RoundedRectangle(cornerRadius: 8)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.orange.opacity(0.8),
                                Color.yellow.opacity(0.6),
                                Color.orange.opacity(0.8)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: isSpecialCard ? 2 : 0
                    )
                    .scaleEffect(isSpecialCard ? (specialCardPulse ? 1.03 : 1.0) : 1.0)
                    .opacity(isSpecialCard ? (specialCardPulse ? 0.7 : 0.9) : 0)
                    .animation(
                        isSpecialCard ?
                            .easeInOut(duration: 2.0).repeatForever(autoreverses: true) :
                            .easeInOut(duration: 0.3),
                        value: specialCardPulse
                    )
            )
            .shadow(
                color: isSelected ? RomanianColors.goldAccent.opacity(0.4) : Color.clear,
                radius: isSelected ? 12 : 0,
                x: 0,
                y: isSelected ? 6 : 0
            )
            .onAppear {
                glowAnimation = true
                specialCardPulse = true
            }
    }
}

/// Premium depth and lighting effect for cards
struct PremiumCardDepth: ViewModifier {
    let isLifted: Bool
    let isPressed: Bool
    
    func body(content: Content) -> some View {
        content
            .shadow(
                color: Color.black.opacity(0.3),
                radius: isLifted ? 8 : 4,
                x: 0,
                y: isLifted ? 8 : 4
            )
            .shadow(
                color: RomanianColors.primaryBlue.opacity(0.1),
                radius: isLifted ? 12 : 6,
                x: 0,
                y: isLifted ? 12 : 6
            )
            .scaleEffect(
                isPressed ? 0.95 : 
                isLifted ? 1.05 : 1.0
            )
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isLifted)
            .animation(.easeInOut(duration: 0.15), value: isPressed)
    }
}

/// Romanian traditional pattern overlay for premium visual depth
struct RomanianPatternOverlay: ViewModifier {
    let intensity: Double = 0.1
    
    func body(content: Content) -> some View {
        content
            .overlay(
                // Subtle Romanian folk pattern
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        LinearGradient(
                            colors: [
                                RomanianColors.goldAccent.opacity(intensity * 0.3),
                                Color.clear,
                                RomanianColors.primaryYellow.opacity(intensity * 0.2),
                                Color.clear
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .blendMode(.overlay)
            )
    }
}

/// Premium card interaction feedback system
struct CardInteractionFeedback: ViewModifier {
    let isHovered: Bool
    let isPlayable: Bool
    
    @State private var hoverScale = false
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isHovered && isPlayable ? (hoverScale ? 1.08 : 1.05) : 1.0)
            .animation(
                isHovered ? 
                    .easeInOut(duration: 0.8).repeatForever(autoreverses: true) :
                    .easeInOut(duration: 0.3),
                value: hoverScale
            )
            .onAppear {
                hoverScale = true
            }
    }
}

// MARK: - View Extensions

extension View {
    /// Apply premium selection effect with Romanian cultural styling
    func premiumSelection(
        isSelected: Bool,
        isPlayable: Bool = false,
        isSpecialCard: Bool = false
    ) -> some View {
        modifier(PremiumSelectionEffect(
            isSelected: isSelected,
            isPlayable: isPlayable,
            isSpecialCard: isSpecialCard
        ))
    }
    
    /// Apply premium card depth and lighting
    func premiumDepth(isLifted: Bool, isPressed: Bool = false) -> some View {
        modifier(PremiumCardDepth(isLifted: isLifted, isPressed: isPressed))
    }
    
    /// Apply subtle Romanian traditional pattern overlay
    func romanianPatternOverlay() -> some View {
        modifier(RomanianPatternOverlay())
    }
    
    /// Apply premium card interaction feedback
    func cardInteractionFeedback(isHovered: Bool, isPlayable: Bool) -> some View {
        modifier(CardInteractionFeedback(isHovered: isHovered, isPlayable: isPlayable))
    }
}