//
//  PremiumGameScreen.swift
//  Septica
//
//  High production value main game screen combining all premium elements
//  Professional Romanian card game experience with cultural authenticity
//

import SwiftUI

/// Premium game screen with high production value and Romanian cultural elements
struct PremiumGameScreen: View {
    // Game state
    @State private var currentPlayer = Player(name: "Jucător")
    @State private var opponentPlayer = Player(name: "Computer")
    @State private var tableCards: [Card] = []
    @State private var selectedCard: Card? = nil
    @State private var gameRound = 1
    @State private var turnTimeRemaining: TimeInterval = 30
    
    // Animation states
    @State private var backgroundPulse = false
    @State private var showVictoryEffects = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Enhanced background with premium gradient overlay
                ShuffleCatsInspiredBackground()
                    .ignoresSafeArea()

                // Premium gradient overlay with Romanian cultural themes
                PremiumGradientOverlays.GameScreenGradientOverlay(
                    culturalTheme: .romanianHeritage,
                    animationState: showVictoryEffects ? .celebration : .active,
                    isInteractive: true
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    GameStatusView(
                        currentPlayer: currentPlayer,
                        opponentPlayer: opponentPlayer,
                        gameRound: gameRound,
                        totalRounds: 5,
                        turnTimeRemaining: turnTimeRemaining,
                        totalTurnTime: 30,
                        gamePhase: SepticaGamePhase.playing
                    )
                    .padding(.horizontal, 24)
                    .padding(.top, geometry.safeAreaInsets.top + 12)
                    
                    Spacer()
                    
                    // Opponent hand area with premium styling
                    OpponentInfoPanel(player: opponentPlayer)
                        .padding(.top, 4)

                    Spacer()
                    
                    // Central game table with premium effects
                    GameTableView(
                        tableCards: tableCards,
                        validMoves: getValidMoves(),
                        onCardTapped: { card in
                            // Handle table card interaction
                        },
                        animatingCard: nil
                    )
                    .overlay(
                        // Special effects for active game state
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        RomanianColors.goldAccent.opacity(0.3),
                                        Color.clear,
                                        RomanianColors.goldAccent.opacity(0.3)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                            .scaleEffect(backgroundPulse ? 1.02 : 1.0)
                            .animation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true), value: backgroundPulse)
                    )
                    
                    Spacer()
                    
                    // Player hand with premium interactions
                    PlayerHandView(
                        player: currentPlayer,
                        selectedCard: selectedCard,
                        validMoves: getValidMoves(),
                        onCardSelected: { card in
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                selectedCard = card
                            }
                        },
                        onCardPlayed: { card in
                            playCard(card)
                        },
                        isCurrentPlayer: true,
                        isInteractionEnabled: true,
                        onDragStateChanged: nil
                    )
                    .padding(.horizontal)
                    
                    // Premium action buttons
                    premiumActionButtons
                        .padding()
                    
                    Spacer(minLength: geometry.safeAreaInsets.bottom)
                }
                
                // Victory/celebration effects overlay
                if showVictoryEffects {
                    celebrationOverlay
                }

                // Premium floating action button
                VStack {
                    HStack {
                        Spacer()
                        PremiumButtonComponents.PremiumFloatingActionButton(
                            iconName: "heart.fill",
                            culturalAccent: .gold
                        ) {
                            // Handle favorite action
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                                // Toggle favorite state
                            }
                        }
                        .accessibilityEnhanced()
                        .padding(.trailing, 24)
                        .padding(.top, 100)
                    }
                    Spacer()
                }
            }
        }
        .ignoresSafeArea(edges: .top)
        .onAppear {
            setupInitialGameState()
            backgroundPulse = true
        }
    }
    
    // MARK: - Premium Glass Morphism Action Buttons

    private var premiumActionButtons: some View {
        HStack(spacing: 24) {
            // Secondary glass button - Pass action
            PremiumButtonComponents.PremiumGlassSecondaryButton(
                title: "Treci",
                iconName: "hand.raised.fill",
                culturalTheme: .carpathian
            ) {
                // Handle pass action
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    selectedCard = nil
                }
            }
            .accessibilityEnhanced()

            // Primary glass button - Play action
            PremiumButtonComponents.PremiumGlassButton(
                title: "Joacă",
                subtitle: "Confirmă cartea",
                iconName: "play.fill",
                style: .primary
            ) {
                if let card = selectedCard {
                    playCard(card)
                }
            }
            .accessibilityEnhanced()

            // Secondary glass button - Menu action
            PremiumButtonComponents.PremiumGlassSecondaryButton(
                title: "Meniu",
                iconName: "line.3.horizontal",
                culturalTheme: .traditional
            ) {
                // Handle menu action
                print("Menu button tapped")
            }
            .accessibilityEnhanced()
        }
    }
    
    // MARK: - Celebration Effects
    
    private var celebrationOverlay: some View {
        ZStack {
            // Romanian victory colors celebration
            RadialGradient(
                colors: [
                    RomanianColors.goldAccent.opacity(0.3),
                    RomanianColors.primaryYellow.opacity(0.2),
                    Color.clear
                ],
                center: .center,
                startRadius: 50,
                endRadius: 300
            )
            .scaleEffect(2.0)
            .animation(.easeOut(duration: 1.5), value: showVictoryEffects)
            
            Text("Felicitări!")
                .font(.largeTitle.weight(.black))
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            RomanianColors.goldAccent,
                            RomanianColors.primaryYellow,
                            RomanianColors.goldAccent
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: RomanianColors.primaryBlue.opacity(0.5), radius: 4, x: 0, y: 2)
                .scaleEffect(showVictoryEffects ? 1.2 : 0.1)
                .animation(.spring(response: 0.8, dampingFraction: 0.6), value: showVictoryEffects)
        }
        .allowsHitTesting(false)
    }
    
    // MARK: - Game Logic Helpers
    
    private func setupInitialGameState() {
        // Initialize players with sample data
        currentPlayer.hand = [
            Card(suit: .hearts, value: 10),
            Card(suit: .spades, value: 7),
            Card(suit: .diamonds, value: 14),
            Card(suit: .clubs, value: 11)
        ]
        currentPlayer.score = 2
        
        opponentPlayer.hand = [
            Card(suit: .hearts, value: 8),
            Card(suit: .spades, value: 9),
            Card(suit: .diamonds, value: 12),
            Card(suit: .clubs, value: 13)
        ]
        opponentPlayer.score = 1
    }
    
    private func getValidMoves() -> [Card] {
        // Return all player cards as valid for demo
        return currentPlayer.hand
    }
    
    private func playCard(_ card: Card) {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
            // Add card to table
            tableCards.append(card)
            
            // Remove from player hand
            if let index = currentPlayer.hand.firstIndex(where: { $0.id == card.id }) {
                currentPlayer.hand.remove(at: index)
            }
            
            selectedCard = nil
        }
    }
}

// MARK: - Supporting Views

private struct OpponentInfoPanel: View {
    let player: Player
    
    private var cardCount: Int { max(player.hand.count, 0) }
    
    var body: some View {
        VStack(spacing: 14) {
            opponentBadge
            cardTray
        }
        .padding(.horizontal, 32)
    }
    
    private var opponentBadge: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(hex: player.currentArena.primaryColor).opacity(0.8),
                                Color(hex: player.currentArena.accentColor).opacity(0.5)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 78, height: 78)
                    .shadow(color: .black.opacity(0.35), radius: 8, x: 0, y: 5)
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.2), lineWidth: 1.5)
                    )
                
                RomanianPlayerAvatarView(
                    avatar: player.romanianAvatar,
                    frame: player.avatarFrame,
                    level: player.playerLevel,
                    arena: player.currentArena,
                    isCurrentPlayer: false
                )
                .frame(width: 78, height: 78)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Text(player.name)
                        .font(.headline.weight(.semibold))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 1)
                    Spacer()
                    Text("🇷🇴")
                        .font(.title3)
                    Image(systemName: "wifi")
                        .font(.caption)
                        .foregroundColor(RomanianColors.primaryYellow.opacity(0.8))
                }
                
                HStack(spacing: 6) {
                    Label("\(player.score)", systemImage: "star.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [RomanianColors.goldAccent, RomanianColors.primaryYellow],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                    Text("puncte câștigate")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.12),
                                Color.white.opacity(0.04)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(height: 6)
                    .overlay(
                        Capsule()
                            .fill(RomanianColors.primaryYellow.opacity(0.7))
                            .frame(width: max(CGFloat(player.score) * 18, 12), height: 6)
                            .animation(.easeInOut(duration: 0.6), value: player.score)
                    )
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.black.opacity(0.35))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
            )
        }
    }
    
    private var cardTray: some View {
        ZStack(alignment: .top) {
            RoundedRectangle(cornerRadius: 18)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.black.opacity(0.5),
                            Color.black.opacity(0.35)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(height: 90)
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.35), radius: 8, x: 0, y: 6)
            
            HStack(spacing: -10) {
                ForEach(0..<cardCount, id: \.self) { index in
                    OpponentCardBack(index: index)
                        .zIndex(Double(index))
                }
            }
            .padding(.top, 12)
        }
    }
}

private struct OpponentCardBack: View {
    let index: Int
    
    var body: some View {
        RoundedRectangle(cornerRadius: 10)
            .fill(
                LinearGradient(
                    colors: [
                        RomanianColors.cardBack,
                        RomanianColors.primaryBlue.opacity(0.9)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: 46, height: 66)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.white.opacity(0.15), lineWidth: 1)
            )
            .overlay(
                Text("♣︎")
                    .font(.title2.weight(.bold))
                    .foregroundColor(RomanianColors.goldAccent.opacity(0.35))
            )
            .rotationEffect(.degrees(Double(index % 3) * 2 - 2))
            .offset(y: CGFloat(index % 4) * -3)
            .shadow(color: RomanianColors.primaryBlue.opacity(0.25), radius: 4, x: 0, y: 3)
    }
}

private struct ShuffleCatsInspiredBackground: View {
    var body: some View {
        GeometryReader { geo in
            let size = geo.size
            ZStack {
                LinearGradient(
                    colors: [
                        Color(red: 0.02, green: 0.08, blue: 0.22),
                        Color(red: 0.12, green: 0.26, blue: 0.32),
                        Color(red: 0.05, green: 0.12, blue: 0.09)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                
                // Skyline silhouette inspired by Shuffle Cats backdrop
                VStack {
                    Spacer(minLength: size.height * 0.35)
                    ZStack {
                        RoundedRectangle(cornerRadius: 40)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color(red: 0.78, green: 0.58, blue: 0.45).opacity(0.35),
                                        Color(red: 0.4, green: 0.25, blue: 0.45).opacity(0.45)
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .frame(width: size.width * 1.2, height: size.height * 0.65)
                            .offset(y: size.height * 0.32)
                        
                        HStack(spacing: 18) {
                            ForEach(0..<7) { index in
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                Color.white.opacity(0.05),
                                                Color.black.opacity(0.2)
                                            ],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                                    .frame(width: 40 + CGFloat(index % 3) * 8,
                                           height: 120 + CGFloat((index * 13) % 70))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.white.opacity(0.05), lineWidth: 1)
                                    )
                                    .offset(y: CGFloat((index % 2) * 15))
                            }
                        }
                        .offset(y: size.height * 0.28)
                    }
                }
                
                // Ambient glows
                RadialGradient(
                    colors: [
                        RomanianColors.primaryYellow.opacity(0.15),
                        Color.clear
                    ],
                    center: .top,
                    startRadius: 10,
                    endRadius: size.height * 0.8
                )
                
                RadialGradient(
                    colors: [
                        RomanianColors.goldAccent.opacity(0.10),
                        Color.clear
                    ],
                    center: .center,
                    startRadius: 50,
                    endRadius: size.width
                )
                .blendMode(.screen)
                
                // Floating decorative orbs
                VStack {
                    HStack {
                        Circle()
                            .fill(RomanianColors.primaryYellow.opacity(0.18))
                            .blur(radius: 10)
                            .frame(width: 80, height: 80)
                            .offset(x: -size.width * 0.3, y: -size.height * 0.35)
                        Spacer()
                        Circle()
                            .fill(RomanianColors.primaryBlue.opacity(0.25))
                            .blur(radius: 12)
                            .frame(width: 100, height: 100)
                            .offset(x: size.width * 0.35, y: -size.height * 0.3)
                    }
                    Spacer()
                }
            }
        }
    }
}

// Old button components removed - replaced by premium glass morphism components

// MARK: - Preview

struct PremiumGameScreen_Previews: PreviewProvider {
    static var previews: some View {
        PremiumGameScreen()
    }
}
