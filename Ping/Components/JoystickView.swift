//
//  JoystickView.swift
//  Ping - Packet World
//
//  Virtual joystick for player movement
//

import SwiftUI

struct JoystickView: View {
    /// Called continuously with a normalized direction vector (magnitude 0–1).
    /// Returns .zero when the player releases the stick.
    var onDirectionChanged: (CGVector) -> Void

    private let baseRadius: CGFloat = 60 // Slightly larger for easier iPad tapping
    private let knobRadius: CGFloat = 25

    @State private var dragOffset: CGSize = .zero
    @State private var hasHitEdge: Bool = false // Tracks haptic state
    
    // Local haptic generator for the joystick "bump"
    private let hapticFeedback = UIImpactFeedbackGenerator(style: .rigid)

    var body: some View {
        ZStack {
            // Base circle (Glassmorphism Cyberpunk style)
            Circle()
                .fill(Color.black.opacity(0.4))
                .frame(width: baseRadius * 2, height: baseRadius * 2)
                .overlay(
                    Circle()
                        .stroke(Color.cyan.opacity(0.5), lineWidth: 2)
                        .shadow(color: .cyan.opacity(0.5), radius: 5)
                )

            // Knob (Glowing Orb)
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.cyan.opacity(0.9), Color.blue.opacity(0.6)],
                        center: .center,
                        startRadius: 0,
                        endRadius: knobRadius
                    )
                )
                .frame(width: knobRadius * 2, height: knobRadius * 2)
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.5), lineWidth: 1)
                )
                .shadow(color: .cyan, radius: hasHitEdge ? 10 : 3) // Glows brighter when pushed
                .offset(dragOffset)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Movement joystick")
        .accessibilityHint("Drag to move your packet character")
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    let translation = value.translation
                    let distance = sqrt(translation.width * translation.width + translation.height * translation.height)
                    let maxDistance = baseRadius - knobRadius / 2

                    if distance <= maxDistance {
                        dragOffset = translation
                        hasHitEdge = false
                    } else {
                        // Clamp to circle boundary
                        let ratio = maxDistance / distance
                        dragOffset = CGSize(
                            width: translation.width * ratio,
                            height: translation.height * ratio
                        )
                        
                        // Trigger haptic bump ONLY once when hitting the edge
                        if !hasHitEdge {
                            hapticFeedback.impactOccurred()
                            hasHitEdge = true
                        }
                    }

                    // Normalize to 0–1 magnitude
                    let clampedDistance = min(distance, maxDistance)
                    let magnitude = clampedDistance / maxDistance
                    let angle = atan2(translation.height, translation.width)

                    onDirectionChanged(CGVector(
                        dx: cos(angle) * magnitude,
                        dy: sin(angle) * magnitude
                    ))
                }
                .onEnded { _ in
                    // Snap back to center with a spring
                    withAnimation(.interactiveSpring(response: 0.25, dampingFraction: 0.6)) {
                        dragOffset = .zero
                    }
                    hasHitEdge = false
                    onDirectionChanged(.zero)
                    
                    // Light haptic when returning to center
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                }
        )
    }
}

#Preview {
    ZStack {
        Color(red: 0.04, green: 0.02, blue: 0.08).edgesIgnoringSafeArea(.all)
        JoystickView { direction in
            // print("Direction: \(direction)")
        }
    }
}
