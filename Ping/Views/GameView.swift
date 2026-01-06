//
//  GameView.swift
//  Ping
//
//  Main runner gameplay view
//

import SwiftUI
import Combine

struct GameView: View {
    @ObservedObject var engine: GameEngine
    @State private var isThrusting = false
    @State private var scrollOffset: CGFloat = 0
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Zone background
                ZoneBackground(zone: engine.currentZone, scrollOffset: scrollOffset)
                
                // Obstacles
                ForEach(engine.obstacles) { obstacle in
                    ObstacleView(obstacle: obstacle)
                }
                
                // Power-ups
                ForEach(engine.powerUps) { powerUp in
                    PowerUpView(powerUp: powerUp)
                }
                
                // Player packet
                PacketView(packet: engine.packet, isThrusting: isThrusting)
                
                // HUD
                HUDView(
                    latency: engine.latency,
                    maxLatency: engine.maxLatency,
                    currentZone: engine.currentZone,
                    protocolMode: engine.packet.protocolMode,
                    movementStyle: engine.packet.movementStyle,
                    isPaused: engine.isPaused,
                    onToggleProtocol: { engine.toggleProtocol() },
                    onToggleMovement: { engine.toggleMovementStyle() },
                    onPause: { engine.isPaused ? engine.resumeGame() : engine.pauseGame() }
                )
                
                // Pause overlay
                if engine.isPaused {
                    PauseMenuView(
                        currentZone: engine.currentZone,
                        latency: engine.latency,
                        onResume: { engine.resumeGame() },
                        onQuit: { engine.resetGame() }
                    )
                    .transition(.opacity)
                }
                
                // Heavy packet indicator
                if engine.packet.isCarryingPayload {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            PayloadIndicator()
                            Spacer()
                        }
                        .padding(.bottom, 80)
                    }
                }
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        if !isThrusting {
                            isThrusting = true
                            engine.startThrust()
                        }
                    }
                    .onEnded { _ in
                        isThrusting = false
                        engine.stopThrust()
                    }
            )
            .onAppear {
                engine.setScreenSize(geo.size)
                engine.startGame(screenSize: geo.size)
            }
            .onReceive(Timer.publish(every: 0.016, on: .main, in: .common).autoconnect()) { _ in
                if !engine.isPaused {
                    scrollOffset += engine.packet.protocolMode.speedMultiplier * 5
                }
            }
        }
    }
}

// MARK: - Payload Indicator
struct PayloadIndicator: View {
    @State private var pulse = false
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "photo.fill")
            Text("CARRYING PAYLOAD")
                .font(.system(size: 12, weight: .bold, design: .monospaced))
            Text("• HEAVY")
                .font(.system(size: 10, design: .monospaced))
                .foregroundColor(.orange)
        }
        .foregroundColor(.white)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.orange.opacity(0.3))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.orange, lineWidth: 1)
                )
        )
        .scaleEffect(pulse ? 1.02 : 1.0)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                pulse = true
            }
        }
    }
}

#Preview {
    GameView(engine: GameEngine())
}
