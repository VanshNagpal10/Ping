//
//  EpilogueView.swift
//  Ping - Packet World
//
//  Mission complete - the coffee cup finally falls
//

import SwiftUI

struct EpilogueView: View {
    let stats: JourneyStats
    let onReplay: () -> Void
    
    @State private var showCoffee = false
    @State private var coffeeFall: CGFloat = 0
    @State private var showSmile = false
    @State private var showStats = false
    @State private var showReplay = false
    @State private var feedLoaded = false
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Dark neon background
                LinearGradient(
                    colors: [
                        Color(red: 0.04, green: 0.02, blue: 0.10),
                        Color(red: 0.02, green: 0.01, blue: 0.06)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                
                // The scene resumes
                VStack {
                    Spacer()
                    
                    HStack(spacing: 40) {
                        // Coffee cup falling and splashing
                        ZStack {
                            if showCoffee {
                                FallingCoffeeCup(fallProgress: coffeeFall)
                                
                                // Splash effect
                                if coffeeFall >= 1.0 {
                                    CoffeeSplash()
                                        .transition(.scale)
                                }
                            }
                        }
                        .offset(y: -100)
                        
                        // The girl - now smiling!
                        EpilogueGirl(smiling: showSmile, feedLoaded: feedLoaded)
                    }
                    .padding(.bottom, geo.size.height * 0.15)
                }
                
                // Success message
                VStack(spacing: 20) {
                    if feedLoaded {
                        VStack(spacing: 8) {
                            Text("✨ MISSION COMPLETE ✨")
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundColor(.cyan)
                                .shadow(color: .cyan.opacity(0.5), radius: 10)
                            
                            Text("The feed loaded in the blink of an eye!")
                                .font(.system(size: 16, design: .serif))
                                .foregroundColor(.white.opacity(0.7))
                            
                            Text("(To her, it was instant. To you, it was an adventure.)")
                                .font(.system(size: 12, design: .serif))
                                .foregroundColor(.white.opacity(0.4))
                        }
                        .padding()
                        .transition(.opacity)
                    }
                    
                    Spacer()
                }
                .padding(.top, 60)
                
                // Stats panel
                if showStats {
                    VStack {
                        Spacer()
                        
                        JourneyStatsPanel(stats: stats)
                            .padding(.horizontal, 40)
                        
                        if showReplay {
                            Button(action: onReplay) {
                                HStack(spacing: 12) {
                                    Image(systemName: "arrow.counterclockwise")
                                    Text("Play Again")
                                }
                                .font(.system(size: 18, weight: .semibold, design: .rounded))
                                .foregroundColor(.black)
                                .padding(.horizontal, 32)
                                .padding(.vertical, 16)
                                .background(
                                    Capsule()
                                        .fill(
                                            LinearGradient(
                                                colors: [.cyan, Color(red: 0.0, green: 0.7, blue: 1.0)],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                )
                                .shadow(color: .cyan.opacity(0.5), radius: 15, y: 5)
                            }
                            .padding(.top, 20)
                            .transition(.move(edge: .bottom))
                        }
                        
                        Spacer().frame(height: 40)
                    }
                }
            }
        }
        .onAppear {
            startEpilogue()
        }
    }
    
    private func startEpilogue() {
        // Show coffee and let it fall
        withAnimation(.easeIn(duration: 0.3)) {
            showCoffee = true
        }
        
        withAnimation(.easeIn(duration: 0.8).delay(0.5)) {
            coffeeFall = 1.0
        }
        
        // Girl smiles as feed loads
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation(.spring()) {
                showSmile = true
                feedLoaded = true
            }
        }
        
        // Show stats
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation(.easeOut(duration: 0.5)) {
                showStats = true
            }
        }
        
        // Show replay button
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            withAnimation(.spring()) {
                showReplay = true
            }
        }
    }
}

// MARK: - Falling Coffee Cup
struct FallingCoffeeCup: View {
    let fallProgress: CGFloat
    
    var body: some View {
        ZStack {
            // Cup body
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.white)
                .frame(width: 30, height: 40)
            
            // Coffee
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.brown)
                .frame(width: 24, height: 30)
                .offset(y: -2)
        }
        .rotationEffect(.degrees(Double(fallProgress) * 90))
        .offset(y: fallProgress * 150)
    }
}

// MARK: - Coffee Splash
struct CoffeeSplash: View {
    @State private var expand = false
    
    var body: some View {
        ZStack {
            ForEach(0..<8, id: \.self) { i in
                Circle()
                    .fill(Color.brown.opacity(0.6))
                    .frame(width: 10, height: 10)
                    .offset(
                        x: expand ? cos(CGFloat(i) * .pi / 4) * 30 : 0,
                        y: expand ? sin(CGFloat(i) * .pi / 4) * 30 + 150 : 150
                    )
            }
            
            // Puddle
            Ellipse()
                .fill(Color.brown.opacity(0.4))
                .frame(width: expand ? 60 : 20, height: expand ? 20 : 5)
                .offset(y: 160)
        }
        .onAppear {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                expand = true
            }
        }
    }
}

// MARK: - Epilogue Girl
struct EpilogueGirl: View {
    let smiling: Bool
    let feedLoaded: Bool
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // Head
                Circle()
                    .fill(Color(red: 0.95, green: 0.8, blue: 0.7))
                    .frame(width: 50, height: 50)
                    .overlay(
                        Ellipse()
                            .fill(Color.brown)
                            .frame(width: 55, height: 35)
                            .offset(y: -15)
                    )
                    .overlay(
                        VStack(spacing: 4) {
                            HStack(spacing: 12) {
                                // Eyes - happy when smiling
                                if smiling {
                                    Text("^").font(.system(size: 8, weight: .bold)).foregroundColor(.black)
                                    Text("^").font(.system(size: 8, weight: .bold)).foregroundColor(.black)
                                } else {
                                    Circle().fill(.black).frame(width: 6, height: 6)
                                    Circle().fill(.black).frame(width: 6, height: 6)
                                }
                            }
                            // Big smile
                            if smiling {
                                Text("😊")
                                    .font(.system(size: 16))
                                    .offset(y: -5)
                            } else {
                                Capsule()
                                    .fill(Color(red: 0.9, green: 0.6, blue: 0.6))
                                    .frame(width: 12, height: 4)
                            }
                        }
                        .offset(y: 5)
                    )
                
                // Body
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.pink.opacity(0.7))
                    .frame(width: 60, height: 80)
                
                // Arms
                HStack(spacing: 30) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(red: 0.95, green: 0.8, blue: 0.7))
                        .frame(width: 12, height: 40)
                        .rotationEffect(.degrees(30))
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(red: 0.95, green: 0.8, blue: 0.7))
                        .frame(width: 12, height: 40)
                        .rotationEffect(.degrees(-30))
                }
                .offset(y: -50)
            }
            
            // Phone showing feed
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.black)
                    .frame(width: 35, height: 60)
                
                RoundedRectangle(cornerRadius: 6)
                    .fill(feedLoaded ? Color.white : Color.gray.opacity(0.3))
                    .frame(width: 30, height: 52)
                
                // Feed content
                if feedLoaded {
                    VStack(spacing: 3) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.pink.opacity(0.5))
                            .frame(width: 26, height: 15)
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.blue.opacity(0.5))
                            .frame(width: 26, height: 15)
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.green.opacity(0.5))
                            .frame(width: 26, height: 15)
                    }
                }
            }
            .offset(y: 30)
        }
    }
}

// MARK: - Journey Stats Panel
struct JourneyStatsPanel: View {
    let stats: JourneyStats
    
    var body: some View {
        VStack(spacing: 16) {
            Text("YOUR JOURNEY")
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .foregroundColor(.cyan)
            
            HStack(spacing: 30) {
                StatBadge(
                    icon: "clock",
                    value: stats.formattedDuration,
                    label: "Time"
                )
                
                StatBadge(
                    icon: "book.fill",
                    value: "\(stats.termsLearned.count)",
                    label: "Terms Learned"
                )
                
                StatBadge(
                    icon: "person.2.fill",
                    value: "\(stats.npcsSpokenTo.count)",
                    label: "NPCs Met"
                )
                
                StatBadge(
                    icon: "map.fill",
                    value: "\(stats.scenesVisited.count)",
                    label: "Places"
                )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.black.opacity(0.8))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.cyan.opacity(0.5), lineWidth: 1)
                )
        )
    }
}

struct StatBadge: View {
    let icon: String
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.cyan)
            
            Text(value)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
            Text(label)
                .font(.system(size: 10, design: .rounded))
                .foregroundColor(.gray)
        }
    }
}

#Preview {
    EpilogueView(stats: JourneyStats(), onReplay: {})
}
