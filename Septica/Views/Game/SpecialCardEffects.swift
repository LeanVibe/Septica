//
//  SpecialCardEffects.swift
//  Septica
//
//  Special visual effects for different card types and actions
//  Provides ShuffleCats-quality animations with Romanian cultural authenticity
//

import SwiftUI

// MARK: - Seven Card Magical Effect

/// Special magical effect for seven cards (wild cards in Romanian Septica)
struct SevenCardMagicalEffect: View {
    let intensity: Float
    
    @State private var rotationAngle: Double = 0
    @State private var pulseScale: CGFloat = 1.0
    @State private var sparkleOffsets: [CGPoint] = []
    @State private var sparkleOpacities: [Double] = []
    
    var body: some View {
        ZStack {
            // Magical aura
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.purple.opacity(Double(intensity) * 0.3),
                            Color.blue.opacity(Double(intensity) * 0.2),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 10,
                        endRadius: 80
                    )
                )
                .scaleEffect(pulseScale)
                .rotationEffect(.degrees(rotationAngle))
            
            // Magical sparkles
            ForEach(0..<8, id: \.self) { index in
                if index < sparkleOffsets.count {
                    Image(systemName: "sparkle")
                        .foregroundColor(Color.yellow.opacity(sparkleOpacities[index]))
                        .font(.system(size: 12, weight: .bold))
                        .offset(sparkleOffsets[index])
                        .scaleEffect(0.5 + Double(intensity) * 0.5)
                }
            }
            
            // Center glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.white.opacity(Double(intensity) * 0.8),
                            Color.yellow.opacity(Double(intensity) * 0.6),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 15
                    )
                )
                .frame(width: 30, height: 30)
                .scaleEffect(pulseScale * 0.8)
        }
        .onAppear {
            startMagicalAnimation()
        }
    }
    
    private func startMagicalAnimation() {
        // Initialize sparkle positions
        sparkleOffsets = (0..<8).map { index in
            let angle = Double(index) * 45 * .pi / 180
            let radius: CGFloat = 30
            return CGPoint(
                x: cos(angle) * radius,
                y: sin(angle) * radius
            )
        }
        
        sparkleOpacities = Array(repeating: 0.0, count: 8)
        
        // Start rotation animation
        withAnimation(.linear(duration: 4.0).repeatForever(autoreverses: false)) {
            rotationAngle = 360
        }
        
        // Start pulse animation
        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
            pulseScale = 1.3
        }
        
        // Animate sparkles
        animateSparkles()
    }
    
    private func animateSparkles() {
        for index in 0..<8 {
            let delay = Double(index) * 0.2
            
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                    sparkleOpacities[index] = Double(intensity)
                }
                
                withAnimation(.linear(duration: 3.0).repeatForever(autoreverses: false)) {
                    let angle = Double(index) * 45 * .pi / 180 + .pi
                    let radius: CGFloat = 50
                    sparkleOffsets[index] = CGPoint(
                        x: cos(angle) * radius,
                        y: sin(angle) * radius
                    )
                }
            }
        }
    }
}

// MARK: - Point Card Shimmer Effect

/// Shimmer effect for point cards (10, J, Q, K)
struct PointCardShimmerEffect: View {
    let intensity: Float
    
    @State private var shimmerOffset: CGFloat = -100
    @State private var goldGlow: Double = 0.0
    
    var body: some View {
        ZStack {
            // Gold shimmer sweep
            LinearGradient(
                colors: [
                    Color.clear,
                    RomanianColors.goldAccent.opacity(Double(intensity) * 0.6),
                    Color.white.opacity(Double(intensity) * 0.8),
                    RomanianColors.goldAccent.opacity(Double(intensity) * 0.6),
                    Color.clear
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
            .mask(
                Rectangle()
                    .frame(width: 20)
                    .offset(x: shimmerOffset)
            )
            
            // Gold particle effects
            ForEach(0..<12, id: \.self) { index in
                Circle()
                    .fill(
                        RomanianColors.goldAccent.opacity(goldGlow * Double(intensity))
                    )
                    .frame(width: 3, height: 3)
                    .offset(
                        x: CGFloat.random(in: -50...50),
                        y: CGFloat.random(in: -70...70)
                    )
                    .opacity(goldGlow)
            }
            
            // Border highlight
            RoundedRectangle(cornerRadius: 8)
                .stroke(
                    LinearGradient(
                        colors: [
                            RomanianColors.goldAccent.opacity(Double(intensity) * goldGlow),
                            Color.yellow.opacity(Double(intensity) * goldGlow * 0.8)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2
                )
        }
        .onAppear {
            startShimmerAnimation()
        }
    }
    
    private func startShimmerAnimation() {
        // Shimmer sweep animation
        withAnimation(.linear(duration: 2.0).repeatForever(autoreverses: false)) {
            shimmerOffset = 150
        }
        
        // Gold glow pulse
        withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
            goldGlow = 1.0
        }
    }
}

// MARK: - Romanian Flourish Effect

/// Traditional Romanian flourish effect for cultural moments
struct RomanianFlourishEffect: View {
    let intensity: Float
    
    @State private var flourishScale: CGFloat = 0.0
    @State private var flourishRotation: Double = 0
    @State private var flourishOpacity: Double = 0.0
    
    var body: some View {
        ZStack {
            // Traditional Romanian cross flourish
            ForEach(0..<4, id: \.self) { index in
                Path { path in
                    // Create traditional Romanian decorative element
                    path.move(to: CGPoint(x: 0, y: -20))
                    path.addCurve(
                        to: CGPoint(x: 15, y: 0),
                        control1: CGPoint(x: 5, y: -15),
                        control2: CGPoint(x: 12, y: -5)
                    )
                    path.addCurve(
                        to: CGPoint(x: 0, y: 20),
                        control1: CGPoint(x: 12, y: 5),
                        control2: CGPoint(x: 5, y: 15)
                    )
                    path.addCurve(
                        to: CGPoint(x: -15, y: 0),
                        control1: CGPoint(x: -5, y: 15),
                        control2: CGPoint(x: -12, y: 5)
                    )
                    path.addCurve(
                        to: CGPoint(x: 0, y: -20),
                        control1: CGPoint(x: -12, y: -5),
                        control2: CGPoint(x: -5, y: -15)
                    )
                }
                .fill(
                    LinearGradient(
                        colors: [
                            RomanianColors.embroideryRed.opacity(Double(intensity) * 0.6),
                            RomanianColors.goldAccent.opacity(Double(intensity) * 0.8),
                            RomanianColors.primaryBlue.opacity(Double(intensity) * 0.6)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .rotationEffect(.degrees(Double(index) * 90 + flourishRotation))
                .scaleEffect(flourishScale)
                .opacity(flourishOpacity)
            }
            
            // Center traditional motif
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            RomanianColors.goldAccent.opacity(Double(intensity) * 0.8),
                            RomanianColors.embroideryRed.opacity(Double(intensity) * 0.6),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 8
                    )
                )
                .frame(width: 16, height: 16)
                .scaleEffect(flourishScale)
                .opacity(flourishOpacity)
                
            // Traditional Romanian border elements
            ForEach(0..<8, id: \.self) { index in
                RomanianBorderElement()
                    .offset(
                        x: cos(Double(index) * .pi / 4) * 35,
                        y: sin(Double(index) * .pi / 4) * 35
                    )
                    .rotationEffect(.degrees(Double(index) * 45))
                    .scaleEffect(flourishScale * 0.7)
                    .opacity(flourishOpacity * 0.8)
            }
        }
        .onAppear {
            startFlourishAnimation()
        }
    }
    
    private func startFlourishAnimation() {
        // Scale in animation
        withAnimation(.easeOut(duration: 0.8)) {
            flourishScale = 1.0
            flourishOpacity = 1.0
        }
        
        // Gentle rotation
        withAnimation(.linear(duration: 8.0).repeatForever(autoreverses: false)) {
            flourishRotation = 360
        }
        
        // Fade out after display
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation(.easeIn(duration: 1.0)) {
                flourishScale = 0.0
                flourishOpacity = 0.0
            }
        }
    }
}

// MARK: - Golden Glow Effect

/// Golden glow effect for special moments
struct GoldenGlowEffect: View {
    let intensity: Float
    
    @State private var glowRadius: CGFloat = 10
    @State private var glowOpacity: Double = 0.0
    @State private var particleAnimations: [Bool] = Array(repeating: false, count: 16)
    
    var body: some View {
        ZStack {
            // Main golden glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.white.opacity(Double(intensity) * 0.8),
                            RomanianColors.goldAccent.opacity(Double(intensity) * 0.6),
                            Color.yellow.opacity(Double(intensity) * 0.4),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: glowRadius
                    )
                )
                .frame(width: glowRadius * 2, height: glowRadius * 2)
                .opacity(glowOpacity)
            
            // Golden particles
            ForEach(0..<16, id: \.self) { index in
                Circle()
                    .fill(RomanianColors.goldAccent.opacity(Double(intensity) * 0.8))
                    .frame(width: 4, height: 4)
                    .offset(
                        x: particleAnimations[index] ? CGFloat.random(in: -60...60) : 0,
                        y: particleAnimations[index] ? CGFloat.random(in: -60...60) : 0
                    )
                    .opacity(particleAnimations[index] ? 0 : 1)
                    .animation(
                        .easeOut(duration: Double.random(in: 1.0...2.0))
                        .delay(Double(index) * 0.1),
                        value: particleAnimations[index]
                    )
            }
        }
        .onAppear {
            startGlowAnimation()
        }
    }
    
    private func startGlowAnimation() {
        // Main glow animation
        withAnimation(.easeOut(duration: 0.5)) {
            glowOpacity = 1.0
            glowRadius = 40
        }
        
        // Pulsing effect
        withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
            glowRadius = 50
        }
        
        // Animate particles
        for index in 0..<16 {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.1) {
                particleAnimations[index] = true
            }
        }
        
        // Fade out
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            withAnimation(.easeIn(duration: 1.0)) {
                glowOpacity = 0.0
            }
        }
    }
}

// MARK: - Romanian Border Element

/// Small decorative element for Romanian flourish
struct RomanianBorderElement: View {
    @State private var elementScale: CGFloat = 0.0
    
    var body: some View {
        Path { path in
            // Traditional Romanian decorative diamond
            path.move(to: CGPoint(x: 0, y: -4))
            path.addLine(to: CGPoint(x: 3, y: 0))
            path.addLine(to: CGPoint(x: 0, y: 4))
            path.addLine(to: CGPoint(x: -3, y: 0))
            path.closeSubpath()
            
            // Inner detail
            path.move(to: CGPoint(x: 0, y: -2))
            path.addLine(to: CGPoint(x: 1.5, y: 0))
            path.addLine(to: CGPoint(x: 0, y: 2))
            path.addLine(to: CGPoint(x: -1.5, y: 0))
            path.closeSubpath()
        }
        .fill(
            LinearGradient(
                colors: [
                    RomanianColors.goldAccent,
                    RomanianColors.embroideryRed,
                    RomanianColors.goldAccent
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .scaleEffect(elementScale)
        .onAppear {
            withAnimation(.easeOut(duration: 0.3).delay(Double.random(in: 0...0.5))) {
                elementScale = 1.0
            }
        }
    }
}

// MARK: - Preview

struct SpecialCardEffects_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 30) {
            HStack(spacing: 20) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.white)
                        .frame(width: 80, height: 110)
                    
                    SevenCardMagicalEffect(intensity: 1.0)
                }
                
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.white)
                        .frame(width: 80, height: 110)
                    
                    PointCardShimmerEffect(intensity: 1.0)
                }
            }
            
            HStack(spacing: 20) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.white)
                        .frame(width: 80, height: 110)
                    
                    RomanianFlourishEffect(intensity: 1.0)
                }
                
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.white)
                        .frame(width: 80, height: 110)
                    
                    GoldenGlowEffect(intensity: 1.0)
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.2))
    }
}