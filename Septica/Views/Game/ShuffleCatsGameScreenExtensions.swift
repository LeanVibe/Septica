//
//  ShuffleCatsGameScreenExtensions.swift
//  Septica
//
//  Professional rendering extensions for ShuffleCatsInspiredGameScreen
//  Provides transform and material helpers for Metal rendering
//

import SwiftUI
import simd

extension ShuffleCatsInspiredGameScreen {
    
    // MARK: - Professional Card Transform Helpers
    
    func getTableCardTransform(for index: Int, total: Int) -> SimpleTransform {
        let baseRotation = Double(index - total/2) * 4
        let depthTilt = 10.0
        
        return SimpleTransform(
            perspective: 0.6,
            rotationX: depthTilt,
            rotationY: 3.0,
            rotationZ: baseRotation,
            translation: simd_float3(Float(index * 18 - total * 9), Float(index * 12 - total * 6), 0),
            lightingVector: simd_float3(0, 1, 0.5)
        )
    }
    
    func getTableCardMaterial(for card: Card, isLastPlayed: Bool) -> MaterialProperties {
        var properties = MaterialProperties()
        properties.albedo = Color.white.toSIMD3()
        properties.metallicFactor = isLastPlayed ? 0.3 : 0.1
        properties.roughnessFactor = 0.5
        properties.folkPatternIntensity = isLastPlayed ? 1.5 : 0.8
        properties.goldLeafEffect = card.isSpecialCard ? 1.0 : 0.6
        return properties
    }
    
    func getPlayerCardTransform(for index: Int, total: Int, isSelected: Bool) -> SimpleTransform {
        let offsetFromCenter = Double(index) - Double(total - 1) / 2
        let maxFanAngle = min(70.0, Double(total - 1) * 12.0)
        let step = total > 1 ? maxFanAngle / Double(total - 1) : 0
        let fanAngle = offsetFromCenter * step
        let depthTilt = 10 - abs(offsetFromCenter) * 2.5
        
        return SimpleTransform(
            perspective: 0.6,
            rotationX: depthTilt,
            rotationY: offsetFromCenter * 6,
            rotationZ: fanAngle * 0.7,
            translation: simd_float3(0, isSelected ? -22 : 0, isSelected ? 10 : 0),
            lightingVector: simd_float3(0, 1, 0.5)
        )
    }
    
    func getPlayerCardMaterial(for card: Card, isSelected: Bool) -> MaterialProperties {
        var properties = MaterialProperties()
        properties.albedo = Color.white.toSIMD3()
        properties.metallicFactor = isSelected ? 0.4 : 0.1
        properties.roughnessFactor = isSelected ? 0.3 : 0.6
        properties.folkPatternIntensity = isSelected ? 1.8 : 1.0
        properties.goldLeafEffect = card.isSpecialCard ? 1.2 : 0.7
        return properties
    }
}