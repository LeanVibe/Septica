//
//  RomanianCharacterSelectionView.swift
//  Septica
//
//  Romanian character selection inspired by Shuffle Cats character picker
//  Allows players to choose avatars and frames representing Romanian cultural heritage
//

import SwiftUI

/// Character selection view inspired by Shuffle Cats design patterns
/// Features circular avatar previews, Romanian cultural frames, and progression unlocks
struct RomanianCharacterSelectionView: View {
    @Binding var selectedAvatar: RomanianCharacterAvatar
    @Binding var selectedFrame: AvatarFrame
    @Binding var playerLevel: Int
    @Binding var currentArena: RomanianArena
    
    let onSelectionComplete: () -> Void
    
    @State private var showingFrameSelector = false
    @State private var showingArenaSelector = false
    @State private var animatingAvatar: RomanianCharacterAvatar?
    
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 16), count: 3)
    
    var body: some View {
        VStack(spacing: 24) {
            // Header with Romanian cultural styling
            VStack(spacing: 8) {
                Text("Alegeți Personajul")
                    .font(.largeTitle.bold())
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Color(hex: "#FFD700"), // Romanian gold
                                Color(hex: "#C9A961")  // Darker gold
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: .black.opacity(0.3), radius: 2, x: 1, y: 1)
                
                Text("Selectați un personaj din tradițiile românești")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
            }
            .padding(.top)
            
            // Selected avatar preview (large, Shuffle Cats style)
            VStack(spacing: 16) {
                RomanianPlayerAvatarView(
                    avatar: selectedAvatar,
                    frame: selectedFrame,
                    level: playerLevel,
                    arena: currentArena,
                    isCurrentPlayer: true
                )
                .scaleEffect(1.8) // Large preview like Shuffle Cats
                .shadow(color: .black.opacity(0.4), radius: 8, x: 0, y: 4)
                
                // Character name and description
                VStack(spacing: 4) {
                    Text(selectedAvatar.displayName)
                        .font(.title2.bold())
                        .foregroundColor(.white)
                    
                    Text(selectedAvatar.description)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                }
            }
            .frame(height: 200)
            
            // Character grid selector (Shuffle Cats inspired layout)
            ScrollView {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(RomanianCharacterAvatar.allCases, id: \.self) { avatar in
                        CharacterSelectionButton(
                            avatar: avatar,
                            frame: selectedFrame,
                            level: playerLevel,
                            arena: currentArena,
                            isSelected: selectedAvatar == avatar,
                            isAnimating: animatingAvatar == avatar,
                            onTap: {
                                selectAvatar(avatar)
                            }
                        )
                    }
                }
                .padding(.horizontal)
            }
            
            // Customization options (Shuffle Cats style tabs)
            HStack(spacing: 20) {
                // Frame selector button
                VStack(spacing: 4) {
                    Button(action: { showingFrameSelector = true }) {
                        HStack(spacing: 8) {
                            Image(systemName: "square.on.circle")
                                .font(.title3)
                            Text("Ramă")
                                .font(.caption.bold())
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(Color(hex: selectedFrame.frameColor))
                                .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 2)
                        )
                    }
                    
                    Text(selectedFrame.displayName)
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.6))
                }
                
                // Arena selector button
                VStack(spacing: 4) {
                    Button(action: { showingArenaSelector = true }) {
                        HStack(spacing: 8) {
                            Image(systemName: "building.2")
                                .font(.title3)
                            Text("Arenă")
                                .font(.caption.bold())
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(Color(hex: currentArena.primaryColor))
                                .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 2)
                        )
                    }
                    
                    Text(currentArena.displayName)
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.6))
                }
            }
            .padding(.bottom)
            
            // Confirm selection button (Shuffle Cats style)
            Button(action: onSelectionComplete) {
                HStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                    Text("Confirmați Selecția")
                        .font(.headline.bold())
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    LinearGradient(
                        colors: [
                            Color(hex: "#2E7D32"), // Romanian green
                            Color(hex: "#1B5E20")  // Darker green
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .cornerRadius(16)
                .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
        .background(
            // Romanian-inspired background
            LinearGradient(
                colors: [
                    Color(hex: "#1A1A2E"),
                    Color(hex: "#16213E"),
                    Color(hex: "#0F1419")
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .sheet(isPresented: $showingFrameSelector) {
            RomanianFrameSelectorView(
                selectedFrame: $selectedFrame,
                playerLevel: playerLevel,
                onDismiss: { showingFrameSelector = false }
            )
        }
        .sheet(isPresented: $showingArenaSelector) {
            RomanianArenaSelectorView(
                selectedArena: $currentArena,
                playerLevel: playerLevel,
                onDismiss: { showingArenaSelector = false }
            )
        }
    }
    
    /// Select avatar with Shuffle Cats-style animation
    private func selectAvatar(_ avatar: RomanianCharacterAvatar) {
        // Animate selection
        animatingAvatar = avatar
        
        // Haptic feedback like Shuffle Cats
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        withAnimation(.easeInOut(duration: 0.3)) {
            selectedAvatar = avatar
        }
        
        // Clear animation after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            animatingAvatar = nil
        }
    }
}

/// Individual character selection button (Shuffle Cats inspired)
struct CharacterSelectionButton: View {
    let avatar: RomanianCharacterAvatar
    let frame: AvatarFrame
    let level: Int
    let arena: RomanianArena
    let isSelected: Bool
    let isAnimating: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            ZStack {
                // Selection glow effect (Shuffle Cats style)
                if isSelected {
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [Color.yellow, Color.orange],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 3
                        )
                        .frame(width: 94, height: 94)
                        .scaleEffect(isAnimating ? 1.1 : 1.0)
                        .animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true), value: isSelected)
                }
                
                // Avatar preview
                RomanianPlayerAvatarView(
                    avatar: avatar,
                    frame: frame,
                    level: level,
                    arena: arena,
                    isCurrentPlayer: isSelected
                )
                .scaleEffect(isSelected ? 1.1 : 1.0)
                .shadow(color: .black.opacity(isSelected ? 0.4 : 0.2), radius: isSelected ? 6 : 3, x: 0, y: 2)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}

/// Frame selector sheet view
struct RomanianFrameSelectorView: View {
    @Binding var selectedFrame: AvatarFrame
    let playerLevel: Int
    let onDismiss: () -> Void
    
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 16), count: 4)
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Alegeți Rama Avatarului")
                    .font(.title2.bold())
                    .foregroundColor(.primary)
                    .padding(.top)
                
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(AvatarFrame.allCases, id: \.self) { frame in
                            FrameSelectionButton(
                                frame: frame,
                                isSelected: selectedFrame == frame,
                                isUnlocked: frame.requiredLevel <= playerLevel,
                                onTap: {
                                    if frame.requiredLevel <= playerLevel {
                                        selectedFrame = frame
                                        onDismiss()
                                    }
                                }
                            )
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Închide", action: onDismiss)
                }
            }
        }
    }
}

/// Arena selector sheet view
struct RomanianArenaSelectorView: View {
    @Binding var selectedArena: RomanianArena
    let playerLevel: Int
    let onDismiss: () -> Void
    
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 16), count: 2)
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Alegeți Arena de Joc")
                    .font(.title2.bold())
                    .foregroundColor(.primary)
                    .padding(.top)
                
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(RomanianArena.allCases, id: \.self) { arena in
                            ArenaSelectionButton(
                                arena: arena,
                                isSelected: selectedArena == arena,
                                isUnlocked: arena.requiredLevel <= playerLevel,
                                onTap: {
                                    if arena.requiredLevel <= playerLevel {
                                        selectedArena = arena
                                        onDismiss()
                                    }
                                }
                            )
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Închide", action: onDismiss)
                }
            }
        }
    }
}

/// Frame selection button
struct FrameSelectionButton: View {
    let frame: AvatarFrame
    let isSelected: Bool
    let isUnlocked: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .stroke(Color(hex: frame.frameColor), lineWidth: 4)
                        .frame(width: 60, height: 60)
                        .opacity(isUnlocked ? 1.0 : 0.4)
                    
                    if isSelected {
                        Circle()
                            .fill(Color(hex: frame.frameColor).opacity(0.3))
                            .frame(width: 56, height: 56)
                    }
                    
                    if !isUnlocked {
                        Image(systemName: "lock.fill")
                            .font(.title3)
                            .foregroundColor(.gray)
                    }
                }
                
                Text(frame.displayName)
                    .font(.caption.bold())
                    .foregroundColor(isUnlocked ? .primary : .gray)
                    .multilineTextAlignment(.center)
                
                if !isUnlocked {
                    Text("Nivel \(frame.requiredLevel)")
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
            }
        }
        .disabled(!isUnlocked)
        .buttonStyle(PlainButtonStyle())
    }
}

/// Arena selection button
struct ArenaSelectionButton: View {
    let arena: RomanianArena
    let isSelected: Bool
    let isUnlocked: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(hex: arena.primaryColor))
                        .frame(height: 80)
                        .opacity(isUnlocked ? 1.0 : 0.4)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color(hex: arena.accentColor), lineWidth: isSelected ? 3 : 1)
                        )
                    
                    if !isUnlocked {
                        Image(systemName: "lock.fill")
                            .font(.title2)
                            .foregroundColor(.white.opacity(0.7))
                    } else {
                        Image(systemName: "building.2.fill")
                            .font(.title2)
                            .foregroundColor(.white)
                    }
                }
                
                Text(arena.displayName)
                    .font(.caption.bold())
                    .foregroundColor(isUnlocked ? .primary : .gray)
                    .multilineTextAlignment(.center)
                
                if !isUnlocked {
                    Text("Nivel \(arena.requiredLevel)")
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
            }
        }
        .disabled(!isUnlocked)
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Character Avatar Extensions

extension RomanianCharacterAvatar {
    /// Human-readable display name for each character
    var displayName: String {
        switch self {
        case .traditionalPlayer:
            return "Jucător Tradițional"
        case .folkMusician:
            return "Muzician Popular"
        case .villageElder:
            return "Bătrânul Satului"
        case .transylvanianNoble:
            return "Nobil Ardelean"
        case .moldovanScholar:
            return "Cărturar Moldovean"
        case .wallachianWarrior:
            return "Războinic Valah"
        case .carpathianShepherd:
            return "Cioban Carpatin"
        case .danubianFisherman:
            return "Pescar Danubian"
        case .bucovinianArtisan:
            return "Meșter Bucovina"
        case .dobrudjanMerchant:
            return "Negustor Dobrogean"
        }
    }
    
    /// Cultural description for each character
    var description: String {
        switch self {
        case .traditionalPlayer:
            return "Un jucător clasic care respectă tradițiile"
        case .folkMusician:
            return "Artist popular cu înțelepciune veche"
        case .villageElder:
            return "Bătrân cu experiență vastă la cărți"
        case .transylvanianNoble:
            return "Aristocrat ardelean cu stil rafinat"
        case .moldovanScholar:
            return "Învățat moldovean cu tactici subtile"
        case .wallachianWarrior:
            return "Războinic valah cu spirit de luptă"
        case .carpathianShepherd:
            return "Cioban înțelept de pe culmile Carpaților"
        case .danubianFisherman:
            return "Pescar iscusit de pe malurile Dunării"
        case .bucovinianArtisan:
            return "Meșter priceput din Bucovina"
        case .dobrudjanMerchant:
            return "Negustor știutor din Dobrogea"
        }
    }
}

extension AvatarFrame {
    /// Human-readable display name for frames
    var displayName: String {
        switch self {
        case .woodenFrame:
            return "Lemn"
        case .bronzeFrame:
            return "Bronz"
        case .silverFrame:
            return "Argint"
        case .goldenFrame:
            return "Aur"
        case .culturalFrame:
            return "Cultural"
        case .royalFrame:
            return "Regal"
        case .legendaryFrame:
            return "Legendar"
        }
    }
}

extension RomanianArena {
    /// Human-readable display name for arenas
    var displayName: String {
        switch self {
        case .sateImarica:
            return "Satul Imarica"
        case .satuMihai:
            return "Satul Mihai"
        case .orasulBrara:
            return "Orașul Brara"
        case .orasulBacau:
            return "Orașul Bacău"
        case .orasulCluj:
            return "Orașul Cluj"
        case .orasulConstanta:
            return "Orașul Constanța"
        case .orasulIasi:
            return "Orașul Iași"
        case .orasulTimisoara:
            return "Orașul Timișoara"
        case .orasulBrasov:
            return "Orașul Brașov"
        case .orasulSibiu:
            return "Orașul Sibiu"
        case .marealeBucuresti:
            return "Marele Oraș București"
        }
    }
}

// MARK: - Preview Support

#if DEBUG
struct RomanianCharacterSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        RomanianCharacterSelectionView(
            selectedAvatar: .constant(.traditionalPlayer),
            selectedFrame: .constant(.woodenFrame),
            playerLevel: .constant(5),
            currentArena: .constant(.sateImarica),
            onSelectionComplete: {}
        )
        .previewDevice("iPhone 14 Pro")
        .preferredColorScheme(.dark)
    }
}
#endif