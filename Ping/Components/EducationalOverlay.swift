//
//  EducationalOverlay.swift
//  Ping
//
//  Educational content between zones and pause menu wiki
//

import SwiftUI

// MARK: - Zone Transition Overlay
struct ZoneTransitionOverlay: View {
    let fromZone: Zone
    let toZone: Zone
    @State private var showLesson = false
    
    var body: some View {
        ZStack {
            // Dark overlay
            Color.black.opacity(0.9)
            
            VStack(spacing: 24) {
                // Zone header
                HStack {
                    Text("ENTERING")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundColor(.gray)
                    
                    Image(systemName: "arrow.right")
                        .foregroundColor(toZone.accentColor)
                    
                    Text(toZone.name.uppercased())
                        .font(.system(size: 18, weight: .bold, design: .monospaced))
                        .foregroundColor(toZone.accentColor)
                }
                
                // Routing table visual
                VStack(spacing: 8) {
                    Text("ROUTING TABLE UPDATE")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(.green)
                    
                    HStack(spacing: 20) {
                        VStack(alignment: .leading) {
                            Text("FROM:")
                                .font(.system(size: 9, design: .monospaced))
                                .foregroundColor(.gray)
                            Text(fromZone.name)
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundColor(.white)
                        }
                        
                        Image(systemName: "arrow.right.circle.fill")
                            .foregroundColor(.green)
                        
                        VStack(alignment: .leading) {
                            Text("TO:")
                                .font(.system(size: 9, design: .monospaced))
                                .foregroundColor(.gray)
                            Text(toZone.name)
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundColor(.white)
                        }
                    }
                    .padding()
                    .background(Color.black)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.green.opacity(0.5), lineWidth: 1)
                    )
                }
                
                // Educational lesson
                if showLesson {
                    VStack(spacing: 12) {
                        Image(systemName: "lightbulb.fill")
                            .font(.title2)
                            .foregroundColor(.yellow)
                        
                        Text(toZone.lesson)
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(0.9))
                            .multilineTextAlignment(.center)
                            .lineLimit(3)
                            .padding(.horizontal, 40)
                    }
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                }
            }
        }
        .onAppear {
            withAnimation(.easeIn(duration: 0.5).delay(0.5)) {
                showLesson = true
            }
        }
    }
}

// MARK: - Pause Menu Wiki
struct PauseMenuView: View {
    let currentZone: Zone
    let latency: Int
    let onResume: () -> Void
    let onQuit: () -> Void
    
    @State private var selectedTopic: WikiTopic = .currentZone
    
    var body: some View {
        ZStack {
            // Blur background
            Color.black.opacity(0.85)
            
            VStack(spacing: 20) {
                // Header
                HStack {
                    Text("PAUSED")
                        .font(.system(size: 24, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    HStack(spacing: 8) {
                        Image(systemName: "clock")
                        Text("\(latency)ms")
                    }
                    .font(.system(size: 14, design: .monospaced))
                    .foregroundColor(latency < 200 ? .green : latency < 400 ? .yellow : .red)
                }
                .padding(.horizontal, 40)
                
                Divider()
                    .background(Color.gray)
                    .padding(.horizontal, 40)
                
                // Wiki content
                HStack(alignment: .top, spacing: 30) {
                    // Topic selector
                    VStack(alignment: .leading, spacing: 12) {
                        Text("WIKI")
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundColor(.gray)
                        
                        ForEach(WikiTopic.allCases, id: \.self) { topic in
                            Button(action: { selectedTopic = topic }) {
                                HStack {
                                    Image(systemName: topic.icon)
                                        .frame(width: 20)
                                    Text(topic.title)
                                        .font(.system(size: 12, design: .monospaced))
                                }
                                .foregroundColor(selectedTopic == topic ? topic.color : .gray)
                            }
                        }
                    }
                    .frame(width: 150)
                    
                    // Content
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            Text(selectedTopic.title)
                                .font(.system(size: 18, weight: .bold, design: .monospaced))
                                .foregroundColor(selectedTopic.color)
                            
                            Text(wikiContent(for: selectedTopic))
                                .font(.system(size: 13))
                                .foregroundColor(.white.opacity(0.9))
                                .lineSpacing(4)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(maxWidth: 400)
                }
                .padding(.horizontal, 40)
                
                Divider()
                    .background(Color.gray)
                    .padding(.horizontal, 40)
                
                // Buttons
                HStack(spacing: 20) {
                    Button(action: onResume) {
                        HStack {
                            Image(systemName: "play.fill")
                            Text("RESUME")
                        }
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                        .foregroundColor(.black)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color.green)
                        .cornerRadius(8)
                    }
                    
                    Button(action: onQuit) {
                        HStack {
                            Image(systemName: "xmark")
                            Text("QUIT")
                        }
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color.red.opacity(0.8))
                        .cornerRadius(8)
                    }
                }
                .padding(.bottom, 20)
            }
            .padding(.vertical, 30)
        }
    }
    
    private func wikiContent(for topic: WikiTopic) -> String {
        switch topic {
        case .currentZone:
            return currentZone.lesson + "\n\n" + zoneDetails(for: currentZone)
        case .protocols:
            return """
            HTTP (Hypertext Transfer Protocol) sends data in plain text. It's fast but vulnerable to interception.
            
            HTTPS adds SSL/TLS encryption, creating a secure tunnel. This protects your data from eavesdroppers but adds slight overhead.
            
            In the game, HTTPS mode gives you a shield that protects against firewall attacks!
            """
        case .tcpUdp:
            return """
            TCP (Transmission Control Protocol) ensures reliable delivery. It confirms every packet arrived and resends lost ones. Great for web pages!
            
            UDP (User Datagram Protocol) is faster but doesn't guarantee delivery. Perfect for live video or gaming where speed matters more than perfection.
            
            In the game, TCP gives precise control while UDP is faster but slippery!
            """
        case .latency:
            return """
            Latency (Ping) measures the time for data to travel from source to destination and back.
            
            < 50ms: Excellent - feels instant
            50-100ms: Good - barely noticeable
            100-200ms: Fair - slight delay
            > 200ms: Poor - noticeable lag
            > 500ms: Timeout - connection lost!
            
            Physical distance, network congestion, and processing time all add latency.
            """
        case .dns:
            return """
            DNS (Domain Name System) is like the internet's phone book.
            
            When you type "google.com", your device asks a DNS server: "What's the IP address for google.com?"
            
            The DNS responds: "142.250.x.x"
            
            Without DNS, you'd have to memorize IP addresses for every website!
            """
        }
    }
    
    private func zoneDetails(for zone: Zone) -> String {
        switch zone {
        case .localNetwork:
            return "Your home network uses private IP addresses (192.168.x.x). The router acts as a gateway between your devices and the internet."
        case .ispDns:
            return "Your ISP (Internet Service Provider) routes your data through their network. DNS servers translate domain names to IP addresses."
        case .backbone:
            return "The internet backbone consists of undersea cables and major exchange points. Data travels at the speed of light through fiber optics!"
        case .lastMile:
            return "The 'last mile' is often the slowest part - the connection from the ISP to your home. Bandwidth limits how much data can flow at once."
        }
    }
}

// MARK: - Wiki Topics
enum WikiTopic: CaseIterable {
    case currentZone
    case protocols
    case tcpUdp
    case latency
    case dns
    
    var title: String {
        switch self {
        case .currentZone: return "Current Zone"
        case .protocols: return "HTTP vs HTTPS"
        case .tcpUdp: return "TCP vs UDP"
        case .latency: return "What is Latency?"
        case .dns: return "DNS Explained"
        }
    }
    
    var icon: String {
        switch self {
        case .currentZone: return "mappin.circle.fill"
        case .protocols: return "lock.shield.fill"
        case .tcpUdp: return "arrow.left.arrow.right"
        case .latency: return "clock.fill"
        case .dns: return "text.book.closed.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .currentZone: return .cyan
        case .protocols: return .yellow
        case .tcpUdp: return .purple
        case .latency: return .green
        case .dns: return .orange
        }
    }
}

#Preview {
    PauseMenuView(
        currentZone: .ispDns,
        latency: 125,
        onResume: {},
        onQuit: {}
    )
}
