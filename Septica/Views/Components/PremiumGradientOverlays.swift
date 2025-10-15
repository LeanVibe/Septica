//
//  PremiumGradientOverlays.swift
//  Septica
//
//  Premium gradient overlays with Romanian cultural themes
//  Glass morphism integration with ShuffleCats-quality visual polish
//

import SwiftUI

/// Premium gradient overlay system with Romanian cultural integration
/// Features animated gradients, glass morphism effects, and cultural patterns
struct PremiumGradientOverlays {

    // MARK: - Main Gradient Overlay Components

    /// Premium gradient overlay for game screens with Romanian cultural themes
    struct GameScreenGradientOverlay: View {
        let culturalTheme: CulturalGradientTheme
        let animationState: OverlayAnimationState
        let isInteractive: Bool

        @State private var gradientOffset: CGPoint = .zero
        @State private var pulseOpacity: Double = 1.0
        @State private var rotationAngle: Double = 0.0

        var body: some View {
            ZStack {
                // Base cultural gradient
                baseCulturalGradient

                // Animated cultural pattern overlay
                animatedCulturalPattern

                // Glass morphism effect layers
                glassMorphismLayers

                // Interactive hover gradient
                if isInteractive {
                    interactiveHoverGradient
                }

                // Ambient lighting effects
                ambientLightingEffects

                // Cultural accent points
                culturalAccentPoints
            }
            .onAppear {
                startAnimations()
            }
            .onChange(of: animationState) { newState in
                respondToAnimationState(newState)
            }
        }

        // MARK: - Base Cultural Gradient

        private var baseCulturalGradient: some View {
            LinearGradient(
                colors: culturalTheme.baseGradient,
                startPoint: gradientOffset,
                endPoint: CGPoint(x: gradientOffset.x + 1, y: gradientOffset.y + 1)
            )
            .opacity(pulseOpacity)
            .animation(.easeInOut(duration: 4.0).repeatForever(autoreverses: true), value: pulseOpacity)
            .animation(.linear(duration: 20.0).repeatForever(autoreverses: false), value: gradientOffset)
        }

        // MARK: - Animated Cultural Pattern

        private var animatedCulturalPattern: some View {
            GeometryReader { geometry in
                ZStack {
                    // Romanian folk pattern elements
                    ForEach(0..<culturalTheme.patternCount, id: \.self) { index in
                        CulturalPatternElement(
                            patternType: culturalTheme.patternType,
                            position: calculatePatternPosition(index: index, in: geometry.size),
                            size: calculatePatternSize(index: index),
                            rotation: Double(index) * 45 + rotationAngle,
                            opacity: 0.1 + (Double(index) * 0.02)
                        )
                    }
                }
            }
            .rotationEffect(.degrees(rotationAngle))
            .animation(.linear(duration: 60.0).repeatForever(autoreverses: false), value: rotationAngle)
        }

        // MARK: - Glass Morphism Layers

        private var glassMorphismLayers: some View {
            ZStack {
                // Primary glass layer
                RoundedRectangle(cornerRadius: 0)
                    .fill(.ultraThinMaterial)
                    .opacity(0.15)

                // Secondary glass layer with blur
                RoundedRectangle(cornerRadius: 0)
                    .fill(.thinMaterial)
                    .opacity(0.08)
                    .blur(radius: 2)

                // Tertiary glass layer with texture
                RoundedRectangle(cornerRadius: 0)
                    .fill(.regularMaterial)
                    .opacity(0.05)
                    .blendMode(.overlay)
            }
        }

        // MARK: - Interactive Hover Gradient

        private var interactiveHoverGradient: some View {
            RadialGradient(
                colors: [
                    culturalTheme.interactiveColor.opacity(0.3),
                    culturalTheme.interactiveColor.opacity(0.1),
                    Color.clear
                ],
                center: .center,
                startRadius: 50,
                endRadius: 300
            )
            .scaleEffect(animationState == .active ? 1.2 : 1.0)
            .animation(.spring(response: 0.6, dampingFraction: 0.8), value: animationState)
        }

        // MARK: - Ambient Lighting Effects

        private var ambientLightingEffects: some View {
            ZStack {
                // Top ambient glow
                RadialGradient(
                    colors: [
                        culturalTheme.ambientColor.opacity(0.2),
                        Color.clear
                    ],
                    center: .top,
                    startRadius: 20,
                    endRadius: 200
                )

                // Bottom ambient glow
                RadialGradient(
                    colors: [
                        culturalTheme.ambientColor.opacity(0.15),
                        Color.clear
                    ],
                    center: .bottom,
                    startRadius: 20,
                    endRadius: 200
                )

                // Side ambient glows
                HStack {
                    RadialGradient(
                        colors: [
                            culturalTheme.accentColor.opacity(0.1),
                            Color.clear
                        ],
                        center: .leading,
                        startRadius: 10,
                        endRadius: 150
                    )
                    Spacer()
                    RadialGradient(
                        colors: [
                            culturalTheme.accentColor.opacity(0.1),
                            Color.clear
                        ],
                        center: .trailing,
                        startRadius: 10,
                        endRadius: 150
                    )
                }
            }
        }

        // MARK: - Cultural Accent Points

        private var culturalAccentPoints: some View {
            GeometryReader { geometry in
                ZStack {
                    ForEach(0..<5, id: \.self) { index in
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [
                                        culturalTheme.accentColor.opacity(0.4),
                                        culturalTheme.accentColor.opacity(0.1),
                                        Color.clear
                                    ],
                                    center: .center,
                                    startRadius: 5,
                                    endRadius: 30
                                )
                            )
                            .frame(width: 60, height: 60)
                            .position(
                                x: geometry.size.width * CGFloat([0.2, 0.8, 0.5, 0.3, 0.7][index]),
                                y: geometry.size.height * CGFloat([0.3, 0.4, 0.7, 0.8, 0.2][index])
                            )
                            .opacity(0.3 + (Double(index) * 0.1))
                            .scaleEffect(1.0 + (sin(animationState.progress * 2 + Double(index)) * 0.2))
                    }
                }
            }
            .animation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true), value: animationState.progress)
        }

        // MARK: - Animation Methods

        private func startAnimations() {
            withAnimation(.linear(duration: 20.0).repeatForever(autoreverses: false)) {
                gradientOffset = CGPoint(x: 1, y: 1)
            }

            withAnimation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true)) {
                pulseOpacity = 0.7
            }

            withAnimation(.linear(duration: 60.0).repeatForever(autoreverses: false)) {
                rotationAngle = 360.0
            }
        }

        private func respondToAnimationState(_ state: OverlayAnimationState) {
            switch state {
            case .idle:
                break
            case .active:
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    pulseOpacity = 1.0
                }
            case .celebration:
                withAnimation(.spring(response: 0.8, dampingFraction: 0.6)) {
                    pulseOpacity = 1.2
                }
            case .transition:
                withAnimation(.easeInOut(duration: 0.6)) {
                    gradientOffset = CGPoint(x: 0, y: 0)
                }
            }
        }

        // MARK: - Helper Methods

        private func calculatePatternPosition(index: Int, in size: CGSize) -> CGPoint {
            let positions = [
                CGPoint(x: size.width * 0.2, y: size.height * 0.2),
                CGPoint(x: size.width * 0.8, y: size.height * 0.3),
                CGPoint(x: size.width * 0.5, y: size.height * 0.7),
                CGPoint(x: size.width * 0.3, y: size.height * 0.8),
                CGPoint(x: size.width * 0.7, y: size.height * 0.6)
            ]
            return positions[index % positions.count]
        }

        private func calculatePatternSize(index: Int) -> CGFloat {
            return 40 + (CGFloat(index % 3) * 20)
        }
    }

    /// Premium menu overlay with glass morphism and cultural themes
    struct MenuGradientOverlay: View {
        let culturalTheme: CulturalGradientTheme
        let menuState: MenuState
        let onBackgroundTap: () -> Void

        @State private var backgroundOpacity: Double = 0.0
        @State private var menuScale: CGFloat = 0.8
        @State private var menuRotation: Double = 0.0

        var body: some View {
            ZStack {
                // Background with glass morphism
                backgroundGlassOverlay
                    .onTapGesture {
                        onBackgroundTap()
                    }

                // Menu content gradient
                menuContentGradient

                // Cultural pattern backdrop
                culturalPatternBackdrop

                // Ambient menu lighting
                ambientMenuLighting

                // Menu container with glass effect
                menuGlassContainer
            }
            .onAppear {
                showMenu()
            }
            .onChange(of: menuState) { newState in
                respondToMenuState(newState)
            }
        }

        // MARK: - Background Glass Overlay

        private var backgroundGlassOverlay: some View {
            ZStack {
                // Dark blur background
                Color.black.opacity(0.6)

                // Cultural gradient overlay
                LinearGradient(
                    colors: [
                        culturalTheme.baseGradient[0].opacity(0.3),
                        culturalTheme.baseGradient[1].opacity(0.2),
                        culturalTheme.baseGradient[2].opacity(0.1)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .opacity(backgroundOpacity)

                // Glass material overlay
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .opacity(0.3)
            }
            .animation(.easeInOut(duration: 0.4), value: backgroundOpacity)
        }

        // MARK: - Menu Content Gradient

        private var menuContentGradient: some View {
            RoundedRectangle(cornerRadius: 24)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.1),
                            Color.white.opacity(0.05),
                            Color.clear
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .background(
                    RoundedRectangle(cornerRadius: 24)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 24)
                                .stroke(
                                    LinearGradient(
                                        colors: [
                                            Color.white.opacity(0.3),
                                            Color.white.opacity(0.1),
                                            Color.clear
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1.5
                                )
                        )
                )
                .scaleEffect(menuScale)
                .rotationEffect(.degrees(menuRotation))
                .animation(.spring(response: 0.6, dampingFraction: 0.8), value: menuScale)
                .animation(.easeInOut(duration: 0.8), value: menuRotation)
        }

        // MARK: - Cultural Pattern Backdrop

        private var culturalPatternBackdrop: some View {
            GeometryReader { geometry in
                ZStack {
                    ForEach(0..<3, id: \.self) { index in
                        CulturalPatternElement(
                            patternType: .traditional,
                            position: CGPoint(
                                x: geometry.size.width * (0.2 + Double(index) * 0.3),
                                y: geometry.size.height * (0.3 + Double(index) * 0.2)
                            ),
                            size: 80 + CGFloat(index * 20),
                            rotation: Double(index * 30),
                            opacity: 0.05
                        )
                    }
                }
            }
        }

        // MARK: - Ambient Menu Lighting

        private var ambientMenuLighting: some View {
            ZStack {
                // Top menu light
                RadialGradient(
                    colors: [
                        culturalTheme.ambientColor.opacity(0.3),
                        Color.clear
                    ],
                    center: .top,
                    startRadius: 20,
                    endRadius: 150
                )

                // Center menu light
                RadialGradient(
                    colors: [
                        culturalTheme.accentColor.opacity(0.2),
                        Color.clear
                    ],
                    center: .center,
                    startRadius: 30,
                    endRadius: 200
                )
            }
        }

        // MARK: - Menu Glass Container

        private var menuGlassContainer: some View {
            RoundedRectangle(cornerRadius: 24)
                .fill(.thinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    culturalTheme.accentColor.opacity(0.3),
                                    culturalTheme.accentColor.opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
                .shadow(color: culturalTheme.accentColor.opacity(0.3), radius: 20, x: 0, y: 10)
                .scaleEffect(menuScale)
                .animation(.spring(response: 0.5, dampingFraction: 0.7), value: menuScale)
        }

        // MARK: - Animation Methods

        private func showMenu() {
            withAnimation(.easeInOut(duration: 0.3)) {
                backgroundOpacity = 1.0
            }

            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                menuScale = 1.0
            }

            withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                menuRotation = 2.0
            }
        }

        private func respondToMenuState(_ state: MenuState) {
            switch state {
            case .opening:
                showMenu()
            case .open:
                break
            case .closing:
                withAnimation(.easeInOut(duration: 0.3)) {
                    backgroundOpacity = 0.0
                    menuScale = 0.8
                }
            case .closed:
                break
            }
        }
    }

    // MARK: - Supporting Components

    /// Individual cultural pattern element
    struct CulturalPatternElement: View {
        let patternType: PatternType
        let position: CGPoint
        let size: CGFloat
        let rotation: Double
        let opacity: Double

        var body: some View {
            Image(systemName: patternType.systemImage)
                .font(.system(size: size, weight: .light))
                .foregroundColor(.white)
                .opacity(opacity)
                .rotationEffect(.degrees(rotation))
                .position(position)
                .blur(radius: 1)
        }
    }

    // MARK: - Supporting Types

    enum CulturalGradientTheme {
        case romanianHeritage    // Romanian flag colors
        case carpathianMountains // Mountain landscape
        case traditionalPottery  // Romanian pottery
        case byzantineArt       // Byzantine gold influence
        case folkEmbroidery     // Traditional embroidery

        var baseGradient: [Color] {
            switch self {
            case .romanianHeritage:
                return [RomanianColors.primaryBlue, RomanianColors.primaryYellow, RomanianColors.primaryRed]
            case .carpathianMountains:
                return [RomanianColors.countrysideGreen, RomanianColors.tableGreen, Color(red: 0.2, green: 0.4, blue: 0.1)]
            case .traditionalPottery:
                return [RomanianColors.folkBlue, Color(red: 0.3, green: 0.5, blue: 0.8), RomanianColors.primaryBlue]
            case .byzantineArt:
                return [RomanianColors.byzantineGold, RomanianColors.goldAccent, Color(red: 1.0, green: 0.9, blue: 0.2)]
            case .folkEmbroidery:
                return [RomanianColors.embroideryRed, RomanianColors.primaryRed, Color(red: 0.95, green: 0.3, blue: 0.3)]
            }
        }

        var accentColor: Color {
            switch self {
            case .romanianHeritage: return RomanianColors.primaryBlue
            case .carpathianMountains: return RomanianColors.countrysideGreen
            case .traditionalPottery: return RomanianColors.folkBlue
            case .byzantineArt: return RomanianColors.byzantineGold
            case .folkEmbroidery: return RomanianColors.embroideryRed
            }
        }

        var ambientColor: Color {
            switch self {
            case .romanianHeritage: return RomanianColors.primaryYellow
            case .carpathianMountains: return RomanianColors.tableGreen
            case .traditionalPottery: return RomanianColors.primaryBlue
            case .byzantineArt: return RomanianColors.goldAccent
            case .folkEmbroidery: return RomanianColors.primaryRed
            }
        }

        var interactiveColor: Color {
            return accentColor
        }

        var patternType: PatternType {
            switch self {
            case .romanianHeritage: return .traditional
            case .carpathianMountains: return .mountain
            case .traditionalPottery: return .pottery
            case .byzantineArt: return .byzantine
            case .folkEmbroidery: return .embroidery
            }
        }

        var patternCount: Int {
            switch self {
            case .romanianHeritage: return 8
            case .carpathianMountains: return 6
            case .traditionalPottery: return 5
            case .byzantineArt: return 7
            case .folkEmbroidery: return 9
            }
        }
    }

    enum OverlayAnimationState: Equatable {
        case idle
        case active
        case celebration
        case transition

        var progress: Double {
            switch self {
            case .idle: return 0.0
            case .active: return 0.5
            case .celebration: return 1.0
            case .transition: return 0.25
            }
        }
    }

    enum MenuState {
        case opening
        case open
        case closing
        case closed
    }

    enum PatternType {
        case traditional
        case mountain
        case pottery
        case byzantine
        case embroidery

        var systemImage: String {
            switch self {
            case .traditional: return "star.circle"
            case .mountain: return "mountain.2"
            case .pottery: return "circle.hexagongrid"
            case .byzantine: return "sun.max"
            case .embroidery: return "thread"
            }
        }
    }
}

// MARK: - Performance Optimization

extension PremiumGradientOverlays.GameScreenGradientOverlay {
    /// Optimized version for better performance
    func performanceOptimized() -> some View {
        self
            .drawingGroup(opaque: false, colorMode: .nonLinear)
            .clipped()
    }
}

extension PremiumGradientOverlays.MenuGradientOverlay {
    /// Optimized version for better performance
    func performanceOptimized() -> some View {
        self
            .drawingGroup(opaque: false, colorMode: .nonLinear)
            .clipped()
    }
}

// MARK: - Accessibility Support

extension PremiumGradientOverlays.GameScreenGradientOverlay {
    /// Enhanced accessibility support
    func accessibilityEnhanced() -> some View {
        self
            .accessibilityHidden(true) // Decorative background
            .accessibilityElement(children: .ignore)
    }
}

extension PremiumGradientOverlays.MenuGradientOverlay {
    /// Enhanced accessibility support
    func accessibilityEnhanced() -> some View {
        self
            .accessibilityLabel("Menu overlay")
            .accessibilityHint("Tap outside to close menu")
            .accessibilityAddTraits(.isModal)
    }
}

// MARK: - Preview

struct PremiumGradientOverlays_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Game screen overlay preview
            PremiumGradientOverlays.GameScreenGradientOverlay(
                culturalTheme: .romanianHeritage,
                animationState: .active,
                isInteractive: true
            )
            .frame(width: 400, height: 300)
            .previewDisplayName("Game Screen Overlay")

            // Menu overlay preview
            PremiumGradientOverlays.MenuGradientOverlay(
                culturalTheme: .byzantineArt,
                menuState: .open,
                onBackgroundTap: {}
            )
            .frame(width: 400, height: 300)
            .previewDisplayName("Menu Overlay")

            // Cultural themes preview
            VStack(spacing: 20) {
                ForEach([
                    PremiumGradientOverlays.CulturalGradientTheme.romanianHeritage,
                    .carpathianMountains,
                    .traditionalPottery,
                    .byzantineArt,
                    .folkEmbroidery
                ], id: \.self) { theme in
                    HStack {
                        Text("\(String(describing: theme))")
                            .font(.caption)
                            .foregroundColor(.white)
                        Spacer()
                        RoundedRectangle(cornerRadius: 8)
                            .fill(
                                LinearGradient(
                                    colors: theme.baseGradient,
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: 100, height: 30)
                    }
                    .padding(.horizontal)
                }
            }
            .padding()
            .background(Color.black)
            .previewDisplayName("Cultural Themes")
        }
    }
}