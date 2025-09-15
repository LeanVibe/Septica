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
                // Premium Romanian cultural background
                premiumBackground
                
                VStack(spacing: 0) {
                    // Top game status bar
                    GameStatusView(
                        currentPlayer: currentPlayer,
                        opponentPlayer: opponentPlayer,
                        gameRound: gameRound,
                        totalRounds: 5,
                        turnTimeRemaining: turnTimeRemaining,
                        totalTurnTime: 30,
                        gamePhase: .playing
                    )
                    .padding(.horizontal)
                    .padding(.top, geometry.safeAreaInsets.top + 8)
                    
                    Spacer()
                    
                    // Opponent hand area with premium styling
                    VStack(spacing: 8) {
                        Text("Adversar")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [
                                        RomanianColors.primaryYellow.opacity(0.8),
                                        RomanianColors.goldAccent.opacity(0.6)
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                        
                        // Opponent cards (face down with premium effects)
                        HStack(spacing: -8) {
                            ForEach(0..<opponentPlayer.hand.count, id: \.self) { index in
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                RomanianColors.cardBack,
                                                RomanianColors.primaryBlue.opacity(0.8)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 45, height: 63) // Small cards for opponent
                                    .overlay(
                                        // Romanian folk pattern on card backs
                                        Text("♦")
                                            .font(.title2)
                                            .foregroundColor(RomanianColors.goldAccent.opacity(0.3))
                                    )
                                    .shadow(color: RomanianColors.primaryBlue.opacity(0.3), radius: 4, x: 0, y: 2)
                                    .offset(y: CGFloat(index % 2) * -4) // Subtle fan effect
                                    .zIndex(Double(index))
                            }
                        }
                    }
                    
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
                        isInteractionEnabled: true
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
            }
        }
        .ignoresSafeArea(edges: .top)
        .onAppear {
            setupInitialGameState()
            backgroundPulse = true
        }
    }
    
    // MARK: - Premium Background
    
    private var premiumBackground: some View {
        ZStack {
            // Base Romanian cultural gradient
            LinearGradient(
                colors: [
                    Color(red: 0.05, green: 0.15, blue: 0.05),
                    RomanianColors.tableGreen.opacity(0.3),
                    Color(red: 0.08, green: 0.20, blue: 0.08),
                    RomanianColors.primaryBlue.opacity(0.1)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // Subtle Romanian pattern overlay
            RadialGradient(
                colors: [
                    RomanianColors.goldAccent.opacity(0.05),
                    Color.clear,
                    RomanianColors.primaryYellow.opacity(0.03)
                ],
                center: .center,
                startRadius: 100,
                endRadius: 400
            )
            .scaleEffect(backgroundPulse ? 1.1 : 1.0)
            .animation(.easeInOut(duration: 4.0).repeatForever(autoreverses: true), value: backgroundPulse)
        }
    }
    
    // MARK: - Premium Action Buttons
    
    private var premiumActionButtons: some View {
        HStack(spacing: 16) {
            // Romanian-styled pass button
            Button(action: {
                // Handle pass action
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "hand.raised.fill")
                    Text("Treci")
                        .font(.headline.weight(.semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(
                    LinearGradient(
                        colors: [
                            RomanianColors.primaryBlue.opacity(0.8),
                            RomanianColors.primaryBlue
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(color: RomanianColors.primaryBlue.opacity(0.4), radius: 6, x: 0, y: 3)
            }
            
            Spacer()
            
            // Romanian-styled menu button
            Button(action: {
                // Handle menu action
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "line.3.horizontal")
                    Text("Meniu")
                        .font(.headline.weight(.semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(
                    LinearGradient(
                        colors: [
                            RomanianColors.primaryRed.opacity(0.8),
                            RomanianColors.primaryRed
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(color: RomanianColors.primaryRed.opacity(0.4), radius: 6, x: 0, y: 3)
            }
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

// MARK: - Preview

struct PremiumGameScreen_Previews: PreviewProvider {
    static var previews: some View {
        PremiumGameScreen()
    }
}