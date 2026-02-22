//
//  ExplorationView3D.swift
//  Ping - Packet World
//

import SwiftUI
import SceneKit

struct ExplorationView3D: View {
    @ObservedObject var engine: GameEngine
    @State private var showControls = true
    @State private var flashWhite: Bool = false
    
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
                    antialiasingMode: .none
                )
                .ignoresSafeArea()
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
                        onInventory: { engine.showLayerInventory.toggle() }
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
                            
                            // Center: Joystick Hint (Fades out)
                            if showControls {
                                HStack {
                                    Image(systemName: "arrow.up.and.down.and.arrow.left.and.right")
                                    Text("Use the joystick to explore")
                                }
                                .font(.system(size: 12, design: .rounded))
                                .foregroundColor(.white.opacity(0.6))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Capsule().fill(Color.black.opacity(0.5)))
                                .padding(.bottom, 30)
                                .transition(.opacity)
                                .onAppear {
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                                        withAnimation { showControls = false }
                                    }
                                }
                            }
                            
                            Spacer()
                            
                            // Right Side Placeholder (Keeps layout balanced)
                            Color.clear.frame(width: 100, height: 100)
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
                }
            }
            .onAppear {
                engine.setScreenSize(geo.size)
                engine.setup3DScene()
                
                // --- CRITICAL CRASH FIX FOR SIMULATOR ---
                if let camera = engine.sceneManager.cameraNode.camera {
                    camera.wantsHDR = false
                    camera.bloomIntensity = 0
                    camera.wantsDepthOfField = false
                    camera.motionBlurIntensity = 0
                    engine.sceneManager.scene.fogDensityExponent = 1.5
                }
                // ----------------------------------------
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
                    .font(.system(size: 13, weight: .bold, design: .rounded))
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
                    .font(.system(size: 13, weight: .bold, design: .rounded))
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
        .onAppear {
            withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
                glow = true
            }
        }
    }
}

// MARK: - Magenta Color Extension
extension Color {
    static let magenta = Color(red: 1.0, green: 0.1, blue: 0.6)
}
