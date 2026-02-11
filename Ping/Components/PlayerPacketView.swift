//
//  PlayerPacketView.swift
//  Ping - Packet World
//
//  The cute packet character with face and layer equipment
//

import SwiftUI

struct PlayerPacketView: View {
    let packet: PacketState
    let isMoving: Bool
    
    @State private var bounce: CGFloat = 0
    @State private var wobble: Double = 0
    
    var body: some View {
        ZStack {
            // Shadow
            Ellipse()
                .fill(Color.black.opacity(0.3))
                .frame(width: 50, height: 15)
                .offset(y: 35)
                .blur(radius: 3)
            
            // Main packet body
            ZStack {
                // Glow effect
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [packet.layers.applicationLayer.color.opacity(0.5), Color.clear],
                            center: .center,
                            startRadius: 20,
                            endRadius: 50
                        )
                    )
                    .frame(width: 100, height: 100)
                
                // Packet body (geometric cube-ish shape)
                PacketBody(layers: packet.layers)
                
                // Face
                PacketFace(mood: packet.mood, direction: packet.facingDirection)
                
                // Equipment indicators
                EquipmentBadges(layers: packet.layers)
            }
            .offset(y: bounce)
            .rotationEffect(.degrees(wobble))
        }
        .position(packet.position)
        .onAppear {
            startIdleAnimation()
        }
        .onChange(of: isMoving) { _, moving in
            if moving {
                startMovingAnimation()
            } else {
                startIdleAnimation()
            }
        }
    }
    
    private func startIdleAnimation() {
        withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
            bounce = -5
        }
        withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
            wobble = 3
        }
    }
    
    private func startMovingAnimation() {
        withAnimation(.easeInOut(duration: 0.2).repeatForever(autoreverses: true)) {
            bounce = -10
        }
        withAnimation(.easeInOut(duration: 0.3).repeatForever(autoreverses: true)) {
            wobble = 8
        }
    }
}

// MARK: - Packet Body
struct PacketBody: View {
    let layers: PacketLayers
    
    var body: some View {
        ZStack {
            // Base shape (rounded square - like a cute box)
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.3, green: 0.8, blue: 0.9),
                            Color(red: 0.2, green: 0.6, blue: 0.8)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 55, height: 55)
            
            // Shine highlight
            RoundedRectangle(cornerRadius: 10)
                .fill(
                    LinearGradient(
                        colors: [Color.white.opacity(0.5), Color.clear],
                        startPoint: .topLeading,
                        endPoint: .center
                    )
                )
                .frame(width: 50, height: 50)
            
            // Protocol indicator ring
            RoundedRectangle(cornerRadius: 14)
                .stroke(layers.transportLayer.color, lineWidth: 3)
                .frame(width: 60, height: 60)
        }
    }
}

// MARK: - Packet Face
struct PacketFace: View {
    let mood: PacketMood
    let direction: PacketState.Direction
    
    var body: some View {
        VStack(spacing: 6) {
            // Eyes
            HStack(spacing: 12) {
                PacketEye(looking: direction)
                PacketEye(looking: direction)
            }
            
            // Mouth based on mood
            MouthView(mood: mood)
        }
        .offset(y: -2)
    }
}

struct PacketEye: View {
    let looking: PacketState.Direction
    
    var eyeOffset: CGPoint {
        switch looking {
        case .left: return CGPoint(x: -2, y: 0)
        case .right: return CGPoint(x: 2, y: 0)
        case .up: return CGPoint(x: 0, y: -2)
        case .down: return CGPoint(x: 0, y: 2)
        }
    }
    
    var body: some View {
        ZStack {
            // Eye white
            Ellipse()
                .fill(Color.white)
                .frame(width: 12, height: 14)
            
            // Pupil
            Circle()
                .fill(Color.black)
                .frame(width: 6, height: 6)
                .offset(x: eyeOffset.x, y: eyeOffset.y)
            
            // Eye shine
            Circle()
                .fill(Color.white)
                .frame(width: 3, height: 3)
                .offset(x: 2, y: -2)
        }
    }
}

struct MouthView: View {
    let mood: PacketMood
    
    var body: some View {
        switch mood {
        case .neutral:
            Capsule()
                .fill(Color(red: 0.3, green: 0.2, blue: 0.2))
                .frame(width: 12, height: 5)
        case .happy:
            HappyMouth()
        case .worried:
            WorriedMouth()
        case .excited:
            ExcitedMouth()
        case .confused:
            ConfusedMouth()
        case .determined:
            DeterminedMouth()
        }
    }
}

struct HappyMouth: View {
    var body: some View {
        ZStack {
            // Smile curve
            Circle()
                .trim(from: 0.1, to: 0.4)
                .stroke(Color(red: 0.3, green: 0.2, blue: 0.2), lineWidth: 3)
                .frame(width: 20, height: 20)
                .rotationEffect(.degrees(180))
        }
    }
}

struct WorriedMouth: View {
    var body: some View {
        Circle()
            .trim(from: 0.6, to: 0.9)
            .stroke(Color(red: 0.3, green: 0.2, blue: 0.2), lineWidth: 3)
            .frame(width: 15, height: 15)
            .rotationEffect(.degrees(180))
    }
}

struct ExcitedMouth: View {
    var body: some View {
        Ellipse()
            .fill(Color(red: 0.3, green: 0.2, blue: 0.2))
            .frame(width: 14, height: 10)
    }
}

struct ConfusedMouth: View {
    var body: some View {
        Path { path in
            path.move(to: CGPoint(x: 0, y: 5))
            path.addQuadCurve(to: CGPoint(x: 15, y: 0), control: CGPoint(x: 7, y: 8))
        }
        .stroke(Color(red: 0.3, green: 0.2, blue: 0.2), lineWidth: 3)
        .frame(width: 15, height: 10)
    }
}

struct DeterminedMouth: View {
    var body: some View {
        Rectangle()
            .fill(Color(red: 0.3, green: 0.2, blue: 0.2))
            .frame(width: 14, height: 4)
    }
}

// MARK: - Equipment Badges
struct EquipmentBadges: View {
    let layers: PacketLayers
    
    var body: some View {
        VStack {
            // Hat (Network Layer) - IP address
            HStack(spacing: 2) {
                Image(systemName: "network")
                    .font(.system(size: 8))
            }
            .foregroundColor(.yellow)
            .padding(4)
            .background(Circle().fill(Color.black.opacity(0.6)))
            .offset(y: -35)
            
            Spacer()
        }
        .frame(height: 80)
        
        // Backpack indicator (Application Layer)
        if layers.applicationLayer != .empty {
            HStack {
                Spacer()
                
                Image(systemName: layers.applicationLayer.icon)
                    .font(.system(size: 10))
                    .foregroundColor(.white)
                    .padding(5)
                    .background(Circle().fill(layers.applicationLayer.color))
                    .offset(x: 25, y: 10)
            }
        }
        
        // Protocol badge (Transport Layer)
        HStack {
            Image(systemName: layers.transportLayer.icon)
                .font(.system(size: 8))
                .foregroundColor(.white)
                .padding(4)
                .background(Circle().fill(layers.transportLayer.color))
                .offset(x: -25, y: 10)
            
            Spacer()
        }
    }
}

#Preview {
    ZStack {
        Color.black
        PlayerPacketView(
            packet: PacketState(
                position: CGPoint(x: 200, y: 200),
                layers: PacketLayers(applicationLayer: .dnsQuery)
            ),
            isMoving: false
        )
    }
}
