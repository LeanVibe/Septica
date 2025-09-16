//
//  RomanianCharacterSystem.swift
//  Septica
//
//  Animated character reactions and expressions system for enhanced gameplay
//  Features Romanian cultural characters with authentic expressions and behaviors
//

import SwiftUI
import Observation
import Combine

/// Romanian character archetypes with authentic cultural personalities
enum RomanianCharacterType: String, CaseIterable {
    case oldWiseMan = "Moșu Înțelept"           // Wise Old Man
    case playfulGirl = "Fetița Jucăușă"         // Playful Girl
    case mountainShepherd = "Ciobanu Munților"   // Mountain Shepherd
    case villageTeacher = "Dascălu Satului"     // Village Teacher
    case folkDancer = "Dansatoarea Populară"   // Folk Dancer
    case cardMaster = "Meșteru Cărților"        // Card Master
    
    var culturalBackground: String {
        switch self {
        case .oldWiseMan:
            return "Traditional Romanian grandfather figure, keeper of folk wisdom and card game traditions"
        case .playfulGirl:
            return "Young Romanian girl in traditional costume, representing joy and cultural continuity"
        case .mountainShepherd:
            return "Carpathian mountain shepherd, embodying patience and strategic thinking"
        case .villageTeacher:
            return "Village educator, preserving Romanian language and cultural knowledge"
        case .folkDancer:
            return "Traditional Romanian folk dancer, bringing celebration and cultural expression"
        case .cardMaster:
            return "Expert card player, master of Septica traditions and strategies"
        }
    }
    
    var personalityTraits: [String] {
        switch self {
        case .oldWiseMan:
            return ["Patient", "Thoughtful", "Strategic", "Kind", "Traditional"]
        case .playfulGirl:
            return ["Energetic", "Joyful", "Quick", "Creative", "Optimistic"]
        case .mountainShepherd:
            return ["Calm", "Observant", "Steady", "Reliable", "Nature-connected"]
        case .villageTeacher:
            return ["Intellectual", "Encouraging", "Precise", "Educational", "Supportive"]
        case .folkDancer:
            return ["Expressive", "Rhythmic", "Celebratory", "Graceful", "Cultural"]
        case .cardMaster:
            return ["Confident", "Skilled", "Competitive", "Respectful", "Masterful"]
        }
    }
}

/// Character reaction types for different game events
enum CharacterReaction: String, CaseIterable {
    case victory = "Victorie"
    case defeat = "Înfrângere"
    case goodMove = "Mișcare Bună"
    case badMove = "Mișcare Slabă"
    case thinking = "Gândire"
    case surprise = "Surpriză"
    case celebration = "Sărbătoare"
    case encouragement = "Încurajare"
    case wisdom = "Înțelepciune"
    case playfulTease = "Glumă Prietenoasă"
    case respect = "Respect"
    case disappointment = "Dezamăgire"
    
    var animationDuration: Double {
        switch self {
        case .victory, .celebration:
            return 3.0
        case .defeat, .disappointment:
            return 2.5
        case .thinking:
            return 4.0
        case .goodMove, .badMove, .surprise:
            return 1.5
        case .encouragement, .wisdom, .respect:
            return 2.0
        case .playfulTease:
            return 1.8
        }
    }
}

/// Character expression data with Romanian cultural authenticity
struct CharacterExpression {
    let reaction: CharacterReaction
    let characterType: RomanianCharacterType
    let romanianPhrase: String
    let englishTranslation: String
    let facialExpression: FacialExpression
    let bodyLanguage: BodyLanguage
    let voiceTone: VoiceTone
    let culturalNotes: String
    
    static func getExpression(
        character: RomanianCharacterType,
        reaction: CharacterReaction
    ) -> CharacterExpression {
        switch (character, reaction) {
        case (.oldWiseMan, .victory):
            return CharacterExpression(
                reaction: .victory,
                characterType: .oldWiseMan,
                romanianPhrase: "Bravo, copile! Așa se joacă cu minte!",
                englishTranslation: "Bravo, child! That's how you play with wisdom!",
                facialExpression: .proudSmile,
                bodyLanguage: .approvalNod,
                voiceTone: .gentle,
                culturalNotes: "Romanian grandfathers express pride through gentle encouragement"
            )
            
        case (.playfulGirl, .goodMove):
            return CharacterExpression(
                reaction: .goodMove,
                characterType: .playfulGirl,
                romanianPhrase: "Uite ce deșteaptă ești!",
                englishTranslation: "Look how clever you are!",
                facialExpression: .delightedSmile,
                bodyLanguage: .excitedClap,
                voiceTone: .cheerful,
                culturalNotes: "Romanian children express joy through physical celebration"
            )
            
        case (.mountainShepherd, .thinking):
            return CharacterExpression(
                reaction: .thinking,
                characterType: .mountainShepherd,
                romanianPhrase: "Hmm... să vedem ce-i mai bine...",
                englishTranslation: "Hmm... let's see what's best...",
                facialExpression: .thoughtful,
                bodyLanguage: .handOnChin,
                voiceTone: .contemplative,
                culturalNotes: "Mountain shepherds are known for patient, careful thinking"
            )
            
        case (.villageTeacher, .encouragement):
            return CharacterExpression(
                reaction: .encouragement,
                characterType: .villageTeacher,
                romanianPhrase: "Nu te descuraja! Învățăm din greșeli!",
                englishTranslation: "Don't get discouraged! We learn from mistakes!",
                facialExpression: .kindSmile,
                bodyLanguage: .supportiveGesture,
                voiceTone: .encouraging,
                culturalNotes: "Romanian teachers emphasize learning and growth over perfection"
            )
            
        case (.folkDancer, .celebration):
            return CharacterExpression(
                reaction: .celebration,
                characterType: .folkDancer,
                romanianPhrase: "Hai să sărbătorim! Bravo!",
                englishTranslation: "Let's celebrate! Bravo!",
                facialExpression: .joyousLaughter,
                bodyLanguage: .danceMovement,
                voiceTone: .festive,
                culturalNotes: "Romanian folk culture celebrates achievements with dance and joy"
            )
            
        case (.cardMaster, .respect):
            return CharacterExpression(
                reaction: .respect,
                characterType: .cardMaster,
                romanianPhrase: "Mișcare de maestru! Îmi ridic pălăria!",
                englishTranslation: "Master's move! I tip my hat to you!",
                facialExpression: .respectfulNod,
                bodyLanguage: .tipHat,
                voiceTone: .respectful,
                culturalNotes: "Romanian card masters show respect through traditional gestures"
            )
            
        default:
            return CharacterExpression(
                reaction: reaction,
                characterType: character,
                romanianPhrase: "Foarte bine!",
                englishTranslation: "Very good!",
                facialExpression: .neutralSmile,
                bodyLanguage: .casualGesture,
                voiceTone: .friendly,
                culturalNotes: "General positive Romanian expression"
            )
        }
    }
}

/// Facial expression animation states
enum FacialExpression: String, CaseIterable {
    case neutralSmile = "zâmbet neutru"
    case proudSmile = "zâmbet mândru"
    case delightedSmile = "zâmbet încântat"
    case thoughtful = "gânditor"
    case kindSmile = "zâmbet blând"
    case joyousLaughter = "râs bucuros"
    case respectfulNod = "încuviințare respectuoasă"
    case concerned = "îngrijorat"
    case surprised = "surprins"
    case disappointed = "dezamăgit"
    case encouraging = "încurajator"
    case playful = "jucăuș"
    
    var animationKeyframes: [FacialKeyframe] {
        switch self {
        case .proudSmile:
            return [
                FacialKeyframe(eyebrows: .raised, eyes: .sparkling, mouth: .warmSmile, time: 0.0),
                FacialKeyframe(eyebrows: .normal, eyes: .kind, mouth: .proudSmile, time: 1.0)
            ]
        case .joyousLaughter:
            return [
                FacialKeyframe(eyebrows: .raised, eyes: .closed, mouth: .openLaugh, time: 0.0),
                FacialKeyframe(eyebrows: .raised, eyes: .sparkling, mouth: .bigSmile, time: 0.5),
                FacialKeyframe(eyebrows: .normal, eyes: .joyful, mouth: .warmSmile, time: 1.0)
            ]
        case .thoughtful:
            return [
                FacialKeyframe(eyebrows: .furrowed, eyes: .focused, mouth: .neutral, time: 0.0),
                FacialKeyframe(eyebrows: .raised, eyes: .contemplating, mouth: .slight_frown, time: 0.5),
                FacialKeyframe(eyebrows: .normal, eyes: .understanding, mouth: .neutral, time: 1.0)
            ]
        default:
            return [
                FacialKeyframe(eyebrows: .normal, eyes: .kind, mouth: .neutralSmile, time: 0.0),
                FacialKeyframe(eyebrows: .normal, eyes: .kind, mouth: .neutralSmile, time: 1.0)
            ]
        }
    }
}

/// Body language animation states
enum BodyLanguage: String, CaseIterable {
    case approvalNod = "încuviințare"
    case excitedClap = "bătăi entuziaste din palme"
    case handOnChin = "mâna la bărbie"
    case supportiveGesture = "gest de susținere"
    case danceMovement = "mișcare de dans"
    case tipHat = "ridicare pălărie"
    case casualGesture = "gest casual"
    case armsCrossed = "brațe încrucișate"
    case handsOnHips = "mâinile în șolduri"
    case pointingUp = "arătând în sus"
    case shrug = "ridicare din umeri"
    case victory_pose = "pozitie de victorie"
    
    var animationSequence: [BodyKeyframe] {
        switch self {
        case .excitedClap:
            return [
                BodyKeyframe(arms: .raised, hands: .together, body: .straight, time: 0.0),
                BodyKeyframe(arms: .clapping, hands: .clapping, body: .bouncing, time: 0.3),
                BodyKeyframe(arms: .raised, hands: .apart, body: .straight, time: 0.6),
                BodyKeyframe(arms: .normal, hands: .relaxed, body: .normal, time: 1.0)
            ]
        case .danceMovement:
            return [
                BodyKeyframe(arms: .extended, hands: .graceful, body: .swaying_left, time: 0.0),
                BodyKeyframe(arms: .flowing, hands: .expressive, body: .swaying_right, time: 0.5),
                BodyKeyframe(arms: .extended, hands: .graceful, body: .swaying_left, time: 1.0)
            ]
        case .tipHat:
            return [
                BodyKeyframe(arms: .normal, hands: .relaxed, body: .normal, time: 0.0),
                BodyKeyframe(arms: .right_raised, hands: .hat_tip, body: .slight_bow, time: 0.5),
                BodyKeyframe(arms: .normal, hands: .relaxed, body: .normal, time: 1.0)
            ]
        default:
            return [
                BodyKeyframe(arms: .normal, hands: .relaxed, body: .normal, time: 0.0),
                BodyKeyframe(arms: .normal, hands: .relaxed, body: .normal, time: 1.0)
            ]
        }
    }
}

/// Voice tone characteristics for audio feedback
enum VoiceTone: String, CaseIterable {
    case gentle = "blând"
    case cheerful = "vesel"
    case contemplative = "contemplativ"
    case encouraging = "încurajator"
    case festive = "festiv"
    case respectful = "respectuos"
    case friendly = "prietenos"
    case wise = "înțelept"
    case playful = "jucăuș"
    case warm = "cald"
    
    var audioSettings: AudioSettings {
        switch self {
        case .gentle:
            return AudioSettings(pitch: 0.9, volume: 0.7, reverb: 0.3, warmth: 0.8)
        case .cheerful:
            return AudioSettings(pitch: 1.2, volume: 0.9, reverb: 0.1, warmth: 0.9)
        case .contemplative:
            return AudioSettings(pitch: 0.8, volume: 0.6, reverb: 0.4, warmth: 0.7)
        case .encouraging:
            return AudioSettings(pitch: 1.0, volume: 0.8, reverb: 0.2, warmth: 0.9)
        case .festive:
            return AudioSettings(pitch: 1.3, volume: 1.0, reverb: 0.2, warmth: 1.0)
        case .respectful:
            return AudioSettings(pitch: 0.9, volume: 0.7, reverb: 0.3, warmth: 0.8)
        default:
            return AudioSettings(pitch: 1.0, volume: 0.8, reverb: 0.2, warmth: 0.8)
        }
    }
}

/// Animation keyframe structures for precise character movement
struct FacialKeyframe {
    let eyebrows: EyebrowPosition
    let eyes: EyeExpression
    let mouth: MouthShape
    let time: Double
}

struct BodyKeyframe {
    let arms: ArmPosition
    let hands: HandGesture
    let body: BodyPosition
    let time: Double
}

struct AudioSettings {
    let pitch: Float
    let volume: Float
    let reverb: Float
    let warmth: Float
}

// MARK: - Animation Detail Enums

enum EyebrowPosition: String {
    case normal, raised, furrowed, asymmetric
}

enum EyeExpression: String {
    case kind, sparkling, focused, contemplating, understanding, joyful, closed
}

enum MouthShape: String {
    case neutralSmile, warmSmile, proudSmile, openLaugh, bigSmile, neutral, slight_frown
}

enum ArmPosition: String {
    case normal, raised, extended, flowing, right_raised, clapping
}

enum HandGesture: String {
    case relaxed, together, apart, clapping, graceful, expressive, hat_tip
}

enum BodyPosition: String {
    case normal, straight, bouncing, swaying_left, swaying_right, slight_bow
}

/// Main character animation coordinator with Romanian cultural context
@Observable
class RomanianCharacterAnimator {
    
    var currentCharacter: RomanianCharacterType = .oldWiseMan
    var currentExpression: CharacterExpression?
    var isAnimating = false
    var animationProgress: Double = 0.0
    var speechBubbleText: String = ""
    var showSpeechBubble = false
    
    private var animationTimer: Timer?
    private let hapticManager = HapticManager()
    private let audioManager = AudioManager()
    
    // Character selection based on game context
    func selectAppropriateCharacter(for context: GameContext) -> RomanianCharacterType {
        switch context {
        case .teaching, .rules_explanation:
            return .villageTeacher
        case .celebration, .victory:
            return .folkDancer
        case .strategic_thinking, .difficult_decision:
            return .mountainShepherd
        case .encouragement, .learning:
            return .oldWiseMan
        case .playful_moment, .quick_game:
            return .playfulGirl
        case .expert_play, .advanced_strategy:
            return .cardMaster
        }
    }
    
    /// Trigger character reaction with full Romanian cultural context
    func triggerReaction(
        _ reaction: CharacterReaction,
        context: GameContext,
        intensity: AnimationIntensity = .normal
    ) {
        currentCharacter = selectAppropriateCharacter(for: context)
        let expression = CharacterExpression.getExpression(
            character: currentCharacter,
            reaction: reaction
        )
        
        performReaction(expression, intensity: intensity)
    }
    
    /// Perform complete character reaction animation
    private func performReaction(
        _ expression: CharacterExpression,
        intensity: AnimationIntensity
    ) {
        currentExpression = expression
        isAnimating = true
        animationProgress = 0.0
        
        // Display Romanian phrase with translation
        showRomanianPhrase(expression)
        
        // Play cultural audio feedback
        playAudioFeedback(expression)
        
        // Trigger haptic feedback
        triggerHapticFeedback(expression, intensity: intensity)
        
        // Start animation sequence
        startAnimationSequence(expression, intensity: intensity)
    }
    
    /// Display Romanian phrase with cultural authenticity
    private func showRomanianPhrase(_ expression: CharacterExpression) {
        speechBubbleText = expression.romanianPhrase
        showSpeechBubble = true
        
        // Auto-hide speech bubble after phrase duration
        DispatchQueue.main.asyncAfter(deadline: .now() + expression.reaction.animationDuration) {
            withAnimation(.easeOut(duration: 0.5)) {
                self.showSpeechBubble = false
            }
        }
    }
    
    /// Play culturally appropriate audio feedback
    private func playAudioFeedback(_ expression: CharacterExpression) {
        let audioSettings = expression.voiceTone.audioSettings
        
        // Play Romanian pronunciation if available
        if let audioFile = getRomanianAudioFile(for: expression) {
            audioManager.playSound(audioFile, settings: audioSettings)
        }
        
        // Fallback to emotional sound effects
        let emotionalSound = getEmotionalSound(for: expression.reaction)
        audioManager.playSound(emotionalSound, settings: audioSettings)
    }
    
    /// Trigger appropriate haptic feedback for character reactions
    private func triggerHapticFeedback(
        _ expression: CharacterExpression,
        intensity: AnimationIntensity
    ) {
        let hapticIntensity = intensity.hapticStrength
        
        switch expression.reaction {
        case .victory, .celebration:
            hapticManager.trigger(.success)
        case .goodMove, .encouragement:
            hapticManager.trigger(.success)
        case .badMove, .disappointment:
            hapticManager.trigger(.warning)
        case .defeat:
            hapticManager.trigger(.error)
        case .thinking, .wisdom:
            hapticManager.trigger(.selection)
        case .surprise:
            hapticManager.trigger(.lightImpact)
        default:
            hapticManager.trigger(.lightImpact)
        }
    }
    
    /// Execute complete animation sequence with Romanian cultural flair
    private func startAnimationSequence(
        _ expression: CharacterExpression,
        intensity: AnimationIntensity
    ) {
        let duration = expression.reaction.animationDuration * intensity.durationMultiplier
        let frameRate: Double = 60.0 // 60 FPS for smooth animation
        let totalFrames = Int(duration * frameRate)
        var currentFrame = 0
        
        animationTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / frameRate, repeats: true) { _ in
            currentFrame += 1
            let progress = Double(currentFrame) / Double(totalFrames)
            
            withAnimation(.easeInOut(duration: 1.0 / frameRate)) {
                self.animationProgress = min(progress, 1.0)
            }
            
            if progress >= 1.0 {
                self.completeAnimation()
            }
        }
    }
    
    /// Complete animation and reset state
    private func completeAnimation() {
        animationTimer?.invalidate()
        animationTimer = nil
        
        withAnimation(.easeOut(duration: 0.3)) {
            isAnimating = false
            animationProgress = 0.0
        }
    }
    
    /// Get Romanian audio file for authentic pronunciation
    private func getRomanianAudioFile(for expression: CharacterExpression) -> String? {
        let audioFileName = "\(expression.characterType.rawValue)_\(expression.reaction.rawValue)_ro"
        return Bundle.main.path(forResource: audioFileName, ofType: "mp3") != nil ? audioFileName : nil
    }
    
    /// Get emotional sound effect for reaction
    private func getEmotionalSound(for reaction: CharacterReaction) -> String {
        switch reaction {
        case .victory, .celebration:
            return "romanian_victory_cheer"
        case .goodMove:
            return "romanian_approval"
        case .badMove, .disappointment:
            return "romanian_gentle_correction"
        case .thinking:
            return "romanian_contemplation"
        case .encouragement:
            return "romanian_encouragement"
        case .wisdom:
            return "romanian_wisdom_share"
        default:
            return "romanian_general_positive"
        }
    }
}

/// Game context for appropriate character selection
enum GameContext {
    case teaching
    case rules_explanation
    case celebration
    case victory
    case strategic_thinking
    case difficult_decision
    case encouragement
    case learning
    case playful_moment
    case quick_game
    case expert_play
    case advanced_strategy
}

/// Animation intensity for different situations
enum AnimationIntensity {
    case subtle
    case normal
    case dramatic
    case celebration
    
    var durationMultiplier: Double {
        switch self {
        case .subtle: return 0.7
        case .normal: return 1.0
        case .dramatic: return 1.3
        case .celebration: return 1.5
        }
    }
    
    var hapticStrength: Float {
        switch self {
        case .subtle: return 0.4
        case .normal: return 0.7
        case .dramatic: return 1.0
        case .celebration: return 1.0
        }
    }
}

// MARK: - SwiftUI Character View Component

/// Visual character component with animated reactions
struct RomanianCharacterView: View {
    @Bindable var animator: RomanianCharacterAnimator
    let size: CGSize
    
    var body: some View {
        ZStack {
            // Character illustration with animation
            characterIllustration
                .scaleEffect(animator.isAnimating ? 1.05 : 1.0)
                .rotationEffect(.degrees(animator.isAnimating ? 2 : 0))
                .animation(.spring(response: 0.4, dampingFraction: 0.7), value: animator.isAnimating)
            
            // Speech bubble with Romanian phrases
            if animator.showSpeechBubble {
                speechBubbleView
                    .transition(.scale.combined(with: .opacity))
            }
            
            // Character name and cultural context
            characterInfoView
        }
        .frame(width: size.width, height: size.height)
    }
    
    @ViewBuilder
    private var characterIllustration: some View {
        // Placeholder for character artwork - would be replaced with actual illustrations
        RoundedRectangle(cornerRadius: 16)
            .fill(
                LinearGradient(
                    colors: characterGradientColors,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                VStack {
                    Text(animator.currentCharacter.rawValue)
                        .font(.caption.bold())
                        .foregroundColor(.white)
                    
                    // Cultural icon representation
                    Image(systemName: characterIcon)
                        .font(.title)
                        .foregroundColor(.white)
                }
            )
            .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
    }
    
    @ViewBuilder
    private var speechBubbleView: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(animator.speechBubbleText)
                .font(.body.bold())
                .foregroundColor(.black)
            
            if let expression = animator.currentExpression {
                Text(expression.englishTranslation)
                    .font(.caption)
                    .foregroundColor(.gray)
                    .italic()
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
        )
        .offset(y: -size.height * 0.4)
    }
    
    @ViewBuilder
    private var characterInfoView: some View {
        VStack {
            Spacer()
            
            Text(animator.currentCharacter.rawValue)
                .font(.caption2.bold())
                .foregroundColor(RomanianColors.primaryYellow)
                .shadow(color: .black.opacity(0.6), radius: 2, x: 0, y: 1)
        }
        .offset(y: size.height * 0.4)
    }
    
    private var characterGradientColors: [Color] {
        switch animator.currentCharacter {
        case .oldWiseMan:
            return [RomanianColors.primaryBlue, RomanianColors.primaryBlue.opacity(0.8)]
        case .playfulGirl:
            return [RomanianColors.primaryRed, RomanianColors.primaryRed.opacity(0.8)]
        case .mountainShepherd:
            return [RomanianColors.countrysideGreen, RomanianColors.countrysideGreen.opacity(0.8)]
        case .villageTeacher:
            return [RomanianColors.primaryYellow, RomanianColors.goldAccent]
        case .folkDancer:
            return [RomanianColors.embroideryRed, RomanianColors.embroideryRed.opacity(0.8)]
        case .cardMaster:
            return [RomanianColors.goldAccent, RomanianColors.primaryYellow]
        }
    }
    
    private var characterIcon: String {
        switch animator.currentCharacter {
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
}
