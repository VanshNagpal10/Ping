//
//  TransitionView.swift
//  Ping
//
//  Glitch effect transitioning from phone to digital world
//

import SwiftUI

struct TransitionView: View {
    let onComplete: () -> Void
    
    @State private var glitchPhase: Int = 0
    @State private var zoomScale: CGFloat = 1.0
    @State private var glitchOffset: CGFloat = 0
    @State private var showDigital = false
    @State private var scanlineOffset: CGFloat = 0
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Background
                Color.black
                
                // Glitch layers
                if glitchPhase < 3 {
                    GlitchingPhone(phase: glitchPhase, offset: glitchOffset)
                        .scaleEffect(zoomScale)
                }
                
                // Scanlines
                ScanlineEffect(offset: scanlineOffset)
                    .opacity(glitchPhase >= 1 ? 0.5 : 0)
                
                // Digital world emerging
                if showDigital {
                    DigitalWorldTransition()
                        .transition(.opacity)
                }
                
                // Zoom tunnel effect
                if glitchPhase >= 2 {
                    ZoomTunnel()
                        .opacity(min(Double(glitchPhase - 1) * 0.5, 1.0))
                }
                
                // Text overlay
                VStack {
                    Spacer()
                    
                    if glitchPhase >= 1 && glitchPhase < 4 {
                        Text(transitionText)
                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                            .foregroundColor(.green)
                            .opacity(0.8)
                            .transition(.opacity)
                    }
                    
                    Spacer().frame(height: 60)
                }
            }
        }
        .ignoresSafeArea()
        .onAppear {
            startTransitionSequence()
        }
    }
    
    private var transitionText: String {
        switch glitchPhase {
        case 1: return "INITIATING DATA TRANSFER..."
        case 2: return "ENTERING NETWORK LAYER..."
        case 3: return "PACKET TRANSFORMATION COMPLETE"
        default: return ""
        }
    }
    
    private func startTransitionSequence() {
        // Phase 1: Glitch starts
        withAnimation(.easeIn(duration: 0.3)) {
            glitchPhase = 1
        }
        
        // Glitch animation
        withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
            glitchOffset = 1000
            scanlineOffset = 500
        }
        
        // Phase 2: Zoom in
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.easeIn(duration: 1.0)) {
                zoomScale = 5.0
                glitchPhase = 2
            }
        }
        
        // Phase 3: Digital world
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            withAnimation(.easeInOut(duration: 0.5)) {
                showDigital = true
                glitchPhase = 3
            }
        }
        
        // Complete
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            onComplete()
        }
    }
}

// MARK: - Glitching Phone
struct GlitchingPhone: View {
    let phase: Int
    let offset: CGFloat
    
    var body: some View {
        ZStack {
            // Red channel offset
            PhoneGlitchLayer(color: .red)
                .offset(x: sin(offset / 50) * CGFloat(phase) * 3)
                .opacity(0.7)
            
            // Green channel
            PhoneGlitchLayer(color: .green)
                .offset(x: -sin(offset / 50) * CGFloat(phase) * 2)
                .opacity(0.7)
            
            // Blue channel offset
            PhoneGlitchLayer(color: .blue)
                .offset(x: cos(offset / 30) * CGFloat(phase) * 4)
                .opacity(0.7)
            
            // White core
            PhoneGlitchLayer(color: .white)
                .opacity(0.3)
        }
        .blendMode(.screen)
    }
}

struct PhoneGlitchLayer: View {
    let color: Color
    
    var body: some View {
        RoundedRectangle(cornerRadius: 30)
            .fill(color)
            .frame(width: 200, height: 380)
    }
}

// MARK: - Scanline Effect
struct ScanlineEffect: View {
    let offset: CGFloat
    
    var body: some View {
        GeometryReader { geo in
            VStack(spacing: 2) {
                ForEach(0..<Int(geo.size.height / 4), id: \.self) { i in
                    Rectangle()
                        .fill(Color.black.opacity(0.3))
                        .frame(height: 2)
                }
            }
            .offset(y: offset.truncatingRemainder(dividingBy: 4))
        }
    }
}

// MARK: - Zoom Tunnel
struct ZoomTunnel: View {
    @State private var rotate = false
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Concentric circles
                ForEach(0..<10, id: \.self) { i in
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [.cyan.opacity(0.5), .blue.opacity(0.3)],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 2
                        )
                        .frame(width: CGFloat(50 + i * 80), height: CGFloat(50 + i * 80))
                        .rotationEffect(.degrees(rotate ? 360 : 0))
                        .animation(
                            .linear(duration: Double(3 + i))
                            .repeatForever(autoreverses: false),
                            value: rotate
                        )
                }
                
                // Speed lines
                ForEach(0..<20, id: \.self) { i in
                    Rectangle()
                        .fill(Color.cyan.opacity(0.4))
                        .frame(width: 2, height: 100)
                        .offset(y: -geo.size.height / 2 + 50)
                        .rotationEffect(.degrees(Double(i) * 18))
                }
            }
            .position(x: geo.size.width / 2, y: geo.size.height / 2)
        }
        .onAppear { rotate = true }
    }
}

// MARK: - Digital World Transition
struct DigitalWorldTransition: View {
    @State private var gridExpand = false
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Base color
                Color(red: 0.02, green: 0.05, blue: 0.1)
                
                // Expanding grid
                VStack(spacing: 40) {
                    ForEach(0..<15, id: \.self) { _ in
                        Rectangle()
                            .fill(Color.cyan.opacity(0.3))
                            .frame(height: 1)
                    }
                }
                .scaleEffect(gridExpand ? 1.5 : 0.5)
                .opacity(gridExpand ? 1 : 0)
                
                // Center glow (the packet being born)
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [.cyan, .cyan.opacity(0.5), .clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: 100
                        )
                    )
                    .frame(width: 200, height: 200)
                    .scaleEffect(gridExpand ? 1 : 0.1)
                    .position(x: geo.size.width / 2, y: geo.size.height / 2)
                
                // "YOU ARE THE PACKET" text
                Text("YOU ARE THE PACKET")
                    .font(.system(size: 20, weight: .bold, design: .monospaced))
                    .foregroundColor(.cyan)
                    .opacity(gridExpand ? 1 : 0)
                    .position(x: geo.size.width / 2, y: geo.size.height / 2 + 80)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                gridExpand = true
            }
        }
    }
}

#Preview {
    TransitionView(onComplete: {})
}
