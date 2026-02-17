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
        case .frozenCafe: return Color(red: 0.04, green: 0.02, blue: 0.08)
        case .cpuCity: return Color(red: 0.04, green: 0.02, blue: 0.08)
        case .wifiAntenna: return Color(red: 0.03, green: 0.05, blue: 0.08)
        case .routerStation: return Color(red: 0.06, green: 0.04, blue: 0.08)
        case .oceanCable: return Color(red: 0.01, green: 0.03, blue: 0.10)
        case .dnsLibrary: return Color(red: 0.06, green: 0.02, blue: 0.10)
        case .returnJourney: return Color(red: 0.08, green: 0.03, blue: 0.05)
        case .feedLoaded: return Color(red: 0.04, green: 0.02, blue: 0.08)
        }
    }
    
    var accentColor: Color {
        switch self {
        case .frozenCafe: return .cyan
        case .cpuCity: return .cyan
        case .wifiAntenna: return Color(red: 0.4, green: 1.0, blue: 0.3)
        case .routerStation: return Color(red: 1.0, green: 0.75, blue: 0.0)
        case .oceanCable: return .cyan
        case .dnsLibrary: return Color(red: 0.6, green: 0.2, blue: 1.0)
        case .returnJourney: return Color(red: 1.0, green: 0.4, blue: 0.3)
        case .feedLoaded: return Color(red: 1.0, green: 0.1, blue: 0.6)
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
            definition: "A background process that runs continuously without user interaction. Your phone has hundreds of daemons managing Wi-Fi, Bluetooth, notifications, and more — all while you think you're the one in charge!",
            icon: "🤖",
            category: .basics
        ),
        EncyclopediaTerm(
            id: "packet",
            term: "Packet",
            definition: "A small unit of data transmitted over a network. When you send a photo, it gets chopped into thousands of tiny packets, each traveling independently, then reassembled at the destination. Like a jigsaw puzzle mailed in separate envelopes!",
            icon: "📦",
            category: .basics
        ),
        EncyclopediaTerm(
            id: "dns",
            term: "DNS",
            definition: "Domain Name System — the internet's phone book. When you type 'google.com', DNS translates that into a numeric IP address (like 142.250.185.78) that computers understand. Without DNS, you'd have to memorize numbers for every website!",
            icon: "📚",
            category: .infrastructure
        ),
        EncyclopediaTerm(
            id: "ip_address",
            term: "IP Address",
            definition: "A unique numerical label (like 192.168.1.42) assigned to every device on a network. IPv4 uses 4 numbers (0-255), giving about 4.3 billion combinations. We're running out, so IPv6 was invented with 340 undecillion addresses!",
            icon: "🏠",
            category: .basics
        ),
        EncyclopediaTerm(
            id: "tcp",
            term: "TCP",
            definition: "Transmission Control Protocol — the 'careful delivery' method. TCP numbers every packet, checks they all arrived, and requests re-sends for any lost. Like certified mail: slower, but nothing goes missing. Used for web pages, emails, and files.",
            icon: "✅",
            category: .protocols
        ),
        EncyclopediaTerm(
            id: "udp",
            term: "UDP",
            definition: "User Datagram Protocol — the 'fire and forget' method. UDP sends data without verifying arrival. Perfect for live video calls and gaming where speed matters more than perfection — a dropped frame is better than a frozen screen!",
            icon: "⚡",
            category: .protocols
        ),
        EncyclopediaTerm(
            id: "router",
            term: "Router",
            definition: "A device that reads packet addresses and forwards them toward their destination. Like an air-traffic controller managing millions of packets per second, choosing the fastest available path. Your home Wi-Fi box is a router too!",
            icon: "🔀",
            category: .infrastructure
        ),
        EncyclopediaTerm(
            id: "firewall",
            term: "Firewall",
            definition: "A security system that monitors all incoming and outgoing network traffic. Firewalls use rules to decide what's allowed — like a bouncer with a strict guest list. They protect against hackers, malware, and unauthorized access.",
            icon: "🛡️",
            category: .security
        ),
        EncyclopediaTerm(
            id: "latency",
            term: "Latency",
            definition: "The time delay between sending a request and receiving a response, measured in milliseconds. Every router hop, cable length, and processing step adds latency. A typical web request has 50-200ms of latency — faster than a human blink (300ms)!",
            icon: "⏱️",
            category: .basics
        ),
        EncyclopediaTerm(
            id: "fiber_optic",
            term: "Fiber Optic Cable",
            definition: "Cables that transmit data as pulses of LIGHT through thin glass fibers. Over 1.3 million km of submarine cables crisscross the ocean floor connecting continents. A single cable can carry 200+ terabits per second — enough to stream millions of videos at once!",
            icon: "🌊",
            category: .infrastructure
        ),
        EncyclopediaTerm(
            id: "header",
            term: "Packet Header",
            definition: "Metadata attached to every packet: source address, destination, protocol type, packet number, and error-checking data. Think of it as the shipping label on a package — without it, the packet would be lost!",
            icon: "🎫",
            category: .basics
        ),
        EncyclopediaTerm(
            id: "payload",
            term: "Payload",
            definition: "The actual data inside a packet — your message, image, or web request. Everything else (headers, checksums) is packaging. A packet's payload is typically 1,500 bytes or less, so large files get split across many packets.",
            icon: "📨",
            category: .basics
        )
    ]
    
    static func term(for id: String) -> EncyclopediaTerm? {
        allTerms.first { $0.id == id }
    }
}
