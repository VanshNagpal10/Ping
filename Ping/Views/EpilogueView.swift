//
//  EpilogueView.swift
//  Ping - Packet World
//
//  Mission complete — the coffee cup finally falls.
//  Full cyberpunk epilogue with cinematic sequence,
//  animated stats, journey recap, and replay prompt.
//

import SwiftUI

// MARK: - Main Epilogue View
struct EpilogueView: View {
    let stats: JourneyStats
    let onReplay: () -> Void

    // Neon palette (matches PrologueView)
    private let nCyan    = Color(red: 0.0, green: 0.9, blue: 1.0)
    private let nMagenta = Color(red: 1.0, green: 0.1, blue: 0.6)
    private let nViolet  = Color(red: 0.6, green: 0.2, blue: 1.0)
    private let nAmber   = Color(red: 1.0, green: 0.75, blue: 0.0)

    // Phase timing
    @State private var phase: EpiloguePhase = .blackout
    @State private var showCoffee = false
    @State private var coffeeFall: CGFloat = 0
    @State private var showSmile = false
    @State private var feedLoaded = false
    @State private var showMissionComplete = false
    @State private var showSubtitle = false
    @State private var showPerspective = false
    @State private var showStats = false
    @State private var showJourneyRoute = false
    @State private var showReplay = false
    @State private var gridScroll: CGFloat = 0
    @State private var ringPulse: CGFloat = 0.4
    @State private var glowPulse = false
    @State private var particleSeed: Double = 0
    
    private enum EpiloguePhase {
        case blackout, cafeScene, missionTitle, statsReveal
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // ── Layer 0: Deep void background ──
                Color(red: 0.02, green: 0.01, blue: 0.06)
                    .ignoresSafeArea()

                // ── Layer 1: Cyber grid floor (same as prologue) ──
                EpilogueCyberGrid(scroll: gridScroll, color: nCyan)
                    .opacity(phase != .blackout ? 0.25 : 0)

                // ── Layer 2: Radial glow ──
                RadialGradient(
                    colors: [nViolet.opacity(0.12), nCyan.opacity(0.04), .clear],
                    center: .center,
                    startRadius: 20,
                    endRadius: geo.size.width * 0.7
                )
                .opacity(phase != .blackout ? 1 : 0)

                // ── Layer 3: Floating neon particles ──
                EpilogueParticles(colors: [nCyan, nMagenta, nViolet, nAmber], seed: particleSeed)
                    .opacity(phase != .blackout ? 0.6 : 0)

                // ── Layer 4: Falling data streams ──
                EpilogueDataStreams(color: nCyan)
                    .opacity(phase != .blackout ? 0.18 : 0)

                // ── Layer 5: Scan-line CRT overlay ──
                EpilogueScanLines()
                    .opacity(phase != .blackout ? 0.05 : 0)

                // ── Layer 6: Café scene (girl + coffee + phone) ──
                VStack {
                    Spacer()
                    HStack(spacing: 36) {
                        // Coffee cup falling & splashing
                        ZStack {
                            if showCoffee {
                                FallingCoffeeCup(fallProgress: coffeeFall, accentColor: nAmber)
                                if coffeeFall >= 1.0 {
                                    CoffeeSplash(accentColor: nAmber)
                                        .transition(.scale.combined(with: .opacity))
                                }
                            }
                        }
                        .frame(width: 80)
                        .offset(y: -80)

                        // The girl — now smiling
                        EpilogueGirl(smiling: showSmile, feedLoaded: feedLoaded, accentColor: nCyan, magentaColor: nMagenta)
                    }
                    .padding(.bottom, geo.size.height * 0.13)
                }
                .opacity(phase == .blackout ? 0 : 1)

                // ── Layer 7: Expanding ring pulses behind title ──
                if showMissionComplete {
                    ForEach(0..<3, id: \.self) { i in
                        Circle()
                            .stroke(nCyan.opacity(0.15 - Double(i) * 0.04), lineWidth: 1.5)
                            .frame(
                                width: 100 + CGFloat(i) * 70,
                                height: 100 + CGFloat(i) * 70
                            )
                            .scaleEffect(ringPulse)
                            .opacity(Double(2.0 - ringPulse))
                            .position(x: geo.size.width / 2, y: geo.size.height * 0.14)
                    }
                }

                // ── Layer 8: Mission Complete text ──
                VStack(spacing: 20) {
                    Spacer().frame(height: geo.size.height * 0.06)

                    if showMissionComplete {
                        VStack(spacing: 6) {
                            Text("MISSION")
                                .font(.system(size: 14, weight: .light, design: .monospaced))
                                .foregroundColor(.white.opacity(0.4))
                                .tracking(8)
                                .transition(.opacity)

                            Text("COMPLETE")
                                .font(.system(size: 42, weight: .black, design: .monospaced))
                                .foregroundColor(nCyan)
                                .shadow(color: nCyan.opacity(0.8), radius: 20)
                                .shadow(color: nCyan.opacity(0.4), radius: 40)
                                .shadow(color: nMagenta.opacity(0.2), radius: 60)
                                .tracking(8)
                                .transition(.scale(scale: 0.7).combined(with: .opacity))
                        }
                    }

                    if showSubtitle {
                        EpilogueTypewriterText(
                            text: "The feed loaded in the blink of an eye.",
                            font: .system(size: 16, weight: .regular, design: .monospaced)
                        )
                        .foregroundColor(.white.opacity(0.6))
                        .shadow(color: nCyan.opacity(0.2), radius: 8)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                        .transition(.opacity)
                    }

                    if showPerspective {
                        EpilogueTypewriterText(
                            text: "To her, it was instant. To you, it was an adventure.",
                            font: .system(size: 13, weight: .medium, design: .monospaced)
                        )
                        .foregroundColor(nMagenta.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                        .transition(.opacity)
                    }

                    Spacer()
                }

                // ── Layer 9: Stats + Journey Route + Replay ──
                if showStats {
                    VStack(spacing: 0) {
                        Spacer()

                        // Journey route visualizer
                        if showJourneyRoute {
                            JourneyRouteStrip(
                                scenes: stats.scenesVisited,
                                accentColor: nCyan,
                                magenta: nMagenta,
                                violet: nViolet
                            )
                            .padding(.horizontal, 30)
                            .padding(.bottom, 14)
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                        }

                        JourneyStatsPanel(
                            stats: stats,
                            accentColor: nCyan,
                            magenta: nMagenta
                        )
                        .padding(.horizontal, 30)
                        .transition(.move(edge: .bottom).combined(with: .opacity))

                        if showReplay {
                            Button(action: onReplay) {
                                HStack(spacing: 12) {
                                    Text("Replay Journey")
                                        .font(.system(size: 17, weight: .bold, design: .monospaced))
                                        .tracking(2)

                                    Image(systemName: "chevron.right.2")
                                        .font(.system(size: 16, weight: .bold))
                                }
                                .foregroundColor(.black)
                                .padding(.horizontal, 36)
                                .padding(.vertical, 16)
                                .background(
                                    Capsule()
                                        .fill(
                                            LinearGradient(
                                                colors: [nCyan, Color(red: 0.3, green: 0.95, blue: 1.0)],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                )
                                .overlay(
                                    Capsule()
                                        .stroke(nCyan.opacity(0.6), lineWidth: 1)
                                )
                                .shadow(color: nCyan.opacity(0.5), radius: 25, y: 4)
                                .shadow(color: nMagenta.opacity(0.15), radius: 40, y: 8)
                            }
                            .scaleEffect(glowPulse ? 1.04 : 1.0)
                            .padding(.top, 20)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                        }

                        Spacer().frame(height: 40)
                    }
                }

                // ── Layer 10: Title badge (top-left, matches prologue) ──
                VStack {
                    HStack {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("PING")
                                .font(.system(size: 20, weight: .black, design: .monospaced))
                                .foregroundColor(nCyan)
                                .shadow(color: nCyan.opacity(0.6), radius: 10)
                                .tracking(4)

                            Text("A Journey Through the Internet")
                                .font(.system(size: 9, weight: .medium, design: .monospaced))
                                .foregroundColor(.white.opacity(0.3))
                                .tracking(1)
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                    .opacity(phase != .blackout ? 1 : 0)
                    Spacer()
                }
            }
        }
        .onAppear { startEpilogue() }
    }

    // MARK: – Cinematic Timeline
    private func startEpilogue() {
        // Continuous grid scroll
        withAnimation(.linear(duration: 25).repeatForever(autoreverses: false)) {
            gridScroll = 1
        }

        // 0.0s — Fade in scene
        withAnimation(.easeOut(duration: 1.0)) {
            phase = .cafeScene
        }

        // 0.4s — Coffee appears
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            withAnimation(.easeIn(duration: 0.3)) { showCoffee = true }
        }

        // 0.8s — Coffee falls
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            withAnimation(.easeIn(duration: 0.7)) { coffeeFall = 1.0 }
        }

        // 1.6s — Girl smiles, feed loads
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                showSmile = true
                feedLoaded = true
            }
        }

        // 2.4s — MISSION COMPLETE title
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.4) {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                phase = .missionTitle
                showMissionComplete = true
            }
            withAnimation(.easeOut(duration: 2.5).repeatForever(autoreverses: false)) {
                ringPulse = 2.0
            }
        }

        // 3.4s — Subtitle typewriter
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.4) {
            withAnimation(.easeIn(duration: 0.6)) { showSubtitle = true }
        }

        // 5.0s — Perspective line
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            withAnimation(.easeIn(duration: 0.6)) { showPerspective = true }
        }

        // 6.6s — Stats panel
        DispatchQueue.main.asyncAfter(deadline: .now() + 6.6) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                phase = .statsReveal
                showStats = true
            }
        }

        // 7.2s — Journey route
        DispatchQueue.main.asyncAfter(deadline: .now() + 7.2) {
            withAnimation(.easeOut(duration: 0.6)) { showJourneyRoute = true }
        }

        // 8.0s — Replay button
        DispatchQueue.main.asyncAfter(deadline: .now() + 8.0) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                showReplay = true
            }
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                glowPulse = true
            }
        }
    }
}

// MARK: - Journey Route Strip
/// Horizontal strip showing each scene the player visited, connected by neon lines.
struct JourneyRouteStrip: View {
    let scenes: [StoryScene]
    let accentColor: Color
    let magenta: Color
    let violet: Color

    @State private var lineProgress: CGFloat = 0

    private var uniqueScenes: [StoryScene] {
        // Preserve order, deduplicate
        var seen = Set<StoryScene>()
        return scenes.filter { seen.insert($0).inserted }
    }

    var body: some View {
        VStack(spacing: 8) {
            Text("ROUTE TAKEN")
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundColor(accentColor.opacity(0.7))
                .tracking(3)

            GeometryReader { geo in
                let count = max(uniqueScenes.count, 1)
                let spacing = geo.size.width / CGFloat(count + 1)

                ZStack {
                    // Connecting line
                    Path { path in
                        for (i, _) in uniqueScenes.enumerated() {
                            let x = spacing * CGFloat(i + 1)
                            if i == 0 { path.move(to: CGPoint(x: x, y: 14)) }
                            else { path.addLine(to: CGPoint(x: x, y: 14)) }
                        }
                    }
                    .trim(from: 0, to: lineProgress)
                    .stroke(
                        LinearGradient(
                            colors: [accentColor, magenta, violet],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        style: StrokeStyle(lineWidth: 2, lineCap: .round)
                    )

                    // Scene nodes
                    ForEach(Array(uniqueScenes.enumerated()), id: \.element) { i, scene in
                        VStack(spacing: 4) {
                            Circle()
                                .fill(scene.accentColor)
                                .frame(width: 10, height: 10)
                                .shadow(color: scene.accentColor.opacity(0.7), radius: 6)

                            Text(sceneIcon(for: scene))
                                .font(.system(size: 10))
                        }
                        .position(x: spacing * CGFloat(i + 1), y: 14)
                    }
                }
            }
            .frame(height: 40)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.6))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(accentColor.opacity(0.2), lineWidth: 1)
                )
        )
        .onAppear {
            withAnimation(.easeInOut(duration: 1.4).delay(0.2)) {
                lineProgress = 1
            }
        }
    }

    private func sceneIcon(for scene: StoryScene) -> String {
        switch scene {
        case .frozenCafe: return "☕"
        case .cpuCity: return "🏙️"
        case .wifiAntenna: return "📡"
        case .routerStation: return "🔀"
        case .oceanCable: return "🌊"
        case .dnsLibrary: return "📚"
        case .returnJourney: return "🏠"
        case .feedLoaded: return "✅"
        }
    }
}

// MARK: - Falling Coffee Cup (Improved)
struct FallingCoffeeCup: View {
    let fallProgress: CGFloat
    let accentColor: Color

    var body: some View {
        ZStack {
            // Handle
            RoundedRectangle(cornerRadius: 3)
                .stroke(Color.white.opacity(0.8), lineWidth: 2)
                .frame(width: 12, height: 16)
                .offset(x: 18, y: -4)

            // Cup body
            UnevenRoundedRectangle(
                topLeadingRadius: 2,
                bottomLeadingRadius: 6,
                bottomTrailingRadius: 6,
                topTrailingRadius: 2
            )
            .fill(Color.white)
            .frame(width: 30, height: 38)

            // Coffee surface
            RoundedRectangle(cornerRadius: 2)
                .fill(
                    LinearGradient(
                        colors: [Color(red: 0.45, green: 0.25, blue: 0.1), Color(red: 0.35, green: 0.18, blue: 0.05)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 24, height: 28)
                .offset(y: 2)

            // Steam wisps (only before falling)
            if fallProgress < 0.1 {
                ForEach(0..<3, id: \.self) { i in
                    SteamWisp()
                        .offset(x: CGFloat(i - 1) * 8, y: -26)
                }
            }
        }
        .rotationEffect(.degrees(Double(fallProgress) * 110))
        .offset(y: fallProgress * 140)
        .opacity(fallProgress >= 1.0 ? 0.3 : 1.0)
    }
}

struct SteamWisp: View {
    @State private var rise: CGFloat = 0
    @State private var fade: CGFloat = 0.5

    var body: some View {
        Circle()
            .fill(Color.white.opacity(fade))
            .frame(width: 4, height: 4)
            .offset(y: rise)
            .onAppear {
                withAnimation(.easeOut(duration: 1.5).repeatForever(autoreverses: false)) {
                    rise = -18
                    fade = 0
                }
            }
    }
}

// MARK: - Coffee Splash (Improved)
struct CoffeeSplash: View {
    let accentColor: Color
    @State private var expand = false

    var body: some View {
        ZStack {
            // Spray droplets
            ForEach(0..<12, id: \.self) { i in
                Circle()
                    .fill(Color(red: 0.45, green: 0.25, blue: 0.1).opacity(0.7))
                    .frame(width: CGFloat(4 + i % 4 * 2), height: CGFloat(4 + i % 4 * 2))
                    .offset(
                        x: expand ? cos(CGFloat(i) * .pi / 6) * CGFloat(20 + i * 3) : 0,
                        y: expand ? sin(CGFloat(i) * .pi / 6) * CGFloat(15 + i * 2) + 140 : 140
                    )
                    .opacity(expand ? 0 : 0.8)
            }

            // Impact ring
            Circle()
                .stroke(Color(red: 0.45, green: 0.25, blue: 0.1).opacity(expand ? 0 : 0.5), lineWidth: 2)
                .frame(width: expand ? 80 : 10, height: expand ? 80 : 10)
                .offset(y: 150)

            // Puddle
            Ellipse()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(red: 0.45, green: 0.25, blue: 0.1).opacity(0.5),
                            Color(red: 0.35, green: 0.18, blue: 0.05).opacity(0.2)
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 35
                    )
                )
                .frame(width: expand ? 70 : 15, height: expand ? 18 : 4)
                .offset(y: 158)
        }
        .onAppear {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.5)) {
                expand = true
            }
        }
    }
}

// MARK: - Epilogue Girl (Improved)
struct EpilogueGirl: View {
    let smiling: Bool
    let feedLoaded: Bool
    let accentColor: Color
    let magentaColor: Color

    @State private var bob: CGFloat = 0
    
    private let skin = Color(red: 0.95, green: 0.82, blue: 0.72)
    private let hair = Color(red: 0.22, green: 0.14, blue: 0.08)

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // Head
                ZStack {
                    // Hair back
                    Ellipse()
                        .fill(hair)
                        .frame(width: 58, height: 40)
                        .offset(y: -10)

                    // Face
                    Circle()
                        .fill(skin)
                        .frame(width: 50, height: 50)

                    // Hair bangs
                    Ellipse()
                        .fill(hair)
                        .frame(width: 54, height: 22)
                        .offset(y: -18)

                    // Side hair
                    HStack(spacing: 36) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(hair)
                            .frame(width: 10, height: 30)
                        RoundedRectangle(cornerRadius: 4)
                            .fill(hair)
                            .frame(width: 10, height: 30)
                    }
                    .offset(y: 8)

                    // Face features
                    VStack(spacing: 5) {
                        HStack(spacing: 14) {
                            if smiling {
                                // Happy eyes (arcs)
                                EyeArc().frame(width: 8, height: 5)
                                EyeArc().frame(width: 8, height: 5)
                            } else {
                                Circle().fill(.black).frame(width: 5, height: 5)
                                Circle().fill(.black).frame(width: 5, height: 5)
                            }
                        }

                        // Mouth
                        if smiling {
                            SmileArc()
                                .frame(width: 14, height: 7)
                        } else {
                            Capsule()
                                .fill(Color(red: 0.9, green: 0.55, blue: 0.55))
                                .frame(width: 10, height: 3)
                        }

                        // Blush when smiling
                        if smiling {
                            HStack(spacing: 18) {
                                Circle()
                                    .fill(Color.pink.opacity(0.35))
                                    .frame(width: 10, height: 10)
                                Circle()
                                    .fill(Color.pink.opacity(0.35))
                                    .frame(width: 10, height: 10)
                            }
                            .offset(y: -6)
                        }
                    }
                    .offset(y: 4)
                }

                // Body
                ZStack {
                    // Torso
                    UnevenRoundedRectangle(
                        topLeadingRadius: 14,
                        bottomLeadingRadius: 6,
                        bottomTrailingRadius: 6,
                        topTrailingRadius: 14
                    )
                    .fill(
                        LinearGradient(
                            colors: [magentaColor.opacity(0.7), Color.pink.opacity(0.6)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 55, height: 70)
                }

                // Legs
                HStack(spacing: 6) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(red: 0.2, green: 0.2, blue: 0.3))
                        .frame(width: 14, height: 30)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(red: 0.2, green: 0.2, blue: 0.3))
                        .frame(width: 14, height: 30)
                }
            }

            // Arms (holding phone)
            HStack(spacing: 24) {
                RoundedRectangle(cornerRadius: 5)
                    .fill(skin)
                    .frame(width: 12, height: 36)
                    .rotationEffect(.degrees(25))

                RoundedRectangle(cornerRadius: 5)
                    .fill(skin)
                    .frame(width: 12, height: 36)
                    .rotationEffect(.degrees(-25))
            }
            .offset(y: 18)

            // Phone
            PhoneWithFeed(feedLoaded: feedLoaded, accentColor: accentColor, magenta: magentaColor)
                .offset(y: 32)
        }
        .offset(y: bob)
        .onAppear {
            withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
                bob = -4
            }
        }
    }
}

// MARK: - Eye Arc (Happy Eyes)
struct EyeArc: View {
    var body: some View {
        Path { p in
            p.move(to: CGPoint(x: 0, y: 5))
            p.addQuadCurve(to: CGPoint(x: 8, y: 5), control: CGPoint(x: 4, y: 0))
        }
        .stroke(Color.black, lineWidth: 1.5)
    }
}

// MARK: - Smile Arc
struct SmileArc: View {
    var body: some View {
        Path { p in
            p.move(to: CGPoint(x: 0, y: 0))
            p.addQuadCurve(to: CGPoint(x: 14, y: 0), control: CGPoint(x: 7, y: 9))
        }
        .stroke(Color(red: 0.85, green: 0.4, blue: 0.4), lineWidth: 1.5)
    }
}

// MARK: - Phone With Feed
struct PhoneWithFeed: View {
    let feedLoaded: Bool
    let accentColor: Color
    let magenta: Color

    var body: some View {
        ZStack {
            // Phone body
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(red: 0.1, green: 0.08, blue: 0.14))
                .frame(width: 36, height: 62)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(
                            feedLoaded
                                ? LinearGradient(colors: [accentColor, magenta], startPoint: .top, endPoint: .bottom)
                                : LinearGradient(colors: [Color.white.opacity(0.1), Color.white.opacity(0.05)], startPoint: .top, endPoint: .bottom),
                            lineWidth: feedLoaded ? 1.5 : 0.5
                        )
                )
                .shadow(color: feedLoaded ? accentColor.opacity(0.4) : .clear, radius: 12)

            // Screen
            RoundedRectangle(cornerRadius: 7)
                .fill(feedLoaded
                      ? LinearGradient(colors: [Color.white, Color(red: 0.95, green: 0.95, blue: 1.0)], startPoint: .top, endPoint: .bottom)
                      : LinearGradient(colors: [Color.gray.opacity(0.15), Color.gray.opacity(0.1)], startPoint: .top, endPoint: .bottom)
                )
                .frame(width: 30, height: 54)

            // Feed content
            if feedLoaded {
                VStack(spacing: 3) {
                    // Header bar
                    RoundedRectangle(cornerRadius: 1)
                        .fill(accentColor.opacity(0.3))
                        .frame(width: 26, height: 5)

                    // Feed posts
                    ForEach(0..<3, id: \.self) { i in
                        RoundedRectangle(cornerRadius: 2)
                            .fill([Color.pink, Color.blue, Color.green][i].opacity(0.45))
                            .frame(width: 26, height: 12)
                    }
                }
            } else {
                // Loading spinner placeholder
                ProgressView()
                    .scaleEffect(0.4)
                    .tint(.white.opacity(0.4))
            }
        }
    }
}

// MARK: - Journey Stats Panel (Redesigned)
struct JourneyStatsPanel: View {
    let stats: JourneyStats
    let accentColor: Color
    let magenta: Color

    @State private var revealedStats = 0

    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 8) {
                Rectangle()
                    .fill(accentColor.opacity(0.4))
                    .frame(height: 1)
                Text("YOUR JOURNEY")
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundColor(accentColor)
                    .tracking(4)
                Rectangle()
                    .fill(accentColor.opacity(0.4))
                    .frame(height: 1)
            }

            HStack(spacing: 0) {
                StatBadge(
                    icon: "clock",
                    value: stats.formattedDuration,
                    label: "Time",
                    accent: accentColor,
                    revealed: revealedStats >= 1
                )
                .frame(maxWidth: .infinity)

                StatDivider(color: accentColor)

                StatBadge(
                    icon: "book.fill",
                    value: "\(stats.termsLearned.count)",
                    label: "Terms",
                    accent: Color(red: 1.0, green: 0.75, blue: 0.0),
                    revealed: revealedStats >= 2
                )
                .frame(maxWidth: .infinity)

                StatDivider(color: accentColor)

                StatBadge(
                    icon: "person.2.fill",
                    value: "\(stats.npcsSpokenTo.count)",
                    label: "NPCs",
                    accent: magenta,
                    revealed: revealedStats >= 3
                )
                .frame(maxWidth: .infinity)

                StatDivider(color: accentColor)

                StatBadge(
                    icon: "map.fill",
                    value: "\(stats.scenesVisited.count)",
                    label: "Places",
                    accent: Color(red: 0.6, green: 0.2, blue: 1.0),
                    revealed: revealedStats >= 4
                )
                .frame(maxWidth: .infinity)
            }
            
            // Choice outcomes row
            if !stats.choicesMade.isEmpty {
                Rectangle()
                    .fill(accentColor.opacity(0.3))
                    .frame(height: 1)
                    .padding(.vertical, 4)
                
                HStack(spacing: 0) {
                    StatBadge(
                        icon: stats.chosenProtocol == .udp ? "bolt.fill" : "checkmark.shield.fill",
                        value: stats.chosenProtocol.rawValue,
                        label: "Protocol",
                        accent: stats.chosenProtocol == .udp ? .orange : .green,
                        revealed: revealedStats >= 5
                    )
                    .frame(maxWidth: .infinity)
                    
                    StatDivider(color: accentColor)
                    
                    StatBadge(
                        icon: stats.upgradedToSSL ? "lock.fill" : "lock.open.fill",
                        value: stats.upgradedToSSL ? "SSL" : "None",
                        label: "Security",
                        accent: stats.upgradedToSSL ? .green : .red,
                        revealed: revealedStats >= 5
                    )
                    .frame(maxWidth: .infinity)
                    
                    StatDivider(color: accentColor)
                    
                    StatBadge(
                        icon: stats.lostPacketData ? "exclamationmark.triangle.fill" : "checkmark.circle.fill",
                        value: stats.lostPacketData ? "Lost" : "Intact",
                        label: "Data",
                        accent: stats.lostPacketData ? .red : .green,
                        revealed: revealedStats >= 5
                    )
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.black.opacity(0.85))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            LinearGradient(
                                colors: [accentColor.opacity(0.5), magenta.opacity(0.3)],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            lineWidth: 1
                        )
                )
                .shadow(color: accentColor.opacity(0.15), radius: 20, y: 5)
        )
        .onAppear { revealStatsSequentially() }
    }

    private func revealStatsSequentially() {
        for i in 1...4 {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.25) {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    revealedStats = i
                }
            }
        }
    }
}

struct StatDivider: View {
    let color: Color
    var body: some View {
        Rectangle()
            .fill(color.opacity(0.15))
            .frame(width: 1, height: 50)
    }
}

struct StatBadge: View {
    let icon: String
    let value: String
    let label: String
    let accent: Color
    let revealed: Bool

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(accent)
                .shadow(color: accent.opacity(0.5), radius: 6)

            Text(value)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(.white)

            Text(label)
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .foregroundColor(.gray)
                .tracking(1)
        }
        .scaleEffect(revealed ? 1 : 0.5)
        .opacity(revealed ? 1 : 0)
    }
}

// MARK: - Epilogue Cyber Grid
struct EpilogueCyberGrid: View {
    let scroll: CGFloat
    let color: Color

    var body: some View {
        GeometryReader { geo in
            Canvas { context, size in
                let lineColor = color.opacity(0.25)
                let horizon: CGFloat = size.height * 0.42
                let lineCount = 18
                for i in 0..<lineCount {
                    let t = CGFloat(i) / CGFloat(lineCount)
                    let adjusted = t + scroll.truncatingRemainder(dividingBy: 1.0 / CGFloat(lineCount))
                    let y = horizon + pow(adjusted, 1.8) * (size.height - horizon)
                    var path = Path()
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: size.width, y: y))
                    context.stroke(path, with: .color(lineColor), lineWidth: 0.6)
                }
                let vCount = 14
                let vanishX = size.width / 2
                for i in 0...vCount {
                    let t = CGFloat(i) / CGFloat(vCount)
                    let bottomX = t * size.width
                    let topX = vanishX + (bottomX - vanishX) * 0.15
                    var path = Path()
                    path.move(to: CGPoint(x: topX, y: horizon))
                    path.addLine(to: CGPoint(x: bottomX, y: size.height))
                    context.stroke(path, with: .color(lineColor), lineWidth: 0.5)
                }
            }
        }
    }
}

// MARK: - Epilogue Particles
struct EpilogueParticles: View {
    let colors: [Color]
    let seed: Double

    var body: some View {
        Canvas { context, canvasSize in
            for i in 0..<50 {
                let s = Double(i) * 137.508 + seed
                let x = CGFloat((sin(s) * 0.5 + 0.5)) * canvasSize.width
                let y = CGFloat((cos(s * 0.7) * 0.5 + 0.5)) * canvasSize.height
                let radius: CGFloat = CGFloat(i % 4 == 0 ? 2.5 : 1.0)
                let rect = CGRect(x: x - radius, y: y - radius, width: radius * 2, height: radius * 2)
                let ci = i % colors.count
                context.fill(Circle().path(in: rect), with: .color(colors[ci].opacity(0.4)))
            }
        }
    }
}

// MARK: - Epilogue Data Streams
struct EpilogueDataStreams: View {
    let color: Color
    @State private var offset: CGFloat = 0

    var body: some View {
        Canvas { context, canvasSize in
            for i in 0..<12 {
                let x = CGFloat(i) * (canvasSize.width / 12) + 15
                let lineHeight: CGFloat = CGFloat(35 + (i * 41) % 70)
                let y = ((offset * canvasSize.height * 1.5 + CGFloat(i) * 70)
                    .truncatingRemainder(dividingBy: canvasSize.height + lineHeight)) - lineHeight
                var path = Path()
                path.move(to: CGPoint(x: x, y: y))
                path.addLine(to: CGPoint(x: x, y: y + lineHeight))
                context.stroke(path, with: .color(color.opacity(0.15)), lineWidth: 1)
            }
        }
        .onAppear {
            withAnimation(.linear(duration: 7).repeatForever(autoreverses: false)) {
                offset = 1
            }
        }
    }
}

// MARK: - Epilogue Scan Lines
struct EpilogueScanLines: View {
    var body: some View {
        Canvas { context, size in
            for y in stride(from: 0, to: size.height, by: 3) {
                var path = Path()
                path.move(to: CGPoint(x: 0, y: y))
                path.addLine(to: CGPoint(x: size.width, y: y))
                context.stroke(path, with: .color(.black.opacity(0.3)), lineWidth: 1)
            }
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Epilogue Typewriter Text
struct EpilogueTypewriterText: View {
    let text: String
    let font: Font

    @State private var displayedText = ""

    var body: some View {
        Text(displayedText)
            .font(font)
            .multilineTextAlignment(.center)
            .onAppear {
                displayedText = ""
                var charIndex = 0
                Timer.scheduledTimer(withTimeInterval: 0.04, repeats: true) { timer in
                    if charIndex < text.count {
                        let index = text.index(text.startIndex, offsetBy: charIndex)
                        displayedText += String(text[index])
                        charIndex += 1
                    } else {
                        timer.invalidate()
                    }
                }
            }
    }
}

#Preview {
    EpilogueView(stats: JourneyStats(), onReplay: {})
}
