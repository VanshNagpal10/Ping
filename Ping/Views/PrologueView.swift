//
//  PrologueView.swift
//  Ping
//

import SwiftUI

struct PrologueView: View {
    let onStartGame: () -> Void

    // Cinematic sequence states
    @State private var phase = 0          // drives the text sequence
    @State private var showButton = false
    @State private var buttonPulse = false
    @State private var cursorVisible = true
    @State private var isSkipped = false
    @State private var showMissionBriefing = false

    private let accent = Color(red: 0.0, green: 0.9, blue: 1.0)


    private let lines: [(text: String, size: CGFloat, weight: Font.Weight, delay: Double, color: Color?)] = [
        ("Every time you open an app…",              20, .medium,  1.0,  nil),
        ("a tiny packet of data is born.",            20, .medium,  4.5,  nil),
        ("It travels thousands of miles",             18, .regular, 9.0,  nil),
        ("through cables, routers, and servers",      18, .regular, 12.5, nil),
        ("all in under a second.",                    18, .regular, 16.0, nil),
        ("This is that journey.",                     24, .bold,    20.5, Color(red: 0.0, green: 0.9, blue: 1.0)),
    ]

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Pure black
                Color.black
                    .ignoresSafeArea()
                    .accessibilityHidden(true)

                // Subtle vignette at edges
                RadialGradient(
                    colors: [.clear, Color.white.opacity(0.015)],
                    center: .center,
                    startRadius: geo.size.width * 0.3,
                    endRadius: geo.size.width * 0.8
                )
                .ignoresSafeArea()
                .accessibilityHidden(true)

                // ── Text Stack ──
                VStack(spacing: 20) {
                    Spacer()

                    ForEach(Array(lines.enumerated()), id: \.offset) { index, line in
                        if phase > index {
                            PrologueTypewriterLine(
                                text: line.text,
                                fontSize: line.size,
                                fontWeight: line.weight,
                                textColor: line.color ?? .white.opacity(0.85)
                            )
                            .transition(.opacity)
                        }
                    }

                    // Blinking cursor after last visible line
                    if phase > 0 && phase <= lines.count {
                        Rectangle()
                            .fill(accent)
                            .frame(width: 2, height: 20)
                            .opacity(cursorVisible ? 1 : 0)
                            .shadow(color: accent.opacity(0.6), radius: 4)
                            .padding(.top, 4)
                            .accessibilityHidden(true)
                    }

                    Spacer()
                    Spacer()
                }
                .padding(.horizontal, 48)

                // ── Enter Button ──
                if showButton {
                    VStack {
                        Spacer()

                        Button {
                            isSkipped = true
                            SoundManager.shared.stopTypewriterSound()
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            withAnimation(.easeInOut(duration: 0.4)) {
                                onStartGame()
                            }
                        } label: {
                            HStack(spacing: 10) {
                                Text("Enter the Network")
                                    .font(ScaledFont.scaledFont(size: 17, weight: .semibold, design: .monospaced))
                                    .tracking(2)
                                Image(systemName: "chevron.right.2")
                                    .font(ScaledFont.scaledFont(size: 15, weight: .bold))
                            }
                            .foregroundColor(.black)
                            .padding(.horizontal, 40)
                            .padding(.vertical, 16)
                            .background(
                                Capsule().fill(accent)
                            )
                            .shadow(color: accent.opacity(0.5), radius: 20, y: 4)
                        }
                        .buttonStyle(.plain)
                        .scaleEffect(buttonPulse ? 1.03 : 1.0)
                        .padding(.bottom, 60)
                        .accessibilityLabel("Enter the Network")
                        .accessibilityHint("Starts the game")
                    }
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                }

                // ── Top Bar: Skip + Info ──
                VStack {
                    HStack {
                        // "What You'll Learn" button (bottom-left style but placed top-left for visibility)
                        Button {
                            SoundManager.shared.stopTypewriterSound()
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                showMissionBriefing = true
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "info.circle.fill")
                                    .font(ScaledFont.scaledFont(size: 13, weight: .semibold))
                                Text("What You'll Learn")
                                    .font(ScaledFont.scaledFont(size: 13, weight: .semibold, design: .rounded))
                            }
                            .foregroundColor(accent.opacity(0.8))
                            .padding(.horizontal, 18)
                            .padding(.vertical, 10)
                            .background(
                                Capsule()
                                    .fill(accent.opacity(0.08))
                                    .overlay(
                                        Capsule().stroke(accent.opacity(0.25), lineWidth: 1)
                                    )
                            )
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("What you'll learn")
                        .accessibilityHint("Shows the educational topics covered in this app")
                        .padding(.leading, 24)
                        .padding(.top, 20)
                        
                        Spacer()
                        
                        // Skip button
                        if !showButton {
                            Button {
                                isSkipped = true
                                SoundManager.shared.stopTypewriterSound()
                                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                onStartGame()
                            } label: {
                                HStack(spacing: 6) {
                                    Text("Skip")
                                        .font(ScaledFont.scaledFont(size: 14, weight: .semibold, design: .rounded))
                                    Image(systemName: "forward.fill")
                                        .font(ScaledFont.scaledFont(size: 11, weight: .semibold))
                                }
                                .foregroundColor(.white.opacity(0.6))
                                .padding(.horizontal, 22)
                                .padding(.vertical, 10)
                                .background(
                                    Capsule()
                                        .fill(Color.white.opacity(0.08))
                                        .overlay(
                                            Capsule().stroke(Color.white.opacity(0.15), lineWidth: 1)
                                        )
                                )
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Skip prologue")
                            .accessibilityHint("Skips the intro and starts the game immediately")
                            .padding(.trailing, 24)
                            .padding(.top, 20)
                        }
                    }
                    Spacer()
                }
                
                // Mission Briefing Popup
                if showMissionBriefing {
                    MissionBriefingPopup(accent: accent) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            showMissionBriefing = false
                        }
                    }
                    .transition(.opacity.combined(with: .scale(scale: 0.9)))
                    .zIndex(50)
                }
            }
        }
        .onAppear { startCinematic() }
        .onDisappear {
            isSkipped = true
            SoundManager.shared.stopTypewriterSound()
        }
    }

    // MARK: - Cinematic Sequence
    private func startCinematic() {
        guard !isSkipped else { return }
        
        // Ambient music
        SoundManager.shared.playAmbientSound(for: .prologue)

        // Blinking cursor
        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            cursorVisible.toggle()
        }

        // Schedule each line
        for (index, line) in lines.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + line.delay) {
                if isSkipped { return }
                SoundManager.shared.startTypewriterSound()
                withAnimation(.easeIn(duration: 0.3)) {
                    phase = index + 1
                }
                // Stop typing sound after the line would finish typing
                let typeDuration = Double(line.text.count) * 0.04 + 0.2
                DispatchQueue.main.asyncAfter(deadline: .now() + typeDuration) {
                    if isSkipped { return }
                    SoundManager.shared.stopTypewriterSound()
                }
            }
        }

        // Show enter button after all text
        let lastDelay = lines.last?.delay ?? 20.0
        let lastTypeDuration = Double(lines.last?.text.count ?? 20) * 0.04
        DispatchQueue.main.asyncAfter(deadline: .now() + lastDelay + lastTypeDuration + 1.5) {
            if isSkipped { return }
            SoundManager.shared.playPortalSound()
            withAnimation(.easeOut(duration: 0.6)) {
                showButton = true
            }
            withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                buttonPulse = true
            }
        }
    }
}

// MARK: - Mission Briefing Popup
/// Glassmorphic "What You'll Learn" popup for judges
struct MissionBriefingPopup: View {
    let accent: Color
    let onDismiss: () -> Void
    
    private let learningTopics: [(icon: String, title: String, description: String)] = [
        ("network",               "TCP/IP & Packets",      "How data packets travel across the internet"),
        ("lock.shield.fill",      "Encryption & SSL/TLS",  "Why HTTPS keeps your data safe"),
        ("signpost.right.fill",   "DNS & Routing",         "How your device finds websites by name"),
        ("arrow.triangle.branch", "TCP vs UDP",            "Choosing reliability vs speed in networking"),
        ("server.rack",           "Internet Infrastructure","Routers, cables, and servers behind the scenes"),
    ]
    
    var body: some View {
        ZStack {
            // Dimmed backdrop
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .onTapGesture { onDismiss() }
                .accessibilityHidden(true)
            
            VStack(spacing: 20) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 8) {
                            Image(systemName: "graduationcap.fill")
                                .font(.system(size: 20))
                                .foregroundColor(accent)
                            Text("WHAT YOU'LL LEARN")
                                .font(ScaledFont.scaledFont(size: 16, weight: .bold, design: .monospaced))
                                .foregroundColor(.white)
                                .tracking(2)
                        }
                        Text("An interactive journey through computer networking")
                            .font(ScaledFont.scaledFont(size: 12, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.5))
                    }
                    
                    Spacer()
                    
                    Button(action: onDismiss) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 22))
                            .foregroundColor(.white.opacity(0.4))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Close")
                }
                .accessibilityElement(children: .combine)
                .accessibilityAddTraits(.isHeader)
                
                // Divider
                Rectangle()
                    .fill(LinearGradient(colors: [.clear, accent.opacity(0.5), .clear], startPoint: .leading, endPoint: .trailing))
                    .frame(height: 1)
                    .accessibilityHidden(true)
                
                // Pitch
                Text("Ping teaches how the internet works, from TCP/IP protocols to encryption and DNS routing, through an interactive 3D adventure where you become a data packet.")
                    .font(ScaledFont.scaledFont(size: 15, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.85))
                    .lineSpacing(5)
                    .fixedSize(horizontal: false, vertical: true)
                
                // Topic list
                VStack(spacing: 10) {
                    ForEach(Array(learningTopics.enumerated()), id: \.offset) { _, topic in
                        HStack(spacing: 14) {
                            Image(systemName: topic.icon)
                                .font(.system(size: 16))
                                .foregroundColor(accent)
                                .frame(width: 32, height: 32)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(accent.opacity(0.1))
                                )
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(topic.title)
                                    .font(ScaledFont.scaledFont(size: 13, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                                Text(topic.description)
                                    .font(ScaledFont.scaledFont(size: 11, weight: .medium, design: .rounded))
                                    .foregroundColor(.white.opacity(0.5))
                            }
                            
                            Spacer()
                        }
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("\(topic.title): \(topic.description)")
                    }
                }
                
                // Built with badge
                HStack(spacing: 6) {
                    Image(systemName: "swift")
                        .foregroundColor(.orange)
                    Text("Built with SwiftUI & SceneKit")
                        .font(ScaledFont.scaledFont(size: 11, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.35))
                }
                .padding(.top, 4)
            }
            .padding(28)
            .frame(maxWidth: 480)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(red: 0.05, green: 0.05, blue: 0.08).opacity(0.9))
                    .background(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(
                                LinearGradient(
                                    colors: [accent.opacity(0.6), Color.purple.opacity(0.3)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.5
                            )
                    )
            )
            .shadow(color: accent.opacity(0.2), radius: 30)
        }
    }
}

// MARK: - Prologue Typewriter Line
/// Each line types out character by character with a monospaced font.
struct PrologueTypewriterLine: View {
    let text: String
    let fontSize: CGFloat
    let fontWeight: Font.Weight
    let textColor: Color

    @State private var displayedText = ""

    var body: some View {
        Text(displayedText)
            .font(ScaledFont.scaledFont(size: fontSize, weight: fontWeight, design: .monospaced))
            .foregroundColor(textColor)
            .multilineTextAlignment(.center)
            .shadow(color: textColor == .white.opacity(0.85) ? .clear : textColor.opacity(0.5), radius: 12)
            .accessibilityLabel(text)
            .onAppear {
                displayedText = ""
                var charIndex = 0
                Timer.scheduledTimer(withTimeInterval: 0.04, repeats: true) { timer in
                    if charIndex < text.count {
                        let idx = text.index(text.startIndex, offsetBy: charIndex)
                        displayedText += String(text[idx])
                        charIndex += 1
                    } else {
                        timer.invalidate()
                    }
                }
            }
    }
}

// MARK: - Legacy components kept for other views that may reference them

struct CyberGrid: View {
    let scroll: CGFloat
    let color: Color

    var body: some View {
        GeometryReader { geo in
            Canvas { context, size in
                let lineColor = color.opacity(0.3)
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
        .accessibilityHidden(true)
    }
}

struct ScanLineOverlay: View {
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
        .accessibilityHidden(true)
    }
}

#Preview {
    PrologueView(onStartGame: {})
}
