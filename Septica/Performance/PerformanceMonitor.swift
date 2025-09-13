//
//  PerformanceMonitor.swift
//  Septica
//
//  Real-time performance monitoring system for Septica game
//  Tracks FPS, memory usage, AI decision times, and system metrics
//  Optimized for 60 FPS gameplay on minimum target devices
//

import Foundation
import UIKit
import Combine

/// Real-time performance monitoring for Septica game
/// Designed to achieve 60 FPS performance targets on iPhone 11 and iPad 8th gen
@MainActor
class PerformanceMonitor: ObservableObject {
    
    // MARK: - Published Performance Metrics
    
    @Published var currentFPS: Double = 60.0
    @Published var memoryUsage: Int64 = 0 // Bytes
    @Published var averageAIDecisionTime: Double = 0.0 // Seconds
    @Published var frameDropCount: Int = 0
    @Published var isPerformanceAcceptable: Bool = true
    
    // MARK: - Performance Targets
    
    static let targetFPS: Double = 60.0
    static let maxMemoryUsage: Int64 = 100_000_000 // 100MB
    static let maxAIDecisionTime: Double = 3.0 // 3 seconds max for expert AI
    static let maxFrameDropsPerSecond: Int = 6 // Allow 10% frame drops
    
    // MARK: - Internal Tracking
    
    private var fpsTracker = FPSTracker()
    private var memoryTracker = MemoryTracker()
    private var aiDecisionTracker = AIDecisionTracker()
    private var frameDropTracker = FrameDropTracker()
    
    private var cancellables = Set<AnyCancellable>()
    private var updateTimer: Timer?
    
    // MARK: - Initialization
    
    init() {
        setupPerformanceTracking()
    }
    
    deinit {
        Task { @MainActor in
            await self.stopMonitoring()
        }
    }
    
    // MARK: - Monitoring Control
    
    /// Start performance monitoring
    func startMonitoring() {
        fpsTracker.start()
        memoryTracker.start()
        
        // Update UI metrics every second
        updateTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateMetrics()
            }
        }
    }
    
    /// Stop performance monitoring
    func stopMonitoring() async {
        updateTimer?.invalidate()
        updateTimer = nil
        fpsTracker.stop()
        memoryTracker.stop()
        cancellables.removeAll()
    }
    
    /// Record AI decision time for tracking
    func recordAIDecision(duration: TimeInterval) {
        aiDecisionTracker.recordDecision(duration: duration)
    }
    
    /// Record frame rendering for FPS tracking
    func recordFrame() {
        fpsTracker.recordFrame()
    }
    
    /// Record frame drop event
    func recordFrameDrop() {
        frameDropTracker.recordFrameDrop()
    }
    
    // MARK: - Performance Analysis
    
    /// Get detailed performance report
    func getPerformanceReport() -> PerformanceReport {
        return PerformanceReport(
            currentFPS: currentFPS,
            memoryUsageMB: Double(memoryUsage) / 1_000_000.0,
            averageAIDecisionTime: averageAIDecisionTime,
            frameDropsPerSecond: frameDropTracker.getFrameDropsPerSecond(),
            recommendations: generateRecommendations()
        )
    }
    
    /// Get performance status for current device
    func getDevicePerformanceStatus() -> DevicePerformanceStatus {
        let deviceModel = UIDevice.current.modelName
        let isMinimumDevice = deviceModel.contains("iPhone 11") || deviceModel.contains("iPad") && deviceModel.contains("8th")
        
        return DevicePerformanceStatus(
            deviceModel: deviceModel,
            isMinimumTargetDevice: isMinimumDevice,
            meetsPerformanceTargets: isPerformanceAcceptable,
            currentPerformanceLevel: calculatePerformanceLevel(),
            optimizationSuggestions: generateOptimizationSuggestions(for: deviceModel)
        )
    }
    
    // MARK: - Private Methods
    
    private func setupPerformanceTracking() {
        // Monitor for memory warnings
        NotificationCenter.default.publisher(for: UIApplication.didReceiveMemoryWarningNotification)
            .sink { [weak self] _ in
                self?.handleMemoryWarning()
            }
            .store(in: &cancellables)
        
        // Monitor app state changes
        NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)
            .sink { [weak self] _ in
                Task { @MainActor in
                    await self?.stopMonitoring()
                }
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)
            .sink { [weak self] _ in
                self?.startMonitoring()
            }
            .store(in: &cancellables)
    }
    
    private func updateMetrics() {
        currentFPS = fpsTracker.getCurrentFPS()
        memoryUsage = memoryTracker.getCurrentMemoryUsage()
        averageAIDecisionTime = aiDecisionTracker.getAverageDecisionTime()
        frameDropCount = frameDropTracker.getTotalFrameDrops()
        
        // Update performance status
        isPerformanceAcceptable = evaluatePerformanceStatus()
    }
    
    private func evaluatePerformanceStatus() -> Bool {
        let fpsAcceptable = currentFPS >= Self.targetFPS * 0.9 // Allow 10% variance
        let memoryAcceptable = memoryUsage <= Self.maxMemoryUsage
        let aiSpeedAcceptable = averageAIDecisionTime <= Self.maxAIDecisionTime
        let frameDropsAcceptable = frameDropTracker.getFrameDropsPerSecond() <= Self.maxFrameDropsPerSecond
        
        return fpsAcceptable && memoryAcceptable && aiSpeedAcceptable && frameDropsAcceptable
    }
    
    private func calculatePerformanceLevel() -> PerformanceLevel {
        let fpsScore = min(currentFPS / Self.targetFPS, 1.0)
        let memoryScore = 1.0 - min(Double(memoryUsage) / Double(Self.maxMemoryUsage), 1.0)
        let aiScore = 1.0 - min(averageAIDecisionTime / Self.maxAIDecisionTime, 1.0)
        
        let overallScore = (fpsScore + memoryScore + aiScore) / 3.0
        
        switch overallScore {
        case 0.9...1.0: return .excellent
        case 0.7..<0.9: return .good
        case 0.5..<0.7: return .acceptable
        default: return .poor
        }
    }
    
    private func generateRecommendations() -> [String] {
        var recommendations: [String] = []
        
        if currentFPS < Self.targetFPS * 0.9 {
            recommendations.append("Reduce visual effects or complexity to improve frame rate")
        }
        
        if memoryUsage > Self.maxMemoryUsage * 3/4 {
            recommendations.append("Memory usage is high - consider clearing caches")
        }
        
        if averageAIDecisionTime > Self.maxAIDecisionTime * 3/4 {
            recommendations.append("AI decision time is slow - reduce difficulty or optimize algorithms")
        }
        
        if frameDropTracker.getFrameDropsPerSecond() > Self.maxFrameDropsPerSecond / 2 {
            recommendations.append("Frame drops detected - optimize rendering pipeline")
        }
        
        return recommendations
    }
    
    private func generateOptimizationSuggestions(for deviceModel: String) -> [String] {
        var suggestions: [String] = []
        
        if deviceModel.contains("iPhone 11") {
            suggestions.append("Reduce AI difficulty for smoother gameplay")
            suggestions.append("Limit animation complexity")
        }
        
        if deviceModel.contains("iPad") && deviceModel.contains("8th") {
            suggestions.append("Optimize for larger screen rendering")
            suggestions.append("Consider reduced particle effects")
        }
        
        if !isPerformanceAcceptable {
            suggestions.append("Enable performance mode in settings")
            suggestions.append("Close other apps to free memory")
        }
        
        return suggestions
    }
    
    private func handleMemoryWarning() {
        // Immediate memory cleanup
        memoryTracker.recordMemoryWarning()
        
        // Post notification for game components to clean up
        NotificationCenter.default.post(name: .performanceMemoryWarning, object: nil)
    }
}

// MARK: - FPS Tracking

private class FPSTracker {
    private var frameTimestamps: [CFTimeInterval] = []
    private var displayLink: CADisplayLink?
    private let maxSamples = 60 // Track last 60 frames for 1-second window
    
    func start() {
        displayLink = CADisplayLink(target: self, selector: #selector(frameUpdate))
        displayLink?.add(to: .main, forMode: .common)
    }
    
    func stop() {
        displayLink?.invalidate()
        displayLink = nil
    }
    
    @objc private func frameUpdate(displayLink: CADisplayLink) {
        let currentTime = CACurrentMediaTime()
        frameTimestamps.append(currentTime)
        
        // Keep only recent frames
        if frameTimestamps.count > maxSamples {
            frameTimestamps.removeFirst()
        }
    }
    
    func recordFrame() {
        // Called manually for additional frame tracking
        frameUpdate(displayLink: displayLink ?? CADisplayLink())
    }
    
    func getCurrentFPS() -> Double {
        guard frameTimestamps.count >= 2 else { return 0.0 }
        
        let timeWindow = frameTimestamps.last! - frameTimestamps.first!
        let frameCount = Double(frameTimestamps.count - 1)
        
        return frameCount / timeWindow
    }
}

// MARK: - Memory Tracking

private class MemoryTracker {
    private var isTracking = false
    
    func start() {
        isTracking = true
    }
    
    func stop() {
        isTracking = false
    }
    
    func getCurrentMemoryUsage() -> Int64 {
        guard isTracking else { return 0 }
        
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                          task_flavor_t(MACH_TASK_BASIC_INFO),
                          $0,
                          &count)
            }
        }
        
        return kerr == KERN_SUCCESS ? Int64(info.resident_size) : 0
    }
    
    func recordMemoryWarning() {
        // Log memory warning for analysis
        print("⚠️ Memory warning received at \(Date()) - Current usage: \(getCurrentMemoryUsage() / 1_000_000)MB")
    }
}

// MARK: - AI Decision Tracking

private class AIDecisionTracker {
    private var decisionTimes: [TimeInterval] = []
    private let maxSamples = 20 // Track last 20 decisions
    
    func recordDecision(duration: TimeInterval) {
        decisionTimes.append(duration)
        
        if decisionTimes.count > maxSamples {
            decisionTimes.removeFirst()
        }
    }
    
    func getAverageDecisionTime() -> Double {
        guard !decisionTimes.isEmpty else { return 0.0 }
        return decisionTimes.reduce(0, +) / Double(decisionTimes.count)
    }
}

// MARK: - Frame Drop Tracking

private class FrameDropTracker {
    private var frameDropTimestamps: [Date] = []
    private let trackingWindow: TimeInterval = 60.0 // Track drops in last 60 seconds
    
    func recordFrameDrop() {
        frameDropTimestamps.append(Date())
        cleanOldFrameDrops()
    }
    
    func getFrameDropsPerSecond() -> Int {
        cleanOldFrameDrops()
        return frameDropTimestamps.count / Int(trackingWindow)
    }
    
    func getTotalFrameDrops() -> Int {
        cleanOldFrameDrops()
        return frameDropTimestamps.count
    }
    
    private func cleanOldFrameDrops() {
        let cutoffTime = Date().addingTimeInterval(-trackingWindow)
        frameDropTimestamps.removeAll { $0 < cutoffTime }
    }
}

// MARK: - Supporting Types

struct PerformanceReport {
    let currentFPS: Double
    let memoryUsageMB: Double
    let averageAIDecisionTime: Double
    let frameDropsPerSecond: Int
    let recommendations: [String]
}

struct DevicePerformanceStatus {
    let deviceModel: String
    let isMinimumTargetDevice: Bool
    let meetsPerformanceTargets: Bool
    let currentPerformanceLevel: PerformanceLevel
    let optimizationSuggestions: [String]
}

enum PerformanceLevel: String, CaseIterable {
    case excellent = "Excellent"
    case good = "Good"  
    case acceptable = "Acceptable"
    case poor = "Poor"
}

// MARK: - Notifications

extension Notification.Name {
    static let performanceMemoryWarning = Notification.Name("performanceMemoryWarning")
}

// MARK: - Device Extensions

extension UIDevice {
    var modelName: String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)) ?? UnicodeScalar(0)!)
        }
        
        // Map device identifiers to readable names
        switch identifier {
        case "iPhone13,2": return "iPhone 12"
        case "iPhone14,2": return "iPhone 13 Pro"
        case "iPhone14,3": return "iPhone 13 Pro Max"
        case "iPhone15,2": return "iPhone 14 Pro"
        case "iPhone16,1": return "iPhone 15"
        case "iPhone16,2": return "iPhone 15 Plus"
        case "iPad13,1", "iPad13,2": return "iPad Air (5th generation)"
        case "iPad14,1", "iPad14,2": return "iPad mini (6th generation)"
        default: return identifier
        }
    }
}