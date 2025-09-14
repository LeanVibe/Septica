//
//  MainMenuView.swift
//  Septica
//
//  Main menu view with Romanian cultural design elements
//  Entry point for the Septica card game application
//

import SwiftUI

/// Main menu view displaying the game title and navigation options
struct MainMenuView: View {
    @StateObject private var navigationManager = NavigationManager()
    @StateObject private var userSettings = UserSettings.shared
    @State private var showingContinueOption = false
    @State private var animateTitle = false
    
    var body: some View {
        NavigationStack(path: $navigationManager.navigationPath) {
            ZStack {
                // Romanian-inspired background
                RomanianBackground()
                
                VStack(spacing: 30) {
                    Spacer(minLength: 40)
                    
                    // App title with Romanian styling
                    TitleSection(animated: $animateTitle)
                    
                    Spacer(minLength: 20)
                    
                    // Central PLAY button (Clash Royale style)
                    ClashRoyaleStyleButtons(
                        navigationManager: navigationManager,
                        showingContinue: showingContinueOption
                    )
                    
                    Spacer(minLength: 40)
                    
                    // Footer with cultural elements
                    FooterSection()
                }
                .padding(.horizontal, 20)
            }
            .navigationBarHidden(true)
            .preferredColorScheme(.dark)
            .navigationDestination(for: AppScreen.self) { screen in
                NavigationDestinationView(
                    screen: screen,
                    navigationManager: navigationManager
                )
            }
        }
        .environmentObject(navigationManager)
        .sheet(item: $navigationManager.presentedSheet) { sheet in
            SheetContentView(sheet: sheet, navigationManager: navigationManager)
        }
        .onAppear {
            checkForSavedGame()
            animateTitle = true
        }
    }
    
    /// Check if there's a saved game to offer continue option
    private func checkForSavedGame() {
        showingContinueOption = navigationManager.gameController.hasSavedGame()
    }
}

// MARK: - Main Menu Components

/// Romanian-inspired background with traditional colors and patterns
struct RomanianBackground: View {
    var body: some View {
        ZStack {
            // Base gradient using Romanian flag colors adapted for card game
            LinearGradient(
                colors: [
                    Color(red: 0.1, green: 0.1, blue: 0.2),  // Deep blue-black
                    Color(red: 0.2, green: 0.1, blue: 0.1),  // Deep red-brown
                    Color(red: 0.1, green: 0.15, blue: 0.1)   // Deep green
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // Subtle pattern overlay
            GeometryReader { geometry in
                ForEach(0..<15) { i in
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.white.opacity(0.02))
                        .frame(width: 60, height: 90)
                        .rotationEffect(.degrees(Double.random(in: -15...15)))
                        .position(
                            x: CGFloat.random(in: 0...geometry.size.width),
                            y: CGFloat.random(in: 0...geometry.size.height)
                        )
                }
            }
            
            // Radial highlight in center
            RadialGradient(
                colors: [
                    Color.white.opacity(0.1),
                    Color.clear
                ],
                center: .center,
                startRadius: 50,
                endRadius: 300
            )
        }
        .ignoresSafeArea()
    }
}

/// Main title section with Romanian styling
struct TitleSection: View {
    @Binding var animated: Bool
    
    var body: some View {
        VStack(spacing: 16) {
            // Main title with traditional Romanian card game styling
            HStack(spacing: 0) {
                Text("S")
                    .font(.system(size: 72, weight: .bold, design: .serif))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.red.opacity(0.9), Color.red.opacity(0.7)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .shadow(color: .black.opacity(0.5), radius: 4, x: 2, y: 2)
                
                Text("EPTICA")
                    .font(.system(size: 48, weight: .bold, design: .serif))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.white, Color.gray.opacity(0.8)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .shadow(color: .black.opacity(0.5), radius: 4, x: 2, y: 2)
            }
            .scaleEffect(animated ? 1.0 : 0.8)
            .opacity(animated ? 1.0 : 0.0)
            .animation(.spring(response: 1.2, dampingFraction: 0.8), value: animated)
            
            // Subtitle
            Text("Jocul Tradițional Românesc")
                .font(.system(size: 16, weight: .medium, design: .serif))
                .foregroundColor(.white.opacity(0.8))
                .italic()
                .opacity(animated ? 1.0 : 0.0)
                .animation(.easeInOut(duration: 1.0).delay(0.5), value: animated)
            
            // Decorative card symbols
            HStack(spacing: 20) {
                CardSymbolView(symbol: "♠", color: .black)
                CardSymbolView(symbol: "♦", color: .red)
                CardSymbolView(symbol: "♣", color: .black)
                CardSymbolView(symbol: "♥", color: .red)
            }
            .opacity(animated ? 1.0 : 0.0)
            .animation(.easeInOut(duration: 1.0).delay(1.0), value: animated)
        }
    }
}

/// Decorative card symbol
struct CardSymbolView: View {
    let symbol: String
    let color: Color
    
    var body: some View {
        Text(symbol)
            .font(.system(size: 24, weight: .bold))
            .foregroundColor(color == .black ? .white : color)
            .frame(width: 40, height: 40)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.white.opacity(0.1))
                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
            )
    }
}

/// Clash Royale style main menu with central PLAY button
struct ClashRoyaleStyleButtons: View {
    let navigationManager: NavigationManager
    let showingContinue: Bool
    
    var body: some View {
        VStack(spacing: 30) {
            // Central PLAY button (massive, like Clash Royale BATTLE button)
            Button(action: {
                // Start game directly - no setup screen
                navigationManager.startNewGame(
                    playerName: UserSettings.shared.playerName,
                    difficulty: UserSettings.shared.preferredDifficulty,
                    targetScore: 11
                )
            }) {
                VStack(spacing: 8) {
                    Image(systemName: "play.fill")
                        .font(.system(size: 40, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("PLAY")
                        .font(.system(size: 28, weight: .black, design: .default))
                        .foregroundColor(.white)
                        .tracking(2)
                    
                    if showingContinue {
                        Text("Continue Game")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                    } else {
                        Text("Start New Game")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
                .frame(width: 200, height: 120)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.green.opacity(0.9),
                                    Color.green.opacity(0.7),
                                    Color.green.opacity(0.9)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .shadow(color: .green.opacity(0.5), radius: 10, x: 0, y: 5)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            LinearGradient(
                                colors: [.white.opacity(0.3), .clear],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 2
                        )
                )
            }
            .buttonStyle(PressEffectButtonStyle())
            .scaleEffect(showingContinue ? 1.05 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: showingContinue)
            
            // Secondary options in horizontal row (like Clash Royale)
            HStack(spacing: 20) {
                SmallMenuButton(
                    icon: "chart.bar.fill",
                    color: .purple,
                    action: { navigationManager.showStatistics() }
                )
                
                SmallMenuButton(
                    icon: "book.fill", 
                    color: .orange,
                    action: { navigationManager.showRules() }
                )
                
                SmallMenuButton(
                    icon: "gearshape.fill",
                    color: .gray,
                    action: { navigationManager.showSettings() }
                )
            }
        }
    }
}

/// Small circular buttons for secondary options (Clash Royale style)
struct SmallMenuButton: View {
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.white)
                .frame(width: 50, height: 50)
                .background(
                    Circle()
                        .fill(color.opacity(0.8))
                        .shadow(color: color.opacity(0.3), radius: 5, x: 0, y: 2)
                )
        }
        .buttonStyle(PressEffectButtonStyle())
    }
}

/// Button style with press effect (like Clash Royale)
struct PressEffectButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

/// Individual menu button with Romanian card game styling
struct MenuButton: View {
    let title: String
    let subtitle: String
    let iconName: String
    let color: Color
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(color.opacity(0.2))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: iconName)
                        .font(.title2)
                        .foregroundColor(color)
                }
                
                // Text content
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
                
                // Chevron
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.5))
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.1),
                                Color.white.opacity(0.05)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: isPressed)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity) { isPressing in
            isPressed = isPressing
        } perform: {
            action()
        }
    }
}

/// Footer section with cultural elements
struct FooterSection: View {
    var body: some View {
        VStack(spacing: 8) {
            // Traditional Romanian saying about cards (translated)
            Text("\"Cărțile nu mint niciodată\"")
                .font(.system(size: 14, weight: .medium, design: .serif))
                .foregroundColor(.white.opacity(0.6))
                .italic()
            
            Text("\"Cards never lie\"")
                .font(.caption2)
                .foregroundColor(.white.opacity(0.4))
            
            // Version info
            if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
                Text("Version \(version)")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.3))
                    .padding(.top, 4)
            }
        }
    }
}

// MARK: - Navigation Views

/// Handle navigation destinations
struct NavigationDestinationView: View {
    let screen: AppScreen
    let navigationManager: NavigationManager
    
    var body: some View {
        switch screen {
        case .gameSetup:
            GameSetupView()
                .environmentObject(navigationManager)
        case .gamePlay(let session):
            GameBoardView(gameState: session.gameState)
                .environmentObject(navigationManager)
        case .gameResults(let result, let session):
            GameResultsView(result: result, session: session)
                .environmentObject(navigationManager)
        case .rules:
            RulesView()
                .environmentObject(navigationManager)
        case .statistics:
            StatisticsView()
                .environmentObject(navigationManager)
        case .settings:
            SettingsView()
                .environmentObject(navigationManager)
        case .mainMenu:
            MainMenuView() // Shouldn't reach here in navigation stack
        }
    }
}

/// Handle sheet presentations
struct SheetContentView: View {
    let sheet: PresentedSheet
    let navigationManager: NavigationManager
    
    var body: some View {
        switch sheet {
        case .settings:
            SettingsView()
                .environmentObject(navigationManager)
        case .gameMenu:
            GameMenuView(
                onResume: {
                    navigationManager.dismissSheet()
                },
                onNewGame: {
                    navigationManager.dismissSheet()
                    // Handle new game logic
                },
                onMainMenu: {
                    navigationManager.dismissSheet()
                    navigationManager.returnToMainMenu()
                }
            )
        case .pauseMenu:
            PauseMenuView()
                .environmentObject(navigationManager)
        }
    }
}

/// Pause menu view for in-game pausing
struct PauseMenuView: View {
    @EnvironmentObject var navigationManager: NavigationManager
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Game Paused")
                    .font(.title)
                    .foregroundColor(.white)
                
                VStack(spacing: 16) {
                    Button("Resume Game") {
                        navigationManager.dismissSheet()
                    }
                    .buttonStyle(MenuButtonStyleSimple(color: .green))
                    
                    Button("Save & Exit") {
                        navigationManager.saveAndReturnToMenu()
                        navigationManager.dismissSheet()
                    }
                    .buttonStyle(MenuButtonStyleSimple(color: .blue))
                    
                    Button("Quit Game") {
                        navigationManager.returnToMainMenu()
                        navigationManager.dismissSheet()
                    }
                    .buttonStyle(MenuButtonStyleSimple(color: .red))
                }
                .padding()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.black.opacity(0.9))
            .navigationBarHidden(true)
        }
    }
}

/// Simple button style for menus
struct MenuButtonStyleSimple: ButtonStyle {
    let color: Color
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(color)
            .foregroundColor(.white)
            .font(.headline)
            .cornerRadius(12)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Preview

struct MainMenuView_Previews: PreviewProvider {
    static var previews: some View {
        MainMenuView()
            .previewDevice("iPhone 14 Pro")
            .preferredColorScheme(.dark)
    }
}