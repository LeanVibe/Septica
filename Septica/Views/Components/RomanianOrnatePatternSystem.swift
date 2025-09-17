//
//  RomanianOrnatePatternSystem.swift
//  Septica
//
//  Enhanced Romanian folk art pattern system for ornate game table design
//  Inspired by traditional Romanian decorative arts and Shuffle Cats visual richness
//

import SwiftUI

/// Comprehensive Romanian ornate pattern system for rich visual design
struct RomanianOrnatePatternSystem {
    
    // MARK: - Traditional Romanian Motifs
    
    /// Traditional Romanian cross pattern (Cruce Românească)
    struct RomanianCrossPattern: View {
        let size: CGFloat
        let color: Color
        
        var body: some View {
            ZStack {
                // Vertical arm
                Rectangle()
                    .fill(color)
                    .frame(width: size * 0.15, height: size)
                
                // Horizontal arm
                Rectangle()
                    .fill(color)
                    .frame(width: size * 0.8, height: size * 0.15)
                
                // Traditional Romanian cross decorative ends
                HStack(spacing: size * 0.65) {
                    ForEach(0..<2, id: \.self) { _ in
                        RoundedRectangle(cornerRadius: size * 0.03)
                            .fill(color)
                            .frame(width: size * 0.08, height: size * 0.25)
                    }
                }
            }
        }
    }
    
    /// Traditional Romanian geometric flower pattern (Floare Geometrică)
    struct RomanianFlowerPattern: View {
        let size: CGFloat
        let color: Color
        
        var body: some View {
            ZStack {
                // Center circle
                Circle()
                    .fill(color)
                    .frame(width: size * 0.3, height: size * 0.3)
                
                // Petals arranged in traditional Romanian style
                ForEach(0..<8, id: \.self) { index in
                    Ellipse()
                        .fill(color.opacity(0.8))
                        .frame(width: size * 0.2, height: size * 0.4)
                        .offset(y: -size * 0.25)
                        .rotationEffect(.degrees(Double(index) * 45))
                }
                
                // Traditional Romanian center dot
                Circle()
                    .fill(RomanianColors.goldAccent)
                    .frame(width: size * 0.1, height: size * 0.1)
            }
        }
    }
    
    /// Traditional Romanian diamond pattern (Romb Tradițional)
    struct RomanianDiamondPattern: View {
        let size: CGFloat
        let color: Color
        
        var body: some View {
            ZStack {
                // Main diamond
                Diamond()
                    .stroke(color, lineWidth: size * 0.02)
                    .frame(width: size, height: size * 0.7)
                
                // Inner diamond
                Diamond()
                    .stroke(color.opacity(0.7), lineWidth: size * 0.015)
                    .frame(width: size * 0.6, height: size * 0.42)
                
                // Traditional center pattern
                RomanianCrossPattern(size: size * 0.3, color: color.opacity(0.5))
            }
        }
    }
    
    /// Traditional Romanian border pattern (Bordură Românească)
    struct RomanianBorderPattern: View {
        let width: CGFloat
        let height: CGFloat
        let color: Color
        
        var body: some View {
            HStack(spacing: width * 0.05) {
                ForEach(0..<Int(width / (height * 0.8)), id: \.self) { index in
                    if index % 3 == 0 {
                        RomanianFlowerPattern(size: height * 0.6, color: color)
                    } else if index % 3 == 1 {
                        RomanianDiamondPattern(size: height * 0.6, color: color)
                    } else {
                        RomanianCrossPattern(size: height * 0.6, color: color)
                    }
                }
            }
        }
    }
    
    // MARK: - Complex Ornate Patterns
    
    /// Elaborate Romanian table center pattern
    struct OrnateCenterPattern: View {
        let size: CGFloat
        
        var body: some View {
            ZStack {
                // Outer decorative ring
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [
                                RomanianColors.goldAccent,
                                RomanianColors.primaryYellow,
                                RomanianColors.goldAccent
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: size * 0.03
                    )
                    .frame(width: size, height: size)
                
                // Middle ornate ring with traditional motifs
                ForEach(0..<12, id: \.self) { index in
                    Group {
                        if index % 4 == 0 {
                            RomanianFlowerPattern(
                                size: size * 0.15,
                                color: RomanianColors.primaryRed
                            )
                        } else if index % 4 == 1 {
                            RomanianDiamondPattern(
                                size: size * 0.12,
                                color: RomanianColors.primaryBlue
                            )
                        } else if index % 4 == 2 {
                            RomanianCrossPattern(
                                size: size * 0.1,
                                color: RomanianColors.goldAccent
                            )
                        } else {
                            Circle()
                                .fill(RomanianColors.primaryYellow)
                                .frame(width: size * 0.06, height: size * 0.06)
                        }
                    }
                    .offset(y: -size * 0.35)
                    .rotationEffect(.degrees(Double(index) * 30))
                }
                
                // Inner traditional Romanian coat of arms inspired center
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    RomanianColors.primaryBlue,
                                    RomanianColors.primaryBlue.opacity(0.8)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: size * 0.4, height: size * 0.4)
                    
                    // Traditional Romanian heraldic pattern
                    VStack(spacing: size * 0.02) {
                        RomanianCrossPattern(
                            size: size * 0.12,
                            color: RomanianColors.goldAccent
                        )
                        
                        HStack(spacing: size * 0.01) {
                            ForEach(0..<3, id: \.self) { _ in
                                Circle()
                                    .fill(RomanianColors.primaryYellow)
                                    .frame(width: size * 0.025, height: size * 0.025)
                            }
                        }
                    }
                }
            }
        }
    }
    
    /// Traditional Romanian corner ornament
    struct OrnateCornerPattern: View {
        let size: CGFloat
        
        var body: some View {
            ZStack {
                // Corner curves with traditional styling
                Path { path in
                    path.move(to: CGPoint(x: 0, y: size))
                    path.addQuadCurve(
                        to: CGPoint(x: size, y: 0),
                        control: CGPoint(x: size * 0.3, y: size * 0.3)
                    )
                }
                .stroke(
                    LinearGradient(
                        colors: [
                            RomanianColors.goldAccent,
                            RomanianColors.primaryYellow.opacity(0.8)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: size * 0.04
                )
                
                // Traditional motifs along the corner
                ForEach(0..<3, id: \.self) { index in
                    let position = CGFloat(index + 1) * 0.25
                    RomanianFlowerPattern(
                        size: size * 0.15,
                        color: RomanianColors.primaryRed.opacity(0.8)
                    )
                    .offset(
                        x: size * position * 0.7,
                        y: size * (1 - position) * 0.7
                    )
                }
            }
        }
    }
}

// MARK: - Supporting Shapes

/// Traditional Romanian diamond shape
struct Diamond: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let top = CGPoint(x: center.x, y: rect.minY)
        let right = CGPoint(x: rect.maxX, y: center.y)
        let bottom = CGPoint(x: center.x, y: rect.maxY)
        let left = CGPoint(x: rect.minX, y: center.y)
        
        path.move(to: top)
        path.addLine(to: right)
        path.addLine(to: bottom)
        path.addLine(to: left)
        path.closeSubpath()
        
        return path
    }
}

// MARK: - Table-Specific Ornate Components

/// Enhanced ornate table surface with Romanian folk patterns
struct OrnateRomanianTableSurface: View {
    let size: CGSize
    
    var body: some View {
        ZStack {
            // Base table surface with gradient
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    RadialGradient(
                        colors: [
                            RomanianColors.tableGreen.opacity(0.9),
                            RomanianColors.tableGreen,
                            Color(red: 0.05, green: 0.2, blue: 0.05)
                        ],
                        center: .center,
                        startRadius: 30,
                        endRadius: max(size.width, size.height) * 0.6
                    )
                )
            
            // Ornate border pattern
            RoundedRectangle(cornerRadius: 20)
                .stroke(
                    LinearGradient(
                        colors: [
                            RomanianColors.goldAccent,
                            RomanianColors.primaryYellow,
                            RomanianColors.goldAccent
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 4
                )
            
            // Inner decorative border
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    LinearGradient(
                        colors: [
                            RomanianColors.primaryBlue.opacity(0.6),
                            RomanianColors.folkBlue.opacity(0.4)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 2
                )
                .padding(8)
            
            // Corner ornaments
            VStack {
                HStack {
                    RomanianOrnatePatternSystem.OrnateCornerPattern(size: 40)
                        .rotationEffect(.degrees(0))
                    
                    Spacer()
                    
                    RomanianOrnatePatternSystem.OrnateCornerPattern(size: 40)
                        .rotationEffect(.degrees(90))
                }
                
                Spacer()
                
                HStack {
                    RomanianOrnatePatternSystem.OrnateCornerPattern(size: 40)
                        .rotationEffect(.degrees(270))
                    
                    Spacer()
                    
                    RomanianOrnatePatternSystem.OrnateCornerPattern(size: 40)
                        .rotationEffect(.degrees(180))
                }
            }
            .padding(16)
            
            // Central ornate pattern
            RomanianOrnatePatternSystem.OrnateCenterPattern(size: min(size.width, size.height) * 0.3)
                .opacity(0.4)
        }
        .frame(width: size.width, height: size.height)
        .shadow(
            color: RomanianColors.primaryBlue.opacity(0.3),
            radius: 12,
            x: 0,
            y: 6
        )
    }
}

// MARK: - Preview Support

#if DEBUG
struct RomanianOrnatePatternSystem_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            VStack(spacing: 30) {
                // Individual patterns
                HStack(spacing: 20) {
                    RomanianOrnatePatternSystem.RomanianCrossPattern(
                        size: 60,
                        color: RomanianColors.primaryRed
                    )
                    
                    RomanianOrnatePatternSystem.RomanianFlowerPattern(
                        size: 60,
                        color: RomanianColors.primaryBlue
                    )
                    
                    RomanianOrnatePatternSystem.RomanianDiamondPattern(
                        size: 60,
                        color: RomanianColors.goldAccent
                    )
                }
                
                // Ornate center pattern
                RomanianOrnatePatternSystem.OrnateCenterPattern(size: 120)
                
                // Complete ornate table surface
                OrnateRomanianTableSurface(size: CGSize(width: 280, height: 180))
            }
            .padding()
        }
        .background(Color.black)
        .previewDevice("iPhone 14 Pro")
    }
}
#endif