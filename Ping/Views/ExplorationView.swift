//
//  ExplorationView.swift
//  Ping - Packet World
//
//  Main top-down exploration gameplay view
//

import SwiftUI

struct ExplorationView: View {
    @ObservedObject var engine: GameEngine
    @State private var showControls = true
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Scene background
                SceneBackground(scene: engine.currentScene, size: geo.size)
                
                // Interactive objects (portals, terminals)
                ForEach(engine.interactiveObjects) { obj in
                    InteractiveObjectView(object: obj)
                }
                
                // NPCs
                ForEach(engine.npcs) { npc in
                    NPCView(npc: npc, packetPosition: engine.packet.position)
                }
                
                // Player packet
                PlayerPacketView(
                    packet: engine.packet,
                    isMoving: engine.packet.isMoving
                )
                
                // Top HUD
                ExplorationHUD(
                    scene: engine.currentScene,
                    mission: engine.currentMission,
                    termsCount: engine.learnedTerms.count,
                    onEncyclopedia: { engine.showEncyclopedia = true },
                    onInventory: { engine.showLayerInventory.toggle() }
                )
                
                // Dialogue overlay
                if engine.isDialogueActive {
                    DialogueOverlay(engine: engine)
                }
                
                // Layer inventory panel
                if engine.showLayerInventory {
                    LayerInventoryPanel(
                        layers: engine.packet.layers,
                        onClose: { engine.showLayerInventory = false }
                    )
                    .transition(.move(edge: .leading))
                }
                
                // Touch to move hint
                if showControls && !engine.isDialogueActive {
                    VStack {
                        Spacer()

                        HStack {
                            Image(systemName: "arrow.up.and.down.and.arrow.left.and.right")
                            Text("Use the joystick to move")
                        }
                        .font(.system(size: 12, design: .rounded))
                        .foregroundColor(.white.opacity(0.6))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Capsule().fill(Color.black.opacity(0.4)))
                        .padding(.bottom, 30)
                    }
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                            withAnimation {
                                showControls = false
                            }
                        }
                    }
                }

                // Joystick (bottom-left corner)
                if !engine.isDialogueActive {
                    VStack {
                        Spacer()
                        HStack {
                            JoystickView { direction in
                                engine.updatePlayerDirection(direction)
                            }
                            .padding(.leading, 40)
                            .padding(.bottom, 30)
                            Spacer()
                        }
                    }
                }
            }
            .contentShape(Rectangle())
            .onTapGesture { location in
                if engine.isDialogueActive {
                    engine.advanceDialogue()
                }
            }
            .onAppear {
                engine.setScreenSize(geo.size)
                engine.setupSceneContent(for: engine.currentScene)
            }
        }
    }
}

// MARK: - Scene Background
struct SceneBackground: View {
    let scene: StoryScene
    let size: CGSize
    
    var body: some View {
        ZStack {
            // Base gradient
            LinearGradient(
                colors: [scene.backgroundColor, scene.backgroundColor.opacity(0.8)],
                startPoint: .top,
                endPoint: .bottom
            )
            
            // Scene-specific elements
            switch scene {
            case .cpuCity:
                CPUCityBackground(size: size)
            case .wifiAntenna:
                WiFiAntennaBackground(size: size)
            case .routerStation:
                RouterStationBackground(size: size)
            case .oceanCable:
                OceanCableBackground(size: size)
            case .dnsLibrary:
                DNSLibraryBackground(size: size)
            case .returnJourney:
                ReturnJourneyBackground(size: size)
            default:
                EmptyView()
            }
            
            // Grid overlay for digital feel
            DigitalGrid(color: scene.accentColor)
        }
        .ignoresSafeArea()
    }
}

// MARK: - CPU City Background
struct CPUCityBackground: View {
    let size: CGSize
    @State private var pulse = false
    
    var body: some View {
        ZStack {
            // Neon city glow
            RadialGradient(
                colors: [Color.cyan.opacity(0.2), Color.clear],
                center: .center,
                startRadius: 0,
                endRadius: size.width * 0.6
            )
            
            // Circuit board patterns
            ForEach(0..<8, id: \.self) { i in
                Rectangle()
                    .fill(Color.cyan.opacity(0.1))
                    .frame(width: 2, height: size.height)
                    .position(x: CGFloat(i) * (size.width / 7), y: size.height / 2)
            }
            
            ForEach(0..<6, id: \.self) { i in
                Rectangle()
                    .fill(Color.cyan.opacity(0.1))
                    .frame(width: size.width, height: 2)
                    .position(x: size.width / 2, y: CGFloat(i) * (size.height / 5))
            }
            
            // CPU chips (buildings)
            ForEach(0..<5, id: \.self) { i in
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 60, height: 80)
                    .overlay(
                        VStack(spacing: 4) {
                            ForEach(0..<4, id: \.self) { _ in
                                HStack(spacing: 4) {
                                    ForEach(0..<3, id: \.self) { _ in
                                        Rectangle()
                                            .fill(Color.cyan.opacity(pulse ? 0.8 : 0.3))
                                            .frame(width: 8, height: 8)
                                    }
                                }
                            }
                        }
                    )
                    .position(
                        x: CGFloat(80 + i * 150),
                        y: CGFloat([100, 180, 120, 200, 140][i])
                    )
            }
            
            // "CPU CITY" sign
            Text("CPU CITY")
                .font(.system(size: 24, weight: .bold, design: .monospaced))
                .foregroundColor(.cyan.opacity(0.6))
                .position(x: size.width / 2, y: 40)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1).repeatForever(autoreverses: true)) {
                pulse = true
            }
        }
    }
}

// MARK: - WiFi Antenna Background
struct WiFiAntennaBackground: View {
    let size: CGSize
    @State private var waveScale: CGFloat = 1.0
    
    var body: some View {
        ZStack {
            // Sky gradient
            LinearGradient(
                colors: [Color.blue.opacity(0.3), Color.purple.opacity(0.2)],
                startPoint: .top,
                endPoint: .bottom
            )
            
            // Antenna tower
            VStack(spacing: 0) {
                // Antenna tip
                Triangle()
                    .fill(Color.gray)
                    .frame(width: 30, height: 40)
                
                // Tower body
                Rectangle()
                    .fill(Color.gray.opacity(0.8))
                    .frame(width: 20, height: 200)
            }
            .position(x: size.width * 0.3, y: size.height * 0.5)
            
            // WiFi waves
            ForEach(0..<4, id: \.self) { i in
                Circle()
                    .stroke(Color.green.opacity(0.5 - Double(i) * 0.1), lineWidth: 3)
                    .frame(width: CGFloat(60 + i * 50), height: CGFloat(60 + i * 50))
                    .scaleEffect(waveScale)
                    .position(x: size.width * 0.3, y: size.height * 0.35)
            }
            
            Text("📡 Wi-Fi Antenna")
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundColor(.green)
                .position(x: size.width / 2, y: 40)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                waveScale = 1.3
            }
        }
    }
}

// MARK: - Router Station Background
struct RouterStationBackground: View {
    let size: CGSize
    
    var body: some View {
        ZStack {
            // Subway station feel
            Rectangle()
                .fill(Color.orange.opacity(0.1))
            
            // Platform lines
            ForEach(0..<4, id: \.self) { i in
                Rectangle()
                    .fill(Color.orange.opacity(0.3))
                    .frame(width: size.width, height: 4)
                    .position(x: size.width / 2, y: size.height * CGFloat(0.3 + Double(i) * 0.15))
            }
            
            // Direction signs
            HStack(spacing: 60) {
                DirectionSign(text: "← BACKBONE", color: .blue)
                DirectionSign(text: "LOCAL →", color: .green)
            }
            .position(x: size.width / 2, y: 60)
            
            Text("🚇 Router Station")
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundColor(.orange)
                .position(x: size.width / 2, y: 30)
        }
    }
}

struct DirectionSign: View {
    let text: String
    let color: Color
    
    var body: some View {
        Text(text)
            .font(.system(size: 12, weight: .bold, design: .monospaced))
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(RoundedRectangle(cornerRadius: 4).fill(color))
    }
}

// MARK: - Ocean Cable Background
struct OceanCableBackground: View {
    let size: CGSize
    @State private var fishOffset: CGFloat = 0
    @State private var bubbleOffset: CGFloat = 0
    
    var body: some View {
        ZStack {
            // Deep ocean gradient
            LinearGradient(
                colors: [
                    Color(red: 0.0, green: 0.1, blue: 0.3),
                    Color(red: 0.0, green: 0.05, blue: 0.15)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            
            // Light rays from above
            ForEach(0..<5, id: \.self) { i in
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [Color.cyan.opacity(0.1), Color.clear],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 40, height: size.height)
                    .rotationEffect(.degrees(-10 + Double(i) * 5))
                    .position(x: CGFloat(i) * (size.width / 4), y: size.height / 2)
            }
            
            // The fiber optic cable (glass tube)
            ZStack {
                // Cable outer
                RoundedRectangle(cornerRadius: 30)
                    .stroke(Color.cyan.opacity(0.5), lineWidth: 4)
                    .frame(width: size.width * 0.9, height: 80)
                
                // Cable inner glow
                RoundedRectangle(cornerRadius: 25)
                    .fill(Color.cyan.opacity(0.1))
                    .frame(width: size.width * 0.85, height: 70)
                
                // Light pulses inside cable
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .fill(Color.cyan.opacity(0.8))
                        .frame(width: 10, height: 10)
                        .offset(x: CGFloat(-200 + i * 200))
                        .blur(radius: 3)
                }
            }
            .position(x: size.width / 2, y: size.height / 2)
            
            // Fish swimming by
            ForEach(0..<3, id: \.self) { i in
                Text(["🐟", "🦈", "🐠"][i])
                    .font(.system(size: CGFloat([30, 50, 25][i])))
                    .position(
                        x: (CGFloat(i * 200) + fishOffset).truncatingRemainder(dividingBy: size.width + 100) - 50,
                        y: size.height * CGFloat([0.2, 0.7, 0.85][i])
                    )
            }
            
            // Bubbles
            ForEach(0..<10, id: \.self) { i in
                Circle()
                    .fill(Color.white.opacity(0.3))
                    .frame(width: CGFloat.random(in: 5...15))
                    .position(
                        x: CGFloat.random(in: 0...size.width),
                        y: (size.height - bubbleOffset + CGFloat(i * 80)).truncatingRemainder(dividingBy: size.height)
                    )
            }
            
            Text("🌊 Ocean Floor - Fiber Optic Cable")
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundColor(.cyan)
                .position(x: size.width / 2, y: 30)
        }
        .onAppear {
            withAnimation(.linear(duration: 10).repeatForever(autoreverses: false)) {
                fishOffset = size.width + 100
            }
            withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
                bubbleOffset = size.height
            }
        }
    }
}

// MARK: - DNS Library Background
struct DNSLibraryBackground: View {
    let size: CGSize
    
    var body: some View {
        ZStack {
            // Warm library atmosphere
            RadialGradient(
                colors: [Color.purple.opacity(0.2), Color.black.opacity(0.5)],
                center: .center,
                startRadius: 0,
                endRadius: size.width * 0.7
            )
            
            // Bookshelves
            ForEach(0..<4, id: \.self) { row in
                ForEach(0..<8, id: \.self) { col in
                    RoundedRectangle(cornerRadius: 2)
                        .fill([Color.red, Color.blue, Color.green, Color.brown, Color.orange].randomElement()!.opacity(0.6))
                        .frame(width: 20, height: 40)
                        .position(
                            x: 50 + CGFloat(col * 45),
                            y: 80 + CGFloat(row * 60)
                        )
                }
            }
            
            // Floating book particles
            ForEach(0..<5, id: \.self) { i in
                Text("📖")
                    .font(.system(size: 20))
                    .opacity(0.4)
                    .position(
                        x: CGFloat.random(in: size.width * 0.5...size.width * 0.9),
                        y: CGFloat.random(in: 100...size.height - 100)
                    )
            }
            
            Text("📚 DNS Library - The Internet's Phonebook")
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundColor(.purple)
                .position(x: size.width / 2, y: 30)
        }
    }
}

// MARK: - Return Journey Background
struct ReturnJourneyBackground: View {
    let size: CGSize
    @State private var speedLines: CGFloat = 0
    
    var body: some View {
        ZStack {
            // Urgent gradient
            LinearGradient(
                colors: [Color.orange.opacity(0.3), Color.red.opacity(0.2)],
                startPoint: .leading,
                endPoint: .trailing
            )
            
            // Speed lines
            ForEach(0..<20, id: \.self) { i in
                Rectangle()
                    .fill(Color.yellow.opacity(0.3))
                    .frame(width: CGFloat.random(in: 50...150), height: 2)
                    .position(
                        x: (speedLines + CGFloat(i * 50)).truncatingRemainder(dividingBy: size.width + 200) - 100,
                        y: CGFloat.random(in: 0...size.height)
                    )
            }
            
            Text("⚡ RETURN JOURNEY - Hurry back!")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(.yellow)
                .position(x: size.width / 2, y: 40)
        }
        .onAppear {
            withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                speedLines = size.width + 200
            }
        }
    }
}

// MARK: - Digital Grid
struct DigitalGrid: View {
    let color: Color
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Horizontal lines
                VStack(spacing: 40) {
                    ForEach(0..<20, id: \.self) { _ in
                        Rectangle()
                            .fill(color.opacity(0.05))
                            .frame(height: 1)
                    }
                }
                
                // Vertical lines
                HStack(spacing: 40) {
                    ForEach(0..<30, id: \.self) { _ in
                        Rectangle()
                            .fill(color.opacity(0.05))
                            .frame(width: 1)
                    }
                }
            }
        }
    }
}

// MARK: - Triangle Shape
struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

#Preview {
    ExplorationView(engine: GameEngine())
}
