//
//  ExplorationView3D.swift
//  Ping - Packet World
//

import SwiftUI
import SceneKit

struct ExplorationView3D: View {
    @ObservedObject var engine: GameEngine
    @State private var showControls = true
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                // 3D SceneKit World
                SceneView(
                    scene: engine.sceneManager.scene,
                    pointOfView: engine.sceneManager.cameraNode,
                    // FIX 1: Removed .temporalAntialiasingEnabled to stop the Metal Crash
                    // FIX 2: Removed .allowsCameraControl (unless you want the user to pinch/rotate manually)
                    options: [],
                    preferredFramesPerSecond: 60,
                    antialiasingMode: .none // FIX 3: Explicitly disable MSAA for Simulator stability
                )
                .ignoresSafeArea()
                
                // Proximity interaction prompt
                if let nearbyNPC = engine.nearbyNPCName, !engine.isDialogueActive {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            InteractionPrompt(name: nearbyNPC)
                                .padding(.trailing, 40)
                                .padding(.bottom, 120)
                        }
                    }
                    .transition(.scale.combined(with: .opacity))
                }
                
                // Portal proximity prompt — tap to enter
                if engine.nearPortal && !engine.isDialogueActive {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            PortalPrompt {
                                engine.enterPortal()
                            }
                                .padding(.trailing, 40)
                                .padding(.bottom, 120)
                        }
                    }
                    .transition(.scale.combined(with: .opacity))
                }
                
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
                
                // Joystick hint
                if showControls && !engine.isDialogueActive {
                    VStack {
                        Spacer()
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
                    }
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                            withAnimation { showControls = false }
                        }
                    }
                }
                
                // Joystick (bottom-left)
                if !engine.isDialogueActive {
                    VStack {
                        Spacer()
                        HStack {
                            JoystickView { direction in
                                engine.updatePlayerDirection3D(direction)
                            }
                            .padding(.leading, 40)
                            .padding(.bottom, 30)
                            Spacer()
                        }
                    }
                }
            }
            .contentShape(Rectangle())
            .onTapGesture { _ in
                if engine.isDialogueActive {
                    engine.advanceDialogue()
                }
            }
            .onAppear {
                engine.setScreenSize(geo.size)
                engine.setup3DScene()
                
                // --- CRITICAL CRASH FIX FOR SIMULATOR ---
                // The Simulator cannot handle Bloom/HDR + Depth Buffers correctly.
                // We forcibly disable them here to ensure the app runs.
                if let camera = engine.sceneManager.cameraNode.camera {
                    camera.wantsHDR = false
                    camera.bloomIntensity = 0
                    camera.wantsDepthOfField = false
                    camera.motionBlurIntensity = 0
                    
                    // Add tuned fog to blend distant floor into the void (Improves look without crashing)
                    engine.sceneManager.scene.fogDensityExponent = 1.5
                }
                // ----------------------------------------
            }
        }
    }
}

// MARK: - Interaction Prompt
struct InteractionPrompt: View {
    let name: String
    @State private var pulse = false
    
    var body: some View {
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
                            .stroke(Color.pink.opacity(glow ? 0.8 : 0.4), lineWidth: 1.5)
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
