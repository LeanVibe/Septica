//
//  MultiplayerReadyGameScreen.swift
//  Septica
//
//  Premium game screen with adaptive card layout and multiplayer support
//  Integrates reference-quality design with Romanian cultural elements
//

import SwiftUI

struct MultiplayerReadyGameScreen: View {
    // Game state
    @StateObject private var gameState = GameStateManager()
    @StateObject private var emoteManager = EmoteManager()
    @StateObject private var animationCoordinator = AnimationCoordinator()
    @State private var selectedCard: Card?
    @State private var showEmoteMenu = false
    @State private var backgroundPulse = false

    // Multiplayer state
    @State private var players: [Player] = []
    @State private var currentPlayerIndex = 0
    @State private var isMultiplayer = false
    @State private var emoteCoordinator: GameEmoteCoordinator?

    // MARK: - Initialization

    init() {
        // Setup emote manager delegate
    }

    // MARK: - Body

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Premium background with enhanced gradient overlay
                premiumBackground

                // Premium gradient overlay with Romanian cultural themes
                if let gradientOverlay = PremiumGradientOverlays.GameScreenGradientOverlay(
                    culturalTheme: .romanianHeritage,
                    animationState: gameState.gamePhase == .ended ? .celebration : .active,
                    isInteractive: true
                ) {
                    gradientOverlay.ignoresSafeArea()
                }

                // Main game layout
                gameLayout(geometry: geometry)

                // Overlay effects
                gameOverlayEffects
            }
        }
        .ignoresSafeArea(edges: .top)
        .onAppear {
            setupGame()
        }
        .onReceive(NotificationCenter.default.publisher(for: .playerDidEmote)) { notification in
            handleRemoteEmote(notification)
        }
    }

    // MARK: - Premium Background

    private var premiumBackground: some View {
        LinearGradient(
            colors: [
                Color(red: 0.05, green: 0.08, blue: 0.18),
                Color(red: 0.12, green: 0.18, blue: 0.32),
                Color(red: 0.08, green: 0.12, blue: 0.16)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .overlay {
            // Subtle pattern overlay
            RomaninanPatternOverlay()
                .opacity(0.15)
        }
        .overlay {
            // Ambient lighting effects
            ambientLightingEffects
        }
    }

    private var ambientLightingEffects: some View {
        ZStack {
            // Top ambient glow
            RadialGradient(
                colors: [
                    RomanianColors.goldAccent.opacity(0.2),
                    Color.clear
                ],
                center: .top,
                startRadius: 50,
                endRadius: 300
            )

            // Center table glow
            RadialGradient(
                colors: [
                    RomanianColors.primaryYellow.opacity(0.15),
                    Color.clear
                ],
                center: .center,
                startRadius: 100,
                endRadius: 400
            )
            .scaleEffect(backgroundPulse ? 1.1 : 1.0)
            .animation(.easeInOut(duration: 4.0).repeatForever(autoreverses: true), value: backgroundPulse)
        }
    }

    // MARK: - Game Layout

    private func gameLayout(geometry: GeometryProxy) -> some View {
        VStack(spacing: 0) {
            // Top status bar
            gameStatusBar
                .padding(.horizontal, 16)
                .padding(.top, geometry.safeAreaInsets.top + 8)

            Spacer()

            // Opponent areas
            opponentAreas

            Spacer()

            // Central game table
            centralGameTable
                .frame(height: min(geometry.size.width, geometry.size.height) * 0.35)

            Spacer()

            // Player hand area
            playerHandArea

            Spacer(minLength: geometry.safeAreaInsets.bottom + 8)
        }
    }

    // MARK: - Game Status Bar

    private var gameStatusBar: some View {
        HStack {
            // Game info
            VStack(alignment: .leading, spacing: 4) {
                Text("Septica Românească")
                    .font(.title3.weight(.bold))
                    .foregroundColor(.white)

                Text("Runda \(gameState.currentRound) • \(gameState.gamePhase.displayText)")
                    .font(.caption.weight(.medium))
                    .foregroundColor(.white.opacity(0.8))
            }

            Spacer()

            // Timer
            if gameState.isTimed {
                TimerView(
                    timeRemaining: gameState.timeRemaining,
                    totalTime: gameState.turnTimeLimit,
                    isWarning: gameState.timeRemaining < 10
                )
            }

            // Menu button
            Button(action: {
                gameState.showGameMenu = true
            }) {
                Image(systemName: "line.3.horizontal")
                    .font(.title2.weight(.medium))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(
                        Circle()
                            .fill(Color.white.opacity(0.1))
                            .overlay(
                                Circle()
                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                            )
                    )
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.black.opacity(0.3))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }

    // MARK: - Opponent Areas

    private var opponentAreas: some View {
        GeometryReader { geometry in
            let opponentCount = max(0, players.count - 1)
            let availableWidth = geometry.size.width - 40
            let spacing: CGFloat = opponentCount > 1 ? 16 : 0
            let cardWidth = (availableWidth - spacing * CGFloat(opponentCount - 1)) / CGFloat(opponentCount)

            HStack(spacing: spacing) {
                ForEach(Array(players.dropFirst().enumerated()), id: \.element.id) { index, opponent in
                    ZStack {
                        AdaptivePlayerHandView(
                            player: opponent,
                            selectedCard: nil,
                            validMoves: [],
                            onCardSelected: { _ in },
                            onCardPlayed: { _ in },
                            isCurrentPlayer: index == currentPlayerIndex - 1,
                            isInteractionEnabled: false,
                            playerType: .ai // Will be .remote for multiplayer
                        )

                        // Emote overlay for this player
                        if let coordinator = emoteCoordinator {
                            AnyView(coordinator.emoteOverlay(for: opponent.id))
                                .offset(y: -60)
                        }
                    }
                    .frame(width: min(cardWidth, 200))
                }
            }
            .frame(width: geometry.size.width)
        }
        .frame(height: 120)
    }

    // MARK: - Central Game Table

    private var centralGameTable: some View {
        ZStack {
            // Table surface with premium styling
            RoundedRectangle(cornerRadius: 24)
                .fill(
                    RadialGradient(
                        colors: [
                            RomanianColors.tableGreen.opacity(0.9),
                            RomanianColors.tableGreen.opacity(0.6),
                            RomanianColors.primaryBlue.opacity(0.3)
                        ],
                        center: .center,
                        startRadius: 50,
                        endRadius: 200
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    RomanianColors.goldAccent.opacity(0.6),
                                    Color.clear,
                                    RomanianColors.goldAccent.opacity(0.6)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                )
                .shadow(color: .black.opacity(0.4), radius: 16, x: 0, y: 8)

            // Table cards layout
            if !gameState.tableCards.isEmpty {
                tableCardsLayout
            } else {
                tableEmptyState
            }

            // Game state indicators
            gameStateIndicators
        }
        .padding(.horizontal, 20)
    }

    private var tableCardsLayout: some View {
        GeometryReader { geometry in
            let tableSize = geometry.size
            let cardCount = gameState.tableCards.count

            if cardCount <= 4 {
                // Small layout - single row
                HStack(spacing: 12) {
                    ForEach(Array(gameState.tableCards.enumerated()), id: \.element.id) { index, tableCard in
                        tableCardView(tableCard, at: index, in: tableSize)
                    }
                }
                .frame(width: tableSize.width, height: tableSize.height)
            } else {
                // Large layout - circular arrangement
                ForEach(Array(gameState.tableCards.enumerated()), id: \.element.id) { index, tableCard in
                    let angle = Double(index) * (360.0 / Double(cardCount)) * (.pi / 180.0)
                    let radius = min(tableSize.width, tableSize.height) * 0.25

                    tableCardView(tableCard, at: index, in: tableSize)
                        .position(
                            x: tableSize.width / 2 + cos(angle) * radius,
                            y: tableSize.height / 2 + sin(angle) * radius
                        )
                }
            }
        }
    }

    private func tableCardView(_ tableCard: TableCard, at index: Int, in tableSize: CGSize) -> some View {
        let transform = AdaptiveCardLayoutSystem.tableCardTransform(
            for: tableCard,
            at: gameState.tableCards.count <= 4 ? .center : .playerSide(index),
            tableSize: tableSize
        )

        // Create enhanced material properties for table cards
        let materialProperties = createTableCardMaterialProperties(for: tableCard.card)
        let lightingEnvironment = createTableCardLightingEnvironment()
        let cardTransform = createTableCardTransform(from: transform)

        return ProfessionalCardView(
            card: tableCard.card,
            isSelected: false,
            isPlayable: false,
            isAnimating: tableCard.isWinning,
            cardSize: .small,
            professionalRenderer: gameState.professionalCardRenderer,
            transform: cardTransform,
            materialProperties: materialProperties,
            lightingEnvironment: lightingEnvironment,
            onTap: nil,
            onDragChanged: nil,
            onDragEnded: nil
        )
        .offset(transform.position)
        .rotationEffect(transform.rotation)
        .scaleEffect(transform.scale)
        .zIndex(transform.zOffset)
        .shadow(color: .black.opacity(0.4), radius: 6, x: 0, y: 3)
        .overlay {
            if tableCard.isWinning {
                enhancedWinningCardOverlay
            }
        }
    }

    // MARK: - Enhanced Material Properties

    private func createTableCardMaterialProperties(for card: Card) -> MaterialProperties {
        var properties = MaterialProperties()

        // Base material for table cards
        properties.albedo = Color.white.toSIMD3()
        properties.metallicFactor = 0.15
        properties.roughnessFactor = 0.7
        properties.folkPatternIntensity = 0.6

        // Card-specific enhancements
        if card.value == 7 {
            properties.mysticalGlow = 1.0
            properties.traditionalCraftsmanship = 0.8
        } else if card.isPointCard {
            properties.goldLeafEffect = 0.9
            properties.byzantineInfluence = 0.7
        }

        // Romanian cultural themes
        properties.regionalVariationIntensity = 0.5
        properties.carpathianHeritage = 0.3
        properties.monasticTradition = 0.4

        return properties
    }

    private func createTableCardLightingEnvironment() -> LightingEnvironment {
        return LightingEnvironment(
            primaryLightDirection: simd_float3(0.2, 1.0, 0.6),
            primaryLightColor: Color.white.toSIMD3(),
            ambientLightColor: RomanianColors.goldAccent.toSIMD3() * 0.4,
            lightIntensity: 1.2,
            shadowBias: 0.0008,
            romanianCulturalTint: RomanianColors.primaryBlue.toSIMD3() * 0.3
        )
    }

    private func createTableCardTransform(from simpleTransform: CardTransform) -> SimpleTransform {
        return SimpleTransform(
            perspective: 0.4,
            rotationX: simpleTransform.rotation.degrees * 0.1,
            rotationY: simpleTransform.rotation.degrees * 0.2,
            rotationZ: simpleTransform.rotation.degrees,
            translation: simd_float3(
                Float(simpleTransform.position.x),
                Float(simpleTransform.position.y),
                Float(simpleTransform.zOffset)
            ),
            lightingVector: simd_float3(0.2, 1.0, 0.5)
        )
    }

    private var enhancedWinningCardOverlay: some View {
        RoundedRectangle(cornerRadius: 8)
            .stroke(
                LinearGradient(
                    colors: [
                        RomanianColors.goldAccent,
                        RomanianColors.primaryYellow,
                        RomanianColors.goldAccent,
                        RomanianColors.byzantineGold
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 4
            )
            .shadow(color: RomanianColors.goldAccent.opacity(0.8), radius: 12)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.6),
                                Color.clear
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
    }

    private var winningCardOverlay: some View {
        RoundedRectangle(cornerRadius: 8)
            .stroke(
                LinearGradient(
                    colors: [
                        RomanianColors.goldAccent,
                        RomanianColors.primaryYellow,
                        RomanianColors.goldAccent
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 3
            )
            .shadow(color: RomanianColors.goldAccent.opacity(0.6), radius: 8)
    }

    private var tableEmptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "rectangle.stack.fill")
                .font(.title)
                .foregroundColor(.white.opacity(0.3))

            Text("Așteptare cărți")
                .font(.caption.weight(.medium))
                .foregroundColor(.white.opacity(0.4))
        }
    }

    private var gameStateIndicators: some View {
        VStack {
            HStack {
                Spacer()

                // Turn indicator
                if gameState.isPlayerTurn {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(RomanianColors.countrysideGreen)
                            .frame(width: 8, height: 8)
                            .scaleEffect(1.2)
                            .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: gameState.isPlayerTurn)

                        Text("Turnul tău")
                            .font(.caption.weight(.semibold))
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(Color.black.opacity(0.5))
                            .overlay(
                                Capsule()
                                    .stroke(RomanianColors.countrysideGreen, lineWidth: 1)
                            )
                    )
                }

                Spacer()
            }

            Spacer()
        }
        .padding(.top, 12)
        .padding(.horizontal, 16)
    }

    // MARK: - Player Hand Area

    private var playerHandArea: some View {
        VStack(spacing: 16) {
            // Player hand
            Group {
                if let humanPlayer = players.first {
                    AdaptivePlayerHandView(
                        player: humanPlayer,
                        selectedCard: selectedCard,
                        validMoves: gameState.validMoves,
                        onCardSelected: { card in
                            // Coordinate card selection animation
                            animationCoordinator.coordinateCardSelection(
                                cardId: card.id,
                                characterType: humanPlayer.romanianAvatar ?? .pacala
                            ) {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    selectedCard = card
                                }
                            }
                        },
                        onCardPlayed: { card in
                            playCard(card)
                        },
                        isCurrentPlayer: gameState.isPlayerTurn,
                        isInteractionEnabled: gameState.isPlayerTurn,
                        playerType: .human
                    )
                    .padding(.horizontal, 16)
                }
            }

            // Premium glass morphism action buttons
            if gameState.isPlayerTurn {
                premiumGameActionButtons
                    .padding(.horizontal, 16)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
    }

    // MARK: - Premium Game Action Buttons

    private var premiumGameActionButtons: some View {
        HStack(spacing: 20) {
            // Secondary glass button - Pass action
            PremiumButtonComponents.PremiumGlassSecondaryButton(
                title: "Treci",
                iconName: "hand.raised.fill",
                culturalTheme: .carpathian
            ) {
                // Handle pass action
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    selectedCard = nil
                    // Process pass turn
                    gameState.processPlayerPass()
                }
            }
            .accessibilityEnhanced()

            // Primary glass button - Play action
            PremiumButtonComponents.PremiumGlassButton(
                title: "Joacă",
                subtitle: selectedCard != nil ? "Confirmă cartea" : "Selectează carte",
                iconName: "play.fill",
                style: .primary
            ) {
                if let card = selectedCard {
                    playCard(card)
                }
            }
            .disabled(selectedCard == nil)
            .accessibilityEnhanced()

            // Secondary glass button - Menu action
            PremiumButtonComponents.PremiumGlassSecondaryButton(
                title: "Meniu",
                iconName: "line.3.horizontal",
                culturalTheme: .traditional
            ) {
                // Handle menu action
                gameState.showGameMenu = true
            }
            .accessibilityEnhanced()
        }
    }

    // MARK: - Game Overlay Effects

    private var gameOverlayEffects: some View {
        ZStack {
            // Victory/defeat overlays
            if gameState.gamePhase == .ended {
                gameEndOverlay
            }

            // Emote effects
            if showEmoteMenu {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .onTapGesture {
                        showEmoteMenu = false
                    }

                // Emote selection menu
                emoteSelectionMenu
                    .transition(.scale.combined(with: .opacity))
            }

            // Premium floating action button
            VStack {
                HStack {
                    Spacer()
                    PremiumButtonComponents.PremiumFloatingActionButton(
                        iconName: "heart.fill",
                        culturalAccent: .gold
                    ) {
                        // Handle favorite/emote action
                        toggleEmoteMenu()
                    }
                    .accessibilityEnhanced()
                    .padding(.trailing, 24)
                    .padding(.top, 100)
                }
                Spacer()
            }
        }
    }

    private func toggleEmoteMenu() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            showEmoteMenu.toggle()
        }
    }

    private var emoteSelectionMenu: some View {
        VStack(spacing: 20) {
            Text("Alege Emoticon")
                .font(.title2.bold())
                .foregroundColor(.white)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 16) {
                ForEach(EmoteType.allCases, id: \.self) { emoteType in
                    EmoteButton(emoteType: emoteType) {
                        sendEmote(emoteType)
                        showEmoteMenu = false
                    }
                }
            }
            .padding()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.black.opacity(0.8))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(RomanianColors.goldAccent, lineWidth: 2)
                )
        )
        .padding()
    }

    private func sendEmote(_ emoteType: EmoteType) {
        guard let currentPlayer = players.first,
              let coordinator = emoteCoordinator else {
            return
        }

        Task {
            await coordinator.sendEmote(
                emoteType,
                from: currentPlayer.id,
                in: "current_game" // TODO: Use actual game ID
            )
        }
    }

    private var gameEndOverlay: some View {
        ZStack {
            // Background overlay
            Color.black.opacity(0.7)
                .ignoresSafeArea()

            // Content
            VStack(spacing: 24) {
                // Result icon
                Image(systemName: gameState.playerWon ? "trophy.fill" : "heart.fill")
                    .font(.system(size: 60))
                    .foregroundColor(gameState.playerWon ? RomanianColors.goldAccent : RomanianColors.embroideryRed)

                // Result text
                Text(gameState.playerWon ? "Victorie!" : "Înfrângere")
                    .font(.largeTitle.weight(.black))
                    .foregroundColor(.white)

                // Score
                Text("Scor: \(gameState.playerScore) - \(gameState.opponentScore)")
                    .font(.title2.weight(.semibold))
                    .foregroundColor(.white.opacity(0.9))

                // Action buttons
                HStack(spacing: 16) {
                    Button("Joc Nou") {
                        gameState.startNewGame()
                    }
                    .buttonStyle(PrimaryButtonStyle())

                    Button("Meniu") {
                        gameState.returnToMenu()
                    }
                    .buttonStyle(SecondaryButtonStyle())
                }
                .onAppear {
                    // Trigger victory celebration animation
                    if gameState.playerWon, let humanPlayer = players.first {
                        animationCoordinator.coordinateVictoryCelebration(
                            characterType: humanPlayer.romanianAvatar ?? .pacala,
                            victoryType: .decisive
                        )
                    }
                }
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.black.opacity(0.8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
            )
            .padding(40)
        }
    }

    // MARK: - Game Logic

    private func setupGame() {
        // Initialize players
        let humanPlayer = Player(name: "Tu")
        humanPlayer.romanianAvatar = .pacala
        humanPlayer.hand = generateRandomHand(count: 6)

        let aiPlayer = Player(name: "Păcală AI")
        aiPlayer.romanianAvatar = .pacala
        aiPlayer.hand = generateRandomHand(count: 6)

        players = [humanPlayer, aiPlayer]

        // Initialize emote coordinator
        emoteCoordinator = GameEmoteCoordinator(
            gameScreen: self,
            emoteManager: emoteManager,
            players: players
        )

        // Start background pulse
        backgroundPulse = true

        // Coordinate card dealing animation
        animationCoordinator.coordinateCardDealing(
            playerCount: players.count,
            cardsPerPlayer: 6,
            dealingStyle: .smooth
        ) {
            // Initialize game state after dealing animation
            self.gameState.setupGame(players: self.players)
        }
    }

    private func generateRandomHand(count: Int) -> [Card] {
        let suits: [Card.Suit] = [.hearts, .diamonds, .clubs, .spades]
        let values: [Int] = [7, 8, 9, 10, 11, 12, 13, 14]

        return (0..<count).map { _ in
            Card(
                suit: suits.randomElement()!,
                value: values.randomElement()!
            )
        }
    }

    private func playCard(_ card: Card) {
        guard let humanPlayer = players.first,
              let cardIndex = humanPlayer.hand.firstIndex(where: { $0.id == card.id }) else { return }

        // Calculate animation positions
        let handPosition = CGPoint(x: 200, y: 500) // Approximate hand position
        let tablePosition = CGPoint(x: 200, y: 300) // Approximate table position

        // Coordinate card play animation with trajectory
        animationCoordinator.coordinateCardPlay(
            card: card,
            from: handPosition,
            to: tablePosition,
            characterType: humanPlayer.romanianAvatar ?? .pacala
        ) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                // Remove card from player hand
                humanPlayer.hand.remove(at: cardIndex)

                // Add to table
                let tableCard = TableCard(
                    card: card,
                    playOrder: self.gameState.tableCards.count,
                    isWinning: self.isWinningCard(card)
                )
                self.gameState.tableCards.append(tableCard)

                // Clear selection
                self.selectedCard = nil

                // Process turn
                self.gameState.processPlayerTurn()
            }
        }

        // AI plays after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.aiPlayTurn()
        }
    }

    private func aiPlayTurn() {
        guard players.count > 1 else { return }

        let aiPlayer = players[1]
        guard !aiPlayer.hand.isEmpty else { return }

        let cardToPlay = aiPlayer.hand.randomElement()!

        // Calculate animation positions for AI
        let aiHandPosition = CGPoint(x: 200, y: 100) // Approximate AI hand position
        let tablePosition = CGPoint(x: 200, y: 300) // Table position

        // Coordinate AI card play animation
        animationCoordinator.coordinateCardPlay(
            card: cardToPlay,
            from: aiHandPosition,
            to: tablePosition,
            characterType: aiPlayer.romanianAvatar ?? .pacala
        ) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                // Remove card from AI hand
                if let index = aiPlayer.hand.firstIndex(where: { $0.id == cardToPlay.id }) {
                    aiPlayer.hand.remove(at: index)
                }

                // Add to table
                let tableCard = TableCard(
                    card: cardToPlay,
                    playOrder: self.gameState.tableCards.count,
                    isWinning: self.isWinningCard(cardToPlay)
                )
                self.gameState.tableCards.append(tableCard)

                // Process turn
                self.gameState.processAITurn()
            }
        }
    }

    private func isWinningCard(_ card: Card) -> Bool {
        // Simplified winning logic
        return card.value == 14 || card.value == 10
    }

    private func handleRemoteEmote(_ notification: Notification) {
        // Handle emote notifications from other players
        if let emoteData = notification.object as? EmoteData {
            // Find player to get character type
            guard let player = players.first(where: { $0.id == emoteData.playerId }) else {
                print("⚠️ Unknown player for emote: \(emoteData.playerId)")
                return
            }

            // Create EmoteMessage for the manager
            let emoteMessage = EmoteMessage(
                playerId: emoteData.playerId,
                emoteType: emoteData.emote,
                gameId: "current_game", // TODO: Get actual game ID
                characterType: player.romanianAvatar.characterType,
                targetPlayerId: nil,
                intensity: 1.0,
                duration: getEmoteDuration(emoteData.emote)
            )

            // Process through emote manager
            Task {
                do {
                    try await emoteManager.receiveEmote(emoteMessage)
                } catch {
                    print("⚠️ Failed to process remote emote: \(error)")
                }
            }
        }
    }

    private func getEmoteDuration(_ emoteType: EmoteType) -> TimeInterval {
        switch emoteType {
        case .greeting: return 2.0
        case .goodMove: return 1.5
        case .badMove: return 2.0
        case .thinking: return 3.0
        case .taunt: return 2.5
        case .victory: return 4.0
        case .defeat: return 2.0
        }
    }
}

// MARK: - Supporting Views

struct TimerView: View {
    let timeRemaining: TimeInterval
    let totalTime: TimeInterval
    let isWarning: Bool

    private var progress: Double {
        max(0, timeRemaining / totalTime)
    }

    var body: some View {
        VStack(spacing: 4) {
            Text("\(Int(timeRemaining))s")
                .font(.caption.weight(.semibold))
                .foregroundColor(isWarning ? RomanianColors.embroideryRed : .white)

            // Progress bar
            Capsule()
                .fill(Color.white.opacity(0.2))
                .frame(width: 40, height: 4)
                .overlay(
                    Capsule()
                        .fill(isWarning ? RomanianColors.embroideryRed : RomanianColors.countrysideGreen)
                        .frame(width: 40 * progress, height: 4)
                        .animation(.linear(duration: 1.0), value: timeRemaining)
                )
        }
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline.weight(.semibold))
            .foregroundColor(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(RomanianColors.goldAccent)
                    .shadow(color: RomanianColors.goldAccent.opacity(0.4), radius: 8, x: 0, y: 4)
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline.weight(.semibold))
            .foregroundColor(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

struct RomaninanPatternOverlay: View {
    var body: some View {
        Canvas { context, size in
            // Draw subtle Romanian folk pattern overlay
            let patternSize: CGFloat = 40
            let cols = Int(size.width / patternSize)
            let rows = Int(size.height / patternSize)

            for row in 0..<rows {
                for col in 0..<cols {
                    let x = CGFloat(col) * patternSize + patternSize / 2
                    let y = CGFloat(row) * patternSize + patternSize / 2

                    // Simple geometric pattern
                    let path = Path { path in
                        path.addEllipse(in: CGRect(x: x - 2, y: y - 2, width: 4, height: 4))
                    }

                    context.fill(path, with: .color(.white.opacity(0.1)))
                }
            }
        }
    }
}

// MARK: - Game State Manager

@MainActor
class GameStateManager: ObservableObject {
    @Published var currentRound = 1
    @Published var gamePhase: GameScreenPhase = .playing
    @Published var tableCards: [TableCard] = []
    @Published var validMoves: [Card] = []
    @Published var isPlayerTurn = true
    @Published var isTimed = true
    @Published var timeRemaining: TimeInterval = 30
    @Published var turnTimeLimit: TimeInterval = 30
    @Published var playerScore = 0
    @Published var opponentScore = 0
    @Published var playerWon = false
    @Published var showGameMenu = false

    // Professional rendering system
    @Published var professionalCardRenderer: ProfessionalCardRenderer? = nil

    func setupGame(players: [Player]) {
        // Initialize professional card renderer
        initializeProfessionalRenderer()

        // Initialize game state with players
        validMoves = players.first?.hand ?? []
        startTurnTimer()
    }

    private func initializeProfessionalRenderer() {
        // Initialize the professional card renderer for enhanced visual quality
        do {
            professionalCardRenderer = try ProfessionalCardRenderer()
            print("✅ Professional card renderer initialized successfully")
        } catch {
            print("⚠️ Failed to initialize professional card renderer: \(error)")
            professionalCardRenderer = nil
        }
    }

    func startTurnTimer() {
        timeRemaining = turnTimeLimit

        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            if self.timeRemaining > 0 {
                self.timeRemaining -= 1
            } else {
                timer.invalidate()
                self.handleTimeOut()
            }
        }
    }

    func processPlayerTurn() {
        isPlayerTurn = false
        // Process game logic
    }

    func processPlayerPass() {
        isPlayerTurn = false
        // Process pass logic
        validMoves = []

        // AI plays after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            self.aiPlayTurn()
        }
    }

    func processAITurn() {
        isPlayerTurn = true
        validMoves = generateValidMoves()
        startTurnTimer()
    }

    func generateValidMoves() -> [Card] {
        // Generate valid moves based on game state
        return []
    }

    func handleTimeOut() {
        // Handle timeout situation
        processPlayerTurn()
    }

    func startNewGame() {
        // Reset game state
        currentRound = 1
        gamePhase = .playing
        tableCards = []
        playerScore = 0
        opponentScore = 0
    }

    func returnToMenu() {
        // Return to main menu
    }
}

enum GameScreenPhase: String, Codable {
    case playing
    case ended

    var displayText: String {
        switch self {
        case .playing: return "În Joc"
        case .ended: return "Finalizat"
        }
    }
}

struct EmoteButton: View {
    let emoteType: EmoteType
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Text(emoteIcon)
                    .font(.system(size: 40))

                Text(emoteType.rawValue)
                    .font(.caption2.bold())
                    .foregroundColor(.white)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
            }
            .frame(width: 80, height: 90)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            colors: [
                                RomanianColors.primaryBlue.opacity(0.3),
                                RomanianColors.primaryBlue.opacity(0.5)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(RomanianColors.goldAccent.opacity(0.5), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private var emoteIcon: String {
        switch emoteType {
        case .greeting: return "👋"
        case .goodMove: return "👍"
        case .badMove: return "👎"
        case .thinking: return "🤔"
        case .taunt: return "😏"
        case .victory: return "🎉"
        case .defeat: return "😢"
        }
    }
}

// MARK: - Preview

struct MultiplayerReadyGameScreen_Previews: PreviewProvider {
    static var previews: some View {
        MultiplayerReadyGameScreen()
            .preferredColorScheme(.dark)
    }
}