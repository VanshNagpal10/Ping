//
//  EpilogueView.swift
//  Ping - Packet World
//
//  Mission complete — the payload is delivered.
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
    @State private var showDevice = false
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
        case blackout, deliveryScene, missionTitle, statsReveal
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // ── Layer 0: Deep void background ──
                Color(red: 0.02, green: 0.01, blue: 0.06)
                    .ignoresSafeArea()

                // ── Layer 1: Cyber grid floor ──
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

                // ── Layer 6: Holographic Device (Center) ──
                VStack {
                    Spacer()
                    if showDevice {
                        HolographicFeedView(
                            isLoaded: feedLoaded,
                            cyan: nCyan,
                            magenta: nMagenta
                        )
                        .transition(.scale(scale: 0.8).combined(with: .opacity))
                    }
                    Spacer().frame(height: geo.size.height * 0.15)
                }

                // ── Layer 7: Expanding ring pulses ──
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
                        EpilogueSafeTypewriter(
                            text: "Payload delivered. The feed loaded in 114ms.",
                            font: .system(size: 16, weight: .regular, design: .monospaced)
                        )
                        .foregroundColor(.white.opacity(0.6))
                        .shadow(color: nCyan.opacity(0.2), radius: 8)
                    }

                    if showPerspective {
                        EpilogueSafeTypewriter(
                            text: "To the user, it was instant. To you, it was an epic journey.",
                            font: .system(size: 13, weight: .medium, design: .monospaced)
                        )
                        .foregroundColor(nMagenta.opacity(0.8))
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
                            Button(action: {
                                SoundManager.shared.playButtonSound()
                                onReplay()
                            }) {
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
                                .overlay(Capsule().stroke(nCyan.opacity(0.6), lineWidth: 1))
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

                // ── Layer 10: Title badge ──
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
                        .padding(.vertical, 10)
                        .padding(.horizontal, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.black.opacity(0.5))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(nCyan.opacity(0.2), lineWidth: 1)
                                )
                        )
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
        SoundManager.shared.playAmbientSound(for: .cpuCity) // Switch back to a cool synth
        
        withAnimation(.linear(duration: 25).repeatForever(autoreverses: false)) {
            gridScroll = 1
        }

        // 0.0s — Fade in scene
        withAnimation(.easeOut(duration: 1.0)) {
            phase = .deliveryScene
        }

        // 0.5s — Holographic Device appears
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                showDevice = true
            }
        }

        // 1.5s — Feed Loads on device
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            SoundManager.shared.playMissionCompleteSound() // Success chime!
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                feedLoaded = true
            }
        }

        // 2.5s — MISSION COMPLETE title drops
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            SoundManager.shared.playPortalSound() // Heavy boom
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                phase = .missionTitle
                showMissionComplete = true
            }
            withAnimation(.easeOut(duration: 2.5).repeatForever(autoreverses: false)) {
                ringPulse = 2.0
            }
        }

        // 3.5s — Subtitle typewriter
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
            withAnimation(.easeIn(duration: 0.6)) { showSubtitle = true }
        }

        // 5.5s — Perspective line
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.5) {
            withAnimation(.easeIn(duration: 0.6)) { showPerspective = true }
        }

        // 7.5s — Stats panel
        DispatchQueue.main.asyncAfter(deadline: .now() + 7.5) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                phase = .statsReveal
                showStats = true
            }
        }

        // 8.2s — Journey route
        DispatchQueue.main.asyncAfter(deadline: .now() + 8.2) {
            withAnimation(.easeOut(duration: 0.6)) { showJourneyRoute = true }
        }

        // 9.0s — Replay button
        DispatchQueue.main.asyncAfter(deadline: .now() + 9.0) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                showReplay = true
            }
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                glowPulse = true
            }
        }
    }
}

// MARK: - Holographic Feed View
struct HolographicFeedView: View {
    let isLoaded: Bool
    let cyan: Color
    let magenta: Color
    
    @State private var floatOffset: CGFloat = 0
    
    var body: some View {
        ZStack {
            // Glowing Aura
            RoundedRectangle(cornerRadius: 16)
                .fill(isLoaded ? cyan.opacity(0.15) : magenta.opacity(0.1))
                .frame(width: 140, height: 220)
                .blur(radius: 20)
            
            // Device Frame
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(red: 0.05, green: 0.05, blue: 0.08).opacity(0.9))
                .frame(width: 130, height: 210)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            LinearGradient(
                                colors: isLoaded ? [cyan, cyan.opacity(0.3)] : [magenta, magenta.opacity(0.3)],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            ), lineWidth: 2
                        )
                )
            
            // Screen Content
            VStack(spacing: 12) {
                if !isLoaded {
                    // Loading State
                    Spacer()
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: magenta))
                        .scaleEffect(1.5)
                    Text("RESOLVING IP...")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(magenta)
                        .tracking(1)
                    Spacer()
                } else if isLoaded {
                    // Loaded Feed State
                    HStack {
                        Image(systemName: "checkmark.shield.fill")
                            .foregroundColor(cyan)
                        Text("SECURE CONNECTION")
                            .font(.system(size: 8, weight: .bold, design: .monospaced))
                            .foregroundColor(cyan)
                    }
                    .padding(.top, 8)
                    
                    // Mock Social Media Posts
                    VStack(spacing: 8) {
                        ForEach(0..<3) { i in
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Circle().fill(Color.gray.opacity(0.4)).frame(width: 16, height: 16)
                                    RoundedRectangle(cornerRadius: 2).fill(Color.gray.opacity(0.4)).frame(width: 50, height: 6)
                                }
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(
                                        LinearGradient(colors: [.cyan.opacity(0.3), .purple.opacity(0.2)], startPoint: .topLeading, endPoint: .bottomTrailing)
                                    )
                                    .frame(height: i == 0 ? 50 : 30) // First post is taller
                            }
                            .padding(8)
                            .background(RoundedRectangle(cornerRadius: 8).fill(Color.white.opacity(0.05)))
                        }
                    }
                    .padding(.horizontal, 10)
                    Spacer()
                }
            }
        }
        .offset(y: floatOffset)
        .onAppear {
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                floatOffset = -10
            }
        }
    }
}

// MARK: - Safe Typewriter Text
struct EpilogueSafeTypewriter: View {
    let text: String
    let font: Font
    
    @State private var displayedText = ""
    
    var body: some View {
        Text(displayedText)
            .font(font)
            .multilineTextAlignment(.center)
            .task { await typeText() }
    }
    
    private func typeText() async {
        displayedText = ""
        for (index, char) in text.enumerated() {
            if Task.isCancelled { break }
            displayedText.append(char)
            if index % 4 == 0 {
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.impactOccurred()
            }
            do {
                try await Task.sleep(nanoseconds: 30_000_000)
            } catch { break }
        }
    }
}

// MARK: - Journey Route Strip
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

                            Image(systemName: sceneIcon(for: scene))
                                .font(.system(size: 10))
                                .foregroundColor(scene.accentColor)
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
        case .frozenCafe: return "cup.and.saucer.fill"
        case .cpuCity: return "cpu.fill"
        case .wifiAntenna: return "antenna.radiowaves.left.and.right"
        case .routerStation: return "arrow.triangle.branch"
        case .oceanCable: return "water.waves"
        case .dnsLibrary: return "book.closed.fill"
        case .returnJourney: return "arrow.turn.up.left"
        case .feedLoaded: return "checkmark.circle.fill"
        }
    }
}

// MARK: - Journey Stats Panel (Glassmorphism)
struct JourneyStatsPanel: View {
    let stats: JourneyStats
    let accentColor: Color
    let magenta: Color

    @State private var revealedStats = 0

    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 12) {
                Rectangle().fill(accentColor.opacity(0.4)).frame(height: 1)
                Text("YOUR JOURNEY")
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundColor(accentColor)
                    .tracking(4)
                    .fixedSize(horizontal: true, vertical: false)
                Rectangle().fill(accentColor.opacity(0.4)).frame(height: 1)
            }

            HStack(spacing: 0) {
                StatBadge(icon: "clock", value: stats.formattedDuration, label: "Time", accent: accentColor, revealed: revealedStats >= 1)
                    .frame(maxWidth: .infinity)
                StatDivider(color: accentColor)
                StatBadge(icon: "book.fill", value: "\(stats.termsLearned.count)", label: "Terms", accent: Color(red: 1.0, green: 0.75, blue: 0.0), revealed: revealedStats >= 2)
                    .frame(maxWidth: .infinity)
                StatDivider(color: accentColor)
                StatBadge(icon: "person.2.fill", value: "\(stats.npcsSpokenTo.count)", label: "NPCs", accent: magenta, revealed: revealedStats >= 3)
                    .frame(maxWidth: .infinity)
                StatDivider(color: accentColor)
                StatBadge(icon: "map.fill", value: "\(stats.scenesVisited.count)", label: "Places", accent: Color(red: 0.6, green: 0.2, blue: 1.0), revealed: revealedStats >= 4)
                    .frame(maxWidth: .infinity)
            }
            
            // Choice outcomes row
            if !stats.choicesMade.isEmpty {
                Rectangle().fill(accentColor.opacity(0.2)).frame(height: 1).padding(.vertical, 4)
                
                HStack(spacing: 0) {
                    StatBadge(icon: stats.chosenProtocol == .udp ? "bolt.fill" : "checkmark.shield.fill", value: stats.chosenProtocol.rawValue, label: "Protocol", accent: stats.chosenProtocol == .udp ? .orange : .green, revealed: revealedStats >= 5)
                        .frame(maxWidth: .infinity)
                    StatDivider(color: accentColor)
                    StatBadge(icon: stats.upgradedToSSL ? "lock.fill" : "lock.open.fill", value: stats.upgradedToSSL ? "SSL" : "None", label: "Security", accent: stats.upgradedToSSL ? .green : .red, revealed: revealedStats >= 5)
                        .frame(maxWidth: .infinity)
                    StatDivider(color: accentColor)
                    StatBadge(icon: stats.lostPacketData ? "exclamationmark.triangle.fill" : "checkmark.circle.fill", value: stats.lostPacketData ? "Lost" : "Intact", label: "Data", accent: stats.lostPacketData ? .red : .green, revealed: revealedStats >= 5)
                        .frame(maxWidth: .infinity)
                    StatDivider(color: accentColor)
                    StatBadge(icon: "brain.head.profile", value: "\(Int(stats.quizAccuracy * 100))%", label: "Quiz", accent: stats.quizAccuracy >= 0.8 ? .green : stats.quizAccuracy >= 0.5 ? .yellow : .orange, revealed: revealedStats >= 5)
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.black.opacity(0.5))
                .background(.ultraThinMaterial) // Added glassmorphism!
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(LinearGradient(colors: [accentColor.opacity(0.5), magenta.opacity(0.3)], startPoint: .leading, endPoint: .trailing), lineWidth: 1)
                )
                .shadow(color: accentColor.opacity(0.15), radius: 20, y: 5)
        )
        .onAppear { revealStatsSequentially() }
    }

    private func revealStatsSequentially() {
        for i in 1...5 {
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

#Preview {
    EpilogueView(stats: JourneyStats(), onReplay: {})
}
