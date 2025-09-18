//
//  RenderingSettingsView.swift
//  Septica
//
//  Settings panel for controlling professional rendering features
//  Allows users to toggle Metal rendering and adjust visual quality
//

import SwiftUI
import Metal

// MARK: - Rendering Settings View

/// Settings view for controlling professional rendering features
struct RenderingSettingsView: View {
    
    // MARK: - Settings Properties
    
    @AppStorage("enableMetalRendering") private var enableMetalRendering: Bool = false
    @AppStorage("renderQuality") private var renderQuality: String = "high"
    @AppStorage("enableAdvancedEffects") private var enableAdvancedEffects: Bool = true
    @AppStorage("enableRomanianCulturalEffects") private var enableRomanianCulturalEffects: Bool = true
    @AppStorage("enableShuffleCatsEnhancements") private var enableShuffleCatsEnhancements: Bool = true
    @AppStorage("performanceMode") private var performanceMode: String = "balanced"
    
    // MARK: - State
    
    @State private var isMetalAvailable: Bool = false
    @State private var deviceInfo: String = ""
    @State private var memoryInfo: String = ""
    @State private var showAdvancedSettings: Bool = false
    
    // MARK: - Environment
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                // Metal Rendering Section
                metalRenderingSection
                
                // Visual Quality Section
                visualQualitySection
                
                // Cultural Effects Section
                culturalEffectsSection
                
                // Performance Section
                performanceSection
                
                // Advanced Settings
                if showAdvancedSettings {
                    advancedSettingsSection
                }
                
                // Device Information
                deviceInformationSection
            }
            .navigationTitle("Rendering Settings")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(showAdvancedSettings ? "Hide Advanced" : "Show Advanced") {
                        withAnimation {
                            showAdvancedSettings.toggle()
                        }
                    }
                    .font(.caption)
                }
            }
        }
        .onAppear {
            checkMetalAvailability()
            updateDeviceInfo()
        }
    }
    
    // MARK: - Metal Rendering Section
    
    @ViewBuilder
    private var metalRenderingSection: some View {
        Section {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Professional Metal Rendering")
                        .font(.headline)
                    Text("High-performance GPU-accelerated card rendering")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Toggle("", isOn: $enableMetalRendering)
                    .disabled(!isMetalAvailable)
            }
            
            if !isMetalAvailable {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    Text("Metal rendering not available on this device")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            if enableMetalRendering && isMetalAvailable {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Metal Features Enabled:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    FeatureRow(
                        icon: "cube.transparent",
                        title: "3D Transformations",
                        description: "Hardware-accelerated 3D card movements"
                    )
                    
                    FeatureRow(
                        icon: "sparkles",
                        title: "Material Physics",
                        description: "Realistic surface properties and lighting"
                    )
                    
                    FeatureRow(
                        icon: "camera.filters",
                        title: "Advanced Shaders",
                        description: "Professional visual effects and shadows"
                    )
                    
                    FeatureRow(
                        icon: "paintbrush.pointed",
                        title: "Cultural Patterns",
                        description: "Authentic Romanian folk art textures"
                    )
                }
                .padding(.vertical, 8)
            }
        } header: {
            Text("Professional Rendering")
        } footer: {
            if enableMetalRendering {
                Text("Professional Metal rendering provides ShuffleCats-quality visual effects with optimized performance.")
            }
        }
    }
    
    // MARK: - Visual Quality Section
    
    @ViewBuilder
    private var visualQualitySection: some View {
        Section {
            VStack(alignment: .leading, spacing: 12) {
                Text("Render Quality")
                    .font(.headline)
                
                Picker("Quality", selection: $renderQuality) {
                    Text("Low").tag("low")
                    Text("Medium").tag("medium")
                    Text("High").tag("high")
                    Text("Ultra").tag("ultra")
                }
                .pickerStyle(.segmented)
                
                qualityDescriptionView
            }
            
            Toggle("Advanced Visual Effects", isOn: $enableAdvancedEffects)
            
            Toggle("ShuffleCats-Style Enhancements", isOn: $enableShuffleCatsEnhancements)
            
        } header: {
            Text("Visual Quality")
        } footer: {
            Text("Higher quality settings provide better visuals but may impact battery life.")
        }
    }
    
    @ViewBuilder
    private var qualityDescriptionView: some View {
        switch renderQuality {
        case "low":
            QualityDescriptionCard(
                title: "Low Quality",
                description: "Basic rendering, optimized for battery life",
                features: ["Simple textures", "Basic lighting", "60 FPS target"],
                color: .green
            )
        case "medium":
            QualityDescriptionCard(
                title: "Medium Quality",
                description: "Balanced performance and visual quality",
                features: ["Enhanced textures", "Improved lighting", "90 FPS target"],
                color: .orange
            )
        case "high":
            QualityDescriptionCard(
                title: "High Quality",
                description: "Premium visuals with excellent performance",
                features: ["High-res textures", "Advanced lighting", "120 FPS target"],
                color: .blue
            )
        case "ultra":
            QualityDescriptionCard(
                title: "Ultra Quality",
                description: "Maximum visual fidelity",
                features: ["4K textures", "Realistic lighting", "Variable refresh rate"],
                color: .purple
            )
        default:
            EmptyView()
        }
    }
    
    // MARK: - Cultural Effects Section
    
    @ViewBuilder
    private var culturalEffectsSection: some View {
        Section {
            Toggle("Romanian Cultural Effects", isOn: $enableRomanianCulturalEffects)
            
            if enableRomanianCulturalEffects {
                VStack(alignment: .leading, spacing: 8) {
                    CulturalFeatureRow(
                        icon: "paintbrush",
                        title: "Folk Art Patterns",
                        description: "Traditional Romanian motifs and borders"
                    )
                    
                    CulturalFeatureRow(
                        icon: "scissors",
                        title: "Embroidery Effects",
                        description: "Simulated traditional embroidery textures"
                    )
                    
                    CulturalFeatureRow(
                        icon: "star.circle",
                        title: "Cultural Animations",
                        description: "Authentic Romanian card ceremonial movements"
                    )
                    
                    CulturalFeatureRow(
                        icon: "crown",
                        title: "Gold Accents",
                        description: "Traditional Romanian gold leaf effects"
                    )
                }
                .padding(.vertical, 8)
            }
            
        } header: {
            Text("Cultural Authenticity")
        } footer: {
            Text("Romanian cultural effects preserve the authentic visual heritage of traditional Septica cards.")
        }
    }
    
    // MARK: - Performance Section
    
    @ViewBuilder
    private var performanceSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 12) {
                Text("Performance Mode")
                    .font(.headline)
                
                Picker("Performance", selection: $performanceMode) {
                    Text("Battery Saver").tag("battery")
                    Text("Balanced").tag("balanced")
                    Text("Performance").tag("performance")
                }
                .pickerStyle(.segmented)
                
                performanceModeDescriptionView
            }
            
        } header: {
            Text("Performance")
        } footer: {
            Text("Performance mode affects frame rate, visual quality, and battery usage.")
        }
    }
    
    @ViewBuilder
    private var performanceModeDescriptionView: some View {
        switch performanceMode {
        case "battery":
            PerformanceModeCard(
                title: "Battery Saver",
                description: "Optimized for maximum battery life",
                specs: ["30-60 FPS", "Reduced effects", "Lower GPU usage"],
                icon: "battery.100",
                color: .green
            )
        case "balanced":
            PerformanceModeCard(
                title: "Balanced",
                description: "Great performance with good battery life",
                specs: ["60-90 FPS", "All effects enabled", "Moderate GPU usage"],
                icon: "speedometer",
                color: .blue
            )
        case "performance":
            PerformanceModeCard(
                title: "Performance",
                description: "Maximum visual quality and frame rate",
                specs: ["90-120 FPS", "All effects maximized", "High GPU usage"],
                icon: "bolt.fill",
                color: .orange
            )
        default:
            EmptyView()
        }
    }
    
    // MARK: - Advanced Settings Section
    
    @ViewBuilder
    private var advancedSettingsSection: some View {
        Section {
            Button("Reset to Defaults") {
                resetToDefaults()
            }
            .foregroundColor(.red)
            
            Button("Clear Texture Cache") {
                clearTextureCache()
            }
            
            Button("Clear Geometry Cache") {
                clearGeometryCache()
            }
            
            NavigationLink("Shader Debugging") {
                ShaderDebuggingView()
            }
            
        } header: {
            Text("Advanced Settings")
        } footer: {
            Text("Advanced settings for developers and power users.")
        }
    }
    
    // MARK: - Device Information Section
    
    @ViewBuilder
    private var deviceInformationSection: some View {
        Section {
            InfoRow(title: "Device", value: deviceInfo)
            InfoRow(title: "GPU Memory", value: memoryInfo)
            InfoRow(title: "Metal Support", value: isMetalAvailable ? "Available" : "Not Available")
            InfoRow(title: "iOS Version", value: UIDevice.current.systemVersion)
            
        } header: {
            Text("Device Information")
        }
    }
    
    // MARK: - Helper Methods
    
    private func checkMetalAvailability() {
        isMetalAvailable = MTLCreateSystemDefaultDevice() != nil
    }
    
    private func updateDeviceInfo() {
        deviceInfo = UIDevice.current.model
        
        if let device = MTLCreateSystemDefaultDevice() {
            memoryInfo = "\(device.recommendedMaxWorkingSetSize / (1024 * 1024)) MB"
        } else {
            memoryInfo = "N/A"
        }
    }
    
    private func resetToDefaults() {
        enableMetalRendering = false
        renderQuality = "high"
        enableAdvancedEffects = true
        enableRomanianCulturalEffects = true
        enableShuffleCatsEnhancements = true
        performanceMode = "balanced"
    }
    
    private func clearTextureCache() {
        // Implementation would clear texture cache
        print("Texture cache cleared")
    }
    
    private func clearGeometryCache() {
        // Implementation would clear geometry cache
        print("Geometry cache cleared")
    }
}

// MARK: - Supporting Views

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                Text(description)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

struct CulturalFeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(RomanianColors.goldAccent)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                Text(description)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

struct QualityDescriptionCard: View {
    let title: String
    let description: String
    let features: [String]
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(color)
                
                Spacer()
            }
            
            Text(description)
                .font(.caption2)
                .foregroundColor(.secondary)
            
            VStack(alignment: .leading, spacing: 4) {
                ForEach(features, id: \.self) { feature in
                    HStack {
                        Circle()
                            .fill(color)
                            .frame(width: 4, height: 4)
                        Text(feature)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}

struct PerformanceModeCard: View {
    let title: String
    let description: String
    let specs: [String]
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.title2)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption)
                    .fontWeight(.semibold)
                
                Text(description)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                ForEach(specs, id: \.self) { spec in
                    Text("• \(spec)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

struct InfoRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
            Spacer()
            Text(value)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Shader Debugging View (Placeholder)

struct ShaderDebuggingView: View {
    var body: some View {
        VStack {
            Text("Shader Debugging")
                .font(.title)
            Text("Advanced shader debugging tools would go here")
                .foregroundColor(.secondary)
        }
        .navigationTitle("Shader Debug")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Preview

struct RenderingSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        RenderingSettingsView()
    }
}