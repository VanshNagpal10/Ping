//
//  SceneManager.swift
//  Ping - Packet World
//
//  SceneKit 3D scene manager — neon cyberpunk aesthetic
//

import SceneKit
import SwiftUI
import Combine

/// Manages the 3D SceneKit world. Each story scene builds a unique diorama.
class SceneManager: ObservableObject {

    let scene = SCNScene()
    
    // Node references
    private(set) var playerNode: SCNNode!
    private(set) var cameraNode: SCNNode!
    private(set) var cameraRig: SCNNode!
    private var npcNodes: [UUID: SCNNode] = [:]
    private var portalNodes: [UUID: SCNNode] = [:]
    private var floorNode: SCNNode?
    
    // World boundaries
    var worldBounds: CGSize = CGSize(width: 30, height: 20)
    
    // Obstacle collision — simple AABB rects on the XZ plane
    struct ObstacleRect {
        let minX: Float
        let maxX: Float
        let minZ: Float
        let maxZ: Float
    }
    private(set) var obstacles: [ObstacleRect] = []
    private let playerRadius: Float = 0.4  // collision radius for the player
    
    /// Register a box obstacle at world position with given half-extents.
    func registerObstacle(x: Float, z: Float, halfW: Float, halfL: Float) {
        obstacles.append(ObstacleRect(
            minX: x - halfW, maxX: x + halfW,
            minZ: z - halfL, maxZ: z + halfL
        ))
    }
    
    // MARK: - Color Palette (Neon Cyberpunk)
    struct Palette {
        // Base darks
        static let void        = UIColor(red: 0.04, green: 0.02, blue: 0.08, alpha: 1)
        static let charcoal    = UIColor(red: 0.08, green: 0.06, blue: 0.14, alpha: 1)
        static let slate       = UIColor(red: 0.12, green: 0.10, blue: 0.20, alpha: 1)
        
        // Neon accents
        static let cyan        = UIColor(red: 0.0, green: 0.9, blue: 1.0, alpha: 1)
        static let magenta     = UIColor(red: 1.0, green: 0.1, blue: 0.6, alpha: 1)
        static let amber       = UIColor(red: 1.0, green: 0.75, blue: 0.0, alpha: 1)
        static let lime        = UIColor(red: 0.4, green: 1.0, blue: 0.3, alpha: 1)
        static let violet      = UIColor(red: 0.6, green: 0.2, blue: 1.0, alpha: 1)
        static let coral       = UIColor(red: 1.0, green: 0.4, blue: 0.3, alpha: 1)
        
        // Surfaces
        static let gridLine    = UIColor(red: 0.15, green: 0.12, blue: 0.30, alpha: 1)
        static let floorBase   = UIColor(red: 0.06, green: 0.04, blue: 0.12, alpha: 1)
    }
    
    // MARK: - Init
    init() {
        setupScene()
        setupCamera()
        setupPlayer()
        setupLighting()
    }
    
    // MARK: - Base Scene
    private func setupScene() {
        scene.background.contents = Palette.void
        scene.fogStartDistance = 25
        scene.fogEndDistance = 55
        scene.fogColor = Palette.void
    }
    
    // MARK: - Camera
    private func setupCamera() {
        let camera = SCNCamera()
        camera.fieldOfView = 50
        camera.zNear = 0.1
        camera.zFar = 200
        // Turn HDR ON for lavish cyberpunk glow
        camera.wantsHDR = true
        camera.bloomThreshold = 0.8
        camera.bloomIntensity = 1.2
        camera.bloomBlurRadius = 12.0
        camera.wantsExposureAdaptation = false
        
        cameraNode = SCNNode()
        cameraNode.camera = camera
        cameraNode.position = SCNVector3(0, 8, 14)
        cameraNode.eulerAngles = SCNVector3(-Float.pi / 6, 0, 0)
        
        // Rig so we can smoothly follow player
        cameraRig = SCNNode()
        cameraRig.addChildNode(cameraNode)
        scene.rootNode.addChildNode(cameraRig)
    }
    
    // MARK: - Lighting
    private func setupLighting() {
        // Key light — warm amber from above-right
        let keyLight = SCNLight()
        keyLight.type = .directional
        keyLight.color = UIColor(red: 1.0, green: 0.95, blue: 0.85, alpha: 1)
        keyLight.intensity = 600
        keyLight.castsShadow = true
        keyLight.shadowMode = .deferred
        keyLight.shadowRadius = 4
        keyLight.shadowSampleCount = 16
        keyLight.shadowColor = UIColor.black.withAlphaComponent(0.8)
        let keyNode = SCNNode()
        keyNode.light = keyLight
        keyNode.eulerAngles = SCNVector3(-Float.pi / 3, Float.pi / 5, 0)
        scene.rootNode.addChildNode(keyNode)
        
        // Fill light — cool cyan from left (kept subtle to avoid washing everything)
        let fillLight = SCNLight()
        fillLight.type = .directional
        fillLight.color = Palette.cyan
        fillLight.intensity = 80
        let fillNode = SCNNode()
        fillNode.light = fillLight
        fillNode.eulerAngles = SCNVector3(-Float.pi / 4, -Float.pi / 3, 0)
        scene.rootNode.addChildNode(fillNode)
        
        // Ambient — dark purple tint, low intensity for deep shadows
        let ambient = SCNLight()
        ambient.type = .ambient
        ambient.color = UIColor(red: 0.10, green: 0.06, blue: 0.18, alpha: 1)
        ambient.intensity = 350
        let ambientNode = SCNNode()
        ambientNode.light = ambient
        scene.rootNode.addChildNode(ambientNode)
    }
    
    // MARK: - Player
    private func setupPlayer() {
        // Cute robot packet character — replace with .usdz model later
        playerNode = SCNNode()
        
        // Body — rounded box with metallic finish
        let body = SCNBox(width: 0.9, height: 1.0, length: 0.9, chamferRadius: 0.25)
        let bodyMat = SCNMaterial()
        bodyMat.diffuse.contents = UIColor(red: 0.88, green: 0.90, blue: 0.92, alpha: 1)
        bodyMat.metalness.contents = 0.15
        bodyMat.roughness.contents = 0.55
        body.materials = [bodyMat]
        let bodyNode = SCNNode(geometry: body)
        bodyNode.name = "body"
        bodyNode.position = SCNVector3(0, 0.55, 0)
        
        // Head — slightly bigger rounded box
        let head = SCNBox(width: 0.95, height: 0.7, length: 0.85, chamferRadius: 0.2)
        let headMat = SCNMaterial()
        headMat.diffuse.contents = UIColor(red: 0.92, green: 0.93, blue: 0.95, alpha: 1)
        headMat.metalness.contents = 0.1
        headMat.roughness.contents = 0.5
        head.materials = [headMat]
        let headNode = SCNNode(geometry: head)
        headNode.position = SCNVector3(0, 1.4, 0)
        
        // Visor — glowing face plate
        let visor = SCNBox(width: 0.75, height: 0.35, length: 0.05, chamferRadius: 0.1)
        let visorMat = SCNMaterial()
        visorMat.diffuse.contents = UIColor.black
        visorMat.emission.contents = UIColor.black
        visorMat.transparency = 0.85
        visor.materials = [visorMat]
        let visorNode = SCNNode(geometry: visor)
        visorNode.position = SCNVector3(0, 1.38, 0.44)
        
        // Glowing eyes inside visor
        let eyeGeo = SCNSphere(radius: 0.08)
        let eyeMat = SCNMaterial()
        eyeMat.diffuse.contents = UIColor.black
        eyeMat.emission.contents = UIColor.black
        eyeGeo.materials = [eyeMat]
        
        let leftEye = SCNNode(geometry: eyeGeo)
        leftEye.position = SCNVector3(-0.18, 1.4, 0.42)
        let rightEye = SCNNode(geometry: eyeGeo)
        rightEye.position = SCNVector3(0.18, 1.4, 0.42)
        
        // Antenna on top
        let antennaStick = SCNCylinder(radius: 0.03, height: 0.3)
        let antennaMat = SCNMaterial()
        antennaMat.diffuse.contents = UIColor.lightGray
        antennaMat.metalness.contents = 0.8
        antennaStick.materials = [antennaMat]
        let antennaNode = SCNNode(geometry: antennaStick)
        antennaNode.position = SCNVector3(0, 1.9, 0)
        
        let antennaBall = SCNSphere(radius: 0.07)
        let abMat = SCNMaterial()
        abMat.diffuse.contents = Palette.magenta
        abMat.emission.contents = Palette.magenta
        antennaBall.materials = [abMat]
        let abNode = SCNNode(geometry: antennaBall)
        abNode.position = SCNVector3(0, 2.1, 0)
        
        // Neon accent stripe on body
        let stripe = SCNBox(width: 0.92, height: 0.06, length: 0.92, chamferRadius: 0.2)
        let stripeMat = SCNMaterial()
        stripeMat.diffuse.contents = Palette.cyan.withAlphaComponent(0.3)
        stripeMat.emission.contents = Palette.cyan
        stripe.materials = [stripeMat]
        let stripeNode = SCNNode(geometry: stripe)
        stripeNode.position = SCNVector3(0, 0.55, 0)
        
        // Ground glow ring
        let glowRing = SCNTorus(ringRadius: 0.6, pipeRadius: 0.04)
        let glowMat = SCNMaterial()
        glowMat.diffuse.contents = Palette.cyan.withAlphaComponent(0.2)
        glowMat.emission.contents = Palette.cyan
        glowMat.transparency = 0.5
        glowRing.materials = [glowMat]
        let glowNode = SCNNode(geometry: glowRing)
        glowNode.name = "glow"
        glowNode.position = SCNVector3(0, 0.02, 0)
        
        // Point light on player
        let playerLight = SCNLight()
        playerLight.type = .omni
        playerLight.color = Palette.cyan
        playerLight.intensity = 200
        playerLight.attenuationStartDistance = 1
        playerLight.attenuationEndDistance = 5
        let playerLightNode = SCNNode()
        playerLightNode.light = playerLight
        playerLightNode.position = SCNVector3(0, 1.5, 0)
        
        playerNode.addChildNode(bodyNode)
        playerNode.addChildNode(headNode)
        playerNode.addChildNode(visorNode)
        playerNode.addChildNode(leftEye)
        playerNode.addChildNode(rightEye)
        playerNode.addChildNode(antennaNode)
        playerNode.addChildNode(abNode)
        playerNode.addChildNode(stripeNode)
        playerNode.addChildNode(glowNode)
        playerNode.addChildNode(playerLightNode)
        playerNode.position = SCNVector3(0, 0, 0)
        
        // Idle hover animation
        let hover = SCNAction.sequence([
            SCNAction.moveBy(x: 0, y: 0.12, z: 0, duration: 0.8),
            SCNAction.moveBy(x: 0, y: -0.12, z: 0, duration: 0.8)
        ])
        bodyNode.runAction(SCNAction.repeatForever(hover))
        headNode.runAction(SCNAction.repeatForever(hover))
        
        // Glow pulse
        let pulse = SCNAction.sequence([
            SCNAction.scale(to: 1.12, duration: 0.9),
            SCNAction.scale(to: 1.0, duration: 0.9)
        ])
        glowNode.runAction(SCNAction.repeatForever(pulse))
        
        // Antenna blink
        let blink = SCNAction.sequence([
            SCNAction.fadeOpacity(to: 0.3, duration: 0.4),
            SCNAction.fadeOpacity(to: 1.0, duration: 0.4),
            SCNAction.wait(duration: 1.5)
        ])
        abNode.runAction(SCNAction.repeatForever(blink))
        
        scene.rootNode.addChildNode(playerNode)
    }
    
    // MARK: - Move Player
    func movePlayer(direction: CGVector, speed: Float = 0.15) {
        let dx = Float(direction.dx) * speed
        let dz = Float(direction.dy) * speed
        
        var newX = playerNode.position.x + dx
        var newZ = playerNode.position.z + dz
        
        // Clamp to world bounds
        let halfW = Float(worldBounds.width) / 2
        let halfH = Float(worldBounds.height) / 2
        newX = max(-halfW, min(halfW, newX))
        newZ = max(-halfH, min(halfH, newZ))
        
        // Obstacle collision — resolve each axis independently for sliding
        let r = playerRadius
        let oldX = playerNode.position.x
        let oldZ = playerNode.position.z
        
        // Try X movement
        var canMoveX = true
        for obs in obstacles {
            if (newX + r > obs.minX) && (newX - r < obs.maxX) &&
               (oldZ + r > obs.minZ) && (oldZ - r < obs.maxZ) {
                canMoveX = false
                break
            }
        }
        
        // Try Z movement
        var canMoveZ = true
        let testX = canMoveX ? newX : oldX
        for obs in obstacles {
            if (testX + r > obs.minX) && (testX - r < obs.maxX) &&
               (newZ + r > obs.minZ) && (newZ - r < obs.maxZ) {
                canMoveZ = false
                break
            }
        }
        
        let finalX = canMoveX ? newX : oldX
        let finalZ = canMoveZ ? newZ : oldZ
        
        playerNode.position = SCNVector3(finalX, playerNode.position.y, finalZ)
        
        // Rotate to face movement direction (quaternion slerp — no gimbal flip)
        if abs(dx) > 0.001 || abs(dz) > 0.001 {
            let angle = atan2(dx, dz)
            let target = simd_quatf(angle: angle, axis: simd_float3(0, 1, 0))
            playerNode.simdOrientation = simd_slerp(playerNode.simdOrientation, target, 0.25)
        }
        
        // Camera follow smoothly
        updateCameraFollow()
    }
    
    func updateCameraFollow() {
        let target = playerNode.position
        let smoothed = SCNVector3(
            cameraRig.position.x + (target.x - cameraRig.position.x) * 0.08,
            0,
            cameraRig.position.z + (target.z - cameraRig.position.z) * 0.08
        )
        cameraRig.position = smoothed
    }
    
    // MARK: - NPC Management
    func addNPC(id: UUID, type: NPCType, at position: SCNVector3) {
        let npcNode = createNPCNode(type: type)
        npcNode.position = position
        npcNodes[id] = npcNode
        scene.rootNode.addChildNode(npcNode)
    }
    
    func removeAllNPCs() {
        npcNodes.values.forEach { $0.removeFromParentNode() }
        npcNodes.removeAll()
    }
    
    func npcPosition(for id: UUID) -> SCNVector3? {
        npcNodes[id]?.position
    }
    
    private func createNPCNode(type: NPCType) -> SCNNode {
        let node = SCNNode()
        
        let accentColor: UIColor
        let bodyWidth: CGFloat
        let bodyHeight: CGFloat
        
        switch type {
        case .daemon:
            accentColor = Palette.cyan
            bodyWidth = 1.0; bodyHeight = 1.3
        case .firewall:
            accentColor = Palette.coral
            bodyWidth = 1.3; bodyHeight = 1.8
        case .routerGuard:
            accentColor = Palette.amber
            bodyWidth = 1.1; bodyHeight = 1.5
        case .librarian:
            accentColor = Palette.violet
            bodyWidth = 0.9; bodyHeight = 1.6
        case .networkManager:
            accentColor = Palette.lime
            bodyWidth = 1.2; bodyHeight = 1.4
        }
        
        // Body - dark metallic with accent glow
        let body = SCNBox(width: bodyWidth, height: bodyHeight, length: bodyWidth * 0.8, chamferRadius: bodyWidth * 0.2)
        let bodyMat = SCNMaterial()
        bodyMat.diffuse.contents = UIColor(red: 0.1, green: 0.1, blue: 0.15, alpha: 1)
        bodyMat.metalness.contents = 0.6
        bodyMat.roughness.contents = 0.3
        body.materials = [bodyMat]
        let bodyNode = SCNNode(geometry: body)
        bodyNode.position = SCNVector3(0, Float(bodyHeight / 2), 0)
        node.addChildNode(bodyNode)
        
        // Head
        let headSize = bodyWidth * 0.85
        let head = SCNBox(width: headSize, height: headSize * 0.7, length: headSize * 0.75, chamferRadius: headSize * 0.2)
        let headMat = SCNMaterial()
        headMat.diffuse.contents = UIColor(red: 0.12, green: 0.12, blue: 0.18, alpha: 1)
        headMat.metalness.contents = 0.5
        headMat.roughness.contents = 0.25
        head.materials = [headMat]
        let headNode = SCNNode(geometry: head)
        headNode.position = SCNVector3(0, Float(bodyHeight) + Float(headSize * 0.35), 0)
        node.addChildNode(headNode)
        
        // Glowing eyes
        let eyeGeo = SCNSphere(radius: 0.1)
        let eyeMat = SCNMaterial()
        eyeMat.diffuse.contents = accentColor
        eyeMat.emission.contents = accentColor
        eyeGeo.materials = [eyeMat]
        
        let eyeY = Float(bodyHeight) + Float(headSize * 0.35)
        let eyeZ = Float(headSize * 0.75 / 2) + 0.01
        let leftEye = SCNNode(geometry: eyeGeo)
        leftEye.position = SCNVector3(-0.2, eyeY, eyeZ)
        node.addChildNode(leftEye)
        let rightEye = SCNNode(geometry: eyeGeo)
        rightEye.position = SCNVector3(0.2, eyeY, eyeZ)
        node.addChildNode(rightEye)
        
        // Accent stripe across body
        let stripe = SCNBox(width: bodyWidth + 0.02, height: 0.08, length: bodyWidth * 0.8 + 0.02, chamferRadius: bodyWidth * 0.15)
        let stripeMat = SCNMaterial()
        stripeMat.diffuse.contents = accentColor.withAlphaComponent(0.3)
        stripeMat.emission.contents = accentColor
        stripe.materials = [stripeMat]
        let stripeNode = SCNNode(geometry: stripe)
        stripeNode.position = SCNVector3(0, Float(bodyHeight * 0.7), 0)
        node.addChildNode(stripeNode)
        
        // Ground glow
        let glow = SCNTorus(ringRadius: CGFloat(bodyWidth * 0.7), pipeRadius: 0.03)
        let glowMat = SCNMaterial()
        glowMat.diffuse.contents = accentColor.withAlphaComponent(0.2)
        glowMat.emission.contents = accentColor
        glowMat.transparency = 0.4
        glow.materials = [glowMat]
        let glowNode = SCNNode(geometry: glow)
        glowNode.position = SCNVector3(0, 0.02, 0)
        node.addChildNode(glowNode)
        
        // Point light
        let npcLight = SCNLight()
        npcLight.type = .omni
        npcLight.color = accentColor
        npcLight.intensity = 150
        npcLight.attenuationStartDistance = 1
        npcLight.attenuationEndDistance = 4
        let lightNode = SCNNode()
        lightNode.light = npcLight
        lightNode.position = SCNVector3(0, Float(bodyHeight * 0.5), 0)
        node.addChildNode(lightNode)
        
        // Hover animation
        let hover = SCNAction.sequence([
            SCNAction.moveBy(x: 0, y: 0.2, z: 0, duration: 1.3),
            SCNAction.moveBy(x: 0, y: -0.2, z: 0, duration: 1.3)
        ])
        bodyNode.runAction(SCNAction.repeatForever(hover))
        headNode.runAction(SCNAction.repeatForever(hover))
        
        // Quest Marker (Bouncing Yellow Indicator)
        let markerGeo = pyramidGeometry() // Custom pyramid/diamond shape
        let markerMat = SCNMaterial()
        markerMat.diffuse.contents = Palette.amber
        markerMat.emission.contents = Palette.amber
        markerGeo.materials = [markerMat]
        
        let markerNode = SCNNode(geometry: markerGeo)
        markerNode.name = "QuestMarker"
        // Start high above the head
        markerNode.position = SCNVector3(0, Float(headSize) * 2.5, 0)
        
        let bounce = SCNAction.sequence([
            SCNAction.moveBy(x: 0, y: 0.3, z: 0, duration: 0.6),
            SCNAction.moveBy(x: 0, y: -0.3, z: 0, duration: 0.6)
        ])
        bounce.timingMode = .easeInEaseOut
        markerNode.runAction(SCNAction.repeatForever(bounce))
        
        // Add a slow spin to the marker
        let spinMarker = SCNAction.rotateBy(x: 0, y: .pi * 2, z: 0, duration: 2.0)
        markerNode.runAction(SCNAction.repeatForever(spinMarker))
        
        node.addChildNode(markerNode)
        
        return node
    }
    
    // Helper to draw a simple diamond shape for the quest marker
    private func pyramidGeometry() -> SCNGeometry {
        let size: Float = 0.2
        let vertices: [SCNVector3] = [
            SCNVector3(0, size, 0),    // Top
            SCNVector3(-size, 0, size),  // Front Left
            SCNVector3(size, 0, size),   // Front Right
            SCNVector3(size, 0, -size),  // Back Right
            SCNVector3(-size, 0, -size), // Back Left
            SCNVector3(0, -size, 0)    // Bottom
        ]
        
        let source = SCNGeometrySource(vertices: vertices)
        let indices: [Int32] = [
            0, 1, 2,  0, 2, 3,  0, 3, 4,  0, 4, 1, // Top half
            5, 2, 1,  5, 3, 2,  5, 4, 3,  5, 1, 4  // Bottom half
        ]
        
        let element = SCNGeometryElement(indices: indices, primitiveType: .triangles)
        return SCNGeometry(sources: [source], elements: [element])
    }
    
    // MARK: - Portal Management
    func addPortal(id: UUID, at position: SCNVector3, color: UIColor = Palette.magenta) {
        let portal = SCNNode()
        
        // Portal arch frame
        let archOuter = SCNTorus(ringRadius: 1.5, pipeRadius: 0.12)
        let archMat = SCNMaterial()
        archMat.diffuse.contents = UIColor(red: 0.15, green: 0.12, blue: 0.2, alpha: 1)
        archMat.metalness.contents = 0.7
        archMat.roughness.contents = 0.3
        archOuter.materials = [archMat]
        let archNode = SCNNode(geometry: archOuter)
        archNode.position = SCNVector3(0, 1.5, 0)
        archNode.eulerAngles = SCNVector3(Float.pi / 2, 0, 0)
        portal.addChildNode(archNode)
        
        // Inner spinning ring — colored
        let innerRing = SCNTorus(ringRadius: 1.2, pipeRadius: 0.06)
        let innerMat = SCNMaterial()
        innerMat.diffuse.contents = color
        innerMat.emission.contents = color
        innerRing.materials = [innerMat]
        let innerNode = SCNNode(geometry: innerRing)
        innerNode.position = SCNVector3(0, 1.5, 0)
        innerNode.eulerAngles = SCNVector3(Float.pi / 2, 0, 0)
        portal.addChildNode(innerNode)
        
        // Portal fill — glowing disc
        let disc = SCNCylinder(radius: 1.1, height: 0.02)
        let discMat = SCNMaterial()
        discMat.diffuse.contents = color.withAlphaComponent(0.15)
        discMat.emission.contents = color
        discMat.transparency = 0.4
        discMat.isDoubleSided = true
        disc.materials = [discMat]
        let discNode = SCNNode(geometry: disc)
        discNode.position = SCNVector3(0, 1.5, 0)
        portal.addChildNode(discNode)
        
        // Light pillar
        let pillar = SCNCylinder(radius: 0.04, height: 5)
        let pillarMat = SCNMaterial()
        pillarMat.diffuse.contents = color.withAlphaComponent(0.15)
        pillarMat.emission.contents = color
        pillarMat.transparency = 0.3
        pillar.materials = [pillarMat]
        let pillarNode = SCNNode(geometry: pillar)
        pillarNode.position = SCNVector3(0, 2.5, 0)
        portal.addChildNode(pillarNode)
        
        // Portal light
        let portalLight = SCNLight()
        portalLight.type = .omni
        portalLight.color = color
        portalLight.intensity = 600
        portalLight.attenuationStartDistance = 1
        portalLight.attenuationEndDistance = 8
        let lightNode = SCNNode()
        lightNode.light = portalLight
        lightNode.position = SCNVector3(0, 1.5, 0)
        portal.addChildNode(lightNode)
        
        // Portal Text Label "ENTER"
        let textGeo = SCNText(string: "ENTER", extrusionDepth: 0.5)
        textGeo.font = UIFont.systemFont(ofSize: 5, weight: .bold)
        textGeo.firstMaterial?.diffuse.contents = UIColor.white
        textGeo.firstMaterial?.emission.contents = color
        
        let textNode = SCNNode(geometry: textGeo)
        // Scale it way down
        textNode.scale = SCNVector3(0.1, 0.1, 0.1)
        
        // Center the text
        let (minVec, maxVec) = textNode.boundingBox
        textNode.pivot = SCNMatrix4MakeTranslation(
            (maxVec.x - minVec.x) / 2 + minVec.x,
            (maxVec.y - minVec.y) / 2 + minVec.y,
            0
        )
        textNode.position = SCNVector3(0, 3.5, 0) // float above the portal
        portal.addChildNode(textNode)
        
        // Spin animation
        let spin = SCNAction.rotateBy(x: 0, y: CGFloat.pi * 2, z: 0, duration: 3)
        innerNode.runAction(SCNAction.repeatForever(spin))
        
        // Disc pulse
        let discPulse = SCNAction.sequence([
            SCNAction.fadeOpacity(to: 0.6, duration: 1.0),
            SCNAction.fadeOpacity(to: 1.0, duration: 1.0)
        ])
        discNode.runAction(SCNAction.repeatForever(discPulse))
        
        portal.position = position
        portalNodes[id] = portal
        // Gentle floating animation for the whole portal
        let floatAction = SCNAction.sequence([
            SCNAction.moveBy(x: 0, y: 0.2, z: 0, duration: 1.5),
            SCNAction.moveBy(x: 0, y: -0.2, z: 0, duration: 1.5)
        ])
        floatAction.timingMode = .easeInEaseOut
        portal.runAction(SCNAction.repeatForever(floatAction))
        scene.rootNode.addChildNode(portal)
    }
    
    func removeAllPortals() {
        portalNodes.values.forEach { $0.removeFromParentNode() }
        portalNodes.removeAll()
    }
    
    // MARK: - Distance Checking (3D → 2D projected)
    func distanceToPlayer(from position: SCNVector3) -> Float {
        let dx = playerNode.position.x - position.x
        let dz = playerNode.position.z - position.z
        return sqrt(dx * dx + dz * dz)
    }
    
    func nearestNPCInRange(range: Float = 3.0) -> UUID? {
        var closest: (UUID, Float)? = nil
        for (id, node) in npcNodes {
            let dist = distanceToPlayer(from: node.position)
            if dist < range {
                if closest == nil || dist < closest!.1 {
                    closest = (id, dist)
                }
            }
        }
        return closest?.0
    }
    
    func nearestPortalInRange(range: Float = 2.5) -> UUID? {
        var closest: (UUID, Float)? = nil
        for (id, node) in portalNodes {
            let dist = distanceToPlayer(from: node.position)
            if dist < range {
                if closest == nil || dist < closest!.1 {
                    closest = (id, dist)
                }
            }
        }
        return closest?.0
    }
    
    // MARK: - Quest Marker Management
    func hideQuestMarker(for id: UUID) {
        if let npcNode = npcNodes[id],
           let marker = npcNode.childNode(withName: "QuestMarker", recursively: false) {
            
            // Fade out and remove
            let fadeOut = SCNAction.sequence([
                SCNAction.moveBy(x: 0, y: 0.5, z: 0, duration: 0.4),
                SCNAction.fadeOut(duration: 0.4),
                SCNAction.removeFromParentNode()
            ])
            marker.runAction(fadeOut)
        }
    }
    
    // MARK: - Clear Scene Content (keep player, camera, lights)
    func clearSceneContent() {
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 0
        
        // Restore camera to default outdoor position
        resetCameraToDefault()
        
        removeAllNPCs()
        removeAllPortals()
        obstacles.removeAll()
        floorNode?.removeFromParentNode()
        
        // Snapshot array first to avoid mutating while iterating
        let children = Array(scene.rootNode.childNodes)
        for child in children {
            if child == playerNode || child == cameraRig { continue }
            if child.light != nil { continue }
            child.removeFromParentNode()
        }
        
        SCNTransaction.commit()
    }
    
    // Default camera settings (outdoor scenes)
    private let defaultCameraPosition = SCNVector3(0, 14, 12)
    private let defaultCameraAngle = SCNVector3(-Float.pi / 3.5, 0, 0)
    
    /// Override camera for indoor / enclosed scenes (e.g. Router Station).
    func setCameraOverride(position: SCNVector3, eulerAngles: SCNVector3) {
        cameraNode.position = position
        cameraNode.eulerAngles = eulerAngles
    }
    
    /// Restore camera to default (called during scene clear).
    func resetCameraToDefault() {
        cameraNode.position = defaultCameraPosition
        cameraNode.eulerAngles = defaultCameraAngle
    }
    
    // MARK: - Reset Player Position
    func resetPlayerPosition(to pos: SCNVector3 = SCNVector3(0, 0, 0)) {
        playerNode.position = pos
        cameraRig.position = SCNVector3(pos.x, 0, pos.z)
    }
    
    // MARK: - Gradient Sky Generator
    /// Creates a vertical-gradient UIImage suitable for `scene.background.contents`
    /// and `scene.lightingEnvironment.contents`.
    static func makeGradientSky(
        topColor: UIColor,
        midColor: UIColor,
        bottomColor: UIColor,
        size: CGSize = CGSize(width: 1, height: 512)
    ) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            let colors = [topColor.cgColor, midColor.cgColor, bottomColor.cgColor] as CFArray
            let locations: [CGFloat] = [0.0, 0.45, 1.0]
            guard let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                            colors: colors,
                                            locations: locations) else { return }
            ctx.cgContext.drawLinearGradient(
                gradient,
                start: CGPoint(x: size.width / 2, y: 0),
                end: CGPoint(x: size.width / 2, y: size.height),
                options: [.drawsBeforeStartLocation, .drawsAfterEndLocation]
            )
        }
    }
}

