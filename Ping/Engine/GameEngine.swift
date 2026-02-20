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
        withAnimation(.easeInOut(duration: 0.5)) {
            currentScene = scene
            stats.scenesVisited.append(scene)
        }
        
        // Setup scene content
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.setupSceneContent(for: scene)
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
                DialogueLine(
                    speaker: "Firewall Blaze",
                    text: "HALT! *scans you* ...Processing... Ah, outbound traffic. You check out.",
                    emotion: "\u{1F6E1}\u{FE0F}"
                ),
                DialogueLine(
                    speaker: "Firewall Blaze",
                    text: "I'm a Firewall. Every single packet that enters or leaves this device has to pass through ME. I decide who gets in and who gets blocked.",
                    emotion: "\u{1F6E1}\u{FE0F}",
                    learnedTerm: EncyclopediaTerm.term(for: "firewall")
                ),
                DialogueLine(
                    speaker: "Firewall Blaze",
                    text: "Malware, hackers, suspicious connections \u{2014} I stop them all. Think of me as the bouncer of this phone. No ticket? No entry.",
                    emotion: "\u{1F6E1}\u{FE0F}"
                ),
                DialogueLine(
                    speaker: "Firewall Blaze",
                    text: "See that massive antenna? That's the Wi-Fi transmitter. It converts your data into radio waves that fly through the air at the speed of light!",
                    emotion: "\u{1F6E1}\u{FE0F}"
                ),
                DialogueLine(
                    speaker: "Firewall Blaze",
                    text: "Once you reach it, you'll be encoded into electromagnetic waves and beamed to the router. It'll feel like teleportation. Trust me, it's a rush.",
                    emotion: "\u{1F6E1}\u{FE0F}"
                ),
                DialogueLine(
                    speaker: "Firewall Blaze",
                    text: "Stay safe out there, little packet. The internet isn't always friendly. Now GO \u{2014} the portal to the Router Station awaits!",
                    emotion: "\u{1F6E1}\u{FE0F}"
                )
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
                DialogueLine(
                    speaker: "Router Rex",
                    text: "*stamps routing table* Well well, another packet! Welcome to the Router Station — the Grand Central Terminal of the internet.",
                    emotion: "👮"
                ),
                DialogueLine(
                    speaker: "Router Rex",
                    text: "I'm a Router, and this is what I do: I read the destination on your HAT (your Network Layer header) and figure out where to send you next.",
                    emotion: "👮",
                    learnedTerm: EncyclopediaTerm.term(for: "router")
                ),
                DialogueLine(
                    speaker: "Router Rex",
                    text: "See those glowing rails? Each one is a different network path. Millions of packets zoom through here every second — and I route EVERY. SINGLE. ONE.",
                    emotion: "👮"
                ),
                DialogueLine(
                    speaker: "Router Rex",
                    text: "Fun fact: your data doesn't travel in one piece. It gets split into many packets, each finding its own path, then reassembled at the destination!",
                    emotion: "👮"
                ),
                DialogueLine(
                    speaker: "Router Rex",
                    text: "Your destination is blank though... you need the DNS Library. I'll route you through the undersea fiber optic cable — the Blue Line, fastest route!",
                    emotion: "👮",
                    learnedTerm: EncyclopediaTerm.term(for: "fiber_optic")
                ),
                DialogueLine(
                    speaker: "Router Rex",
                    text: "That cable runs along the actual ocean floor. Thousands of miles of glass fiber, carrying 99% of the world's internet traffic. Mind-blowing, right?",
                    emotion: "👮"
                ),
                DialogueLine(
                    speaker: "Router Rex",
                    text: "Head to the portal. And remember: every hop between routers adds a tiny delay called LATENCY. The fewer hops, the faster the internet feels!",
                    emotion: "👮",
                    learnedTerm: EncyclopediaTerm.term(for: "latency")
                )
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
                DialogueLine(
                    speaker: "Librarian DNS",
                    text: "*adjusts holographic spectacles* A visitor from a smartphone! Welcome to the Domain Name System — the Grand Library of the Internet.",
                    emotion: "📚",
                    learnedTerm: EncyclopediaTerm.term(for: "dns")
                ),
                DialogueLine(
                    speaker: "Librarian DNS",
                    text: "Every website you've ever visited? The browser asked ME first. Humans type names like 'socialmedia.com', but computers only understand numbers.",
                    emotion: "📚"
                ),
                DialogueLine(
                    speaker: "Librarian DNS",
                    text: "My job is to translate those human-readable names into IP addresses — the numerical addresses that computers use to find each other.",
                    emotion: "📚"
                ),
                DialogueLine(
                    speaker: "Librarian DNS",
                    text: "Now, you seek... *consults ancient glowing tome* ...socialmedia.com? Let me trace through the hierarchy...",
                    emotion: "📚"
                ),
                DialogueLine(
                    speaker: "Librarian DNS",
                    text: "First I check the ROOT servers (the 13 master directories of the internet), then the .COM registry, and finally the authoritative server for socialmedia.com...",
                    emotion: "📚"
                ),
                DialogueLine(
                    speaker: "Librarian DNS",
                    text: "*a book flies off the shelf* FOUND IT! The IP address is: 142.250.185.78. I'll cache this answer so the NEXT lookup is instant!",
                    emotion: "📚",
                    learnedTerm: EncyclopediaTerm.term(for: "ip_address")
                ),
                DialogueLine(
                    speaker: "SYSTEM",
                    text: "🎩 HAT Updated! Destination IP: 142.250.185.78 — Your network layer now has a complete address!",
                    emotion: nil
                ),
                DialogueLine(
                    speaker: "SYSTEM",
                    text: "🎒 BACKPACK Updated! Now carrying: IP Response — Mission data acquired!",
                    emotion: nil
                ),
                DialogueLine(
                    speaker: "Librarian DNS",
                    text: "Now RUSH back! Every millisecond counts. To the human, this entire journey should feel instant. That's the magic of the internet — it's only fast because every piece works together.",
                    emotion: "📚"
                ),
                DialogueLine(
                    speaker: "Librarian DNS",
                    text: "Fun fact: this whole DNS lookup? In real life it takes about 20-120 milliseconds. The human won't even notice. But for us? It's an EPIC quest.",
                    emotion: "📚",
                    learnedTerm: EncyclopediaTerm.term(for: "latency")
                )
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
        currentMission = "Race back through the network \u{2014} the user is waiting for their feed!"
        packet.layers.applicationLayer = .ipResponse
        packet.layers.networkLayer.destinationIP = "142.250.185.78"
        
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
                    transitionToScene(scene)
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
        
        Timer.scheduledTimer(withTimeInterval: 0.03, repeats: true) { [weak self] timer in
            guard let self = self, charIndex < fullText.count else {
                timer.invalidate()
                self?.isTyping = false
                return
            }
            
            let index = fullText.index(fullText.startIndex, offsetBy: charIndex)
            self.typewriterText += String(fullText[index])
            charIndex += 1
        }
    }
    
    func advanceDialogue() {
        if isTyping {
            // Skip typewriter and show full text
            if currentDialogueIndex < currentDialogue.count {
                typewriterText = currentDialogue[currentDialogueIndex].text
                isTyping = false
            }
        } else {
            currentDialogueIndex += 1
            showCurrentDialogueLine()
        }
    }
    
    func endDialogue() {
        isDialogueActive = false
        currentDialogue = []
        currentDialogueIndex = 0
        typewriterText = ""
    }
    
    // MARK: - Encyclopedia
    func learnTerm(_ term: EncyclopediaTerm) {
        if !learnedTerms.contains(term) {
            learnedTerms.insert(term)
            stats.termsLearned.append(term)
            latestTerm = term
            
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
        transitionTo3DScene(scene)
    }
    
    func transitionTo3DScene(_ scene: StoryScene) {
        // Stop movement
        joystickDirection = .zero
        gameLoop3DTimer?.invalidate()
        gameLoop3DTimer = nil
        packet.isMoving = false
        
        // Mark as setup so ExplorationView3D.onAppear won't double-build
        has3DSceneBeenSetup = true
        
        currentScene = scene
        stats.scenesVisited.append(scene)
        
        // Setup scene content first (populates npcs and interactiveObjects arrays),
        // then build 3D world synchronously to avoid race conditions
        setupSceneContent(for: scene)
        build3DWorld(for: scene)
    }
}
