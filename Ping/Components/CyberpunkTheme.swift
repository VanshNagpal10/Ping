//
//  CyberpunkTheme.swift
//  Ping
//
//  Design system for a lavish, neon cyberpunk aesthetic.
//

import SwiftUI

struct CyberpunkTheme {
    // MARK: - Colors
    static let bgVoid = Color(red: 0.03, green: 0.02, blue: 0.06)
    static let bgPanel = Color(red: 0.08, green: 0.05, blue: 0.12)
    
    static let neonCyan = Color(red: 0.0, green: 1.0, blue: 0.95)
    static let neonMagenta = Color(red: 1.0, green: 0.0, blue: 0.8)
    static let neonPurple = Color(red: 0.6, green: 0.2, blue: 1.0)
    static let neonGreen = Color(red: 0.2, green: 1.0, blue: 0.4)
    static let neonOrange = Color(red: 1.0, green: 0.5, blue: 0.0)
    static let neonYellow = Color(red: 1.0, green: 0.9, blue: 0.0)
    
    // MARK: - Fluid Mesh / Aura Background
    /// Creates a beautiful, animated blurred orb background simulating a mesh gradient.
    struct FluidBackground: View {
        @State private var animate = false
        
        var body: some View {
            ZStack {
                bgVoid.ignoresSafeArea()
                
                // Cyan Orb
                Circle()
                    .fill(neonCyan.opacity(0.4))
                    .frame(width: 400, height: 400)
                    .blur(radius: 120)
                    .offset(x: animate ? -100 : 150, y: animate ? -200 : 100)
                
                // Magenta Orb
                Circle()
                    .fill(neonMagenta.opacity(0.3))
                    .frame(width: 300, height: 300)
                    .blur(radius: 100)
                    .offset(x: animate ? 200 : -150, y: animate ? 150 : -100)
                
                // Purple Orb
                Circle()
                    .fill(neonPurple.opacity(0.4))
                    .frame(width: 500, height: 500)
                    .blur(radius: 150)
                    .offset(x: animate ? -50 : 50, y: animate ? 100 : -50)
            }
            .accessibilityHidden(true)
            .onAppear {
                withAnimation(.easeInOut(duration: 8.0).repeatForever(autoreverses: true)) {
                    animate.toggle()
                }
            }
        }
    }
    
    // MARK: - modifiers
    
    /// Modifer for crisp, glowing text
    struct GlowingTextModifier: ViewModifier {
        var color: Color
        var blurRadius: CGFloat = 3
        
        func body(content: Content) -> some View {
            content
                .foregroundColor(.white)
                .shadow(color: color, radius: blurRadius)
                .shadow(color: color.opacity(0.5), radius: blurRadius * 2)
        }
    }
    
    // MARK: - Effects
    
    /// Arcade-style CRT scanlines overlay
    struct ScanlineOverlay: View {
        var alpha: CGFloat = 0.05
        var body: some View {
            GeometryReader { geo in
                VStack(spacing: 2) {
                    ForEach(0..<Int(geo.size.height / 3), id: \.self) { _ in
                        Rectangle()
                            .fill(Color.black.opacity(alpha))
                            .frame(height: 1)
                    }
                }
            }
            .allowsHitTesting(false)
            .accessibilityHidden(true)
        }
    }
}

extension View {
    func textGlow(color: Color, radius: CGFloat = 3) -> some View {
        self.modifier(CyberpunkTheme.GlowingTextModifier(color: color, blurRadius: radius))
    }
}
