//
//  SettingsView.swift
//  Septica
//
//  Settings view for app configuration and preferences
//  Handles sound, animations, themes, and other user preferences
//

import SwiftUI

/// Settings view for configuring app preferences and options
struct SettingsView: View {
    @EnvironmentObject var navigationManager: NavigationManager
    @StateObject var userSettings = UserSettings.shared
    @StateObject private var accessibilityManager = AccessibilityManager()
    @StateObject private var hapticManager = HapticManager()
    @StateObject private var audioManager = AudioManager()
    @State private var showingResetConfirmation = false
    @State private var showingAbout = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Settings sections
                VStack(spacing: 16) {
                    // Accessibility settings - prioritized at top
                    AccessibilitySettingsSection()
                        .environmentObject(accessibilityManager)
                        .environmentObject(hapticManager)
                        .environmentObject(audioManager)
                    
                    // Audio settings
                    AudioSettingsSection()
                        .environmentObject(audioManager)
                    
                    // Visual settings
                    VisualSettingsSection()
                        .environmentObject(accessibilityManager)
                    
                    // Gameplay settings
                    GameplaySettingsSection()
                    
                    // Data and privacy
                    DataPrivacySection(showingReset: $showingResetConfirmation)
                    
                    // About section
                    AboutSection(showingAbout: $showingAbout)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 20)
            }
        }
        .background(RomanianSettingsBackground())
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.large)
        .accessibilityLabel("Settings Screen")
        .accessibilityHint("Configure app preferences and accessibility options")
        .alert("Reset Statistics", isPresented: $showingResetConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) {
                resetAllData()
            }
        } message: {
            Text("This will permanently delete all your game statistics and progress. This action cannot be undone.")
        }
        .sheet(isPresented: $showingAbout) {
            AboutSheet()
        }
        .onDisappear {
            userSettings.saveSettings()
        }
    }
    
    private func resetAllData() {
        // Reset user defaults
        let domain = Bundle.main.bundleIdentifier!
        UserDefaults.standard.removePersistentDomain(forName: domain)
        UserDefaults.standard.synchronize()
        
        // Reset user settings to defaults
        userSettings.soundEnabled = true
        userSettings.animationSpeed = .normal
        userSettings.cardTheme = .classic
        userSettings.playerName = "Player"
        userSettings.preferredDifficulty = .medium
        
        // Could also reset game history in GameController if accessible
    }
}

// MARK: - Settings Sections

/// Comprehensive accessibility settings section
struct AccessibilitySettingsSection: View {
    @EnvironmentObject var accessibilityManager: AccessibilityManager
    @EnvironmentObject var hapticManager: HapticManager
    @EnvironmentObject var audioManager: AudioManager
    
    var body: some View {
        SettingsCard(title: "Accessibility", icon: "accessibility") {
            VStack(spacing: 20) {
                // VoiceOver and screen reader support
                VStack(alignment: .leading, spacing: 12) {
                    Text("Screen Reader Support")
                        .font(.subheadline.bold())
                        .foregroundColor(.white)
                    
                    SettingsToggle(
                        title: "Announce Game State",
                        subtitle: "Voice descriptions of game events",
                        isOn: Binding(
                            get: { accessibilityManager.announceGameState },
                            set: { accessibilityManager.setAnnounceGameState($0) }
                        )
                    )
                    
                    SettingsToggle(
                        title: "Announce Card Details",
                        subtitle: "Detailed card descriptions",
                        isOn: Binding(
                            get: { accessibilityManager.announceCardDetails },
                            set: { accessibilityManager.setAnnounceCardDetails($0) }
                        )
                    )
                }
                
                Divider().background(Color.white.opacity(0.2))
                
                // Haptic feedback settings
                VStack(alignment: .leading, spacing: 12) {
                    Text("Haptic Feedback")
                        .font(.subheadline.bold())
                        .foregroundColor(.white)
                    
                    if hapticManager.supportsHaptics {
                        Picker("Haptic Level", selection: Binding(
                            get: { accessibilityManager.hapticFeedbackLevel },
                            set: { accessibilityManager.setHapticFeedbackLevel($0) }
                        )) {
                            ForEach(AccessibilityManager.HapticLevel.allCases, id: \.self) { level in
                                Text(level.rawValue).tag(level)
                            }
                        }
                        .pickerStyle(.segmented)
                        .accentColor(.blue)
                    } else {
                        Text("Haptic feedback not available on this device")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
                
                Divider().background(Color.white.opacity(0.2))
                
                // Game speed adjustment
                VStack(alignment: .leading, spacing: 12) {
                    Text("Game Speed")
                        .font(.subheadline.bold())
                        .foregroundColor(.white)
                    
                    Picker("Speed", selection: Binding(
                        get: { accessibilityManager.gameSpeedAdjustment },
                        set: { accessibilityManager.setGameSpeedAdjustment($0) }
                    )) {
                        ForEach(AccessibilityManager.SpeedAdjustment.allCases, id: \.self) { speed in
                            Text(speed.rawValue).tag(speed)
                        }
                    }
                    .pickerStyle(.segmented)
                    .accentColor(.blue)
                }
                
                // Accessibility status info
                if accessibilityManager.isVoiceOverEnabled {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("VoiceOver Active")
                                .font(.caption.bold())
                                .foregroundColor(.green)
                        }
                        
                        Text("VoiceOver is currently active. All accessibility features are optimized for screen reader use.")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .padding(.top, 8)
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Accessibility Settings")
        .accessibilityHint("Configure screen reader, haptic feedback, and other accessibility options")
    }
}

/// Audio and sound settings
struct AudioSettingsSection: View {
    @StateObject var userSettings = UserSettings.shared
    @EnvironmentObject var audioManager: AudioManager
    
    var body: some View {
        SettingsCard(title: "Audio", icon: "speaker.wave.2.fill") {
            VStack(spacing: 16) {
                SettingsToggle(
                    title: "Sound Effects",
                    subtitle: "Card sounds and game audio",
                    isOn: $userSettings.soundEnabled
                )
                
                // Volume slider could be added here if implemented
                if userSettings.soundEnabled {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Audio Volume")
                            .font(.subheadline)
                            .foregroundColor(.white)
                        
                        HStack {
                            Image(systemName: "speaker.fill")
                                .foregroundColor(.gray)
                            
                            Slider(value: .constant(0.8), in: 0...1)
                                .accentColor(.blue)
                                .disabled(true) // Placeholder for future implementation
                            
                            Image(systemName: "speaker.wave.3.fill")
                                .foregroundColor(.gray)
                        }
                        .font(.caption)
                    }
                    .transition(.opacity.combined(with: .slide))
                }
            }
        }
    }
}

/// Visual appearance settings
struct VisualSettingsSection: View {
    @StateObject var userSettings = UserSettings.shared
    
    var body: some View {
        SettingsCard(title: "Appearance", icon: "paintbrush.fill") {
            VStack(spacing: 20) {
                // Animation speed
                VStack(alignment: .leading, spacing: 12) {
                    Text("Animation Speed")
                        .font(.subheadline)
                        .foregroundColor(.white)
                    
                    Picker("Animation Speed", selection: $userSettings.animationSpeed) {
                        ForEach(AnimationSpeed.allCases) { speed in
                            Text(speed.displayName).tag(speed)
                        }
                    }
                    .pickerStyle(.segmented)
                    .accentColor(.blue)
                }
                
                Divider()
                    .background(Color.white.opacity(0.2))
                
                // Card theme
                VStack(alignment: .leading, spacing: 12) {
                    Text("Card Theme")
                        .font(.subheadline)
                        .foregroundColor(.white)
                    
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 12) {
                        ForEach(CardTheme.allCases) { theme in
                            CardThemeButton(
                                theme: theme,
                                isSelected: userSettings.cardTheme == theme,
                                action: {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        userSettings.cardTheme = theme
                                    }
                                }
                            )
                        }
                    }
                }
            }
        }
    }
}

/// Card theme selection button
struct CardThemeButton: View {
    let theme: CardTheme
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                // Theme preview icon
                RoundedRectangle(cornerRadius: 8)
                    .fill(themePreviewColor)
                    .frame(height: 50)
                    .overlay(
                        Text(themePreviewSymbol)
                            .font(.title2)
                            .foregroundColor(.white)
                    )
                
                Text(theme.displayName)
                    .font(.caption)
                    .foregroundColor(isSelected ? .white : .white.opacity(0.7))
            }
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.blue.opacity(0.3) : Color.clear)
                    .stroke(
                        isSelected ? Color.blue : Color.white.opacity(0.2),
                        lineWidth: isSelected ? 2 : 1
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var themePreviewColor: Color {
        switch theme {
        case .classic:
            return .red
        case .modern:
            return .blue
        case .romanian:
            return .green
        }
    }
    
    private var themePreviewSymbol: String {
        switch theme {
        case .classic:
            return "♠"
        case .modern:
            return "●"
        case .romanian:
            return "♦"
        }
    }
}

/// Gameplay-related settings
struct GameplaySettingsSection: View {
    @StateObject var userSettings = UserSettings.shared
    
    var body: some View {
        SettingsCard(title: "Gameplay", icon: "gamecontroller.fill") {
            VStack(spacing: 16) {
                SettingsRow(
                    title: "Default Player Name",
                    subtitle: "Used for new games"
                ) {
                    TextField("Player", text: $userSettings.playerName)
                        .textFieldStyle(CompactTextFieldStyle())
                        .frame(maxWidth: 120)
                }
                
                Divider()
                    .background(Color.white.opacity(0.2))
                
                SettingsRow(
                    title: "Preferred AI Difficulty",
                    subtitle: "Default for new games"
                ) {
                    Picker("Difficulty", selection: $userSettings.preferredDifficulty) {
                        ForEach(AIDifficulty.allCases, id: \.self) { difficulty in
                            Text(difficulty.displayName).tag(difficulty)
                        }
                    }
                    .pickerStyle(.menu)
                    .accentColor(.blue)
                }
            }
        }
    }
}

/// Data and privacy settings
struct DataPrivacySection: View {
    @Binding var showingReset: Bool
    
    var body: some View {
        SettingsCard(title: "Data & Privacy", icon: "lock.shield.fill") {
            VStack(spacing: 16) {
                // Privacy info
                VStack(alignment: .leading, spacing: 8) {
                    Text("Your Privacy Matters")
                        .font(.subheadline.bold())
                        .foregroundColor(.white)
                    
                    Text("Septica stores all data locally on your device. No information is collected or shared with third parties.")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Divider()
                    .background(Color.white.opacity(0.2))
                
                // Reset data button
                Button(action: { showingReset = true }) {
                    HStack {
                        Image(systemName: "trash.fill")
                            .foregroundColor(.red)
                        
                        VStack(alignment: .leading) {
                            Text("Reset All Data")
                                .font(.subheadline)
                                .foregroundColor(.red)
                            
                            Text("Delete statistics and settings")
                                .font(.caption)
                                .foregroundColor(.red.opacity(0.7))
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .foregroundColor(.red.opacity(0.5))
                            .font(.caption)
                    }
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
}

/// About and app information
struct AboutSection: View {
    @Binding var showingAbout: Bool
    
    var body: some View {
        SettingsCard(title: "About", icon: "info.circle.fill") {
            VStack(spacing: 16) {
                Button(action: { showingAbout = true }) {
                    SettingsRow(
                        title: "About Septica",
                        subtitle: "Version and information"
                    ) {
                        HStack {
                            if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
                                Text("v\(version)")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.7))
                            }
                            
                            Image(systemName: "chevron.right")
                                .foregroundColor(.white.opacity(0.5))
                                .font(.caption)
                        }
                    }
                }
                .buttonStyle(PlainButtonStyle())
                
                // Traditional Romanian saying
                VStack(spacing: 4) {
                    Text("\"Un joc bun cu prieteni este mai bun decât aurul\"")
                        .font(.caption.italic())
                        .foregroundColor(.white.opacity(0.6))
                        .multilineTextAlignment(.center)
                    
                    Text("\"A good game with friends is better than gold\"")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.4))
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 8)
            }
        }
    }
}

// MARK: - Supporting Views

/// Common card styling for settings sections
struct SettingsCard<Content: View>: View {
    let title: String
    let icon: String
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(.blue)
                
                Text(title)
                    .font(.title3.bold())
                    .foregroundColor(.white)
                
                Spacer()
            }
            
            // Content
            content
        }
        .padding(20)
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
    }
}

/// Settings toggle control
struct SettingsToggle: View {
    let title: String
    let subtitle: String
    @Binding var isOn: Bool
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.white)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .toggleStyle(SwitchToggleStyle(tint: .blue))
        }
    }
}

/// Generic settings row
struct SettingsRow<Content: View>: View {
    let title: String
    let subtitle: String
    @ViewBuilder let content: Content
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.white)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
            
            Spacer()
            
            content
        }
    }
}

/// Compact text field style for settings
struct CompactTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.black.opacity(0.3))
                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
            )
            .foregroundColor(.white)
    }
}

/// Background for settings view
struct RomanianSettingsBackground: View {
    var body: some View {
        ZStack {
            // Base gradient
            LinearGradient(
                colors: [
                    Color(red: 0.05, green: 0.1, blue: 0.15),
                    Color(red: 0.1, green: 0.05, blue: 0.1),
                    Color(red: 0.05, green: 0.08, blue: 0.1)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // Subtle pattern
            GeometryReader { geometry in
                ForEach(0..<25) { _ in
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white.opacity(0.01))
                        .frame(width: 40, height: 60)
                        .rotationEffect(.degrees(Double.random(in: -30...30)))
                        .position(
                            x: CGFloat.random(in: 0...geometry.size.width),
                            y: CGFloat.random(in: 0...geometry.size.height)
                        )
                }
            }
        }
        .ignoresSafeArea()
    }
}

/// About information sheet
struct AboutSheet: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // App icon and title
                    VStack(spacing: 16) {
                        Image(systemName: "suit.club.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.blue, .purple],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        
                        Text("Septica")
                            .font(.largeTitle.bold())
                        
                        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
                           let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
                            Text("Version \(version) (\(build))")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.bottom)
                    
                    // About the game
                    VStack(alignment: .leading, spacing: 16) {
                        Text("About Septica")
                            .font(.title2.bold())
                        
                        Text("Septica is a traditional Romanian card game that combines strategy, skill, and a bit of luck. This digital version brings the authentic Romanian gaming experience to your iOS device.")
                            .font(.body)
                        
                        Text("The game features intelligent AI opponents with multiple difficulty levels, ensuring both beginners and experts can enjoy the challenge.")
                            .font(.body)
                    }
                    
                    // Traditional rules info
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Traditional Romanian Game")
                            .font(.title2.bold())
                        
                        Text("Septica has been played in Romania for generations, often in family gatherings and social events. The rules implemented in this app follow the traditional Romanian variant of the game.")
                            .font(.body)
                        
                        Text("Seven cards (\"septica\" in Romanian) are dealt to each player, hence the name of the game.")
                            .font(.body)
                            .italic()
                    }
                    
                    // Privacy and data
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Privacy & Data")
                            .font(.title2.bold())
                        
                        Text("Your privacy is important to us. This app stores all data locally on your device and does not collect, transmit, or share any personal information.")
                            .font(.body)
                        
                        Text("No network connection is required to play, ensuring your gaming remains private and secure.")
                            .font(.body)
                    }
                    
                    // Credits
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Acknowledgments")
                            .font(.title2.bold())
                        
                        Text("Special thanks to the Romanian card game community for preserving these traditional games and sharing their knowledge of authentic gameplay strategies.")
                            .font(.body)
                            .italic()
                    }
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Preview

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            SettingsView()
                .environmentObject(NavigationManager())
        }
        .preferredColorScheme(.dark)
        .environmentObject(AccessibilityManager.preview)
        .environmentObject(HapticManager.preview)
        .environmentObject(AudioManager.preview)
    }
}