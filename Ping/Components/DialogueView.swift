//
//  DialogueView.swift
//  Ping
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
                        Text(line.speaker)
                            .font(ScaledFont.scaledFont(size: 14, weight: .bold, design: .monospaced))
                            .foregroundColor(speakerColor(for: line.speaker))
                        
                        Spacer()
                        
                        // Progress indicator
                        Text("\(engine.currentDialogueIndex + 1)/\(engine.currentDialogue.count)")
                            .font(ScaledFont.scaledFont(size: 10, design: .monospaced))
                            .foregroundColor(.gray)
                            .accessibilityLabel("Line \(engine.currentDialogueIndex + 1) of \(engine.currentDialogue.count)")
                    }
                    
                    // Dialogue text with typewriter effect
                    Text(engine.typewriterText)
                        .font(ScaledFont.scaledFont(size: 16, design: .rounded))
                        .foregroundColor(.white)
                        .lineLimit(4)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .frame(minHeight: 60)
                        .accessibilityLabel(line.text)
                    
                    // Choices OR continue prompt
                    if let choices = engine.activeChoices {
                        // Show interactive choices
                        DialogueChoicesView(choices: choices) { choice in
                            engine.selectChoice(choice)
                        }
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    } else if engine.showInventorySwap && !engine.inventorySwapCompleted {
                        // Waiting for inventory swap  - show hint
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.up")
                                .font(.system(size: 10, weight: .bold))
                            Text("TAP YOUR SECURITY LAYER TO UPGRADE")
                                .font(ScaledFont.scaledFont(size: 10, weight: .semibold, design: .monospaced))
                        }
                        .foregroundColor(.yellow)
                        .frame(maxWidth: .infinity)
                        .transition(.opacity)
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("Tap your security layer to upgrade")
                    } else {
                        // Normal continue prompt
                        HStack {
                            Spacer()
                            
                            if !engine.isTyping {
                                HStack(spacing: 6) {
                                    Text("TAP TO CONTINUE")
                                        .font(ScaledFont.scaledFont(size: 10, weight: .semibold, design: .monospaced))
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 10))
                                }
                                .foregroundColor(.cyan)
                                .transition(.opacity)
                                .accessibilityHidden(true)
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
                                .accessibilityHidden(true)
                            }
                        }
                    }
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(red: 0.05, green: 0.05, blue: 0.08).opacity(0.85))
                    .background(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                LinearGradient(
                                    colors: [CyberpunkTheme.neonCyan, CyberpunkTheme.neonMagenta.opacity(0.3)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                    )
            )
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
        }
        .background(Color.black.opacity(0.3))
        .accessibilityAction {
            engine.advanceDialogue()
        }
        .accessibilityHint("Double tap to continue dialogue")
        .onTapGesture {
            engine.advanceDialogue()
        }
    }
    
    private func speakerColor(for speaker: String) -> Color {
        switch speaker {
        case "SYSTEM":
            return .yellow
        case _ where speaker.contains("Daemon"):
            return .cyan
        case _ where speaker.contains("Security Gateway"):
            return .orange
        case _ where speaker.contains("Router") || speaker.contains("Load Balancer"):
            return .orange
        case _ where speaker.contains("DNS Resolver"):
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
                .accessibilityLabel(choiceAccessibilityLabel(for: choice))
                .accessibilityHint("Double tap to select this option")
            }
        }
        .padding(.top, 8)
    }
    
    private func choiceAccessibilityLabel(for choice: DialogueChoice) -> String {
        let isTCP = choice.text.contains("TCP")
        let isUDP = choice.text.contains("UDP")
        if isTCP {
            return "\(choice.text). Reliable and safe."
        } else if isUDP {
            return "\(choice.text). Fast but risky."
        }
        return choice.text
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
                .font(ScaledFont.scaledFont(size: 12, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
            
            // Subtitle hint
            if isTCP {
                Text("Reliable • Safe")
                    .font(ScaledFont.scaledFont(size: 9, design: .monospaced))
                    .foregroundColor(.green.opacity(0.7))
            } else if isUDP {
                Text("Fast • Risky")
                    .font(ScaledFont.scaledFont(size: 9, design: .monospaced))
                    .foregroundColor(.orange.opacity(0.7))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(accent.opacity(0.15))
                .background(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(accent.opacity(0.8), lineWidth: 1.5)
                        .shadow(color: accent.opacity(0.5), radius: 5)
                )
        )
    }
}

// MARK: - Inventory Swap Puzzle
/// Appears during the Firewall SSL check  - player must tap the security slot to equip SSL.
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
                    .font(ScaledFont.scaledFont(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(.cyan)
                    .tracking(2)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Packet inventory")
            .accessibilityAddTraits(.isHeader)
            
            HStack(spacing: 10) {
                // Layer 4 (Application)
                InventorySlot(
                    icon: "shippingbox.fill",
                    label: "Layer 4",
                    value: engine.packet.layers.applicationLayer.rawValue,
                    color: engine.packet.layers.applicationLayer.color,
                    isTarget: false
                )
                
                // Layer 3 (Transport)
                InventorySlot(
                    icon: "arrow.left.arrow.right",
                    label: "Layer 3",
                    value: engine.packet.layers.transportLayer.rawValue,
                    color: engine.packet.layers.transportLayer.color,
                    isTarget: false
                )
                
                // Security Layer  - THE TARGET
                Button {
                    if !engine.inventorySwapCompleted {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                            showLockAnimation = true
                        }
                        engine.completeInventorySwap()
                    }
                } label: {
                    InventorySlot(
                        icon: engine.packet.layers.isSecure ? "lock.fill" : "lock.open.fill",
                        label: engine.packet.layers.isSecure ? "SSL/TLS" : "No Encryption",
                        value: engine.packet.layers.securityLayer.rawValue,
                        color: engine.packet.layers.isSecure ? .green : .red,
                        isTarget: !engine.inventorySwapCompleted
                    )
                }
                .buttonStyle(.plain)
                .scaleEffect(pulseSSL && !engine.inventorySwapCompleted ? 1.08 : 1.0)
                .accessibilityLabel(engine.packet.layers.isSecure ? "Security layer: SSL/TLS equipped" : "Security layer: No encryption. Tap to equip SSL")
                .accessibilityHint(engine.inventorySwapCompleted ? "" : "Double tap to upgrade your security")
                
                // Layer 2 (Network)
                InventorySlot(
                    icon: "signpost.right.fill",
                    label: "Layer 2",
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
                        .font(ScaledFont.scaledFont(size: 11, weight: .semibold, design: .rounded))
                        .foregroundColor(.green)
                }
                .transition(.scale.combined(with: .opacity))
                .accessibilityLabel("SSL equipped. Your data is now encrypted.")
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
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)
            
            Text(label)
                .font(ScaledFont.scaledFont(size: 9, weight: .semibold, design: .rounded))
                .foregroundColor(.white)
            
            Text(value)
                .font(ScaledFont.scaledFont(size: 8, weight: .medium, design: .monospaced))
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
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(label): \(value)")
    }
}

// MARK: - Exploration HUD
struct ExplorationHUD: View {
    let scene: StoryScene
    let mission: String
    let termsCount: Int
    let onEncyclopedia: () -> Void
    let onInventory: () -> Void
    let onPause: () -> Void
    @ObservedObject private var soundManager = SoundManager.shared
    
    var body: some View {
        VStack {
            HStack(alignment: .top) {
                // Scene title
                VStack(alignment: .leading, spacing: 4) {
                    Text(scene.displayName)
                        .font(ScaledFont.scaledFont(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .accessibilityAddTraits(.isHeader)
                    
                    // Mission text
                    HStack(spacing: 6) {
                        Image(systemName: "target")
                            .foregroundColor(.yellow)
                        Text(mission)
                            .font(ScaledFont.scaledFont(size: 11, design: .rounded))
                            .foregroundColor(.yellow.opacity(0.9))
                            .lineLimit(2)
                    }
                    .padding(8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(red: 0.05, green: 0.05, blue: 0.08).opacity(0.7))
                            .background(.ultraThinMaterial)
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(CyberpunkTheme.neonCyan.opacity(0.4), lineWidth: 1))
                    )
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Mission: \(mission)")
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
                                        .font(ScaledFont.scaledFont(size: 10, weight: .bold))
                                        .foregroundColor(.white)
                                        .padding(4)
                                        .background(Circle().fill(Color.purple))
                                        .offset(x: 12, y: -12)
                                }
                            }
                            
                            Text("Wiki")
                                .font(ScaledFont.scaledFont(size: 9, design: .rounded))
                                .foregroundColor(.gray)
                        }
                        .padding(10)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color(red: 0.05, green: 0.05, blue: 0.08).opacity(0.7))
                                .background(.ultraThinMaterial)
                                .overlay(RoundedRectangle(cornerRadius: 10).stroke(CyberpunkTheme.neonPurple.opacity(0.5), lineWidth: 1))
                        )
                    }
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("Encyclopedia, \(termsCount) terms collected")
                    .accessibilityHint("Opens your collected networking terms")
                    .accessibilityAddTraits(.isButton)
                    
                    // Layer Inventory
                    Button(action: onInventory) {
                        VStack(spacing: 4) {
                            Image(systemName: "cube.box.fill")
                                .font(.title2)
                                .foregroundColor(.cyan)
                            
                            Text("Layers")
                                .font(ScaledFont.scaledFont(size: 9, design: .rounded))
                                .foregroundColor(.gray)
                        }
                        .padding(10)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color(red: 0.05, green: 0.05, blue: 0.08).opacity(0.7))
                                .background(.ultraThinMaterial)
                                .overlay(RoundedRectangle(cornerRadius: 10).stroke(CyberpunkTheme.neonCyan.opacity(0.5), lineWidth: 1))
                        )
                    }
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("Packet layers")
                    .accessibilityHint("Shows your packet's network layers")
                    .accessibilityAddTraits(.isButton)
                    
                    // Mute Toggle
                    Button(action: { soundManager.toggleMute() }) {
                        VStack(spacing: 4) {
                            Image(systemName: soundManager.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                                .font(.title2)
                                .foregroundColor(soundManager.isMuted ? .gray : .orange)
                            
                            Text(soundManager.isMuted ? "Muted" : "Sound")
                                .font(ScaledFont.scaledFont(size: 9, design: .rounded))
                                .foregroundColor(.gray)
                        }
                        .padding(10)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color(red: 0.05, green: 0.05, blue: 0.08).opacity(0.7))
                                .background(.ultraThinMaterial)
                                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.orange.opacity(0.5), lineWidth: 1))
                        )
                    }
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(soundManager.isMuted ? "Sound muted" : "Sound on")
                    .accessibilityHint("Double tap to toggle sound")
                    .accessibilityAddTraits(.isButton)
                    
                    // Pause Button
                    Button(action: {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        onPause()
                    }) {
                        VStack(spacing: 4) {
                            Image(systemName: "pause.fill")
                                .font(.title2)
                                .foregroundColor(.white)
                            
                            Text("Pause")
                                .font(ScaledFont.scaledFont(size: 9, design: .rounded))
                                .foregroundColor(.gray)
                        }
                        .padding(10)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color(red: 0.05, green: 0.05, blue: 0.08).opacity(0.7))
                                .background(.ultraThinMaterial)
                                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.white.opacity(0.5), lineWidth: 1))
                        )
                    }
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("Pause game")
                    .accessibilityAddTraits(.isButton)
                }
            }
            .padding(.horizontal, 24) // slightly more breathing room on the sides
            .padding(.top, 24)
            
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
    
    private let panelAccent = Color(red: 0.0, green: 0.88, blue: 0.95)
    
    private var equippedCount: Int {
        [
            layers.applicationLayer != .empty,
            true,
            layers.isSecure,
            layers.networkLayer.hasDestination
        ].filter { $0 }.count
    }
    
    var body: some View {
        VStack {
            HStack {
                VStack(spacing: 0) {
                    // MARK: Header
                    HStack(spacing: 12) {
                        // Animated holographic icon
                        ZStack {
                            Circle()
                                .fill(
                                    RadialGradient(
                                        colors: [panelAccent.opacity(0.2), panelAccent.opacity(0.0)],
                                        center: .center, startRadius: 0, endRadius: 22
                                    )
                                )
                                .frame(width: 44, height: 44)
                                .scaleEffect(glowPulse ? 1.15 : 1.0)
                            
                            Circle()
                                .stroke(panelAccent.opacity(0.3), lineWidth: 1.5)
                                .frame(width: 38, height: 38)
                            
                            Image(systemName: "cube.transparent.fill")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundStyle(
                                    LinearGradient(colors: [panelAccent, .white], startPoint: .top, endPoint: .bottom)
                                )
                                .shadow(color: panelAccent.opacity(0.5), radius: 6)
                        }
                        
                        VStack(alignment: .leading, spacing: 3) {
                            Text("PACKET LAYERS")
                                .font(ScaledFont.scaledFont(size: 13, weight: .black, design: .monospaced))
                                .foregroundColor(.white)
                                .tracking(3)
                            Text("Your gear for the journey")
                                .font(ScaledFont.scaledFont(size: 10, weight: .medium, design: .rounded))
                                .foregroundColor(.white.opacity(0.4))
                        }
                        
                        Spacer()
                        
                        Button(action: onClose) {
                            Image(systemName: "xmark")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white.opacity(0.4))
                                .padding(8)
                                .background(Circle().fill(Color.white.opacity(0.06)))
                                .overlay(Circle().stroke(Color.white.opacity(0.08), lineWidth: 1))
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Close layers panel")
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Packet layers. Your gear for the journey.")
                    .accessibilityAddTraits(.isHeader)
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 16)
                    
                    // MARK: Progress Bar
                    VStack(spacing: 10) {
                        HStack {
                            Text("READINESS")
                                .font(ScaledFont.scaledFont(size: 9, weight: .bold, design: .monospaced))
                                .foregroundColor(.white.opacity(0.3))
                                .tracking(2)
                            Spacer()
                            Text("\(equippedCount)/4 LAYERS")
                                .font(ScaledFont.scaledFont(size: 9, weight: .bold, design: .monospaced))
                                .foregroundColor(equippedCount == 4 ? .green : panelAccent)
                                .tracking(1)
                        }
                        
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(Color.white.opacity(0.06))
                                
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(
                                        LinearGradient(
                                            colors: equippedCount == 4
                                                ? [.green, Color(red: 0.3, green: 0.95, blue: 0.85)]
                                                : [panelAccent, panelAccent.opacity(0.6)],
                                            startPoint: .leading, endPoint: .trailing
                                        )
                                    )
                                    .frame(width: geo.size.width * CGFloat(equippedCount) / 4.0)
                                    .shadow(color: (equippedCount == 4 ? Color.green : panelAccent).opacity(0.4), radius: 6)
                            }
                        }
                        .frame(height: 5)
                        
                        // Status dots
                        HStack(spacing: 16) {
                            statusDot(label: "Payload", ok: layers.applicationLayer != .empty)
                            statusDot(label: "Transport", ok: true)
                            statusDot(label: "Encrypt", ok: layers.isSecure)
                            statusDot(label: "Dest", ok: layers.networkLayer.hasDestination)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 14)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("\(equippedCount) of 4 layers equipped")
                    
                    // Divider
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [.clear, panelAccent.opacity(0.25), .clear],
                                startPoint: .leading, endPoint: .trailing
                            )
                        )
                        .frame(height: 1)
                        .accessibilityHidden(true)
                    
                    // MARK: Layer Cards
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: 8) {
                            layerCard(
                                index: 0,
                                icon: "signpost.right.fill",
                                name: "Network Layer",
                                layerNum: "L2",
                                value: "IP: \(layers.networkLayer.displayDestination)",
                                detail: layers.networkLayer.hasDestination
                                    ? "Route: \(layers.networkLayer.sourceIP) → \(layers.networkLayer.destinationIP)"
                                    : "Destination unknown - visit DNS Library",
                                color: layers.networkLayer.hasDestination ? .green : .gray,
                                isActive: layers.networkLayer.hasDestination
                            )
                            
                            layerCard(
                                index: 1,
                                icon: layers.isSecure ? "lock.fill" : "lock.open.fill",
                                name: "Security Layer",
                                layerNum: "L1",
                                value: layers.securityLayer.rawValue,
                                detail: layers.securityLayer.description,
                                color: layers.isSecure ? .green : .red,
                                isActive: layers.isSecure
                            )
                            
                            layerCard(
                                index: 2,
                                icon: "arrow.left.arrow.right",
                                name: "Transport Layer",
                                layerNum: "L3",
                                value: layers.transportLayer.rawValue,
                                detail: layers.transportLayer.description,
                                color: layers.transportLayer.color,
                                isActive: true
                            )
                            
                            layerCard(
                                index: 3,
                                icon: "shippingbox.fill",
                                name: "Application Layer",
                                layerNum: "L4",
                                value: layers.applicationLayer.rawValue,
                                detail: layers.applicationLayer == .empty
                                    ? "No payload yet"
                                    : "Carrying data for the mission",
                                color: layers.applicationLayer.color,
                                isActive: layers.applicationLayer != .empty
                            )
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                    }
                }
                .frame(width: 340)
                .background(
                    RoundedRectangle(cornerRadius: 22)
                        .fill(Color(red: 0.04, green: 0.03, blue: 0.07).opacity(0.98))
                        .background(
                            RoundedRectangle(cornerRadius: 22)
                                .fill(.ultraThinMaterial)
                                .opacity(0.3)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 22)
                                .stroke(
                                    LinearGradient(
                                        colors: [panelAccent.opacity(0.5), .purple.opacity(0.25), panelAccent.opacity(0.15)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1.5
                                )
                        )
                        .shadow(color: panelAccent.opacity(0.1), radius: 30)
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
            withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true)) {
                glowPulse = true
            }
        }
    }
    
    // MARK: - Status Dot
    @ViewBuilder
    private func statusDot(label: String, ok: Bool) -> some View {
        VStack(spacing: 4) {
            ZStack {
                Circle()
                    .fill(ok ? Color.green.opacity(0.2) : Color.white.opacity(0.04))
                    .frame(width: 20, height: 20)
                Circle()
                    .fill(ok ? Color.green : Color.white.opacity(0.1))
                    .frame(width: 8, height: 8)
                if ok {
                    Circle()
                        .fill(Color.green.opacity(0.3))
                        .frame(width: 20, height: 20)
                        .scaleEffect(glowPulse ? 1.3 : 1.0)
                        .opacity(glowPulse ? 0 : 0.5)
                }
            }
            Text(label)
                .font(ScaledFont.scaledFont(size: 8, weight: .semibold, design: .rounded))
                .foregroundColor(ok ? .white.opacity(0.5) : .white.opacity(0.2))
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(label): \(ok ? "Ready" : "Not ready")")
    }
    
    // MARK: - Layer Card
    @ViewBuilder
    private func layerCard(
        index: Int,
        icon: String,
        name: String,
        layerNum: String,
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
            HStack(spacing: 0) {
                // Left accent bar
                RoundedRectangle(cornerRadius: 2)
                    .fill(isActive ? color : color.opacity(0.2))
                    .frame(width: 3)
                    .padding(.vertical, 6)
                    .shadow(color: isActive ? color.opacity(0.5) : .clear, radius: 4)
                
                VStack(spacing: 0) {
                    HStack(spacing: 12) {
                        // Icon with background
                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(color.opacity(isActive ? 0.15 : 0.06))
                                .frame(width: 36, height: 36)
                            Image(systemName: icon)
                                .font(.system(size: 15))
                                .foregroundColor(isActive ? color : color.opacity(0.4))
                                .shadow(color: isActive ? color.opacity(0.4) : .clear, radius: 4)
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: 6) {
                                Text(name)
                                    .font(ScaledFont.scaledFont(size: 13, weight: .semibold, design: .rounded))
                                    .foregroundColor(.white)
                                
                                Text(layerNum)
                                    .font(ScaledFont.scaledFont(size: 8, weight: .bold, design: .monospaced))
                                    .foregroundColor(.white.opacity(0.2))
                                    .padding(.horizontal, 5)
                                    .padding(.vertical, 2)
                                    .background(
                                        Capsule().fill(Color.white.opacity(0.05))
                                    )
                            }
                            
                            // Value pill inline
                            Text(value)
                                .font(ScaledFont.scaledFont(size: 10, weight: .bold, design: .monospaced))
                                .foregroundColor(color.opacity(isActive ? 1.0 : 0.5))
                                .lineLimit(1)
                        }
                        
                        Spacer()
                        
                        // Status indicator
                        ZStack {
                            Circle()
                                .fill(isActive ? color.opacity(0.12) : Color.white.opacity(0.03))
                                .frame(width: 28, height: 28)
                            Image(systemName: isActive ? "checkmark" : "minus")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(isActive ? color : .white.opacity(0.15))
                        }
                        
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.white.opacity(0.2))
                            .padding(.leading, 4)
                            .accessibilityHidden(true)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    
                    if isExpanded {
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "lightbulb.fill")
                                .font(.system(size: 10))
                                .foregroundColor(.yellow.opacity(0.6))
                                .padding(.top, 1)
                            
                            Text(detail)
                                .font(ScaledFont.scaledFont(size: 11, weight: .medium, design: .rounded))
                                .foregroundColor(.white.opacity(0.55))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .lineSpacing(2)
                        }
                        .padding(.horizontal, 14)
                        .padding(.bottom, 10)
                        .padding(.leading, 48)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(color.opacity(isActive ? 0.05 : 0.02))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(color.opacity(isActive ? 0.15 : 0.06), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(name), \(layerNum). \(value). \(isActive ? "Active" : "Inactive")\(isExpanded ? ". \(detail)" : "")")
        .accessibilityHint(isExpanded ? "Double tap to collapse" : "Double tap to expand details")
        .accessibilityAddTraits(.isButton)
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
            onInventory: {},
            onPause: {}
        )
    }
}
