//
//  RomanianDialogueSystem.swift
//  Septica
//
//  Romanian character dialogue system inspired by Shuffle Cats personality
//  Provides authentic cultural expressions and reactions during gameplay
//

import Foundation
import SwiftUI
import Combine

// Note: Color(hex:) extension and Triangle shape are defined in other files

/// Romanian dialogue system that adds cultural personality to character interactions
/// Characters react with authentic Romanian expressions based on game events
@MainActor
class RomanianDialogueSystem: ObservableObject {
    
    // MARK: - Published State
    
    @Published var currentDialogue: RomanianDialogue?
    @Published var isShowingDialogue: Bool = false
    @Published var dialogueHistory: [RomanianDialogue] = []
    
    // MARK: - Configuration
    
    private let maxDialogueHistory = 10
    private let dialogueDuration: TimeInterval = 5.0  // Increased for better visibility
    private var dialogueTimer: Timer?
    
    // MARK: - Romanian Dialogue Database
    
    private let gameStartDialogues = [
        RomanianDialogue(
            romanian: "Să începem jocul!",
            english: "Let's start the game!",
            pronunciation: "Sah in-che-pem jo-cool",
            culturalContext: "Traditional Romanian game opening"
        ),
        RomanianDialogue(
            romanian: "Noroc bun la joc!",
            english: "Good luck with the game!",
            pronunciation: "No-rock boon la zhock",
            culturalContext: "Romanian good luck wish"
        ),
        RomanianDialogue(
            romanian: "Să vedem cine e maestrul!",
            english: "Let's see who's the master!",
            pronunciation: "Sah ve-dem chi-ne e ma-es-trool",
            culturalContext: "Playful challenge in Romanian tradition"
        )
    ]
    
    private let goodPlayDialogues = [
        RomanianDialogue(
            romanian: "Bravo, măiestre!",
            english: "Bravo, master!",
            pronunciation: "Bra-vo, mah-yes-tre",
            culturalContext: "Traditional Romanian praise for skilled play"
        ),
        RomanianDialogue(
            romanian: "Excelent joc!",
            english: "Excellent game!",
            pronunciation: "Ek-che-lent zhock",
            culturalContext: "Romanian appreciation for good strategy"
        ),
        RomanianDialogue(
            romanian: "Ai dat lovitura!",
            english: "You struck gold!",
            pronunciation: "Ah-ee dat lo-vi-too-ra",
            culturalContext: "Romanian expression for a great move"
        ),
        RomanianDialogue(
            romanian: "Joci ca un adevărat român!",
            english: "You play like a true Romanian!",
            pronunciation: "Zhock-ee ka oon a-de-vah-rat ro-mahn",
            culturalContext: "Ultimate compliment in Romanian card games"
        ),
        RomanianDialogue(
            romanian: "Ție îți merge mâna!",
            english: "Your hand is working well!",
            pronunciation: "Tee-ye eet-ee mer-ge mah-na",
            culturalContext: "Romanian expression for being lucky/skilled"
        )
    ]
    
    private let sevenCardDialogues = [
        RomanianDialogue(
            romanian: "Șeptarul magic!",
            english: "The magic seven!",
            pronunciation: "Shep-ta-rool ma-zhick",
            culturalContext: "Seven is special in Romanian card traditions"
        ),
        RomanianDialogue(
            romanian: "Ai găsit cartea câștigătoare!",
            english: "You found the winning card!",
            pronunciation: "Ah-ee gah-sit kar-tea cahsh-ti-gah-toa-re",
            culturalContext: "Romanian expression for finding the right card"
        ),
        RomanianDialogue(
            romanian: "Înțelepciunea bătrânilor!",
            english: "The wisdom of the elders!",
            pronunciation: "In-tse-lep-choo-nea bah-trah-ni-lor",
            culturalContext: "Referencing traditional Romanian wisdom"
        )
    ]
    
    private let victoryDialogues = [
        RomanianDialogue(
            romanian: "Felicitări, campione!",
            english: "Congratulations, champion!",
            pronunciation: "Fe-li-chi-tah-ree, kam-pee-oh-ne",
            culturalContext: "Romanian victory celebration"
        ),
        RomanianDialogue(
            romanian: "Ai câștigat cu onoare!",
            english: "You won with honor!",
            pronunciation: "Ah-ee cahsh-ti-gat koo o-noa-re",
            culturalContext: "Romanian emphasis on honorable victory"
        ),
        RomanianDialogue(
            romanian: "Victorie pe măsura ta!",
            english: "A victory worthy of you!",
            pronunciation: "Vik-to-ree-e pe mah-su-ra ta",
            culturalContext: "Romanian praise for deserved victory"
        ),
        RomanianDialogue(
            romanian: "Să trăiești, măiestre!",
            english: "Long live the master!",
            pronunciation: "Sah trah-eesh-tee, mah-yes-tre",
            culturalContext: "Traditional Romanian toast for winners"
        )
    ]
    
    private let encouragementDialogues = [
        RomanianDialogue(
            romanian: "Nu te descuraja!",
            english: "Don't get discouraged!",
            pronunciation: "Noo te des-koo-ra-zha",
            culturalContext: "Romanian encouragement during difficult times"
        ),
        RomanianDialogue(
            romanian: "Încă nu s-a terminat!",
            english: "It's not over yet!",
            pronunciation: "In-kah noo sa ter-mi-nat",
            culturalContext: "Romanian fighting spirit"
        ),
        RomanianDialogue(
            romanian: "Gândește-te bine!",
            english: "Think it through!",
            pronunciation: "Gahn-deesh-te te bee-ne",
            culturalContext: "Romanian advice for strategic thinking"
        ),
        RomanianDialogue(
            romanian: "Răbdarea e o virtute!",
            english: "Patience is a virtue!",
            pronunciation: "Rahb-da-rea e o vir-too-te",
            culturalContext: "Traditional Romanian wisdom"
        )
    ]
    
    private let traditionalPhrases = [
        RomanianDialogue(
            romanian: "Cum îi zice la carte, așa îi zice la om!",
            english: "As the card is called, so is the person!",
            pronunciation: "Koom ee-ee zee-che la kar-te, a-sha ee-ee zee-che la om",
            culturalContext: "Romanian saying about character and cards"
        ),
        RomanianDialogue(
            romanian: "Cartea nu minte niciodată!",
            english: "The card never lies!",
            pronunciation: "Kar-tea noo min-te ni-cho-da-tah",
            culturalContext: "Romanian belief in card truth"
        ),
        RomanianDialogue(
            romanian: "Cu mâna de aur!",
            english: "With a golden hand!",
            pronunciation: "Koo mah-na de a-oor",
            culturalContext: "Romanian expression for skilled card play"
        )
    ]
    
    // MARK: - Public Interface
    
    /// Trigger dialogue based on game event
    func triggerDialogue(for event: DialogueEvent, character: RomanianCharacterAvatar) {
        let dialogue = selectDialogue(for: event, character: character)
        showDialogue(dialogue)
    }
    
    /// Show specific dialogue with timing
    func showDialogue(_ dialogue: RomanianDialogue) {
        // Cancel any existing dialogue timer
        dialogueTimer?.invalidate()
        
        // Show new dialogue
        currentDialogue = dialogue
        isShowingDialogue = true
        
        // Add to history
        dialogueHistory.append(dialogue)
        if dialogueHistory.count > maxDialogueHistory {
            dialogueHistory.removeFirst()
        }
        
        // Auto-hide after duration
        dialogueTimer = Timer.scheduledTimer(withTimeInterval: dialogueDuration, repeats: false) { [weak self] _ in
            Task { @MainActor in
                self?.hideDialogue()
            }
        }
    }
    
    /// Hide current dialogue
    func hideDialogue() {
        currentDialogue = nil
        isShowingDialogue = false
        dialogueTimer?.invalidate()
        dialogueTimer = nil
    }
    
    /// Get random traditional phrase for ambient dialogue
    func getRandomTraditionalPhrase() -> RomanianDialogue {
        return traditionalPhrases.randomElement() ?? traditionalPhrases[0]
    }
    
    // MARK: - Private Methods
    
    private func selectDialogue(for event: DialogueEvent, character: RomanianCharacterAvatar) -> RomanianDialogue {
        let dialoguePool: [RomanianDialogue]
        
        switch event {
        case .gameStart:
            dialoguePool = gameStartDialogues
        case .goodPlay, .strategicMove:
            dialoguePool = goodPlayDialogues
        case .sevenPlayed:
            dialoguePool = sevenCardDialogues
        case .victory:
            dialoguePool = victoryDialogues
        case .encouragement, .badLuck:
            dialoguePool = encouragementDialogues
        case .traditional:
            dialoguePool = traditionalPhrases
        }
        
        // Select random dialogue, ensuring variety
        var availableDialogues = dialoguePool
        
        // Avoid repeating the last dialogue if possible
        if let lastDialogue = dialogueHistory.last,
           availableDialogues.count > 1 {
            availableDialogues.removeAll { $0.romanian == lastDialogue.romanian }
        }
        
        return availableDialogues.randomElement() ?? dialoguePool[0]
    }
}

// MARK: - Supporting Data Models

/// Romanian dialogue entry with cultural context
struct RomanianDialogue: Identifiable, Equatable {
    let id = UUID()
    let romanian: String
    let english: String
    let pronunciation: String
    let culturalContext: String
    
    var displayText: String {
        return romanian
    }
    
    var tooltipText: String {
        return "\(english)\n\nPronunciation: \(pronunciation)\n\nCultural Context: \(culturalContext)"
    }
    
    static func == (lhs: RomanianDialogue, rhs: RomanianDialogue) -> Bool {
        return lhs.romanian == rhs.romanian
    }
}

/// Dialogue-specific events that trigger Romanian character reactions
enum DialogueEvent {
    case gameStart
    case goodPlay
    case strategicMove
    case sevenPlayed
    case victory
    case encouragement
    case badLuck
    case traditional
}

// MARK: - SwiftUI Integration

/// Dialogue bubble view that displays Romanian expressions
struct RomanianDialogueBubbleView: View {
    let dialogue: RomanianDialogue
    let character: RomanianCharacterAvatar
    @State private var isVisible = false
    @State private var showTooltip = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Prominent speech bubble with Romanian text - Shuffle Cats style
            HStack {
                speechBubbleContent
                Spacer()
            }
            
            // Enhanced translation hint with better visibility
            if showTooltip {
                tooltipContent
            }
        }
        .scaleEffect(isVisible ? 1.0 : 0.3)  // More dramatic entrance effect
        .opacity(isVisible ? 1.0 : 0.0)
        .onAppear {
            // Dramatic bounce animation like Shuffle Cats characters
            withAnimation(.spring(response: 0.6, dampingFraction: 0.6, blendDuration: 0.3)) {
                isVisible = true
            }
            
            // Show tooltip after appropriate delay for reading
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                withAnimation(.easeInOut(duration: 0.4)) {
                    showTooltip = true
                }
            }
        }
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.3)) {
                showTooltip.toggle()
            }
        }
        .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)  // Enhanced shadow for prominence
    }
    
    // MARK: - Helper Views
    
    private var speechBubbleContent: some View {
        let bubbleColor = getBubbleColor(for: character)
        
        return Text(dialogue.displayText)
            .font(Font.system(size: 22, weight: .bold, design: .rounded))  // Much larger and bolder
            .foregroundColor(.white)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 24)  // Increased padding for prominence
            .padding(.vertical, 16)    // Increased vertical padding
            .frame(minWidth: 160)      // Minimum width for better presence
            .background(speechBubbleBackground(color: bubbleColor))
            .overlay(speechBubbleTail(color: bubbleColor))
    }
    
    private func speechBubbleBackground(color: Color) -> some View {
        RoundedRectangle(cornerRadius: 24)  // Larger corner radius for prominent bubbles
            .fill(
                LinearGradient(
                    colors: [color, color.opacity(0.8)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(Color.white.opacity(0.3), lineWidth: 2)  // Subtle border for definition
            )
            .shadow(color: .black.opacity(0.4), radius: 8, x: 0, y: 4)  // Enhanced shadow
    }
    
    private func speechBubbleTail(color: Color) -> some View {
        Triangle()
            .fill(
                LinearGradient(
                    colors: [color, color.opacity(0.8)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: 16, height: 12)  // Larger tail for prominent bubbles
            .offset(x: -12, y: 24)         // Adjusted positioning
    }
    
    private func getBubbleColor(for character: RomanianCharacterAvatar) -> Color {
        // Enhanced colors for better visibility and prominence
        switch character {
        case .traditionalPlayer: return Color(red: 0.6, green: 0.4, blue: 0.2)  // Rich brown
        case .villageElder: return Color(red: 0.2, green: 0.6, blue: 0.3)      // Forest green
        case .folkMusician: return Color(red: 0.2, green: 0.4, blue: 0.8)      // Royal blue
        case .transylvanianNoble: return Color(red: 0.7, green: 0.2, blue: 0.2) // Deep red
        case .moldovanScholar: return Color(red: 0.3, green: 0.3, blue: 0.5)    // Slate blue
        case .wallachianWarrior: return Color(red: 0.8, green: 0.6, blue: 0.1)  // Golden
        case .carpathianShepherd: return Color(red: 0.3, green: 0.6, blue: 0.3) // Mountain green
        case .danubianFisherman: return Color(red: 0.2, green: 0.5, blue: 0.7)  // River blue
        case .bucovinianArtisan: return Color(red: 0.8, green: 0.4, blue: 0.2)  // Artisan orange
        case .dobrudjanMerchant: return Color(red: 0.7, green: 0.5, blue: 0.1)  // Merchant gold
        }
    }
    
    private var tooltipContent: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(dialogue.english)
                .font(.system(size: 16, weight: .medium))  // Larger, more readable font
                .foregroundColor(.white)
                .italic()
            
            Text("Tap to learn more")
                .font(.system(size: 12, weight: .regular))
                .foregroundColor(.white.opacity(0.7))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.8))
                .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
        )
        .transition(.asymmetric(
            insertion: .scale.combined(with: .opacity),
            removal: .opacity.combined(with: .move(edge: .top))
        ))
    }
}


// MARK: - Character Extensions

extension RomanianCharacterAvatar {
    /// Primary color for dialogue bubbles
    var primaryColor: String {
        switch self {
        case .traditionalPlayer: return "#8B4513" // Brown
        case .villageElder: return "#228B22" // Forest green
        case .folkMusician: return "#4169E1" // Royal blue
        case .transylvanianNoble: return "#8B0000" // Dark red
        case .moldovanScholar: return "#2F4F4F" // Dark slate gray
        case .wallachianWarrior: return "#FFD700" // Gold
        case .carpathianShepherd: return "#006400" // Dark green
        case .danubianFisherman: return "#4682B4" // Steel blue
        case .bucovinianArtisan: return "#FF6347" // Tomato red
        case .dobrudjanMerchant: return "#DAA520" // Goldenrod
        }
    }
    
    /// Preferred dialogue style for character
    var dialoguePersonality: DialoguePersonality {
        switch self {
        case .traditionalPlayer: return .traditional
        case .villageElder: return .wise
        case .folkMusician: return .enthusiastic
        case .transylvanianNoble: return .clever
        case .moldovanScholar: return .wise
        case .wallachianWarrior: return .straightforward
        case .carpathianShepherd: return .traditional
        case .danubianFisherman: return .straightforward
        case .bucovinianArtisan: return .nurturing
        case .dobrudjanMerchant: return .clever
        }
    }
}

enum DialoguePersonality {
    case traditional, wise, nurturing, enthusiastic, straightforward, clever
}

// MARK: - Preview Support

#if DEBUG
struct RomanianDialogueSystem_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            RomanianDialogueBubbleView(
                dialogue: RomanianDialogue(
                    romanian: "Bravo, măiestre!",
                    english: "Bravo, master!",
                    pronunciation: "Bra-vo, mah-yes-tre",
                    culturalContext: "Traditional Romanian praise"
                ),
                character: .traditionalPlayer
            )
            
            RomanianDialogueBubbleView(
                dialogue: RomanianDialogue(
                    romanian: "Șeptarul magic!",
                    english: "The magic seven!",
                    pronunciation: "Shep-ta-rool ma-zhick",
                    culturalContext: "Seven is special in Romanian traditions"
                ),
                character: .villageElder
            )
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .previewDevice("iPhone 14 Pro")
    }
}
#endif