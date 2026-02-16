//
//  PrologueView.swift
//  Ping - Packet World
//
//  Cinematic cyberpunk opening — "The Tap That Started It All"
//

import SwiftUI

struct PrologueView: View {
    let onStartGame: () -> Void
    
    @State private var showScene = false
    @State private var showText1 = false
    @State private var showText2 = false
    @State private var showText3 = false
    @State private var showButton = false
    @State private var phoneGlow = false
    @State private var tapPulse = false
    @State private var gridScroll: CGFloat = 0
    @State private var ringScale: CGFloat = 0.2
    
    // Neon palette
    private let nCyan    = Color(red: 0.0, green: 0.9, blue: 1.0)
    private let nMagenta = Color(red: 1.0, green: 0.1, blue: 0.6)
    private let nViolet  = Color(red: 0.6, green: 0.2, blue: 1.0)
    private let nAmber   = Color(red: 1.0, green: 0.75, blue: 0.0)
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Deep void background
                Color(red: 0.02, green: 0.01, blue: 0.06)
                    .ignoresSafeArea()
                
                // Animated perspective grid floor
                CyberGrid(scroll: gridScroll, color: nCyan)
                    .opacity(showScene ? 0.35 : 0)
                
                // Radial glow behind center
                RadialGradient(
                    colors: [nViolet.opacity(0.15), .clear],
                    center: .center,
                    startRadius: 20,
                    endRadius: geo.size.width * 0.6
                )
                .opacity(showScene ? 1 : 0)
                
                // Floating neon particles
                NeonParticles(colors: [nCyan, nMagenta, nViolet, nAmber])
                    .opacity(showScene ? 0.7 : 0)
                
                // Data stream lines (vertical falling lines)
                DataStreamLines(color: nCyan)
                    .opacity(showScene ? 0.25 : 0)
                
                // Central phone + ripple composition
                VStack(spacing: 0) {
                    Spacer()
                    
                    ZStack {
                        // Expanding ripple rings on tap
                        if phoneGlow {
                            ForEach(0..<3, id: \.self) { i in
                                Circle()
                                    .stroke(nCyan.opacity(0.3 - Double(i) * 0.1), lineWidth: 1.5)
                                    .frame(width: 80 + CGFloat(i) * 60, height: 80 + CGFloat(i) * 60)
                                    .scaleEffect(ringScale)
                                    .opacity(2.0 - Double(ringScale))
                            }
                        }
                        
                        // Stylized phone
                        StylizedPhone(glowing: phoneGlow, tapPulse: tapPulse, cyan: nCyan, magenta: nMagenta)
                    }
                    
                    Spacer()
                        .frame(height: geo.size.height * 0.18)
                }
                .opacity(showScene ? 1 : 0)
                
                // Scan-line overlay
                ScanLineOverlay()
                    .opacity(showScene ? 0.06 : 0)
                
                // Text overlays
                VStack(spacing: 24) {
                    Spacer()
                        .frame(height: geo.size.height * 0.08)
                    
                    if showText1 {
                        TypewriterText(
                            text: "To a computer, a second is an eternity.",
                            font: .system(size: 22, weight: .medium, design: .monospaced)
                        )
                        .foregroundColor(.white.opacity(0.85))
                        .shadow(color: nCyan.opacity(0.3), radius: 8)
                        .transition(.opacity)
                    }
                    
                    if showText2 {
                        TypewriterText(
                            text: "While humans blink, billions of operations occur.",
                            font: .system(size: 17, weight: .regular, design: .monospaced)
                        )
                        .foregroundColor(.white.opacity(0.5))
                        .transition(.opacity)
                    }
                    
                    if showText3 {
                        VStack(spacing: 10) {
                            Text("Welcome to the")
                                .font(.system(size: 14, weight: .light, design: .monospaced))
                                .foregroundColor(.white.opacity(0.4))
                                .tracking(6)
                            
                            Text("INTERNET")
                                .font(.system(size: 44, weight: .black, design: .monospaced))
                                .foregroundColor(nCyan)
                                .shadow(color: nCyan.opacity(0.8), radius: 20)
                                .shadow(color: nCyan.opacity(0.4), radius: 40)
                                .shadow(color: nMagenta.opacity(0.25), radius: 60)
                                .tracking(10)
                        }
                        .transition(.scale(scale: 0.7).combined(with: .opacity))
                    }
                    
                    Spacer()
                }
                
                // Start button
                if showButton {
                    VStack {
                        Spacer()
                        
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.5)) {
                                onStartGame()
                            }
                        }) {
                            HStack(spacing: 12) {
                                Text("Enter the Network")
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
                        .scaleEffect(tapPulse ? 1.04 : 1.0)
                        .padding(.bottom, 55)
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                
                // Title — top left
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
                    .opacity(showScene ? 1 : 0)
                    
                    Spacer()
                }
            }
        }
        .onAppear {
            startCinematic()
        }
    }
    
    private func startCinematic() {
        // Grid scroll animation
        withAnimation(.linear(duration: 20).repeatForever(autoreverses: false)) {
            gridScroll = 1
        }
        
        // Fade in scene
        withAnimation(.easeOut(duration: 1.2)) {
            showScene = true
        }
        
        // Text sequence
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.easeIn(duration: 0.8)) {
                showText1 = true
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
            withAnimation(.easeIn(duration: 0.8)) {
                showText2 = true
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 6.5) {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                showText3 = true
                phoneGlow = true
            }
            withAnimation(.easeOut(duration: 2.0).repeatForever(autoreverses: false)) {
                ringScale = 2.0
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 8.0) {
            withAnimation(.easeOut(duration: 0.5)) {
                showButton = true
            }
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                tapPulse = true
            }
        }
    }
}

// MARK: - Cyber Grid (Perspective Floor)
struct CyberGrid: View {
    let scroll: CGFloat
    let color: Color
    
    var body: some View {
        GeometryReader { geo in
            Canvas { context, size in
                let lineColor = color.opacity(0.3)
                
                // Horizontal lines (converging toward horizon)
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
                
                // Vertical lines (perspective)
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

// MARK: - Stylized Phone
struct StylizedPhone: View {
    let glowing: Bool
    let tapPulse: Bool
    let cyan: Color
    let magenta: Color
    
    var body: some View {
        ZStack {
            // Phone body — dark with neon border
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(red: 0.06, green: 0.04, blue: 0.12))
                .frame(width: 70, height: 120)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(
                            LinearGradient(
                                colors: glowing ? [cyan, magenta] : [Color.white.opacity(0.15), Color.white.opacity(0.05)],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: glowing ? 2 : 1
                        )
                )
                .shadow(color: glowing ? cyan.opacity(0.5) : .clear, radius: 25)
                .shadow(color: glowing ? magenta.opacity(0.2) : .clear, radius: 40)
            
            // Screen
            RoundedRectangle(cornerRadius: 10)
                .fill(
                    glowing
                    ? LinearGradient(colors: [cyan.opacity(0.3), magenta.opacity(0.15)], startPoint: .top, endPoint: .bottom)
                    : LinearGradient(colors: [Color.white.opacity(0.03), Color.white.opacity(0.01)], startPoint: .top, endPoint: .bottom)
                )
                .frame(width: 58, height: 100)
            
            // Screen content — tiny code lines
            if glowing {
                VStack(alignment: .leading, spacing: 5) {
                    ForEach(0..<5, id: \.self) { i in
                        RoundedRectangle(cornerRadius: 1)
                            .fill(cyan.opacity(0.4))
                            .frame(width: CGFloat(20 + (i * 7) % 25), height: 2)
                    }
                }
                .frame(width: 50, height: 80, alignment: .topLeading)
            }
            
            // Tap ripple on screen
            if tapPulse && glowing {
                Circle()
                    .fill(cyan.opacity(0.3))
                    .frame(width: 16, height: 16)
                    .scaleEffect(tapPulse ? 2 : 1)
                    .opacity(tapPulse ? 0 : 0.8)
                    .offset(y: 10)
            }
        }
    }
}

// MARK: - Neon Particles
struct NeonParticles: View {
    let colors: [Color]
    
    var body: some View {
        Canvas { context, canvasSize in
            for i in 0..<40 {
                let seed = Double(i) * 137.508
                let x = CGFloat((sin(seed) * 0.5 + 0.5)) * canvasSize.width
                let y = CGFloat((cos(seed * 0.7) * 0.5 + 0.5)) * canvasSize.height
                let radius: CGFloat = CGFloat(i % 3 == 0 ? 2.5 : 1.2)
                
                let rect = CGRect(x: x - radius, y: y - radius, width: radius * 2, height: radius * 2)
                let colorIdx = i % colors.count
                context.fill(Circle().path(in: rect), with: .color(colors[colorIdx].opacity(0.5)))
            }
        }
    }
}

// MARK: - Data Stream Lines
struct DataStreamLines: View {
    let color: Color
    
    @State private var offset: CGFloat = 0
    
    var body: some View {
        Canvas { context, canvasSize in
            for i in 0..<10 {
                let x = CGFloat(i) * (canvasSize.width / 10) + 20
                let lineHeight: CGFloat = CGFloat(40 + (i * 37) % 80)
                let y = ((offset * canvasSize.height * 1.5 + CGFloat(i) * 80).truncatingRemainder(dividingBy: canvasSize.height + lineHeight)) - lineHeight
                
                var path = Path()
                path.move(to: CGPoint(x: x, y: y))
                path.addLine(to: CGPoint(x: x, y: y + lineHeight))
                context.stroke(path, with: .color(color.opacity(0.2)), lineWidth: 1)
            }
        }
        .onAppear {
            withAnimation(.linear(duration: 6).repeatForever(autoreverses: false)) {
                offset = 1
            }
        }
    }
}

// MARK: - Scan Line Overlay
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

// MARK: - Typewriter Text
struct TypewriterText: View {
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
    PrologueView(onStartGame: {})
}
