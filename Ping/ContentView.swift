//
//  ContentView.swift
//  Ping
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
                switch engine.phase {
                case .intro:
                    IntroView(onStartGame: {
                        engine.setScreenSize(geo.size)
                        engine.startTransition()
                    })
                    .transition(.opacity)
                    
                case .transition:
                    TransitionView(onComplete: {
                        // Game starts automatically after transition
                    })
                    .transition(.opacity)
                    
                case .playing, .returning:
                    GameView(engine: engine)
                        .transition(.opacity)
                    
                case .handshake:
                    HandshakeView(engine: engine)
                        .transition(.opacity)
                    
                case .debrief:
                    DebriefView(stats: engine.stats, onReplay: {
                        withAnimation {
                            engine.resetGame()
                        }
                    })
                    .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.5), value: engine.phase)
        }
        .ignoresSafeArea()
        .statusBarHidden(true)
        .persistentSystemOverlays(.hidden)
    }
}

#Preview(traits: .landscapeRight) {
    ContentView()
}
