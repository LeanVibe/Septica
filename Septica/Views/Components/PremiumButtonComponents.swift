//
//  PremiumButtonComponents.swift
//  Septica
//
//  Premium glass morphism UI components with Romanian cultural elements
//  ShuffleCats-quality visual polish with sophisticated micro-interactions
//

import SwiftUI

/// Premium glass morphism button system with Romanian cultural themes
/// Features blur effects, sophisticated hover states, and cultural integration
struct PremiumButtonComponents {

    // MARK: - Glass Morphism Action Buttons

    /// Primary glass morphism button with Romanian gold accent
    struct PremiumGlassButton: View {
        let title: String
        let subtitle: String?
        let iconName: String?
        let action: () -> Void
        let buttonStyle: GlassButtonStyle

        @State private var isHovered = false
        @State private var isPressed = false
        @State private var shimmerOffset: CGFloat = -200
        @State private var pulseScale: CGFloat = 1.0

        init(
            title: String,
            subtitle: String? = nil,
            iconName: String? = nil,
            style: GlassButtonStyle = .primary,
            action: @escaping () -> Void
        ) {
            self.title = title
            self.subtitle = subtitle
            self.iconName = iconName
            self.buttonStyle = style
            self.action = action
        }

        var body: some View {
            Button(action: action) {
                ZStack {
                    // Glass morphism background with blur
                    glassBackground

                    // Romanian cultural gradient overlay
                    culturalGradientOverlay

                    // Subtle shimmer effect for premium feel
                    shimmerEffect

                    // Button content
                    buttonContent

                    // Interactive hover state overlay
                    hoverStateOverlay
                }
                .scaleEffect(isPressed ? 0.96 : (isHovered ? 1.02 : 1.0))
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovered)
                .animation(.spring(response: 0.2, dampingFraction: 0.8), value: isPressed)
            }
            .buttonStyle(.plain)
            .onHover { hovering in
                withAnimation(.easeInOut(duration: 0.2)) {
                    isHovered = hovering
                }

                // Trigger haptic feedback on hover (iOS 17+)
                if hovering {
                    HapticManager.shared.lightImpact()
                }
            }
            .onAppear {
                // Start shimmer animation
                withAnimation(.linear(duration: 3.0).repeatForever(autoreverses: false)) {
                    shimmerOffset = 200
                }

                // Start subtle pulsing for primary buttons
                if buttonStyle == .primary {
                    withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                        pulseScale = 1.05
                    }
                }
            }
        }

        // MARK: - Glass Morphism Background

        private var glassBackground: some View {
            RoundedRectangle(cornerRadius: buttonStyle.cornerRadius)
                .fill(.ultraThinMaterial)
                .background(
                    RoundedRectangle(cornerRadius: buttonStyle.cornerRadius)
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
                )
                .overlay(
                    RoundedRectangle(cornerRadius: buttonStyle.cornerRadius)
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
        }

        // MARK: - Cultural Gradient Overlay

        private var culturalGradientOverlay: some View {
            RoundedRectangle(cornerRadius: buttonStyle.cornerRadius)
                .fill(
                    LinearGradient(
                        colors: buttonStyle.gradientColors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .opacity(isHovered ? 0.3 : 0.15)
                .animation(.easeInOut(duration: 0.3), value: isHovered)
        }

        // MARK: - Shimmer Effect

        private var shimmerEffect: some View {
            RoundedRectangle(cornerRadius: buttonStyle.cornerRadius)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.clear,
                            Color.white.opacity(0.3),
                            Color.clear
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .offset(x: shimmerOffset)
                .mask(
                    RoundedRectangle(cornerRadius: buttonStyle.cornerRadius)
                )
        }

        // MARK: - Button Content

        private var buttonContent: some View {
            HStack(spacing: 12) {
                if let iconName = iconName {
                    Image(systemName: iconName)
                        .font(.title2.weight(.semibold))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(title.uppercased())
                        .font(.headline.weight(.bold))
                        .foregroundColor(.white)
                        .tracking(1.2)
                        .shadow(color: .black.opacity(0.4), radius: 2, x: 0, y: 1)

                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.caption.weight(.medium))
                            .foregroundColor(.white.opacity(0.8))
                            .shadow(color: .black.opacity(0.3), radius: 1, x: 0, y: 1)
                    }
                }

                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
        }

        // MARK: - Hover State Overlay

        private var hoverStateOverlay: some View {
            RoundedRectangle(cornerRadius: buttonStyle.cornerRadius)
                .fill(
                    RadialGradient(
                        colors: [
                            RomanianColors.goldAccent.opacity(isHovered ? 0.2 : 0.0),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 10,
                        endRadius: 100
                    )
                )
                .scaleEffect(pulseScale)
                .animation(.easeInOut(duration: 0.3), value: isHovered)
        }
    }

    /// Secondary glass morphism button with cultural variants
    struct PremiumGlassSecondaryButton: View {
        let title: String
        let iconName: String
        let culturalTheme: CulturalTheme
        let action: () -> Void

        @State private var isHovered = false
        @State private var glowIntensity: Double = 0.0

        var body: some View {
            Button(action: action) {
                ZStack {
                    // Glass background
                    glassBackground

                    // Cultural theme overlay
                    culturalThemeOverlay

                    // Content
                    buttonContent

                    // Hover glow
                    hoverGlow
                }
                .scaleEffect(isHovered ? 1.05 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovered)
            }
            .buttonStyle(.plain)
            .onHover { hovering in
                withAnimation(.easeInOut(duration: 0.2)) {
                    isHovered = hovering
                    glowIntensity = hovering ? 1.0 : 0.0
                }

                if hovering {
                    HapticManager.shared.lightImpact()
                }
            }
        }

        private var glassBackground: some View {
            RoundedRectangle(cornerRadius: 20)
                .fill(.thinMaterial)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.08),
                                    Color.white.opacity(0.02)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
                )
        }

        private var culturalThemeOverlay: some View {
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        colors: culturalTheme.gradientColors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .opacity(isHovered ? 0.4 : 0.2)
                .animation(.easeInOut(duration: 0.3), value: isHovered)
        }

        private var buttonContent: some View {
            HStack(spacing: 10) {
                Image(systemName: iconName)
                    .font(.headline.weight(.medium))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.3), radius: 1, x: 0, y: 1)

                Text(title.uppercased())
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.white)
                    .tracking(0.8)
                    .shadow(color: .black.opacity(0.3), radius: 1, x: 0, y: 1)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
        }

        private var hoverGlow: some View {
            RoundedRectangle(cornerRadius: 20)
                .stroke(
                    LinearGradient(
                        colors: [
                            culturalTheme.accentColor.opacity(glowIntensity * 0.8),
                            culturalTheme.accentColor.opacity(glowIntensity * 0.2)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2
                )
                .shadow(
                    color: culturalTheme.accentColor.opacity(glowIntensity * 0.4),
                    radius: 8,
                    x: 0,
                    y: 0
                )
        }
    }

    /// Floating action button with glass morphism and Romanian cultural elements
    struct PremiumFloatingActionButton: View {
        let iconName: String
        let culturalAccent: CulturalAccent
        let action: () -> Void

        @State private var isHovered = false
        @State private var rotationAngle: Double = 0.0
        @State private var pulseScale: CGFloat = 1.0

        var body: some View {
            Button(action: action) {
                ZStack {
                    // Glass sphere background
                    Circle()
                        .fill(.ultraThinMaterial)
                        .background(
                            Circle()
                                .fill(
                                    RadialGradient(
                                        colors: [
                                            Color.white.opacity(0.2),
                                            Color.white.opacity(0.05),
                                            Color.clear
                                        ],
                                        center: .topLeading,
                                        startRadius: 5,
                                        endRadius: 25
                                    )
                                )
                        )
                        .overlay(
                            Circle()
                                .stroke(
                                    LinearGradient(
                                        colors: [
                                            Color.white.opacity(0.4),
                                            Color.white.opacity(0.1)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1.5
                                )
                        )

                    // Cultural accent ring
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: culturalAccent.ringColors,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 3
                        )
                        .opacity(isHovered ? 1.0 : 0.6)
                        .scaleEffect(pulseScale)

                    // Icon
                    Image(systemName: iconName)
                        .font(.title2.weight(.semibold))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                        .rotationEffect(.degrees(rotationAngle))

                    // Hover glow
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    culturalAccent.glowColor.opacity(isHovered ? 0.6 : 0.2),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 5,
                                endRadius: 30
                            )
                        )
                }
                .frame(width: 64, height: 64)
                .scaleEffect(isHovered ? 1.1 : 1.0)
                .rotationEffect(.degrees(isHovered ? 5 : 0))
                .animation(.spring(response: 0.4, dampingFraction: 0.7), value: isHovered)
                .animation(.linear(duration: 8.0).repeatForever(autoreverses: false), value: rotationAngle)
                .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: pulseScale)
                .shadow(color: culturalAccent.shadowColor.opacity(0.4), radius: 12, x: 0, y: 6)
            }
            .buttonStyle(.plain)
            .onHover { hovering in
                withAnimation(.easeInOut(duration: 0.2)) {
                    isHovered = hovering
                }

                if hovering {
                    HapticManager.shared.mediumImpact()
                }
            }
            .onAppear {
                rotationAngle = 360.0
                pulseScale = 1.1
            }
        }
    }

    // MARK: - Supporting Types

    enum GlassButtonStyle {
        case primary    // Gold accent Romanian theme
        case secondary  // Blue accent Romanian theme
        case tertiary   // Green accent Romanian theme
        case danger     // Red accent Romanian theme

        var cornerRadius: CGFloat {
            switch self {
            case .primary: return 28
            case .secondary: return 24
            case .tertiary: return 22
            case .danger: return 26
            }
        }

        var gradientColors: [Color] {
            switch self {
            case .primary:
                return [
                    RomanianColors.goldAccent,
                    RomanianColors.primaryYellow,
                    RomanianColors.goldAccent
                ]
            case .secondary:
                return [
                    RomanianColors.primaryBlue,
                    RomanianColors.folkBlue,
                    RomanianColors.primaryBlue
                ]
            case .tertiary:
                return [
                    RomanianColors.countrysideGreen,
                    RomanianColors.tableGreen,
                    RomanianColors.countrysideGreen
                ]
            case .danger:
                return [
                    RomanianColors.embroideryRed,
                    RomanianColors.primaryRed,
                    RomanianColors.embroideryRed
                ]
            }
        }
    }

    enum CulturalTheme {
        case traditional   // Romanian flag colors
        case carpathian    // Mountain landscape
        case pottery       // Traditional Romanian pottery
        case byzantine     // Byzantine gold influence

        var gradientColors: [Color] {
            switch self {
            case .traditional:
                return [RomanianColors.primaryBlue, RomanianColors.primaryYellow, RomanianColors.primaryRed]
            case .carpathian:
                return [RomanianColors.countrysideGreen, RomanianColors.tableGreen]
            case .pottery:
                return [RomanianColors.folkBlue, Color(red: 0.3, green: 0.5, blue: 0.8)]
            case .byzantine:
                return [RomanianColors.byzantineGold, RomanianColors.goldAccent]
            }
        }

        var accentColor: Color {
            switch self {
            case .traditional: return RomanianColors.primaryBlue
            case .carpathian: return RomanianColors.countrysideGreen
            case .pottery: return RomanianColors.folkBlue
            case .byzantine: return RomanianColors.byzantineGold
            }
        }
    }

    enum CulturalAccent {
        case gold
        case blue
        case red
        case green

        var ringColors: [Color] {
            switch self {
            case .gold:
                return [RomanianColors.goldAccent, RomanianColors.byzantineGold]
            case .blue:
                return [RomanianColors.primaryBlue, RomanianColors.folkBlue]
            case .red:
                return [RomanianColors.primaryRed, RomanianColors.embroideryRed]
            case .green:
                return [RomanianColors.countrysideGreen, RomanianColors.tableGreen]
            }
        }

        var glowColor: Color {
            switch self {
            case .gold: return RomanianColors.goldAccent
            case .blue: return RomanianColors.primaryBlue
            case .red: return RomanianColors.primaryRed
            case .green: return RomanianColors.countrysideGreen
            }
        }

        var shadowColor: Color {
            switch self {
            case .gold: return RomanianColors.goldAccent
            case .blue: return RomanianColors.primaryBlue
            case .red: return RomanianColors.embroideryRed
            case .green: return RomanianColors.tableGreen
            }
        }
    }
}

// MARK: - Premium Button Styles for SwiftUI Integration

extension PremiumButtonComponents {

    /// Glass morphism button style for SwiftUI integration
    struct GlassButtonStyle: ButtonStyle {
        let theme: CulturalTheme
        let isPressed: Bool

        init(theme: CulturalTheme = .traditional, isPressed: Bool = false) {
            self.theme = theme
            self.isPressed = isPressed
        }

        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
                .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(
                                    LinearGradient(
                                        colors: theme.gradientColors,
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .opacity(configuration.isPressed ? 0.4 : 0.2)
                        )
                )
        }
    }
}

// MARK: - Accessibility Support

extension PremiumButtonComponents.PremiumGlassButton {
    /// Enhanced accessibility support for VoiceOver and Dynamic Type
    func accessibilityEnhanced() -> some View {
        self
            .accessibilityLabel(title)
            .accessibilityHint(subtitle ?? "Glass morphism button with Romanian cultural theme")
            .accessibilityAddTraits(.isButton)
            .dynamicTypeSize(.medium ... .accessibility1)
    }
}

extension PremiumButtonComponents.PremiumGlassSecondaryButton {
    /// Enhanced accessibility support for VoiceOver and Dynamic Type
    func accessibilityEnhanced() -> some View {
        self
            .accessibilityLabel(title)
            .accessibilityHint("Secondary glass button with \(culturalTheme) theme")
            .accessibilityAddTraits(.isButton)
            .dynamicTypeSize(.medium ... .accessibility1)
    }
}

extension PremiumButtonComponents.PremiumFloatingActionButton {
    /// Enhanced accessibility support for VoiceOver and Dynamic Type
    func accessibilityEnhanced() -> some View {
        self
            .accessibilityLabel("Action button")
            .accessibilityHint("Floating action button with \(culturalAccent) accent")
            .accessibilityAddTraits(.isButton)
            .dynamicTypeSize(.medium ... .accessibility1)
    }
}

// MARK: - Preview

struct PremiumButtonComponents_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 30) {
            // Primary glass button
            PremiumButtonComponents.PremiumGlassButton(
                title: "Joacă",
                subtitle: "Confirmă cartea",
                iconName: "play.fill",
                style: .primary
            ) {
                print("Primary button tapped")
            }
            .accessibilityEnhanced()

            HStack(spacing: 20) {
                // Secondary buttons with cultural themes
                PremiumButtonComponents.PremiumGlassSecondaryButton(
                    title: "Treci",
                    iconName: "hand.raised.fill",
                    culturalTheme: .carpathian
                ) {
                    print("Secondary button tapped")
                }
                .accessibilityEnhanced()

                PremiumButtonComponents.PremiumGlassSecondaryButton(
                    title: "Meniu",
                    iconName: "line.3.horizontal",
                    culturalTheme: .pottery
                ) {
                    print("Menu button tapped")
                }
                .accessibilityEnhanced()
            }

            HStack(spacing: 30) {
                // Floating action buttons
                PremiumButtonComponents.PremiumFloatingActionButton(
                    iconName: "plus.fill",
                    culturalAccent: .gold
                ) {
                    print("FAB tapped")
                }
                .accessibilityEnhanced()

                PremiumButtonComponents.PremiumFloatingActionButton(
                    iconName: "heart.fill",
                    culturalAccent: .red
                ) {
                    print("FAB tapped")
                }
                .accessibilityEnhanced()

                PremiumButtonComponents.PremiumFloatingActionButton(
                    iconName: "star.fill",
                    culturalAccent: .blue
                ) {
                    print("FAB tapped")
                }
                .accessibilityEnhanced()
            }
        }
        .padding(40)
        .background(
            LinearGradient(
                colors: [Color(red: 0.02, green: 0.08, blue: 0.22), Color(red: 0.12, green: 0.26, blue: 0.32)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .previewDisplayName("Premium Button Components")
    }
}