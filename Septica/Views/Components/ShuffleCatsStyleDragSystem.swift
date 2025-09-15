//
//  ShuffleCatsStyleDragSystem.swift
//  Septica
//
//  Enhanced drag-and-drop system inspired by Shuffle Cats
//  Features ghost cards, magnetic snapping, and smooth animations
//

import SwiftUI
import Observation

/// Enhanced drag coordinator for Shuffle Cats-style interactions
@Observable
class ShuffleCatsDragCoordinator: ObservableObject {
    
    // MARK: - Drag State
    
    @Published var isDragActive = false
    @Published var draggedCard: Card?
    @Published var dragPosition = CGPoint.zero
    @Published var ghostCardPosition = CGPoint.zero
    @Published var isValidDropZone = false
    @Published var activeDropZone: DropZoneInfo?
    @Published var dropZones: [DropZoneInfo] = []
    
    // MARK: - Animation State
    
    @Published var showGhostCard = false
    @Published var ghostCardOpacity: Double = 0.0
    @Published var magneticSnappingActive = false
    @Published var snapTargetPosition = CGPoint.zero
    
    // MARK: - Drag Configuration
    
    private let magneticSnapDistance: CGFloat = 80.0
    private let ghostCardOpacityActive: Double = 0.6
    private let snapAnimationDuration: Double = 0.3
    
    // MARK: - Public Methods
    
    /// Start dragging a card with Shuffle Cats-style visual feedback
    func startDrag(card: Card, at position: CGPoint) {
        guard !isDragActive else { return }
        
        draggedCard = card
        isDragActive = true
        dragPosition = position
        ghostCardPosition = position
        showGhostCard = true
        
        // Animate ghost card appearance
        withAnimation(.easeOut(duration: 0.2)) {
            ghostCardOpacity = ghostCardOpacityActive
        }
        
        updateDropZoneStates(dragPosition: position)
    }
    
    /// Update drag position and handle magnetic snapping
    func updateDrag(position: CGPoint) {
        guard isDragActive else { return }
        
        dragPosition = position
        
        // Check for magnetic snapping to valid drop zones
        if let nearestZone = findNearestDropZone(to: position) {
            let distance = distanceBetween(position, nearestZone.center)
            
            if distance <= magneticSnapDistance && nearestZone.isValid {
                // Magnetic snapping to drop zone
                if !magneticSnappingActive {
                    magneticSnappingActive = true
                    snapTargetPosition = nearestZone.center
                    
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        ghostCardPosition = nearestZone.center
                    }
                    
                    // Provide haptic feedback for snapping
                    let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                    impactFeedback.impactOccurred()
                }
                
                activeDropZone = nearestZone
                isValidDropZone = true
                
            } else {
                // Outside snap distance
                if magneticSnappingActive {
                    magneticSnappingActive = false
                    
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        ghostCardPosition = position
                    }
                }
                
                ghostCardPosition = position
                activeDropZone = nil
                isValidDropZone = false
            }
        } else {
            // No nearby drop zones
            ghostCardPosition = position
            magneticSnappingActive = false
            activeDropZone = nil
            isValidDropZone = false
        }
        
        updateDropZoneStates(dragPosition: position)
    }
    
    /// End drag interaction with smooth animations
    func endDrag(at position: CGPoint) -> DropZoneInfo? {
        guard isDragActive else { return nil }
        
        let selectedZone = activeDropZone
        let wasValidDrop = isValidDropZone && selectedZone != nil
        
        // Animate ghost card disappearance
        if wasValidDrop {
            // Successful drop - animate to final position
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                ghostCardOpacity = 0.0
                if let zone = selectedZone {
                    ghostCardPosition = zone.center
                }
            }
        } else {
            // Failed drop - animate back to hand
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                ghostCardOpacity = 0.0
                ghostCardPosition = CGPoint(x: 0, y: 200) // Back to hand area
            }
        }
        
        // Reset state after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.resetDragState()
        }
        
        return wasValidDrop ? selectedZone : nil
    }
    
    /// Cancel drag and return card to hand
    func cancelDrag() {
        guard isDragActive else { return }
        
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
            ghostCardOpacity = 0.0
            ghostCardPosition = CGPoint(x: 0, y: 200) // Back to hand
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.resetDragState()
        }
    }
    
    /// Configure available drop zones
    func setDropZones(_ zones: [DropZoneInfo]) {
        dropZones = zones
    }
    
    // MARK: - Private Methods
    
    private func resetDragState() {
        isDragActive = false
        draggedCard = nil
        dragPosition = .zero
        ghostCardPosition = .zero
        showGhostCard = false
        ghostCardOpacity = 0.0
        magneticSnappingActive = false
        snapTargetPosition = .zero
        activeDropZone = nil
        isValidDropZone = false
    }
    
    private func findNearestDropZone(to position: CGPoint) -> DropZoneInfo? {
        guard !dropZones.isEmpty else { return nil }
        
        return dropZones
            .filter { $0.isActive }
            .min { zone1, zone2 in
                let distance1 = distanceBetween(position, zone1.center)
                let distance2 = distanceBetween(position, zone2.center)
                return distance1 < distance2
            }
    }
    
    private func distanceBetween(_ point1: CGPoint, _ point2: CGPoint) -> CGFloat {
        let dx = point1.x - point2.x
        let dy = point1.y - point2.y
        return sqrt(dx * dx + dy * dy)
    }
    
    private func updateDropZoneStates(dragPosition: CGPoint) {
        // Update the visual state of all drop zones based on current drag position
        for i in dropZones.indices {
            let distance = distanceBetween(dragPosition, dropZones[i].center)
            dropZones[i].isHighlighted = distance <= magneticSnapDistance * 1.5
        }
    }
}

/// Drop zone information for enhanced drag system
struct DropZoneInfo: Identifiable, Equatable {
    let id = UUID()
    let center: CGPoint
    let size: CGSize
    let type: DropZoneType
    let isValid: Bool
    let isActive: Bool
    var isHighlighted: Bool = false
    
    static func == (lhs: DropZoneInfo, rhs: DropZoneInfo) -> Bool {
        return lhs.id == rhs.id
    }
}

/// Enhanced ghost card view for Shuffle Cats-style drag feedback
struct GhostCardView: View {
    let card: Card
    let position: CGPoint
    let opacity: Double
    let isSnapping: Bool
    
    var body: some View {
        CardView(
            card: card,
            isSelected: false,
            isPlayable: true,
            cardSize: .normal
        )
        .opacity(opacity)
        .scaleEffect(isSnapping ? 1.1 : 0.95)
        .rotationEffect(.degrees(isSnapping ? 0 : 5))
        .shadow(
            color: .white.opacity(isSnapping ? 0.8 : 0.4), 
            radius: isSnapping ? 15 : 8,
            x: 0, 
            y: isSnapping ? 8 : 4
        )
        .position(position)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isSnapping)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: position)
        .allowsHitTesting(false) // Ghost card shouldn't intercept touches
    }
}

/// Enhanced drop zone with Shuffle Cats-style magnetic feedback
struct EnhancedDropZoneView: View {
    let zone: DropZoneInfo
    let coordinator: ShuffleCatsDragCoordinator
    
    @State private var pulseAnimation = false
    @State private var magneticGlow = false
    
    var body: some View {
        DropZoneView(
            isHighlighted: zone.isHighlighted || magneticGlow,
            isValidDrop: zone.isValid,
            zone: zone.type
        )
        .scaleEffect(magneticGlow ? 1.15 : (zone.isHighlighted ? 1.05 : 1.0))
        .shadow(
            color: zone.isValid ? RomanianColors.countrysideGreen.opacity(magneticGlow ? 0.8 : 0.4) : 
                                   RomanianColors.primaryRed.opacity(magneticGlow ? 0.8 : 0.4),
            radius: magneticGlow ? 20 : (zone.isHighlighted ? 12 : 4),
            x: 0,
            y: magneticGlow ? 10 : (zone.isHighlighted ? 6 : 2)
        )
        .overlay(
            // Magnetic attraction effect
            Circle()
                .stroke(
                    zone.isValid ? RomanianColors.countrysideGreen : RomanianColors.primaryRed,
                    lineWidth: magneticGlow ? 3 : 0
                )
                .scaleEffect(pulseAnimation ? 1.3 : 1.0)
                .opacity(pulseAnimation ? 0.0 : 0.8)
                .animation(
                    .easeOut(duration: 1.5).repeatForever(autoreverses: false),
                    value: pulseAnimation
                )
        )
        .position(zone.center)
        .frame(width: zone.size.width, height: zone.size.height)
        .onChange(of: coordinator.activeDropZone?.id) { _, newActiveZoneId in
            let isActive = newActiveZoneId == zone.id
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                magneticGlow = isActive && coordinator.magneticSnappingActive
            }
            
            if isActive && coordinator.magneticSnappingActive {
                pulseAnimation = true
                // Play magnetic snap audio
                // AudioManager.shared.playSound(.magneticSnap)
            } else {
                pulseAnimation = false
            }
        }
    }
}

/// Trail effect for dragged cards (Shuffle Cats style)
struct DragTrailView: View {
    let positions: [CGPoint]
    let opacity: Double
    
    var body: some View {
        ZStack {
            ForEach(positions.indices.reversed(), id: \.self) { index in
                if index < positions.count {
                    Circle()
                        .fill(RomanianColors.primaryYellow.opacity(opacity * Double(index + 1) / Double(positions.count)))
                        .frame(width: 8, height: 8)
                        .position(positions[index])
                        .animation(.easeOut(duration: 0.3), value: positions[index])
                }
            }
        }
    }
}
