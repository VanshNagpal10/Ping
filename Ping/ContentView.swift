//
//  ContentView.swift
//  Ping - Packet World
//
//  Main game flow controller
//

import SwiftUI

struct ContentView: View {
    @StateObject private var engine = GameEngine()
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Phase-based view switching
                Group {
                    switch engine.phase {
                    case .prologue:
                        PrologueView(onStartGame: {
                            engine.setScreenSize(geo.size)
                            engine.startGame()
                        })
                        .transition(.opacity)
                        
                    case .act1_smartphone, .act2_transmission, .act3_oceanFloor, .act4_dnsServer, .act5_return:
                        ExplorationView3D(engine: engine)
                            .transition(.opacity)
                        
                    case .epilogue:
                        EpilogueView(stats: engine.stats, onReplay: {
                            withAnimation {
                                engine.resetGame()
                            }
                        })
                        .transition(.opacity)
                    }
                }
                .animation(.easeInOut(duration: 0.5), value: engine.phase)
                
                // Encyclopedia overlay (Updated transition for the new floating modal design)
                if engine.showEncyclopedia {
                    EncyclopediaView(
                        terms: Array(engine.learnedTerms),
                        onClose: { engine.showEncyclopedia = false }
                    )
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                    .zIndex(100) // Ensures it sits above everything else
                }
                
                // Pause Menu Overlay
                if engine.showPauseMenu {
                    PauseMenuView(engine: engine)
                        .transition(.opacity.combined(with: .scale(scale: 0.95)))
                        .zIndex(300) // Above encyclopedia and notifications
                }
                
                // New term popup notification
                if engine.showNewTermPopup, let term = engine.latestTerm {
                    NewTermPopup(term: term)
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .zIndex(200)
                }
            }
            .onAppear {
                engine.setScreenSize(geo.size)
            }
        }
        .ignoresSafeArea()
        .statusBarHidden(true)
        .persistentSystemOverlays(.hidden)
    }
}

// MARK: - New Term Popup (Upgraded with Glassmorphism)
struct NewTermPopup: View {
    let term: EncyclopediaTerm
    
    var body: some View {
        VStack {
            HStack(spacing: 16) {
                // Glowing Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.cyan.opacity(0.2))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: term.icon)
                        .font(.system(size: 20))
                        .foregroundColor(CyberpunkTheme.neonCyan)
                        .shadow(color: CyberpunkTheme.neonCyan.opacity(0.8), radius: 6)
                }
                .accessibilityHidden(true)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("NEW DATA FRAGMENT ACQUIRED")
                        .font(ScaledFont.scaledFont(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(.cyan)
                        .tracking(1)
                    
                    Text(term.term)
                        .font(ScaledFont.scaledFont(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                // Tech decor
                VStack(spacing: 3) {
                    ForEach(0..<3) { i in
                        Rectangle()
                            .fill(Color.cyan.opacity(0.5))
                            .frame(width: 4, height: 4)
                    }
                }
                .accessibilityHidden(true)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(red: 0.05, green: 0.05, blue: 0.08).opacity(0.85))
                    .background(.ultraThinMaterial) // Glassmorphism blur
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                LinearGradient(
                                    colors: [CyberpunkTheme.neonCyan, CyberpunkTheme.neonMagenta.opacity(0.5)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.5
                            )
                    )
                    .shadow(color: CyberpunkTheme.neonCyan.opacity(0.4), radius: 25, y: 5)
            )
            .accessibilityElement(children: .combine)
            .accessibilityLabel("New data fragment acquired: \(term.term)")
            .padding(.horizontal, 40)
            .padding(.top, 40) // Adjusted slightly to account for notch/dynamic island on newer iPads
            
            Spacer()
        }
    }
}

#Preview {
    ContentView()
}
