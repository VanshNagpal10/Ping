//
//  GameEngine.swift
//  Ping
//
//  Main game engine managing state, physics, and game loop
//

import SwiftUI
import Combine

class GameEngine: ObservableObject {
    // MARK: - Published State
    @Published var phase: GamePhase = .intro
    @Published var packet: PacketState = PacketState()
    @Published var currentZone: Zone = .localNetwork
    @Published var latency: Int = 0  // Ping in ms
    @Published var obstacles: [Obstacle] = []
    @Published var powerUps: [PowerUp] = []
    @Published var handshakeStep: HandshakeStep = .waiting
    @Published var isPaused: Bool = false
    @Published var stats: JourneyStats = JourneyStats()
    
    // MARK: - Game Constants
    let gravity: CGFloat = 15.0
    let thrustPower: CGFloat = -25.0
    let scrollSpeed: CGFloat = 300.0
    let maxLatency: Int = 500  // Timeout threshold
    
    // MARK: - Internal State
    private var displayLink: CADisplayLink?
    private var lastUpdateTime: CFTimeInterval = 0
    private var screenSize: CGSize = .zero
    private var isThrusting: Bool = false
    private var zoneProgress: CGFloat = 0
    private let zoneLength: CGFloat = 3000  // Pixels per zone
    
    // MARK: - Initialization
    init() {}
    
    // MARK: - Game Loop Control
    func startGame(screenSize: CGSize) {
        self.screenSize = screenSize
        self.packet = PacketState(x: 100, y: screenSize.height / 2)
        self.latency = 0
        self.currentZone = .localNetwork
        self.stats = JourneyStats()
        self.zoneProgress = 0
        
        spawnObstaclesForZone()
        startGameLoop()
    }
    
    func startGameLoop() {
        displayLink?.invalidate()
        displayLink = CADisplayLink(target: self, selector: #selector(gameLoop))
        displayLink?.preferredFrameRateRange = CAFrameRateRange(minimum: 30, maximum: 60)
        displayLink?.add(to: .main, forMode: .common)
        lastUpdateTime = CACurrentMediaTime()
    }
    
    func pauseGame() {
        isPaused = true
        displayLink?.isPaused = true
    }
    
    func resumeGame() {
        isPaused = false
        displayLink?.isPaused = false
        lastUpdateTime = CACurrentMediaTime()
    }
    
    func stopGame() {
        displayLink?.invalidate()
        displayLink = nil
    }
    
    // MARK: - Input Handling
    func startThrust() {
        isThrusting = true
    }
    
    func stopThrust() {
        isThrusting = false
    }
    
    func toggleProtocol() {
        packet.protocolMode = packet.protocolMode == .http ? .https : .http
        stats.protocolSwitches += 1
    }
    
    func toggleMovementStyle() {
        packet.movementStyle = packet.movementStyle == .tcp ? .udp : .tcp
    }
    
    // MARK: - Game Loop
    @objc private func gameLoop(_ displayLink: CADisplayLink) {
        guard !isPaused, phase == .playing || phase == .returning else { return }
        
        let currentTime = CACurrentMediaTime()
        let deltaTime = CGFloat(currentTime - lastUpdateTime)
        lastUpdateTime = currentTime
        
        // Clamp delta time to prevent huge jumps
        let dt = min(deltaTime, 0.05)
        
        updatePhysics(dt: dt)
        updateObstacles(dt: dt)
        checkCollisions()
        updateZoneProgress(dt: dt)
        checkGameState()
    }
    
    // MARK: - Physics
    private func updatePhysics(dt: CGFloat) {
        // Apply gravity or thrust
        if isThrusting {
            packet.velocityY += thrustPower * dt * 60
        } else {
            packet.velocityY += gravity * dt * 60
        }
        
        // Apply friction based on movement style
        packet.velocityY *= packet.movementStyle.friction
        
        // Clamp velocity
        packet.velocityY = max(-500, min(500, packet.velocityY))
        
        // Update position
        packet.y += packet.velocityY * dt
        
        // Boundary checks
        let halfSize = packet.effectiveSize / 2
        if packet.y < halfSize {
            packet.y = halfSize
            packet.velocityY = 0
        }
        if packet.y > screenSize.height - halfSize {
            packet.y = screenSize.height - halfSize
            packet.velocityY = 0
        }
    }
    
    // MARK: - Obstacles
    private func updateObstacles(dt: CGFloat) {
        let speed = scrollSpeed * (phase == .returning ? 0.7 : 1.0) * packet.protocolMode.speedMultiplier
        
        // Move obstacles left
        for i in obstacles.indices {
            obstacles[i].x -= speed * dt
        }
        
        // Remove off-screen obstacles
        obstacles.removeAll { $0.x < -100 }
        
        // Move power-ups
        for i in powerUps.indices {
            powerUps[i].x -= speed * dt
        }
        powerUps.removeAll { $0.x < -50 || $0.isCollected }
    }
    
    private func spawnObstaclesForZone() {
        obstacles.removeAll()
        powerUps.removeAll()
        
        let startX: CGFloat = screenSize.width + 100
        
        switch currentZone {
        case .localNetwork:
            // Easy obstacles - furniture/walls
            for i in 0..<5 {
                let obstacle = Obstacle(
                    type: .router,
                    x: startX + CGFloat(i) * 400,
                    y: CGFloat.random(in: 100...(screenSize.height - 100)),
                    width: 60,
                    height: 80
                )
                obstacles.append(obstacle)
            }
            
        case .ispDns:
            // Highway with DNS fork
            for i in 0..<4 {
                let obstacle = Obstacle(
                    type: .router,
                    x: startX + CGFloat(i) * 500,
                    y: CGFloat.random(in: 150...(screenSize.height - 150)),
                    width: 50,
                    height: 70
                )
                obstacles.append(obstacle)
            }
            // Add bandwidth power-ups
            for i in 0..<3 {
                let powerUp = PowerUp(
                    type: .bandwidth,
                    x: startX + CGFloat(i) * 600 + 200,
                    y: CGFloat.random(in: 100...(screenSize.height - 100))
                )
                powerUps.append(powerUp)
            }
            
        case .backbone:
            // Firewalls - need HTTPS
            for i in 0..<6 {
                let isFirewall = i % 2 == 0
                let obstacle = Obstacle(
                    type: isFirewall ? .firewall : .router,
                    x: startX + CGFloat(i) * 350,
                    y: isFirewall ? screenSize.height / 2 : CGFloat.random(in: 100...(screenSize.height - 100)),
                    width: isFirewall ? 20 : 50,
                    height: isFirewall ? screenSize.height * 0.6 : 60
                )
                obstacles.append(obstacle)
            }
            
        case .lastMile:
            // Congestion - need bandwidth power-ups
            for i in 0..<8 {
                let obstacle = Obstacle(
                    type: .congestion,
                    x: startX + CGFloat(i) * 300,
                    y: CGFloat.random(in: 80...(screenSize.height - 80)),
                    width: 40,
                    height: 50
                )
                obstacles.append(obstacle)
            }
            // More bandwidth power-ups
            for i in 0..<5 {
                let powerUp = PowerUp(
                    type: .bandwidth,
                    x: startX + CGFloat(i) * 400 + 150,
                    y: CGFloat.random(in: 100...(screenSize.height - 100))
                )
                powerUps.append(powerUp)
            }
        }
    }
    
    // MARK: - Collisions
    private func checkCollisions() {
        let packetFrame = CGRect(
            x: packet.x - packet.effectiveSize/2,
            y: packet.y - packet.effectiveSize/2,
            width: packet.effectiveSize,
            height: packet.effectiveSize
        )
        
        // Check obstacles
        for i in obstacles.indices where obstacles[i].isActive {
            if packetFrame.intersects(obstacles[i].frame) {
                handleObstacleHit(obstacles[i])
                obstacles[i].isActive = false
            }
        }
        
        // Check power-ups
        for i in powerUps.indices where !powerUps[i].isCollected {
            let powerUpFrame = CGRect(x: powerUps[i].x - 20, y: powerUps[i].y - 20, width: 40, height: 40)
            if packetFrame.intersects(powerUpFrame) {
                collectPowerUp(powerUps[i])
                powerUps[i].isCollected = true
            }
        }
    }
    
    private func handleObstacleHit(_ obstacle: Obstacle) {
        switch obstacle.type {
        case .firewall:
            if packet.protocolMode == .http {
                // Instant death without HTTPS
                latency = maxLatency + 1
            } else {
                // HTTPS protects, small penalty
                latency += 20
            }
        case .router, .congestion:
            latency += obstacle.type.latencyPenalty
            stats.obstaclesHit += 1
        case .dnsFork, .gateway:
            break
        }
        
        SoundManager.shared.playHit()
    }
    
    private func collectPowerUp(_ powerUp: PowerUp) {
        switch powerUp.type {
        case .bandwidth:
            // Temporary speed doesn't affect latency directly
            break
        case .latencyReduce:
            latency = max(0, latency - 30)
        case .shield:
            // Could add temporary HTTPS
            break
        }
        
        SoundManager.shared.playCollect()
    }
    
    // MARK: - Zone Progress
    private func updateZoneProgress(dt: CGFloat) {
        let speed = scrollSpeed * packet.protocolMode.speedMultiplier
        zoneProgress += speed * dt
        
        if zoneProgress >= zoneLength {
            advanceZone()
        }
    }
    
    private func advanceZone() {
        zoneProgress = 0
        stats.zonesVisited.append(currentZone)
        
        if phase == .playing {
            switch currentZone {
            case .localNetwork:
                currentZone = .ispDns
                spawnObstaclesForZone()
            case .ispDns:
                currentZone = .backbone
                spawnObstaclesForZone()
            case .backbone:
                // Reached server - start handshake
                phase = .handshake
                stopGame()
            case .lastMile:
                break
            }
        } else if phase == .returning {
            // Completed return journey
            completeGame(success: true)
        }
    }
    
    // MARK: - Handshake
    func performHandshakeStep() {
        guard phase == .handshake else { return }
        
        switch handshakeStep {
        case .waiting:
            handshakeStep = .syn
        case .syn:
            handshakeStep = .synAck
        case .synAck:
            handshakeStep = .ack
        case .ack:
            handshakeStep = .complete
            // After short delay, start return journey
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                self?.startReturnJourney()
            }
        case .complete:
            break
        }
        
        SoundManager.shared.playHandshake()
    }
    
    private func startReturnJourney() {
        phase = .returning
        packet.isCarryingPayload = true
        currentZone = .lastMile
        zoneProgress = 0
        handshakeStep = .waiting
        spawnObstaclesForZone()
        startGameLoop()
    }
    
    // MARK: - Game State
    private func checkGameState() {
        if latency > maxLatency {
            completeGame(success: false)
        }
    }
    
    private func completeGame(success: Bool) {
        stopGame()
        stats.endTime = Date()
        stats.finalLatency = latency
        stats.success = success
        phase = .debrief
    }
    
    // MARK: - Phase Transitions
    func startTransition() {
        phase = .transition
        SoundManager.shared.playTransition()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            guard let self = self else { return }
            self.phase = .playing
            self.startGame(screenSize: self.screenSize)
        }
    }
    
    func setScreenSize(_ size: CGSize) {
        screenSize = size
    }
    
    func resetGame() {
        stopGame()
        phase = .intro
        packet = PacketState()
        latency = 0
        currentZone = .localNetwork
        obstacles = []
        powerUps = []
        handshakeStep = .waiting
        stats = JourneyStats()
        zoneProgress = 0
    }
}
