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
                        ExplorationView(engine: engine)
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
                
                // Encyclopedia overlay
                if engine.showEncyclopedia {
                    EncyclopediaView(
                        terms: Array(engine.learnedTerms),
                        onClose: { engine.showEncyclopedia = false }
                    )
                    .transition(.move(edge: .trailing))
                }
                
                // New term popup
                if engine.showNewTermPopup, let term = engine.latestTerm {
                    NewTermPopup(term: term)
                        .transition(.move(edge: .top).combined(with: .opacity))
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

// MARK: - New Term Popup
struct NewTermPopup: View {
    let term: EncyclopediaTerm
    
    var body: some View {
        VStack {
            HStack(spacing: 12) {
                Text(term.icon)
                    .font(.title)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("NEW TERM LEARNED!")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(.yellow)
                    
                    Text(term.term)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                Image(systemName: "book.fill")
                    .foregroundColor(.yellow)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.black.opacity(0.9))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.yellow, lineWidth: 2)
                    )
            )
            .padding(.horizontal, 40)
            .padding(.top, 60)
            
            Spacer()
        }
    }
}

#Preview {
    ContentView()
}
