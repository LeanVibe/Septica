//
//  RomanianAvatarSystem.swift
//  Septica
//
//  Extended Romanian character system with nano banana style characters
//  Integrates with multiplayer avatar and emote system
//

import SwiftUI

// MARK: - Romanian Character Types

enum RomanianCharacterType: String, CaseIterable, Codable {
    case pacala = "Păcală"
    case iele = "Iele"
    case strigoi = "Strigoi"
    case fatFrumos = "Făt-Frumos"
    case babaCloantza = "Baba Cloanța"
    case zmeu = "Zmeu"

    var description: String {
        switch self {
        case .pacala: return "The Trickster"
        case .iele: return "The Ethereal Nymph"
        case .strigoi: return "The Restless Spirit"
        case .fatFrumos: return "The Heroic Prince"
        case .babaCloantza: return "The Forest Witch"
        case .zmeu: return "The Playful Dragon"
        }
    }

    var personality: String {
        switch self {
        case .pacala: return "Clever, unpredictable, endlessly cheerful"
        case .iele: return "Ethereal, mysterious, moody"
        case .strigoi: return "Mischievous, dramatic, show-off"
        case .fatFrumos: return "Brave, earnest, honorable"
        case .babaCloantza: return "Grumpy, impatient, secretly wise"
        case .zmeu: return "Boisterous, competitive, clumsy"
        }
    }

    var primaryColor: String {
        switch self {
        case .pacala: return "#8B4513" // Earthy brown
        case .iele: return "#E6E6FA" // Lavender
        case .strigoi: return "#483D8B" // Dark slate blue
        case .fatFrumos: return "#4169E1" // Royal blue
        case .babaCloantza: return "#2F4F4F" // Dark slate gray
        case .zmeu: return "#228B22" // Forest green
        }
    }

    var accentColor: String {
        switch self {
        case .pacala: return "#DEB887" // Burlywood
        case .iele: return "#FFB6C1" // Light pink
        case .strigoi: return "#8B008B" // Dark magenta
        case .fatFrumos: return "#FFD700" // Gold
        case .babaCloantza: return "#654321" // Dark brown
        case .zmeu: return "#32CD32" // Lime green
        }
    }
}

// MARK: - Extended Romanian Avatar Model

struct RomanianAvatar {
    let id = UUID()
    let characterType: RomanianCharacterType
    let name: String
    let unlockLevel: Int
    let isPremium: Bool
    let customEmotes: [EmoteType]

    init(
        characterType: RomanianCharacterType,
        name: String? = nil,
        unlockLevel: Int = 1,
        isPremium: Bool = false,
        customEmotes: [EmoteType] = []
    ) {
        self.characterType = characterType
        self.name = name ?? characterType.rawValue
        self.unlockLevel = unlockLevel
        self.isPremium = isPremium
        self.customEmotes = customEmotes.isEmpty ? EmoteType.allCases : customEmotes
    }

    // Predefined characters
    static let pacala = RomanianAvatar(characterType: .pacala, unlockLevel: 1)
    static let iele = RomanianAvatar(characterType: .iele, unlockLevel: 1)
    static let strigoi = RomanianAvatar(characterType: .strigoi, unlockLevel: 2)
    static let fatFrumos = RomanianAvatar(characterType: .fatFrumos, unlockLevel: 3)
    static let babaCloantza = RomanianAvatar(characterType: .babaCloantza, unlockLevel: 4)
    static let zmeu = RomanianAvatar(characterType: .zmeu, unlockLevel: 5)

    static let allCharacters: [RomanianAvatar] = [
        .pacala, .iele, .strigoi, .fatFrumos, .babaCloantza, .zmeu
    ]

    static func availableCharacters(for level: Int) -> [RomanianAvatar] {
        return allCharacters.filter { $0.unlockLevel <= level }
    }
}

// MARK: - Avatar Selection View

struct AvatarSelectionView: View {
    @Binding var selectedAvatar: RomanianAvatar
    let playerLevel: Int
    @Environment(\.dismiss) private var dismiss

    @State private var previewCharacter: RomanianCharacterType = .pacala
    @State private var showingUnlockAlert = false
    @State private var unlockCandidate: RomanianAvatar?

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Character preview
                    characterPreviewSection

                    // Character grid
                    characterGridSection

                    // Character details
                    characterDetailsSection
                }
                .padding()
            }
            .navigationTitle("Alege Personaj")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .disabled(selectedAvatar.characterType != previewCharacter)
                }
            }
        }
        .alert("Necesită Deblocare", isPresented: $showingUnlockAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            if let avatar = unlockCandidate {
                Text("\(avatar.name) se deblochează la nivelul \(avatar.unlockLevel)")
            }
        }
    }

    // MARK: - Character Preview

    private var characterPreviewSection: some View {
        VStack(spacing: 16) {
            Text("Previzualizare")
                .font(.headline.weight(.semibold))
                .foregroundColor(.white)

            ZStack {
                // Preview background
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color(hex: previewCharacter.primaryColor).opacity(0.8),
                                Color(hex: previewCharacter.primaryColor).opacity(0.4)
                            ],
                            center: .center,
                            startRadius: 40,
                            endRadius: 80
                        )
                    )
                    .frame(width: 120, height: 120)
                    .overlay(
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color(hex: previewCharacter.accentColor),
                                        Color(hex: previewCharacter.primaryColor)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 3
                            )
                    )

                // Character avatar
                previewAvatarView
            }
            .frame(height: 140)

            // Character name and level
            VStack(spacing: 4) {
                Text(previewCharacter.rawValue)
                    .font(.title2.weight(.bold))
                    .foregroundColor(.white)

                Text(previewCharacter.description)
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.white.opacity(0.8))

                if previewCharacter != .pacala {
                    Text("Deblochează la nivelul \(unlockLevelForCharacter(previewCharacter))")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(RomanianColors.goldAccent)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.black.opacity(0.3))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }

    private var previewAvatarView: some View {
        Group {
            switch previewCharacter {
            case .pacala:
                PacalaAvatar(emote: .greeting)
            case .iele:
                IeleAvatar(emote: .greeting)
            case .strigoi:
                StrigoiAvatar(emote: .greeting)
            case .fatFrumos:
                FatFrumosAvatar(emote: .greeting)
            case .babaCloantza:
                BabaCloantzaAvatar(emote: .greeting)
            case .zmeu:
                ZmeuAvatar(emote: .greeting)
            }
        }
        .scaleEffect(2.0)
    }

    // MARK: - Character Grid

    private var characterGridSection: some View {
        VStack(spacing: 16) {
            Text("Personaje Disponibile")
                .font(.headline.weight(.semibold))
                .foregroundColor(.white)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 16) {
                ForEach(RomanianCharacterType.allCases, id: \.self) { characterType in
                    characterCard(for: characterType)
                }
            }
        }
    }

    private func characterCard(for characterType: RomanianCharacterType) -> some View {
        let avatar = RomanianAvatar(characterType: characterType)
        let isUnlocked = playerLevel >= avatar.unlockLevel
        let isSelected = previewCharacter == characterType

        return Button(action: {
            if isUnlocked {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    previewCharacter = characterType
                    selectedAvatar = avatar
                }
            } else {
                unlockCandidate = avatar
                showingUnlockAlert = true
            }
        }) {
            VStack(spacing: 8) {
                // Mini avatar
                ZStack {
                    Circle()
                        .fill(
                            isUnlocked ?
                                Color(hex: characterType.primaryColor).opacity(0.8) :
                                Color.gray.opacity(0.3)
                        )
                        .frame(width: 50, height: 50)
                        .overlay(
                            Circle()
                                .stroke(
                                    isSelected ?
                                        RomanianColors.goldAccent :
                                        Color.white.opacity(0.3),
                                    lineWidth: isSelected ? 3 : 1
                                )
                        )

                    if isUnlocked {
                        miniCharacterView(for: characterType)
                    } else {
                        Image(systemName: "lock.fill")
                            .font(.title3)
                            .foregroundColor(.white.opacity(0.6))
                    }
                }

                // Character name
                Text(characterType.rawValue)
                    .font(.caption.weight(.medium))
                    .foregroundColor(isUnlocked ? .white : .gray)
                    .lineLimit(1)

                // Level requirement
                Text("Lv.\(avatar.unlockLevel)")
                    .font(.caption2)
                    .foregroundColor(
                        isUnlocked ?
                            RomanianColors.goldAccent :
                            Color.gray.opacity(0.6)
                    )
            }
            .frame(width: 80, height: 90)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        isUnlocked ?
                            Color.white.opacity(0.1) :
                            Color.gray.opacity(0.2)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                isSelected ?
                                    RomanianColors.goldAccent :
                                    Color.white.opacity(0.2),
                                lineWidth: isSelected ? 2 : 1
                            )
                    )
            )
        }
        .buttonStyle(.plain)
        .disabled(!isUnlocked && !isSelected)
    }

    private func miniCharacterView(for characterType: RomanianCharacterType) -> some View {
        Group {
            switch characterType {
            case .pacala:
                PacalaAvatar(emote: nil)
            case .iele:
                IeleAvatar(emote: nil)
            case .strigoi:
                StrigoiAvatar(emote: nil)
            case .fatFrumos:
                FatFrumosAvatar(emote: nil)
            case .babaCloantza:
                BabaCloantzaAvatar(emote: nil)
            case .zmeu:
                ZmeuAvatar(emote: nil)
            }
        }
        .scaleEffect(0.6)
    }

    // MARK: - Character Details

    private var characterDetailsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Detalii Personaj")
                .font(.headline.weight(.semibold))
                .foregroundColor(.white)

            VStack(alignment: .leading, spacing: 8) {
                detailRow(title: "Nume", value: previewCharacter.rawValue)
                detailRow(title: "Descriere", value: previewCharacter.description)
                detailRow(title: "Personalitate", value: previewCharacter.personality)
                detailRow(title: "Nivel Deblocare", value: "\(unlockLevelForCharacter(previewCharacter))")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.black.opacity(0.3))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }

    private func detailRow(title: String, value: String) -> some View {
        HStack {
            Text(title + ":")
                .font(.subheadline.weight(.medium))
                .foregroundColor(.white.opacity(0.8))
                .frame(width: 100, alignment: .leading)

            Text(value)
                .font(.subheadline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)

            Spacer()
        }
    }

    // MARK: - Helper Methods

    private func unlockLevelForCharacter(_ characterType: RomanianCharacterType) -> Int {
        return RomanianAvatar(characterType: characterType).unlockLevel
    }
}

// MARK: - RomanianAvatar Extension

extension RomanianAvatar {
    /// Display name for the avatar (localized)
    var displayName: String {
        return name
    }

    /// Emoji representation of the character
    var emoji: String {
        switch characterType {
        case .pacala: return "🎭"
        case .iele: return "✨"
        case .strigoi: return "👻"
        case .fatFrumos: return "⚔️"
        case .babaCloantza: return "🧙‍♀️"
        case .zmeu: return "🐉"
        }
    }

    /// Cultural theme description
    var culturalTheme: String {
        switch characterType {
        case .pacala: return "Romanian Folklore Trickster"
        case .iele: return "Ethereal Nymphs of Romanian Mythology"
        case .strigoi: return "Romanian Undead Spirits"
        case .fatFrumos: return "Heroic Prince of Romanian Fairy Tales"
        case .babaCloantza: return "Wise Forest Witch"
        case .zmeu: return "Romanian Dragon of Legend"
        }
    }
}

// MARK: - Player Extension for Avatar Display

extension Player {
    /// Display name for the current avatar
    var avatarDisplayName: String {
        return romanianAvatar.displayName
    }

    /// Get avatar emoji representation
    var avatarEmoji: String {
        return romanianAvatar.emoji
    }

    /// Get avatar cultural theme
    var avatarCulturalTheme: String {
        return romanianAvatar.culturalTheme
    }
}

// MARK: - Preview

struct RomanianAvatarSystem_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            AvatarSelectionView(
                selectedAvatar: .constant(.pacala),
                playerLevel: 3
            )
        }
        .preferredColorScheme(.dark)
        .background(RomanianColors.cardBack)
    }
}