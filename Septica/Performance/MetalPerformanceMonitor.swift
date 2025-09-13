//
//  MetalPerformanceMonitor.swift
//  Septica
//
//  Specialized performance monitoring for Metal rendering pipeline
//  Tracks GPU performance, frame timing, and rendering metrics
//

import Foundation
import Metal
import MetalKit
import Combine
import SwiftUI

/// Specialized performance monitoring for Metal rendering
@MainActor
class MetalPerformanceMonitor: ObservableObject {
    
    // MARK: - Performance Metrics
    
    @Published var gpuUtilization: Double = 0.0
    @Published var frameRenderTime: Double = 0.0 // milliseconds
    @Published var trianglesPerSecond: Double = 0.0
    @Published var textureMemoryUsage: Int64 = 0 // bytes
    @Published var commandBufferCompletionTime: Double = 0.0
    @Published var metalPipelinePerformance: [String: Double] = [:]
    
    // MARK: - Frame Rate Monitoring
    
    @Published var currentFPS: Double = 60.0
    @Published var targetFPS: Double = 60.0
    @Published var frameTimeVariance: Double = 0.0
    @Published var droppedFrames: Int = 0
    @Published var frameTimeHistory: [Double] = []
    
    // MARK: - GPU Memory Monitoring
    
    @Published var allocatedGPUMemory: Int64 = 0
    @Published var usedGPUMemory: Int64 = 0
    @Published var availableGPUMemory: Int64 = 0
    @Published var bufferAllocationCount: Int = 0
    @Published var textureAllocationCount: Int = 0
    
    // MARK: - Romanian Septica Specific Metrics
    
    @Published var cardRenderPerformance: [String: Double] = [:]
    @Published var particleSystemPerformance: [String: Double] = [:]
    @Published var shaderCompilationTime: [String: Double] = [:]
    @Published var culturalEffectsImpact: Double = 0.0
    
    // MARK: - Internal Tracking
    
    private let device: MTLDevice
    private var performanceMonitor: PerformanceMonitor?
    private var frameStartTime: CFTimeInterval = 0
    private var lastFrameTime: CFTimeInterval = 0
    private let maxFrameHistorySize = 120 // 2 seconds at 60 FPS
    private var commandBufferStartTimes: [ObjectIdentifier: CFTimeInterval] = [:]
    
    // MARK: - Performance Thresholds
    
    static let targetFrameTime: Double = 16.67 // 60 FPS in milliseconds
    static let maxFrameTimeVariance: Double = 5.0 // milliseconds
    static let maxGPUMemoryUsage: Int64 = 256 * 1024 * 1024 // 256 MB
    static let warningFrameTime: Double = 20.0 // 50 FPS
    static let criticalFrameTime: Double = 33.33 // 30 FPS
    
    // MARK: - Initialization
    
    init(device: MTLDevice, performanceMonitor: PerformanceMonitor? = nil) {
        self.device = device
        self.performanceMonitor = performanceMonitor
        
        startMonitoring()
    }
    
    // MARK: - Monitoring Control
    
    func startMonitoring() {
        // Reset metrics
        resetMetrics()
        
        // Begin frame timing
        frameStartTime = CACurrentMediaTime()
        lastFrameTime = frameStartTime
        
        print("🎯 Metal performance monitoring started")
    }
    
    func stopMonitoring() {
        // Clean up tracking data
        commandBufferStartTimes.removeAll()
        frameTimeHistory.removeAll()
        
        print("🎯 Metal performance monitoring stopped")
    }
    
    private func resetMetrics() {
        gpuUtilization = 0.0
        frameRenderTime = 0.0
        trianglesPerSecond = 0.0
        textureMemoryUsage = 0
        commandBufferCompletionTime = 0.0
        currentFPS = 60.0
        frameTimeVariance = 0.0
        droppedFrames = 0
        frameTimeHistory.removeAll()
        metalPipelinePerformance.removeAll()
        cardRenderPerformance.removeAll()
        particleSystemPerformance.removeAll()
        shaderCompilationTime.removeAll()
        culturalEffectsImpact = 0.0
    }
    
    // MARK: - Frame Performance Tracking
    
    func beginFrame() {
        frameStartTime = CACurrentMediaTime()
    }
    
    func endFrame() {
        let currentTime = CACurrentMediaTime()
        let frameTime = (currentTime - frameStartTime) * 1000.0 // Convert to milliseconds
        
        // Update frame time history
        frameTimeHistory.append(frameTime)
        if frameTimeHistory.count > maxFrameHistorySize {
            frameTimeHistory.removeFirst()
        }
        
        // Calculate current FPS
        if lastFrameTime > 0 {
            let deltaTime = currentTime - lastFrameTime
            currentFPS = deltaTime > 0 ? 1.0 / deltaTime : 60.0
        }
        
        // Update frame render time
        frameRenderTime = frameTime
        
        // Calculate frame time variance
        updateFrameTimeVariance()
        
        // Check for dropped frames
        if frameTime > Self.warningFrameTime {
            droppedFrames += 1
        }
        
        // Update last frame time
        lastFrameTime = currentTime
        
        // Report to main performance monitor
        performanceMonitor?.recordMetric(name: "MetalFrameTime", value: frameTime, unit: "ms")
        performanceMonitor?.recordMetric(name: "MetalFPS", value: currentFPS, unit: "fps")
        
        // Check performance thresholds
        checkPerformanceThresholds()
    }
    
    private func updateFrameTimeVariance() {
        guard frameTimeHistory.count >= 10 else { return }
        
        let recent = Array(frameTimeHistory.suffix(10))
        let average = recent.reduce(0, +) / Double(recent.count)
        let variance = recent.map { pow($0 - average, 2) }.reduce(0, +) / Double(recent.count)
        frameTimeVariance = sqrt(variance)
    }
    
    // MARK: - Command Buffer Tracking
    
    func trackCommandBuffer(_ commandBuffer: MTLCommandBuffer, operation: String) {
        let startTime = CACurrentMediaTime()
        commandBufferStartTimes[ObjectIdentifier(commandBuffer)] = startTime
        
        commandBuffer.addCompletedHandler { [weak self] buffer in
            Task { @MainActor in
                self?.handleCommandBufferCompletion(buffer, operation: operation, startTime: startTime)
            }
        }
    }
    
    private func handleCommandBufferCompletion(
        _ commandBuffer: MTLCommandBuffer,
        operation: String,
        startTime: CFTimeInterval
    ) {
        let completionTime = (CACurrentMediaTime() - startTime) * 1000.0 // milliseconds
        commandBufferCompletionTime = completionTime
        
        // Track specific operations
        metalPipelinePerformance[operation] = completionTime
        
        // Romanian Septica specific tracking
        if operation.contains("Card") {
            cardRenderPerformance[operation] = completionTime
        } else if operation.contains("Particle") {
            particleSystemPerformance[operation] = completionTime
        } else if operation.contains("Romanian") {
            culturalEffectsImpact = max(culturalEffectsImpact, completionTime)
        }
        
        // Clean up tracking
        commandBufferStartTimes.removeValue(forKey: ObjectIdentifier(commandBuffer))
        
        // Report to main performance monitor
        performanceMonitor?.recordMetric(name: "MetalOperation_\(operation)", value: completionTime, unit: "ms")
    }
    
    // MARK: - GPU Memory Tracking
    
    func updateGPUMemoryUsage() {
        // Note: Metal doesn't provide direct GPU memory usage APIs
        // This would typically be implemented using device-specific methods
        // For now, we'll estimate based on allocated resources
        
        // Placeholder implementation - in a real app, you'd track buffer/texture allocations
        allocatedGPUMemory = Int64(bufferAllocationCount * 1024 * 1024) // Rough estimate
        usedGPUMemory = allocatedGPUMemory // Simplified
        availableGPUMemory = Self.maxGPUMemoryUsage - usedGPUMemory
        
        performanceMonitor?.recordMetric(name: "GPUMemoryUsage", value: Double(usedGPUMemory), unit: "bytes")
    }
    
    func trackBufferAllocation(size: Int) {
        bufferAllocationCount += 1
        updateGPUMemoryUsage()
    }
    
    func trackTextureAllocation(size: Int) {
        textureAllocationCount += 1
        textureMemoryUsage += Int64(size)
        updateGPUMemoryUsage()
    }
    
    // MARK: - Shader Performance Tracking
    
    func trackShaderCompilation(shaderName: String, compilationTime: Double) {
        shaderCompilationTime[shaderName] = compilationTime
        
        performanceMonitor?.recordMetric(
            name: "ShaderCompilation_\(shaderName)",
            value: compilationTime,
            unit: "ms"
        )
    }
    
    // MARK: - Romanian Septica Specific Tracking
    
    func trackCardRenderingPerformance(cardType: String, renderTime: Double) {
        cardRenderPerformance["Card_\(cardType)"] = renderTime
        
        performanceMonitor?.recordMetric(
            name: "CardRender_\(cardType)",
            value: renderTime,
            unit: "ms"
        )
    }
    
    func trackRomanianEffectsPerformance(effectName: String, renderTime: Double) {
        let key = "RomanianEffect_\(effectName)"
        metalPipelinePerformance[key] = renderTime
        culturalEffectsImpact = max(culturalEffectsImpact, renderTime)
        
        performanceMonitor?.recordMetric(
            name: key,
            value: renderTime,
            unit: "ms"
        )
    }
    
    // MARK: - Performance Analysis
    
    func getPerformanceReport() -> MetalPerformanceReport {
        return MetalPerformanceReport(
            averageFPS: calculateAverageFPS(),
            averageFrameTime: calculateAverageFrameTime(),
            frameTimeVariance: frameTimeVariance,
            droppedFramePercentage: calculateDroppedFramePercentage(),
            gpuMemoryUsage: Double(usedGPUMemory) / Double(Self.maxGPUMemoryUsage) * 100.0,
            commandBufferPerformance: metalPipelinePerformance,
            cardRenderingPerformance: cardRenderPerformance,
            romanianEffectsImpact: culturalEffectsImpact,
            performanceLevel: determinePerformanceLevel(),
            recommendations: generatePerformanceRecommendations()
        )
    }
    
    private func calculateAverageFPS() -> Double {
        guard !frameTimeHistory.isEmpty else { return 60.0 }
        
        let averageFrameTime = frameTimeHistory.reduce(0, +) / Double(frameTimeHistory.count)
        return averageFrameTime > 0 ? 1000.0 / averageFrameTime : 60.0
    }
    
    private func calculateAverageFrameTime() -> Double {
        guard !frameTimeHistory.isEmpty else { return Self.targetFrameTime }
        
        return frameTimeHistory.reduce(0, +) / Double(frameTimeHistory.count)
    }
    
    private func calculateDroppedFramePercentage() -> Double {
        guard !frameTimeHistory.isEmpty else { return 0.0 }
        
        let totalFrames = frameTimeHistory.count
        let droppedCount = frameTimeHistory.filter { $0 > Self.warningFrameTime }.count
        
        return Double(droppedCount) / Double(totalFrames) * 100.0
    }
    
    func determinePerformanceLevel() -> MetalPerformanceLevel {
        let avgFPS = calculateAverageFPS()
        let avgFrameTime = calculateAverageFrameTime()
        let droppedPercentage = calculateDroppedFramePercentage()
        
        if avgFPS >= 58 && avgFrameTime <= 17 && droppedPercentage <= 1 {
            return .excellent
        } else if avgFPS >= 50 && avgFrameTime <= 20 && droppedPercentage <= 5 {
            return .good
        } else if avgFPS >= 40 && avgFrameTime <= 25 && droppedPercentage <= 10 {
            return .acceptable
        } else {
            return .poor
        }
    }
    
    private func generatePerformanceRecommendations() -> [String] {
        var recommendations: [String] = []
        
        let avgFPS = calculateAverageFPS()
        let avgFrameTime = calculateAverageFrameTime()
        let memoryUsagePercentage = Double(usedGPUMemory) / Double(Self.maxGPUMemoryUsage) * 100.0
        
        if avgFPS < 50 {
            recommendations.append("Frame rate below target - consider reducing render complexity")
        }
        
        if avgFrameTime > Self.warningFrameTime {
            recommendations.append("Frame time too high - optimize rendering pipeline")
        }
        
        if frameTimeVariance > Self.maxFrameTimeVariance {
            recommendations.append("Frame time inconsistent - check for performance spikes")
        }
        
        if memoryUsagePercentage > 80 {
            recommendations.append("GPU memory usage high - consider reducing texture sizes")
        }
        
        if culturalEffectsImpact > 5.0 {
            recommendations.append("Romanian cultural effects impacting performance - consider optimization")
        }
        
        if cardRenderPerformance.values.max() ?? 0 > 3.0 {
            recommendations.append("Card rendering taking too long - optimize card shaders")
        }
        
        return recommendations
    }
    
    // MARK: - Performance Threshold Checking
    
    private func checkPerformanceThresholds() {
        let avgFPS = calculateAverageFPS()
        let avgFrameTime = calculateAverageFrameTime()
        
        if avgFrameTime > Self.criticalFrameTime {
            performanceMonitor?.recordMetric(name: "PerformanceCritical", value: 1, unit: "events")
        } else if avgFrameTime > Self.warningFrameTime {
            performanceMonitor?.recordMetric(name: "PerformanceWarning", value: 1, unit: "events")
        }
        
        if avgFPS < 30 {
            performanceMonitor?.recordMetric(name: "LowFPS", value: avgFPS, unit: "fps")
        }
    }
}

// MARK: - Supporting Types

struct MetalPerformanceReport {
    let averageFPS: Double
    let averageFrameTime: Double
    let frameTimeVariance: Double
    let droppedFramePercentage: Double
    let gpuMemoryUsage: Double
    let commandBufferPerformance: [String: Double]
    let cardRenderingPerformance: [String: Double]
    let romanianEffectsImpact: Double
    let performanceLevel: MetalPerformanceLevel
    let recommendations: [String]
}

enum MetalPerformanceLevel: String, CaseIterable {
    case excellent = "Excellent"
    case good = "Good"
    case acceptable = "Acceptable"
    case poor = "Poor"
    
    var color: Color {
        switch self {
        case .excellent: return .green
        case .good: return .yellow
        case .acceptable: return .orange
        case .poor: return .red
        }
    }
    
    var icon: String {
        switch self {
        case .excellent: return "checkmark.circle.fill"
        case .good: return "checkmark.circle"
        case .acceptable: return "exclamationmark.triangle"
        case .poor: return "xmark.circle"
        }
    }
}

// MARK: - Renderer Integration

extension Renderer {
    /// Integrate Metal performance monitor with the renderer
    func integratePerformanceMonitor(_ metalMonitor: MetalPerformanceMonitor) {
        // This would be called during renderer initialization
        // The renderer would then call metalMonitor methods at appropriate times
        print("🔗 Metal performance monitor integrated with renderer")
    }
    
    /// Helper method for tracking render operations
    func trackRenderOperation<T>(_ operation: () -> T, operationName: String, metalMonitor: MetalPerformanceMonitor) -> T {
        let startTime = CACurrentMediaTime()
        let result = operation()
        let endTime = CACurrentMediaTime()
        let duration = (endTime - startTime) * 1000.0 // milliseconds
        
        metalMonitor.metalPipelinePerformance[operationName] = duration
        return result
    }
}

// MARK: - SwiftUI Integration

struct MetalPerformanceView: View {
    @ObservedObject var metalMonitor: MetalPerformanceMonitor
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: metalMonitor.determinePerformanceLevel().icon)
                    .foregroundColor(metalMonitor.determinePerformanceLevel().color)
                Text("Metal Performance")
                    .font(.headline)
                Spacer()
                Text(String(format: "%.1f FPS", metalMonitor.currentFPS))
                    .font(.system(.body, design: .monospaced))
            }
            
            ProgressView("Frame Time", value: metalMonitor.frameRenderTime, total: 33.33)
            ProgressView("GPU Memory", value: Double(metalMonitor.usedGPUMemory), total: Double(MetalPerformanceMonitor.maxGPUMemoryUsage))
            
            if !metalMonitor.cardRenderPerformance.isEmpty {
                Text("Card Rendering")
                    .font(.subheadline)
                    .padding(.top, 4)
                
                ForEach(Array(metalMonitor.cardRenderPerformance.keys), id: \.self) { key in
                    HStack {
                        Text(key)
                            .font(.caption)
                        Spacer()
                        Text(String(format: "%.2f ms", metalMonitor.cardRenderPerformance[key] ?? 0))
                            .font(.caption.monospaced())
                    }
                }
            }
        }
        .padding()
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(8)
    }
}

// MARK: - Preview Support

#if DEBUG
extension MetalPerformanceMonitor {
    static let preview: MetalPerformanceMonitor = {
        let device = MTLCreateSystemDefaultDevice()!
        let monitor = MetalPerformanceMonitor(device: device)
        monitor.currentFPS = 58.5
        monitor.frameRenderTime = 17.2
        monitor.cardRenderPerformance = [
            "SevenOfHearts": 2.1,
            "AceOfSpades": 1.8,
            "BasicCard": 1.2
        ]
        return monitor
    }()
}
#endif