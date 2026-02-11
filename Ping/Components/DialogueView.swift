//
//  DialogueView.swift
//  Ping - Packet World
//
//  Dialogue system with typewriter effect
//

import SwiftUI

struct DialogueOverlay: View {
    @ObservedObject var engine: GameEngine
    
    var body: some View {
        VStack {
            Spacer()
            
            // Dialogue box
            VStack(alignment: .leading, spacing: 12) {
                // Speaker name and emotion
                if engine.currentDialogueIndex < engine.currentDialogue.count {
                    let line = engine.currentDialogue[engine.currentDialogueIndex]
                    
                    HStack {
                        if let emotion = line.emotion {
                            Text(emotion)
                                .font(.title2)
                        }
                        
                        Text(line.speaker)
                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                            .foregroundColor(speakerColor(for: line.speaker))
                        
                        Spacer()
                        
                        // Progress indicator
                        Text("\(engine.currentDialogueIndex + 1)/\(engine.currentDialogue.count)")
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(.gray)
                    }
                    
                    // Dialogue text with typewriter effect
                    Text(engine.typewriterText)
                        .font(.system(size: 16, design: .rounded))
                        .foregroundColor(.white)
                        .lineLimit(4)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .frame(minHeight: 60)
                    
                    // Continue prompt
                    HStack {
                        Spacer()
                        
                        if !engine.isTyping {
                            HStack(spacing: 6) {
                                Text("TAP TO CONTINUE")
                                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 10))
                            }
                            .foregroundColor(.cyan)
                            .transition(.opacity)
                        } else {
                            // Typing indicator
                            HStack(spacing: 4) {
                                ForEach(0..<3, id: \.self) { i in
                                    Circle()
                                        .fill(Color.cyan)
                                        .frame(width: 6, height: 6)
                                        .opacity(0.6)
                                }
                            }
                        }
                    }
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.black.opacity(0.9))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                LinearGradient(
                                    colors: [.cyan.opacity(0.5), .purple.opacity(0.5)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ),
                                lineWidth: 2
                            )
                    )
            )
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
        }
        .background(Color.black.opacity(0.3))
    }
    
    private func speakerColor(for speaker: String) -> Color {
        switch speaker {
        case "SYSTEM":
            return .yellow
        case _ where speaker.contains("Daemon"):
            return .cyan
        case _ where speaker.contains("Router"):
            return .orange
        case _ where speaker.contains("Librarian"):
            return .purple
        default:
            return .white
        }
    }
}

// MARK: - Exploration HUD
struct ExplorationHUD: View {
    let scene: StoryScene
    let mission: String
    let termsCount: Int
    let onEncyclopedia: () -> Void
    let onInventory: () -> Void
    
    var body: some View {
        VStack {
            HStack(alignment: .top) {
                // Scene title
                VStack(alignment: .leading, spacing: 4) {
                    Text(scene.displayName)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    // Mission text
                    HStack(spacing: 6) {
                        Image(systemName: "target")
                            .foregroundColor(.yellow)
                        Text(mission)
                            .font(.system(size: 11, design: .rounded))
                            .foregroundColor(.yellow.opacity(0.9))
                            .lineLimit(2)
                    }
                    .padding(8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.black.opacity(0.5))
                    )
                }
                .frame(maxWidth: 300)
                
                Spacer()
                
                // Action buttons
                HStack(spacing: 12) {
                    // Encyclopedia
                    Button(action: onEncyclopedia) {
                        VStack(spacing: 4) {
                            ZStack {
                                Image(systemName: "book.fill")
                                    .font(.title2)
                                    .foregroundColor(.purple)
                                
                                // Badge for terms count
                                if termsCount > 0 {
                                    Text("\(termsCount)")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundColor(.white)
                                        .padding(4)
                                        .background(Circle().fill(Color.purple))
                                        .offset(x: 12, y: -12)
                                }
                            }
                            
                            Text("Wiki")
                                .font(.system(size: 9, design: .rounded))
                                .foregroundColor(.gray)
                        }
                        .padding(10)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.black.opacity(0.5))
                        )
                    }
                    
                    // Layer Inventory
                    Button(action: onInventory) {
                        VStack(spacing: 4) {
                            Image(systemName: "cube.box.fill")
                                .font(.title2)
                                .foregroundColor(.cyan)
                            
                            Text("Layers")
                                .font(.system(size: 9, design: .rounded))
                                .foregroundColor(.gray)
                        }
                        .padding(10)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.black.opacity(0.5))
                        )
                    }
                }
            }
            .padding(16)
            
            Spacer()
        }
    }
}

// MARK: - Layer Inventory Panel
struct LayerInventoryPanel: View {
    let layers: PacketLayers
    let onClose: () -> Void
    
    var body: some View {
        VStack {
            HStack {
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("📦 PACKET LAYERS")
                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                            .foregroundColor(.cyan)
                        
                        Spacer()
                        
                        Button(action: onClose) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title2)
                                .foregroundColor(.gray)
                        }
                    }
                    
                    // Application Layer (Backpack)
                    LayerRow(
                        icon: "🎒",
                        name: "Application Layer",
                        description: "The Backpack",
                        value: layers.applicationLayer.rawValue,
                        color: layers.applicationLayer.color
                    )
                    
                    // Transport Layer (Shirt)
                    LayerRow(
                        icon: "👕",
                        name: "Transport Layer",
                        description: "The Shirt",
                        value: "\(layers.transportLayer.rawValue) - \(layers.transportLayer.description)",
                        color: layers.transportLayer.color
                    )
                    
                    // Network Layer (Hat)
                    LayerRow(
                        icon: "🎩",
                        name: "Network Layer",
                        description: "The Hat",
                        value: "Dest: \(layers.networkLayer.displayDestination)",
                        color: layers.networkLayer.hasDestination ? .green : .gray
                    )
                    
                    Spacer()
                }
                .padding(20)
                .frame(width: 280)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.black.opacity(0.95))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.cyan.opacity(0.3), lineWidth: 1)
                        )
                )
                
                Spacer()
            }
            .padding(16)
            
            Spacer()
        }
    }
}

struct LayerRow: View {
    let icon: String
    let name: String
    let description: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Text(icon)
                .font(.title)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                
                Text(description)
                    .font(.system(size: 10, design: .rounded))
                    .foregroundColor(.gray)
                
                Text(value)
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundColor(color)
            }
            
            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(color.opacity(0.1))
        )
    }
}

// MARK: - Interactive Object View
struct InteractiveObjectView: View {
    let object: InteractiveObject
    @State private var pulse = false
    
    var body: some View {
        ZStack {
            switch object.type {
            case .portal:
                PortalView(pulse: pulse)
            case .terminal:
                TerminalObjectView()
            case .checkpoint:
                CheckpointView()
            case .collectable:
                CollectableView(pulse: pulse)
            }
        }
        .position(object.position)
        .opacity(object.isActive ? 1 : 0.3)
        .onAppear {
            withAnimation(.easeInOut(duration: 1).repeatForever(autoreverses: true)) {
                pulse = true
            }
        }
    }
}

struct PortalView: View {
    let pulse: Bool
    
    var body: some View {
        ZStack {
            // Outer glow
            Circle()
                .fill(Color.cyan.opacity(0.3))
                .frame(width: 80, height: 80)
                .scaleEffect(pulse ? 1.2 : 1.0)
                .blur(radius: 10)
            
            // Portal ring
            Circle()
                .stroke(
                    LinearGradient(
                        colors: [.cyan, .blue, .purple],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 4
                )
                .frame(width: 60, height: 60)
            
            // Inner swirl
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.cyan.opacity(0.8), Color.purple.opacity(0.4), Color.clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 25
                    )
                )
                .frame(width: 50, height: 50)
            
            // Arrow indicator
            Image(systemName: "arrow.right")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)
        }
    }
}

struct TerminalObjectView: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.8))
                .frame(width: 40, height: 50)
            
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.green.opacity(0.6))
                .frame(width: 32, height: 25)
                .offset(y: -8)
            
            Text(">_")
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(.black)
                .offset(y: -8)
        }
    }
}

struct CheckpointView: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(Color.green.opacity(0.3))
                .frame(width: 50, height: 50)
            
            Image(systemName: "flag.fill")
                .font(.title)
                .foregroundColor(.green)
        }
    }
}

struct CollectableView: View {
    let pulse: Bool
    
    var body: some View {
        ZStack {
            Circle()
                .fill(Color.yellow.opacity(0.3))
                .frame(width: 40, height: 40)
                .scaleEffect(pulse ? 1.2 : 1.0)
            
            Image(systemName: "star.fill")
                .font(.title2)
                .foregroundColor(.yellow)
        }
    }
}

#Preview {
    ZStack {
        Color.black
        
        ExplorationHUD(
            scene: .cpuCity,
            mission: "Find the Daemon and receive your mission.",
            termsCount: 3,
            onEncyclopedia: {},
            onInventory: {}
        )
    }
}
