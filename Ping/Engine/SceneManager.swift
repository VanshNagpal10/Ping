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
        scene.fogStartDistance = 40
        scene.fogEndDistance = 80
        scene.fogColor = Palette.void
    }
    
    // MARK: - Camera
    private func setupCamera() {
        let camera = SCNCamera()
        camera.fieldOfView = 45
        camera.zNear = 0.1
        camera.zFar = 200
        // Bloom / HDR
        camera.wantsHDR = true
        camera.bloomIntensity = 0.6
        camera.bloomThreshold = 0.7
        camera.bloomBlurRadius = 8
        camera.wantsExposureAdaptation = false
        camera.exposureOffset = 0
        
        cameraNode = SCNNode()
        cameraNode.camera = camera
        cameraNode.position = SCNVector3(0, 18, 14)
        cameraNode.eulerAngles = SCNVector3(-Float.pi / 3.2, 0, 0)
        
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
        keyLight.shadowRadius = 4
        keyLight.shadowSampleCount = 8
        keyLight.shadowColor = UIColor.black.withAlphaComponent(0.6)
        let keyNode = SCNNode()
        keyNode.light = keyLight
        keyNode.eulerAngles = SCNVector3(-Float.pi / 3, Float.pi / 5, 0)
        scene.rootNode.addChildNode(keyNode)
        
        // Fill light — cool cyan from left
        let fillLight = SCNLight()
        fillLight.type = .directional
        fillLight.color = Palette.cyan
        fillLight.intensity = 200
        let fillNode = SCNNode()
        fillNode.light = fillLight
        fillNode.eulerAngles = SCNVector3(-Float.pi / 4, -Float.pi / 3, 0)
        scene.rootNode.addChildNode(fillNode)
        
        // Ambient
        let ambient = SCNLight()
        ambient.type = .ambient
        ambient.color = UIColor(red: 0.15, green: 0.10, blue: 0.25, alpha: 1)
        ambient.intensity = 300
        let ambientNode = SCNNode()
        ambientNode.light = ambient
        scene.rootNode.addChildNode(ambientNode)
    }
    
    // MARK: - Player
    private func setupPlayer() {
        // Placeholder cube character — will be replaced with .usdz model
        playerNode = SCNNode()
        
        // Body — rounded box
        let body = SCNBox(width: 1.0, height: 1.0, length: 1.0, chamferRadius: 0.2)
        let bodyMat = SCNMaterial()
        bodyMat.diffuse.contents = Palette.cyan
        bodyMat.emission.contents = UIColor(red: 0.0, green: 0.3, blue: 0.4, alpha: 1)
        bodyMat.roughness.contents = 0.3
        bodyMat.metalness.contents = 0.1
        body.materials = [bodyMat]
        let bodyNode = SCNNode(geometry: body)
        bodyNode.name = "body"
        bodyNode.position = SCNVector3(0, 0.5, 0)
        
        // Face — tiny sphere eyes
        let eyeGeo = SCNSphere(radius: 0.1)
        let eyeMat = SCNMaterial()
        eyeMat.diffuse.contents = UIColor.white
        eyeMat.emission.contents = UIColor.white
        eyeGeo.materials = [eyeMat]
        
        let leftEye = SCNNode(geometry: eyeGeo)
        leftEye.position = SCNVector3(-0.2, 0.6, 0.5)
        let rightEye = SCNNode(geometry: eyeGeo)
        rightEye.position = SCNVector3(0.2, 0.6, 0.5)
        
        // Pupil
        let pupilGeo = SCNSphere(radius: 0.06)
        let pupilMat = SCNMaterial()
        pupilMat.diffuse.contents = UIColor.black
        pupilGeo.materials = [pupilMat]
        let leftPupil = SCNNode(geometry: pupilGeo)
        leftPupil.position = SCNVector3(0, 0, 0.06)
        leftEye.addChildNode(leftPupil)
        let rightPupil = SCNNode(geometry: pupilGeo)
        rightPupil.position = SCNVector3(0, 0, 0.06)
        rightEye.addChildNode(rightPupil)
        
        // Mouth
        let mouthGeo = SCNCapsule(capRadius: 0.04, height: 0.2)
        let mouthMat = SCNMaterial()
        mouthMat.diffuse.contents = UIColor(red: 0.15, green: 0.1, blue: 0.1, alpha: 1)
        mouthGeo.materials = [mouthMat]
        let mouthNode = SCNNode(geometry: mouthGeo)
        mouthNode.position = SCNVector3(0, 0.3, 0.5)
        mouthNode.eulerAngles = SCNVector3(0, 0, Float.pi / 2)
        
        // Glow halo under feet
        let glowRing = SCNTorus(ringRadius: 0.7, pipeRadius: 0.05)
        let glowMat = SCNMaterial()
        glowMat.diffuse.contents = Palette.cyan
        glowMat.emission.contents = Palette.cyan
        glowMat.transparency = 0.6
        glowRing.materials = [glowMat]
        let glowNode = SCNNode(geometry: glowRing)
        glowNode.name = "glow"
        glowNode.position = SCNVector3(0, 0.02, 0)
        
        playerNode.addChildNode(bodyNode)
        playerNode.addChildNode(leftEye)
        playerNode.addChildNode(rightEye)
        playerNode.addChildNode(mouthNode)
        playerNode.addChildNode(glowNode)
        playerNode.position = SCNVector3(0, 0, 0)
        
        // Idle bounce animation
        let bounce = SCNAction.sequence([
            SCNAction.moveBy(x: 0, y: 0.15, z: 0, duration: 0.6),
            SCNAction.moveBy(x: 0, y: -0.15, z: 0, duration: 0.6)
        ])
        bodyNode.runAction(SCNAction.repeatForever(bounce))
        
        // Glow pulse
        let pulse = SCNAction.sequence([
            SCNAction.scale(to: 1.15, duration: 0.8),
            SCNAction.scale(to: 1.0, duration: 0.8)
        ])
        glowNode.runAction(SCNAction.repeatForever(pulse))
        
        scene.rootNode.addChildNode(playerNode)
    }
    
    // MARK: - Move Player
    func movePlayer(direction: CGVector, speed: Float = 0.15) {
        let dx = Float(direction.dx) * speed
        let dz = Float(direction.dy) * speed
        
        let newX = playerNode.position.x + dx
        let newZ = playerNode.position.z + dz
        
        // Clamp to world bounds
        let halfW = Float(worldBounds.width) / 2
        let halfH = Float(worldBounds.height) / 2
        let clampedX = max(-halfW, min(halfW, newX))
        let clampedZ = max(-halfH, min(halfH, newZ))
        
        playerNode.position = SCNVector3(clampedX, playerNode.position.y, clampedZ)
        
        // Rotate to face movement direction
        if abs(dx) > 0.001 || abs(dz) > 0.001 {
            let angle = atan2(dx, dz)
            let rotateAction = SCNAction.rotateTo(
                x: 0,
                y: CGFloat(angle),
                z: 0,
                duration: 0.15,
                usesShortestUnitArc: true
            )
            playerNode.runAction(rotateAction, forKey: "rotate")
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
        
        let color: UIColor
        let shape: SCNGeometry
        let halfHeight: Float  // Used for positioning instead of boundingSphere
        
        switch type {
        case .daemon:
            color = Palette.cyan
            shape = SCNBox(width: 1.2, height: 1.5, length: 1.2, chamferRadius: 0.15)
            halfHeight = 0.75
        case .firewall:
            color = Palette.coral
            shape = SCNBox(width: 1.5, height: 2.0, length: 0.4, chamferRadius: 0.1)
            halfHeight = 1.0
        case .routerGuard:
            color = Palette.amber
            shape = SCNCylinder(radius: 0.6, height: 1.8)
            halfHeight = 0.9
        case .librarian:
            color = Palette.violet
            shape = SCNCapsule(capRadius: 0.5, height: 1.8)
            halfHeight = 0.9
        case .networkManager:
            color = Palette.lime
            shape = SCNBox(width: 1.3, height: 1.6, length: 1.3, chamferRadius: 0.3)
            halfHeight = 0.8
        }
        
        let mat = SCNMaterial()
        mat.diffuse.contents = color
        mat.emission.contents = color.withAlphaComponent(0.3)
        mat.roughness.contents = 0.4
        shape.materials = [mat]
        
        let bodyNode = SCNNode(geometry: shape)
        bodyNode.position = SCNVector3(0, halfHeight, 0)
        node.addChildNode(bodyNode)
        
        // Eyes
        let eyeGeo = SCNSphere(radius: 0.12)
        let eyeMat = SCNMaterial()
        eyeMat.diffuse.contents = UIColor.white
        eyeMat.emission.contents = UIColor.white
        eyeGeo.materials = [eyeMat]
        
        let eyeY = halfHeight + 0.45
        let leftEye = SCNNode(geometry: eyeGeo)
        leftEye.position = SCNVector3(-0.25, eyeY, 0.55)
        node.addChildNode(leftEye)
        let rightEye = SCNNode(geometry: eyeGeo)
        rightEye.position = SCNVector3(0.25, eyeY, 0.55)
        node.addChildNode(rightEye)
        
        // Interaction ring
        let ring = SCNTorus(ringRadius: 1.2, pipeRadius: 0.03)
        let ringMat = SCNMaterial()
        ringMat.diffuse.contents = Palette.amber
        ringMat.emission.contents = Palette.amber
        ringMat.transparency = 0.5
        ring.materials = [ringMat]
        let ringNode = SCNNode(geometry: ring)
        ringNode.name = "interactRing"
        ringNode.position = SCNVector3(0, 0.02, 0)
        node.addChildNode(ringNode)
        
        // Hover animation
        let hover = SCNAction.sequence([
            SCNAction.moveBy(x: 0, y: 0.3, z: 0, duration: 1.2),
            SCNAction.moveBy(x: 0, y: -0.3, z: 0, duration: 1.2)
        ])
        bodyNode.runAction(SCNAction.repeatForever(hover))
        
        // Ring pulse
        let ringPulse = SCNAction.sequence([
            SCNAction.scale(to: 1.1, duration: 0.8),
            SCNAction.scale(to: 1.0, duration: 0.8)
        ])
        ringNode.runAction(SCNAction.repeatForever(ringPulse))
        
        return node
    }
    
    // MARK: - Portal Management
    func addPortal(id: UUID, at position: SCNVector3, color: UIColor = Palette.magenta) {
        let portal = SCNNode()
        
        // Outer ring
        let torus = SCNTorus(ringRadius: 0.8, pipeRadius: 0.1)
        let torusMat = SCNMaterial()
        torusMat.diffuse.contents = color
        torusMat.emission.contents = color
        torusMat.transparency = 0.8
        torus.materials = [torusMat]
        let torusNode = SCNNode(geometry: torus)
        torusNode.position = SCNVector3(0, 1.0, 0)
        torusNode.eulerAngles = SCNVector3(Float.pi / 2, 0, 0)
        portal.addChildNode(torusNode)
        
        // Inner glow disc
        let disc = SCNCylinder(radius: 0.6, height: 0.02)
        let discMat = SCNMaterial()
        discMat.diffuse.contents = color.withAlphaComponent(0.3)
        discMat.emission.contents = color
        discMat.transparency = 0.5
        disc.materials = [discMat]
        let discNode = SCNNode(geometry: disc)
        discNode.position = SCNVector3(0, 1.0, 0)
        portal.addChildNode(discNode)
        
        // Light pillar
        let pillar = SCNCylinder(radius: 0.05, height: 4)
        let pillarMat = SCNMaterial()
        pillarMat.diffuse.contents = color.withAlphaComponent(0.2)
        pillarMat.emission.contents = color
        pillarMat.transparency = 0.4
        pillar.materials = [pillarMat]
        let pillarNode = SCNNode(geometry: pillar)
        pillarNode.position = SCNVector3(0, 2.0, 0)
        portal.addChildNode(pillarNode)
        
        // Point light for glow effect
        let portalLight = SCNLight()
        portalLight.type = .omni
        portalLight.color = color
        portalLight.intensity = 400
        portalLight.attenuationStartDistance = 1
        portalLight.attenuationEndDistance = 6
        let lightNode = SCNNode()
        lightNode.light = portalLight
        lightNode.position = SCNVector3(0, 1.5, 0)
        portal.addChildNode(lightNode)
        
        // Spin animation
        let spin = SCNAction.rotateBy(x: 0, y: CGFloat.pi * 2, z: 0, duration: 4)
        torusNode.runAction(SCNAction.repeatForever(spin))
        
        portal.position = position
        portalNodes[id] = portal
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
    
    // MARK: - Clear Scene Content (keep player, camera, lights)
    func clearSceneContent() {
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 0
        
        removeAllNPCs()
        removeAllPortals()
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
    
    // MARK: - Reset Player Position
    func resetPlayerPosition(to pos: SCNVector3 = SCNVector3(0, 0, 0)) {
        playerNode.position = pos
        cameraRig.position = SCNVector3(pos.x, 0, pos.z)
    }
}

