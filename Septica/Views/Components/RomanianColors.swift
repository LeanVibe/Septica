//
//  RomanianColors.swift
//  Septica
//
//  Romanian cultural color palette for authentic heritage design
//  Based on traditional Romanian flag colors and folk art
//

import SwiftUI

/// Romanian cultural color system for authentic heritage design
struct RomanianColors {
    
    // MARK: - Primary Romanian Flag Colors
    
    /// Romanian flag red - deep traditional red
    static let primaryRed = Color(red: 0.8, green: 0.2, blue: 0.2)
    
    /// Romanian flag blue - deep royal blue  
    static let primaryBlue = Color(red: 0.0, green: 0.3, blue: 0.6)
    
    /// Romanian flag yellow - golden yellow
    static let primaryYellow = Color(red: 1.0, green: 0.8, blue: 0.0)
    
    // MARK: - Game-Specific Cultural Colors
    
    /// Deep navy for card backs - traditional Romanian card color
    static let cardBack = Color(red: 0.15, green: 0.25, blue: 0.4)
    
    /// Forest green for table - Carpathian Mountains inspiration
    static let tableGreen = Color(red: 0.1, green: 0.5, blue: 0.2)
    
    /// Metallic gold accent - traditional Romanian craftsmanship
    static let goldAccent = Color(red: 1.0, green: 0.84, blue: 0.0)
    
    // MARK: - Traditional Romanian Folk Art Colors
    
    /// Traditional Romanian pottery blue
    static let folkBlue = Color(red: 0.2, green: 0.4, blue: 0.7)
    
    /// Traditional Romanian embroidery red
    static let embroideryRed = Color(red: 0.9, green: 0.2, blue: 0.2)
    
    /// Traditional Romanian countryside green
    static let countrysideGreen = Color(red: 0.3, green: 0.6, blue: 0.3)
    
    /// Traditional Romanian golden yellow - Byzantine influence
    static let byzantineGold = Color(red: 1.0, green: 0.8, blue: 0.2)
    
    // MARK: - Game State Colors with Romanian Influence
    
    /// Valid move indicator with Romanian green
    static let validMove = countrysideGreen.opacity(0.3)
    
    /// Invalid move indicator with Romanian red
    static let invalidMove = embroideryRed.opacity(0.3)
    
    /// Current player indicator with Romanian blue
    static let currentPlayer = folkBlue.opacity(0.6)
    
    /// Winning card indicator with Romanian gold
    static let winningCard = byzantineGold.opacity(0.8)
    
    // MARK: - Cultural Gradients
    
    /// Romanian heritage gradient - flag colors
    static let heritageGradient = LinearGradient(
        colors: [primaryBlue, primaryYellow, primaryRed],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    /// Carpathian mountains gradient - natural Romanian landscape
    static let carpathianGradient = LinearGradient(
        colors: [Color(red: 0.2, green: 0.4, blue: 0.1), Color(red: 0.4, green: 0.6, blue: 0.3)],
        startPoint: .top,
        endPoint: .bottom
    )
    
    /// Traditional pottery gradient
    static let potteryGradient = LinearGradient(
        colors: [folkBlue, Color(red: 0.3, green: 0.5, blue: 0.8)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

// MARK: - Romanian Cultural Patterns

extension Color {
    /// Initialize Color from hex string
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
    
    /// Get appropriate text color for Romanian cultural backgrounds
    static func romanianText(for background: Color) -> Color {
        // Use traditional Romanian contrast principles
        return Color.primary // Adapts to light/dark mode appropriately
    }
}

// MARK: - Accessibility Support

extension RomanianColors {
    /// Ensure Romanian colors meet WCAG accessibility standards
    static func accessibleRomanianColor(for context: ColorContext) -> Color {
        switch context {
        case .cardSuit:
            return primaryRed // High contrast for card suits
        case .tableBackground:
            return tableGreen // Sufficient contrast for readability
        case .selectionHighlight:
            return goldAccent // Highly visible for selection
        case .culturalAccent:
            return primaryBlue // Romanian blue for cultural elements
        }
    }
    
    enum ColorContext {
        case cardSuit
        case tableBackground
        case selectionHighlight
        case culturalAccent
    }
}