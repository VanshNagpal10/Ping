//
//  DebriefView.swift
//  Ping
//
//  Journey summary with TraceRoute log and educational facts
//

import SwiftUI

struct DebriefView: View {
    let stats: JourneyStats
    let onReplay: () -> Void
    
    @State private var showContent = false
    @State private var typewriterIndex = 0
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Background
                TerminalBackground()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        VStack(spacing: 8) {
                            Image(systemName: stats.success ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .font(.system(size: 60))
                                .foregroundColor(stats.success ? .green : .red)
                                .scaleEffect(showContent ? 1 : 0)
                                .animation(.spring(response: 0.5, dampingFraction: 0.6), value: showContent)
                            
                            Text(stats.success ? "PACKET DELIVERED!" : "REQUEST TIMED OUT")
                                .font(.system(size: 28, weight: .bold, design: .monospaced))
                                .foregroundColor(stats.success ? .green : .red)
                            
                            Text(stats.success ? "Your data made it home safely" : "The packet was lost in transit")
                                .font(.system(size: 14, design: .monospaced))
                                .foregroundColor(.gray)
                        }
                        .padding(.top, 40)
                        
                        // Stats cards
                        HStack(spacing: 20) {
                            StatCard(title: "FINAL PING", value: "\(stats.finalLatency)ms", color: pingColor)
                            StatCard(title: "DURATION", value: String(format: "%.1fs", stats.duration), color: .cyan)
                            StatCard(title: "OBSTACLES HIT", value: "\(stats.obstaclesHit)", color: .orange)
                        }
                        .opacity(showContent ? 1 : 0)
                        .offset(y: showContent ? 0 : 20)
                        
                        // TraceRoute log
                        TraceRouteLog(zones: stats.zonesVisited.isEmpty ? Zone.allCases.map { $0 } : stats.zonesVisited)
                            .opacity(showContent ? 1 : 0)
                            .offset(y: showContent ? 0 : 30)
                        
                        // Educational summary
                        EducationalSummary()
                            .opacity(showContent ? 1 : 0)
                            .offset(y: showContent ? 0 : 40)
                        
                        // Action buttons
                        HStack(spacing: 20) {
                            Button(action: onReplay) {
                                HStack {
                                    Image(systemName: "arrow.counterclockwise")
                                    Text("PLAY AGAIN")
                                }
                                .font(.system(size: 16, weight: .bold, design: .monospaced))
                                .foregroundColor(.black)
                                .padding(.horizontal, 30)
                                .padding(.vertical, 14)
                                .background(Color.cyan)
                                .cornerRadius(10)
                            }
                        }
                        .padding(.top, 20)
                        .padding(.bottom, 40)
                        .opacity(showContent ? 1 : 0)
                    }
                    .padding(.horizontal, 40)
                }
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8).delay(0.3)) {
                showContent = true
            }
        }
    }
    
    private var pingColor: Color {
        if stats.finalLatency < 100 {
            return .green
        } else if stats.finalLatency < 300 {
            return .yellow
        } else {
            return .red
        }
    }
}

// MARK: - Terminal Background
struct TerminalBackground: View {
    var body: some View {
        ZStack {
            Color.black
            
            // CRT scanlines
            VStack(spacing: 3) {
                ForEach(0..<200, id: \.self) { _ in
                    Rectangle()
                        .fill(Color.green.opacity(0.03))
                        .frame(height: 1)
                }
            }
            
            // Vignette
            RadialGradient(
                colors: [Color.clear, Color.black.opacity(0.8)],
                center: .center,
                startRadius: 200,
                endRadius: 600
            )
        }
        .ignoresSafeArea()
    }
}

// MARK: - Stat Card
struct StatCard: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundColor(.gray)
            
            Text(value)
                .font(.system(size: 24, weight: .bold, design: .monospaced))
                .foregroundColor(color)
        }
        .frame(width: 140, height: 80)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(color.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(color.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

// MARK: - TraceRoute Log
struct TraceRouteLog: View {
    let zones: [Zone]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: "terminal.fill")
                Text("TRACEROUTE LOG")
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
            }
            .foregroundColor(.green)
            
            // Log entries
            VStack(alignment: .leading, spacing: 8) {
                Text("$ traceroute packet.journey")
                    .foregroundColor(.gray)
                
                ForEach(Array(zones.enumerated()), id: \.offset) { index, zone in
                    TraceRouteEntry(hop: index + 1, zone: zone)
                }
                
                Text("Trace complete.")
                    .foregroundColor(.green)
            }
            .font(.system(size: 12, design: .monospaced))
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.black.opacity(0.5))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.green.opacity(0.3), lineWidth: 1)
            )
        }
    }
}

struct TraceRouteEntry: View {
    let hop: Int
    let zone: Zone
    
    @State private var appear = false
    
    var body: some View {
        HStack(spacing: 12) {
            Text("\(hop)")
                .frame(width: 20)
                .foregroundColor(.cyan)
            
            Text(zoneIP)
                .frame(width: 100, alignment: .leading)
                .foregroundColor(.yellow)
            
            Text(zone.name)
                .foregroundColor(.white)
            
            Spacer()
            
            Text("\(Int.random(in: 5...50))ms")
                .foregroundColor(.green)
        }
        .opacity(appear ? 1 : 0)
        .offset(x: appear ? 0 : -10)
        .onAppear {
            withAnimation(.easeOut(duration: 0.3).delay(Double(hop) * 0.2)) {
                appear = true
            }
        }
    }
    
    private var zoneIP: String {
        switch zone {
        case .localNetwork: return "192.168.1.1"
        case .ispDns: return "10.0.0.1"
        case .backbone: return "8.8.8.8"
        case .lastMile: return "200.10.1.1"
        }
    }
}

// MARK: - Educational Summary
struct EducationalSummary: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.yellow)
                Text("WHAT YOU LEARNED")
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundColor(.yellow)
            }
            
            VStack(alignment: .leading, spacing: 12) {
                LearningPoint(
                    icon: "wifi",
                    title: "Local Network",
                    description: "Data starts at your device and finds the gateway router"
                )
                
                LearningPoint(
                    icon: "globe",
                    title: "DNS Resolution",
                    description: "Domain names are translated to IP addresses"
                )
                
                LearningPoint(
                    icon: "lock.shield",
                    title: "HTTPS Encryption",
                    description: "SSL/TLS protects data from interception"
                )
                
                LearningPoint(
                    icon: "arrow.left.arrow.right",
                    title: "TCP Handshake",
                    description: "SYN → SYN-ACK → ACK establishes connection"
                )
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.yellow.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.yellow.opacity(0.2), lineWidth: 1)
                    )
            )
        }
    }
}

struct LearningPoint: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(.cyan)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
                
                Text(description)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(.gray)
            }
        }
    }
}

#Preview {
    DebriefView(
        stats: JourneyStats(
            startTime: Date().addingTimeInterval(-120),
            endTime: Date(),
            finalLatency: 142,
            obstaclesHit: 3,
            protocolSwitches: 2,
            zonesVisited: [.localNetwork, .ispDns, .backbone, .lastMile],
            success: true
        ),
        onReplay: {}
    )
}
