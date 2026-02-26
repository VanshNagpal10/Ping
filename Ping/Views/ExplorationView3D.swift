//
//  ExplorationView3D.swift
//  Ping
//

import SwiftUI
import SceneKit

struct ExplorationView3D: View {
    @ObservedObject var engine: GameEngine
    @State private var showControls = true
    @State private var flashWhite: Bool = false
    @State private var tutorialText = "Use the joystick to explore"
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                // ==========================================
                // LAYER 1: The 3D World (Background)
                // ==========================================
                SceneView(
                    scene: engine.sceneManager.scene,
                    pointOfView: engine.sceneManager.cameraNode,
                    options: [],
                    preferredFramesPerSecond: 60,
                    antialiasingMode: .multisampling4X
                )
                .ignoresSafeArea()
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("3D game world")
                .onTapGesture { _ in
                    // If dialogue is active, tapping anywhere on the 3D world advances it
                    if engine.isDialogueActive {
                        engine.advanceDialogue()
                    }
                }
                
                // ==========================================
                // LAYER 2: HUD & Controls
                // ==========================================
                VStack {
                    // Top HUD
                    ExplorationHUD(
                        scene: engine.currentScene,
                        mission: engine.currentMission,
                        termsCount: engine.learnedTerms.count,
                        onEncyclopedia: { engine.showEncyclopedia = true },
                        onInventory: { engine.showLayerInventory.toggle() },
                        onPause: { 
                            withAnimation { engine.showPauseMenu = true } 
                        }
                    )
                    
                    Spacer()
                    
                    // Bottom Controls Area
                    if !engine.isDialogueActive {
                        HStack(alignment: .bottom) {
                            // Left Side: Joystick
                            JoystickView { direction in
                                engine.updatePlayerDirection3D(direction)
                            }
                            .padding(.leading, 40)
                            .padding(.bottom, 30)
                            
                            Spacer()
                            
                            // Center: Tutorial Tooltip
                            if showControls {
                                HStack {
                                    Image(systemName: "info.circle.fill")
                                        .foregroundColor(.cyan)
                                    Text(tutorialText)
                                }
                                .font(ScaledFont.scaledFont(size: 13, weight: .semibold, design: .rounded))
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(
                                    Capsule()
                                        .fill(Color.black.opacity(0.7))
                                        .overlay(Capsule().stroke(Color.cyan.opacity(0.5), lineWidth: 1))
                                )
                                .padding(.bottom, 30)
                                .transition(.opacity.combined(with: .scale))
                                .accessibilityElement(children: .combine)
                                .accessibilityLabel("Tip: \(tutorialText)")
                                .onAppear {
                                    // Change text after 4 seconds
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                                        withAnimation { tutorialText = "Walk up to characters to talk" }
                                    }
                                    // Change text again after 8 seconds
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 8) {
                                        withAnimation { tutorialText = "Step into Portals to travel" }
                                    }
                                    // Fade out entirely after 12 seconds
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 12) {
                                        withAnimation { showControls = false }
                                    }
                                }
                            }
                            
                            Spacer()
                            
                            // Right Side Placeholder (Keeps layout balanced)
                            Color.clear.frame(width: 100, height: 100)
                                .accessibilityHidden(true)
                        }
                    }
                }
                
                // ==========================================
                // LAYER 3: Action Prompts (Center Right)
                // ==========================================
                if !engine.isDialogueActive {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            VStack(alignment: .trailing, spacing: 16) {
                                // Proximity interaction prompt
                                if let nearbyNPC = engine.nearbyNPCName {
                                    InteractionPrompt(name: nearbyNPC) {
                                        engine.interactWithNearby3DNPC()
                                    }
                                    .transition(.scale.combined(with: .opacity))
                                }
                                
                                // Portal proximity prompt
                                if engine.nearPortal {
                                    PortalPrompt {
                                        // 1. Trigger the flash animation
                                        withAnimation(.easeIn(duration: 0.1)) {
                                            flashWhite = true
                                        }
                                        // 2. Actually transition the scene right as it hits peak white
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                            engine.enterPortal()
                                            // 3. Fade the flash out over the new scene
                                            withAnimation(.easeOut(duration: 0.5)) {
                                                flashWhite = false
                                            }
                                        }
                                    }
                                    .transition(.scale.combined(with: .opacity))
                                }
                                
                                // Portal locked prompt
                                if engine.portalLocked {
                                    LockedPortalPrompt(npcName: engine.lockedPortalNPCName)
                                        .transition(.scale.combined(with: .opacity))
                                }
                            }
                            .padding(.trailing, 60)
                            .padding(.bottom, 160) // Ergonomic thumb position
                        }
                    }
                }
                
                // ==========================================
                // LAYER 4: Full Screen Overlays (Dialogue, Menus)
                // ==========================================
                if engine.isDialogueActive {
                    DialogueOverlay(engine: engine)
                        .transition(.opacity)
                }
                
                if engine.showLayerInventory {
                    LayerInventoryPanel(
                        layers: engine.packet.layers,
                        onClose: { engine.showLayerInventory = false }
                    )
                    .transition(.move(edge: .trailing).combined(with: .opacity))
                }
                
                if engine.showQuiz {
                    QuizOverlay(engine: engine, scene: engine.quizScene)
                        .transition(.opacity)
                }
                
                // ==========================================
                // LAYER 5: Visual FX (Teleport Flash)
                // ==========================================
                if flashWhite {
                    Color.white
                        .ignoresSafeArea()
                        .zIndex(100) // Guarantees it covers absolutely everything
                        .accessibilityHidden(true)
                }
            }
            .onAppear {
                engine.setScreenSize(geo.size)
                engine.setup3DScene()
                
                // --- Removed simulator crash fix that was forcing HDR off ---
                // Let SceneManager handle the camera properties natively.
            }
        }
    }
}

// MARK: - Interaction Prompt (Tappable)
struct InteractionPrompt: View {
    let name: String
    let onTalk: () -> Void
    @State private var pulse = false
    
    var body: some View {
        Button(action: onTalk) {
            HStack(spacing: 8) {
                Image(systemName: "bubble.left.fill")
                    .foregroundColor(.yellow)
                Text("TALK to \(name)")
                    .font(ScaledFont.scaledFont(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.black.opacity(0.8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.yellow.opacity(0.6), lineWidth: 1.5)
                    )
            )
        }
        .accessibilityLabel("Talk to \(name)")
        .accessibilityHint("Double tap to start a conversation")
        .scaleEffect(pulse ? 1.05 : 1.0)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                pulse = true
            }
        }
    }
}

// MARK: - Portal Prompt
struct PortalPrompt: View {
    let onEnter: () -> Void
    @State private var glow = false
    
    var body: some View {
        Button(action: onEnter) {
            HStack(spacing: 8) {
                Image(systemName: "arrow.right.circle.fill")
                    .foregroundColor(.magenta)
                Text("ENTER PORTAL")
                    .font(ScaledFont.scaledFont(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.black.opacity(0.8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.magenta.opacity(glow ? 0.8 : 0.4), lineWidth: 1.5)
                    )
            )
        }
        .accessibilityLabel("Enter portal")
        .accessibilityHint("Double tap to travel to the next area")
        .onAppear {
            withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
                glow = true
            }
        }
    }
}

// MARK: - Locked Portal Prompt
struct LockedPortalPrompt: View {
    let npcName: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "lock.fill")
                .foregroundColor(.red)
            Text("TALK TO \(npcName) FIRST")
                .font(ScaledFont.scaledFont(size: 13, weight: .bold, design: .rounded))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.8))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.red.opacity(0.6), lineWidth: 1.5)
                )
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Portal locked. Talk to \(npcName) first.")
    }
}

// MARK: - Magenta Color Extension
extension Color {
    static let magenta = Color(red: 1.0, green: 0.1, blue: 0.6)
}
