//
//  NPCView.swift
//  Ping - Packet World
//  NPC characters with visual representation
//

import SwiftUI

struct NPCView: View {
    let npc: NPC
    let packetPosition: CGPoint
    
    @State private var hover: CGFloat = 0
    @State private var glow = false
    
    private var distance: CGFloat {
        sqrt(pow(npc.position.x - packetPosition.x, 2) + pow(npc.position.y - packetPosition.y, 2))
    }
    
    private var isNearby: Bool {
        distance < 120
    }
    
    var body: some View {
        ZStack {
            // Interaction radius indicator
            if isNearby && npc.isInteractable {
                Circle()
                    .stroke(Color.yellow.opacity(0.5), lineWidth: 2)
                    .frame(width: 100, height: 100)
                    .scaleEffect(glow ? 1.1 : 1.0)
            }
            
            // Shadow
            Ellipse()
                .fill(Color.black.opacity(0.3))
                .frame(width: 60, height: 15)
                .offset(y: 45)
                .blur(radius: 3)
            
            // NPC body based on type
            NPCBody(type: npc.type)
                .offset(y: hover)
            
            // Name label
            if isNearby {
                VStack {
                    Text(npc.name)
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(Color.black.opacity(0.7))
                        )
                }
                .offset(y: -60)
                .transition(.opacity)
            }
            
            // "Talk" prompt
            if isNearby && npc.isInteractable && !npc.hasSpoken {
                VStack {
                    HStack(spacing: 4) {
                        Image(systemName: "bubble.left.fill")
                        Text("TAP")
                    }
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundColor(.yellow)
                }
                .offset(y: -80)
                .transition(.scale.combined(with: .opacity))
            }
        }
        .position(npc.position)
        .animation(.easeInOut(duration: 0.3), value: isNearby)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                hover = -8
            }
            withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                glow = true
            }
        }
    }
}

// MARK: - NPC Body
struct NPCBody: View {
    let type: NPCType
    
    var body: some View {
        switch type {
        case .daemon:
            DaemonNPCView()
        case .firewall:
            FirewallNPCView()
        case .routerGuard:
            RouterGuardNPCView()
        case .librarian:
            LibrarianNPCView()
        case .networkManager:
            NetworkManagerNPCView()
        }
    }
}

// MARK: - Daemon NPC
struct DaemonNPCView: View {
    @State private var armRotation: Double = 0
    
    var body: some View {
        ZStack {
            // Body (robot-like)
            RoundedRectangle(cornerRadius: 10)
                .fill(
                    LinearGradient(
                        colors: [Color.gray, Color(red: 0.3, green: 0.3, blue: 0.35)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 50, height: 60)
            
            // Screen face
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.cyan.opacity(0.8))
                .frame(width: 40, height: 30)
                .offset(y: -8)
                .overlay(
                    // Digital eyes
                    HStack(spacing: 10) {
                        Rectangle().fill(Color.black).frame(width: 8, height: 4)
                        Rectangle().fill(Color.black).frame(width: 8, height: 4)
                    }
                    .offset(y: -8)
                )
            
            // Multiple arms (juggling tasks!)
            ForEach(0..<4, id: \.self) { i in
                Rectangle()
                    .fill(Color.gray)
                    .frame(width: 8, height: 25)
                    .offset(x: i < 2 ? -30 : 30, y: CGFloat(i % 2) * 15)
                    .rotationEffect(.degrees(armRotation + Double(i) * 45), anchor: i < 2 ? .trailing : .leading)
            }
            
            // Antenna
            VStack(spacing: 0) {
                Circle()
                    .fill(Color.red)
                    .frame(width: 8, height: 8)
                Rectangle()
                    .fill(Color.gray)
                    .frame(width: 3, height: 10)
            }
            .offset(y: -45)
        }
        .onAppear {
            withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                armRotation = 360
            }
        }
    }
}

// MARK: - Firewall NPC
struct FirewallNPCView: View {
    @State private var shieldGlow = false
    
    var body: some View {
        ZStack {
            // Shield body
            ShieldShape()
                .fill(
                    LinearGradient(
                        colors: [Color.orange, Color.red],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 60, height: 70)
                .shadow(color: shieldGlow ? .orange : .clear, radius: 15)
            
            // Face on shield
            VStack(spacing: 8) {
                HStack(spacing: 15) {
                    Circle().fill(Color.white).frame(width: 10, height: 10)
                    Circle().fill(Color.white).frame(width: 10, height: 10)
                }
                
                Rectangle()
                    .fill(Color.white)
                    .frame(width: 20, height: 4)
            }
            .offset(y: -5)
            
            // "SECURITY" badge
            Image(systemName: "shield.checkered")
                .font(.system(size: 20))
                .foregroundColor(.orange)
                .offset(y: -45)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1).repeatForever(autoreverses: true)) {
                shieldGlow = true
            }
        }
    }
}

struct ShieldShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + rect.height * 0.2))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        path.addQuadCurve(
            to: CGPoint(x: rect.midX, y: rect.maxY),
            control: CGPoint(x: rect.maxX, y: rect.maxY - rect.height * 0.2)
        )
        path.addQuadCurve(
            to: CGPoint(x: rect.minX, y: rect.midY),
            control: CGPoint(x: rect.minX, y: rect.maxY - rect.height * 0.2)
        )
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + rect.height * 0.2))
        path.closeSubpath()
        return path
    }
}

// MARK: - Router Guard NPC
struct RouterGuardNPCView: View {
    var body: some View {
        ZStack {
            // Body (uniformed character)
            VStack(spacing: 0) {
                // Head
                Circle()
                    .fill(Color(red: 0.9, green: 0.75, blue: 0.6))
                    .frame(width: 35, height: 35)
                    .overlay(
                        // Cap
                        VStack {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.blue)
                                .frame(width: 40, height: 12)
                                .offset(y: -12)
                        }
                    )
                    .overlay(
                        // Face
                        VStack(spacing: 4) {
                            HStack(spacing: 8) {
                                Circle().fill(.black).frame(width: 5, height: 5)
                                Circle().fill(.black).frame(width: 5, height: 5)
                            }
                            // Badge icon
                            Image(systemName: "shield.checkered")
                                .font(.system(size: 8))
                                .foregroundColor(.orange)
                        }
                    )
                
                // Uniform body
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.blue)
                    .frame(width: 40, height: 45)
                    .overlay(
                        // Badge
                        Circle()
                            .fill(Color.yellow)
                            .frame(width: 12, height: 12)
                            .offset(x: -10, y: -10)
                    )
            }
            
            // Directional signs
            HStack(spacing: 5) {
                Image(systemName: "arrow.left")
                Image(systemName: "arrow.right")
            }
            .font(.system(size: 10))
            .foregroundColor(.white)
            .offset(y: 50)
        }
    }
}

// MARK: - Librarian NPC
struct LibrarianNPCView: View {
    @State private var readingGlasses = false
    
    var body: some View {
        ZStack {
            // Body
            VStack(spacing: 0) {
                // Head
                Circle()
                    .fill(Color(red: 0.9, green: 0.8, blue: 0.7))
                    .frame(width: 35, height: 35)
                    .overlay(
                        // Hair bun
                        Circle()
                            .fill(Color.gray)
                            .frame(width: 20, height: 20)
                            .offset(y: -15)
                    )
                    .overlay(
                        // Glasses
                        HStack(spacing: 2) {
                            Circle()
                                .stroke(Color.brown, lineWidth: 2)
                                .frame(width: 12, height: 12)
                            Circle()
                                .stroke(Color.brown, lineWidth: 2)
                                .frame(width: 12, height: 12)
                        }
                        .offset(y: -2)
                        .scaleEffect(readingGlasses ? 1.1 : 1.0)
                    )
                    .overlay(
                        // Smile
                        Circle()
                            .trim(from: 0.1, to: 0.4)
                            .stroke(Color.brown, lineWidth: 2)
                            .frame(width: 12, height: 12)
                            .rotationEffect(.degrees(180))
                            .offset(y: 8)
                    )
                
                // Robe/dress
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.purple.opacity(0.7))
                    .frame(width: 45, height: 50)
            }
            
            // Holding a book
            RoundedRectangle(cornerRadius: 3)
                .fill(Color.brown)
                .frame(width: 25, height: 30)
                .offset(x: 30, y: 10)
                .rotationEffect(.degrees(-15))
            
            // Floating books
            ForEach(0..<3, id: \.self) { i in
                Image(systemName: "book.closed.fill")
                    .font(.system(size: 13))
                    .foregroundColor(.purple.opacity(0.5))
                    .offset(
                        x: CGFloat([-40, 35, 0][i]),
                        y: CGFloat([-40, -35, -55][i])
                    )
                    .opacity(0.6)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                readingGlasses = true
            }
        }
    }
}

// MARK: - Network Manager NPC
struct NetworkManagerNPCView: View {
    @State private var controlsMoving = false
    
    var body: some View {
        ZStack {
            // Control panel body
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    LinearGradient(
                        colors: [Color(red: 0.2, green: 0.2, blue: 0.25), Color(red: 0.1, green: 0.1, blue: 0.15)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 70, height: 80)
            
            // Screen with face
            VStack(spacing: 4) {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.green.opacity(0.8))
                    .frame(width: 55, height: 35)
                    .overlay(
                        // Digital face
                        VStack(spacing: 4) {
                            HStack(spacing: 12) {
                                Text(">").font(.system(size: 12, design: .monospaced))
                                Text("<").font(.system(size: 12, design: .monospaced))
                            }
                            .foregroundColor(.black)
                            
                            // Scrolling data
                            Text("01101")
                                .font(.system(size: 8, design: .monospaced))
                                .foregroundColor(.black.opacity(0.6))
                        }
                    )
                
                // Control buttons
                HStack(spacing: 6) {
                    ForEach(0..<4, id: \.self) { i in
                        Circle()
                            .fill([Color.red, Color.yellow, Color.green, Color.blue][i])
                            .frame(width: 10, height: 10)
                            .opacity(controlsMoving && i % 2 == 0 ? 1.0 : 0.5)
                    }
                }
            }
            
            // Wires coming out
            ForEach(0..<3, id: \.self) { i in
                Rectangle()
                    .fill([Color.red, Color.yellow, Color.green][i])
                    .frame(width: 3, height: 30)
                    .offset(x: CGFloat(i - 1) * 15, y: 55)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) {
                controlsMoving = true
            }
        }
    }
}

#Preview {
    ZStack {
        Color.black
        
        VStack(spacing: 80) {
            HStack(spacing: 80) {
                DaemonNPCView()
                FirewallNPCView()
                RouterGuardNPCView()
            }
            
            HStack(spacing: 80) {
                LibrarianNPCView()
                NetworkManagerNPCView()
            }
        }
    }
}
