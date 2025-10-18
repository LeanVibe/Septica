//
//  AvatarWithEmotesView.swift
//  Septica
//
//  Multiplayer avatar system with emote support
//  Integrates nano banana style Romanian folklore characters
//

import SwiftUI

struct AvatarWithEmotesView: View {
    let player: Player
    let playerType: PlayerType
    let isCurrentPlayer: Bool

    @State private var currentEmote: EmoteType?
    @State private var emoteAnimationProgress: Double = 0
    @State private var showEmoteMenu = false

    var body: some View {
        ZStack {
            // Avatar display
            avatarContainer

            // Emote overlay
            if let emote = currentEmote {
                emoteOverlay(for: emote)
            }

            // Emote menu (only for human players)
            if playerType == .human && showEmoteMenu {
                emoteMenu
            }
        }
        .onTapGesture {
            if playerType == .human {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    showEmoteMenu.toggle()
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .playerDidEmote)) { notification in
            if let emoteData = notification.object as? EmoteData,
               emoteData.playerId == player.id {
                triggerEmote(emoteData.emote)
            }
        }
    }

    // MARK: - Avatar Container

    private var avatarContainer: some View {
        ZStack {
            // Avatar background
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            avatarBackgroundColor.opacity(0.8),
                            avatarBackgroundColor.opacity(0.4)
                        ],
                        center: .center,
                        startRadius: 20,
                        endRadius: 45
                    )
                )
                .frame(width: 64, height: 64)
                .overlay(
                    Circle()
                        .stroke(
                            isCurrentPlayer ?
                                LinearGradient(
                                    colors: [
                                        RomanianColors.goldAccent,
                                        RomanianColors.primaryYellow
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ) :
                                LinearGradient(
                                    colors: [Color.white.opacity(0.2)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                ),
                            lineWidth: isCurrentPlayer ? 3 : 1
                        )
                )
                .shadow(color: .black.opacity(0.3), radius: 6, x: 0, y: 3)

            // Character avatar
            characterAvatar
                .scaleEffect(currentEmote != nil ? 1.1 : 1.0)
                .animation(.spring(response: 0.4, dampingFraction: 0.6), value: currentEmote)

            // Player level indicator
            if player.playerLevel > 1 {
                levelIndicator
            }
        }
    }

    private var characterAvatar: some View {
        Group {
            switch player.romanianAvatar.characterType {
            case .pacala:
                PacalaAvatar(emote: currentEmote)
            case .iele:
                IeleAvatar(emote: currentEmote)
            case .strigoi:
                StrigoiAvatar(emote: currentEmote)
            case .fatFrumos:
                FatFrumosAvatar(emote: currentEmote)
            case .babaCloantza:
                BabaCloantzaAvatar(emote: currentEmote)
            case .zmeu:
                ZmeuAvatar(emote: currentEmote)
            }
        }
    }

    private var avatarBackgroundColor: Color {
        switch player.romanianAvatar.characterType {
        case .pacala: return Color(hex: "#8B4513") // Earthy brown
        case .iele: return Color(hex: "#E6E6FA") // Lavender
        case .strigoi: return Color(hex: "#483D8B") // Dark slate blue
        case .fatFrumos: return Color(hex: "#4169E1") // Royal blue
        case .babaCloantza: return Color(hex: "#2F4F4F") // Dark slate gray
        case .zmeu: return Color(hex: "#228B22") // Forest green
        }
    }

    private var levelIndicator: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                Text("\(player.playerLevel)")
                    .font(.caption2.weight(.bold))
                    .foregroundColor(.white)
                    .frame(width: 16, height: 16)
                    .background(
                        Circle()
                            .fill(RomanianColors.goldAccent)
                    )
                    .shadow(color: .black.opacity(0.3), radius: 2)
            }
        }
        .frame(width: 64, height: 64)
    }

    // MARK: - Emote Overlay

    private func emoteOverlay(for emote: EmoteType) -> some View {
        VStack {
            Spacer()
            emoteContent(for: emote)
                .scaleEffect(emoteAnimationProgress)
                .opacity(emoteAnimationProgress)
            Spacer()
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.5)) {
                emoteAnimationProgress = 1.0
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                withAnimation(.easeOut(duration: 0.3)) {
                    emoteAnimationProgress = 0.0
                }

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    currentEmote = nil
                }
            }
        }
    }

    private func emoteContent(for emote: EmoteType) -> some View {
        Group {
            switch emote {
            case .greeting:
                Text("👋")
                    .font(.title2)
            case .goodMove:
                Text("🎯")
                    .font(.title2)
            case .badMove:
                Text("🤔")
                    .font(.title2)
            case .thinking:
                Text("💭")
                    .font(.title2)
            case .taunt:
                Text("😏")
                    .font(.title2)
            case .victory:
                Text("🏆")
                    .font(.title2)
            case .defeat:
                Text("😅")
                    .font(.title2)
            }
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.7))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                )
        )
    }

    // MARK: - Emote Menu

    private var emoteMenu: some View {
        VStack(spacing: 8) {
            // Menu header
            Text("Alege Emoție")
                .font(.caption.weight(.semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(RomanianColors.primaryBlue.opacity(0.9))
                )

            // Emote buttons
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 8) {
                ForEach(EmoteType.allCases, id: \.self) { emote in
                    emoteButton(for: emote)
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.black.opacity(0.8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
            )
        }
        .offset(y: -80)
        .shadow(color: .black.opacity(0.4), radius: 12, x: 0, y: 6)
    }

    private func emoteButton(for emote: EmoteType) -> some View {
        Button(action: {
            sendEmote(emote)
        }) {
            VStack(spacing: 2) {
                emoteIcon(for: emote)
                    .font(.title3)
                Text(emote.shortName)
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.8))
            }
            .frame(width: 50, height: 50)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.white.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
        .hoverEffect(.lift)
    }

    private func emoteIcon(for emote: EmoteType) -> Text {
        switch emote {
        case .greeting: return Text("👋")
        case .goodMove: return Text("🎯")
        case .badMove: return Text("🤔")
        case .thinking: return Text("💭")
        case .taunt: return Text("😏")
        case .victory: return Text("🏆")
        case .defeat: return Text("😅")
        }
    }

    // MARK: - Emote Actions

    private func triggerEmote(_ emote: EmoteType) {
        currentEmote = emote
        emoteAnimationProgress = 0
    }

    private func sendEmote(_ emote: EmoteType) {
        triggerEmote(emote)
        showEmoteMenu = false

        // Notify other players
        let emoteData = EmoteData(playerId: player.id, emote: emote)
        NotificationCenter.default.post(name: .playerDidEmote, object: emoteData)

        // Play sound effect
        SoundManager.shared.playEmoteSound(for: emote)
    }
}

// MARK: - Character Avatar Views

struct PacalaAvatar: View {
    let emote: EmoteType?

    var body: some View {
        VStack(spacing: 2) {
            // Floppy hat
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(hex: "#8B4513"))
                .frame(width: 40, height: 12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(hex: "#654321"), lineWidth: 1)
                )
                .offset(y: emote == .greeting ? -3 : 0)

            // Face with knowing grin
            VStack(spacing: 1) {
                // Eyes (mostly hidden by hat)
                HStack(spacing: 12) {
                    Circle()
                        .fill(Color.black)
                        .frame(width: 3, height: 3)
                    Circle()
                        .fill(Color.black)
                        .frame(width: 3, height: 3)
                }

                // Grin
                Path { path in
                    path.move(to: CGPoint(x: -8, y: 8))
                    path.addQuadCurve(to: CGPoint(x: 8, y: 8), control: CGPoint(x: 0, y: 12))
                    path.addQuadCurve(to: CGPoint(x: -8, y: 8), control: CGPoint(x: 0, y: 10))
                }
                .fill(Color.black)
                .scaleEffect(emote == .taunt ? 1.2 : 1.0)
            }

            // Body
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(hex: "#DEB887"))
                .frame(width: 24, height: 16)
        }
        .scaleEffect(emote == .goodMove ? 1.1 : 1.0)
        .animation(.spring(response: 0.4, dampingFraction: 0.6), value: emote)
    }
}

struct IeleAvatar: View {
    let emote: EmoteType?

    var body: some View {
        VStack(spacing: 2) {
            // Flowing hair with flowers
            HStack(spacing: 2) {
                ForEach(0..<3) { index in
                    Circle()
                        .fill(emote == .badMove ? Color.red : Color(hex: "#FFB6C1"))
                        .frame(width: 4, height: 4)
                        .scaleEffect(emote == .goodMove ? 1.3 : 1.0)
                }
            }
            .opacity(0.8)

            // Ethereal face
            VStack(spacing: 2) {
                // Luminous eyes
                HStack(spacing: 8) {
                    Circle()
                        .fill(emote == .badMove ? Color.red : Color(hex: "#87CEEB"))
                        .frame(width: 6, height: 6)
                        .glow(color: Color(hex: "#87CEEB"), radius: 2)
                    Circle()
                        .fill(emote == .badMove ? Color.red : Color(hex: "#87CEEB"))
                        .frame(width: 6, height: 6)
                        .glow(color: Color(hex: "#87CEEB"), radius: 2)
                }

                // No mouth - ethereal
            }

            // Flowing body
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(hex: "#F0F8FF").opacity(0.7))
                .frame(width: 20, height: 18)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(hex: "#E6E6FA").opacity(0.5), lineWidth: 1)
                )
        }
        .opacity(emote == .thinking ? 0.6 : 1.0)
        .animation(.easeInOut(duration: 0.6), value: emote)
    }
}

struct StrigoiAvatar: View {
    let emote: EmoteType?

    var body: some View {
        VStack(spacing: 0) {
            // Dark hood
            Path { path in
                path.move(to: CGPoint(x: -16, y: 0))
                path.addLine(to: CGPoint(x: -12, y: -12))
                path.addLine(to: CGPoint(x: 12, y: -12))
                path.addLine(to: CGPoint(x: 16, y: 0))
                path.closeSubpath()
            }
            .fill(Color(hex: "#2F2F2F"))
            .overlay(
                Path { path in
                    path.move(to: CGPoint(x: -16, y: 0))
                    path.addLine(to: CGPoint(x: -12, y: -12))
                    path.addLine(to: CGPoint(x: 12, y: -12))
                    path.addLine(to: CGPoint(x: 16, y: 0))
                    path.closeSubpath()
                }
                .stroke(Color(hex: "#1A1A1A"), lineWidth: 1)
            )

            // Glowing red eyes
            HStack(spacing: 6) {
                Circle()
                    .fill(Color.red)
                    .frame(width: 4, height: 4)
                    .glow(color: Color.red, radius: emote == .taunt ? 6 : 3)
                Circle()
                    .fill(Color.red)
                    .frame(width: 4, height: 4)
                    .glow(color: Color.red, radius: emote == .taunt ? 6 : 3)
            }
            .offset(y: -4)

            // Shadowy body
            RoundedRectangle(cornerRadius: 8)
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "#483D8B"), Color.clear],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 18, height: 20)
                .blur(radius: 2)

            // Smoke wisps at bottom
            HStack(spacing: 2) {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 6, height: 6)
                    .blur(radius: 2)
                Circle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 8, height: 8)
                    .blur(radius: 3)
            }
            .offset(y: 4)
        }
        .scaleEffect(emote == .greeting ? 1.2 : 1.0)
        .animation(.spring(response: 0.5, dampingFraction: 0.4), value: emote)
    }
}

struct FatFrumosAvatar: View {
    let emote: EmoteType?

    var body: some View {
        VStack(spacing: 2) {
            // Golden block hair
            Rectangle()
                .fill(RomanianColors.goldAccent)
                .frame(width: 20, height: 8)
                .overlay(
                    Rectangle()
                        .stroke(Color(hex: "#B8860B"), lineWidth: 1)
                )

            // Determined face
            VStack(spacing: 2) {
                // Bright blue eyes
                HStack(spacing: 8) {
                    Circle()
                        .fill(Color(hex: "#4169E1"))
                        .frame(width: 5, height: 5)
                    Circle()
                        .fill(Color(hex: "#4169E1"))
                        .frame(width: 5, height: 5)
                }

                // Determined mouth
                Rectangle()
                    .fill(Color.black)
                    .frame(width: 8, height: 2)
                    .cornerRadius(1)
            }

            // Proud body with chest plate
            RoundedRectangle(cornerRadius: 4)
                .fill(Color(hex: "#C0C0C0"))
                .frame(width: 22, height: 16)
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(Color(hex: "#808080"), lineWidth: 1)
                )
                .overlay(
                    // Tiny sword
                    Rectangle()
                        .fill(Color(hex: "#8B4513"))
                        .frame(width: 2, height: 8)
                        .offset(x: 10)
                )
        }
        .scaleEffect(emote == .victory ? 1.15 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: emote)
    }
}

struct BabaCloantzaAvatar: View {
    let emote: EmoteType?

    var body: some View {
        VStack(spacing: 1) {
            // Headscarf
            Path { path in
                path.move(to: CGPoint(x: -14, y: 0))
                path.addQuadCurve(to: CGPoint(x: 0, y: -8), control: CGPoint(x: -7, y: -12))
                path.addQuadCurve(to: CGPoint(x: 14, y: 0), control: CGPoint(x: 7, y: -12))
                path.addLine(to: CGPoint(x: 14, y: 8))
                path.addLine(to: CGPoint(x: -14, y: 8))
                path.closeSubpath()
            }
            .fill(Color(hex: "#2F2F2F"))
            .overlay(
                Path { path in
                    path.move(to: CGPoint(x: -14, y: 0))
                    path.addQuadCurve(to: CGPoint(x: 0, y: -8), control: CGPoint(x: -7, y: -12))
                    path.addQuadCurve(to: CGPoint(x: 14, y: 0), control: CGPoint(x: 7, y: -12))
                    path.addLine(to: CGPoint(x: 14, y: 8))
                    path.addLine(to: CGPoint(x: -14, y: 8))
                    path.closeSubpath()
                }
                .stroke(Color(hex: "#1A1A1A"), lineWidth: 1)
            )

            // Grumpy face
            VStack(spacing: 1) {
                // Beady eyes
                HStack(spacing: 6) {
                    Circle()
                        .fill(Color.black)
                        .frame(width: 3, height: 3)
                    Circle()
                        .fill(Color.black)
                        .frame(width: 3, height: 3)
                }

                // Single expressive eyebrow
                Rectangle()
                    .fill(Color(hex: "#654321"))
                    .frame(width: 12, height: 2)
                    .cornerRadius(1)

                // Grumpy mouth
                Path { path in
                    path.move(to: CGPoint(x: -6, y: 6))
                    path.addQuadCurve(to: CGPoint(x: 6, y: 6), control: CGPoint(x: 0, y: 8))
                }
                .stroke(Color.black, lineWidth: 1.5)
            }

            // Round body
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(hex: "#8B7355"))
                .frame(width: 24, height: 18)

            // Gnawed staff
            Rectangle()
                .fill(Color(hex: "#654321"))
                .frame(width: 3, height: 12)
                .offset(x: 10, y: 2)
        }
        .scaleEffect(emote == .goodMove ? 1.05 : 1.0)
        .rotationEffect(.degrees(emote == .badMove ? -5 : 0))
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: emote)
    }
}

struct ZmeuAvatar: View {
    let emote: EmoteType?

    var body: some View {
        VStack(spacing: 0) {
            // Friendly dragon head
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(hex: "#228B22"))
                .frame(width: 24, height: 20)
                .overlay(
                    // Underbite with fangs
                    VStack(spacing: 0) {
                        Rectangle()
                            .fill(Color(hex: "#228B22"))
                            .frame(width: 20, height: 8)

                        HStack(spacing: 4) {
                            Rectangle()
                                .fill(Color.white)
                                .frame(width: 2, height: 4)
                            Rectangle()
                                .fill(Color.white)
                                .frame(width: 2, height: 4)
                        }
                        .offset(y: 2)
                    }
                )

            // Curious eyes
            HStack(spacing: 6) {
                Circle()
                    .fill(Color.black)
                    .frame(width: 5, height: 5)
                    .scaleEffect(emote == .thinking ? 0.7 : 1.0)
                Circle()
                    .fill(Color.black)
                    .frame(width: 5, height: 5)
                    .scaleEffect(emote == .thinking ? 0.7 : 1.0)
            }
            .offset(y: -6)

            // Stubby wings
            HStack(spacing: 20) {
                Path { path in
                    path.move(to: CGPoint(x: 0, y: 0))
                    path.addQuadCurve(to: CGPoint(x: -8, y: -6), control: CGPoint(x: -4, y: -8))
                    path.addQuadCurve(to: CGPoint(x: -4, y: 0), control: CGPoint(x: -6, y: -3))
                    path.closeSubpath()
                }
                .fill(Color(hex: "#32CD32"))

                Path { path in
                    path.move(to: CGPoint(x: 0, y: 0))
                    path.addQuadCurve(to: CGPoint(x: 8, y: -6), control: CGPoint(x: 4, y: -8))
                    path.addQuadCurve(to: CGPoint(x: 4, y: 0), control: CGPoint(x: 6, y: -3))
                    path.closeSubpath()
                }
                .fill(Color(hex: "#32CD32"))
            }
            .offset(y: -8)

            // Chunky body
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(hex: "#228B22"))
                .frame(width: 28, height: 16)

            // Smoke puff (when emote is taunt)
            if emote == .taunt {
                Circle()
                    .fill(Color.gray.opacity(0.6))
                    .frame(width: 8, height: 8)
                    .blur(radius: 2)
                    .offset(y: -8)
                    .scaleEffect(1.2)
                    .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: emote)
            }
        }
        .scaleEffect(emote == .victory ? 1.2 : 1.0)
        .rotationEffect(.degrees(emote == .defeat ? -10 : 0))
        .animation(.spring(response: 0.5, dampingFraction: 0.5), value: emote)
    }
}

// MARK: - Supporting Types

enum EmoteType: String, CaseIterable, Codable {
    case greeting = "Salut"
    case goodMove = "Mutare bună"
    case badMove = "Greșit"
    case thinking = "Gândire"
    case taunt = "Provocare"
    case victory = "Victorie"
    case defeat = "Înfrângere"

    var shortName: String {
        switch self {
        case .greeting: return "Salut"
        case .goodMove: return "Bun"
        case .badMove: return "Greș"
        case .thinking: return "Gând"
        case .taunt: return "Prov"
        case .victory: return "Vict"
        case .defeat: return "Înfr"
        }
    }
}

struct EmoteData {
    let playerId: UUID
    let emote: EmoteType
}

extension Notification.Name {
    static let playerDidEmote = Notification.Name("playerDidEmote")
}

// MARK: - Sound Manager

class SoundManager {
    static let shared = SoundManager()

    func playEmoteSound(for emote: EmoteType) {
        // Implement sound effects for emotes
        print("🔊 Playing sound for emote: \(emote.rawValue)")
    }
}

// MARK: - View Extensions

extension View {
    func glow(color: Color, radius: CGFloat) -> some View {
        self.shadow(color: color, radius: radius)
    }
}

// MARK: - Preview

struct AvatarWithEmotesView_Previews: PreviewProvider {
    static var previews: some View {
        let player = Player(name: "Păcală")
        player.romanianAvatar = RomanianAvatar(characterType: .pacala)
        player.playerLevel = 3

        return VStack(spacing: 30) {
            AvatarWithEmotesView(
                player: player,
                playerType: .human,
                isCurrentPlayer: true
            )

            let aiPlayer = Player(name: "Iele")
            aiPlayer.romanianAvatar = RomanianAvatar(characterType: .iele)
            aiPlayer.playerLevel = 1

            AvatarWithEmotesView(
                player: aiPlayer,
                playerType: .ai,
                isCurrentPlayer: false
            )
        }
        .padding()
        .background(RomanianColors.cardBack)
    }
}