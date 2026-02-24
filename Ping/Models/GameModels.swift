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
    var securityLayer: SecurityProtocol = .none
    
    var isComplete: Bool {
        applicationLayer != .empty && networkLayer.hasDestination
    }
    
    var isSecure: Bool {
        securityLayer == .ssl
    }
}

enum SecurityProtocol: String, Equatable {
    case none = "None"
    case ssl  = "SSL/TLS"
    
    var description: String {
        switch self {
        case .none: return "Unencrypted — anyone can read your data"
        case .ssl:  return "Encrypted — data is scrambled and safe"
        }
    }
    
    var icon: String {
        switch self {
        case .none: return "lock.open"
        case .ssl:  return "lock.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .none: return .red
        case .ssl:  return .green
        }
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
    var layers: PacketLayers = PacketLayers()
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
        case .daemon: return "gearshape.2.fill"
        case .firewall: return "shield.checkered"
        case .routerGuard: return "network"
        case .librarian: return "server.rack"
        case .networkManager: return "slider.horizontal.3"
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
    let learnedTerm: EncyclopediaTerm?
    let choices: [DialogueChoice]?
    let action: ChoiceAction?    // Direct action triggered when this line displays (e.g. inventory swap)
    
    init(speaker: String, text: String, learnedTerm: EncyclopediaTerm? = nil, choices: [DialogueChoice]? = nil, action: ChoiceAction? = nil) {
        self.speaker = speaker
        self.text = text
        self.learnedTerm = learnedTerm
        self.choices = choices
        self.action = action
    }
    
    static func == (lhs: DialogueLine, rhs: DialogueLine) -> Bool {
        lhs.id == rhs.id
    }
}

struct DialogueChoice: Identifiable, Equatable {
    let id = UUID()
    let text: String
    let nextDialogueIndex: Int?
    let action: ChoiceAction?
    
    init(text: String, nextDialogueIndex: Int? = nil, action: ChoiceAction? = nil) {
        self.text = text
        self.nextDialogueIndex = nextDialogueIndex
        self.action = action
    }
    
    static func == (lhs: DialogueChoice, rhs: DialogueChoice) -> Bool {
        lhs.id == rhs.id
    }
}

/// Actions that dialogue choices can trigger on the game state.
enum ChoiceAction: Equatable {
    case setTransportProtocol(TransportProtocol)
    case setSecurityLayer(SecurityProtocol)
    case showInventorySwap            // Prompt user to tap the security layer in inventory
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
    var chosenProtocol: TransportProtocol = .tcp
    var upgradedToSSL: Bool = false
    var lostPacketData: Bool = false   // true if UDP caused data loss in ocean
    var quizResults: [QuizResult] = []
    
    var duration: TimeInterval {
        Date().timeIntervalSince(startTime)
    }
    
    var formattedDuration: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    var quizAccuracy: Double {
        guard !quizResults.isEmpty else { return 0 }
        let correct = quizResults.filter(\.wasCorrect).count
        return Double(correct) / Double(quizResults.count)
    }
}

// MARK: - Quiz System
struct QuizQuestion: Identifiable, Equatable {
    let id = UUID()
    let question: String
    let options: [String]
    let correctIndex: Int
    let explanation: String
    
    static func == (lhs: QuizQuestion, rhs: QuizQuestion) -> Bool {
        lhs.id == rhs.id
    }
}

struct QuizResult: Equatable {
    let scene: StoryScene
    let questionText: String
    let wasCorrect: Bool
    let selectedIndex: Int
    let correctIndex: Int
    let options: [String]
    let explanation: String
}

/// Pre-built quizzes for each level
struct LevelQuizzes {
    static func quiz(for scene: StoryScene) -> [QuizQuestion] {
        switch scene {
        case .cpuCity:
            return [
                QuizQuestion(
                    question: "What is a Daemon?",
                    options: [
                        "A type of virus",
                        "A background process that runs continuously",
                        "A firewall program",
                        "A network cable"
                    ],
                    correctIndex: 1,
                    explanation: "Daemons are background processes that keep your device running — managing Wi-Fi, notifications, and more!"
                ),
                QuizQuestion(
                    question: "What does the Application Layer carry?",
                    options: [
                        "The IP address",
                        "The encryption key",
                        "The actual data / payload",
                        "The transport protocol"
                    ],
                    correctIndex: 2,
                    explanation: "The Application Layer holds the payload — the actual data you want to send, like 'GET socialmedia.com'."
                )
            ]
        case .wifiAntenna:
            return [
                QuizQuestion(
                    question: "What does a Firewall do?",
                    options: [
                        "Speeds up your internet",
                        "Translates domain names to IPs",
                        "Filters incoming and outgoing network traffic",
                        "Stores your passwords"
                    ],
                    correctIndex: 2,
                    explanation: "A Firewall inspects every packet entering or leaving your device and blocks suspicious traffic."
                ),
                QuizQuestion(
                    question: "Why is SSL/TLS encryption important?",
                    options: [
                        "It makes your internet faster",
                        "It scrambles data so only the destination can read it",
                        "It compresses files to save space",
                        "It blocks advertisements"
                    ],
                    correctIndex: 1,
                    explanation: "SSL/TLS encrypts your data during transit so hackers and eavesdroppers can only see gibberish!"
                )
            ]
        case .routerStation:
            return [
                QuizQuestion(
                    question: "What does a Router do?",
                    options: [
                        "Stores website data",
                        "Reads the destination header and forwards packets to the next hop",
                        "Encrypts your data",
                        "Runs background processes"
                    ],
                    correctIndex: 1,
                    explanation: "Routers read the Network Layer header and decide the best path to forward each packet."
                ),
                QuizQuestion(
                    question: "What is the key difference between TCP and UDP?",
                    options: [
                        "TCP is wireless, UDP uses cables",
                        "TCP checks every packet arrived; UDP sends without confirming",
                        "UDP is more secure than TCP",
                        "There is no difference"
                    ],
                    correctIndex: 1,
                    explanation: "TCP guarantees delivery by checking and resending lost packets. UDP is faster but doesn't confirm — lost data is gone forever."
                )
            ]
        case .oceanCable:
            return [
                QuizQuestion(
                    question: "How much of the world's internet traffic travels through undersea fiber optic cables?",
                    options: [
                        "About 25%",
                        "About 50%",
                        "About 75%",
                        "Over 95%"
                    ],
                    correctIndex: 3,
                    explanation: "Over 95% of intercontinental data travels through undersea cables — thousands of miles of glass fiber on the ocean floor!"
                )
            ]
        case .dnsLibrary:
            return [
                QuizQuestion(
                    question: "What does DNS stand for?",
                    options: [
                        "Digital Network Service",
                        "Domain Name System",
                        "Data Node Server",
                        "Dynamic Name Security"
                    ],
                    correctIndex: 1,
                    explanation: "DNS = Domain Name System. It's the internet's phone book — translating human-readable names like 'google.com' into IP addresses."
                ),
                QuizQuestion(
                    question: "What is an IP address?",
                    options: [
                        "A website's password",
                        "A unique numerical address computers use to find each other",
                        "The speed of your internet connection",
                        "A type of encryption"
                    ],
                    correctIndex: 1,
                    explanation: "An IP address (like 142.250.185.78) is a unique number that identifies every device on a network — like a street address for computers."
                )
            ]
        default:
            return []
        }
    }
}

// MARK: - Pre-built Encyclopedia Terms
extension EncyclopediaTerm {
    static let allTerms: [EncyclopediaTerm] = [
        EncyclopediaTerm(
            id: "daemon",
            term: "Daemon",
            definition: "A background process that runs continuously without user interaction. Your phone has hundreds of daemons managing Wi-Fi, Bluetooth, notifications, and more.",
            icon: "gearshape.2.fill",
            category: .basics
        ),
        EncyclopediaTerm(
            id: "packet",
            term: "Packet",
            definition: "A small unit of data transmitted over a network. When you send a photo, it gets chopped into thousands of tiny packets, each traveling independently, then reassembled at the destination.",
            icon: "shippingbox.fill",
            category: .basics
        ),
        EncyclopediaTerm(
            id: "dns",
            term: "DNS",
            definition: "Domain Name System — the internet's address book. When you type 'google.com', DNS translates that into a numeric IP address (like 142.250.185.78) that computers understand.",
            icon: "book.closed.fill",
            category: .infrastructure
        ),
        EncyclopediaTerm(
            id: "ip_address",
            term: "IP Address",
            definition: "A unique numerical label (like 192.168.1.42) assigned to every device on a network. IPv4 uses 4 numbers (0-255), giving about 4.3 billion combinations. IPv6 was invented with 340 undecillion addresses.",
            icon: "number.circle.fill",
            category: .basics
        ),
        EncyclopediaTerm(
            id: "tcp",
            term: "TCP",
            definition: "Transmission Control Protocol — the reliable delivery method. TCP numbers every packet, checks they all arrived, and requests re-sends for any lost. Used for web pages, emails, and files.",
            icon: "checkmark.circle.fill",
            category: .protocols
        ),
        EncyclopediaTerm(
            id: "udp",
            term: "UDP",
            definition: "User Datagram Protocol — the fast delivery method. UDP sends data without verifying arrival. Perfect for live video calls and gaming where speed matters more than perfection.",
            icon: "bolt.circle.fill",
            category: .protocols
        ),
        EncyclopediaTerm(
            id: "router",
            term: "Router",
            definition: "A device that reads packet addresses and forwards them toward their destination. Like an air-traffic controller managing millions of packets per second, choosing the fastest available path.",
            icon: "arrow.triangle.branch",
            category: .infrastructure
        ),
        EncyclopediaTerm(
            id: "firewall",
            term: "Firewall",
            definition: "A security system that monitors all incoming and outgoing network traffic. Firewalls use rules to decide what's allowed — protecting against hackers, malware, and unauthorized access.",
            icon: "shield.checkered",
            category: .security
        ),
        EncyclopediaTerm(
            id: "latency",
            term: "Latency",
            definition: "The time delay between sending a request and receiving a response, measured in milliseconds. Every router hop, cable length, and processing step adds latency. A typical web request has 50-200ms of latency.",
            icon: "clock.arrow.circlepath",
            category: .basics
        ),
        EncyclopediaTerm(
            id: "fiber_optic",
            term: "Fiber Optic Cable",
            definition: "Cables that transmit data as pulses of light through thin glass fibers. Over 1.3 million km of submarine cables crisscross the ocean floor. A single cable can carry 200+ terabits per second.",
            icon: "cable.connector.horizontal",
            category: .infrastructure
        ),
        EncyclopediaTerm(
            id: "header",
            term: "Packet Header",
            definition: "Metadata attached to every packet: source address, destination, protocol type, packet number, and error-checking data. Without it, the packet would be lost.",
            icon: "tag.fill",
            category: .basics
        ),
        EncyclopediaTerm(
            id: "payload",
            term: "Payload",
            definition: "The actual data inside a packet — your message, image, or web request. Everything else (headers, checksums) is packaging. A packet's payload is typically 1,500 bytes or less.",
            icon: "doc.fill",
            category: .basics
        ),
        EncyclopediaTerm(
            id: "https",
            term: "HTTPS / SSL",
            definition: "HTTPS (HyperText Transfer Protocol Secure) uses SSL/TLS encryption to scramble data so only the sender and receiver can read it. Without it, anyone between you and the server could read your data.",
            icon: "lock.fill",
            category: .security
        ),
        EncyclopediaTerm(
            id: "encryption",
            term: "Encryption",
            definition: "The process of converting readable data into scrambled code that only authorized parties can decode. Modern encryption (AES-256) would take a supercomputer billions of years to crack by brute force.",
            icon: "key.fill",
            category: .security
        )
    ]
    
    static func term(for id: String) -> EncyclopediaTerm? {
        allTerms.first { $0.id == id }
    }
}
