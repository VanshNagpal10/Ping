//
//  ObstacleViews.swift
//  Ping
//
//  Visual components for game obstacles
//

import SwiftUI

struct ObstacleView: View {
    let obstacle: Obstacle
    
    var body: some View {
        Group {
            switch obstacle.type {
            case .router:
                RouterObstacle(width: obstacle.width, height: obstacle.height)
            case .firewall:
                FirewallObstacle(width: obstacle.width, height: obstacle.height)
            case .congestion:
                CongestionObstacle(width: obstacle.width, height: obstacle.height)
            case .dnsFork:
                DNSForkObstacle(width: obstacle.width, height: obstacle.height)
            case .gateway:
                GatewayObstacle(width: obstacle.width, height: obstacle.height)
            }
        }
        .position(x: obstacle.x, y: obstacle.y)
        .opacity(obstacle.isActive ? 1.0 : 0.3)
    }
}

// MARK: - Router Obstacle
struct RouterObstacle: View {
    let width: CGFloat
    let height: CGFloat
    
    var body: some View {
        ZStack {
            // Glow
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.orange.opacity(0.3))
                .frame(width: width * 1.3, height: height * 1.3)
                .blur(radius: 10)
            
            // Body
            RoundedRectangle(cornerRadius: 8)
                .fill(
                    LinearGradient(
                        colors: [Color.gray, Color.gray.opacity(0.7)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: width, height: height)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.orange, lineWidth: 2)
                )
            
            // Icon
            VStack(spacing: 4) {
                Image(systemName: "wifi.router.fill")
                    .font(.system(size: width * 0.4))
                    .foregroundColor(.orange)
                
                // Blinking lights
                HStack(spacing: 3) {
                    ForEach(0..<3, id: \.self) { _ in
                        Circle()
                            .fill(Color.green)
                            .frame(width: 4, height: 4)
                    }
                }
            }
        }
    }
}

// MARK: - Firewall Obstacle (Laser)
struct FirewallObstacle: View {
    let width: CGFloat
    let height: CGFloat
    @State private var pulse = false
    
    var body: some View {
        ZStack {
            // Outer glow
            Rectangle()
                .fill(Color.red.opacity(0.5))
                .frame(width: width * 3, height: height)
                .blur(radius: 20)
            
            // Core laser
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [.red, .orange, .red],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: width, height: height)
                .scaleEffect(x: pulse ? 1.2 : 1.0)
                .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: pulse)
            
            // Warning stripes
            VStack(spacing: 0) {
                ForEach(0..<Int(height / 30), id: \.self) { i in
                    Rectangle()
                        .fill(i % 2 == 0 ? Color.black.opacity(0.5) : Color.clear)
                        .frame(height: 15)
                }
            }
            .frame(width: width, height: height)
            .clipped()
            
            // Warning icon at edges
            VStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.title2)
                    .foregroundColor(.yellow)
                Spacer()
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.title2)
                    .foregroundColor(.yellow)
            }
            .frame(height: height)
        }
        .onAppear { pulse = true }
    }
}

// MARK: - Congestion Obstacle
struct CongestionObstacle: View {
    let width: CGFloat
    let height: CGFloat
    @State private var rotate = false
    
    var body: some View {
        ZStack {
            // Slow zone indicator
            Circle()
                .fill(Color.purple.opacity(0.2))
                .frame(width: width * 1.5, height: height * 1.5)
                .blur(radius: 8)
            
            // Spinning congestion
            ZStack {
                ForEach(0..<6, id: \.self) { i in
                    Rectangle()
                        .fill(Color.purple.opacity(0.6))
                        .frame(width: width * 0.15, height: height * 0.6)
                        .offset(y: -height * 0.2)
                        .rotationEffect(.degrees(Double(i) * 60 + (rotate ? 360 : 0)))
                }
            }
            .animation(.linear(duration: 3).repeatForever(autoreverses: false), value: rotate)
            
            // Center
            Circle()
                .fill(Color.purple)
                .frame(width: width * 0.4, height: width * 0.4)
            
            Image(systemName: "hourglass")
                .font(.system(size: width * 0.2))
                .foregroundColor(.white)
        }
        .onAppear { rotate = true }
    }
}

// MARK: - DNS Fork
struct DNSForkObstacle: View {
    let width: CGFloat
    let height: CGFloat
    
    var body: some View {
        ZStack {
            // Sign posts
            VStack(spacing: 20) {
                // Correct path
                HStack {
                    Image(systemName: "arrow.up.right")
                    Text("142.250.x.x")
                }
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(.green)
                .padding(8)
                .background(Color.black.opacity(0.7))
                .cornerRadius(4)
                
                // Wrong path
                HStack {
                    Image(systemName: "arrow.down.right")
                    Text("404.0.0.0")
                }
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(.red)
                .padding(8)
                .background(Color.black.opacity(0.7))
                .cornerRadius(4)
            }
        }
    }
}

// MARK: - Gateway
struct GatewayObstacle: View {
    let width: CGFloat
    let height: CGFloat
    @State private var glow = false
    
    var body: some View {
        ZStack {
            // Gateway arch
            RoundedRectangle(cornerRadius: 20)
                .stroke(
                    LinearGradient(
                        colors: [.cyan, .blue, .cyan],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    lineWidth: 4
                )
                .frame(width: width, height: height)
                .shadow(color: .cyan.opacity(glow ? 0.8 : 0.3), radius: glow ? 20 : 10)
                .animation(.easeInOut(duration: 1).repeatForever(autoreverses: true), value: glow)
            
            // Gateway label
            VStack {
                Image(systemName: "door.left.hand.open")
                    .font(.title)
                    .foregroundColor(.cyan)
                Text("GATEWAY")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.cyan)
            }
        }
        .onAppear { glow = true }
    }
}

// MARK: - Power-Up View
struct PowerUpView: View {
    let powerUp: PowerUp
    @State private var bounce = false
    
    var body: some View {
        ZStack {
            // Glow
            Circle()
                .fill(powerUpColor.opacity(0.4))
                .frame(width: 50, height: 50)
                .blur(radius: 10)
            
            // Icon background
            Circle()
                .fill(Color.black.opacity(0.5))
                .frame(width: 40, height: 40)
                .overlay(
                    Circle()
                        .stroke(powerUpColor, lineWidth: 2)
                )
            
            // Icon
            Image(systemName: powerUpIcon)
                .font(.title3)
                .foregroundColor(powerUpColor)
        }
        .position(x: powerUp.x, y: powerUp.y)
        .scaleEffect(bounce ? 1.1 : 1.0)
        .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: bounce)
        .opacity(powerUp.isCollected ? 0 : 1)
        .onAppear { bounce = true }
    }
    
    private var powerUpColor: Color {
        switch powerUp.type {
        case .bandwidth: return .green
        case .latencyReduce: return .blue
        case .shield: return .yellow
        }
    }
    
    private var powerUpIcon: String {
        switch powerUp.type {
        case .bandwidth: return "arrow.up.circle.fill"
        case .latencyReduce: return "clock.arrow.circlepath"
        case .shield: return "shield.fill"
        }
    }
}

#Preview {
    ZStack {
        Color.black
        VStack(spacing: 40) {
            RouterObstacle(width: 60, height: 80)
            FirewallObstacle(width: 20, height: 200)
            CongestionObstacle(width: 50, height: 50)
        }
    }
}
