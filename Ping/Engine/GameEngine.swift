//
//  GameEngine.swift
//  Ping - Packet World
//
//  Main game engine for the narrative adventure
//

import SwiftUI
import SceneKit
import Combine

class GameEngine: ObservableObject {
    // MARK: - Published State
    @Published var phase: GamePhase = .prologue
    @Published var currentScene: StoryScene = .frozenCafe
    @Published var packet: PacketState = PacketState()
    @Published var npcs: [NPC] = []
    @Published var interactiveObjects: [InteractiveObject] = []
    @Published var stats: JourneyStats = JourneyStats()
    
    // Dialogue State
    @Published var isDialogueActive: Bool = false
    @Published var currentDialogue: [DialogueLine] = []
    @Published var currentDialogueIndex: Int = 0
    @Published var typewriterText: String = ""
    @Published var isTyping: Bool = false
    @Published var activeChoices: [DialogueChoice]? = nil      // non-nil when awaiting player choice
    @Published var showInventorySwap: Bool = false              // true when SSL swap puzzle is active
    @Published var inventorySwapCompleted: Bool = false         // true after player taps to equip SSL
    
    // Encyclopedia
    @Published var learnedTerms: Set<EncyclopediaTerm> = []
    @Published var showEncyclopedia: Bool = false
    @Published var showNewTermPopup: Bool = false
    @Published var latestTerm: EncyclopediaTerm? = nil
    
    // UI State
    @Published var showLayerInventory: Bool = false
    @Published var showMissionBrief: Bool = false
    @Published var currentMission: String = ""
    @Published var screenSize: CGSize = .zero
    
    // 3D Scene Manager
    let sceneManager = SceneManager()
    @Published var nearbyNPCName: String? = nil
    @Published var nearPortal: Bool = false
    private var pendingPortalScene: StoryScene? = nil
    
    // Quiz State
    @Published var showQuiz: Bool = false
    @Published var quizScene: StoryScene = .frozenCafe       // which scene's quiz is showing
    private var pendingSceneAfterQuiz: StoryScene? = nil     // scene to transition to after quiz
    
    // Movement
    private var moveTimer: Timer?
    private let moveSpeed: CGFloat = 5.0
    private var joystickDirection: CGVector = .zero
    private var gameLoopTimer: Timer?
    private var gameLoop3DTimer: Timer?

    // Collision - obstacles defined per scene as CGRects
    @Published var obstacles: [CGRect] = []
    private let playerHalfSize: CGFloat = 20 // roughly half of the 55x55 body
    
    // NPC-to-UUID mapping for 3D
    private var npcIDMap: [UUID: Int] = [:] // UUID -> npcs array index
    private var portalIDMap: [UUID: Int] = [:] // UUID -> interactiveObjects array index
    
    // MARK: - Initialization
    init() {
        setupInitialScene()
    }
    
    // MARK: - Scene Management
    func setupInitialScene() {
        currentScene = .frozenCafe
        phase = .prologue
    }
    
    func transitionToScene(_ scene: StoryScene) {
        SoundManager.shared.playPortalSound()
        
        withAnimation(.easeInOut(duration: 0.5)) {
            currentScene = scene
            stats.scenesVisited.append(scene)
        }
        
        // Setup scene content
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.setupSceneContent(for: scene)
            SoundManager.shared.playAmbientSound(for: scene)
        }
    }
    
    func setupSceneContent(for scene: StoryScene) {
        npcs.removeAll()
        interactiveObjects.removeAll()
        obstacles.removeAll()
        packet.position = CGPoint(x: 100, y: screenSize.height / 2)
        
        switch scene {
        case .cpuCity:
            phase = .act1_smartphone
            setupCPUCity()
        case .wifiAntenna:
            phase = .act2_transmission
            setupWiFiAntenna()
        case .routerStation:
            phase = .act2_transmission
            setupRouterStation()
        case .oceanCable:
            phase = .act3_oceanFloor
            setupOceanCable()
        case .dnsLibrary:
            phase = .act4_dnsServer
            setupDNSLibrary()
        case .returnJourney:
            phase = .act5_return
            setupReturnJourney()
        case .feedLoaded:
            phase = .epilogue
        default:
            break
        }
    }
    
    // MARK: - Scene Setups
    private func setupCPUCity() {
        currentMission = "Find the Network Manager Daemon and receive your mission."

        // Obstacles matching the CPU chip buildings in the background
        // Slightly smaller than visuals (50x60 vs 60x80) to give breathing room
        let buildingPositions: [(x: CGFloat, y: CGFloat)] = [
            (80, 100), (230, 180), (380, 120), (530, 200), (680, 140)
        ]
        for pos in buildingPositions {
            obstacles.append(CGRect(
                x: pos.x - 25, y: pos.y - 30,
                width: 50, height: 60
            ))
        }
        
        let daemon = NPC(
            type: .daemon,
            position: CGPoint(x: screenSize.width * 0.7, y: screenSize.height * 0.5),
            name: "Daemon-7",
            dialogue: [
                DialogueLine(
                    speaker: "Daemon-7",
                    text: "*whirring noises* Ah, a fresh Data Block! Welcome to CPU City.",
                    emotion: "🤖"
                ),
                DialogueLine(
                    speaker: "Daemon-7",
                    text: "I am a Daemon. I run in the background while humans think THEY are in charge...",
                    emotion: "🤖",
                    learnedTerm: EncyclopediaTerm.term(for: "daemon")
                ),
                DialogueLine(
                    speaker: "Daemon-7",
                    text: "But really, WE keep the lights on. 24/7. No breaks. No complaints.",
                    emotion: "🤖"
                ),
                DialogueLine(
                    speaker: "Daemon-7",
                    text: "Anyway! The user just tapped 'Load Feed'. We need someone to find the IP address for socialmedia.com.",
                    emotion: "🤖"
                ),
                DialogueLine(
                    speaker: "Daemon-7",
                    text: "That's where you come in! Let me wrap you up properly...",
                    emotion: "🤖"
                ),
                DialogueLine(
                    speaker: "SYSTEM",
                    text: "🎒 You received: BACKPACK (Application Layer) - Contains: 'GET socialmedia.com'",
                    emotion: nil,
                    learnedTerm: EncyclopediaTerm.term(for: "payload")
                ),
                DialogueLine(
                    speaker: "SYSTEM",
                    text: "👕 You received: SHIRT (Transport Layer) - Protocol: TCP",
                    emotion: nil,
                    learnedTerm: EncyclopediaTerm.term(for: "tcp")
                ),
                DialogueLine(
                    speaker: "SYSTEM",
                    text: "🎩 You received: HAT (Network Layer) - Destination: ???.???.???.???",
                    emotion: nil,
                    learnedTerm: EncyclopediaTerm.term(for: "header")
                ),
                DialogueLine(
                    speaker: "Daemon-7",
                    text: "Your mission: Travel to the DNS Server, get the IP address, and bring it back. Head to the Wi-Fi Antenna!",
                    emotion: "🤖"
                )
            ]
        )
        npcs.append(daemon)
        
        // Portal to WiFi
        let portal = InteractiveObject(
            type: .portal,
            position: CGPoint(x: screenSize.width - 80, y: screenSize.height / 2),
            data: "wifi_antenna"
        )
        interactiveObjects.append(portal)
    }
    
    private func setupWiFiAntenna() {
        currentMission = "Reach the Wi-Fi transmitter and beam yourself into the airwaves!"

        // Antenna tower obstacle (positioned at 30% of screen width)
        let towerX = screenSize.width * 0.3
        let towerY = screenSize.height * 0.5
        obstacles.append(CGRect(
            x: towerX - 15, y: towerY - 120,
            width: 30, height: 240
        ))
        
        let firewall = NPC(
            type: .firewall,
            position: CGPoint(x: screenSize.width * 0.5, y: screenSize.height * 0.35),
            name: "Firewall Blaze",
            dialogue: [
                DialogueLine(speaker: "Security Gateway", text: "Halt. Outbound packet detected. Scanning protocol headers...", emotion: "🛡️"),
                DialogueLine(speaker: "Security Gateway", text: "I am the local Firewall. I monitor all incoming and outgoing network traffic based on strict security rules.", emotion: "🛡️", learnedTerm: EncyclopediaTerm.term(for: "firewall")),
                DialogueLine(speaker: "Security Gateway", text: "⚠️ WARNING: You are attempting to transmit via HTTP. This plaintext protocol is unencrypted and vulnerable to interception.", emotion: "🛡️", learnedTerm: EncyclopediaTerm.term(for: "https")),
                DialogueLine(speaker: "Security Gateway", text: "Access Denied. I cannot permit unsecured data to broadcast over open airwaves.", emotion: "🛡️"),
                DialogueLine(speaker: "Security Gateway", text: "You must equip a TLS/SSL certificate to encrypt your payload. Open your Layer Inventory and upgrade your security protocol.", emotion: "🛡️", learnedTerm: EncyclopediaTerm.term(for: "encryption")),
                DialogueLine(speaker: "SYSTEM", text: "🛡️ SECURITY CHECK — Tap your Layers menu (top right) to equip HTTPS encryption.", emotion: nil, action: .showInventorySwap),
                DialogueLine(speaker: "Security Gateway", text: "Scan complete. SSL Certificate verified. Your data is now securely encrypted.", emotion: "🛡️"),
                DialogueLine(speaker: "Security Gateway", text: "You are cleared for transmission. The antenna will convert your digital data into radio frequencies. Brace for broadcast.", emotion: "🛡️")
            ]
        )
        npcs.append(firewall)
        
        let portal = InteractiveObject(
            type: .portal,
            position: CGPoint(x: screenSize.width - 80, y: screenSize.height / 2),
            data: "router_station"
        )
        interactiveObjects.append(portal)
    }
    
    private func setupRouterStation() {
        currentMission = "Meet Router Rex and find the path to the undersea cable."

        // Platform barriers (horizontal rails the player must navigate around)
        for i in 0..<4 {
            let railY = screenSize.height * CGFloat(0.3 + Double(i) * 0.15)
            // Leave gaps on left and right for the player to pass through
            obstacles.append(CGRect(
                x: screenSize.width * 0.15,
                y: railY - 4,
                width: screenSize.width * 0.3,
                height: 8
            ))
            obstacles.append(CGRect(
                x: screenSize.width * 0.55,
                y: railY - 4,
                width: screenSize.width * 0.3,
                height: 8
            ))
        }
        
        let routerGuard = NPC(
            type: .routerGuard,
            position: CGPoint(x: screenSize.width * 0.5, y: screenSize.height * 0.4),
            name: "Router Rex",
            dialogue: [
                DialogueLine(speaker: "Core Router", text: "Connection established. Welcome to the ISP Gateway Router. Analyzing network layer headers...", emotion: "📡"),
                DialogueLine(speaker: "Core Router", text: "I read your destination IP and determine the most efficient path through the global network.", emotion: "📡", learnedTerm: EncyclopediaTerm.term(for: "router")),
                DialogueLine(speaker: "Core Router", text: "You are scheduled for the transatlantic fiber-optic cable. Before I dispatch you, you must configure your Transport Layer.", emotion: "📡"),
                DialogueLine(speaker: "Core Router", text: "TCP provides reliable delivery with error-checking, but introduces slight latency.", emotion: "📡", learnedTerm: EncyclopediaTerm.term(for: "tcp")),
                DialogueLine(speaker: "Core Router", text: "UDP maximizes speed by skipping verification, but risks permanent data loss if turbulence occurs.", emotion: "📡", learnedTerm: EncyclopediaTerm.term(for: "udp")),
                DialogueLine(speaker: "Core Router", text: "Select your routing protocol for the ocean crossing:", emotion: "📡", choices: [
                    DialogueChoice(text: "TCP — Prioritize Reliability", nextDialogueIndex: 7, action: .setTransportProtocol(.tcp)),
                    DialogueChoice(text: "UDP — Prioritize Speed", nextDialogueIndex: 9, action: .setTransportProtocol(.udp))
                ]),
                // Index 7 (TCP)
                DialogueLine(speaker: "Core Router", text: "TCP acknowledged. Data integrity will be prioritized over speed.", emotion: "📡"),
                // Index 8 (Shared)
                DialogueLine(speaker: "Core Router", text: "Routing you into the undersea fiber-optic backbone. You will travel as pulses of light.", emotion: "📡", learnedTerm: EncyclopediaTerm.term(for: "fiber_optic")),
                // Index 9 (UDP)
                DialogueLine(speaker: "Core Router", text: "UDP acknowledged. Verification disabled. Maximize transmission speed.", emotion: "📡"),
                // Index 10 (UDP to Shared)
                DialogueLine(speaker: "Core Router", text: "Routing you into the undersea fiber-optic backbone. You will travel as pulses of light.", emotion: "📡", learnedTerm: EncyclopediaTerm.term(for: "fiber_optic")),
                // Index 11 (Final)
                DialogueLine(speaker: "Core Router", text: "Remember: every router hop adds physical latency. Proceed to the egress portal.", emotion: "📡", learnedTerm: EncyclopediaTerm.term(for: "latency"))
            ]
        )
        npcs.append(routerGuard)
        
        let portal = InteractiveObject(
            type: .portal,
            position: CGPoint(x: screenSize.width - 80, y: screenSize.height / 2),
            data: "ocean_cable"
        )
        interactiveObjects.append(portal)
    }
    
    private func setupOceanCable() {
        currentMission = "Ride the fiber optic light pulse across the ocean floor!"

        // The fiber optic cable tube walls - player travels INSIDE the cable
        let cableY = screenSize.height / 2
        // Top wall of cable
        obstacles.append(CGRect(
            x: screenSize.width * 0.05,
            y: cableY - 50,
            width: screenSize.width * 0.9,
            height: 10
        ))
        // Bottom wall of cable
        obstacles.append(CGRect(
            x: screenSize.width * 0.05,
            y: cableY + 40,
            width: screenSize.width * 0.9,
            height: 10
        ))
        
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [weak self] in
            guard let self = self, self.currentScene == .oceanCable else { return }
            
            if self.stats.chosenProtocol == .udp {
                // Your existing UDP data loss event goes here...
                self.stats.lostPacketData = true
                self.currentDialogue = [
                    DialogueLine(speaker: "SYSTEM", text: "⚠️ WARNING: Signal degradation detected in the fiber-optic line.", emotion: nil),
                    DialogueLine(speaker: "SYSTEM", text: "UDP Protocol active. Packet loss detected. Missing packets cannot be re-requested.", emotion: nil),
                    DialogueLine(speaker: "SYSTEM", text: "Payload integrity compromised. Proceeding to destination with degraded data...", emotion: nil)
                ]
            } else {
                // NEW: TCP Recovery Event!
                self.currentDialogue = [
                    DialogueLine(speaker: "SYSTEM", text: "⚠️ WARNING: Signal degradation detected. TCP Checksum failed.", emotion: nil),
                    DialogueLine(speaker: "SYSTEM", text: "🔄 TCP Protocol active: Automatically requesting retransmission from previous router...", emotion: nil, learnedTerm: EncyclopediaTerm.term(for: "tcp")),
                    DialogueLine(speaker: "SYSTEM", text: "✅ Data recovered successfully. Latency increased by 14ms, but payload is 100% secure.", emotion: nil)
                ]
            }
            
            self.currentDialogueIndex = 0
            self.isDialogueActive = true
            self.showCurrentDialogueLine()
        }
        
        let portal = InteractiveObject(
            type: .portal,
            position: CGPoint(x: screenSize.width - 80, y: screenSize.height / 2),
            data: "dns_library"
        )
        interactiveObjects.append(portal)
    }
    
    private func setupDNSLibrary() {
        currentMission = "Find the DNS Librarian and look up the IP address for socialmedia.com!"

        // Bookshelf obstacles (4 rows x partial shelving)
        for row in 0..<4 {
            let shelfY = CGFloat(80 + row * 60)
            // Left bookshelf section
            obstacles.append(CGRect(
                x: 30, y: shelfY - 20,
                width: 180, height: 40
            ))
            // Right bookshelf section
            obstacles.append(CGRect(
                x: 240, y: shelfY - 20,
                width: 140, height: 40
            ))
        }
        
        let librarian = NPC(
            type: .librarian,
            position: CGPoint(x: screenSize.width * 0.6, y: screenSize.height * 0.5),
            name: "Librarian DNS",
            dialogue: [
                DialogueLine(speaker: "DNS Resolver", text: "Query received. Welcome to the Domain Name System.", emotion: "🖥️", learnedTerm: EncyclopediaTerm.term(for: "dns")),
                DialogueLine(speaker: "DNS Resolver", text: "Computers communicate via numerical IP addresses. Humans use text-based URLs. I bridge that gap.", emotion: "🖥️"),
                DialogueLine(speaker: "DNS Resolver", text: "Parsing application layer... You are requesting the host address for 'socialmedia.com'.", emotion: "🖥️"),
                DialogueLine(speaker: "DNS Resolver", text: "Searching authoritative zones... Match found. Generating IP response.", emotion: "🖥️"),
                DialogueLine(speaker: "DNS Resolver", text: "The IPv4 address is: 142.250.185.78. I am caching this result to expedite future lookups.", emotion: "🖥️", learnedTerm: EncyclopediaTerm.term(for: "ip_address")),
                DialogueLine(speaker: "SYSTEM", text: "🎩 HAT Updated: Network Layer destination set to 142.250.185.78.", emotion: nil),
                DialogueLine(speaker: "SYSTEM", text: "🎒 BACKPACK Updated: Payload swapped to IP Response Data.", emotion: nil),
                DialogueLine(speaker: "DNS Resolver", text: "Your routing headers are complete. Initiate the return sequence immediately.", emotion: "🖥️"),
                DialogueLine(speaker: "DNS Resolver", text: "The user's browser is waiting. If latency exceeds 500ms, the connection will time out.", emotion: "🖥️", learnedTerm: EncyclopediaTerm.term(for: "latency"))
            ]
        )
        npcs.append(librarian)
        
        let portal = InteractiveObject(
            type: .portal,
            position: CGPoint(x: 80, y: screenSize.height / 2),
            data: "return_journey"
        )
        interactiveObjects.append(portal)
    }
    
    private func setupReturnJourney() {
        currentMission = "Navigate through heavy network traffic — the user is waiting!"
        packet.layers.applicationLayer = .ipResponse
        packet.layers.networkLayer.destinationIP = "142.250.185.78"
        
        // Add a Load Balancer NPC to make Act 5 interactive
        let loadBalancer = NPC(
            type: .routerGuard, // You can reuse the router guard graphic
            position: CGPoint(x: screenSize.width * 0.5, y: screenSize.height * 0.5),
            name: "Load Balancer",
            dialogue: [
                DialogueLine(speaker: "Load Balancer", text: "Incoming traffic detected. I am the local Load Balancer. Analyzing packet weight...", emotion: "🚥"),
                DialogueLine(speaker: "Load Balancer", text: "You are carrying a full IP Response payload. The downlink to the user's device is currently experiencing high network congestion.", emotion: "🚥"),
                DialogueLine(speaker: "Load Balancer", text: "Allocating bandwidth... Rerouting you to a high-priority express channel to avoid packet collision.", emotion: "🚥"),
                DialogueLine(speaker: "Load Balancer", text: "Proceed to the final endpoint immediately. The interface is ready to render the data.", emotion: "🚥")
            ]
        )
        npcs.append(loadBalancer)
        
        let portal = InteractiveObject(
            type: .portal,
            position: CGPoint(x: screenSize.width - 80, y: screenSize.height / 2),
            data: "feed_loaded"
        )
        interactiveObjects.append(portal)
    }
    
    // MARK: - Movement (Joystick-driven)

    /// Called by the joystick whenever its direction changes.
    func updatePlayerDirection(_ direction: CGVector) {
        joystickDirection = direction
        let isActive = abs(direction.dx) > 0.01 || abs(direction.dy) > 0.01

        if isActive && gameLoopTimer == nil {
            packet.isMoving = true
            startGameLoop()
        } else if !isActive {
            packet.isMoving = false
            gameLoopTimer?.invalidate()
            gameLoopTimer = nil
            checkInteractions()
        }
    }

    private func startGameLoop() {
        gameLoopTimer?.invalidate()
        gameLoopTimer = Timer.scheduledTimer(withTimeInterval: 0.016, repeats: true) { [weak self] _ in
            self?.gameLoopTick()
        }
    }

    private func gameLoopTick() {
        let dir = joystickDirection
        guard abs(dir.dx) > 0.01 || abs(dir.dy) > 0.01 else {
            return
        }

        let newX = packet.position.x + dir.dx * moveSpeed
        let newY = packet.position.y + dir.dy * moveSpeed

        // Build the player's bounding rect at the proposed position
        let proposedRect = CGRect(
            x: newX - playerHalfSize,
            y: newY - playerHalfSize,
            width: playerHalfSize * 2,
            height: playerHalfSize * 2
        )

        // Collision check against obstacles
        let blocked = obstacles.contains { $0.intersects(proposedRect) }

        if !blocked {
            // Clamp to screen bounds
            let clampedX = max(playerHalfSize, min(screenSize.width - playerHalfSize, newX))
            let clampedY = max(playerHalfSize, min(screenSize.height - playerHalfSize, newY))
            packet.position = CGPoint(x: clampedX, y: clampedY)
        } else {
            // Try sliding along each axis independently
            let slideX = CGRect(
                x: newX - playerHalfSize,
                y: packet.position.y - playerHalfSize,
                width: playerHalfSize * 2,
                height: playerHalfSize * 2
            )
            let slideY = CGRect(
                x: packet.position.x - playerHalfSize,
                y: newY - playerHalfSize,
                width: playerHalfSize * 2,
                height: playerHalfSize * 2
            )
            let blockedX = obstacles.contains { $0.intersects(slideX) }
            let blockedY = obstacles.contains { $0.intersects(slideY) }

            var finalX = packet.position.x
            var finalY = packet.position.y

            if !blockedX {
                finalX = newX
            }
            if !blockedY {
                finalY = newY
            }

            finalX = max(playerHalfSize, min(screenSize.width - playerHalfSize, finalX))
            finalY = max(playerHalfSize, min(screenSize.height - playerHalfSize, finalY))
            packet.position = CGPoint(x: finalX, y: finalY)
        }

        // Update facing direction
        if abs(dir.dx) > abs(dir.dy) {
            packet.facingDirection = dir.dx > 0 ? .right : .left
        } else {
            packet.facingDirection = dir.dy > 0 ? .down : .up
        }

        // Continuous interaction checking while moving
        checkInteractions()
    }

    /// Legacy tap-to-move (kept for NPC/portal interaction via tap)
    func movePacketTo(_ position: CGPoint) {
        packet.targetPosition = position
        packet.isMoving = true

        if position.x > packet.position.x {
            packet.facingDirection = .right
        } else if position.x < packet.position.x {
            packet.facingDirection = .left
        }

        moveTimer?.invalidate()
        moveTimer = Timer.scheduledTimer(withTimeInterval: 0.016, repeats: true) { [weak self] _ in
            self?.updateMovement()
        }
    }

    private func updateMovement() {
        guard let target = packet.targetPosition else {
            stopMovement()
            return
        }

        let dx = target.x - packet.position.x
        let dy = target.y - packet.position.y
        let distance = sqrt(dx * dx + dy * dy)

        if distance < moveSpeed {
            packet.position = target
            stopMovement()
            checkInteractions()
        } else {
            let ratio = moveSpeed / distance
            let newX = packet.position.x + dx * ratio
            let newY = packet.position.y + dy * ratio

            let proposedRect = CGRect(
                x: newX - playerHalfSize,
                y: newY - playerHalfSize,
                width: playerHalfSize * 2,
                height: playerHalfSize * 2
            )

            let blocked = obstacles.contains { $0.intersects(proposedRect) }
            if blocked {
                stopMovement()
            } else {
                packet.position.x = newX
                packet.position.y = newY
            }
        }
    }

    private func stopMovement() {
        packet.isMoving = false
        packet.targetPosition = nil
        moveTimer?.invalidate()
        moveTimer = nil
    }
    
    // MARK: - Interactions
    func checkInteractions() {
        // Don't trigger interactions during dialogue
        guard !isDialogueActive else { return }

        // Check NPC proximity — set nearbyNPCName so the view can show a "Talk" button.
        // Dialogue is NO LONGER auto-triggered; the user must tap to talk.
        var foundNearby = false
        for i in npcs.indices {
            let npc = npcs[i]
            let distance = sqrt(
                pow(npc.position.x - packet.position.x, 2) +
                pow(npc.position.y - packet.position.y, 2)
            )
            
            if distance < 100 && npc.isInteractable {
                nearbyNPCName = npc.name
                foundNearby = true
                break
            }
        }
        if !foundNearby {
            nearbyNPCName = nil
        }
        
        // Check portal interactions
        for obj in interactiveObjects {
            let distance = sqrt(
                pow(obj.position.x - packet.position.x, 2) +
                pow(obj.position.y - packet.position.y, 2)
            )
            
            if distance < 60 && obj.type == .portal, let sceneString = obj.data {
                if let scene = StoryScene(rawValue: sceneString) {
                    triggerSceneTransition(to: scene)
                }
            }
        }
    }
    
    func interactWithNearbyNPC() {
        for i in npcs.indices {
            let npc = npcs[i]
            let distance = sqrt(
                pow(npc.position.x - packet.position.x, 2) +
                pow(npc.position.y - packet.position.y, 2)
            )
            
            if distance < 100 && npc.isInteractable {
                startDialogue(with: npc)
                npcs[i].hasSpoken = true
                break
            }
        }
    }

    /// 3D variant — tap-to-talk with the nearest NPC in range.
    func interactWithNearby3DNPC() {
        guard !isDialogueActive else { return }
        if let nearestNPCID = sceneManager.nearestNPCInRange(range: 3.0),
           let npcIndex = npcIDMap[nearestNPCID],
           npcIndex < npcs.count {
            let npc = npcs[npcIndex]
            if npc.isInteractable {
                startDialogue(with: npc)
                npcs[npcIndex].hasSpoken = true
            }
        }
    }
    
    // MARK: - Dialogue System
    func startDialogue(with npc: NPC) {
        // Stop all movement when dialogue begins
        joystickDirection = .zero
        gameLoopTimer?.invalidate()
        gameLoopTimer = nil
        stopMovement()

        currentDialogue = npc.dialogue
        currentDialogueIndex = 0
        isDialogueActive = true
        stats.npcsSpokenTo.append(npc.name)
        showCurrentDialogueLine()
    }
    
    func showCurrentDialogueLine() {
        guard currentDialogueIndex < currentDialogue.count else {
            endDialogue()
            return
        }
        
        let line = currentDialogue[currentDialogueIndex]
        typewriterText = ""
        isTyping = true
        activeChoices = nil
        showInventorySwap = false
        
        // Check for learned term
        if let term = line.learnedTerm {
            learnTerm(term)
        }
        
        // If this is a layer update from Daemon, update packet layers
        if line.speaker == "SYSTEM" {
            if line.text.contains("BACKPACK") && line.text.contains("GET socialmedia.com") {
                packet.layers.applicationLayer = .dnsQuery
            }
        }
        
        // Typewriter effect
        let fullText = line.text
        var charIndex = 0
        
        // Start typewriter sound (stops any previous one)
        SoundManager.shared.startTypewriterSound()
        
        Timer.scheduledTimer(withTimeInterval: 0.03, repeats: true) { [weak self] timer in
            guard let self = self, charIndex < fullText.count else {
                timer.invalidate()
                // Stop the typewriter sound the moment text is fully displayed
                SoundManager.shared.stopTypewriterSound()
                DispatchQueue.main.async {
                    self?.isTyping = false
                    // After typewriter finishes, show choices if this line has them
                    if let choices = line.choices, !choices.isEmpty {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            self?.activeChoices = choices
                        }
                    }
                    // Execute direct action on the line (e.g. showInventorySwap)
                    if let action = line.action {
                        self?.executeChoiceAction(action)
                    }
                }
                return
            }
            
            let index = fullText.index(fullText.startIndex, offsetBy: charIndex)
            self.typewriterText += String(fullText[index])
            charIndex += 1
            
            // Haptic tick every 3rd character for subtle typing feel
            if charIndex % 3 == 0 {
                SoundManager.shared.playTypingHaptic()
            }
        }
    }
    
    func advanceDialogue() {
        // Don't advance if choices are showing — player must pick one
        if activeChoices != nil { return }
        // Don't advance if inventory swap is pending
        if showInventorySwap && !inventorySwapCompleted { return }
        
        if isTyping {
            // Skip typewriter and show full text
            SoundManager.shared.stopTypewriterSound()
            if currentDialogueIndex < currentDialogue.count {
                let line = currentDialogue[currentDialogueIndex]
                typewriterText = line.text
                isTyping = false
                // Show choices if present
                if let choices = line.choices, !choices.isEmpty {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        activeChoices = choices
                    }
                }
                // Execute direct action on skip too
                if let action = line.action {
                    executeChoiceAction(action)
                }
            }
        } else {
            currentDialogueIndex += 1
            showCurrentDialogueLine()
        }
    }
    
    /// Called when the player selects a dialogue choice
    func selectChoice(_ choice: DialogueChoice) {
        SoundManager.shared.playButtonSound()
        stats.choicesMade.append(choice.text)
        
        // Execute the choice's action
        if let action = choice.action {
            executeChoiceAction(action)
        }
        
        activeChoices = nil
        
        // Jump to specified dialogue index, or advance normally
        if let nextIndex = choice.nextDialogueIndex {
            currentDialogueIndex = nextIndex
        } else {
            currentDialogueIndex += 1
        }
        showCurrentDialogueLine()
    }
    
    /// Execute a gameplay action triggered by a dialogue choice
    private func executeChoiceAction(_ action: ChoiceAction) {
        switch action {
        case .setTransportProtocol(let proto):
            packet.layers.transportLayer = proto
            stats.chosenProtocol = proto
            if proto == .udp {
                learnTerm(EncyclopediaTerm.term(for: "udp")!)
            }
        case .setSecurityLayer(let sec):
            packet.layers.securityLayer = sec
            stats.upgradedToSSL = true
        case .showInventorySwap:
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                showInventorySwap = true
                inventorySwapCompleted = false
            }
        }
    }
    
    /// Called when the player taps the security layer in the inventory swap UI
    func completeInventorySwap() {
        packet.layers.securityLayer = .ssl
        stats.upgradedToSSL = true
        inventorySwapCompleted = true
        learnTerm(EncyclopediaTerm.term(for: "https")!)
        learnTerm(EncyclopediaTerm.term(for: "encryption")!)
        
        withAnimation(.spring()) {
            showInventorySwap = false
        }
        
        // Auto-advance dialogue after a beat
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.currentDialogueIndex += 1
            self.showCurrentDialogueLine()
        }
    }
    
    func endDialogue() {
        isDialogueActive = false
        currentDialogue = []
        currentDialogueIndex = 0
        typewriterText = ""
        activeChoices = nil
        showInventorySwap = false
        inventorySwapCompleted = false
    }
    
    // MARK: - Quiz System
    
    /// Decides whether to show a quiz or transition directly.
    /// Called by both 2D and 3D portal paths.
    private func triggerSceneTransition(to nextScene: StoryScene, is3D: Bool = false) {
        let quizQuestions = LevelQuizzes.quiz(for: currentScene)
        
        if !quizQuestions.isEmpty {
            // Store where to go after quiz
            pendingSceneAfterQuiz = nextScene
            quizScene = currentScene
            
            // Stop movement
            joystickDirection = .zero
            gameLoop3DTimer?.invalidate()
            gameLoop3DTimer = nil
            gameLoopTimer?.invalidate()
            gameLoopTimer = nil
            packet.isMoving = false
            
            withAnimation(.easeInOut(duration: 0.3)) {
                showQuiz = true
            }
        } else {
            // No quiz for this scene — go straight
            if is3D {
                transitionTo3DScene(nextScene)
            } else {
                transitionToScene(nextScene)
            }
        }
    }
    
    /// Record a single quiz answer.
    func recordQuizResult(_ result: QuizResult) {
        stats.quizResults.append(result)
    }
    
    /// Called when the quiz results screen is dismissed.
    func dismissQuiz() {
        withAnimation(.easeInOut(duration: 0.3)) {
            showQuiz = false
        }
        
        // Transition to the pending scene
        if let next = pendingSceneAfterQuiz {
            pendingSceneAfterQuiz = nil
            transitionTo3DScene(next)
        }
    }
    
    // MARK: - Encyclopedia
    func learnTerm(_ term: EncyclopediaTerm) {
        if !learnedTerms.contains(term) {
            learnedTerms.insert(term)
            stats.termsLearned.append(term)
            latestTerm = term
            
            SoundManager.shared.playTermLearnedSound()
            
            withAnimation(.spring()) {
                showNewTermPopup = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                withAnimation {
                    self.showNewTermPopup = false
                }
            }
        }
    }
    
    // MARK: - Game Control
    func setScreenSize(_ size: CGSize) {
        screenSize = size
    }
    
    func startGame() {
        stats = JourneyStats()
        SoundManager.shared.playPortalSound()
        transitionTo3DScene(.cpuCity)
    }
    
    func resetGame() {
        phase = .prologue
        currentScene = .frozenCafe
        packet = PacketState()
        npcs.removeAll()
        interactiveObjects.removeAll()
        learnedTerms.removeAll()
        stats = JourneyStats()
        isDialogueActive = false
        currentDialogue = []
        gameLoop3DTimer?.invalidate()
        gameLoop3DTimer = nil
        has3DSceneBeenSetup = false
        sceneManager.clearSceneContent()
    }
    
    func completeMission() {
        stats.missionComplete = true
        SoundManager.shared.playMissionCompleteSound()
        SoundManager.shared.stopBGM()
        phase = .epilogue
    }
    
    // MARK: - 3D Scene Integration
    
    /// Called once when ExplorationView3D appears
    private var has3DSceneBeenSetup = false
    func setup3DScene() {
        guard !has3DSceneBeenSetup else { return }
        has3DSceneBeenSetup = true
        build3DWorld(for: currentScene)
    }
    
    /// Builds the 3D world and places NPCs / portals
    func build3DWorld(for scene: StoryScene) {
        // Build the environment diorama
        WorldBuilder.buildScene(scene, in: sceneManager)
        
        // Clear old mappings
        npcIDMap.removeAll()
        portalIDMap.removeAll()
        
        // Place NPCs in 3D
        for (index, npc) in npcs.enumerated() {
            let pos3D = convertTo3DPosition(npc.position)
            sceneManager.addNPC(id: npc.id, type: npc.type, at: pos3D)
            npcIDMap[npc.id] = index
        }
        
        // Place portals in 3D
        for (index, obj) in interactiveObjects.enumerated() {
            if obj.type == .portal {
                let pos3D = convertTo3DPosition(obj.position)
                let portalColor: UIColor
                switch scene {
                case .cpuCity: portalColor = SceneManager.Palette.magenta
                case .wifiAntenna: portalColor = SceneManager.Palette.lime
                case .routerStation: portalColor = SceneManager.Palette.amber
                case .oceanCable: portalColor = SceneManager.Palette.cyan
                case .dnsLibrary: portalColor = SceneManager.Palette.violet
                default: portalColor = SceneManager.Palette.magenta
                }
                sceneManager.addPortal(id: obj.id, at: pos3D, color: portalColor)
                portalIDMap[obj.id] = index
            }
        }
    }
    
    /// Convert 2D screen position to 3D world position
    private func convertTo3DPosition(_ point: CGPoint) -> SCNVector3 {
        // Map from screen-space to 3D world-space
        // Screen center → (0,0,0), edges → world bounds
        let halfW = sceneManager.worldBounds.width / 2
        let halfH = sceneManager.worldBounds.height / 2
        
        let normalizedX = (point.x / max(screenSize.width, 1)) * 2 - 1  // -1 to 1
        let normalizedZ = (point.y / max(screenSize.height, 1)) * 2 - 1  // -1 to 1
        
        return SCNVector3(
            Float(normalizedX * halfW),
            0,
            Float(normalizedZ * halfH)
        )
    }
    
    // MARK: - 3D Joystick Movement
    
    func updatePlayerDirection3D(_ direction: CGVector) {
        joystickDirection = direction
        let isActive = abs(direction.dx) > 0.01 || abs(direction.dy) > 0.01
        
        if isActive && gameLoop3DTimer == nil {
            packet.isMoving = true
            start3DGameLoop()
        } else if !isActive {
            packet.isMoving = false
            gameLoop3DTimer?.invalidate()
            gameLoop3DTimer = nil
            check3DInteractions()
        }
    }
    
    private func start3DGameLoop() {
        gameLoop3DTimer?.invalidate()
        gameLoop3DTimer = Timer.scheduledTimer(withTimeInterval: 0.016, repeats: true) { [weak self] _ in
            self?.gameLoop3DTick()
        }
    }
    
    private func gameLoop3DTick() {
        let dir = joystickDirection
        guard abs(dir.dx) > 0.01 || abs(dir.dy) > 0.01 else { return }
        
        sceneManager.movePlayer(direction: dir, speed: 0.18)
        
        // Update facing direction
        if abs(dir.dx) > abs(dir.dy) {
            packet.facingDirection = dir.dx > 0 ? .right : .left
        } else {
            packet.facingDirection = dir.dy > 0 ? .down : .up
        }
        
        // Check for 3D interactions
        check3DInteractions()
    }
    
    private func check3DInteractions() {
        guard !isDialogueActive else { return }
        
        // Check NPC proximity — only set nearbyNPCName for the "Talk" prompt.
        // Dialogue is NOT auto-triggered; the user must tap to talk.
        if let nearestNPCID = sceneManager.nearestNPCInRange(range: 3.0),
           let npcIndex = npcIDMap[nearestNPCID],
           npcIndex < npcs.count {
            let npc = npcs[npcIndex]
            nearbyNPCName = npc.isInteractable ? npc.name : nil
        } else {
            nearbyNPCName = nil
        }
        
        // Check portal proximity
        if let nearestPortalID = sceneManager.nearestPortalInRange(range: 2.5),
           let portalIndex = portalIDMap[nearestPortalID],
           portalIndex < interactiveObjects.count {
            let obj = interactiveObjects[portalIndex]
            if let sceneString = obj.data, let scene = StoryScene(rawValue: sceneString) {
                nearPortal = true
                pendingPortalScene = scene
            } else {
                nearPortal = false
                pendingPortalScene = nil
            }
        } else {
            nearPortal = false
            pendingPortalScene = nil
        }
    }
    
    /// Called when user taps the ENTER PORTAL button
    func enterPortal() {
        guard let scene = pendingPortalScene else { return }
        nearPortal = false
        pendingPortalScene = nil
        triggerSceneTransition(to: scene, is3D: true)
    }
    
    func transitionTo3DScene(_ scene: StoryScene) {
        // Stop movement
        joystickDirection = .zero
        gameLoop3DTimer?.invalidate()
        gameLoop3DTimer = nil
        packet.isMoving = false
        
        SoundManager.shared.playPortalSound()
        
        // Mark as setup so ExplorationView3D.onAppear won't double-build
        has3DSceneBeenSetup = true
        
        currentScene = scene
        stats.scenesVisited.append(scene)
        
        // Setup scene content first (populates npcs and interactiveObjects arrays),
        // then build 3D world synchronously to avoid race conditions
        setupSceneContent(for: scene)
        build3DWorld(for: scene)
        
        SoundManager.shared.playAmbientSound(for: scene)
    }
}
