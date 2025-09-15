//
//  DropZoneView.swift
//  Septica
//
//  Shuffle Cats inspired drop zone visual feedback system
//  Provides clear visual indication of valid drop areas during card dragging
//

import SwiftUI

/// Visual drop zone component inspired by Shuffle Cats' clear drop feedback
struct DropZoneView: View {
    let isHighlighted: Bool
    let isValidDrop: Bool
    let zone: DropZoneType
    
    @State private var pulseAnimation = false
    @State private var glowIntensity: Double = 0.3
    
    var body: some View {
        RoundedRectangle(cornerRadius: 16)
            .stroke(
                borderColor,
                lineWidth: isHighlighted ? 3 : 1
            )
            .fill(backgroundColor)
            .overlay(
                // Romanian-themed drop zone content
                VStack(spacing: 8) {
                    // Drop zone icon
                    Image(systemName: zone.iconName)
                        .font(.system(size: 32, weight: .medium))
                        .foregroundColor(iconColor)
                        .scaleEffect(isHighlighted ? 1.2 : 1.0)
                    
                    // Drop zone text
                    Text(zone.displayText)
                        .font(.caption.weight(.medium))
                        .foregroundColor(textColor)
                        .multilineTextAlignment(.center)
                }
                .opacity(isHighlighted ? 1.0 : 0.6)
            )
            .scaleEffect(isHighlighted ? 1.05 : 1.0)
            .shadow(
                color: shadowColor,
                radius: isHighlighted ? 12 : 4,
                x: 0,
                y: isHighlighted ? 6 : 2
            )
            .animation(.spring(response: 0.4, dampingFraction: 0.6), value: isHighlighted)
            .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: pulseAnimation)
            .onAppear {
                if isHighlighted {
                    pulseAnimation = true
                }
            }
            .onChange(of: isHighlighted) { highlighted in
                pulseAnimation = highlighted
                
                // Update glow intensity based on highlight state
                withAnimation(.easeInOut(duration: 0.3)) {
                    glowIntensity = highlighted ? 0.8 : 0.3
                }
            }
    }
    
    // MARK: - Color Properties
    
    private var borderColor: Color {
        if !isHighlighted {
            return RomanianColors.primaryYellow.opacity(0.3)
        }
        
        return isValidDrop ? 
            RomanianColors.countrysideGreen :
            RomanianColors.primaryRed
    }
    
    private var backgroundColor: Color {
        if !isHighlighted {
            return Color.clear
        }
        
        let baseColor = isValidDrop ? 
            RomanianColors.countrysideGreen :
            RomanianColors.primaryRed
        
        return baseColor.opacity(0.15)
    }
    
    private var iconColor: Color {
        if !isHighlighted {
            return RomanianColors.primaryYellow.opacity(0.6)
        }
        
        return isValidDrop ? 
            RomanianColors.countrysideGreen :
            RomanianColors.primaryRed
    }
    
    private var textColor: Color {
        if !isHighlighted {
            return RomanianColors.primaryYellow.opacity(0.7)
        }
        
        return isValidDrop ? 
            RomanianColors.countrysideGreen :
            RomanianColors.primaryRed
    }
    
    private var shadowColor: Color {
        if !isHighlighted {
            return RomanianColors.primaryBlue.opacity(0.2)
        }
        
        let baseColor = isValidDrop ? 
            RomanianColors.countrysideGreen :
            RomanianColors.primaryRed
        
        return baseColor.opacity(glowIntensity)
    }
}

/// Drop zone types with Romanian cultural context
enum DropZoneType {
    case playArea
    case invalidArea
    case specialMove
    
    var iconName: String {
        switch self {
        case .playArea:
            return "suit.spade.fill"
        case .invalidArea:
            return "xmark.circle.fill"
        case .specialMove:
            return "star.circle.fill"
        }
    }
    
    var displayText: String {
        switch self {
        case .playArea:
            return "Joacă Cartea\n(Play Card)"
        case .invalidArea:
            return "Mișcare Invalidă\n(Invalid Move)"
        case .specialMove:
            return "Mișcare Specială\n(Special Move)"
        }
    }
}

// MARK: - Preview

#Preview("Drop Zone States") {
    VStack(spacing: 30) {
        // Normal state
        HStack(spacing: 20) {
            DropZoneView(
                isHighlighted: false,
                isValidDrop: false,
                zone: .playArea
            )
            .frame(width: 120, height: 80)
            
            Text("Normal State")
                .font(.caption)
        }
        
        // Valid drop highlighted
        HStack(spacing: 20) {
            DropZoneView(
                isHighlighted: true,
                isValidDrop: true,
                zone: .playArea
            )
            .frame(width: 120, height: 80)
            
            Text("Valid Drop")
                .font(.caption)
                .foregroundColor(RomanianColors.countrysideGreen)
        }
        
        // Invalid drop highlighted
        HStack(spacing: 20) {
            DropZoneView(
                isHighlighted: true,
                isValidDrop: false,
                zone: .invalidArea
            )
            .frame(width: 120, height: 80)
            
            Text("Invalid Drop")
                .font(.caption)
                .foregroundColor(RomanianColors.primaryRed)
        }
        
        // Special move
        HStack(spacing: 20) {
            DropZoneView(
                isHighlighted: true,
                isValidDrop: true,
                zone: .specialMove
            )
            .frame(width: 120, height: 80)
            
            Text("Special Move (7)")
                .font(.caption)
                .foregroundColor(RomanianColors.goldAccent)
        }
    }
    .padding()
    .background(Color.black.opacity(0.8))
}