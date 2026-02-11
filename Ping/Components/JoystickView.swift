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

    private let baseRadius: CGFloat = 50
    private let knobRadius: CGFloat = 22

    @State private var dragOffset: CGSize = .zero

    var body: some View {
        ZStack {
            // Base circle
            Circle()
                .fill(Color.white.opacity(0.08))
                .frame(width: baseRadius * 2, height: baseRadius * 2)
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.25), lineWidth: 2)
                )

            // Knob
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.white.opacity(0.5), Color.white.opacity(0.2)],
                        center: .center,
                        startRadius: 0,
                        endRadius: knobRadius
                    )
                )
                .frame(width: knobRadius * 2, height: knobRadius * 2)
                .offset(dragOffset)
        }
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    let translation = value.translation
                    let distance = sqrt(translation.width * translation.width + translation.height * translation.height)
                    let maxDistance = baseRadius - knobRadius / 2

                    if distance <= maxDistance {
                        dragOffset = translation
                    } else {
                        // Clamp to circle boundary
                        let ratio = maxDistance / distance
                        dragOffset = CGSize(
                            width: translation.width * ratio,
                            height: translation.height * ratio
                        )
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
                    withAnimation(.easeOut(duration: 0.15)) {
                        dragOffset = .zero
                    }
                    onDirectionChanged(.zero)
                }
        )
    }
}

#Preview {
    ZStack {
        Color.black
        JoystickView { direction in
            print("Direction: \(direction)")
        }
    }
}
