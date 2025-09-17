//
//  BatteryOptimizationManager.swift
//  Septica
//
//  Battery usage optimization system for Romanian Septica game
//  Reduces power consumption while maintaining gameplay quality
//  Target: <5% battery usage per hour during gameplay
//

import Foundation
import UIKit
import Combine

/// Comprehensive battery optimization for Septica game
/// Adapts performance based on battery level and usage patterns
@MainActor
class BatteryOptimizationManager: ObservableObject {
    
    // MARK: - Published Battery Status
    
    @Published var currentBatteryLevel: Float = 1.0
    @Published var batteryState: UIDevice.BatteryState = .unknown
    @Published var powerOptimizationLevel: PowerOptimizationLevel = .balanced
    @Published var estimatedPlaytimeRemaining: TimeInterval = 0 // Hours
    
    // MARK: - Power Optimization Targets
    
    static let targetBatteryUsagePerHour: Double = 0.05 // 5% per hour
    static let lowBatteryThreshold: Float = 0.20 // 20%
    static let criticalBatteryThreshold: Float = 0.10 // 10%
    
    // MARK: - Adaptive Performance Settings
    
    @Published var adaptiveFPS: Double = 60.0
    @Published var metalRenderingQuality: RenderingQuality = .high
    @Published var audioProcessingLevel: AudioProcessingLevel = .full
    @Published var animationComplexity: AnimationComplexity = .full
    
    // MARK: - Dependencies
    
    private weak var performanceMonitor: PerformanceMonitor?
    private var cancellables = Set<AnyCancellable>()
    private var batteryUsageTracker = BatteryUsageTracker()
    
    // MARK: - Initialization
    
    init(performanceMonitor: PerformanceMonitor? = nil) {
        self.performanceMonitor = performanceMonitor
        setupBatteryMonitoring()
        updateBatteryStatus()
    }
    
    // MARK: - Battery Monitoring Setup
    
    private func setupBatteryMonitoring() {
        // Enable battery monitoring
        UIDevice.current.isBatteryMonitoringEnabled = true
        
        // Monitor battery level changes
        NotificationCenter.default.publisher(for: UIDevice.batteryLevelDidChangeNotification)
            .sink { [weak self] _ in
                self?.updateBatteryStatus()
            }
            .store(in: &cancellables)
        
        // Monitor battery state changes
        NotificationCenter.default.publisher(for: UIDevice.batteryStateDidChangeNotification)
            .sink { [weak self] _ in
                self?.updateBatteryStatus()
            }
            .store(in: &cancellables)
        
        // Monitor app state changes for power optimization
        NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)
            .sink { [weak self] _ in
                self?.enterBackgroundPowerMode()
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)
            .sink { [weak self] _ in
                self?.exitBackgroundPowerMode()
            }
            .store(in: &cancellables)
        
        // Regular battery usage tracking
        Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { [weak self] _ in
            self?.trackBatteryUsage()
        }
    }
    
    // MARK: - Battery Status Management
    
    private func updateBatteryStatus() {
        let device = UIDevice.current
        currentBatteryLevel = device.batteryLevel
        batteryState = device.batteryState
        
        // Update optimization level based on battery state
        updatePowerOptimizationLevel()
        
        // Calculate estimated playtime
        estimatedPlaytimeRemaining = calculateEstimatedPlaytime()
        
        print("🔋 Battery Status Updated:")
        print("   - Level: \(Int(currentBatteryLevel * 100))%")
        print("   - State: \(batteryState.description)")
        print("   - Optimization: \(powerOptimizationLevel.rawValue)")
        print("   - Estimated playtime: \(String(format: "%.1f", estimatedPlaytimeRemaining)) hours")
    }
    
    private func updatePowerOptimizationLevel() {
        if batteryState == .charging {
            powerOptimizationLevel = .performance
        } else if currentBatteryLevel <= Self.criticalBatteryThreshold {
            powerOptimizationLevel = .maximum
        } else if currentBatteryLevel <= Self.lowBatteryThreshold {
            powerOptimizationLevel = .aggressive
        } else {
            powerOptimizationLevel = .balanced
        }
        
        // Apply optimization settings
        applyOptimizationSettings()
    }
    
    // MARK: - Power Optimization Implementation
    
    private func applyOptimizationSettings() {
        switch powerOptimizationLevel {
        case .performance:
            adaptiveFPS = 60.0
            metalRenderingQuality = .high
            audioProcessingLevel = .full
            animationComplexity = .full
            
        case .balanced:
            adaptiveFPS = 60.0
            metalRenderingQuality = .high
            audioProcessingLevel = .optimized
            animationComplexity = .reduced
            
        case .aggressive:
            adaptiveFPS = 45.0
            metalRenderingQuality = .medium
            audioProcessingLevel = .essential
            animationComplexity = .minimal
            
        case .maximum:
            adaptiveFPS = 30.0
            metalRenderingQuality = .low
            audioProcessingLevel = .disabled
            animationComplexity = .disabled
        }
        
        // Notify performance monitor of FPS changes
        performanceMonitor?.recordMetric(
            name: "AdaptiveFPS", 
            value: adaptiveFPS, 
            unit: "fps"
        )
        
        // Post notification for other components to adapt
        NotificationCenter.default.post(
            name: .batteryOptimizationChanged,
            object: self,
            userInfo: [
                "optimizationLevel": powerOptimizationLevel,
                "adaptiveFPS": adaptiveFPS,
                "renderingQuality": metalRenderingQuality,
                "audioLevel": audioProcessingLevel
            ]
        )
    }
    
    // MARK: - Background Power Management
    
    private func enterBackgroundPowerMode() {
        // Dramatically reduce power consumption when in background
        adaptiveFPS = 1.0 // Minimal updates for background sync
        metalRenderingQuality = .disabled
        audioProcessingLevel = .disabled
        
        print("📱 Entered background power mode - FPS reduced to 1 fps")
    }
    
    private func exitBackgroundPowerMode() {
        // Restore normal power settings when returning to foreground
        updatePowerOptimizationLevel()
        print("📱 Exited background power mode - FPS restored to \(adaptiveFPS) fps")
    }
    
    // MARK: - Battery Usage Tracking
    
    private func trackBatteryUsage() {
        batteryUsageTracker.recordBatteryLevel(currentBatteryLevel)
        
        let hourlyUsage = batteryUsageTracker.getHourlyBatteryUsage()
        if hourlyUsage > Self.targetBatteryUsagePerHour {
            print("⚠️ Battery usage exceeds target: \(String(format: "%.1f", hourlyUsage * 100))%/hour")
            recommendFurtherOptimization()
        }
    }
    
    private func calculateEstimatedPlaytime() -> TimeInterval {
        let usageRate = batteryUsageTracker.getHourlyBatteryUsage()
        if usageRate > 0 {
            return TimeInterval(currentBatteryLevel / Float(usageRate))
        }
        return 8.0 // Default estimate if no usage data
    }
    
    private func recommendFurtherOptimization() {
        // Suggest more aggressive optimization if battery usage is too high
        if powerOptimizationLevel.rawValue < PowerOptimizationLevel.maximum.rawValue {
            let nextLevel = PowerOptimizationLevel(rawValue: powerOptimizationLevel.rawValue + 1) ?? .maximum
            print("💡 Recommending more aggressive optimization: \(nextLevel.rawValue)")
        }
    }
    
    // MARK: - Game-Specific Optimizations
    
    /// Optimize rendering for card animations based on power level
    func getOptimizedCardAnimationSettings() -> CardAnimationSettings {
        switch animationComplexity {
        case .full:
            return CardAnimationSettings(
                enableParticleEffects: true,
                enableGlowEffects: true,
                enableShadowEffects: true,
                animationDuration: 1.0,
                enableRomanianCulturalEffects: true
            )
            
        case .reduced:
            return CardAnimationSettings(
                enableParticleEffects: true,
                enableGlowEffects: false,
                enableShadowEffects: true,
                animationDuration: 0.7,
                enableRomanianCulturalEffects: true
            )
            
        case .minimal:
            return CardAnimationSettings(
                enableParticleEffects: false,
                enableGlowEffects: false,
                enableShadowEffects: false,
                animationDuration: 0.5,
                enableRomanianCulturalEffects: false
            )
            
        case .disabled:
            return CardAnimationSettings(
                enableParticleEffects: false,
                enableGlowEffects: false,
                enableShadowEffects: false,
                animationDuration: 0.1,
                enableRomanianCulturalEffects: false
            )
        }
    }
    
    /// Get optimized Metal rendering settings
    func getOptimizedMetalSettings() -> MetalRenderingSettings {
        switch metalRenderingQuality {
        case .high:
            return MetalRenderingSettings(
                textureQuality: .high,
                shadowQuality: .high,
                antiAliasing: .msaa4x,
                enablePostProcessing: true
            )
            
        case .medium:
            return MetalRenderingSettings(
                textureQuality: .medium,
                shadowQuality: .medium,
                antiAliasing: .msaa2x,
                enablePostProcessing: false
            )
            
        case .low:
            return MetalRenderingSettings(
                textureQuality: .low,
                shadowQuality: .disabled,
                antiAliasing: .disabled,
                enablePostProcessing: false
            )
            
        case .disabled:
            return MetalRenderingSettings(
                textureQuality: .disabled,
                shadowQuality: .disabled,
                antiAliasing: .disabled,
                enablePostProcessing: false
            )
        }
    }
    
    // MARK: - Battery Usage Report
    
    func getBatteryOptimizationReport() -> BatteryOptimizationReport {
        return BatteryOptimizationReport(
            currentBatteryLevel: currentBatteryLevel,
            batteryState: batteryState,
            optimizationLevel: powerOptimizationLevel,
            estimatedPlaytime: estimatedPlaytimeRemaining,
            hourlyUsage: batteryUsageTracker.getHourlyBatteryUsage(),
            targetUsage: Self.targetBatteryUsagePerHour,
            isUsageOptimal: batteryUsageTracker.getHourlyBatteryUsage() <= Self.targetBatteryUsagePerHour,
            recommendations: generateOptimizationRecommendations()
        )
    }
    
    private func generateOptimizationRecommendations() -> [String] {
        var recommendations: [String] = []
        
        let hourlyUsage = batteryUsageTracker.getHourlyBatteryUsage()
        
        if hourlyUsage > Self.targetBatteryUsagePerHour * 1.5 {
            recommendations.append("Consider enabling aggressive power optimization")
            recommendations.append("Reduce Romanian cultural effects complexity")
        } else if hourlyUsage > Self.targetBatteryUsagePerHour {
            recommendations.append("Battery usage slightly elevated - monitor during extended play")
        } else {
            recommendations.append("Battery usage optimized for extended gameplay")
        }
        
        if currentBatteryLevel <= Self.lowBatteryThreshold {
            recommendations.append("Low battery detected - consider charging soon")
        }
        
        if batteryState == .charging {
            recommendations.append("Charging detected - performance mode enabled")
        }
        
        return recommendations
    }
}

// MARK: - Battery Usage Tracker

private class BatteryUsageTracker {
    private var batteryLevels: [(timestamp: Date, level: Float)] = []
    private let maxSamples = 60 // Track last 60 minutes
    
    func recordBatteryLevel(_ level: Float) {
        batteryLevels.append((timestamp: Date(), level: level))
        
        // Remove old samples
        let cutoffTime = Date().addingTimeInterval(-3600) // 1 hour ago
        batteryLevels.removeAll { $0.timestamp < cutoffTime }
    }
    
    func getHourlyBatteryUsage() -> Double {
        guard batteryLevels.count >= 2 else { return 0.0 }
        
        let oldestLevel = batteryLevels.first!.level
        let newestLevel = batteryLevels.last!.level
        let timespan = batteryLevels.last!.timestamp.timeIntervalSince(batteryLevels.first!.timestamp)
        
        if timespan > 0 {
            let usage = Double(oldestLevel - newestLevel)
            let hourlyUsage = usage * (3600.0 / timespan) // Scale to hourly rate
            return max(0.0, hourlyUsage) // Ensure non-negative
        }
        
        return 0.0
    }
}

// MARK: - Supporting Enums and Structs

enum PowerOptimizationLevel: Int, CaseIterable {
    case performance = 0    // Charging - Full performance
    case balanced = 1       // Normal battery - Balanced performance
    case aggressive = 2     // Low battery - Reduced performance
    case maximum = 3        // Critical battery - Minimal performance
    
    var description: String {
        switch self {
        case .performance: return "Performance (Charging)"
        case .balanced: return "Balanced (Normal)"
        case .aggressive: return "Aggressive (Low Battery)"
        case .maximum: return "Maximum (Critical Battery)"
        }
    }
}

enum RenderingQuality: CaseIterable {
    case high, medium, low, disabled
}

enum AudioProcessingLevel: CaseIterable {
    case full, optimized, essential, disabled
}

enum AnimationComplexity: CaseIterable {
    case full, reduced, minimal, disabled
}

struct CardAnimationSettings {
    let enableParticleEffects: Bool
    let enableGlowEffects: Bool
    let enableShadowEffects: Bool
    let animationDuration: TimeInterval
    let enableRomanianCulturalEffects: Bool
}

struct MetalRenderingSettings {
    let textureQuality: RenderingQuality
    let shadowQuality: RenderingQuality
    let antiAliasing: AntiAliasingLevel
    let enablePostProcessing: Bool
}

enum AntiAliasingLevel: CaseIterable {
    case disabled, msaa2x, msaa4x
}

struct BatteryOptimizationReport {
    let currentBatteryLevel: Float
    let batteryState: UIDevice.BatteryState
    let optimizationLevel: PowerOptimizationLevel
    let estimatedPlaytime: TimeInterval
    let hourlyUsage: Double
    let targetUsage: Double
    let isUsageOptimal: Bool
    let recommendations: [String]
    
    var detailedReport: String {
        let batteryPercentage = Int(currentBatteryLevel * 100)
        let usagePercentage = String(format: "%.1f", hourlyUsage * 100)
        let targetPercentage = String(format: "%.1f", targetUsage * 100)
        let playtimeHours = String(format: "%.1f", estimatedPlaytime)
        
        return """
        🔋 Battery Optimization Report
        
        📊 Current Status:
        • Battery Level: \(batteryPercentage)% (\(batteryState.description))
        • Optimization: \(optimizationLevel.description)
        • Estimated Playtime: \(playtimeHours) hours
        
        ⚡ Power Usage:
        • Current Usage: \(usagePercentage)%/hour
        • Target Usage: \(targetPercentage)%/hour
        • Status: \(isUsageOptimal ? "✅ Optimal" : "⚠️ Above Target")
        
        💡 Recommendations:
        \(recommendations.map { "• \($0)" }.joined(separator: "\n"))
        """
    }
}

// MARK: - Extensions

extension UIDevice.BatteryState {
    var description: String {
        switch self {
        case .unknown: return "Unknown"
        case .unplugged: return "Unplugged"
        case .charging: return "Charging"
        case .full: return "Full"
        @unknown default: return "Unknown"
        }
    }
}

// MARK: - Notifications

extension Notification.Name {
    static let batteryOptimizationChanged = Notification.Name("batteryOptimizationChanged")
}