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
            
            // Inventory Swap Puzzle (slides up above dialogue)
            if engine.showInventorySwap {
                InventorySwapPuzzle(engine: engine)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 8)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
            
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
                    
                    // Choices OR continue prompt
                    if let choices = engine.activeChoices {
                        // Show interactive choices
                        DialogueChoicesView(choices: choices) { choice in
                            engine.selectChoice(choice)
                        }
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    } else if engine.showInventorySwap && !engine.inventorySwapCompleted {
                        // Waiting for inventory swap — show hint
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.up")
                                .font(.system(size: 10, weight: .bold))
                            Text("TAP YOUR SHIRT TO UPGRADE")
                                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                        }
                        .foregroundColor(.yellow)
                        .frame(maxWidth: .infinity)
                        .transition(.opacity)
                    } else {
                        // Normal continue prompt
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
        case _ where speaker.contains("Firewall"):
            return .orange
        case _ where speaker.contains("Router"):
            return .orange
        case _ where speaker.contains("Librarian"):
            return .purple
        default:
            return .white
        }
    }
}

// MARK: - Dialogue Choices View
/// Shows tappable cards for branching dialogue (e.g. TCP vs UDP)
struct DialogueChoicesView: View {
    let choices: [DialogueChoice]
    let onSelect: (DialogueChoice) -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            ForEach(choices) { choice in
                Button {
                    onSelect(choice)
                } label: {
                    choiceCard(for: choice)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.top, 8)
    }
    
    @ViewBuilder
    private func choiceCard(for choice: DialogueChoice) -> some View {
        let isTCP = choice.text.contains("TCP")
        let isUDP = choice.text.contains("UDP")
        let accent: Color = isTCP ? .green : isUDP ? .orange : .cyan
        let icon = isTCP ? "checkmark.shield.fill" : isUDP ? "bolt.fill" : "questionmark.circle"
        
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 22))
                .foregroundColor(accent)
                .shadow(color: accent.opacity(0.6), radius: 8)
            
            Text(choice.text)
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
            
            // Subtitle hint
            if isTCP {
                Text("Reliable • Safe")
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundColor(.green.opacity(0.7))
            } else if isUDP {
                Text("Fast • Risky")
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundColor(.orange.opacity(0.7))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(accent.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(accent.opacity(0.5), lineWidth: 1.5)
                )
        )
    }
}

// MARK: - Inventory Swap Puzzle
/// Appears during the Firewall SSL check — player must tap the security slot to equip SSL.
struct InventorySwapPuzzle: View {
    @ObservedObject var engine: GameEngine
    @State private var pulseSSL = false
    @State private var showLockAnimation = false
    
    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "cube.box.fill")
                    .foregroundColor(.cyan)
                Text("PACKET INVENTORY")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(.cyan)
                    .tracking(2)
            }
            
            HStack(spacing: 10) {
                // Backpack (Application)
                InventorySlot(
                    icon: "🎒",
                    label: "Backpack",
                    value: engine.packet.layers.applicationLayer.rawValue,
                    color: engine.packet.layers.applicationLayer.color,
                    isTarget: false
                )
                
                // Shirt (Transport)
                InventorySlot(
                    icon: "👕",
                    label: "Shirt",
                    value: engine.packet.layers.transportLayer.rawValue,
                    color: engine.packet.layers.transportLayer.color,
                    isTarget: false
                )
                
                // Security Layer — THE TARGET
                Button {
                    if !engine.inventorySwapCompleted {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                            showLockAnimation = true
                        }
                        engine.completeInventorySwap()
                    }
                } label: {
                    InventorySlot(
                        icon: engine.packet.layers.isSecure ? "🔒" : "🔓",
                        label: engine.packet.layers.isSecure ? "SSL/TLS" : "No Encryption",
                        value: engine.packet.layers.securityLayer.rawValue,
                        color: engine.packet.layers.isSecure ? .green : .red,
                        isTarget: !engine.inventorySwapCompleted
                    )
                }
                .buttonStyle(.plain)
                .scaleEffect(pulseSSL && !engine.inventorySwapCompleted ? 1.08 : 1.0)
                
                // Hat (Network)
                InventorySlot(
                    icon: "🎩",
                    label: "Hat",
                    value: engine.packet.layers.networkLayer.displayDestination,
                    color: engine.packet.layers.networkLayer.hasDestination ? .green : .gray,
                    isTarget: false
                )
            }
            
            if engine.inventorySwapCompleted {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("SSL EQUIPPED! Your data is now encrypted.")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundColor(.green)
                }
                .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.black.opacity(0.92))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(
                            engine.inventorySwapCompleted
                                ? Color.green.opacity(0.6)
                                : Color.yellow.opacity(0.6),
                            lineWidth: 2
                        )
                )
        )
        .onAppear {
            withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
                pulseSSL = true
            }
        }
    }
}

struct InventorySlot: View {
    let icon: String
    let label: String
    let value: String
    let color: Color
    let isTarget: Bool
    
    var body: some View {
        VStack(spacing: 4) {
            Text(icon)
                .font(.system(size: 24))
            
            Text(label)
                .font(.system(size: 9, weight: .semibold, design: .rounded))
                .foregroundColor(.white)
            
            Text(value)
                .font(.system(size: 8, weight: .medium, design: .monospaced))
                .foregroundColor(color)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(width: 72, height: 72)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(color.opacity(isTarget ? 0.15 : 0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(
                            isTarget ? Color.yellow : color.opacity(0.3),
                            lineWidth: isTarget ? 2 : 1
                        )
                )
        )
    }
}

// MARK: - Exploration HUD
struct ExplorationHUD: View {
    let scene: StoryScene
    let mission: String
    let termsCount: Int
    let onEncyclopedia: () -> Void
    let onInventory: () -> Void
    @ObservedObject private var soundManager = SoundManager.shared
    
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
                    
                    // Mute Toggle
                    Button(action: { soundManager.toggleMute() }) {
                        VStack(spacing: 4) {
                            Image(systemName: soundManager.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                                .font(.title2)
                                .foregroundColor(soundManager.isMuted ? .gray : .orange)
                            
                            Text(soundManager.isMuted ? "Muted" : "Sound")
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
    @State private var appear = false
    @State private var glowPulse = false
    @State private var selectedLayer: Int? = nil
    
    private let layerData: [(icon: String, name: String, metaphor: String)] = [
        ("🎩", "Network Layer", "The Hat"),
        ("🔒", "Security Layer", "The Shield"),
        ("👕", "Transport Layer", "The Shirt"),
        ("🎒", "Application Layer", "The Backpack")
    ]
    
    var body: some View {
        VStack {
            HStack {
                VStack(spacing: 0) {
                    // Header
                    HStack(spacing: 8) {
                        ZStack {
                            Circle()
                                .fill(Color.cyan.opacity(0.15))
                                .frame(width: 32, height: 32)
                            Image(systemName: "cube.box.fill")
                                .font(.system(size: 14))
                                .foregroundColor(.cyan)
                        }
                        
                        VStack(alignment: .leading, spacing: 1) {
                            Text("PACKET LAYERS")
                                .font(.system(size: 12, weight: .bold, design: .monospaced))
                                .foregroundColor(.cyan)
                                .tracking(2)
                            Text("Your gear for the journey")
                                .font(.system(size: 9, weight: .medium, design: .rounded))
                                .foregroundColor(.white.opacity(0.35))
                        }
                        
                        Spacer()
                        
                        // Completion badge
                        completionBadge
                        
                        Button(action: onClose) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 18))
                                .foregroundColor(.white.opacity(0.3))
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .padding(.bottom, 12)
                    
                    // Divider
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [.clear, .cyan.opacity(0.3), .clear],
                                startPoint: .leading, endPoint: .trailing
                            )
                        )
                        .frame(height: 1)
                    
                    // Character visualization
                    packetCharacterView
                        .padding(.vertical, 12)
                    
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [.clear, .cyan.opacity(0.2), .clear],
                                startPoint: .leading, endPoint: .trailing
                            )
                        )
                        .frame(height: 1)
                    
                    // Layer cards
                    VStack(spacing: 6) {
                        layerCard(
                            index: 0,
                            icon: "🎩",
                            name: "Network Layer",
                            metaphor: "The Hat",
                            value: "IP: \(layers.networkLayer.displayDestination)",
                            detail: layers.networkLayer.hasDestination
                                ? "Route: \(layers.networkLayer.sourceIP) → \(layers.networkLayer.destinationIP)"
                                : "Destination unknown — visit DNS Library",
                            color: layers.networkLayer.hasDestination ? .green : .gray,
                            isActive: layers.networkLayer.hasDestination
                        )
                        
                        layerCard(
                            index: 1,
                            icon: layers.isSecure ? "🔒" : "🔓",
                            name: "Security Layer",
                            metaphor: layers.isSecure ? "SSL/TLS Shield" : "No Shield",
                            value: layers.securityLayer.rawValue,
                            detail: layers.securityLayer.description,
                            color: layers.isSecure ? .green : .red,
                            isActive: layers.isSecure
                        )
                        
                        layerCard(
                            index: 2,
                            icon: "👕",
                            name: "Transport Layer",
                            metaphor: "The Shirt",
                            value: layers.transportLayer.rawValue,
                            detail: layers.transportLayer.description,
                            color: layers.transportLayer.color,
                            isActive: true
                        )
                        
                        layerCard(
                            index: 3,
                            icon: "🎒",
                            name: "Application Layer",
                            metaphor: "The Backpack",
                            value: layers.applicationLayer.rawValue,
                            detail: layers.applicationLayer == .empty
                                ? "No payload yet"
                                : "Carrying data for the mission",
                            color: layers.applicationLayer.color,
                            isActive: layers.applicationLayer != .empty
                        )
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                }
                .frame(width: 300)
                .background(
                    RoundedRectangle(cornerRadius: 18)
                        .fill(Color(red: 0.04, green: 0.03, blue: 0.08).opacity(0.97))
                        .overlay(
                            RoundedRectangle(cornerRadius: 18)
                                .stroke(
                                    LinearGradient(
                                        colors: [.cyan.opacity(0.4), .purple.opacity(0.2), .cyan.opacity(0.1)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1.5
                                )
                        )
                        .shadow(color: .cyan.opacity(0.08), radius: 20)
                )
                .scaleEffect(appear ? 1 : 0.9)
                .opacity(appear ? 1 : 0)
                
                Spacer()
            }
            .padding(16)
            
            Spacer()
        }
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                appear = true
            }
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                glowPulse = true
            }
        }
    }
    
    // MARK: - Packet Character Visualization
    @ViewBuilder
    private var packetCharacterView: some View {
        HStack(spacing: 0) {
            Spacer()
            
            ZStack {
                // Glow ring
                Circle()
                    .stroke(Color.cyan.opacity(glowPulse ? 0.2 : 0.05), lineWidth: 2)
                    .frame(width: 90, height: 90)
                    .scaleEffect(glowPulse ? 1.1 : 1.0)
                
                // Character body - stacked layers
                VStack(spacing: -2) {
                    // Hat (Network)
                    Text("🎩")
                        .font(.system(size: 18))
                        .opacity(layers.networkLayer.hasDestination ? 1.0 : 0.25)
                    
                    // Lock (Security) overlaid
                    ZStack {
                        Text("👕")
                            .font(.system(size: 28))
                        
                        Text(layers.isSecure ? "🔒" : "🔓")
                            .font(.system(size: 11))
                            .offset(x: 16, y: -10)
                    }
                    
                    // Backpack indicator
                    Text("🎒")
                        .font(.system(size: 14))
                        .opacity(layers.applicationLayer != .empty ? 1.0 : 0.25)
                        .offset(y: -4)
                }
            }
            
            Spacer()
            
            // Quick status column
            VStack(alignment: .leading, spacing: 6) {
                statusRow(
                    icon: "shippingbox.fill",
                    label: "Payload",
                    ok: layers.applicationLayer != .empty
                )
                statusRow(
                    icon: "arrow.left.arrow.right",
                    label: "Transport",
                    ok: true
                )
                statusRow(
                    icon: "lock.shield.fill",
                    label: "Encryption",
                    ok: layers.isSecure
                )
                statusRow(
                    icon: "signpost.right.fill",
                    label: "Destination",
                    ok: layers.networkLayer.hasDestination
                )
            }
            
            Spacer()
        }
    }
    
    @ViewBuilder
    private func statusRow(icon: String, label: String, ok: Bool) -> some View {
        HStack(spacing: 6) {
            Image(systemName: ok ? "checkmark.circle.fill" : "circle.dashed")
                .font(.system(size: 10))
                .foregroundColor(ok ? .green : .white.opacity(0.2))
            
            Text(label)
                .font(.system(size: 9, weight: .medium, design: .rounded))
                .foregroundColor(ok ? .white.opacity(0.7) : .white.opacity(0.25))
        }
    }
    
    // MARK: - Layer Card
    @ViewBuilder
    private func layerCard(
        index: Int,
        icon: String,
        name: String,
        metaphor: String,
        value: String,
        detail: String,
        color: Color,
        isActive: Bool
    ) -> some View {
        let isExpanded = selectedLayer == index
        
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                selectedLayer = selectedLayer == index ? nil : index
            }
        } label: {
            VStack(spacing: 0) {
                HStack(spacing: 10) {
                    // Icon
                    Text(icon)
                        .font(.system(size: 20))
                        .frame(width: 32)
                    
                    VStack(alignment: .leading, spacing: 1) {
                        Text(name)
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                        
                        Text(metaphor)
                            .font(.system(size: 9, design: .rounded))
                            .foregroundColor(.white.opacity(0.35))
                    }
                    
                    Spacer()
                    
                    // Value pill
                    Text(value)
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundColor(color)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(
                            Capsule().fill(color.opacity(0.12))
                        )
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(.white.opacity(0.25))
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                
                if isExpanded {
                    HStack {
                        Rectangle()
                            .fill(color.opacity(0.4))
                            .frame(width: 2)
                            .padding(.leading, 25)
                        
                        Text(detail)
                            .font(.system(size: 10, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.6))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 6)
                        
                        Spacer()
                    }
                    .padding(.bottom, 6)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(color.opacity(isActive ? 0.06 : 0.02))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(color.opacity(isActive ? 0.15 : 0.05), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Completion Badge
    @ViewBuilder
    private var completionBadge: some View {
        let equipped = [
            layers.applicationLayer != .empty,
            true, // transport always active
            layers.isSecure,
            layers.networkLayer.hasDestination
        ].filter { $0 }.count
        
        Text("\(equipped)/4")
            .font(.system(size: 9, weight: .bold, design: .monospaced))
            .foregroundColor(equipped == 4 ? .green : .cyan)
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(
                Capsule()
                    .fill(equipped == 4 ? Color.green.opacity(0.12) : Color.cyan.opacity(0.1))
                    .overlay(
                        Capsule()
                            .stroke(equipped == 4 ? Color.green.opacity(0.3) : Color.cyan.opacity(0.2), lineWidth: 1)
                    )
            )
            .padding(.trailing, 6)
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
