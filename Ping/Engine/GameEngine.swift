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
    @Published var showPauseMenu: Bool = false
    @Published var currentMission: String = ""
    @Published var portalLocked: Bool = false
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
    private var joystickDirection: CGVector = .zero
    private var gameLoop3DTimer: Timer?
    private var typewriterTimer: Timer?
    
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
    
    func setupSceneContent(for scene: StoryScene) {
        npcs.removeAll()
        interactiveObjects.removeAll()
        
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
        
        let daemon = NPC(
            type: .daemon,
            position: CGPoint(x: screenSize.width * 0.55, y: screenSize.height * 0.45),
            name: "Daemon-7",
            dialogue: [
                DialogueLine(
                    speaker: "Daemon-7",
                    text: "*whirring noises* Ah, a fresh Data Block! Welcome to CPU City."
                ),
                DialogueLine(
                    speaker: "Daemon-7",
                    text: "I am a Daemon. I run in the background while humans think THEY are in charge...",
                    learnedTerm: EncyclopediaTerm.term(for: "daemon")
                ),
                DialogueLine(
                    speaker: "Daemon-7",
                    text: "But really, WE keep the lights on. 24/7. No breaks. No complaints."
                ),
                DialogueLine(
                    speaker: "Daemon-7",
                    text: "Anyway! The user just tapped 'Load Feed'. We need someone to find the IP address for socialmedia.com."
                ),
                DialogueLine(
                    speaker: "Daemon-7",
                    text: "That's where you come in! Let me configure your packet layers..."
                ),
                DialogueLine(
                    speaker: "SYSTEM",
                    text: "[Layer 4] Application Layer initialized - Payload: 'GET socialmedia.com'",
                    learnedTerm: EncyclopediaTerm.term(for: "payload")
                ),
                DialogueLine(
                    speaker: "SYSTEM",
                    text: "[Layer 3] Transport Layer configured - Protocol: TCP",
                    learnedTerm: EncyclopediaTerm.term(for: "tcp")
                ),
                DialogueLine(
                    speaker: "SYSTEM",
                    text: "[Layer 2] Network Layer attached - Destination IP: ???.???.???.???",
                    learnedTerm: EncyclopediaTerm.term(for: "header")
                ),
                DialogueLine(
                    speaker: "Daemon-7",
                    text: "Your mission: Travel to the DNS Server, get the IP address, and bring it back. Head to the Wi-Fi Antenna!"
                )
            ]
        )
        npcs.append(daemon)
        
        // Portal to WiFi — far right, opposite player spawn
        let portal = InteractiveObject(
            type: .portal,
            position: CGPoint(x: screenSize.width * 0.9, y: screenSize.height * 0.5),
            data: "wifi_antenna"
        )
        interactiveObjects.append(portal)
    }
    
    private func setupWiFiAntenna() {
        currentMission = "Reach the Wi-Fi transmitter and beam yourself into the airwaves!"
        
        let firewall = NPC(
            type: .firewall,
            position: CGPoint(x: screenSize.width * 0.6, y: screenSize.height * 0.45),
            name: "Firewall Blaze",
            dialogue: [
                DialogueLine(speaker: "Security Gateway", text: "Halt. Outbound packet detected. Scanning protocol headers..."),
                DialogueLine(speaker: "Security Gateway", text: "I am the local Firewall. I monitor all incoming and outgoing network traffic based on strict security rules.", learnedTerm: EncyclopediaTerm.term(for: "firewall")),
                DialogueLine(speaker: "Security Gateway", text: "WARNING: You are attempting to transmit via HTTP. This plaintext protocol is unencrypted and vulnerable to interception.", learnedTerm: EncyclopediaTerm.term(for: "https")),
                DialogueLine(speaker: "Security Gateway", text: "Access Denied. I cannot permit unsecured data to broadcast over open airwaves."),
                DialogueLine(speaker: "Security Gateway", text: "You must equip a TLS/SSL certificate to encrypt your payload. Open your Layer Inventory and upgrade your security protocol.", learnedTerm: EncyclopediaTerm.term(for: "encryption")),
                DialogueLine(speaker: "SYSTEM", text: "SECURITY CHECK — Open your Layers menu (top right) to equip HTTPS encryption on Layer 1.", action: .showInventorySwap),
                DialogueLine(speaker: "Security Gateway", text: "Scan complete. SSL Certificate verified. Your data is now securely encrypted."),
                DialogueLine(speaker: "Security Gateway", text: "You are cleared for transmission. The antenna will convert your digital data into radio frequencies. Brace for broadcast.")
            ]
        )
        npcs.append(firewall)
        
        // Portal — far right, opposite player spawn
        let portal = InteractiveObject(
            type: .portal,
            position: CGPoint(x: screenSize.width * 0.9, y: screenSize.height * 0.5),
            data: "router_station"
        )
        interactiveObjects.append(portal)
    }
    
    private func setupRouterStation() {
        currentMission = "Meet Router Rex and find the path to the undersea cable."
        
        let routerGuard = NPC(
            type: .routerGuard,
            position: CGPoint(x: screenSize.width * 0.5, y: screenSize.height * 0.45),
            name: "Router Rex",
            dialogue: [
                DialogueLine(speaker: "Core Router", text: "Connection established. Welcome to the ISP Gateway Router. Analyzing network layer headers..."),
                DialogueLine(speaker: "Core Router", text: "I read your destination IP and determine the most efficient path through the global network.", learnedTerm: EncyclopediaTerm.term(for: "router")),
                DialogueLine(speaker: "Core Router", text: "You are scheduled for the transatlantic fiber-optic cable. Before I dispatch you, you must configure your Transport Layer."),
                DialogueLine(speaker: "Core Router", text: "TCP provides reliable delivery with error-checking, but introduces slight latency.", learnedTerm: EncyclopediaTerm.term(for: "tcp")),
                DialogueLine(speaker: "Core Router", text: "UDP maximizes speed by skipping verification, but risks permanent data loss if turbulence occurs.", learnedTerm: EncyclopediaTerm.term(for: "udp")),
                DialogueLine(speaker: "Core Router", text: "Select your routing protocol for the ocean crossing:", choices: [
                    DialogueChoice(text: "TCP — Prioritize Reliability", nextDialogueIndex: 7, action: .setTransportProtocol(.tcp)),
                    DialogueChoice(text: "UDP — Prioritize Speed", nextDialogueIndex: 9, action: .setTransportProtocol(.udp))
                ]),
                // Index 7 (TCP)
                DialogueLine(speaker: "Core Router", text: "TCP acknowledged. Data integrity will be prioritized over speed."),
                // Index 8 (Shared)
                DialogueLine(speaker: "Core Router", text: "Routing you into the undersea fiber-optic backbone. You will travel as pulses of light.", learnedTerm: EncyclopediaTerm.term(for: "fiber_optic")),
                // Index 9 (UDP)
                DialogueLine(speaker: "Core Router", text: "UDP acknowledged. Verification disabled. Maximize transmission speed."),
                // Index 10 (UDP to Shared)
                DialogueLine(speaker: "Core Router", text: "Routing you into the undersea fiber-optic backbone. You will travel as pulses of light.", learnedTerm: EncyclopediaTerm.term(for: "fiber_optic")),
                // Index 11 (Final)
                DialogueLine(speaker: "Core Router", text: "Remember: every router hop adds physical latency. Proceed to the egress portal.", learnedTerm: EncyclopediaTerm.term(for: "latency"))
            ]
        )
        npcs.append(routerGuard)
        
        // Portal — far right, opposite player spawn
        let portal = InteractiveObject(
            type: .portal,
            position: CGPoint(x: screenSize.width * 0.9, y: screenSize.height * 0.5),
            data: "ocean_cable"
        )
        interactiveObjects.append(portal)
    }
    
    private func setupOceanCable() {
        currentMission = "Ride the fiber optic light pulse across the ocean floor!"
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [weak self] in
            guard let self = self, self.currentScene == .oceanCable else { return }
            
            if self.stats.chosenProtocol == .udp {
                self.stats.lostPacketData = true
                self.currentDialogue = [
                    DialogueLine(speaker: "SYSTEM", text: "WARNING: Signal degradation detected in the fiber-optic line."),
                    DialogueLine(speaker: "SYSTEM", text: "UDP Protocol active. Packet loss detected. Missing packets cannot be re-requested."),
                    DialogueLine(speaker: "SYSTEM", text: "Payload integrity compromised. Proceeding to destination with degraded data...")
                ]
            } else {
                self.currentDialogue = [
                    DialogueLine(speaker: "SYSTEM", text: "WARNING: Signal degradation detected. TCP Checksum failed."),
                    DialogueLine(speaker: "SYSTEM", text: "TCP Protocol active: Automatically requesting retransmission from previous router...", learnedTerm: EncyclopediaTerm.term(for: "tcp")),
                    DialogueLine(speaker: "SYSTEM", text: "Data recovered successfully. Latency increased by 14ms, but payload is 100% intact.")
                ]
            }
            
            self.currentDialogueIndex = 0
            self.isDialogueActive = true
            self.showCurrentDialogueLine()
        }
        
        // Portal — far right end of the cable
        let portal = InteractiveObject(
            type: .portal,
            position: CGPoint(x: screenSize.width * 0.9, y: screenSize.height * 0.5),
            data: "dns_library"
        )
        interactiveObjects.append(portal)
    }
    
    private func setupDNSLibrary() {
        currentMission = "Find the DNS Librarian and look up the IP address for socialmedia.com!"
        
        let librarian = NPC(
            type: .librarian,
            position: CGPoint(x: screenSize.width * 0.55, y: screenSize.height * 0.45),
            name: "Librarian DNS",
            dialogue: [
                DialogueLine(speaker: "DNS Resolver", text: "Query received. Welcome to the Domain Name System.", learnedTerm: EncyclopediaTerm.term(for: "dns")),
                DialogueLine(speaker: "DNS Resolver", text: "Computers communicate via numerical IP addresses. Humans use text-based URLs. I bridge that gap."),
                DialogueLine(speaker: "DNS Resolver", text: "Parsing application layer... You are requesting the host address for 'socialmedia.com'."),
                DialogueLine(speaker: "DNS Resolver", text: "Searching authoritative zones... Match found. Generating IP response."),
                DialogueLine(speaker: "DNS Resolver", text: "The IPv4 address is: 142.250.185.78. I am caching this result to expedite future lookups.", learnedTerm: EncyclopediaTerm.term(for: "ip_address")),
                DialogueLine(speaker: "SYSTEM", text: "[Layer 2] Network Layer updated — Destination IP set to 142.250.185.78."),
                DialogueLine(speaker: "SYSTEM", text: "[Layer 4] Application Layer updated — Payload swapped to IP Response Data."),
                DialogueLine(speaker: "DNS Resolver", text: "Your routing headers are complete. Initiate the return sequence immediately."),
                DialogueLine(speaker: "DNS Resolver", text: "The user's browser is waiting. If latency exceeds 500ms, the connection will time out.", learnedTerm: EncyclopediaTerm.term(for: "latency"))
            ]
        )
        npcs.append(librarian)
        
        // Portal — far right, opposite player spawn
        let portal = InteractiveObject(
            type: .portal,
            position: CGPoint(x: screenSize.width * 0.9, y: screenSize.height * 0.5),
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
            type: .routerGuard,
            position: CGPoint(x: screenSize.width * 0.45, y: screenSize.height * 0.45),
            name: "Load Balancer",
            dialogue: [
                DialogueLine(speaker: "Load Balancer", text: "Incoming traffic detected. I am the local Load Balancer. Analyzing packet weight..."),
                DialogueLine(speaker: "Load Balancer", text: "You are carrying a full IP Response payload. The downlink to the user's device is currently experiencing high network congestion."),
                DialogueLine(speaker: "Load Balancer", text: "Allocating bandwidth... Rerouting you to a high-priority express channel to avoid packet collision."),
                DialogueLine(speaker: "Load Balancer", text: "Proceed to the final endpoint immediately. The interface is ready to render the data.")
            ]
        )
        npcs.append(loadBalancer)
        
        // Portal — far right, opposite player spawn
        let portal = InteractiveObject(
            type: .portal,
            position: CGPoint(x: screenSize.width * 0.9, y: screenSize.height * 0.5),
            data: "feed_loaded"
        )
        interactiveObjects.append(portal)
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
                
                // Hide the floating quest marker now that we've talked to them
                sceneManager.hideQuestMarker(for: nearestNPCID)
            }
        }
    }
    
    // MARK: - Dialogue System
    func startDialogue(with npc: NPC) {
        // Stop all movement when dialogue begins
        joystickDirection = .zero
        gameLoop3DTimer?.invalidate()
        gameLoop3DTimer = nil

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
        
        // Kill any previous typewriter timer to prevent garbled text
        typewriterTimer?.invalidate()
        typewriterTimer = nil
        
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
            if line.text.contains("Application Layer") && line.text.contains("GET socialmedia.com") {
                packet.layers.applicationLayer = .dnsQuery
            }
        }
        
        // Typewriter effect
        let fullText = line.text
        var charIndex = 0
        
        // Start typewriter sound (stops any previous one)
        SoundManager.shared.startTypewriterSound()
        
        typewriterTimer = Timer.scheduledTimer(withTimeInterval: 0.03, repeats: true) { [weak self] timer in
            guard let self = self, charIndex < fullText.count else {
                timer.invalidate()
                self?.typewriterTimer = nil
                DispatchQueue.main.async {
                    // Stop the typewriter sound the moment text is fully displayed
                    SoundManager.shared.stopTypewriterSound()
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
                DispatchQueue.main.async {
                    SoundManager.shared.playTypingHaptic()
                }
            }
        }
    }
    
    func advanceDialogue() {
        // If choices are showing, auto-select the first choice (TCP default)
        if let choices = activeChoices, let firstChoice = choices.first {
            selectChoice(firstChoice)
            return
        }
        // Don't advance if inventory swap is pending
        if showInventorySwap && !inventorySwapCompleted { return }
        
        if isTyping {
            // Skip typewriter and show full text immediately
            typewriterTimer?.invalidate()
            typewriterTimer = nil
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
            
            // For transport protocol choices, replace dialogue with branch-specific lines
            // to prevent crossing into the other branch
            if case .setTransportProtocol(let proto) = action {
                let ackText = proto == .tcp
                    ? "TCP acknowledged. Data integrity will be prioritized over speed."
                    : "UDP acknowledged. Verification disabled. Maximize transmission speed."
                currentDialogue = [
                    DialogueLine(speaker: "Core Router", text: ackText),
                    DialogueLine(speaker: "Core Router", text: "Routing you into the undersea fiber-optic backbone. You will travel as pulses of light.", learnedTerm: EncyclopediaTerm.term(for: "fiber_optic")),
                    DialogueLine(speaker: "Core Router", text: "Remember: every router hop adds physical latency. Proceed to the egress portal.", learnedTerm: EncyclopediaTerm.term(for: "latency"))
                ]
                activeChoices = nil
                currentDialogueIndex = 0
                showCurrentDialogueLine()
                return
            }
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
        typewriterTimer?.invalidate()
        typewriterTimer = nil
        SoundManager.shared.stopTypewriterSound()
        isDialogueActive = false
        currentDialogue = []
        currentDialogueIndex = 0
        typewriterText = ""
        isTyping = false
        activeChoices = nil
        showInventorySwap = false
        inventorySwapCompleted = false
    }
    
    // MARK: - Quiz System
    
    /// Decides whether to show a quiz or transition directly.
    /// Called by both 2D and 3D portal paths.
    private func triggerSceneTransition(to nextScene: StoryScene) {
        let quizQuestions = LevelQuizzes.quiz(for: currentScene)
        
        if !quizQuestions.isEmpty {
            // Store where to go after quiz
            pendingSceneAfterQuiz = nextScene
            quizScene = currentScene
            
            // Stop movement
            joystickDirection = .zero
            gameLoop3DTimer?.invalidate()
            gameLoop3DTimer = nil
            
            withAnimation(.easeInOut(duration: 0.3)) {
                showQuiz = true
            }
        } else {
            // No quiz for this scene — go straight
            transitionTo3DScene(nextScene)
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
        guard !showPauseMenu else { return }
        joystickDirection = direction
        let isActive = abs(direction.dx) > 0.01 || abs(direction.dy) > 0.01
        
        if isActive && gameLoop3DTimer == nil {
            start3DGameLoop()
        } else if !isActive {
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
        guard !showPauseMenu else { return }
        let dir = joystickDirection
        guard abs(dir.dx) > 0.01 || abs(dir.dy) > 0.01 else { return }
        
        sceneManager.movePlayer(direction: dir, speed: 0.18)
        
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
        
        // Check portal proximity AND ensure user has talked to the NPC (if there is one)
        let hasTalkedToLocalNPC = npcs.isEmpty || npcs.contains(where: { $0.hasSpoken })
        
        if let nearestPortalID = sceneManager.nearestPortalInRange(range: 2.5),
           let portalIndex = portalIDMap[nearestPortalID],
           portalIndex < interactiveObjects.count {
            let obj = interactiveObjects[portalIndex]
            if let sceneString = obj.data, let scene = StoryScene(rawValue: sceneString) {
                if hasTalkedToLocalNPC {
                    nearPortal = true
                    portalLocked = false
                    pendingPortalScene = scene
                } else {
                    nearPortal = false
                    portalLocked = true
                    pendingPortalScene = nil
                }
            } else {
                nearPortal = false
                portalLocked = false
                pendingPortalScene = nil
            }
        } else {
            nearPortal = false
            portalLocked = false
            pendingPortalScene = nil
        }
    }
    
    /// Called when user taps the ENTER PORTAL button
    func enterPortal() {
        guard let scene = pendingPortalScene else { return }
        nearPortal = false
        pendingPortalScene = nil
        triggerSceneTransition(to: scene)
    }
    
    func transitionTo3DScene(_ scene: StoryScene) {
        // Stop movement
        joystickDirection = .zero
        gameLoop3DTimer?.invalidate()
        gameLoop3DTimer = nil
        
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
