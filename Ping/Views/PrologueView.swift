//
//  PrologueView.swift
//  Ping - Packet World
//
//  Cinematic minimalist opening — black void, typewriter text, pure narrative.
//

import SwiftUI

struct PrologueView: View {
    let onStartGame: () -> Void

    // Cinematic sequence states
    @State private var phase = 0          // drives the text sequence
    @State private var showButton = false
    @State private var buttonPulse = false
    @State private var cursorVisible = true

    private let accent = Color(red: 0.0, green: 0.9, blue: 1.0)

    // The narrative beats — each is a line that types on screen
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

                // Subtle vignette at edges
                RadialGradient(
                    colors: [.clear, Color.white.opacity(0.015)],
                    center: .center,
                    startRadius: geo.size.width * 0.3,
                    endRadius: geo.size.width * 0.8
                )
                .ignoresSafeArea()

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
                            SoundManager.shared.playButtonSound()
                            withAnimation(.easeInOut(duration: 0.4)) {
                                onStartGame()
                            }
                        } label: {
                            HStack(spacing: 10) {
                                Text("Enter the Network")
                                    .font(.system(size: 17, weight: .semibold, design: .monospaced))
                                    .tracking(2)
                                Image(systemName: "chevron.right.2")
                                    .font(.system(size: 15, weight: .bold))
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
                    }
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                }

                // ── Skip Button — rounded capsule, always visible until Enter shows ──
                if !showButton {
                    VStack {
                        HStack {
                            Spacer()
                            Button {
                                SoundManager.shared.stopTypewriterSound()
                                SoundManager.shared.playButtonSound()
                                onStartGame()
                            } label: {
                                HStack(spacing: 6) {
                                    Text("Skip")
                                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                                    Image(systemName: "forward.fill")
                                        .font(.system(size: 11, weight: .semibold))
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
                            .padding(.trailing, 24)
                            .padding(.top, 20)
                        }
                        Spacer()
                    }
                }
            }
        }
        .onAppear { startCinematic() }
    }

    // MARK: - Cinematic Sequence
    private func startCinematic() {
        // Ambient music
        SoundManager.shared.playAmbientSound(for: .frozenCafe)

        // Blinking cursor
        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            cursorVisible.toggle()
        }

        // Schedule each line
        for (index, line) in lines.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + line.delay) {
                SoundManager.shared.startTypewriterSound()
                withAnimation(.easeIn(duration: 0.3)) {
                    phase = index + 1
                }
                // Stop typing sound after the line would finish typing
                let typeDuration = Double(line.text.count) * 0.04 + 0.2
                DispatchQueue.main.asyncAfter(deadline: .now() + typeDuration) {
                    SoundManager.shared.stopTypewriterSound()
                }
            }
        }

        // Show enter button after all text
        let lastDelay = lines.last?.delay ?? 20.0
        let lastTypeDuration = Double(lines.last?.text.count ?? 20) * 0.04
        DispatchQueue.main.asyncAfter(deadline: .now() + lastDelay + lastTypeDuration + 1.5) {
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
            .font(.system(size: fontSize, weight: fontWeight, design: .monospaced))
            .foregroundColor(textColor)
            .multilineTextAlignment(.center)
            .shadow(color: textColor == .white.opacity(0.85) ? .clear : textColor.opacity(0.5), radius: 12)
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
    }
}

#Preview {
    PrologueView(onStartGame: {})
}
