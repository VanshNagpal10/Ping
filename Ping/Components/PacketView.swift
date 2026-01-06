//
//  PacketView.swift
//  Ping
//
//  The player's packet visual with glow and shield effects
//

import SwiftUI

struct PacketView: View {
    let packet: PacketState
    let isThrusting: Bool
    
    var body: some View {
        ZStack {
            // Outer glow
            Circle()
                .fill(glowColor.opacity(0.3))
                .frame(width: packet.effectiveSize * 1.8, height: packet.effectiveSize * 1.8)
                .blur(radius: 15)
            
            // Middle glow pulse
            Circle()
                .fill(glowColor.opacity(0.5))
                .frame(width: packet.effectiveSize * 1.4, height: packet.effectiveSize * 1.4)
                .blur(radius: 8)
                .scaleEffect(isThrusting ? 1.2 : 1.0)
                .animation(.easeInOut(duration: 0.15), value: isThrusting)
            
            // Shield ring (HTTPS)
            if packet.protocolMode == .https {
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [.yellow, .orange, .yellow],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 4
                    )
                    .frame(width: packet.effectiveSize * 1.3, height: packet.effectiveSize * 1.3)
                    .shadow(color: .orange, radius: 8)
                
                // Lock icon
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: packet.effectiveSize * 0.3))
                    .foregroundColor(.yellow)
                    .offset(x: packet.effectiveSize * 0.5, y: -packet.effectiveSize * 0.5)
            }
            
            // Core packet
            Circle()
                .fill(
                    RadialGradient(
                        colors: [.white, coreColor, coreColor.opacity(0.8)],
                        center: .center,
                        startRadius: 0,
                        endRadius: packet.effectiveSize / 2
                    )
                )
                .frame(width: packet.effectiveSize, height: packet.effectiveSize)
            
            // Inner shine
            Circle()
                .fill(
                    LinearGradient(
                        colors: [.white.opacity(0.8), .clear],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: packet.effectiveSize * 0.6, height: packet.effectiveSize * 0.6)
                .offset(x: -packet.effectiveSize * 0.15, y: -packet.effectiveSize * 0.15)
            
            // Payload indicator
            if packet.isCarryingPayload {
                Image(systemName: "photo.fill")
                    .font(.system(size: packet.effectiveSize * 0.4))
                    .foregroundColor(.white)
            } else {
                // Data bits animation
                Image(systemName: "arrow.right")
                    .font(.system(size: packet.effectiveSize * 0.35, weight: .bold))
                    .foregroundColor(.white.opacity(0.9))
            }
            
            // Thrust particles
            if isThrusting {
                ThrustParticles(size: packet.effectiveSize)
                    .offset(y: packet.effectiveSize * 0.6)
            }
        }
        .position(x: packet.x, y: packet.y)
    }
    
    private var coreColor: Color {
        packet.isCarryingPayload ? .orange : .cyan
    }
    
    private var glowColor: Color {
        if packet.protocolMode == .https {
            return .yellow
        }
        return packet.isCarryingPayload ? .orange : .cyan
    }
}

// MARK: - Thrust Particles
struct ThrustParticles: View {
    let size: CGFloat
    @State private var animate = false
    
    var body: some View {
        ZStack {
            ForEach(0..<5) { i in
                Circle()
                    .fill(Color.orange.opacity(0.7))
                    .frame(width: size * 0.15, height: size * 0.15)
                    .offset(
                        x: CGFloat.random(in: -size*0.3...size*0.3),
                        y: animate ? CGFloat.random(in: size*0.3...size*0.8) : 0
                    )
                    .opacity(animate ? 0 : 1)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.3).repeatForever(autoreverses: false)) {
                animate = true
            }
        }
    }
}

#Preview {
    ZStack {
        Color.black
        PacketView(
            packet: PacketState(x: 200, y: 200, protocolMode: .https),
            isThrusting: true
        )
    }
}
