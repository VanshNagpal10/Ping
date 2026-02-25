//
//  WorldBuilder.swift
//  Ping - Packet World
//
//  Builds unique 3D diorama environments for each story scene.
//  Neon cyberpunk aesthetic — dark voids with glowing structures.
//

import SceneKit
import SwiftUI

struct WorldBuilder {
    
    typealias P = SceneManager.Palette
    
    // MARK: - Public API
    static func buildScene(_ scene: StoryScene, in manager: SceneManager) {
        manager.clearSceneContent()
        
        switch scene {
            case .cpuCity:       buildCPUCity(in: manager)
            case .wifiAntenna:   buildWiFiAntenna(in: manager)
            case .routerStation: buildRouterStation(in: manager)
            case .oceanCable:    buildOceanCable(in: manager)
            case .dnsLibrary:    buildDNSLibrary(in: manager)
            case .returnJourney: buildReturnJourney(in: manager)
            default:             buildDefaultFloor(in: manager)
        }
    }
    
    // MARK: - Shared Helpers
    
    /// Creates a massive seamless ground plane that extends far beyond the play area,
    /// making the world feel infinite. Grid lines fade out toward edges.
    private static func makeGroundPlane(
        width: CGFloat = 40,
        length: CGFloat = 30,
        baseColor: UIColor = P.floorBase, // Will be overridden in CPU City
        accentColor: UIColor = P.cyan,
        secondaryGridColor: UIColor = UIColor.white.withAlphaComponent(0.3)
    ) -> SCNNode {
        let floor = SCNNode()
        
        // Massive base plane — extends far beyond play area so edges are never visible
        let visibleSize: CGFloat = 200
        let plane = SCNPlane(width: visibleSize, height: visibleSize)
        let baseMat = SCNMaterial()
        baseMat.diffuse.contents = baseColor
        baseMat.roughness.contents = 0.25 // Slightly rougher so color shows better
        baseMat.metalness.contents = 0.60 // Less metallic, more matte
        plane.materials = [baseMat]
        let baseNode = SCNNode(geometry: plane)
        baseNode.eulerAngles = SCNVector3(-Float.pi / 2, 0, 0)
        baseNode.position = SCNVector3(0, -0.01, 0)
        baseNode.castsShadow = false
        baseNode.geometry?.firstMaterial?.writesToDepthBuffer = true
        floor.addChildNode(baseNode)
        
        let gridExtent: Float = 50 // grid extends well past play area
        let fadeStart: Float = Float(min(width, length)) / 2  // start fading at play-area edge
        
        // Secondary tighter white grid
        let secSpacing: Float = 1.0
        var sx: Float = -gridExtent
        while sx <= gridExtent {
            let distFromCenter = abs(sx)
            let alpha: CGFloat = distFromCenter > fadeStart
                ? CGFloat(max(0, 1.0 - (distFromCenter - fadeStart) / 10.0)) * 0.15
                : 0.15
            guard alpha > 0.005 else { sx += secSpacing; continue }
            let lineMat = SCNMaterial()
            lineMat.diffuse.contents = secondaryGridColor.withAlphaComponent(alpha)
            lineMat.emission.contents = secondaryGridColor.withAlphaComponent(alpha)
            let line = SCNBox(width: 0.008, height: 0.001, length: CGFloat(gridExtent * 2), chamferRadius: 0)
            line.materials = [lineMat]
            let node = SCNNode(geometry: line)
            node.position = SCNVector3(sx, 0.001, 0)
            floor.addChildNode(node)
            sx += secSpacing
        }
        var sz: Float = -gridExtent
        while sz <= gridExtent {
            let distFromCenter = abs(sz)
            let alpha: CGFloat = distFromCenter > fadeStart
                ? CGFloat(max(0, 1.0 - (distFromCenter - fadeStart) / 10.0)) * 0.15
                : 0.15
            guard alpha > 0.005 else { sz += secSpacing; continue }
            let lineMat = SCNMaterial()
            lineMat.diffuse.contents = secondaryGridColor.withAlphaComponent(alpha)
            lineMat.emission.contents = secondaryGridColor.withAlphaComponent(alpha)
            let line = SCNBox(width: CGFloat(gridExtent * 2), height: 0.001, length: 0.008, chamferRadius: 0)
            line.materials = [lineMat]
            let node = SCNNode(geometry: line)
            node.position = SCNVector3(0, 0.001, sz)
            floor.addChildNode(node)
            sz += secSpacing
        }
        
        // Primary Accent Grid lines — concentrated in the play area, fading out beyond it
        let spacing: Float = 4.0
        var x: Float = -gridExtent
        while x <= gridExtent {
            let distFromCenter = abs(x)
            let alpha: CGFloat = distFromCenter > fadeStart
                ? CGFloat(max(0, 1.0 - (distFromCenter - fadeStart) / 20.0)) * 0.12
                : 0.12 // slightly brighter
            guard alpha > 0.005 else { x += spacing; continue }
            let lineMat = SCNMaterial()
            lineMat.diffuse.contents = accentColor.withAlphaComponent(alpha)
            lineMat.emission.contents = accentColor.withAlphaComponent(alpha * 1.8)
            let line = SCNBox(width: 0.025, height: 0.003, length: CGFloat(gridExtent * 2), chamferRadius: 0)
            line.materials = [lineMat]
            let node = SCNNode(geometry: line)
            node.position = SCNVector3(x, 0.003, 0)
            floor.addChildNode(node)
            x += spacing
        }
        var z: Float = -gridExtent
        while z <= gridExtent {
            let distFromCenter = abs(z)
            let alpha: CGFloat = distFromCenter > fadeStart
                ? CGFloat(max(0, 1.0 - (distFromCenter - fadeStart) / 20.0)) * 0.12
                : 0.12
            guard alpha > 0.005 else { z += spacing; continue }
            let lineMat = SCNMaterial()
            lineMat.diffuse.contents = accentColor.withAlphaComponent(alpha)
            lineMat.emission.contents = accentColor.withAlphaComponent(alpha * 1.8)
            let line = SCNBox(width: CGFloat(gridExtent * 2), height: 0.003, length: 0.025, chamferRadius: 0)
            line.materials = [lineMat]
            let node = SCNNode(geometry: line)
            node.position = SCNVector3(0, 0.003, z)
            floor.addChildNode(node)
            z += spacing
        }
        
        return floor
    }
    
    /// Register a box-shaped obstacle with the SceneManager for collision
    private static func registerBox(_ manager: SceneManager, x: Float, z: Float, w: CGFloat, l: CGFloat) {
        manager.registerObstacle(x: x, z: z, halfW: Float(w / 2), halfL: Float(l / 2))
    }
    
    /// Dark metallic structure with thin LED indicator strips (like server racks)
    private static func makeBuilding(
        width: CGFloat, height: CGFloat, length: CGFloat,
        color: UIColor, emissionColor: UIColor,
        at position: SCNVector3
    ) -> SCNNode {
        // 1. The Main Body is now Dark Metal, NOT glowing neon
        let box = SCNBox(width: width, height: height, length: length, chamferRadius: 0.04)
        let mat = SCNMaterial()
        mat.diffuse.contents = UIColor(red: 0.06, green: 0.06, blue: 0.09, alpha: 1.0) // Very dark grey/blue
        mat.metalness.contents = 0.8   // Highly metallic
        mat.roughness.contents = 0.25  // Slightly glossy to catch the neon lights
        box.materials = [mat]
        
        let node = SCNNode(geometry: box)
        node.position = SCNVector3(position.x, position.y + Float(height / 2), position.z)
        
        // 2. Subtle neon edge wireframe (This provides the Cyberpunk outline)
        let wireBox = SCNBox(width: width + 0.02, height: height + 0.02, length: length + 0.02, chamferRadius: 0.05)
        let wireMat = SCNMaterial()
        wireMat.diffuse.contents = UIColor.clear
        wireMat.emission.contents = emissionColor // Glowing color
        wireMat.fillMode = .lines
        wireMat.transparency = 0.9 // Brighter edges
        wireBox.materials = [wireMat]
        let wireNode = SCNNode(geometry: wireBox)
        node.addChildNode(wireNode)
        
        // 3. Thin horizontal LED indicator strips
        let stripCount = max(1, Int(height) - 1)
        for i in 0..<stripCount {
            let stripW = width * 0.6
            let strip = SCNBox(width: stripW, height: 0.03, length: 0.005, chamferRadius: 0)
            let sMat = SCNMaterial()
            let stripColor = (i % 3 == 0) ? P.magenta : emissionColor
            sMat.diffuse.contents = stripColor
            sMat.emission.contents = stripColor // Make the strips glow bright
            strip.materials = [sMat]
            let sNode = SCNNode(geometry: strip)
            sNode.position = SCNVector3(0, Float(i) * 0.8 - Float(height / 2) + 0.6, Float(length / 2) + 0.005)
            node.addChildNode(sNode)
        }
        
        return node
    }
    
    /// Horizontal neon pipe (decorative element for walls/ceilings)
    private static func makePipe(from start: SCNVector3, to end: SCNVector3, radius: CGFloat = 0.06, color: UIColor) -> SCNNode {
        let dx = end.x - start.x
        let dy = end.y - start.y
        let dz = end.z - start.z
        let length = sqrt(dx * dx + dy * dy + dz * dz)
        
        let cyl = SCNCylinder(radius: radius, height: CGFloat(length))
        let mat = SCNMaterial()
        mat.diffuse.contents = UIColor(red: 0.15, green: 0.13, blue: 0.2, alpha: 1)
        mat.metalness.contents = 0.7
        mat.roughness.contents = 0.35
        cyl.materials = [mat]
        let node = SCNNode(geometry: cyl)
        node.position = SCNVector3(
            (start.x + end.x) / 2,
            (start.y + end.y) / 2,
            (start.z + end.z) / 2
        )
        
        // Align cylinder
        if abs(dx) > abs(dz) {
            node.eulerAngles = SCNVector3(0, 0, Float.pi / 2)
        } else if abs(dz) > abs(dx) {
            node.eulerAngles = SCNVector3(Float.pi / 2, 0, 0)
        }
        
        // Glowing band on pipe
        let band = SCNCylinder(radius: radius + 0.01, height: 0.1)
        let bandMat = SCNMaterial()
        bandMat.diffuse.contents = color
        bandMat.emission.contents = color
        band.materials = [bandMat]
        let bandNode = SCNNode(geometry: band)
        node.addChildNode(bandNode)
        
        return node
    }
    
    /// Glowing pillar
    private static func makePillar(radius: CGFloat, height: CGFloat, color: UIColor, at position: SCNVector3) -> SCNNode {
        let cyl = SCNCylinder(radius: radius, height: height)
        let mat = SCNMaterial()
        mat.diffuse.contents = UIColor(red: 0.12, green: 0.1, blue: 0.18, alpha: 1)
        mat.metalness.contents = 0.6
        mat.roughness.contents = 0.3
        cyl.materials = [mat]
        let node = SCNNode(geometry: cyl)
        node.position = SCNVector3(position.x, position.y + Float(height / 2), position.z)
        
        // Accent ring at top
        let ring = SCNTorus(ringRadius: radius + 0.05, pipeRadius: 0.02)
        let ringMat = SCNMaterial()
        ringMat.diffuse.contents = color
        ringMat.emission.contents = color
        ring.materials = [ringMat]
        let ringNode = SCNNode(geometry: ring)
        ringNode.position = SCNVector3(0, Float(height / 2), 0)
        node.addChildNode(ringNode)
        
        return node
    }
    
    /// Neon sign billboard — replaces SCNText (which crashes on background threads)
    private static func makeSignPanel(color: UIColor, width: CGFloat = 6, height: CGFloat = 1.5, at position: SCNVector3) -> SCNNode {
        let panel = SCNBox(width: width, height: height, length: 0.05, chamferRadius: 0.05)
        let mat = SCNMaterial()
        mat.diffuse.contents = color.withAlphaComponent(0.15)
        mat.emission.contents = color
        mat.transparency = 0.8
        panel.materials = [mat]
        let node = SCNNode(geometry: panel)
        node.position = position
        
        // Subtle pulse
        let fadeIn = SCNAction.fadeOpacity(to: 1.0, duration: 1.2)
        let fadeOut = SCNAction.fadeOpacity(to: 0.6, duration: 1.2)
        node.runAction(SCNAction.repeatForever(SCNAction.sequence([fadeIn, fadeOut])))
        
        return node
    }
    
    /// Floating data particle
    private static func makeDataParticle(color: UIColor, at position: SCNVector3, size: CGFloat = 0.15) -> SCNNode {
        let sphere = SCNSphere(radius: size)
        let mat = SCNMaterial()
        mat.diffuse.contents = color
        mat.emission.contents = color
        sphere.materials = [mat]
        let node = SCNNode(geometry: sphere)
        node.position = position
        
        // Float animation
        let floatUp = SCNAction.moveBy(x: 0, y: CGFloat.random(in: 0.5...1.5), z: 0, duration: Double.random(in: 2...4))
        let floatDown = floatUp.reversed()
        node.runAction(SCNAction.repeatForever(SCNAction.sequence([floatUp, floatDown])))
        
        return node
    }
    
    /// Ambient NPC packet — mini robot similar to player but smaller, flowing in a direction
    private static func makeAmbientPacket(in root: SCNNode, bounds: CGSize, accentColor: UIColor, yRange: ClosedRange<Float> = 0.0...0.0, flowDirection: SCNVector3 = SCNVector3(1, 0, 0)) {
        let colors: [UIColor] = [P.cyan, P.magenta, P.amber, P.lime, P.violet, P.coral]
        let count = Int.random(in: 8...14)
        let halfW = max(1, Float(bounds.width) / 2 - 2)
        let halfH = max(1, Float(bounds.height) / 2 - 2)
        let yMin = yRange.lowerBound == 0 && yRange.upperBound == 0 ? Float(0) : yRange.lowerBound
        let yMax = yRange.lowerBound == 0 && yRange.upperBound == 0 ? Float(0) : yRange.upperBound
        
        // --- OPTIMIZATION: Create base geometries ONCE ---
        let baseBody = SCNBox(width: 0.6, height: 0.7, length: 0.5, chamferRadius: 0.1)
        let bodyMat = SCNMaterial()
        bodyMat.diffuse.contents = UIColor(red: 0.12, green: 0.1, blue: 0.2, alpha: 1)
        bodyMat.metalness.contents = 0.5
        bodyMat.roughness.contents = 0.3
        baseBody.materials = [bodyMat]
        
        let baseHead = SCNBox(width: 0.5, height: 0.35, length: 0.4, chamferRadius: 0.1)
        let headMat = SCNMaterial()
        headMat.diffuse.contents = UIColor(red: 0.14, green: 0.12, blue: 0.24, alpha: 1)
        headMat.metalness.contents = 0.5
        baseHead.materials = [headMat]
        
        let baseEye = SCNSphere(radius: 0.03)
        let baseStripe = SCNBox(width: 0.62, height: 0.03, length: 0.52, chamferRadius: 0.1)
        let baseVisor = SCNBox(width: 0.38, height: 0.16, length: 0.02, chamferRadius: 0.04)
        // --------------------------------------------------
        
        for i in 0..<count {
            let color = colors[i % colors.count]
            let scale = Float.random(in: 0.25...0.4)
            let packetNode = SCNNode()
            
            // Body
            let bodyNode = SCNNode(geometry: baseBody)
            bodyNode.position = SCNVector3(0, 0.35, 0)
            packetNode.addChildNode(bodyNode)
            
            // Head
            let headNode = SCNNode(geometry: baseHead)
            headNode.position = SCNVector3(0, 0.78, 0)
            packetNode.addChildNode(headNode)
            
            // Visor (Needs unique material per color)
            let visorMat = SCNMaterial()
            visorMat.diffuse.contents = color.withAlphaComponent(0.3)
            visorMat.emission.contents = color
            let visorNode = SCNNode(geometry: baseVisor)
            visorNode.geometry?.materials = [visorMat]
            visorNode.position = SCNVector3(0, 0.76, 0.22)
            packetNode.addChildNode(visorNode)
            
            // Eyes (Needs unique material per color)
            let eyeMat = SCNMaterial()
            eyeMat.diffuse.contents = color
            eyeMat.emission.contents = color
            
            let leftEye = SCNNode(geometry: baseEye)
            leftEye.geometry?.materials = [eyeMat]
            leftEye.position = SCNVector3(-0.08, 0.78, 0.21)
            
            let rightEye = SCNNode(geometry: baseEye)
            rightEye.geometry?.materials = [eyeMat]
            rightEye.position = SCNVector3(0.08, 0.78, 0.21)
            
            packetNode.addChildNode(leftEye)
            packetNode.addChildNode(rightEye)
            
            // Stripe
            let stripeMat = SCNMaterial()
            stripeMat.diffuse.contents = color.withAlphaComponent(0.2)
            stripeMat.emission.contents = color
            let stripeNode = SCNNode(geometry: baseStripe)
            stripeNode.geometry?.materials = [stripeMat]
            stripeNode.position = SCNVector3(0, 0.3, 0)
            packetNode.addChildNode(stripeNode)
            
            // Scale the whole packet at once instead of multiplying every float
            packetNode.scale = SCNVector3(scale, scale, scale)
            
            // Small ground glow
            if i % 3 == 0 {
                let glow = SCNLight()
                glow.type = .omni
                glow.color = color
                glow.intensity = 30
                glow.attenuationStartDistance = 0.3
                glow.attenuationEndDistance = 2.0
                let glowNode = SCNNode()
                glowNode.light = glow
                glowNode.position = SCNVector3(0, 0.4, 0)
                packetNode.addChildNode(glowNode)
            }
            
            // Position — spread along the scene
            let startX = Float.random(in: -halfW...halfW)
            let startY = yMin == yMax ? Float(0) : Float.random(in: yMin...yMax)
            let startZ = Float.random(in: -halfH...halfH)
            packetNode.position = SCNVector3(startX, startY, startZ)
            
            // Face the flow direction
            let angle = atan2(flowDirection.x, flowDirection.z)
            packetNode.eulerAngles = SCNVector3(0, angle, 0)
            
            // Flow movement — travel in one direction, teleport back, repeat
            let travelDist: Float = halfW * 2
            let speed = Double.random(in: 8...16)
            let dx = CGFloat(flowDirection.x * travelDist)
            let dz = CGFloat(flowDirection.z * travelDist)
            let travel = SCNAction.moveBy(x: dx, y: 0, z: dz, duration: speed)
            let teleportBack = SCNAction.moveBy(x: -dx, y: 0, z: -dz, duration: 0)
            packetNode.runAction(SCNAction.repeatForever(SCNAction.sequence([travel, teleportBack])))
            
            // Subtle hover bob
            let bob = SCNAction.sequence([
                SCNAction.moveBy(x: 0, y: 0.08, z: 0, duration: 0.6),
                SCNAction.moveBy(x: 0, y: -0.08, z: 0, duration: 0.6)
            ])
            packetNode.runAction(SCNAction.repeatForever(bob))
            
            root.addChildNode(packetNode)
        }
    }
    
    // MARK: - CPU City (Act 1)
    // The Digital Nexus — first node of the internet. Towering dark server monoliths,
    // holographic data columns, flowing data streams, hex-grid platform floor.
    // The player (a fresh packet) spawns here, dwarfed by the digital infrastructure.
    private static func buildCPUCity(in manager: SceneManager) {
        manager.worldBounds = CGSize(width: 36, height: 24)
        let root = manager.scene.rootNode
        
        // Cyberpunk sky — deep indigo with cyan horizon glow
        manager.scene.background.contents = SceneManager.makeGradientSky(
            topColor: UIColor(red: 0.05, green: 0.03, blue: 0.16, alpha: 1),
            midColor: UIColor(red: 0.08, green: 0.06, blue: 0.22, alpha: 1),
            bottomColor: UIColor(red: 0.10, green: 0.14, blue: 0.30, alpha: 1)
        )
        manager.scene.fogStartDistance = 30
        manager.scene.fogEndDistance = 60
        manager.scene.fogColor = UIColor(red: 0.07, green: 0.05, blue: 0.16, alpha: 1)
        
        // ── Ground: lighter grid floor ──
        let floorColor = UIColor(red: 0.12, green: 0.12, blue: 0.18, alpha: 1) // Lighter grey/blue base
        let floor = makeGroundPlane(width: 44, length: 34, baseColor: floorColor, accentColor: P.cyan)
        root.addChildNode(floor)
        
        // Hexagonal accent patches on the floor for a circuit-board feel
        for _ in 0..<18 {
            let hexSize: CGFloat = CGFloat.random(in: 0.4...1.2)
            let hex = SCNCylinder(radius: hexSize, height: 0.01)
            hex.radialSegmentCount = 6  // hexagon
            let hMat = SCNMaterial()
            let hexColor = [P.cyan, P.magenta, P.violet].randomElement()!
            hMat.diffuse.contents = hexColor.withAlphaComponent(0.06)
            hMat.emission.contents = hexColor.withAlphaComponent(0.15)
            hex.materials = [hMat]
            let hNode = SCNNode(geometry: hex)
            hNode.position = SCNVector3(Float.random(in: -16...16), 0.005, Float.random(in: -12...12))
            root.addChildNode(hNode)
            
            // Slow pulse
            let pulse = SCNAction.sequence([
                SCNAction.fadeOpacity(to: 0.3, duration: Double.random(in: 2...4)),
                SCNAction.fadeOpacity(to: 1.0, duration: Double.random(in: 2...4))
            ])
            hNode.runAction(SCNAction.repeatForever(pulse))
        }
        
        // ── Server Monoliths — tall dark towers lining corridors ──
        let darkColor = UIColor(red: 0.06, green: 0.06, blue: 0.08, alpha: 1)
        
        // Left corridor wall
        let leftWall: [(x: Float, z: Float, w: CGFloat, h: CGFloat, l: CGFloat)] = [
            (-14, -9, 1.8, 6, 1.4),  (-14, -5, 1.8, 8, 1.4),
            (-14, -1, 1.8, 5, 1.4),  (-14, 3, 1.8, 7, 1.4),
            (-14, 7, 1.8, 4, 1.4),   (-14, 10, 1.8, 6, 1.4),
        ]
        // Right corridor wall — gap near center for portal access
        // Notice we removed the front-facing buildings (z > 0) so the camera doesn't get blocked
        let rightWall: [(x: Float, z: Float, w: CGFloat, h: CGFloat, l: CGFloat)] = [
            (14, -8, 1.8, 7, 1.4),   (14, -4, 1.8, 5, 1.4)
        ]
        // Inner structures — processing nodes deeper in the scene (cleared near right for portal)
        let innerStructures: [(x: Float, z: Float, w: CGFloat, h: CGFloat, l: CGFloat)] = [
            (-7, -8, 1.5, 4, 1.5),    (3, -7, 2, 5, 1.5),
            (-8, 8, 1.5, 3, 1.5),     (6, 8, 2, 4.5, 1.5),
        ]
        
        let allStructures = leftWall + rightWall + innerStructures
        for b in allStructures {
            let building = makeBuilding(
                width: b.w, height: b.h, length: b.l,
                color: darkColor, emissionColor: P.cyan,
                at: SCNVector3(b.x, 0, b.z)
            )
            root.addChildNode(building)
            registerBox(manager, x: b.x, z: b.z, w: b.w, l: b.l)
        }
        
        // ── Holographic Data Columns Removed ──
        
        // ── Data Stream Lanes — animated glowing pathways ──
        // Main horizontal throughway
        let laneMat = SCNMaterial()
        laneMat.diffuse.contents = P.cyan.withAlphaComponent(0.06)
        laneMat.emission.contents = P.cyan.withAlphaComponent(0.3)
        
        let mainLane = SCNBox(width: 30, height: 0.003, length: 1.2, chamferRadius: 0)
        mainLane.materials = [laneMat]
        let mainNode = SCNNode(geometry: mainLane)
        mainNode.position = SCNVector3(0, 0.008, 0)
        root.addChildNode(mainNode)
        
        // Animated data pulses flowing along the lane
        for i in 0..<16 {
            let pulse = SCNBox(width: 0.8, height: 0.005, length: 0.08, chamferRadius: 0.02)
            let pMat = SCNMaterial()
            pMat.diffuse.contents = P.cyan.withAlphaComponent(0.4)
            pMat.emission.contents = P.cyan
            pulse.materials = [pMat]
            let pNode = SCNNode(geometry: pulse)
            pNode.position = SCNVector3(Float(i) * 1.9 - 14, 0.012, 0)
            pNode.opacity = 0.7
            root.addChildNode(pNode)
            
            // Slide right continuously
            let slide = SCNAction.moveBy(x: 30, y: 0, z: 0, duration: 2.5)
            let reset = SCNAction.moveBy(x: -30, y: 0, z: 0, duration: 0)
            let delay = SCNAction.wait(duration: Double(i) * 0.15)
            pNode.runAction(SCNAction.sequence([delay, SCNAction.repeatForever(SCNAction.sequence([slide, reset]))]))
        }
        
        // Cross-lanes (vertical data paths)
        for xPos: Float in [-6, 0, 6] {
            let crossLane = SCNBox(width: 0.6, height: 0.003, length: 20, chamferRadius: 0)
            let crossMat = SCNMaterial()
            crossMat.diffuse.contents = P.violet.withAlphaComponent(0.04)
            crossMat.emission.contents = P.violet.withAlphaComponent(0.2)
            crossLane.materials = [crossMat]
            let cNode = SCNNode(geometry: crossLane)
            cNode.position = SCNVector3(xPos, 0.008, 0)
            root.addChildNode(cNode)
        }
        
        // ── Floating Processing Nodes — rotating wireframe cubes ──
        let floatingCubePositions: [(x: Float, y: Float, z: Float, size: CGFloat, color: UIColor)] = [
            (-4, 4, -5, 0.5, P.magenta), (7, 5, -3, 0.6, P.cyan),
            (-9, 3.5, 2, 0.4, P.violet), (3, 6, 4, 0.55, P.amber),
            (11, 4, 1, 0.45, P.cyan),    (-2, 5, 7, 0.5, P.magenta),
        ]
        for fc in floatingCubePositions {
            let cubeGeo = SCNBox(width: fc.size, height: fc.size, length: fc.size, chamferRadius: 0)
            let cubeMat = SCNMaterial()
            cubeMat.diffuse.contents = UIColor.clear
            cubeMat.emission.contents = fc.color.withAlphaComponent(0.6)
            cubeMat.fillMode = .lines
            cubeMat.transparency = 0.35
            cubeGeo.materials = [cubeMat]
            let cubeNode = SCNNode(geometry: cubeGeo)
            cubeNode.position = SCNVector3(fc.x, fc.y, fc.z)
            root.addChildNode(cubeNode)
            
            // Inner solid core (tiny glowing sphere)
            let core = SCNSphere(radius: fc.size * 0.15)
            let coreMat = SCNMaterial()
            coreMat.diffuse.contents = fc.color
            coreMat.emission.contents = fc.color
            core.materials = [coreMat]
            let coreNode = SCNNode(geometry: core)
            cubeNode.addChildNode(coreNode)
            
            // Slow rotation
            let spin = SCNAction.rotateBy(
                x: CGFloat.random(in: 0.3...1),
                y: CGFloat.random(in: 0.5...1.5),
                z: CGFloat.random(in: 0.2...0.8),
                duration: Double.random(in: 4...8)
            )
            cubeNode.runAction(SCNAction.repeatForever(spin))
            
            // Gentle hover
            let hover = SCNAction.sequence([
                SCNAction.moveBy(x: 0, y: CGFloat.random(in: 0.3...0.6), z: 0, duration: Double.random(in: 2...3.5)),
                SCNAction.moveBy(x: 0, y: CGFloat.random(in: -0.6 ... -0.3), z: 0, duration: Double.random(in: 2...3.5))
            ])
            cubeNode.runAction(SCNAction.repeatForever(hover))
        }
        
        // ── Overhead Cable Conduits Removed ──
        
        // ── Vertical Data Conduits on walls ──
        for x: Float in [-15, -13, 13, 15] {
            for _ in 0..<2 {
                let vPipe = SCNCylinder(radius: 0.035, height: CGFloat.random(in: 4...8))
                let vpMat = SCNMaterial()
                vpMat.diffuse.contents = UIColor(red: 0.08, green: 0.06, blue: 0.14, alpha: 1)
                vpMat.metalness.contents = 0.7
                vPipe.materials = [vpMat]
                let vpNode = SCNNode(geometry: vPipe)
                vpNode.position = SCNVector3(x, Float(vPipe.height / 2), Float.random(in: -10...10))
                root.addChildNode(vpNode)
                
                // Tiny accent ring
                let ring = SCNTorus(ringRadius: 0.06, pipeRadius: 0.012)
                let rMat = SCNMaterial()
                rMat.diffuse.contents = P.cyan
                rMat.emission.contents = P.cyan
                ring.materials = [rMat]
                let rNode = SCNNode(geometry: ring)
                rNode.position = SCNVector3(0, Float(vPipe.height / 2) - 0.1, 0)
                vpNode.addChildNode(rNode)
            }
        }
        
        // ── Floating Data Particles ──
        for _ in 0..<20 {
            let particle = makeDataParticle(
                color: [P.cyan, P.magenta, P.amber, P.violet].randomElement()!,
                at: SCNVector3(Float.random(in: -16...16), Float.random(in: 1.5...8), Float.random(in: -11...11)),
                size: CGFloat.random(in: 0.04...0.1)
            )
            root.addChildNode(particle)
        }
        
        // ── Ground-level haze — large very faint disc simulating fog on floor ──
        let haze = SCNCylinder(radius: 20, height: 0.01)
        let hazeMat = SCNMaterial()
        hazeMat.diffuse.contents = P.cyan.withAlphaComponent(0.015)
        hazeMat.emission.contents = P.cyan.withAlphaComponent(0.04)
        hazeMat.isDoubleSided = true
        hazeMat.transparency = 0.6
        haze.materials = [hazeMat]
        let hazeNode = SCNNode(geometry: haze)
        hazeNode.position = SCNVector3(0, 0.15, 0)
        root.addChildNode(hazeNode)
        
        // ── Sign Panel ──
        root.addChildNode(makeSignPanel(color: P.cyan, at: SCNVector3(0, 9, -13)))
        
        // ── Lighting — multi-colored for depth and drama ──
        // Cyan spot from front-left
        let spot1 = SCNLight()
        spot1.type = .spot
        spot1.color = P.cyan
        spot1.intensity = 200
        spot1.spotInnerAngle = 15
        spot1.spotOuterAngle = 50
        spot1.castsShadow = true
        spot1.shadowRadius = 3
        let spot1Node = SCNNode()
        spot1Node.light = spot1
        spot1Node.position = SCNVector3(-8, 10, -4)
        spot1Node.eulerAngles = SCNVector3(-Float.pi / 3, -Float.pi / 6, 0)
        root.addChildNode(spot1Node)
        
        // Magenta spot from right
        let spot2 = SCNLight()
        spot2.type = .spot
        spot2.color = P.magenta
        spot2.intensity = 120
        spot2.spotInnerAngle = 15
        spot2.spotOuterAngle = 45
        let spot2Node = SCNNode()
        spot2Node.light = spot2
        spot2Node.position = SCNVector3(10, 8, 3)
        spot2Node.eulerAngles = SCNVector3(-Float.pi / 3, Float.pi / 5, 0)
        root.addChildNode(spot2Node)
        
        // Violet rim from behind
        let spot3 = SCNLight()
        spot3.type = .spot
        spot3.color = P.violet
        spot3.intensity = 100
        spot3.spotInnerAngle = 20
        spot3.spotOuterAngle = 60
        let spot3Node = SCNNode()
        spot3Node.light = spot3
        spot3Node.position = SCNVector3(0, 9, 12)
        spot3Node.eulerAngles = SCNVector3(-Float.pi / 4, Float.pi, 0)
        root.addChildNode(spot3Node)
        
        // ── Ambient NPC Packets — flowing along the main data lane ──
        makeAmbientPacket(in: root, bounds: manager.worldBounds, accentColor: P.cyan, flowDirection: SCNVector3(1, 0, 0))
        
        manager.resetPlayerPosition(to: SCNVector3(-12, 0, 0))
    }
    
    // MARK: - WiFi Antenna (Act 2a)
    // Dramatic industrial rooftop broadcast tower — antenna dominates the center,
    // elevated catwalks, equipment racks, satellite dishes, pulsing signal waves
    private static func buildWiFiAntenna(in manager: SceneManager) {
        manager.worldBounds = CGSize(width: 34, height: 26)
        let root = manager.scene.rootNode
        
        // Atmosphere — dark sky with green/teal gradient
        manager.scene.background.contents = SceneManager.makeGradientSky(
            topColor: UIColor(red: 0.03, green: 0.06, blue: 0.05, alpha: 1),
            midColor: UIColor(red: 0.05, green: 0.10, blue: 0.08, alpha: 1),
            bottomColor: UIColor(red: 0.08, green: 0.18, blue: 0.12, alpha: 1)
        )
        manager.scene.fogColor = UIColor(red: 0.05, green: 0.10, blue: 0.07, alpha: 1)
        manager.scene.fogStartDistance = 30
        manager.scene.fogEndDistance = 65
        
        // ── Ground: industrial rooftop with lime grid ──
        let floor = makeGroundPlane(width: 40, length: 32, baseColor: UIColor(red: 0.06, green: 0.06, blue: 0.08, alpha: 1), accentColor: P.lime)
        root.addChildNode(floor)
        
        // Shared dark metal material
        let metalMat = SCNMaterial()
        metalMat.diffuse.contents = UIColor(red: 0.12, green: 0.10, blue: 0.14, alpha: 1)
        metalMat.metalness.contents = 0.85
        metalMat.roughness.contents = 0.25
        
        // ══════════════════════════════════════════════
        // ── CENTRAL ANTENNA TOWER (centered at origin) ──
        // ══════════════════════════════════════════════
        
        // Heavy octagonal base platform
        let basePlatform = SCNCylinder(radius: 2.5, height: 0.4)
        basePlatform.radialSegmentCount = 8
        let basePlatMat = SCNMaterial()
        basePlatMat.diffuse.contents = UIColor(red: 0.08, green: 0.08, blue: 0.1, alpha: 1)
        basePlatMat.metalness.contents = 0.9
        basePlatMat.roughness.contents = 0.2
        basePlatform.materials = [basePlatMat]
        let basePlatNode = SCNNode(geometry: basePlatform)
        basePlatNode.position = SCNVector3(0, 0.2, 0)
        root.addChildNode(basePlatNode)
        
        // Base wireframe glow
        let baseWire = SCNCylinder(radius: 2.52, height: 0.42)
        baseWire.radialSegmentCount = 8
        let baseWireMat = SCNMaterial()
        baseWireMat.diffuse.contents = UIColor.clear
        baseWireMat.emission.contents = P.lime
        baseWireMat.fillMode = .lines
        baseWireMat.transparency = 0.6
        baseWire.materials = [baseWireMat]
        let baseWireNode = SCNNode(geometry: baseWire)
        baseWireNode.position = SCNVector3(0, 0.2, 0)
        root.addChildNode(baseWireNode)
        
        // Tower lower section — thick
        let towerLower = SCNCylinder(radius: 0.6, height: 3)
        towerLower.materials = [metalMat]
        let towerLowerNode = SCNNode(geometry: towerLower)
        towerLowerNode.position = SCNVector3(0, 1.9, 0)
        root.addChildNode(towerLowerNode)
        
        // Tower mid section — medium
        let towerMid = SCNCylinder(radius: 0.35, height: 5)
        towerMid.materials = [metalMat]
        let towerMidNode = SCNNode(geometry: towerMid)
        towerMidNode.position = SCNVector3(0, 5.9, 0)
        root.addChildNode(towerMidNode)
        
        // Tower upper section — thin
        let towerUpper = SCNCylinder(radius: 0.15, height: 4)
        towerUpper.materials = [metalMat]
        let towerUpperNode = SCNNode(geometry: towerUpper)
        towerUpperNode.position = SCNVector3(0, 10.4, 0)
        root.addChildNode(towerUpperNode)
        
        // Antenna cross-arms at mid height
        for angle: Float in [0, Float.pi / 2, Float.pi, Float.pi * 1.5] {
            let arm = SCNBox(width: 3, height: 0.08, length: 0.08, chamferRadius: 0)
            arm.materials = [metalMat]
            let armNode = SCNNode(geometry: arm)
            armNode.position = SCNVector3(0, 8.5, 0)
            armNode.eulerAngles = SCNVector3(0, angle, 0)
            root.addChildNode(armNode)
            
            // Arm tip light
            let armTipSphere = SCNSphere(radius: 0.08)
            let armTipMat = SCNMaterial()
            armTipMat.diffuse.contents = P.lime
            armTipMat.emission.contents = P.lime
            armTipSphere.materials = [armTipMat]
            let armTip = SCNNode(geometry: armTipSphere)
            armTip.position = SCNVector3(1.5, 0, 0)
            armNode.addChildNode(armTip)
            
            // Blinking light on each arm tip
            let blinkOn = SCNAction.fadeOpacity(to: 1.0, duration: 0.3)
            let blinkOff = SCNAction.fadeOpacity(to: 0.2, duration: 0.3)
            let wait = SCNAction.wait(duration: Double.random(in: 0.5...1.5))
            armTip.runAction(SCNAction.repeatForever(SCNAction.sequence([blinkOn, wait, blinkOff, wait])))
        }
        
        // Support struts — diagonal braces from base to mid tower
        for angle: Float in [Float.pi / 4, Float.pi * 3 / 4, Float.pi * 5 / 4, Float.pi * 7 / 4] {
            let strut = SCNCylinder(radius: 0.04, height: 6)
            strut.materials = [metalMat]
            let strutNode = SCNNode(geometry: strut)
            let dx = sin(angle) * 1.8
            let dz = cos(angle) * 1.8
            strutNode.position = SCNVector3(dx, 3.5, dz)
            strutNode.eulerAngles = SCNVector3(cos(angle) * 0.35, 0, -sin(angle) * 0.35)
            root.addChildNode(strutNode)
        }
        
        // Antenna tip — bright glowing sphere
        let tip = SCNSphere(radius: 0.4)
        let tipMat = SCNMaterial()
        tipMat.diffuse.contents = P.lime
        tipMat.emission.contents = P.lime
        tip.materials = [tipMat]
        let tipNode = SCNNode(geometry: tip)
        tipNode.position = SCNVector3(0, 12.8, 0)
        root.addChildNode(tipNode)
        
        // Tip glow pulsing
        let glowUp = SCNAction.customAction(duration: 1.5) { node, t in
            let progress = Float(t) / 1.5
            node.geometry?.firstMaterial?.emission.intensity = CGFloat(0.6 + 0.4 * sin(progress * .pi))
        }
        tipNode.runAction(SCNAction.repeatForever(glowUp))
        
        let tipLight = SCNLight()
        tipLight.type = .omni
        tipLight.color = P.lime
        tipLight.intensity = 800
        tipLight.attenuationStartDistance = 3
        tipLight.attenuationEndDistance = 18
        tipNode.light = tipLight
        
        // Warning beacon at top — rotating red blink
        let beacon = SCNSphere(radius: 0.12)
        let beaconMat = SCNMaterial()
        beaconMat.diffuse.contents = UIColor.red
        beaconMat.emission.contents = UIColor.red
        beacon.materials = [beaconMat]
        let beaconNode = SCNNode(geometry: beacon)
        beaconNode.position = SCNVector3(0, 13.3, 0)
        root.addChildNode(beaconNode)
        let beaconBlink = SCNAction.sequence([
            SCNAction.fadeOpacity(to: 1.0, duration: 0.15),
            SCNAction.fadeOpacity(to: 0.0, duration: 0.15),
            SCNAction.wait(duration: 1.5)
        ])
        beaconNode.runAction(SCNAction.repeatForever(beaconBlink))
        
        // Tower base collision
        registerBox(manager, x: 0, z: 0, w: 2.5, l: 2.5)
        
        // ══════════════════════════════════════════════
        // ── WiFi WAVE RINGS — dramatic pulsing signal ──
        // ══════════════════════════════════════════════
        for i in 0..<5 {
            let ringRadius = CGFloat(1.8 + Double(i) * 2.0)
            let ring = SCNTorus(ringRadius: ringRadius, pipeRadius: 0.08)
            let ringMat = SCNMaterial()
            ringMat.diffuse.contents = P.lime.withAlphaComponent(0.35)
            ringMat.emission.contents = P.lime
            ringMat.transparency = CGFloat(0.8 - Double(i) * 0.12)
            ring.materials = [ringMat]
            let ringNode = SCNNode(geometry: ring)
            ringNode.position = SCNVector3(0, 10.5 + Float(i) * 0.6, 0)
            root.addChildNode(ringNode)
            
            // Staggered pulse: expand + fade, then snap back
            let delay = Double(i) * 0.5
            let expand = SCNAction.scale(to: 1.8, duration: 2.0)
            expand.timingMode = .easeOut
            let fadeOut = SCNAction.fadeOpacity(to: 0.08, duration: 2.0)
            let expandAndFade = SCNAction.group([expand, fadeOut])
            let reset = SCNAction.group([
                SCNAction.scale(to: 0.5, duration: 0),
                SCNAction.fadeOpacity(to: 1.0, duration: 0)
            ])
            let pulse = SCNAction.sequence([
                SCNAction.wait(duration: delay),
                expandAndFade,
                reset
            ])
            ringNode.runAction(SCNAction.repeatForever(pulse))
            
            // Light on first ring for extra glow
            if i == 0 {
                let waveLight = SCNLight()
                waveLight.type = .omni
                waveLight.color = P.lime
                waveLight.intensity = 300
                waveLight.attenuationStartDistance = 2
                waveLight.attenuationEndDistance = 12
                ringNode.light = waveLight
            }
        }
        
        // ══════════════════════════════════════════════
        // ── ELEVATED CATWALKS — adds depth & verticality ──
        // ══════════════════════════════════════════════
        
        // Catwalk ring around the antenna at height 1.5
        let catwalkAngles: [Float] = [0, Float.pi / 2, Float.pi, Float.pi * 1.5]
        for angle in catwalkAngles {
            let walkway = SCNBox(width: 6, height: 0.06, length: 1.2, chamferRadius: 0)
            let walkMat = SCNMaterial()
            walkMat.diffuse.contents = UIColor(red: 0.07, green: 0.07, blue: 0.09, alpha: 1)
            walkMat.metalness.contents = 0.8
            walkMat.roughness.contents = 0.3
            walkway.materials = [walkMat]
            let walkNode = SCNNode(geometry: walkway)
            let wx = sin(angle) * 5
            let wz = cos(angle) * 5
            walkNode.position = SCNVector3(wx, 1.5, wz)
            walkNode.eulerAngles = SCNVector3(0, angle, 0)
            root.addChildNode(walkNode)
            
            // Catwalk wireframe edge
            let walkWire = SCNBox(width: 6.02, height: 0.08, length: 1.22, chamferRadius: 0)
            let walkWireMat = SCNMaterial()
            walkWireMat.diffuse.contents = UIColor.clear
            walkWireMat.emission.contents = P.lime.withAlphaComponent(0.6)
            walkWireMat.fillMode = .lines
            walkWireMat.transparency = 0.4
            walkWire.materials = [walkWireMat]
            let walkWireNode = SCNNode(geometry: walkWire)
            walkWireNode.position = SCNVector3(wx, 1.5, wz)
            walkWireNode.eulerAngles = SCNVector3(0, angle, 0)
            root.addChildNode(walkWireNode)
            
            // Railing posts
            for offset: Float in [-2.5, -1.0, 0.5, 2.0] {
                let post = SCNCylinder(radius: 0.03, height: 0.8)
                post.materials = [metalMat]
                let postNode = SCNNode(geometry: post)
                let px = sin(angle) * 5 + cos(angle) * offset
                let pz = cos(angle) * 5 - sin(angle) * offset
                postNode.position = SCNVector3(px, 1.9, pz)
                root.addChildNode(postNode)
            }
            
            // Collision — axis-aligned bounding box for the catwalk
            // Rotated walkways: swap width/length based on orientation
            let isHorizontal = abs(sin(angle)) > 0.5  // angle ≈ π/2 or 3π/2
            let collW: CGFloat = isHorizontal ? 1.2 : 6
            let collL: CGFloat = isHorizontal ? 6 : 1.2
            registerBox(manager, x: Float(wx), z: Float(wz), w: collW, l: collL)
        }
        
        // ══════════════════════════════════════════════
        // ── SATELLITE DISHES — larger, more dramatic ──
        // ══════════════════════════════════════════════
        let dishPositions: [(x: Float, z: Float, scale: Float, tilt: Float)] = [
            (8, -6, 1.3, -0.4),
            (10, 4, 1.0, -0.3),
            (-9, 6, 1.1, -0.35),
            (-7, -8, 0.9, -0.5)
        ]
        for dish in dishPositions {
            let dishGeo = SCNSphere(radius: CGFloat(dish.scale))
            dishGeo.segmentCount = 12
            let dMat = SCNMaterial()
            dMat.diffuse.contents = UIColor(red: 0.14, green: 0.12, blue: 0.18, alpha: 1)
            dMat.metalness.contents = 0.8
            dMat.roughness.contents = 0.2
            dMat.isDoubleSided = true
            dishGeo.materials = [dMat]
            let dNode = SCNNode(geometry: dishGeo)
            dNode.position = SCNVector3(dish.x, 1.8, dish.z)
            dNode.scale = SCNVector3(1, 0.35, 1)
            dNode.eulerAngles = SCNVector3(dish.tilt, 0, 0)
            root.addChildNode(dNode)
            
            // Dish stem
            let stem = SCNCylinder(radius: 0.1, height: 1.8)
            stem.materials = [metalMat]
            let sNode = SCNNode(geometry: stem)
            sNode.position = SCNVector3(dish.x, 0.9, dish.z)
            root.addChildNode(sNode)
            
            // Dish receiver arm
            let arm = SCNCylinder(radius: 0.03, height: 1.2)
            arm.materials = [metalMat]
            let armNode = SCNNode(geometry: arm)
            armNode.position = SCNVector3(dish.x, 2.2, dish.z - 0.3)
            armNode.eulerAngles = SCNVector3(0.6, 0, 0)
            root.addChildNode(armNode)
            
            // Receiver glow dot
            let rcv = SCNSphere(radius: 0.06)
            let rcvMat = SCNMaterial()
            rcvMat.diffuse.contents = P.lime
            rcvMat.emission.contents = P.lime
            rcv.materials = [rcvMat]
            let rcvNode = SCNNode(geometry: rcv)
            rcvNode.position = SCNVector3(dish.x, 2.8, dish.z - 0.8)
            root.addChildNode(rcvNode)
        }
        
        // ══════════════════════════════════════════════
        // ── EQUIPMENT RACKS & ROOFTOP STRUCTURES ──
        // ══════════════════════════════════════════════
        
        // Equipment racks along left side (player spawn side)
        root.addChildNode(makeBuilding(width: 2, height: 2.5, length: 1.5, color: P.slate, emissionColor: P.lime, at: SCNVector3(-12, 0, -4)))
        registerBox(manager, x: -12, z: -4, w: 2, l: 1.5)
        root.addChildNode(makeBuilding(width: 1.5, height: 2, length: 1.5, color: P.slate, emissionColor: P.lime, at: SCNVector3(-12, 0, 2)))
        registerBox(manager, x: -12, z: 2, w: 1.5, l: 1.5)
        
        // Equipment racks along right side (firewall side)
        root.addChildNode(makeBuilding(width: 2.5, height: 3, length: 2, color: P.slate, emissionColor: P.lime, at: SCNVector3(12, 0, -3)))
        registerBox(manager, x: 12, z: -3, w: 2.5, l: 2)
        root.addChildNode(makeBuilding(width: 2, height: 2, length: 1.5, color: P.slate, emissionColor: P.lime, at: SCNVector3(12, 0, 4)))
        registerBox(manager, x: 12, z: 4, w: 2, l: 1.5)
        
        // Low vent units scattered around
        root.addChildNode(makeBuilding(width: 1.5, height: 0.6, length: 1.5, color: UIColor.darkGray, emissionColor: P.lime, at: SCNVector3(-6, 0, 8)))
        registerBox(manager, x: -6, z: 8, w: 1.5, l: 1.5)
        root.addChildNode(makeBuilding(width: 2, height: 0.5, length: 1, color: UIColor.darkGray, emissionColor: P.lime, at: SCNVector3(5, 0, -9)))
        registerBox(manager, x: 5, z: -9, w: 2, l: 1)
        
        // ══════════════════════════════════════════════
        // ── CABLE CONDUITS — across the rooftop ──
        // ══════════════════════════════════════════════
        for z: Float in [-5, 0, 5, 9] {
            root.addChildNode(makePipe(from: SCNVector3(-14, 0.2, z), to: SCNVector3(14, 0.2, z), radius: 0.04, color: P.lime))
        }
        // Cross cables
        for x: Float in [-8, -3, 3, 8] {
            root.addChildNode(makePipe(from: SCNVector3(x, 0.2, -10), to: SCNVector3(x, 0.2, 10), radius: 0.03, color: P.lime.withAlphaComponent(0.5)))
        }
        
        // Overhead cables at height
        root.addChildNode(makePipe(from: SCNVector3(-14, 4, -6), to: SCNVector3(14, 4, -6), radius: 0.05, color: P.lime))
        root.addChildNode(makePipe(from: SCNVector3(-14, 5, 6), to: SCNVector3(14, 5, 6), radius: 0.05, color: P.lime))
        
        // ══════════════════════════════════════════════
        // ── SIGNAL STRENGTH INDICATORS — vertical light bars ──
        // ══════════════════════════════════════════════
        let barPositions: [(x: Float, z: Float)] = [(-4, -10), (4, -10), (-4, 10), (4, 10)]
        for barPos in barPositions {
            for barIdx in 0..<5 {
                let barH: CGFloat = 0.3
                let bar = SCNBox(width: 0.3, height: barH, length: 0.1, chamferRadius: 0.02)
                let barMat = SCNMaterial()
                let intensity = CGFloat(barIdx + 1) / 5.0
                barMat.diffuse.contents = P.lime.withAlphaComponent(0.2)
                barMat.emission.contents = P.lime
                barMat.transparency = intensity
                bar.materials = [barMat]
                let barNode = SCNNode(geometry: bar)
                barNode.position = SCNVector3(barPos.x, 0.5 + Float(barIdx) * 0.4, barPos.z)
                root.addChildNode(barNode)
                
                // Cascading blink animation
                let delay = Double(barIdx) * 0.3
                let on = SCNAction.fadeOpacity(to: 1.0, duration: 0.2)
                let hold = SCNAction.wait(duration: 0.5)
                let off = SCNAction.fadeOpacity(to: 0.3, duration: 0.4)
                let wait = SCNAction.wait(duration: 2.0 - delay)
                barNode.runAction(SCNAction.repeatForever(SCNAction.sequence([
                    SCNAction.wait(duration: delay), on, hold, off, wait
                ])))
            }
        }
        
        // ══════════════════════════════════════════════
        // ── ROOFTOP EDGE — low wall perimeter ──
        // ══════════════════════════════════════════════
        let edgePositions: [(x: Float, z: Float, w: CGFloat, l: CGFloat)] = [
            (0, -12, 30, 0.3),   // back edge
            (0, 12, 30, 0.3),    // front edge
            (-15, 0, 0.3, 24),   // left edge
            (15, 0, 0.3, 24)     // right edge
        ]
        for edge in edgePositions {
            let wall = SCNBox(width: edge.w, height: 0.6, length: edge.l, chamferRadius: 0)
            let wallMat = SCNMaterial()
            wallMat.diffuse.contents = UIColor(red: 0.06, green: 0.06, blue: 0.08, alpha: 1)
            wallMat.metalness.contents = 0.7
            wallMat.roughness.contents = 0.3
            wall.materials = [wallMat]
            let wallNode = SCNNode(geometry: wall)
            wallNode.position = SCNVector3(edge.x, 0.3, edge.z)
            root.addChildNode(wallNode)
            
            // Edge wireframe
            let wireWall = SCNBox(width: edge.w + 0.02, height: 0.62, length: edge.l + 0.02, chamferRadius: 0)
            let wireWallMat = SCNMaterial()
            wireWallMat.diffuse.contents = UIColor.clear
            wireWallMat.emission.contents = P.lime.withAlphaComponent(0.4)
            wireWallMat.fillMode = .lines
            wireWallMat.transparency = 0.3
            wireWall.materials = [wireWallMat]
            let wireWallNode = SCNNode(geometry: wireWall)
            wireWallNode.position = SCNVector3(edge.x, 0.3, edge.z)
            root.addChildNode(wireWallNode)
            
            // Register collision so player can't walk through
            registerBox(manager, x: edge.x, z: edge.z, w: edge.w, l: edge.l)
        }
        
        // ══════════════════════════════════════════════
        // ── SIGN & DECOR ──
        // ══════════════════════════════════════════════
        root.addChildNode(makeSignPanel(color: P.lime, width: 6, height: 1.5, at: SCNVector3(0, 7, -11)))
        
        // Floating data particles around the antenna
        for _ in 0..<15 {
            let px = Float.random(in: -14...14)
            let py = Float.random(in: 2...10)
            let pz = Float.random(in: -11...11)
            root.addChildNode(makeDataParticle(color: P.lime, at: SCNVector3(px, py, pz), size: 0.08))
        }
        
        // ══════════════════════════════════════════════
        // ── LIGHTING — dramatic multi-color setup ──
        // ══════════════════════════════════════════════
        
        // Main lime spot from above-front
        let mainSpot = SCNLight()
        mainSpot.type = .spot
        mainSpot.color = P.lime
        mainSpot.intensity = 300
        mainSpot.spotInnerAngle = 20
        mainSpot.spotOuterAngle = 60
        mainSpot.castsShadow = true
        mainSpot.shadowRadius = 4
        let mainSpotNode = SCNNode()
        mainSpotNode.light = mainSpot
        mainSpotNode.position = SCNVector3(0, 14, -8)
        mainSpotNode.eulerAngles = SCNVector3(-Float.pi / 3, 0, 0)
        root.addChildNode(mainSpotNode)
        
        // Cyan accent from the left
        let leftSpot = SCNLight()
        leftSpot.type = .spot
        leftSpot.color = P.cyan
        leftSpot.intensity = 150
        leftSpot.spotInnerAngle = 15
        leftSpot.spotOuterAngle = 50
        let leftSpotNode = SCNNode()
        leftSpotNode.light = leftSpot
        leftSpotNode.position = SCNVector3(-12, 8, 0)
        leftSpotNode.eulerAngles = SCNVector3(-Float.pi / 4, -Float.pi / 4, 0)
        root.addChildNode(leftSpotNode)
        
        // Amber warm from the right (firewall side)
        let rightSpot = SCNLight()
        rightSpot.type = .spot
        rightSpot.color = P.amber
        rightSpot.intensity = 120
        rightSpot.spotInnerAngle = 15
        rightSpot.spotOuterAngle = 45
        let rightSpotNode = SCNNode()
        rightSpotNode.light = rightSpot
        rightSpotNode.position = SCNVector3(12, 8, 0)
        rightSpotNode.eulerAngles = SCNVector3(-Float.pi / 4, Float.pi / 4, 0)
        root.addChildNode(rightSpotNode)
        
        // Violet rim from behind for depth
        let backSpot = SCNLight()
        backSpot.type = .spot
        backSpot.color = P.violet
        backSpot.intensity = 80
        backSpot.spotInnerAngle = 20
        backSpot.spotOuterAngle = 60
        let backSpotNode = SCNNode()
        backSpotNode.light = backSpot
        backSpotNode.position = SCNVector3(0, 6, 12)
        backSpotNode.eulerAngles = SCNVector3(-Float.pi / 5, Float.pi, 0)
        root.addChildNode(backSpotNode)
        
        // Ambient NPC packets rising upward toward the antenna
        makeAmbientPacket(in: root, bounds: manager.worldBounds, accentColor: P.lime, yRange: 1.0...9.0, flowDirection: SCNVector3(0, 1, 0))
        
        // Player spawns at far LEFT (opposite of firewall at right)
        manager.resetPlayerPosition(to: SCNVector3(-12, 0, 0))
    }
    
    // MARK: - Router Station (Act 2b)
    // Underground subway station — platforms, rails, overhead pipes, signage
    private static func buildRouterStation(in manager: SceneManager) {
        manager.worldBounds = CGSize(width: 32, height: 20)
        let root = manager.scene.rootNode
        
        // Station atmosphere — warm amber-tinted sky, brighter than default
        manager.scene.background.contents = SceneManager.makeGradientSky(
            topColor: UIColor(red: 0.08, green: 0.06, blue: 0.16, alpha: 1),
            midColor: UIColor(red: 0.14, green: 0.10, blue: 0.22, alpha: 1),
            bottomColor: UIColor(red: 0.24, green: 0.18, blue: 0.10, alpha: 1)
        )
        manager.scene.lightingEnvironment.contents = SceneManager.makeGradientSky(
            topColor: UIColor(red: 0.12, green: 0.10, blue: 0.22, alpha: 1),
            midColor: UIColor(red: 0.18, green: 0.14, blue: 0.28, alpha: 1),
            bottomColor: UIColor(red: 0.28, green: 0.22, blue: 0.14, alpha: 1)
        )
        manager.scene.lightingEnvironment.intensity = 2.2
        manager.scene.fogColor = UIColor(red: 0.10, green: 0.08, blue: 0.16, alpha: 1)
        manager.scene.fogStartDistance = 35
        manager.scene.fogEndDistance = 70
        
        let floor = makeGroundPlane(width: 36, length: 24, baseColor: UIColor(red: 0.06, green: 0.05, blue: 0.1, alpha: 1), accentColor: P.amber)
        root.addChildNode(floor)
        
        // Track rails — embedded glowing lines
        for i in -2...2 {
            let rail = SCNBox(width: 30, height: 0.06, length: 0.08, chamferRadius: 0.02)
            let railMat = SCNMaterial()
            railMat.diffuse.contents = P.amber.withAlphaComponent(0.4)
            railMat.emission.contents = P.amber
            rail.materials = [railMat]
            let railNode = SCNNode(geometry: rail)
            railNode.position = SCNVector3(0, 0.03, Float(i) * 3)
            root.addChildNode(railNode)
        }
        
        // Platform pillars — thick metallic columns
        for x in stride(from: -12, through: 12, by: 6) {
            for z in [-8, 8] as [Float] {
                root.addChildNode(makePillar(radius: 0.3, height: 6, color: P.amber, at: SCNVector3(Float(x), 0, z)))
                registerBox(manager, x: Float(x), z: z, w: 0.6, l: 0.6)
            }
        }
        
        // Overhead pipes
        for z: Float in [-5, 0, 5] {
            root.addChildNode(makePipe(from: SCNVector3(-15, 5.5, z), to: SCNVector3(15, 5.5, z), radius: 0.07, color: P.amber))
        }
        
        // Platform walls — back walls with detail
        for z: Float in [-10, 10] {
            let wall = SCNBox(width: 32, height: 6, length: 0.3, chamferRadius: 0)
            let wMat = SCNMaterial()
            wMat.diffuse.contents = UIColor(red: 0.12, green: 0.10, blue: 0.18, alpha: 1)
            wMat.metalness.contents = 0.4
            wMat.roughness.contents = 0.35
            wall.materials = [wMat]
            let wNode = SCNNode(geometry: wall)
            wNode.position = SCNVector3(0, 3, z)
            root.addChildNode(wNode)
            registerBox(manager, x: 0, z: z, w: 32, l: 0.3)
        }
        
        // Neon direction signs
        root.addChildNode(makeSignPanel(color: UIColor.systemBlue, width: 3, height: 0.8, at: SCNVector3(-8, 4.5, -9.5)))
        root.addChildNode(makeSignPanel(color: UIColor.systemGreen, width: 3, height: 0.8, at: SCNVector3(8, 4.5, -9.5)))
        
        // Data trains — glowing spheres racing along rails
        for rail in 0..<3 {
            for offset in 0..<2 {
                let trainLight = SCNNode()
                let lightGeo = SCNSphere(radius: 0.25)
                let lMat = SCNMaterial()
                lMat.diffuse.contents = P.amber
                lMat.emission.contents = P.amber
                lightGeo.materials = [lMat]
                trainLight.geometry = lightGeo
                trainLight.position = SCNVector3(-15 + Float(offset) * 10, 0.4, Float(rail - 1) * 3)
                root.addChildNode(trainLight)
                
                let moveAcross = SCNAction.moveBy(x: 30, y: 0, z: 0, duration: Double.random(in: 2...5))
                let reset = SCNAction.moveBy(x: -30, y: 0, z: 0, duration: 0)
                trainLight.runAction(SCNAction.repeatForever(SCNAction.sequence([moveAcross, reset])))
            }
        }
        
        // Spot lights from ceiling — boosted for visibility
        for x: Float in [-8, 0, 8] {
            let spot = SCNLight()
            spot.type = .spot
            spot.color = P.amber
            spot.intensity = 500
            spot.spotInnerAngle = 20
            spot.spotOuterAngle = 65
            spot.castsShadow = true
            spot.shadowRadius = 3
            let sNode = SCNNode()
            sNode.light = spot
            sNode.position = SCNVector3(x, 5.8, 0)
            sNode.eulerAngles = SCNVector3(-Float.pi / 2, 0, 0)
            root.addChildNode(sNode)
        }
        
        // Extra amber omni lights between pillars for warmth
        for x: Float in [-10, -4, 4, 10] {
            let omni = SCNLight()
            omni.type = .omni
            omni.color = P.amber
            omni.intensity = 250
            omni.attenuationStartDistance = 2
            omni.attenuationEndDistance = 12
            let oNode = SCNNode()
            oNode.light = omni
            oNode.position = SCNVector3(x, 3.5, 0)
            root.addChildNode(oNode)
        }
        
        root.addChildNode(makeSignPanel(color: P.amber, at: SCNVector3(0, 4.5, -9.5)))
        
        // Packets rushing through the station
        makeAmbientPacket(in: root, bounds: manager.worldBounds, accentColor: P.amber, yRange: 0.5...3.0, flowDirection: SCNVector3(1, 0, 0))
        
        // Use default camera — matches all other scenes for consistent framing
        
        manager.resetPlayerPosition(to: SCNVector3(-10, 0, 0))
    }
    
    // MARK: - Ocean Cable (Act 3)
    // Undersea fiber optic cable run — player travels INSIDE a long glowing tube
    // across the ocean floor. Bioluminescent deep-sea environment outside the glass.
    private static func buildOceanCable(in manager: SceneManager) {
        // Long corridor — player is constrained inside the cable tube
        let cableLength: Float = 80
        let cableRadius: Float = 2.8
        manager.worldBounds = CGSize(width: CGFloat(cableLength), height: CGFloat(cableRadius * 1.4))
        let root = manager.scene.rootNode
        
        // ── Bright underwater atmosphere ──
        manager.scene.background.contents = SceneManager.makeGradientSky(
            topColor: UIColor(red: 0.04, green: 0.08, blue: 0.24, alpha: 1),
            midColor: UIColor(red: 0.06, green: 0.14, blue: 0.36, alpha: 1),
            bottomColor: UIColor(red: 0.08, green: 0.22, blue: 0.48, alpha: 1)
        )
        manager.scene.lightingEnvironment.contents = SceneManager.makeGradientSky(
            topColor: UIColor(red: 0.08, green: 0.12, blue: 0.30, alpha: 1),
            midColor: UIColor(red: 0.10, green: 0.18, blue: 0.40, alpha: 1),
            bottomColor: UIColor(red: 0.14, green: 0.26, blue: 0.50, alpha: 1)
        )
        manager.scene.lightingEnvironment.intensity = 2.5
        manager.scene.fogColor = UIColor(red: 0.05, green: 0.12, blue: 0.28, alpha: 1)
        manager.scene.fogStartDistance = 35
        manager.scene.fogEndDistance = 80
        
        // ── Deep ocean floor — visible far below through the glass ──
        let oceanFloor = SCNPlane(width: 300, height: 300)
        let floorMat = SCNMaterial()
        floorMat.diffuse.contents = UIColor(red: 0.04, green: 0.08, blue: 0.18, alpha: 1)
        floorMat.roughness.contents = 0.8
        floorMat.metalness.contents = 0.1
        oceanFloor.materials = [floorMat]
        let floorNode = SCNNode(geometry: oceanFloor)
        floorNode.eulerAngles = SCNVector3(-Float.pi / 2, 0, 0)
        floorNode.position = SCNVector3(0, -2.0, 0)
        root.addChildNode(floorNode)
        
        // ══════════════════════════════════════════════
        // ── MAIN FIBER OPTIC CABLE — glass tube the player runs through ──
        // ══════════════════════════════════════════════
        let tubeLength = CGFloat(cableLength + 20)
        
        // Outer glass shell — translucent, glowing blue-green
        let outerTube = SCNCylinder(radius: CGFloat(cableRadius), height: tubeLength)
        outerTube.radialSegmentCount = 32
        let outerMat = SCNMaterial()
        outerMat.diffuse.contents = UIColor(red: 0.0, green: 0.20, blue: 0.30, alpha: 0.12)
        outerMat.emission.contents = P.cyan.withAlphaComponent(0.08)
        outerMat.transparency = 0.25
        outerMat.isDoubleSided = true
        outerMat.blendMode = .add
        outerTube.materials = [outerMat]
        let outerNode = SCNNode(geometry: outerTube)
        outerNode.position = SCNVector3(0, Float(cableRadius) * 0.5, 0)
        outerNode.eulerAngles = SCNVector3(0, 0, Float.pi / 2)
        root.addChildNode(outerNode)
        
        // Wireframe overlay on the tube — hexagonal feel
        let wireTube = SCNCylinder(radius: CGFloat(cableRadius) + 0.02, height: tubeLength)
        wireTube.radialSegmentCount = 6
        let wireMat = SCNMaterial()
        wireMat.diffuse.contents = UIColor.clear
        wireMat.emission.contents = P.cyan.withAlphaComponent(0.4)
        wireMat.fillMode = .lines
        wireMat.transparency = 0.6
        wireTube.materials = [wireMat]
        let wireNode = SCNNode(geometry: wireTube)
        wireNode.position = outerNode.position
        wireNode.eulerAngles = outerNode.eulerAngles
        root.addChildNode(wireNode)
        
        // Inner floor walkway — the actual surface the player walks on
        let walkway = SCNBox(width: tubeLength, height: 0.08, length: CGFloat(cableRadius) * 1.4, chamferRadius: 0.02)
        let walkMat = SCNMaterial()
        walkMat.diffuse.contents = UIColor(red: 0.06, green: 0.12, blue: 0.22, alpha: 1)
        walkMat.metalness.contents = 0.7
        walkMat.roughness.contents = 0.2
        walkway.materials = [walkMat]
        let walkNode = SCNNode(geometry: walkway)
        walkNode.position = SCNVector3(0, -0.04, 0)
        root.addChildNode(walkNode)
        
        // Glowing center stripe on the walkway
        let stripe = SCNBox(width: tubeLength, height: 0.01, length: 0.15, chamferRadius: 0)
        let stripeMat = SCNMaterial()
        stripeMat.diffuse.contents = P.cyan.withAlphaComponent(0.3)
        stripeMat.emission.contents = P.cyan
        stripe.materials = [stripeMat]
        let stripeNode = SCNNode(geometry: stripe)
        stripeNode.position = SCNVector3(0, 0.01, 0)
        root.addChildNode(stripeNode)
        
        // Side guide stripes
        for side: Float in [-1, 1] {
            let sideStripe = SCNBox(width: tubeLength, height: 0.01, length: 0.08, chamferRadius: 0)
            let sMat = SCNMaterial()
            sMat.diffuse.contents = P.cyan.withAlphaComponent(0.15)
            sMat.emission.contents = P.cyan.withAlphaComponent(0.5)
            sideStripe.materials = [sMat]
            let sNode = SCNNode(geometry: sideStripe)
            sNode.position = SCNVector3(0, 0.01, side * Float(cableRadius) * 0.55)
            root.addChildNode(sNode)
        }
        
        // ══════════════════════════════════════════════
        // ── DATA PULSES — light orbs racing through the cable ──
        // ══════════════════════════════════════════════
        let pulseColors: [UIColor] = [P.cyan, P.cyan, P.lime, P.cyan, P.magenta, P.cyan, P.violet, P.cyan]
        for i in 0..<8 {
            let pulse = SCNSphere(radius: 0.2)
            let pMat = SCNMaterial()
            let color = pulseColors[i % pulseColors.count]
            pMat.diffuse.contents = color
            pMat.emission.contents = color
            pulse.materials = [pMat]
            let pNode = SCNNode(geometry: pulse)
            let startX = -cableLength / 2 + Float(i) * 10
            pNode.position = SCNVector3(startX, 0.5, Float.random(in: -1.0...1.0))
            root.addChildNode(pNode)
            
            let pLight = SCNLight()
            pLight.type = .omni
            pLight.color = color
            pLight.intensity = 200
            pLight.attenuationStartDistance = 1
            pLight.attenuationEndDistance = 6
            pNode.light = pLight
            
            let speed = Double.random(in: 3.0...6.0)
            let travel = SCNAction.moveBy(x: CGFloat(cableLength + 10), y: 0, z: 0, duration: speed)
            let reset = SCNAction.moveBy(x: -CGFloat(cableLength + 10), y: 0, z: 0, duration: 0)
            pNode.runAction(SCNAction.repeatForever(SCNAction.sequence([travel, reset])))
        }
        
        // ══════════════════════════════════════════════
        // ── RING MARKERS — periodic glowing rings inside the tube ──
        // ══════════════════════════════════════════════
        let ringSpacing: Float = 8
        var ringX: Float = -cableLength / 2
        while ringX <= cableLength / 2 {
            let ring = SCNTorus(ringRadius: CGFloat(cableRadius) * 0.85, pipeRadius: 0.04)
            let ringMat = SCNMaterial()
            ringMat.diffuse.contents = P.cyan.withAlphaComponent(0.2)
            ringMat.emission.contents = P.cyan
            ring.materials = [ringMat]
            let ringNode = SCNNode(geometry: ring)
            ringNode.position = SCNVector3(ringX, Float(cableRadius) * 0.5, 0)
            ringNode.eulerAngles = SCNVector3(0, 0, Float.pi / 2)
            root.addChildNode(ringNode)
            
            // Subtle pulse animation staggered by position
            let delay = SCNAction.wait(duration: Double(abs(ringX)).truncatingRemainder(dividingBy: 3))
            let fadeOut = SCNAction.fadeOpacity(to: 0.3, duration: 1.0)
            let fadeIn = SCNAction.fadeOpacity(to: 1.0, duration: 1.0)
            ringNode.runAction(SCNAction.sequence([delay, SCNAction.repeatForever(SCNAction.sequence([fadeOut, fadeIn]))]))
            
            ringX += ringSpacing
        }
        
        // ══════════════════════════════════════════════
        // ── OCEAN SCENERY OUTSIDE THE CABLE (decorative, no collision) ──
        // ══════════════════════════════════════════════
        
        // Coral formations outside the tube — visible through the glass
        let coralPositions: [(x: Float, z: Float, color: UIColor, size: CGFloat)] = [
            (-30, -8, P.coral, 1.8),  (-20, 9, P.magenta, 1.4),
            (-10, -10, P.violet, 1.6), (0, 10, P.coral, 2.0),
            (10, -9, P.magenta, 1.3), (20, 8, P.violet, 1.5),
            (30, -7, P.coral, 1.7),   (-25, 7, P.lime, 1.2),
            (15, 11, P.magenta, 1.0), (25, -11, P.violet, 1.4),
        ]
        for (cx, cz, color, size) in coralPositions {
            let coralNode = SCNNode()
            let rock = SCNSphere(radius: size)
            let rMat = SCNMaterial()
            rMat.diffuse.contents = UIColor(red: 0.10, green: 0.06, blue: 0.04, alpha: 1)
            rMat.roughness.contents = 0.9
            rock.materials = [rMat]
            let rNode = SCNNode(geometry: rock)
            rNode.position = SCNVector3(0, Float(size) * 0.4, 0)
            rNode.scale = SCNVector3(1, 0.5, 1)
            coralNode.addChildNode(rNode)
            
            for _ in 0..<5 {
                let tip = SCNCylinder(radius: CGFloat.random(in: 0.08...0.18), height: CGFloat.random(in: 0.5...1.2))
                let tMat = SCNMaterial()
                tMat.diffuse.contents = color.withAlphaComponent(0.6)
                tMat.emission.contents = color
                tip.materials = [tMat]
                let tNode = SCNNode(geometry: tip)
                tNode.position = SCNVector3(Float.random(in: -0.5...0.5), Float(size) * 0.3 + Float.random(in: 0.2...0.7), Float.random(in: -0.5...0.5))
                coralNode.addChildNode(tNode)
            }
            coralNode.position = SCNVector3(cx, -1.5, cz)
            root.addChildNode(coralNode)
        }
        
        // Bioluminescent jellyfish-like particles floating outside
        for _ in 0..<30 {
            let jelly = SCNSphere(radius: CGFloat.random(in: 0.15...0.4))
            let jMat = SCNMaterial()
            let jellyColor = [P.cyan, P.magenta, P.violet, P.lime].randomElement()!
            jMat.diffuse.contents = jellyColor.withAlphaComponent(0.3)
            jMat.emission.contents = jellyColor
            jMat.transparency = 0.6
            jelly.materials = [jMat]
            let jNode = SCNNode(geometry: jelly)
            jNode.position = SCNVector3(
                Float.random(in: -cableLength/2...cableLength/2),
                Float.random(in: 0...8),
                Float.random(in: -15...(-5)) // outside the cable on one side
            )
            // Randomize which side
            if Bool.random() { jNode.position.z = -jNode.position.z }
            root.addChildNode(jNode)
            
            // Gentle floating
            let drift = SCNAction.moveBy(
                x: CGFloat.random(in: -2...2),
                y: CGFloat.random(in: -1.5...1.5),
                z: CGFloat.random(in: -1...1),
                duration: Double.random(in: 4...8)
            )
            jNode.runAction(SCNAction.repeatForever(SCNAction.sequence([drift, drift.reversed()])))
        }
        
        // Bubbles rising outside
        for _ in 0..<25 {
            let bubble = SCNSphere(radius: CGFloat.random(in: 0.04...0.14))
            let bMat = SCNMaterial()
            bMat.diffuse.contents = UIColor.white.withAlphaComponent(0.3)
            bMat.emission.contents = UIColor.white.withAlphaComponent(0.1)
            bMat.transparency = 0.5
            bubble.materials = [bMat]
            let bNode = SCNNode(geometry: bubble)
            bNode.position = SCNVector3(
                Float.random(in: -cableLength/2...cableLength/2),
                Float.random(in: -1...2),
                Float.random(in: -12...12)
            )
            root.addChildNode(bNode)
            
            let rise = SCNAction.moveBy(x: 0, y: CGFloat.random(in: 5...12), z: 0, duration: Double.random(in: 6...14))
            let resetB = SCNAction.move(to: SCNVector3(
                Float.random(in: -cableLength/2...cableLength/2),
                Float.random(in: -1...0),
                Float.random(in: -12...12)
            ), duration: 0)
            bNode.runAction(SCNAction.repeatForever(SCNAction.sequence([rise, resetB])))
        }
        
        // ══════════════════════════════════════════════
        // ── LIGHTING — bright underwater glow ──
        // ══════════════════════════════════════════════
        
        // Overhead caustic-style lights along the cable
        for xPos in stride(from: Int(-cableLength / 2), through: Int(cableLength / 2), by: 15) {
            let caustic = SCNLight()
            caustic.type = .spot
            caustic.color = UIColor(red: 0.2, green: 0.6, blue: 0.9, alpha: 1)
            caustic.intensity = 400
            caustic.spotInnerAngle = 20
            caustic.spotOuterAngle = 65
            caustic.castsShadow = true
            caustic.shadowRadius = 3
            let cNode = SCNNode()
            cNode.light = caustic
            cNode.position = SCNVector3(Float(xPos), 8, 0)
            cNode.eulerAngles = SCNVector3(-Float.pi / 2, 0, 0)
            root.addChildNode(cNode)
        }
        
        // Cyan omni lights along the cable interior for glow
        for xPos in stride(from: Int(-cableLength / 2), through: Int(cableLength / 2), by: 10) {
            let omni = SCNLight()
            omni.type = .omni
            omni.color = P.cyan
            omni.intensity = 150
            omni.attenuationStartDistance = 2
            omni.attenuationEndDistance = 10
            let oNode = SCNNode()
            oNode.light = omni
            oNode.position = SCNVector3(Float(xPos), 1.5, 0)
            root.addChildNode(oNode)
        }
        
        // Ambient NPC packets traveling through the cable alongside the player
        makeAmbientPacket(in: root, bounds: CGSize(width: CGFloat(cableLength), height: CGFloat(cableRadius)), accentColor: P.cyan, yRange: 0.0...0.0, flowDirection: SCNVector3(1, 0, 0))
        
        manager.resetPlayerPosition(to: SCNVector3(-cableLength / 2 + 4, 0, 0))
    }
    
    // MARK: - DNS Library (Act 4)
    // Mystical library — towering shelves, floating books, purple haze
    private static func buildDNSLibrary(in manager: SceneManager) {
        manager.worldBounds = CGSize(width: 32, height: 24)
        let root = manager.scene.rootNode
        
        // Mystical library atmosphere — deep indigo-blue with warm amber undertones
        manager.scene.background.contents = SceneManager.makeGradientSky(
            topColor: UIColor(red: 0.06, green: 0.05, blue: 0.18, alpha: 1),
            midColor: UIColor(red: 0.10, green: 0.08, blue: 0.24, alpha: 1),
            bottomColor: UIColor(red: 0.16, green: 0.10, blue: 0.28, alpha: 1)
        )
        // Lighting environment for PBR reflections
        manager.scene.lightingEnvironment.contents = SceneManager.makeGradientSky(
            topColor: UIColor(red: 0.14, green: 0.10, blue: 0.28, alpha: 1),
            midColor: UIColor(red: 0.22, green: 0.16, blue: 0.36, alpha: 1),
            bottomColor: UIColor(red: 0.30, green: 0.22, blue: 0.42, alpha: 1)
        )
        manager.scene.lightingEnvironment.intensity = 2.5
        manager.scene.fogColor = UIColor(red: 0.06, green: 0.05, blue: 0.16, alpha: 1)
        manager.scene.fogStartDistance = 40
        manager.scene.fogEndDistance = 80
        
        // Polished floor — dark with warm amber grid lines
        let floor = makeGroundPlane(width: 36, length: 28, baseColor: UIColor(red: 0.06, green: 0.04, blue: 0.10, alpha: 1), accentColor: P.amber)
        root.addChildNode(floor)
        
        // ══════════════════════════════════════════════
        // ── BOOKSHELVES — open-face units with visible books ──
        // ══════════════════════════════════════════════
        let shelfPositions: [(x: Float, z: Float, h: CGFloat, tiers: Int)] = [
            (-12, -8, 5, 4), (-12, -2, 4, 3), (-12, 4, 5, 4), (-12, 9, 3.5, 3),
            (-6, -7, 4, 3), (-6, 4, 5, 4),
            (6, -6, 5, 4), (6, 1, 4, 3), (6, 7, 3.5, 3),
            (12, -4, 5, 4), (12, 3, 4, 3), (12, 8, 5, 4),
        ]
        
        // Warm dark-wood cyber material — NOT purple
        let woodDark = UIColor(red: 0.14, green: 0.09, blue: 0.06, alpha: 1)
        let woodMid  = UIColor(red: 0.22, green: 0.14, blue: 0.08, alpha: 1)
        let woodEdge = UIColor(red: 0.55, green: 0.35, blue: 0.15, alpha: 1)   // warm amber edge
        let shelfWidth: CGFloat  = 2.6
        let shelfDepth: CGFloat  = 1.0
        let panelThickness: CGFloat = 0.06
        let tierHeight: CGFloat = 1.2
        
        for shelf in shelfPositions {
            let shelfNode = SCNNode()
            let totalH = shelf.h
            
            // Shared dark-wood material for frame panels
            let frameMat = SCNMaterial()
            frameMat.diffuse.contents = woodDark
            frameMat.roughness.contents = 0.55
            frameMat.metalness.contents = 0.35
            
            // ── Back panel ──
            let backPanel = SCNBox(width: shelfWidth, height: totalH, length: panelThickness, chamferRadius: 0)
            backPanel.materials = [frameMat]
            let backNode = SCNNode(geometry: backPanel)
            backNode.position = SCNVector3(0, Float(totalH / 2), -Float(shelfDepth / 2))
            shelfNode.addChildNode(backNode)
            
            // ── Side panels (left & right) ──
            let sidePanel = SCNBox(width: panelThickness, height: totalH, length: shelfDepth, chamferRadius: 0)
            sidePanel.materials = [frameMat]
            let leftSide = SCNNode(geometry: sidePanel)
            leftSide.position = SCNVector3(-Float(shelfWidth / 2), Float(totalH / 2), 0)
            shelfNode.addChildNode(leftSide)
            let rightSide = SCNNode(geometry: sidePanel)
            rightSide.position = SCNVector3(Float(shelfWidth / 2), Float(totalH / 2), 0)
            shelfNode.addChildNode(rightSide)
            
            // ── Top cap ──
            let topCap = SCNBox(width: shelfWidth + 0.08, height: panelThickness, length: shelfDepth + 0.06, chamferRadius: 0.02)
            let topMat = SCNMaterial()
            topMat.diffuse.contents = woodMid
            topMat.roughness.contents = 0.45
            topMat.metalness.contents = 0.4
            topCap.materials = [topMat]
            let topNode = SCNNode(geometry: topCap)
            topNode.position = SCNVector3(0, Float(totalH) + Float(panelThickness / 2), 0)
            shelfNode.addChildNode(topNode)
            
            // ── Horizontal shelf dividers + books on each tier ──
            let bookColors: [UIColor] = [
                UIColor(red: 0.2, green: 0.75, blue: 0.9, alpha: 1),  // soft cyan
                UIColor(red: 0.95, green: 0.55, blue: 0.2, alpha: 1), // warm orange
                UIColor(red: 0.4, green: 0.85, blue: 0.5, alpha: 1),  // green
                UIColor(red: 0.85, green: 0.3, blue: 0.4, alpha: 1),  // red/coral
                UIColor(red: 0.7, green: 0.5, blue: 1.0, alpha: 1),   // lavender
                UIColor(red: 1.0, green: 0.82, blue: 0.3, alpha: 1),  // gold
                UIColor(red: 0.3, green: 0.55, blue: 0.95, alpha: 1), // blue
                UIColor(red: 0.9, green: 0.4, blue: 0.7, alpha: 1),   // pink
            ]
            
            for tier in 0..<shelf.tiers {
                let shelfY = Float(tier) * Float(tierHeight)
                
                // Shelf plank
                let plank = SCNBox(width: shelfWidth - panelThickness, height: panelThickness, length: shelfDepth - panelThickness, chamferRadius: 0)
                let plankMat = SCNMaterial()
                plankMat.diffuse.contents = woodMid
                plankMat.roughness.contents = 0.5
                plankMat.metalness.contents = 0.35
                plank.materials = [plankMat]
                let plankNode = SCNNode(geometry: plank)
                plankNode.position = SCNVector3(0, shelfY + Float(panelThickness / 2), 0)
                shelfNode.addChildNode(plankNode)
                
                // ── Books on this shelf — varied sizes, colorful spines ──
                let numBooks = Int.random(in: 5...8)
                var xCursor: Float = -Float(shelfWidth / 2) + 0.15
                let maxX: Float = Float(shelfWidth / 2) - 0.15
                
                for _ in 0..<numBooks {
                    if xCursor > maxX - 0.15 { break }
                    
                    let bWidth: Float  = Float.random(in: 0.18...0.32)
                    let bHeight: Float = Float.random(in: 0.65...Float(tierHeight) - 0.15)
                    let bDepth: Float  = Float.random(in: 0.5...0.75)
                    let bColor = bookColors.randomElement()!
                    
                    let book = SCNBox(width: CGFloat(bWidth), height: CGFloat(bHeight), length: CGFloat(bDepth), chamferRadius: 0.01)
                    let bMat = SCNMaterial()
                    bMat.diffuse.contents = bColor.withAlphaComponent(0.85)
                    bMat.emission.contents = bColor
                    bMat.emission.intensity = 0.35
                    bMat.roughness.contents = 0.6
                    bMat.metalness.contents = 0.15
                    book.materials = [bMat]
                    
                    let bNode = SCNNode(geometry: book)
                    bNode.position = SCNVector3(
                        xCursor + bWidth / 2,
                        shelfY + Float(panelThickness) + bHeight / 2,
                        Float.random(in: -0.08...0.08)
                    )
                    // Slight random tilt for realism
                    bNode.eulerAngles.z = Float.random(in: -0.06...0.06)
                    shelfNode.addChildNode(bNode)
                    
                    xCursor += bWidth + Float.random(in: 0.02...0.06)
                }
                
                // Occasional small glowing orb on the shelf (like a data crystal)
                if Bool.random() {
                    let orbSize = CGFloat.random(in: 0.08...0.14)
                    let orbColor: UIColor = [P.cyan, P.amber, P.lime].randomElement()!
                    let orb = SCNSphere(radius: orbSize)
                    let orbMat = SCNMaterial()
                    orbMat.diffuse.contents = orbColor
                    orbMat.emission.contents = orbColor
                    orb.materials = [orbMat]
                    let orbNode = SCNNode(geometry: orb)
                    orbNode.position = SCNVector3(
                        Float.random(in: -0.8...0.8),
                        shelfY + Float(panelThickness) + Float(orbSize),
                        Float.random(in: -0.2...0.2)
                    )
                    shelfNode.addChildNode(orbNode)
                }
            }
            
            // ── Warm amber edge accent strip at top ──
            let edgeStrip = SCNBox(width: shelfWidth + 0.1, height: 0.03, length: shelfDepth + 0.08, chamferRadius: 0.02)
            let edgeMat = SCNMaterial()
            edgeMat.diffuse.contents = woodEdge.withAlphaComponent(0.3)
            edgeMat.emission.contents = woodEdge
            edgeMat.emission.intensity = 0.5
            edgeStrip.materials = [edgeMat]
            let edgeNode = SCNNode(geometry: edgeStrip)
            edgeNode.position = SCNVector3(0, Float(totalH) + Float(panelThickness) + 0.02, 0)
            shelfNode.addChildNode(edgeNode)
            
            // ── Warm light per shelf — amber/gold instead of purple ──
            let shelfLight = SCNLight()
            shelfLight.type = .omni
            shelfLight.color = UIColor(red: 1.0, green: 0.85, blue: 0.55, alpha: 1) // warm amber
            shelfLight.intensity = 200
            shelfLight.attenuationStartDistance = 1.0
            shelfLight.attenuationEndDistance = 6
            let shelfLightNode = SCNNode()
            shelfLightNode.light = shelfLight
            shelfLightNode.position = SCNVector3(0, Float(totalH) + 0.5, 0.8)
            shelfNode.addChildNode(shelfLightNode)
            
            shelfNode.position = SCNVector3(shelf.x, 0, shelf.z)
            root.addChildNode(shelfNode)
            registerBox(manager, x: shelf.x, z: shelf.z, w: shelfWidth, l: shelfDepth)
        }
        
        // Central reading desk — dark wood with warm amber trim
        let desk = SCNBox(width: 4, height: 0.8, length: 2.5, chamferRadius: 0.08)
        let deskMat = SCNMaterial()
        deskMat.diffuse.contents = UIColor(red: 0.16, green: 0.10, blue: 0.06, alpha: 1)
        deskMat.roughness.contents = 0.45
        deskMat.metalness.contents = 0.4
        desk.materials = [deskMat]
        let deskNode = SCNNode(geometry: desk)
        deskNode.position = SCNVector3(0, 0.4, 0)
        root.addChildNode(deskNode)
        
        // Desk warm edge glow
        let deskWire = SCNBox(width: 4.02, height: 0.82, length: 2.52, chamferRadius: 0.09)
        let deskWireMat = SCNMaterial()
        deskWireMat.diffuse.contents = UIColor.clear
        deskWireMat.emission.contents = UIColor(red: 0.55, green: 0.35, blue: 0.15, alpha: 1)
        deskWireMat.fillMode = .lines
        deskWireMat.transparency = 0.6
        deskWire.materials = [deskWireMat]
        let deskWireNode = SCNNode(geometry: deskWire)
        deskWireNode.position = SCNVector3(0, 0.4, 0)
        root.addChildNode(deskWireNode)
        registerBox(manager, x: 0, z: 0, w: 4, l: 2.5)
        
        // Desk lamp light — warm amber glow from above the desk
        let deskLight = SCNLight()
        deskLight.type = .omni
        deskLight.color = UIColor(red: 1.0, green: 0.82, blue: 0.5, alpha: 1)
        deskLight.intensity = 600
        deskLight.attenuationStartDistance = 3
        deskLight.attenuationEndDistance = 15
        let deskLightNode = SCNNode()
        deskLightNode.light = deskLight
        deskLightNode.position = SCNVector3(0, 4, 0)
        root.addChildNode(deskLightNode)
        
        // Glowing holographic book floating above desk
        let holoBook = SCNBox(width: 1.2, height: 0.08, length: 0.8, chamferRadius: 0.02)
        let holoMat = SCNMaterial()
        holoMat.diffuse.contents = P.cyan.withAlphaComponent(0.3)
        holoMat.emission.contents = P.cyan
        holoMat.transparency = 0.6
        holoMat.isDoubleSided = true
        holoBook.materials = [holoMat]
        let holoNode = SCNNode(geometry: holoBook)
        holoNode.position = SCNVector3(0, 1.8, 0)
        let hover = SCNAction.moveBy(x: 0, y: 0.3, z: 0, duration: 1.5)
        hover.timingMode = .easeInEaseOut
        let hoverBack = hover.reversed()
        let spin = SCNAction.rotateBy(x: 0, y: CGFloat.pi * 2, z: 0, duration: 12)
        holoNode.runAction(SCNAction.repeatForever(SCNAction.group([SCNAction.sequence([hover, hoverBack]), spin])))
        root.addChildNode(holoNode)
        
        // Holographic light projection from the book
        let holoLight = SCNLight()
        holoLight.type = .omni
        holoLight.color = P.cyan
        holoLight.intensity = 500
        holoLight.attenuationStartDistance = 1
        holoLight.attenuationEndDistance = 8
        holoNode.light = holoLight
        
        // Scene-wide spot lights — warm-tinted, pointing down for shelf illumination
        let librarySpots: [(x: Float, z: Float)] = [(-12, -5), (-12, 5), (-6, 0), (6, 0), (12, -5), (12, 5), (0, -8), (0, 8)]
        for spot in librarySpots {
            let sLight = SCNLight()
            sLight.type = .spot
            sLight.color = UIColor(red: 0.95, green: 0.80, blue: 0.55, alpha: 1)
            sLight.intensity = 600
            sLight.spotInnerAngle = 25
            sLight.spotOuterAngle = 70
            sLight.castsShadow = true
            sLight.shadowRadius = 3
            sLight.attenuationStartDistance = 3
            sLight.attenuationEndDistance = 18
            let sNode = SCNNode()
            sNode.light = sLight
            sNode.position = SCNVector3(spot.x, 10, spot.z)
            sNode.eulerAngles = SCNVector3(-Float.pi / 2, 0, 0) // Point straight down
            root.addChildNode(sNode)
        }
        
        // Large ambient fill lights — warm amber-violet blend
        let fillPositions: [(x: Float, z: Float)] = [(-8, -4), (-8, 4), (0, 0), (8, -4), (8, 4)]
        for fill in fillPositions {
            let fLight = SCNLight()
            fLight.type = .omni
            fLight.color = UIColor(red: 0.85, green: 0.65, blue: 0.45, alpha: 1)
            fLight.intensity = 350
            fLight.attenuationStartDistance = 4
            fLight.attenuationEndDistance = 20
            let fNode = SCNNode()
            fNode.light = fLight
            fNode.position = SCNVector3(fill.x, 5, fill.z)
            root.addChildNode(fNode)
        }
        
        // Key directional light — warm white for natural illumination
        let keyLight = SCNLight()
        keyLight.type = .directional
        keyLight.color = UIColor(red: 0.9, green: 0.82, blue: 0.7, alpha: 1)
        keyLight.intensity = 400
        keyLight.castsShadow = true
        keyLight.shadowRadius = 4
        let keyNode = SCNNode()
        keyNode.light = keyLight
        keyNode.position = SCNVector3(0, 12, -5)
        keyNode.eulerAngles = SCNVector3(-Float.pi / 3, 0, 0)
        root.addChildNode(keyNode)
        
        // Floating knowledge orbs — larger and brighter
        for _ in 0..<20 {
            let orb = makeDataParticle(
                color: [P.violet, P.magenta, P.cyan].randomElement()!,
                at: SCNVector3(Float.random(in: -14...14), Float.random(in: 2...9), Float.random(in: -10...10)),
                size: CGFloat.random(in: 0.12...0.3)
            )
            root.addChildNode(orb)
        }
        
        // Floating rune rings — mystical decoration around the library
        for i in 0..<4 {
            let runeRing = SCNTorus(ringRadius: CGFloat.random(in: 1.5...3.0), pipeRadius: 0.04)
            let runeMat = SCNMaterial()
            runeMat.diffuse.contents = P.amber.withAlphaComponent(0.3)
            runeMat.emission.contents = P.amber
            runeRing.materials = [runeMat]
            let runeNode = SCNNode(geometry: runeRing)
            runeNode.position = SCNVector3(Float(i) * 6 - 9, Float.random(in: 4...7), Float.random(in: -6...6))
            runeNode.eulerAngles = SCNVector3(Float.random(in: -0.3...0.3), 0, Float.random(in: -0.3...0.3))
            let spin = SCNAction.rotateBy(x: 0, y: CGFloat.pi * 2, z: 0, duration: Double.random(in: 8...15))
            runeNode.runAction(SCNAction.repeatForever(spin))
            root.addChildNode(runeNode)
        }
        
        root.addChildNode(makeSignPanel(color: P.amber, at: SCNVector3(0, 8, -12)))
        
        // Knowledge packets floating between the shelves
        makeAmbientPacket(in: root, bounds: manager.worldBounds, accentColor: P.amber, yRange: 2.0...7.0, flowDirection: SCNVector3(0, 0, 1))
        
        manager.resetPlayerPosition(to: SCNVector3(-12, 0, 0))
    }
    
    // MARK: - Return Journey (Act 5)
    // Urgent high-speed corridor — amber/coral streaks, flashing lights, tunnel rush
    private static func buildReturnJourney(in manager: SceneManager) {
        manager.worldBounds = CGSize(width: 30, height: 16)
        let root = manager.scene.rootNode
        
        // Hot atmosphere — warm amber/coral sky for urgency
        manager.scene.background.contents = SceneManager.makeGradientSky(
            topColor: UIColor(red: 0.12, green: 0.04, blue: 0.04, alpha: 1),
            midColor: UIColor(red: 0.18, green: 0.08, blue: 0.06, alpha: 1),
            bottomColor: UIColor(red: 0.28, green: 0.14, blue: 0.06, alpha: 1)
        )
        manager.scene.fogColor = UIColor(red: 0.12, green: 0.06, blue: 0.04, alpha: 1)
        manager.scene.fogStartDistance = 25
        manager.scene.fogEndDistance = 55
        
        let floor = makeGroundPlane(width: 34, length: 20, baseColor: UIColor(red: 0.06, green: 0.03, blue: 0.02, alpha: 1), accentColor: P.coral)
        root.addChildNode(floor)
        
        // Tunnel walls — solid panels with neon trim
        for side in [-1, 1] as [Float] {
            // Continuous wall panels
            for i in 0..<6 {
                let wall = SCNBox(width: 5, height: 4, length: 0.3, chamferRadius: 0)
                let wMat = SCNMaterial()
                wMat.diffuse.contents = UIColor(red: 0.06, green: 0.04, blue: 0.04, alpha: 1)
                wMat.metalness.contents = 0.6
                wMat.roughness.contents = 0.3
                wall.materials = [wMat]
                let wNode = SCNNode(geometry: wall)
                wNode.position = SCNVector3(Float(i) * 5 - 12.5, 2, side * 7)
                root.addChildNode(wNode)
                registerBox(manager, x: Float(i) * 5 - 12.5, z: side * 7, w: 5, l: 0.3)
                
                // Neon stripe along top of wall
                let stripe = SCNBox(width: 5, height: 0.08, length: 0.35, chamferRadius: 0)
                let sMat = SCNMaterial()
                sMat.diffuse.contents = P.coral
                sMat.emission.contents = P.coral
                stripe.materials = [sMat]
                let sNode = SCNNode(geometry: stripe)
                sNode.position = SCNVector3(Float(i) * 5 - 12.5, 4, side * 7)
                root.addChildNode(sNode)
            }
            
            // Vertical accent pillars along walls
            for i in 0..<8 {
                let pillar = SCNCylinder(radius: 0.12, height: 4)
                let pMat = SCNMaterial()
                pMat.diffuse.contents = P.amber.withAlphaComponent(0.4)
                pMat.emission.contents = P.amber.withAlphaComponent(0.6)
                pillar.materials = [pMat]
                let pNode = SCNNode(geometry: pillar)
                pNode.position = SCNVector3(Float(i) * 4 - 14, 2, side * 7.15)
                root.addChildNode(pNode)
            }
        }
        
        // Speed streaks flying past
        for _ in 0..<30 {
            let streakLen = CGFloat.random(in: 3...8)
            let streak = SCNBox(width: streakLen, height: 0.04, length: 0.04, chamferRadius: 0)
            let slMat = SCNMaterial()
            let streakColor: UIColor = [P.amber, P.coral, P.magenta].randomElement()!
            slMat.diffuse.contents = streakColor
            slMat.emission.contents = streakColor
            slMat.transparency = CGFloat.random(in: 0.3...0.7)
            streak.materials = [slMat]
            let slNode = SCNNode(geometry: streak)
            slNode.position = SCNVector3(Float.random(in: -15...15), Float.random(in: 0.5...4), Float.random(in: -6...6))
            root.addChildNode(slNode)
            
            let rush = SCNAction.moveBy(x: -35, y: 0, z: 0, duration: Double.random(in: 0.8...2.5))
            let resetR = SCNAction.moveBy(x: 35, y: 0, z: 0, duration: 0)
            slNode.runAction(SCNAction.repeatForever(SCNAction.sequence([rush, resetR])))
        }
        
        // Overhead cables
        for i in 0..<4 {
            let cable = SCNCylinder(radius: 0.06, height: 30)
            let cMat = SCNMaterial()
            cMat.diffuse.contents = UIColor(red: 0.15, green: 0.08, blue: 0.04, alpha: 1)
            cMat.metalness.contents = 0.7
            cable.materials = [cMat]
            let cNode = SCNNode(geometry: cable)
            cNode.position = SCNVector3(0, 4.5, Float(i) * 3 - 5)
            cNode.eulerAngles = SCNVector3(0, 0, Float.pi / 2)
            root.addChildNode(cNode)
        }
        
        // Flashing urgency lights
        for i in 0..<5 {
            let urgentLight = SCNLight()
            urgentLight.type = .omni
            urgentLight.color = P.coral
            urgentLight.intensity = 400
            urgentLight.attenuationStartDistance = 2
            urgentLight.attenuationEndDistance = 8
            let urgentNode = SCNNode()
            urgentNode.light = urgentLight
            urgentNode.position = SCNVector3(Float(i) * 7 - 14, 4, 0)
            root.addChildNode(urgentNode)
            
            let delay = SCNAction.wait(duration: Double(i) * 0.15)
            let flashOn  = SCNAction.customAction(duration: 0.3) { n, _ in n.light?.intensity = 800 }
            let flashOff = SCNAction.customAction(duration: 0.3) { n, _ in n.light?.intensity = 200 }
            urgentNode.runAction(SCNAction.sequence([delay, SCNAction.repeatForever(SCNAction.sequence([flashOn, flashOff]))]))
        }
        
        root.addChildNode(makeSignPanel(color: P.amber, at: SCNVector3(0, 5, -8)))
        
        // Packets racing alongside you
        makeAmbientPacket(in: root, bounds: manager.worldBounds, accentColor: P.coral, yRange: 0.5...3.5, flowDirection: SCNVector3(-1, 0, 0))
        
        manager.resetPlayerPosition(to: SCNVector3(-12, 0, 0))
        // Data Congestion Blocks (Obstacles)
        let blockPositions: [(x: Float, z: Float)] = [
            (-5, -2), (2, 3), (8, -4)
        ]
        for pos in blockPositions {
            let block = SCNBox(width: 2, height: 2, length: 2, chamferRadius: 0.2)
            let bMat = SCNMaterial()
            bMat.diffuse.contents = UIColor(red: 0.2, green: 0.05, blue: 0.05, alpha: 1)
            bMat.emission.contents = P.coral.withAlphaComponent(0.2)
            bMat.metalness.contents = 0.8
            block.materials = [bMat]
            
            let bNode = SCNNode(geometry: block)
            bNode.position = SCNVector3(pos.x, 1, pos.z)
            
            // Add a warning light to the block
            let warnLight = SCNLight()
            warnLight.type = .omni
            warnLight.color = P.coral
            warnLight.intensity = 150
            let wNode = SCNNode()
            wNode.light = warnLight
            wNode.position = SCNVector3(0, 1.5, 0)
            bNode.addChildNode(wNode)
            
            root.addChildNode(bNode)
            registerBox(manager, x: pos.x, z: pos.z, w: 2.2, l: 2.2) // slightly larger collision box
        }
    }
    
    // MARK: - Default Floor (Fallback)
    private static func buildDefaultFloor(in manager: SceneManager) {
        manager.worldBounds = CGSize(width: 30, height: 20)
        let root = manager.scene.rootNode
        let floor = makeGroundPlane(width: 34, length: 24, baseColor: UIColor(red: 0.06, green: 0.06, blue: 0.1, alpha: 1), accentColor: P.cyan)
        root.addChildNode(floor)
        manager.resetPlayerPosition()
    }
}
