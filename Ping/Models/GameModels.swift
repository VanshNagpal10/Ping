//
//  GameModels.swift
//  Ping - Packet World
//
//  Core data models for the narrative adventure game
//

import SwiftUI

// MARK: - Game Phase (Story Acts)
enum GamePhase: Equatable {
    case prologue           // Frozen world cinematic
    case act1_smartphone    // CPU City - Meet Daemon, get mission
    case act2_transmission  // Wi-Fi Antenna & Router station
    case act3_oceanFloor    // Fiber optic cable journey
    case act4_dnsServer     // The Library - DNS lookup
    case act5_return        // Rush back home
    case epilogue           // Coffee cup falls, feed loads
}

// MARK: - Story Scene
enum StoryScene: String, CaseIterable {
    case frozenCafe = "frozen_cafe"
    case cpuCity = "cpu_city"
    case wifiAntenna = "wifi_antenna"
    case routerStation = "router_station"
    case oceanCable = "ocean_cable"
    case dnsLibrary = "dns_library"
    case returnJourney = "return_journey"
    case feedLoaded = "feed_loaded"
    
    var displayName: String {
        switch self {
        case .frozenCafe: return "The Frozen World"
        case .cpuCity: return "CPU City"
        case .wifiAntenna: return "Wi-Fi Antenna"
        case .routerStation: return "Router Station"
        case .oceanCable: return "Ocean Floor Cable"
        case .dnsLibrary: return "DNS Library"
        case .returnJourney: return "The Return"
        case .feedLoaded: return "Mission Complete"
        }
    }
    
    var backgroundColor: Color {
        switch self {
        case .frozenCafe: return Color(red: 0.95, green: 0.93, blue: 0.88)
        case .cpuCity: return Color(red: 0.05, green: 0.08, blue: 0.15)
        case .wifiAntenna: return Color(red: 0.1, green: 0.15, blue: 0.25)
        case .routerStation: return Color(red: 0.08, green: 0.12, blue: 0.18)
        case .oceanCable: return Color(red: 0.02, green: 0.08, blue: 0.2)
        case .dnsLibrary: return Color(red: 0.12, green: 0.08, blue: 0.15)
        case .returnJourney: return Color(red: 0.1, green: 0.1, blue: 0.2)
        case .feedLoaded: return Color(red: 0.95, green: 0.93, blue: 0.88)
        }
    }
    
    var accentColor: Color {
        switch self {
        case .frozenCafe: return .brown
        case .cpuCity: return .cyan
        case .wifiAntenna: return .green
        case .routerStation: return .orange
        case .oceanCable: return .blue
        case .dnsLibrary: return .purple
        case .returnJourney: return .yellow
        case .feedLoaded: return .pink
        }
    }
}

// MARK: - Packet Layers (Equipment System)
struct PacketLayers: Equatable {
    var applicationLayer: ApplicationPayload = .empty
    var transportLayer: TransportProtocol = .tcp
    var networkLayer: NetworkHeader = NetworkHeader()
    
    var isComplete: Bool {
        applicationLayer != .empty && networkLayer.hasDestination
    }
}

enum ApplicationPayload: String, Equatable {
    case empty = "Empty"
    case dnsQuery = "GET socialmedia.com"
    case ipResponse = "IP: 142.250.185.78"
    
    var icon: String {
        switch self {
        case .empty: return "bag"
        case .dnsQuery: return "magnifyingglass"
        case .ipResponse: return "doc.text"
        }
    }
    
    var color: Color {
        switch self {
        case .empty: return .gray
        case .dnsQuery: return .cyan
        case .ipResponse: return .green
        }
    }
}

enum TransportProtocol: String, Equatable {
    case tcp = "TCP"
    case udp = "UDP"
    
    var description: String {
        switch self {
        case .tcp: return "Reliable but slower"
        case .udp: return "Fast but risky"
        }
    }
    
    var icon: String {
        switch self {
        case .tcp: return "checkmark.shield.fill"
        case .udp: return "bolt.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .tcp: return .green
        case .udp: return .orange
        }
    }
}

struct NetworkHeader: Equatable {
    var destinationIP: String = ""
    var sourceIP: String = "192.168.1.42"
    
    var hasDestination: Bool {
        !destinationIP.isEmpty
    }
    
    var displayDestination: String {
        destinationIP.isEmpty ? "???.???.???.???" : destinationIP
    }
}

// MARK: - Player Packet State
struct PacketState: Equatable {
    var position: CGPoint = CGPoint(x: 100, y: 100)
    var targetPosition: CGPoint? = nil
    var layers: PacketLayers = PacketLayers()
    var mood: PacketMood = .neutral
    var isMoving: Bool = false
    var facingDirection: Direction = .right
    
    enum Direction {
        case up, down, left, right
    }
}

enum PacketMood: String {
    case neutral = "😊"
    case happy = "😄"
    case worried = "😰"
    case excited = "🤩"
    case confused = "🤔"
    case determined = "😤"
}

// MARK: - NPC Types
enum NPCType: String, Identifiable, CaseIterable {
    case daemon = "Daemon"
    case firewall = "Firewall Guard"
    case routerGuard = "Router Guard"
    case librarian = "DNS Librarian"
    case networkManager = "Network Manager"
    
    var id: String { rawValue }
    
    var description: String {
        switch self {
        case .daemon: return "Background process worker"
        case .firewall: return "Security checkpoint guard"
        case .routerGuard: return "Traffic direction officer"
        case .librarian: return "Domain name resolver"
        case .networkManager: return "System orchestrator"
        }
    }
    
    var icon: String {
        switch self {
        case .daemon: return "🤖"
        case .firewall: return "🛡️"
        case .routerGuard: return "👮"
        case .librarian: return "📚"
        case .networkManager: return "🎛️"
        }
    }
}

// MARK: - NPC
struct NPC: Identifiable, Equatable {
    let id = UUID()
    let type: NPCType
    var position: CGPoint
    var name: String
    var dialogue: [DialogueLine]
    var hasSpoken: Bool = false
    var isInteractable: Bool = true
    
    static func == (lhs: NPC, rhs: NPC) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Dialogue System
struct DialogueLine: Identifiable, Equatable {
    let id = UUID()
    let speaker: String
    let text: String
    let emotion: String?
    let learnedTerm: EncyclopediaTerm?
    let choices: [DialogueChoice]?
    
    init(speaker: String, text: String, emotion: String? = nil, learnedTerm: EncyclopediaTerm? = nil, choices: [DialogueChoice]? = nil) {
        self.speaker = speaker
        self.text = text
        self.emotion = emotion
        self.learnedTerm = learnedTerm
        self.choices = choices
    }
    
    static func == (lhs: DialogueLine, rhs: DialogueLine) -> Bool {
        lhs.id == rhs.id
    }
}

struct DialogueChoice: Identifiable, Equatable {
    let id = UUID()
    let text: String
    let nextDialogueIndex: Int?
    
    static func == (lhs: DialogueChoice, rhs: DialogueChoice) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Encyclopedia (Collected Journal)
struct EncyclopediaTerm: Identifiable, Equatable, Hashable {
    let id: String
    let term: String
    let definition: String
    let icon: String
    let category: TermCategory
    
    static func == (lhs: EncyclopediaTerm, rhs: EncyclopediaTerm) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    enum TermCategory: String, CaseIterable {
        case basics = "Basics"
        case protocols = "Protocols"
        case infrastructure = "Infrastructure"
        case security = "Security"
    }
}

// MARK: - Interactive Objects
struct InteractiveObject: Identifiable {
    let id = UUID()
    let type: ObjectType
    var position: CGPoint
    var isActive: Bool = true
    var data: String?
    
    enum ObjectType {
        case portal           // Move between scenes
        case terminal         // Info display
        case checkpoint       // Save progress
        case collectable      // Encyclopedia items
    }
}

// MARK: - Journey Stats
struct JourneyStats {
    var startTime: Date = Date()
    var termsLearned: [EncyclopediaTerm] = []
    var npcsSpokenTo: [String] = []
    var scenesVisited: [StoryScene] = []
    var choicesMade: [String] = []
    var missionComplete: Bool = false
    
    var duration: TimeInterval {
        Date().timeIntervalSince(startTime)
    }
    
    var formattedDuration: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - Pre-built Encyclopedia Terms
extension EncyclopediaTerm {
    static let allTerms: [EncyclopediaTerm] = [
        EncyclopediaTerm(
            id: "daemon",
            term: "Daemon",
            definition: "A background process that runs continuously, performing system tasks without direct user interaction. Like a helpful robot working behind the scenes.",
            icon: "🤖",
            category: .basics
        ),
        EncyclopediaTerm(
            id: "packet",
            term: "Packet",
            definition: "A small unit of data transmitted over a network. Think of it as a digital envelope containing your message and delivery information.",
            icon: "📦",
            category: .basics
        ),
        EncyclopediaTerm(
            id: "dns",
            term: "DNS",
            definition: "Domain Name System - the internet's phonebook. It translates human-friendly domain names (like google.com) into IP addresses computers understand.",
            icon: "📚",
            category: .infrastructure
        ),
        EncyclopediaTerm(
            id: "ip_address",
            term: "IP Address",
            definition: "A unique numerical label assigned to every device on a network. Like a street address for your computer.",
            icon: "🏠",
            category: .basics
        ),
        EncyclopediaTerm(
            id: "tcp",
            term: "TCP",
            definition: "Transmission Control Protocol - ensures reliable, ordered delivery of data. It checks if everything arrived correctly, like certified mail.",
            icon: "✅",
            category: .protocols
        ),
        EncyclopediaTerm(
            id: "udp",
            term: "UDP",
            definition: "User Datagram Protocol - fast but unreliable. Sends data without checking if it arrived. Great for live video, risky for important files.",
            icon: "⚡",
            category: .protocols
        ),
        EncyclopediaTerm(
            id: "router",
            term: "Router",
            definition: "A device that forwards data packets between networks. Like a traffic officer directing cars at an intersection.",
            icon: "🔀",
            category: .infrastructure
        ),
        EncyclopediaTerm(
            id: "firewall",
            term: "Firewall",
            definition: "A security system that monitors and controls incoming and outgoing network traffic. The bouncer at the club of your network.",
            icon: "🛡️",
            category: .security
        ),
        EncyclopediaTerm(
            id: "latency",
            term: "Latency",
            definition: "The time delay between sending a request and receiving a response. Lower latency = faster internet experience.",
            icon: "⏱️",
            category: .basics
        ),
        EncyclopediaTerm(
            id: "fiber_optic",
            term: "Fiber Optic Cable",
            definition: "Cables that transmit data as pulses of light through glass fibers. They run under oceans connecting continents!",
            icon: "🌊",
            category: .infrastructure
        ),
        EncyclopediaTerm(
            id: "header",
            term: "Packet Header",
            definition: "The metadata attached to a packet containing routing information - source, destination, and protocol details.",
            icon: "🎫",
            category: .basics
        ),
        EncyclopediaTerm(
            id: "payload",
            term: "Payload",
            definition: "The actual data being transmitted in a packet. Everything else (headers) is just packaging for this content.",
            icon: "📨",
            category: .basics
        )
    ]
    
    static func term(for id: String) -> EncyclopediaTerm? {
        allTerms.first { $0.id == id }
    }
}
