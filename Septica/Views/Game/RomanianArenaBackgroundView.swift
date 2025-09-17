//
//  RomanianArenaBackgroundView.swift
//  Septica
//
//  Rich Romanian cultural arena backgrounds with immersive environmental details
//  Each arena provides authentic cultural atmosphere and visual storytelling
//

import SwiftUI

// Note: Color(hex:) extension is now defined in RomanianColors.swift

/// Comprehensive Romanian arena background system with rich cultural immersion
/// Provides dynamic, atmospheric backgrounds that enhance gameplay experience
struct RomanianArenaBackgroundView: View {
    let arena: RomanianArena
    let gamePhase: GamePhase
    @State private var animationOffset: CGFloat = 0
    @State private var cloudMovement: CGFloat = 0
    @State private var particleAnimation: Bool = false
    @State private var ambientGlow: Bool = false
    
    enum GamePhase {
        case opening, midGame, endGame, victory
        
        var atmosphericIntensity: Double {
            switch self {
            case .opening: return 0.6
            case .midGame: return 0.8
            case .endGame: return 1.0
            case .victory: return 1.2
            }
        }
    }
    
    var body: some View {
        ZStack {
            // Base atmospheric background
            arenaAtmosphericBackground
            
            // Environmental layers
            environmentalElements
            
            // Animated atmospheric effects
            atmosphericEffects
            
            // Cultural detail overlay
            culturalDetailsOverlay
            
            // Game phase atmospheric enhancement
            gamePhaseAtmosphere
        }
        .onAppear {
            startAtmosphericAnimations()
        }
    }
    
    // MARK: - Arena-Specific Atmospheric Backgrounds
    
    @ViewBuilder
    private var arenaAtmosphericBackground: some View {
        switch arena {
        case .sateImarica:
            // Traditional Romanian village atmosphere
            VillageAtmosphereView(
                primaryColor: Color(hex: arena.primaryColor),
                accentColor: Color(hex: arena.accentColor),
                intensity: gamePhase.atmosphericIntensity
            )
            
        case .satuMihai:
            // Rural countryside with rolling hills
            CountrysideAtmosphereView(
                primaryColor: Color(hex: arena.primaryColor),
                forestDensity: 0.7,
                intensity: gamePhase.atmosphericIntensity
            )
            
        case .orasulBrara:
            // Small town atmosphere with folk elements
            GenericTownAtmosphere(
                primaryColor: Color(hex: arena.primaryColor),
                accentColor: Color(hex: arena.accentColor),
                intensity: gamePhase.atmosphericIntensity
            )
            
        case .orasulBacau:
            // Regional city atmosphere with artisan elements
            GenericTownAtmosphere(
                primaryColor: Color(hex: arena.primaryColor),
                accentColor: Color(hex: arena.accentColor),
                intensity: gamePhase.atmosphericIntensity
            )
            
        case .orasulBrasov:
            // Transylvanian medieval fortress atmosphere
            TransylvanianFortressAtmosphere(
                primaryColor: Color(hex: arena.primaryColor),
                carpathianMountains: true,
                gothicArchitecture: true,
                intensity: gamePhase.atmosphericIntensity
            )
            
        case .orasulCluj:
            // Academic and cultural center atmosphere
            AcademicCityAtmosphere(
                primaryColor: Color(hex: arena.primaryColor),
                culturalElements: .university,
                intensity: gamePhase.atmosphericIntensity
            )
            
        case .orasulConstanta:
            // Black Sea coastal atmosphere
            BlackSeaCoastalAtmosphere(
                primaryColor: Color(hex: arena.primaryColor),
                seaWaves: true,
                portActivity: true,
                intensity: gamePhase.atmosphericIntensity
            )
            
        case .orasulIasi:
            // Cultural and historical center
            CulturalCenterAtmosphere(
                primaryColor: Color(hex: arena.primaryColor),
                historicalMonuments: true,
                intellectualAura: true,
                intensity: gamePhase.atmosphericIntensity
            )
            
        case .orasulTimisoara:
            // Historic Habsburg architecture
            HabsburgCityAtmosphere(
                primaryColor: Color(hex: arena.primaryColor),
                baroqueArchitecture: true,
                europeanFlair: true,
                intensity: gamePhase.atmosphericIntensity
            )
            
        case .orasulSibiu:
            // European Capital of Culture atmosphere
            EuropeanCulturalCapitalAtmosphere(
                primaryColor: Color(hex: arena.primaryColor),
                saxonArchitecture: true,
                culturalPrestige: true,
                intensity: gamePhase.atmosphericIntensity
            )
            
        case .marealeBucuresti:
            // Royal capital grandeur
            RoyalCapitalAtmosphere(
                primaryColor: Color(hex: arena.primaryColor),
                parliamentPalace: true,
                grandBoulevards: true,
                royalMajesty: true,
                intensity: gamePhase.atmosphericIntensity
            )
            
        default:
            // Generic town atmosphere for other arenas
            GenericTownAtmosphere(
                primaryColor: Color(hex: arena.primaryColor),
                accentColor: Color(hex: arena.accentColor),
                intensity: gamePhase.atmosphericIntensity
            )
        }
    }
    
    // MARK: - Environmental Elements Layer
    
    @ViewBuilder
    private var environmentalElements: some View {
        ZStack {
            // Background architectural elements
            arenaArchitecturalElements
                .opacity(0.3)
                .offset(x: animationOffset * 0.2)
            
            // Middle ground environmental details
            arenaEnvironmentalDetails
                .opacity(0.5)
                .offset(x: animationOffset * 0.5)
            
            // Foreground atmospheric particles
            arenaAtmosphericParticles
                .opacity(particleAnimation ? 0.8 : 0.4)
        }
    }
    
    @ViewBuilder
    private var arenaArchitecturalElements: some View {
        switch arena {
        case .sateImarica, .satuMihai:
            // Traditional wooden houses and folk elements
            HStack(spacing: 40) {
                WoodenHouseIcon()
                FolkFenceIcon()
                TraditionalWellIcon()
                WoodenHouseIcon()
            }
            
        case .orasulBrasov:
            // Gothic and medieval elements
            HStack(spacing: 60) {
                GothicTowerIcon()
                MedievalArchIcon()
                CarpathianMountainSilhouette()
            }
            
        case .marealeBucuresti:
            // Royal capital monuments
            HStack(spacing: 80) {
                ParliamentPalaceIcon()
                RoyalCrownIcon()
                TriumphalArchIcon()
            }
            
        default:
            // Traditional rooftops and streets
            HStack(spacing: 50) {
                TraditionalRooftopIcon()
                CobblestonePatternIcon()
                FolkArtIcon()
            }
        }
    }
    
    @ViewBuilder
    private var arenaEnvironmentalDetails: some View {
        switch arena {
        case .orasulConstanta:
            // Black Sea environmental details
            VStack {
                Spacer()
                SeaWavesAnimation()
                    .frame(height: 100)
                    .offset(x: cloudMovement * 2)
            }
            
        case .orasulBrasov:
            // Carpathian mountain atmosphere
            VStack {
                CarpathianMountainRange()
                    .frame(height: 150)
                    .offset(x: cloudMovement * 0.5)
                Spacer()
            }
            
        default:
            // Generic atmospheric elements
            VStack {
                CloudLayer()
                    .offset(x: cloudMovement)
                Spacer()
                GroundMistEffect()
            }
        }
    }
    
    @ViewBuilder
    private var arenaAtmosphericParticles: some View {
        switch arena {
        case .sateImarica, .satuMihai:
            // Rural atmosphere: floating pollen, leaves
            PollenParticleEffect()
                .opacity(particleAnimation ? 1.0 : 0.6)
            
        case .orasulConstanta:
            // Coastal atmosphere: sea spray, gulls
            SeaSprayParticleEffect()
                .opacity(particleAnimation ? 1.0 : 0.6)
            
        case .marealeBucuresti:
            // Urban atmosphere: golden light particles
            GoldenLightParticleEffect()
                .opacity(particleAnimation ? 1.0 : 0.6)
            
        default:
            // Generic atmospheric particles
            AtmosphericDustEffect()
                .opacity(particleAnimation ? 1.0 : 0.6)
        }
    }
    
    // MARK: - Atmospheric Effects
    
    @ViewBuilder
    private var atmosphericEffects: some View {
        ZStack {
            // Ambient glow effect
            ambientGlowLayer
            
            // Weather effects based on arena
            arenaWeatherEffects
            
            // Time-of-day lighting
            timeOfDayLighting
        }
    }
    
    private var ambientGlowLayer: some View {
        RadialGradient(
            gradient: Gradient(colors: [
                Color(hex: arena.primaryColor).opacity(ambientGlow ? 0.2 : 0.1),
                Color(hex: arena.accentColor).opacity(ambientGlow ? 0.1 : 0.05),
                Color.clear
            ]),
            center: .center,
            startRadius: 100,
            endRadius: 400
        )
        .animation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true), value: ambientGlow)
    }
    
    @ViewBuilder
    private var arenaWeatherEffects: some View {
        switch arena {
        case .orasulBrasov:
            // Mountain mist
            MountainMistEffect()
                .opacity(0.3)
                
        case .orasulConstanta:
            // Sea breeze effect
            SeaBreezeEffect()
                .opacity(0.4)
                
        case .sateImarica, .satuMihai:
            // Gentle countryside breeze
            CountrysideBreezeEffect()
                .opacity(0.2)
                
        default:
            // Light atmospheric movement
            GenericAtmosphereEffect()
                .opacity(0.25)
        }
    }
    
    private var timeOfDayLighting: some View {
        // Subtle lighting based on game phase
        LinearGradient(
            gradient: Gradient(colors: [
                gamePhase == .victory ? Color.yellow.opacity(0.1) : Color.clear,
                Color.clear,
                gamePhase == .endGame ? Color(hex: arena.primaryColor).opacity(0.15) : Color.clear
            ]),
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    // MARK: - Cultural Details Overlay
    
    @ViewBuilder
    private var culturalDetailsOverlay: some View {
        VStack {
            Spacer()
            
            HStack {
                Spacer()
                
                // Subtle cultural pattern in corner
                RomanianFolkPatternOverlay(arena: arena)
                    .frame(width: 80, height: 80)
                    .opacity(0.15)
                    .padding(.trailing, 20)
                    .padding(.bottom, 20)
            }
        }
    }
    
    // MARK: - Game Phase Atmosphere
    
    @ViewBuilder
    private var gamePhaseAtmosphere: some View {
        switch gamePhase {
        case .victory:
            // Victory celebration atmosphere
            VictoryCelebrationAtmosphere(arena: arena)
                .transition(.opacity.combined(with: .scale))
                
        case .endGame:
            // Intensified atmosphere for climactic moments
            IntensifiedGameAtmosphere(arena: arena)
                .opacity(0.3)
                
        default:
            EmptyView()
        }
    }
    
    // MARK: - Animation Control
    
    private func startAtmosphericAnimations() {
        // Start gentle background movement
        withAnimation(.linear(duration: 60).repeatForever(autoreverses: false)) {
            animationOffset = 100
        }
        
        // Start cloud movement
        withAnimation(.linear(duration: 45).repeatForever(autoreverses: false)) {
            cloudMovement = 200
        }
        
        // Start particle animation
        withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true)) {
            particleAnimation.toggle()
        }
        
        // Start ambient glow
        withAnimation(.easeInOut(duration: 5).repeatForever(autoreverses: true)) {
            ambientGlow.toggle()
        }
    }
}

// MARK: - Supporting Atmosphere Views

/// Traditional village atmosphere with wooden elements and folk culture
struct VillageAtmosphereView: View {
    let primaryColor: Color
    let accentColor: Color
    let intensity: Double
    
    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [
                    primaryColor.opacity(0.6 * intensity),
                    accentColor.opacity(0.4 * intensity),
                    Color.brown.opacity(0.2 * intensity)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // Wood texture overlay
            WoodTexturePattern()
                .opacity(0.1 * intensity)
        }
    }
}

/// Countryside atmosphere with green fields and natural elements
struct CountrysideAtmosphereView: View {
    let primaryColor: Color
    let forestDensity: Double
    let intensity: Double
    
    var body: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                Color.green.opacity(0.3 * intensity),
                primaryColor.opacity(0.5 * intensity),
                Color.green.opacity(0.2 * intensity * forestDensity)
            ]),
            startPoint: .top,
            endPoint: .bottom
        )
    }
}

/// Transylvanian fortress atmosphere with gothic elements
struct TransylvanianFortressAtmosphere: View {
    let primaryColor: Color
    let carpathianMountains: Bool
    let gothicArchitecture: Bool
    let intensity: Double
    
    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.gray.opacity(0.4 * intensity),
                    primaryColor.opacity(0.6 * intensity),
                    Color.black.opacity(0.3 * intensity)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            if carpathianMountains {
                MountainSilhouettePattern()
                    .opacity(0.2 * intensity)
            }
            
            if gothicArchitecture {
                GothicArchPattern()
                    .opacity(0.15 * intensity)
            }
        }
    }
}

/// Academic city atmosphere with intellectual and cultural elements
struct AcademicCityAtmosphere: View {
    let primaryColor: Color
    let culturalElements: CulturalElement
    let intensity: Double
    
    enum CulturalElement {
        case university, library, museum
    }
    
    var body: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                primaryColor.opacity(0.5 * intensity),
                Color.blue.opacity(0.3 * intensity),
                Color.purple.opacity(0.2 * intensity)
            ]),
            startPoint: .topTrailing,
            endPoint: .bottomLeading
        )
    }
}

/// Black Sea coastal atmosphere with maritime elements
struct BlackSeaCoastalAtmosphere: View {
    let primaryColor: Color
    let seaWaves: Bool
    let portActivity: Bool
    let intensity: Double
    
    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.cyan.opacity(0.4 * intensity),
                    primaryColor.opacity(0.5 * intensity),
                    Color.blue.opacity(0.3 * intensity)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            if seaWaves {
                WavePattern()
                    .opacity(0.2 * intensity)
            }
        }
    }
}

/// Cultural center atmosphere with historical significance
struct CulturalCenterAtmosphere: View {
    let primaryColor: Color
    let historicalMonuments: Bool
    let intellectualAura: Bool
    let intensity: Double
    
    var body: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                Color.red.opacity(0.4 * intensity),
                primaryColor.opacity(0.6 * intensity),
                Color.gold.opacity(0.2 * intensity)
            ]),
            startPoint: .top,
            endPoint: .bottom
        )
    }
}

/// Habsburg city atmosphere with baroque elements
struct HabsburgCityAtmosphere: View {
    let primaryColor: Color
    let baroqueArchitecture: Bool
    let europeanFlair: Bool
    let intensity: Double
    
    var body: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                Color.gold.opacity(0.3 * intensity),
                primaryColor.opacity(0.5 * intensity),
                Color.orange.opacity(0.2 * intensity)
            ]),
            startPoint: .topTrailing,
            endPoint: .bottomLeading
        )
    }
}

/// European cultural capital atmosphere with prestigious elements
struct EuropeanCulturalCapitalAtmosphere: View {
    let primaryColor: Color
    let saxonArchitecture: Bool
    let culturalPrestige: Bool
    let intensity: Double
    
    var body: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                Color.purple.opacity(0.4 * intensity),
                primaryColor.opacity(0.6 * intensity),
                Color.indigo.opacity(0.3 * intensity)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

/// Royal capital atmosphere with majestic elements
struct RoyalCapitalAtmosphere: View {
    let primaryColor: Color
    let parliamentPalace: Bool
    let grandBoulevards: Bool
    let royalMajesty: Bool
    let intensity: Double
    
    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.gold.opacity(0.5 * intensity),
                    primaryColor.opacity(0.7 * intensity),
                    Color.red.opacity(0.4 * intensity)
                ]),
                startPoint: .center,
                endPoint: .bottom
            )
            
            if royalMajesty {
                RoyalPatternOverlay()
                    .opacity(0.1 * intensity)
            }
        }
    }
}

/// Generic town atmosphere for other arenas
struct GenericTownAtmosphere: View {
    let primaryColor: Color
    let accentColor: Color
    let intensity: Double
    
    var body: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                primaryColor.opacity(0.4 * intensity),
                accentColor.opacity(0.3 * intensity),
                primaryColor.opacity(0.2 * intensity)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// MARK: - Placeholder Icon Views
// These would be replaced with actual SVG or detailed SwiftUI drawings

struct WoodenHouseIcon: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(Color.brown.opacity(0.3))
            .frame(width: 60, height: 40)
    }
}

struct FolkFenceIcon: View {
    var body: some View {
        Rectangle()
            .fill(Color.brown.opacity(0.2))
            .frame(width: 80, height: 20)
    }
}

struct TraditionalWellIcon: View {
    var body: some View {
        Circle()
            .fill(Color.gray.opacity(0.3))
            .frame(width: 30, height: 30)
    }
}

struct GothicTowerIcon: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 4)
            .fill(Color.gray.opacity(0.4))
            .frame(width: 40, height: 80)
    }
}

struct MedievalArchIcon: View {
    var body: some View {
        Capsule()
            .fill(Color.stone.opacity(0.3))
            .frame(width: 60, height: 40)
    }
}

struct CarpathianMountainSilhouette: View {
    var body: some View {
        Triangle()
            .fill(Color.gray.opacity(0.2))
            .frame(width: 100, height: 60)
    }
}

struct ParliamentPalaceIcon: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(Color.gold.opacity(0.3))
            .frame(width: 80, height: 60)
    }
}

struct RoyalCrownIcon: View {
    var body: some View {
        Circle()
            .fill(Color.gold.opacity(0.4))
            .frame(width: 40, height: 40)
    }
}

struct TriumphalArchIcon: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 6)
            .fill(Color.stone.opacity(0.3))
            .frame(width: 50, height: 70)
    }
}

struct TraditionalRooftopIcon: View {
    var body: some View {
        Triangle()
            .fill(Color.red.opacity(0.3))
            .frame(width: 50, height: 30)
    }
}

struct CobblestonePatternIcon: View {
    var body: some View {
        Circle()
            .fill(Color.gray.opacity(0.2))
            .frame(width: 20, height: 20)
    }
}

struct FolkArtIcon: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 4)
            .fill(Color.blue.opacity(0.3))
            .frame(width: 30, height: 30)
    }
}

// MARK: - Atmospheric Effect Views

struct SeaWavesAnimation: View {
    var body: some View {
        WaveShape()
            .fill(Color.blue.opacity(0.3))
    }
}

struct CarpathianMountainRange: View {
    var body: some View {
        HStack(spacing: 10) {
            Triangle().fill(Color.gray.opacity(0.2)).frame(width: 80, height: 60)
            Triangle().fill(Color.gray.opacity(0.3)).frame(width: 100, height: 80)
            Triangle().fill(Color.gray.opacity(0.2)).frame(width: 70, height: 50)
        }
    }
}

struct CloudLayer: View {
    var body: some View {
        HStack(spacing: 20) {
            CloudShape().fill(Color.white.opacity(0.1)).frame(width: 60, height: 30)
            CloudShape().fill(Color.white.opacity(0.15)).frame(width: 80, height: 40)
            CloudShape().fill(Color.white.opacity(0.1)).frame(width: 70, height: 35)
        }
    }
}

struct GroundMistEffect: View {
    var body: some View {
        LinearGradient(
            gradient: Gradient(colors: [Color.clear, Color.white.opacity(0.1)]),
            startPoint: .top,
            endPoint: .bottom
        )
        .frame(height: 50)
    }
}

// MARK: - Particle Effects

struct PollenParticleEffect: View {
    var body: some View {
        // Animated floating particles
        EmptyView()
    }
}

struct SeaSprayParticleEffect: View {
    var body: some View {
        // Sea spray animation
        EmptyView()
    }
}

struct GoldenLightParticleEffect: View {
    var body: some View {
        // Golden light particles
        EmptyView()
    }
}

struct AtmosphericDustEffect: View {
    var body: some View {
        // Generic atmospheric particles
        EmptyView()
    }
}

// MARK: - Weather Effects

struct MountainMistEffect: View {
    var body: some View {
        LinearGradient(
            gradient: Gradient(colors: [Color.clear, Color.gray.opacity(0.1), Color.clear]),
            startPoint: .leading,
            endPoint: .trailing
        )
    }
}

struct SeaBreezeEffect: View {
    var body: some View {
        // Sea breeze animation
        EmptyView()
    }
}

struct CountrysideBreezeEffect: View {
    var body: some View {
        // Gentle countryside breeze
        EmptyView()
    }
}

struct GenericAtmosphereEffect: View {
    var body: some View {
        // Generic atmospheric movement
        EmptyView()
    }
}

// MARK: - Pattern Overlays

struct WoodTexturePattern: View {
    var body: some View {
        Rectangle()
            .fill(Color.brown.opacity(0.1))
    }
}

struct MountainSilhouettePattern: View {
    var body: some View {
        // Mountain silhouette pattern
        EmptyView()
    }
}

struct GothicArchPattern: View {
    var body: some View {
        // Gothic architecture pattern
        EmptyView()
    }
}

struct WavePattern: View {
    var body: some View {
        // Wave pattern overlay
        EmptyView()
    }
}

struct RoyalPatternOverlay: View {
    var body: some View {
        // Royal pattern overlay
        EmptyView()
    }
}

struct RomanianFolkPatternOverlay: View {
    let arena: RomanianArena
    
    var body: some View {
        // Romanian folk pattern specific to arena
        Circle()
            .stroke(Color(hex: arena.accentColor), lineWidth: 2)
            .opacity(0.3)
    }
}

// MARK: - Victory and Celebration Effects

struct VictoryCelebrationAtmosphere: View {
    let arena: RomanianArena
    
    var body: some View {
        ZStack {
            // Victory glow
            RadialGradient(
                gradient: Gradient(colors: [
                    Color.gold.opacity(0.3),
                    Color(hex: arena.primaryColor).opacity(0.2),
                    Color.clear
                ]),
                center: .center,
                startRadius: 50,
                endRadius: 300
            )
            
            // Celebration particles
            // Implementation would include animated victory effects
        }
    }
}

struct IntensifiedGameAtmosphere: View {
    let arena: RomanianArena
    
    var body: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                Color(hex: arena.primaryColor).opacity(0.2),
                Color(hex: arena.accentColor).opacity(0.15),
                Color.clear
            ]),
            startPoint: .center,
            endPoint: .bottom
        )
    }
}

// MARK: - Supporting Shapes

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

struct WaveShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: rect.midY))
        
        for x in stride(from: 0, through: rect.width, by: 1) {
            let y = rect.midY + sin(x * 0.02) * 10
            path.addLine(to: CGPoint(x: x, y: y))
        }
        
        return path
    }
}

struct CloudShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        // Simple cloud shape
        path.addEllipse(in: CGRect(x: 0, y: rect.height * 0.3, width: rect.width * 0.6, height: rect.height * 0.4))
        path.addEllipse(in: CGRect(x: rect.width * 0.3, y: 0, width: rect.width * 0.7, height: rect.height * 0.6))
        path.addEllipse(in: CGRect(x: rect.width * 0.5, y: rect.height * 0.2, width: rect.width * 0.5, height: rect.height * 0.5))
        return path
    }
}

// MARK: - Color Extensions

extension Color {
    static let stone = Color.gray
    static let gold = Color.yellow
}

// MARK: - Convenience Background Component

/// Main component to be used in GameBoardView - provides current arena background
struct GameTableBackground: View {
    @EnvironmentObject private var gameViewModel: GameViewModel
    @State private var currentGamePhase: RomanianArenaBackgroundView.GamePhase = .opening
    
    var currentArena: RomanianArena {
        // Get current arena from game state or default to starting arena
        gameViewModel.currentArena ?? .sateImarica
    }
    
    var body: some View {
        RomanianArenaBackgroundView(
            arena: currentArena,
            gamePhase: currentGamePhase
        )
        .onReceive(gameViewModel.$gamePhase) { phase in
            updateGamePhase(phase)
        }
    }
    
    private func updateGamePhase(_ phase: GameViewModel.GamePhase) {
        switch phase {
        case .setup, .playing:
            currentGamePhase = .midGame
        case .gameOver:
            currentGamePhase = .endGame
        }
    }
}

// MARK: - Preview Support

#if DEBUG
struct RomanianArenaBackgroundView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            RomanianArenaBackgroundView(
                arena: .sateImarica,
                gamePhase: .opening
            )
            .previewDisplayName("Village")
            
            RomanianArenaBackgroundView(
                arena: .orasulBrasov,
                gamePhase: .midGame
            )
            .previewDisplayName("Brasov Fortress")
            
            RomanianArenaBackgroundView(
                arena: .marealeBucuresti,
                gamePhase: .victory
            )
            .previewDisplayName("Bucharest Victory")
        }
        .previewDevice("iPhone 14 Pro")
        .preferredColorScheme(.dark)
    }
}
#endif