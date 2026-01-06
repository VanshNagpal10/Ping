//
//  ZoneBackgrounds.swift
//  Ping
//
//  Animated backgrounds for each network zone
//

import SwiftUI

struct ZoneBackground: View {
    let zone: Zone
    let scrollOffset: CGFloat
    
    var body: some View {
        ZStack {
            // Base gradient
            LinearGradient(
                colors: [zone.backgroundColor, zone.backgroundColor.opacity(0.7)],
                startPoint: .top,
                endPoint: .bottom
            )
            
            // Zone-specific elements
            switch zone {
            case .localNetwork:
                LocalNetworkBackground(scrollOffset: scrollOffset)
            case .ispDns:
                ISPHighwayBackground(scrollOffset: scrollOffset)
            case .backbone:
                BackboneBackground(scrollOffset: scrollOffset)
            case .lastMile:
                LastMileBackground(scrollOffset: scrollOffset)
            }
            
            // Universal grid overlay
            GridOverlay(color: zone.accentColor, scrollOffset: scrollOffset)
        }
        .ignoresSafeArea()
    }
}

// MARK: - Grid Overlay
struct GridOverlay: View {
    let color: Color
    let scrollOffset: CGFloat
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Horizontal lines
                VStack(spacing: 60) {
                    ForEach(0..<15, id: \.self) { _ in
                        Rectangle()
                            .fill(color.opacity(0.1))
                            .frame(height: 1)
                    }
                }
                
                // Vertical scrolling lines
                HStack(spacing: 100) {
                    ForEach(0..<20, id: \.self) { i in
                        Rectangle()
                            .fill(color.opacity(0.08))
                            .frame(width: 1)
                            .offset(x: -scrollOffset.truncatingRemainder(dividingBy: 100))
                    }
                }
            }
        }
    }
}

// MARK: - Local Network (Home/Wi-Fi)
struct LocalNetworkBackground: View {
    let scrollOffset: CGFloat
    @State private var wifiPulse = false
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Cozy warm overlay
                RadialGradient(
                    colors: [Color.orange.opacity(0.1), Color.clear],
                    center: .center,
                    startRadius: 0,
                    endRadius: geo.size.width * 0.5
                )
                
                // Wi-Fi waves
                ForEach(0..<3, id: \.self) { i in
                    WifiWave(index: i, pulse: wifiPulse)
                        .position(x: geo.size.width * 0.8 - scrollOffset.truncatingRemainder(dividingBy: 400), y: geo.size.height * 0.3)
                }
                
                // Router icon
                Image(systemName: "wifi.router.fill")
                    .font(.system(size: 30))
                    .foregroundColor(.green.opacity(0.3))
                    .position(x: geo.size.width * 0.85 - scrollOffset.truncatingRemainder(dividingBy: 600), y: geo.size.height * 0.2)
                
                // Home furniture silhouettes
                ForEach(0..<3, id: \.self) { i in
                    Image(systemName: ["sofa.fill", "bed.double.fill", "tv.fill"][i])
                        .font(.system(size: 40))
                        .foregroundColor(.gray.opacity(0.1))
                        .position(
                            x: CGFloat(200 + i * 300) - scrollOffset.truncatingRemainder(dividingBy: CGFloat(300 * 3)),
                            y: geo.size.height * 0.85
                        )
                }
            }
            .onAppear { wifiPulse = true }
        }
    }
}

struct WifiWave: View {
    let index: Int
    let pulse: Bool
    
    var body: some View {
        Circle()
            .stroke(Color.green.opacity(0.3 - Double(index) * 0.1), lineWidth: 2)
            .frame(width: CGFloat(40 + index * 30), height: CGFloat(40 + index * 30))
            .scaleEffect(pulse ? 1.2 : 1.0)
            .opacity(pulse ? 0.5 : 0.3)
            .animation(
                .easeInOut(duration: 1.5)
                .repeatForever(autoreverses: true)
                .delay(Double(index) * 0.2),
                value: pulse
            )
    }
}

// MARK: - ISP Highway
struct ISPHighwayBackground: View {
    let scrollOffset: CGFloat
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Fiber optic cables
                ForEach(0..<5, id: \.self) { i in
                    FiberCable(index: i, scrollOffset: scrollOffset, screenWidth: geo.size.width)
                        .position(y: CGFloat(80 + i * 80))
                }
                
                // Neon signs
                ForEach(0..<3, id: \.self) { i in
                    NeonSign(text: ["DNS", "ISP", "CDN"][i], color: [.cyan, .pink, .purple][i])
                        .position(
                            x: CGFloat(300 + i * 400) - scrollOffset.truncatingRemainder(dividingBy: CGFloat(400 * 3)),
                            y: geo.size.height * 0.15
                        )
                }
                
                // Speed lines
                ForEach(0..<10, id: \.self) { i in
                    SpeedLine(index: i, scrollOffset: scrollOffset, screenWidth: geo.size.width)
                }
            }
        }
    }
}

struct FiberCable: View {
    let index: Int
    let scrollOffset: CGFloat
    let screenWidth: CGFloat
    
    var body: some View {
        GeometryReader { geo in
            Path { path in
                path.move(to: CGPoint(x: 0, y: 0))
                for x in stride(from: 0, to: screenWidth + 100, by: 50) {
                    // Disambiguate types for trigonometry
                    let xD: Double = Double(x)
                    let offsetD: Double = Double(scrollOffset)
                    let phase: Double = (xD + offsetD) / 50.0 + Double(index)
                    let sine: Double = sin(phase)
                    let y: CGFloat = CGFloat(sine * 10.0)
                    path.addLine(to: CGPoint(x: x, y: y))
                }
            }
            .stroke(
                LinearGradient(
                    colors: [.cyan.opacity(0.3), .blue.opacity(0.5), .cyan.opacity(0.3)],
                    startPoint: .leading,
                    endPoint: .trailing
                ),
                lineWidth: 2
            )
        }
        .frame(height: 20)
    }
}

struct NeonSign: View {
    let text: String
    let color: Color
    @State private var glow = false
    
    var body: some View {
        Text(text)
            .font(.system(size: 24, weight: .bold, design: .monospaced))
            .foregroundColor(color)
            .shadow(color: color, radius: glow ? 15 : 5)
            .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: glow)
            .onAppear { glow = true }
    }
}

struct SpeedLine: View {
    let index: Int
    let scrollOffset: CGFloat
    let screenWidth: CGFloat
    
    var body: some View {
        Rectangle()
            .fill(Color.cyan.opacity(0.2))
            .frame(width: 50, height: 2)
            .position(
                x: CGFloat(index * 120) - scrollOffset.truncatingRemainder(dividingBy: CGFloat(120 * 10)),
                y: CGFloat(100 + (index % 5) * 100)
            )
    }
}

// MARK: - Backbone (Undersea)
struct BackboneBackground: View {
    let scrollOffset: CGFloat
    @State private var bubbleOffset: CGFloat = 0
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Deep ocean gradient
                LinearGradient(
                    colors: [Color(red: 0.02, green: 0.05, blue: 0.2), Color(red: 0.01, green: 0.02, blue: 0.1)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                
                // Undersea cables
                ForEach(0..<3, id: \.self) { i in
                    UnderseaCable(index: i, scrollOffset: scrollOffset, screenHeight: geo.size.height)
                }
                
                // Bubbles
                ForEach(0..<8, id: \.self) { i in
                    Circle()
                        .fill(Color.blue.opacity(0.2))
                        .frame(width: CGFloat.random(in: 5...15))
                        .position(
                            x: CGFloat(100 + i * 150),
                            y: geo.size.height - bubbleOffset.truncatingRemainder(dividingBy: geo.size.height) - CGFloat(i * 50)
                        )
                }
                
                // Mysterious glow
                RadialGradient(
                    colors: [Color.blue.opacity(0.15), Color.clear],
                    center: UnitPoint(x: 0.7, y: 0.5),
                    startRadius: 0,
                    endRadius: 300
                )
            }
            .onAppear {
                withAnimation(.linear(duration: 10).repeatForever(autoreverses: false)) {
                    bubbleOffset = geo.size.height
                }
            }
        }
    }
}

struct UnderseaCable: View {
    let index: Int
    let scrollOffset: CGFloat
    let screenHeight: CGFloat
    
    var body: some View {
        GeometryReader { geo in
            Path { path in
                // Disambiguate types and break up expressions for the compiler
                let startY: CGFloat = screenHeight * (0.6 + CGFloat(index) * 0.1)
                path.move(to: CGPoint(x: 0, y: startY))

                let width: CGFloat = geo.size.width
                let step: CGFloat = 30
                let extra: CGFloat = 100

                var x: CGFloat = 0
                while x <= width + extra {
                    // Convert to Double for trigonometry, then back to CGFloat
                    let xD: Double = Double(x)
                    let offsetD: Double = Double(scrollOffset)
                    let phase: Double = (xD + offsetD) / 100.0 + Double(index) * 2.0
                    let sine: Double = sin(phase)
                    let yOffset: CGFloat = CGFloat(sine * 30.0)
                    let y: CGFloat = startY + yOffset
                    path.addLine(to: CGPoint(x: x, y: y))
                    x += step
                }
            }
            .stroke(Color.blue.opacity(0.4), lineWidth: 8)
        }
    }
}

// MARK: - Last Mile (City)
struct LastMileBackground: View {
    let scrollOffset: CGFloat
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                // City gradient
                LinearGradient(
                    colors: [Color(red: 0.15, green: 0.1, blue: 0.2), Color(red: 0.1, green: 0.05, blue: 0.15)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                
                // City skyline
                HStack(spacing: 10) {
                    ForEach(0..<15, id: \.self) { i in
                        BuildingSilhouette(index: i, screenHeight: geo.size.height)
                            .offset(x: -scrollOffset.truncatingRemainder(dividingBy: CGFloat(60 * 15)))
                    }
                }
                
                // Traffic/data lines
                ForEach(0..<6, id: \.self) { i in
                    DataTraffic(index: i, scrollOffset: scrollOffset, screenSize: geo.size)
                }
                
                // Congestion indicator
                if scrollOffset.truncatingRemainder(dividingBy: 500) < 100 {
                    Text("CONGESTION AHEAD")
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(.orange)
                        .padding(8)
                        .background(Color.black.opacity(0.7))
                        .cornerRadius(4)
                        .position(x: geo.size.width * 0.7, y: geo.size.height * 0.2)
                }
            }
        }
    }
}

struct BuildingSilhouette: View {
    let index: Int
    let screenHeight: CGFloat
    
    var body: some View {
        let height = CGFloat.random(in: 80...200)
        let width: CGFloat = 40
        
        VStack(spacing: 0) {
            Spacer()
            ZStack {
                Rectangle()
                    .fill(Color.gray.opacity(0.15))
                    .frame(width: width, height: height)
                
                // Windows
                VStack(spacing: 8) {
                    ForEach(0..<Int(height / 25), id: \.self) { row in
                        HStack(spacing: 6) {
                            ForEach(0..<2, id: \.self) { _ in
                                Rectangle()
                                    .fill(Color.yellow.opacity(CGFloat.random(in: 0.1...0.4)))
                                    .frame(width: 8, height: 6)
                            }
                        }
                    }
                }
            }
        }
        .frame(width: 50)
    }
}

struct DataTraffic: View {
    let index: Int
    let scrollOffset: CGFloat
    let screenSize: CGSize
    
    var body: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [Color.orange.opacity(0.0), Color.orange.opacity(0.4), Color.orange.opacity(0.0)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(width: 80, height: 3)
            .position(
                x: CGFloat(index * 200) - scrollOffset.truncatingRemainder(dividingBy: CGFloat(200 * 6)),
                y: CGFloat(150 + (index % 4) * 80)
            )
    }
}

#Preview {
    ZoneBackground(zone: .backbone, scrollOffset: 100)
}
