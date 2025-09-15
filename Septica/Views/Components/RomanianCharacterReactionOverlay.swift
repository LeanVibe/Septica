//
//  RomanianCharacterReactionOverlay.swift
//  Septica
//
//  Quick character reaction overlay for immediate feedback
//  Provides contextual Romanian character guidance during gameplay
//

import SwiftUI

/// Quick character reaction overlay for immediate gameplay feedback
struct RomanianCharacterReactionOverlay: View {
    let character: RomanianCharacterType
    let reaction: CharacterReaction
    let romanianPhrase: String
    let englishTranslation: String
    @Binding var isVisible: Bool
    
    @State private var animationProgress: CGFloat = 0
    @State private var bubbleScale: CGFloat = 0
    
    var body: some View {
        if isVisible {
            ZStack {
                // Semi-transparent background
                Color.black.opacity(0.1)
                    .ignoresSafeArea()
                    .onTapGesture {
                        dismissOverlay()
                    }
                
                // Character reaction bubble
                VStack(spacing: 16) {
                    // Character icon with animation
                    characterIconView
                    
                    // Speech bubble with Romanian phrase
                    speechBubbleView
                        .scaleEffect(bubbleScale)
                        .animation(.spring(response: 0.6, dampingFraction: 0.7), value: bubbleScale)
                }
                .opacity(animationProgress)
                .offset(y: (1 - animationProgress) * 20)
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: animationProgress)
            }
            .transition(.asymmetric(
                insertion: .scale.combined(with: .opacity),
                removal: .opacity
            ))
            .onAppear {
                appearAnimation()
                
                // Auto-dismiss after reaction duration
                DispatchQueue.main.asyncAfter(deadline: .now() + reaction.animationDuration) {
                    dismissOverlay()
                }
            }
        }
    }
    
    @ViewBuilder
    private var characterIconView: some View {
        ZStack {
            // Character background with cultural colors
            Circle()
                .fill(characterGradient)
                .frame(width: 80, height: 80)
                .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
            
            // Character icon
            Image(systemName: characterIcon)
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(.white)
                .scaleEffect(animationProgress * 1.2)
        }
        .scaleEffect(reactionScale)
        .animation(reactionAnimation, value: animationProgress)
    }
    
    @ViewBuilder
    private var speechBubbleView: some View {
        VStack(spacing: 8) {
            // Romanian phrase
            Text(romanianPhrase)
                .font(.headline.bold())
                .foregroundColor(.black)
                .multilineTextAlignment(.center)
            
            // English translation
            Text(englishTranslation)
                .font(.subheadline)
                .foregroundColor(.gray)
                .italic()
                .multilineTextAlignment(.center)
            
            // Cultural note
            Text(character.rawValue)
                .font(.caption2.bold())
                .foregroundColor(RomanianColors.primaryBlue)
                .padding(.top, 4)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
        )
        .overlay(
            // Speech bubble pointer
            Triangle()
                .fill(Color.white)
                .frame(width: 16, height: 12)
                .rotationEffect(.degrees(180))
                .offset(y: -24)
        )
    }
    
    private var characterGradient: LinearGradient {
        switch character {
        case .oldWiseMan:
            return LinearGradient(
                colors: [RomanianColors.primaryBlue, RomanianColors.primaryBlue.opacity(0.8)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .playfulGirl:
            return LinearGradient(
                colors: [RomanianColors.primaryRed, RomanianColors.primaryRed.opacity(0.8)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .mountainShepherd:
            return LinearGradient(
                colors: [RomanianColors.countrysideGreen, RomanianColors.countrysideGreen.opacity(0.8)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .villageTeacher:
            return LinearGradient(
                colors: [RomanianColors.primaryYellow, RomanianColors.goldAccent],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .folkDancer:
            return LinearGradient(
                colors: [RomanianColors.embroideryRed, RomanianColors.embroideryRed.opacity(0.8)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .cardMaster:
            return LinearGradient(
                colors: [RomanianColors.goldAccent, RomanianColors.primaryYellow],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
    
    private var characterIcon: String {
        switch character {
        case .oldWiseMan:
            return "figure.2.and.child.holdinghands"
        case .playfulGirl:
            return "figure.child"
        case .mountainShepherd:
            return "mountain.2"
        case .villageTeacher:
            return "book.fill"
        case .folkDancer:
            return "figure.dance"
        case .cardMaster:
            return "suit.spade.fill"
        }
    }
    
    private var reactionScale: CGFloat {
        switch reaction {
        case .victory, .celebration:
            return 1.2
        case .goodMove:
            return 1.1
        case .thinking:
            return 1.0
        case .encouragement:
            return 1.05
        default:
            return 1.0
        }
    }
    
    private var reactionAnimation: Animation {
        switch reaction {
        case .victory, .celebration:
            return .easeInOut(duration: 0.8).repeatCount(2, autoreverses: true)
        case .goodMove:
            return .spring(response: 0.4, dampingFraction: 0.6)
        case .thinking:
            return .easeInOut(duration: 2.0).repeatForever(autoreverses: true)
        default:
            return .spring(response: 0.5, dampingFraction: 0.7)
        }
    }
    
    private func appearAnimation() {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            animationProgress = 1.0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                bubbleScale = 1.0
            }
        }
    }
    
    private func dismissOverlay() {
        withAnimation(.easeOut(duration: 0.3)) {
            animationProgress = 0
            bubbleScale = 0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            isVisible = false
        }
    }
}

/// Triangle shape for speech bubble pointer
struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.minY))
        
        return path
    }
}

// MARK: - Character Reaction Manager

/// Manages character reactions throughout the game
class CharacterReactionManager: ObservableObject {
    @Published var showReactionOverlay = false
    @Published var currentCharacter: RomanianCharacterType = .oldWiseMan
    @Published var currentReaction: CharacterReaction = .encouragement
    @Published var currentPhrase: String = ""
    @Published var currentTranslation: String = ""
    
    /// Show a quick character reaction overlay
    func showQuickReaction(
        character: RomanianCharacterType = .oldWiseMan,
        reaction: CharacterReaction,
        romanianPhrase: String,
        englishTranslation: String
    ) {
        currentCharacter = character
        currentReaction = reaction
        currentPhrase = romanianPhrase
        currentTranslation = englishTranslation
        
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            showReactionOverlay = true
        }
    }
    
    /// Show contextual teaching moment
    func showTeachingMoment(for gameEvent: CharacterReactionEvent) {
        let character: RomanianCharacterType
        let reaction: CharacterReaction
        let phrase: String
        let translation: String
        
        switch gameEvent {
        case .firstSevenPlayed:
            character = .cardMaster
            reaction = .wisdom
            phrase = "Șapte învinge tot! Această carte este specială în jocul nostru tradițional."
            translation = "Seven beats all! This card is special in our traditional game."
            
        case .eightPlayedAtRightTime:
            character = .villageTeacher
            reaction = .goodMove
            phrase = "Perfect! Opt învinge când avem trei cărți pe masă!"
            translation = "Perfect! Eight wins when we have three cards on the table!"
            
        case .pointCardCaptured:
            character = .oldWiseMan
            reaction = .encouragement
            phrase = "Bine ai prins cartea cu puncte! Așa se adună victoria!"
            translation = "Good job catching the point card! That's how victory is built!"
            
        case .strategicThinking:
            character = .mountainShepherd
            reaction = .thinking
            phrase = "Gândește-te bine... Ciobanul nu se grăbește niciodată."
            translation = "Think carefully... The shepherd never rushes."
            
        case .gameWon:
            character = .folkDancer
            reaction = .celebration
            phrase = "Sărbătorim! Ai învins cu înțelepciune românească!"
            translation = "Let's celebrate! You won with Romanian wisdom!"
        }
        
        showQuickReaction(
            character: character,
            reaction: reaction,
            romanianPhrase: phrase,
            englishTranslation: translation
        )
    }
}

/// Game events that trigger character reactions (UI overlay)
enum CharacterReactionEvent {
    case firstSevenPlayed
    case eightPlayedAtRightTime
    case pointCardCaptured
    case strategicThinking
    case gameWon
}
