//
//  GameModels.swift
//  Ping
//
//  Core data models for the game
//

import SwiftUI

// MARK: - Game Phase
enum GamePhase {
    case intro          // Fake iPhone screen
    case transition     // Glitch into digital world
    case playing        // Main runner gameplay
    case handshake      // TCP handshake mini-game
    case returning      // Heavy packet return journey
    case debrief        // TraceRoute summary
}

// MARK: - Network Zone
enum Zone: Int, CaseIterable {
    case localNetwork = 0   // Wi-Fi, home
    case ispDns = 1         // Highway, DNS lookup
    case backbone = 2       // Undersea cables, firewalls
    case lastMile = 3       // Return journey
    
    var name: String {
        switch self {
        case .localNetwork: return "Local Network"
        case .ispDns: return "ISP & DNS"
        case .backbone: return "Internet Backbone"
        case .lastMile: return "Last Mile"
        }
    }
    
    var lesson: String {
        switch self {
        case .localNetwork:
            return "Before reaching the internet, data must find the Local Gateway (192.168.x.x)."
        case .ispDns:
            return "DNS translates domain names into IP Addresses so routers know where to send data."
        case .backbone:
            return "Data travels through undersea cables. HTTPS encryption protects it from interception."
        case .lastMile:
            return "Downloads are slower because files (images/video) are much heavier than text requests."
        }
    }
    
    var backgroundColor: Color {
        switch self {
        case .localNetwork: return Color(red: 0.1, green: 0.15, blue: 0.2)
        case .ispDns: return Color(red: 0.05, green: 0.1, blue: 0.2)
        case .backbone: return Color(red: 0.02, green: 0.05, blue: 0.15)
        case .lastMile: return Color(red: 0.1, green: 0.08, blue: 0.15)
        }
    }
    
    var accentColor: Color {
        switch self {
        case .localNetwork: return .green
        case .ispDns: return .cyan
        case .backbone: return .blue
        case .lastMile: return .orange
        }
    }
}

// MARK: - Protocol Mode
enum ProtocolMode {
    case http   // Fast but vulnerable
    case https  // Shield, slightly slower
    
    var speedMultiplier: CGFloat {
        switch self {
        case .http: return 1.0
        case .https: return 0.85  // Encryption overhead
        }
    }
}

// MARK: - Movement Style
enum MovementStyle {
    case tcp    // Precise but slower
    case udp    // Fast but slippery
    
    var friction: CGFloat {
        switch self {
        case .tcp: return 0.9
        case .udp: return 0.98  // More slippery
        }
    }
    
    var speed: CGFloat {
        switch self {
        case .tcp: return 1.0
        case .udp: return 1.3
        }
    }
}

// MARK: - Packet State
struct PacketState {
    var x: CGFloat = 100
    var y: CGFloat = 300
    var velocityY: CGFloat = 0
    var velocityX: CGFloat = 0
    var size: CGFloat = 40          // Grows when carrying data
    var protocolMode: ProtocolMode = .http
    var movementStyle: MovementStyle = .tcp
    var isCarryingPayload: Bool = false
    
    var effectiveSize: CGFloat {
        isCarryingPayload ? size * 2.5 : size
    }
}

// MARK: - Obstacle Types
enum ObstacleType {
    case router         // Blocks path, adds latency
    case firewall       // Laser - instant death without HTTPS
    case congestion     // Slows down
    case dnsFork        // Path choice
    case gateway        // Must pass through
    
    var latencyPenalty: Int {
        switch self {
        case .router: return 50
        case .firewall: return 100
        case .congestion: return 30
        case .dnsFork: return 20
        case .gateway: return 0
        }
    }
}

// MARK: - Obstacle
struct Obstacle: Identifiable {
    let id = UUID()
    var type: ObstacleType
    var x: CGFloat
    var y: CGFloat
    var width: CGFloat
    var height: CGFloat
    var isActive: Bool = true
    
    var frame: CGRect {
        CGRect(x: x - width/2, y: y - height/2, width: width, height: height)
    }
}

// MARK: - Power-Up Types
enum PowerUpType {
    case bandwidth      // Speed boost
    case latencyReduce  // Reduce ping
    case shield         // Temporary invincibility
}

// MARK: - Power-Up
struct PowerUp: Identifiable {
    let id = UUID()
    var type: PowerUpType
    var x: CGFloat
    var y: CGFloat
    var isCollected: Bool = false
}

// MARK: - Handshake Step
enum HandshakeStep: Int, CaseIterable {
    case waiting = 0
    case syn = 1
    case synAck = 2
    case ack = 3
    case complete = 4
    
    var label: String {
        switch self {
        case .waiting: return "CONNECT"
        case .syn: return "SYN"
        case .synAck: return "SYN-ACK"
        case .ack: return "ACK"
        case .complete: return "CONNECTED!"
        }
    }
}

// MARK: - Journey Stats
struct JourneyStats {
    var startTime: Date = Date()
    var endTime: Date?
    var finalLatency: Int = 0
    var obstaclesHit: Int = 0
    var protocolSwitches: Int = 0
    var zonesVisited: [Zone] = []
    var success: Bool = false
    
    var duration: TimeInterval {
        (endTime ?? Date()).timeIntervalSince(startTime)
    }
}
