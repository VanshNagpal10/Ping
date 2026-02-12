//
//  PrologueView.swift
//  Ping - Packet World
//
//  The "Frozen World" opening cinematic
//

import SwiftUI

struct PrologueView: View {
    let onStartGame: () -> Void
    
    @State private var showScene = false
    @State private var showText1 = false
    @State private var showText2 = false
    @State private var showText3 = false
    @State private var showButton = false
    @State private var coffeeFall: CGFloat = 0
    @State private var phoneGlow = false
    @State private var tapPulse = false
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Dark cinematic background
                LinearGradient(
                    colors: [
                        Color(red: 0.04, green: 0.02, blue: 0.10),
                        Color(red: 0.02, green: 0.01, blue: 0.06)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                
                // Cafe interior elements
                CafeBackground(size: geo.size)
                    .opacity(showScene ? 1 : 0)
                
                // The girl with phone
                VStack {
                    Spacer()
                    
                    HStack(spacing: 40) {
                        // Frozen coffee cup falling
                        FrozenCoffeeCup(fallProgress: coffeeFall)
                            .offset(y: -100)
                        
                        // The girl with phone
                        GirlWithPhone(phoneGlow: phoneGlow, tapPulse: tapPulse)
                    }
                    .padding(.bottom, geo.size.height * 0.15)
                }
                .opacity(showScene ? 1 : 0)
                
                // Frozen particles (dust in sunlight, frozen in time)
                FrozenParticles()
                    .opacity(showScene ? 0.6 : 0)
                
                // Time dilation overlay effect
                TimeDilationOverlay()
                    .opacity(showScene ? 0.3 : 0)
                
                // Text overlays
                VStack(spacing: 20) {
                    if showText1 {
                        TypewriterText(
                            text: "To a computer, a second is an eternity.",
                            font: .system(size: 22, weight: .medium, design: .serif)
                        )
                        .foregroundColor(.white.opacity(0.85))
                        .transition(.opacity)
                    }
                    
                    if showText2 {
                        TypewriterText(
                            text: "While humans blink, billions of operations occur.",
                            font: .system(size: 18, weight: .regular, design: .serif)
                        )
                        .foregroundColor(.white.opacity(0.6))
                        .transition(.opacity)
                    }
                    
                    if showText3 {
                        VStack(spacing: 8) {
                            Text("Welcome to the")
                                .font(.system(size: 16, design: .serif))
                                .foregroundColor(.white.opacity(0.5))
                            
                            Text("INTERNET")
                                .font(.system(size: 36, weight: .bold, design: .monospaced))
                                .foregroundColor(.cyan)
                                .shadow(color: .cyan.opacity(0.7), radius: 15)
                                .shadow(color: Color(red: 1.0, green: 0.1, blue: 0.6).opacity(0.3), radius: 25)
                        }
                        .transition(.scale.combined(with: .opacity))
                    }
                }
                .padding(.top, 60)
                .frame(maxHeight: .infinity, alignment: .top)
                
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
                                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                                
                                Image(systemName: "arrow.right.circle.fill")
                                    .font(.title2)
                            }
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
                            .shadow(color: .cyan.opacity(0.6), radius: 20, y: 5)
                            .shadow(color: Color(red: 1.0, green: 0.1, blue: 0.6).opacity(0.2), radius: 30, y: 8)
                        }
                        .scaleEffect(tapPulse ? 1.05 : 1.0)
                        .padding(.bottom, 50)
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                
                // Title at very top
                VStack {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("PING")
                                .font(.system(size: 18, weight: .black, design: .monospaced))
                                .foregroundColor(.cyan)
                                .shadow(color: .cyan.opacity(0.5), radius: 8)
                            
                            Text("A Journey Through the Internet")
                                .font(.system(size: 10, design: .serif))
                                .foregroundColor(.white.opacity(0.4))
                        }
                        Spacer()
                    }
                    .padding(20)
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
        // Fade in scene
        withAnimation(.easeOut(duration: 1.0)) {
            showScene = true
        }
        
        // Coffee frozen mid-fall
        withAnimation(.easeOut(duration: 0.5).delay(0.5)) {
            coffeeFall = 0.3
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
            withAnimation(.spring()) {
                showText3 = true
                phoneGlow = true
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 8.0) {
            withAnimation(.easeOut(duration: 0.5)) {
                showButton = true
            }
            withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                tapPulse = true
            }
        }
    }
}

// MARK: - Cafe Background
struct CafeBackground: View {
    let size: CGSize
    
    var body: some View {
        ZStack {
            // Window with sunlight
            RoundedRectangle(cornerRadius: 8)
                .fill(
                    LinearGradient(
                        colors: [.yellow.opacity(0.3), .orange.opacity(0.1)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: size.width * 0.4, height: size.height * 0.5)
                .position(x: size.width * 0.8, y: size.height * 0.3)
            
            // Table
            Ellipse()
                .fill(Color(red: 0.45, green: 0.3, blue: 0.2))
                .frame(width: 200, height: 80)
                .position(x: size.width * 0.35, y: size.height * 0.75)
            
            // Decorative plants
            Image(systemName: "leaf.fill")
                .font(.system(size: 40))
                .foregroundColor(.green.opacity(0.4))
                .position(x: size.width * 0.1, y: size.height * 0.4)
        }
    }
}

// MARK: - Frozen Coffee Cup
struct FrozenCoffeeCup: View {
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
            
            // Spilling coffee (frozen)
            if fallProgress > 0 {
                Ellipse()
                    .fill(Color.brown.opacity(0.8))
                    .frame(width: 15, height: 8)
                    .offset(x: 20, y: -10)
                    .rotationEffect(.degrees(-30))
            }
        }
        .rotationEffect(.degrees(Double(fallProgress) * 45))
        .offset(y: fallProgress * 50)
    }
}

// MARK: - Girl With Phone
struct GirlWithPhone: View {
    let phoneGlow: Bool
    let tapPulse: Bool
    
    var body: some View {
        ZStack {
            // Simple character representation
            VStack(spacing: 0) {
                // Head
                Circle()
                    .fill(Color(red: 0.95, green: 0.8, blue: 0.7))
                    .frame(width: 50, height: 50)
                    .overlay(
                        // Hair
                        Ellipse()
                            .fill(Color.brown)
                            .frame(width: 55, height: 35)
                            .offset(y: -15)
                    )
                    .overlay(
                        // Face
                        VStack(spacing: 4) {
                            HStack(spacing: 12) {
                                Circle().fill(.black).frame(width: 6, height: 6)
                                Circle().fill(.black).frame(width: 6, height: 6)
                            }
                            // Slight smile
                            Capsule()
                                .fill(Color(red: 0.9, green: 0.6, blue: 0.6))
                                .frame(width: 12, height: 4)
                        }
                        .offset(y: 5)
                    )
                
                // Body
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.pink.opacity(0.7))
                    .frame(width: 60, height: 80)
                
                // Arms holding phone
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
            
            // Phone in hands
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.black)
                    .frame(width: 35, height: 60)
                
                RoundedRectangle(cornerRadius: 6)
                    .fill(phoneGlow ? Color.cyan.opacity(0.8) : Color.gray.opacity(0.3))
                    .frame(width: 30, height: 52)
                
                // Tap indicator
                if tapPulse {
                    Circle()
                        .fill(Color.white.opacity(0.5))
                        .frame(width: 10, height: 10)
                        .scaleEffect(tapPulse ? 1.5 : 1.0)
                        .opacity(tapPulse ? 0 : 1)
                }
            }
            .offset(y: 30)
            .shadow(color: phoneGlow ? .cyan : .clear, radius: 20)
        }
    }
}

// MARK: - Frozen Particles
struct FrozenParticles: View {
    var body: some View {
        GeometryReader { geo in
            ForEach(0..<20, id: \.self) { i in
                Circle()
                    .fill(Color.white.opacity(0.6))
                    .frame(width: CGFloat.random(in: 2...5))
                    .position(
                        x: CGFloat.random(in: 0...geo.size.width),
                        y: CGFloat.random(in: 0...geo.size.height)
                    )
            }
        }
    }
}

// MARK: - Time Dilation Overlay
struct TimeDilationOverlay: View {
    @State private var shimmer = false
    
    var body: some View {
        LinearGradient(
            colors: [
                Color.cyan.opacity(0.1),
                Color.clear,
                Color.purple.opacity(0.1)
            ],
            startPoint: shimmer ? .topLeading : .bottomTrailing,
            endPoint: shimmer ? .bottomTrailing : .topLeading
        )
        .onAppear {
            withAnimation(.linear(duration: 3).repeatForever(autoreverses: true)) {
                shimmer = true
            }
        }
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
                Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { timer in
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
