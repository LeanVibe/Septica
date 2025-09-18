//
//  RomanianCulturalPatternView.swift
//  Septica
//
//  Romanian cultural pattern overlay for authentic card design
//  Provides traditional folk art patterns and embroidery effects
//

import SwiftUI

// MARK: - Romanian Cultural Pattern View

/// View that renders traditional Romanian folk art patterns
struct RomanianCulturalPatternView: View {
    let intensity: Float
    let embroideryEffect: Float
    
    @State private var animationOffset: CGFloat = 0
    @State private var patternRotation: Double = 0
    
    var body: some View {
        ZStack {
            // Base traditional pattern
            traditionalBorderPattern
            
            // Floral motifs
            floralMotifPattern
                .opacity(Double(intensity) * 0.6)
            
            // Embroidery effect overlay
            if embroideryEffect > 0 {
                embroideryOverlay
                    .opacity(Double(embroideryEffect) * 0.8)
            }
            
            // Animated cultural accents
            animatedCulturalAccents
                .opacity(Double(intensity) * 0.4)
        }
        .onAppear {
            startPatternAnimation()
        }
    }
    
    // MARK: - Traditional Border Pattern
    
    @ViewBuilder
    private var traditionalBorderPattern: some View {
        GeometryReader { geometry in
            Path { path in
                let width = geometry.size.width
                let height = geometry.size.height
                let spacing: CGFloat = 8
                let patternSize: CGFloat = 6
                
                // Top border
                for i in stride(from: spacing, to: width - spacing, by: spacing * 2) {
                    drawDiamondMotif(path: &path, at: CGPoint(x: i, y: spacing), size: patternSize)
                }
                
                // Bottom border
                for i in stride(from: spacing, to: width - spacing, by: spacing * 2) {
                    drawDiamondMotif(path: &path, at: CGPoint(x: i, y: height - spacing), size: patternSize)
                }
                
                // Left border
                for i in stride(from: spacing * 3, to: height - spacing * 3, by: spacing * 2) {
                    drawDiamondMotif(path: &path, at: CGPoint(x: spacing, y: i), size: patternSize)
                }
                
                // Right border
                for i in stride(from: spacing * 3, to: height - spacing * 3, by: spacing * 2) {
                    drawDiamondMotif(path: &path, at: CGPoint(x: width - spacing, y: i), size: patternSize)
                }
            }
            .fill(
                LinearGradient(
                    colors: [
                        RomanianColors.embroideryRed.opacity(Double(intensity) * 0.3),
                        RomanianColors.goldAccent.opacity(Double(intensity) * 0.4),
                        RomanianColors.embroideryRed.opacity(Double(intensity) * 0.3)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        }
    }
    
    // MARK: - Floral Motif Pattern
    
    @ViewBuilder
    private var floralMotifPattern: some View {
        GeometryReader { geometry in
            ZStack {
                // Corner rosettes
                ForEach(0..<4, id: \.self) { corner in
                    RomanianRosette(size: 12, intensity: intensity)
                        .position(cornerPosition(for: corner, in: geometry.size))
                        .rotationEffect(.degrees(Double(corner) * 90))
                }
                
                // Center folk motif
                if geometry.size.width > 80 && geometry.size.height > 100 {
                    RomanianCenterMotif(intensity: intensity)
                        .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                        .scaleEffect(0.6)
                }
            }
        }
    }
    
    // MARK: - Embroidery Overlay
    
    @ViewBuilder
    private var embroideryOverlay: some View {
        GeometryReader { geometry in
            Canvas { context, size in
                // Draw embroidery-style stitches
                drawEmbroideryStitches(context: context, size: size, intensity: embroideryEffect)
            }
        }
    }
    
    // MARK: - Animated Cultural Accents
    
    @ViewBuilder
    private var animatedCulturalAccents: some View {
        GeometryReader { geometry in
            ZStack {
                // Subtle pulsing cultural elements
                ForEach(0..<6, id: \.self) { index in
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    RomanianColors.goldAccent.opacity(Double(intensity) * 0.2),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: 4
                            )
                        )
                        .frame(width: 8, height: 8)
                        .position(
                            x: geometry.size.width * 0.2 + CGFloat(index) * geometry.size.width * 0.12,
                            y: geometry.size.height * 0.1 + sin(animationOffset + Double(index)) * 3
                        )
                        .opacity(0.6 + sin(animationOffset + Double(index) * 0.5) * 0.4)
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func drawDiamondMotif(path: inout Path, at point: CGPoint, size: CGFloat) {
        let halfSize = size / 2
        
        path.move(to: CGPoint(x: point.x, y: point.y - halfSize))
        path.addLine(to: CGPoint(x: point.x + halfSize, y: point.y))
        path.addLine(to: CGPoint(x: point.x, y: point.y + halfSize))
        path.addLine(to: CGPoint(x: point.x - halfSize, y: point.y))
        path.closeSubpath()
    }
    
    private func cornerPosition(for corner: Int, in size: CGSize) -> CGPoint {
        let margin: CGFloat = 12
        
        switch corner {
        case 0: return CGPoint(x: margin, y: margin)
        case 1: return CGPoint(x: size.width - margin, y: margin)
        case 2: return CGPoint(x: size.width - margin, y: size.height - margin)
        case 3: return CGPoint(x: margin, y: size.height - margin)
        default: return CGPoint(x: size.width / 2, y: size.height / 2)
        }
    }
    
    private func drawEmbroideryStitches(context: GraphicsContext, size: CGSize, intensity: Float) {
        let stitchLength: CGFloat = 3
        let stitchSpacing: CGFloat = 6
        let stitchWidth: CGFloat = 0.5
        
        context.stroke(
            Path { path in
                // Horizontal stitches
                for y in stride(from: stitchSpacing, to: size.height - stitchSpacing, by: stitchSpacing * 2) {
                    for x in stride(from: stitchSpacing, to: size.width - stitchSpacing, by: stitchSpacing * 3) {
                        path.move(to: CGPoint(x: x, y: y))
                        path.addLine(to: CGPoint(x: x + stitchLength, y: y))
                    }
                }
                
                // Vertical stitches
                for x in stride(from: stitchSpacing * 1.5, to: size.width - stitchSpacing, by: stitchSpacing * 3) {
                    for y in stride(from: stitchSpacing * 1.5, to: size.height - stitchSpacing, by: stitchSpacing * 2) {
                        path.move(to: CGPoint(x: x, y: y))
                        path.addLine(to: CGPoint(x: x, y: y + stitchLength))
                    }
                }
            },
            with: .color(RomanianColors.embroideryRed.opacity(Double(intensity) * 0.6)),
            lineWidth: stitchWidth
        )
    }
    
    private func startPatternAnimation() {
        withAnimation(.linear(duration: 8.0).repeatForever(autoreverses: false)) {
            animationOffset = 2 * .pi
        }
        
        withAnimation(.linear(duration: 12.0).repeatForever(autoreverses: true)) {
            patternRotation = 5.0
        }
    }
}

// MARK: - Romanian Rosette Component

struct RomanianRosette: View {
    let size: CGFloat
    let intensity: Float
    
    @State private var rotationAngle: Double = 0
    
    var body: some View {
        ZStack {
            // Outer petals
            ForEach(0..<8, id: \.self) { petal in
                Ellipse()
                    .fill(
                        LinearGradient(
                            colors: [
                                RomanianColors.goldAccent.opacity(Double(intensity) * 0.4),
                                RomanianColors.embroideryRed.opacity(Double(intensity) * 0.3)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: size * 0.3, height: size * 0.8)
                    .offset(y: -size * 0.3)
                    .rotationEffect(.degrees(Double(petal) * 45))
            }
            
            // Center circle
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            RomanianColors.goldAccent.opacity(Double(intensity) * 0.6),
                            RomanianColors.embroideryRed.opacity(Double(intensity) * 0.4)
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: size * 0.2
                    )
                )
                .frame(width: size * 0.4, height: size * 0.4)
        }
        .frame(width: size, height: size)
        .rotationEffect(.degrees(rotationAngle))
        .onAppear {
            withAnimation(.linear(duration: 10.0).repeatForever(autoreverses: false)) {
                rotationAngle = 360
            }
        }
    }
}

// MARK: - Romanian Center Motif

struct RomanianCenterMotif: View {
    let intensity: Float
    
    @State private var pulseScale: CGFloat = 1.0
    
    var body: some View {
        ZStack {
            // Traditional cross pattern
            RoundedRectangle(cornerRadius: 2)
                .fill(RomanianColors.embroideryRed.opacity(Double(intensity) * 0.4))
                .frame(width: 20, height: 4)
            
            RoundedRectangle(cornerRadius: 2)
                .fill(RomanianColors.embroideryRed.opacity(Double(intensity) * 0.4))
                .frame(width: 4, height: 20)
            
            // Diagonal accents
            ForEach(0..<4, id: \.self) { index in
                RoundedRectangle(cornerRadius: 1)
                    .fill(RomanianColors.goldAccent.opacity(Double(intensity) * 0.3))
                    .frame(width: 8, height: 2)
                    .offset(x: 6, y: 0)
                    .rotationEffect(.degrees(Double(index) * 90 + 45))
            }
            
            // Center dot
            Circle()
                .fill(RomanianColors.goldAccent.opacity(Double(intensity) * 0.8))
                .frame(width: 6, height: 6)
        }
        .scaleEffect(pulseScale)
        .onAppear {
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                pulseScale = 1.1
            }
        }
    }
}

// MARK: - Romanian Colors Extension

extension Color {
    static let romanianTraditionalRed = Color(red: 0.8, green: 0.15, blue: 0.15)
    static let romanianTraditionalBlue = Color(red: 0.1, green: 0.3, blue: 0.7)
    static let romanianTraditionalYellow = Color(red: 0.95, green: 0.8, blue: 0.2)
}

// MARK: - Preview

struct RomanianCulturalPatternView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            RomanianCulturalPatternView(intensity: 1.0, embroideryEffect: 0.8)
                .frame(width: 120, height: 160)
                .background(Color.white)
                .cornerRadius(8)
                .shadow(radius: 4)
            
            RomanianCulturalPatternView(intensity: 0.5, embroideryEffect: 0.3)
                .frame(width: 120, height: 160)
                .background(Color.white)
                .cornerRadius(8)
                .shadow(radius: 4)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
    }
}