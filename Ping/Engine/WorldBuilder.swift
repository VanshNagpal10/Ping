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
    
    /// Creates a textured ground plane with subtle grid and edge glow
    private static func makeGroundPlane(
        width: CGFloat = 40,
        length: CGFloat = 30,
        baseColor: UIColor = P.floorBase,
        accentColor: UIColor = P.cyan
    ) -> SCNNode {
        let floor = SCNNode()
        
        // Base plane — slightly reflective
        let plane = SCNPlane(width: width, height: length)
        let baseMat = SCNMaterial()
        baseMat.diffuse.contents = baseColor
        baseMat.roughness.contents = 0.6
        baseMat.metalness.contents = 0.15
        plane.materials = [baseMat]
        let baseNode = SCNNode(geometry: plane)
        baseNode.eulerAngles = SCNVector3(-Float.pi / 2, 0, 0)
        baseNode.position = SCNVector3(0, -0.01, 0)
        floor.addChildNode(baseNode)
        
        // Sparse grid lines — only major ones for cleaner look
        let spacing: Float = 4.0
        let halfW = Float(width) / 2
        let halfL = Float(length) / 2
        
        let lineMat = SCNMaterial()
        lineMat.diffuse.contents = accentColor.withAlphaComponent(0.08)
        lineMat.emission.contents = accentColor.withAlphaComponent(0.15)
        
        var x: Float = -halfW
        while x <= halfW {
            let line = SCNBox(width: 0.02, height: 0.003, length: CGFloat(length), chamferRadius: 0)
            line.materials = [lineMat]
            let node = SCNNode(geometry: line)
            node.position = SCNVector3(x, 0.003, 0)
            floor.addChildNode(node)
            x += spacing
        }
        var z: Float = -halfL
        while z <= halfL {
            let line = SCNBox(width: CGFloat(width), height: 0.003, length: 0.02, chamferRadius: 0)
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
        let box = SCNBox(width: width, height: height, length: length, chamferRadius: 0.04)
        let mat = SCNMaterial()
        mat.diffuse.contents = color
        mat.emission.contents = emissionColor.withAlphaComponent(0.02)
        mat.roughness.contents = 0.65
        mat.metalness.contents = 0.5
        box.materials = [mat]
        
        let node = SCNNode(geometry: box)
        node.position = SCNVector3(position.x, position.y + Float(height / 2), position.z)
        
        // Subtle neon edge wireframe
        let wireBox = SCNBox(width: width + 0.02, height: height + 0.02, length: length + 0.02, chamferRadius: 0.05)
        let wireMat = SCNMaterial()
        wireMat.diffuse.contents = UIColor.clear
        wireMat.emission.contents = emissionColor.withAlphaComponent(0.5)
        wireMat.fillMode = .lines
        wireMat.transparency = 0.06
        wireBox.materials = [wireMat]
        let wireNode = SCNNode(geometry: wireBox)
        node.addChildNode(wireNode)
        
        // Thin horizontal LED indicator strips (like server rack LEDs) — much subtler than windows
        let stripCount = max(1, Int(height) - 1)
        for i in 0..<stripCount {
            // Narrow strip across the front face
            let stripW = width * 0.6
            let strip = SCNBox(width: stripW, height: 0.03, length: 0.005, chamferRadius: 0)
            let sMat = SCNMaterial()
            let stripColor = (i % 3 == 0) ? P.magenta : emissionColor
            sMat.diffuse.contents = stripColor.withAlphaComponent(0.3)
            sMat.emission.contents = stripColor.withAlphaComponent(0.6)
            strip.materials = [sMat]
            let sNode = SCNNode(geometry: strip)
            sNode.position = SCNVector3(0, Float(i) * 0.8 - Float(height / 2) + 0.6, Float(length / 2) + 0.005)
            node.addChildNode(sNode)
            
            // Tiny dot LED at side
            let dot = SCNSphere(radius: 0.025)
            let dMat = SCNMaterial()
            let dotColor = [emissionColor, P.amber, P.lime].randomElement()!
            dMat.diffuse.contents = dotColor
            dMat.emission.contents = dotColor
            dot.materials = [dMat]
            let dNode = SCNNode(geometry: dot)
            dNode.position = SCNVector3(Float(stripW / 2) + 0.1, sNode.position.y, Float(length / 2) + 0.005)
            node.addChildNode(dNode)
            
            // Random blink on the LED dot
            if Bool.random() {
                let blink = SCNAction.sequence([
                    SCNAction.wait(duration: Double.random(in: 1...4)),
                    SCNAction.fadeOpacity(to: 0.1, duration: 0.15),
                    SCNAction.fadeOpacity(to: 1.0, duration: 0.15),
                    SCNAction.wait(duration: Double.random(in: 0.5...2))
                ])
                dNode.runAction(SCNAction.repeatForever(blink))
            }
        }
        
        // Top accent edge — thin glowing line on top
        let topEdge = SCNBox(width: width, height: 0.015, length: length, chamferRadius: 0)
        let topMat = SCNMaterial()
        topMat.diffuse.contents = emissionColor.withAlphaComponent(0.15)
        topMat.emission.contents = emissionColor.withAlphaComponent(0.4)
        topEdge.materials = [topMat]
        let topNode = SCNNode(geometry: topEdge)
        topNode.position = SCNVector3(0, Float(height / 2) + 0.01, 0)
        node.addChildNode(topNode)
        
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
        let halfW = Float(bounds.width) / 2 - 2
        let halfH = Float(bounds.height) / 2 - 2
        let yMin = yRange.lowerBound == 0 && yRange.upperBound == 0 ? Float(0) : yRange.lowerBound
        let yMax = yRange.lowerBound == 0 && yRange.upperBound == 0 ? Float(0) : yRange.upperBound
        
        for i in 0..<count {
            let color = colors[i % colors.count]
            let scale = Float.random(in: 0.25...0.4) // Small relative to player
            
            let packetNode = SCNNode()
            
            // Body — rounded box
            let body = SCNBox(width: CGFloat(0.6 * scale), height: CGFloat(0.7 * scale), length: CGFloat(0.5 * scale), chamferRadius: CGFloat(0.1 * scale))
            let bodyMat = SCNMaterial()
            bodyMat.diffuse.contents = UIColor(red: 0.12, green: 0.1, blue: 0.2, alpha: 1)
            bodyMat.metalness.contents = 0.5
            bodyMat.roughness.contents = 0.3
            body.materials = [bodyMat]
            let bodyNode = SCNNode(geometry: body)
            bodyNode.position = SCNVector3(0, 0.35 * scale, 0)
            packetNode.addChildNode(bodyNode)
            
            // Head — smaller rounded box
            let head = SCNBox(width: CGFloat(0.5 * scale), height: CGFloat(0.35 * scale), length: CGFloat(0.4 * scale), chamferRadius: CGFloat(0.1 * scale))
            let headMat = SCNMaterial()
            headMat.diffuse.contents = UIColor(red: 0.14, green: 0.12, blue: 0.24, alpha: 1)
            headMat.metalness.contents = 0.5
            head.materials = [headMat]
            let headNode = SCNNode(geometry: head)
            headNode.position = SCNVector3(0, 0.78 * scale, 0)
            packetNode.addChildNode(headNode)
            
            // Visor — colored glow plate (this is what makes each packet distinct)
            let visor = SCNBox(width: CGFloat(0.38 * scale), height: CGFloat(0.16 * scale), length: CGFloat(0.02 * scale), chamferRadius: CGFloat(0.04 * scale))
            let visorMat = SCNMaterial()
            visorMat.diffuse.contents = color.withAlphaComponent(0.3)
            visorMat.emission.contents = color
            visor.materials = [visorMat]
            let visorNode = SCNNode(geometry: visor)
            visorNode.position = SCNVector3(0, 0.76 * scale, 0.22 * scale)
            packetNode.addChildNode(visorNode)
            
            // Tiny eyes
            let eyeGeo = SCNSphere(radius: CGFloat(0.03 * scale))
            let eyeMat = SCNMaterial()
            eyeMat.diffuse.contents = color
            eyeMat.emission.contents = color
            eyeGeo.materials = [eyeMat]
            let leftEye = SCNNode(geometry: eyeGeo)
            leftEye.position = SCNVector3(-0.08 * scale, 0.78 * scale, 0.21 * scale)
            let rightEye = SCNNode(geometry: eyeGeo)
            rightEye.position = SCNVector3(0.08 * scale, 0.78 * scale, 0.21 * scale)
            packetNode.addChildNode(leftEye)
            packetNode.addChildNode(rightEye)
            
            // Accent stripe on body
            let stripe = SCNBox(width: CGFloat(0.62 * scale), height: CGFloat(0.03 * scale), length: CGFloat(0.52 * scale), chamferRadius: CGFloat(0.1 * scale))
            let stripeMat = SCNMaterial()
            stripeMat.diffuse.contents = color.withAlphaComponent(0.2)
            stripeMat.emission.contents = color
            stripe.materials = [stripeMat]
            let stripeNode = SCNNode(geometry: stripe)
            stripeNode.position = SCNVector3(0, 0.3 * scale, 0)
            packetNode.addChildNode(stripeNode)
            
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
                glowNode.position = SCNVector3(0, 0.4 * scale, 0)
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
                SCNAction.moveBy(x: 0, y: CGFloat(0.08 * scale), z: 0, duration: 0.6),
                SCNAction.moveBy(x: 0, y: CGFloat(-0.08 * scale), z: 0, duration: 0.6)
            ])
            bodyNode.runAction(SCNAction.repeatForever(bob))
            headNode.runAction(SCNAction.repeatForever(bob))
            
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
        
        // Tighter fog for this scene — makes it feel enclosed & deep
        manager.scene.fogStartDistance = 20
        manager.scene.fogEndDistance = 50
        manager.scene.fogColor = UIColor(red: 0.02, green: 0.01, blue: 0.06, alpha: 1)
        
        // ── Ground: dark hex-grid platform ──
        let floor = makeGroundPlane(width: 44, length: 34, accentColor: P.cyan)
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
        let darkColor = UIColor(red: 0.04, green: 0.03, blue: 0.08, alpha: 1)
        
        // Left corridor wall
        let leftWall: [(x: Float, z: Float, w: CGFloat, h: CGFloat, l: CGFloat)] = [
            (-14, -9, 1.8, 6, 1.4),  (-14, -5, 1.8, 8, 1.4),
            (-14, -1, 1.8, 5, 1.4),  (-14, 3, 1.8, 7, 1.4),
            (-14, 7, 1.8, 4, 1.4),   (-14, 10, 1.8, 6, 1.4),
        ]
        // Right corridor wall
        let rightWall: [(x: Float, z: Float, w: CGFloat, h: CGFloat, l: CGFloat)] = [
            (14, -8, 1.8, 7, 1.4),   (14, -4, 1.8, 5, 1.4),
            (14, 0, 1.8, 8, 1.4),    (14, 4, 1.8, 6, 1.4),
            (14, 8, 1.8, 5, 1.4),
        ]
        // Inner structures — processing nodes deeper in the scene
        let innerStructures: [(x: Float, z: Float, w: CGFloat, h: CGFloat, l: CGFloat)] = [
            (-7, -8, 1.5, 4, 1.5),    (3, -7, 2, 5, 1.5),
            (9, -9, 1.5, 6, 1.5),     (-8, 8, 1.5, 3, 1.5),
            (6, 8, 2, 4.5, 1.5),      (12, 6, 1.5, 3.5, 1.5),
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
        
        // ── Holographic Data Columns — translucent pillars of light ──
        let columnPositions: [(x: Float, z: Float, h: Float, color: UIColor)] = [
            (-10, -3, 8, P.cyan),    (-10, 3, 6, P.violet),
            (10, -2, 7, P.cyan),     (10, 4, 5, P.magenta),
            (0, -9, 9, P.cyan),      (0, 9, 7, P.violet),
            (-5, 0, 4, P.magenta),   (5, 0, 6, P.cyan),
        ]
        for col in columnPositions {
            let cylinder = SCNCylinder(radius: 0.15, height: CGFloat(col.h))
            let colMat = SCNMaterial()
            colMat.diffuse.contents = col.color.withAlphaComponent(0.08)
            colMat.emission.contents = col.color.withAlphaComponent(0.35)
            colMat.transparency = 0.5
            colMat.isDoubleSided = true
            cylinder.materials = [colMat]
            let colNode = SCNNode(geometry: cylinder)
            colNode.position = SCNVector3(col.x, col.h / 2, col.z)
            root.addChildNode(colNode)
            
            // Glow ring at the base
            let baseRing = SCNTorus(ringRadius: 0.4, pipeRadius: 0.03)
            let ringMat = SCNMaterial()
            ringMat.diffuse.contents = col.color.withAlphaComponent(0.3)
            ringMat.emission.contents = col.color
            baseRing.materials = [ringMat]
            let ringNode = SCNNode(geometry: baseRing)
            ringNode.position = SCNVector3(col.x, 0.03, col.z)
            root.addChildNode(ringNode)
            
            // Omni light at column base for pool of light on floor
            let colLight = SCNLight()
            colLight.type = .omni
            colLight.color = col.color
            colLight.intensity = 60
            colLight.attenuationStartDistance = 0
            colLight.attenuationEndDistance = 5
            let lNode = SCNNode()
            lNode.light = colLight
            lNode.position = SCNVector3(col.x, 0.5, col.z)
            root.addChildNode(lNode)
            
            // Column pulse animation
            let colPulse = SCNAction.sequence([
                SCNAction.fadeOpacity(to: 0.4, duration: Double.random(in: 1.5...3)),
                SCNAction.fadeOpacity(to: 0.9, duration: Double.random(in: 1.5...3))
            ])
            colNode.runAction(SCNAction.repeatForever(colPulse))
        }
        
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
                SCNAction.moveBy(x: 0, y: CGFloat.random(in: -0.3 ... -0.6), z: 0, duration: Double.random(in: 2...3.5))
            ])
            cubeNode.runAction(SCNAction.repeatForever(hover))
        }
        
        // ── Overhead Cable Conduits ──
        let pipePositions: [(SCNVector3, SCNVector3, UIColor)] = [
            (SCNVector3(-14, 5, -7), SCNVector3(-7, 5, -7), P.cyan),
            (SCNVector3(9, 6, -7), SCNVector3(14, 6, -7), P.cyan),
            (SCNVector3(-14, 4, 6), SCNVector3(-3, 4, 6), P.violet),
            (SCNVector3(6, 4.5, 6), SCNVector3(14, 4.5, 6), P.violet),
            (SCNVector3(-6, 7, -4), SCNVector3(6, 7, -4), P.magenta),
        ]
        for (start, end, color) in pipePositions {
            root.addChildNode(makePipe(from: start, to: end, radius: 0.05, color: color))
        }
        
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
    // Industrial rooftop — massive antenna, satellite dishes, cable runs
    private static func buildWiFiAntenna(in manager: SceneManager) {
        manager.worldBounds = CGSize(width: 30, height: 22)
        let root = manager.scene.rootNode
        
        // Concrete rooftop floor
        let floor = makeGroundPlane(width: 34, length: 26, baseColor: UIColor(red: 0.08, green: 0.07, blue: 0.1, alpha: 1), accentColor: P.lime)
        root.addChildNode(floor)
        
        // Main antenna tower
        let towerBase = SCNCylinder(radius: 0.5, height: 2)
        let tbMat = SCNMaterial()
        tbMat.diffuse.contents = UIColor(red: 0.15, green: 0.13, blue: 0.18, alpha: 1)
        tbMat.metalness.contents = 0.8
        tbMat.roughness.contents = 0.3
        towerBase.materials = [tbMat]
        let tbNode = SCNNode(geometry: towerBase)
        tbNode.position = SCNVector3(-4, 1, -4)
        root.addChildNode(tbNode)
        
        let towerShaft = SCNCylinder(radius: 0.2, height: 10)
        towerShaft.materials = [tbMat]
        let tsNode = SCNNode(geometry: towerShaft)
        tsNode.position = SCNVector3(-4, 7, -4)
        root.addChildNode(tsNode)
        
        // Antenna tip — bright glowing sphere
        let tip = SCNSphere(radius: 0.35)
        let tipMat = SCNMaterial()
        tipMat.diffuse.contents = P.lime
        tipMat.emission.contents = P.lime
        tip.materials = [tipMat]
        let tipNode = SCNNode(geometry: tip)
        tipNode.position = SCNVector3(-4, 12.5, -4)
        root.addChildNode(tipNode)
        
        let tipLight = SCNLight()
        tipLight.type = .omni
        tipLight.color = P.lime
        tipLight.intensity = 600
        tipLight.attenuationStartDistance = 2
        tipLight.attenuationEndDistance = 12
        tipNode.light = tipLight
        
        // WiFi wave rings
        for i in 0..<4 {
            let ring = SCNTorus(ringRadius: CGFloat(2 + i * 2), pipeRadius: 0.04)
            let ringMat = SCNMaterial()
            ringMat.diffuse.contents = P.lime.withAlphaComponent(CGFloat(0.5 - Float(i) * 0.1))
            ringMat.emission.contents = P.lime
            ring.materials = [ringMat]
            let ringNode = SCNNode(geometry: ring)
            ringNode.position = SCNVector3(-4, 10, -4)
            root.addChildNode(ringNode)
            
            let delay = Double(i) * 0.5
            let pulse = SCNAction.sequence([
                SCNAction.wait(duration: delay),
                SCNAction.scale(to: 1.2, duration: 1.5),
                SCNAction.scale(to: 1.0, duration: 1.5)
            ])
            ringNode.runAction(SCNAction.repeatForever(pulse))
        }
        
        // Satellite dishes
        let dishPositions: [(Float, Float)] = [(6, -3), (8, 4), (-8, 5)]
        for (dx, dz) in dishPositions {
            let dish = SCNSphere(radius: 1.0)
            dish.segmentCount = 12
            let dMat = SCNMaterial()
            dMat.diffuse.contents = UIColor(red: 0.2, green: 0.18, blue: 0.25, alpha: 1)
            dMat.metalness.contents = 0.7
            dMat.isDoubleSided = true
            dish.materials = [dMat]
            let dNode = SCNNode(geometry: dish)
            dNode.position = SCNVector3(dx, 1.5, dz)
            dNode.scale = SCNVector3(1, 0.4, 1)
            root.addChildNode(dNode)
            
            // Dish stem
            let stem = SCNCylinder(radius: 0.08, height: 1.5)
            stem.materials = [tbMat]
            let sNode = SCNNode(geometry: stem)
            sNode.position = SCNVector3(dx, 0.75, dz)
            root.addChildNode(sNode)
        }
        
        // Rooftop structures — AC units, vents
        root.addChildNode(makeBuilding(width: 2, height: 1.5, length: 2, color: P.slate, emissionColor: P.lime, at: SCNVector3(3, 0, -6)))
        registerBox(manager, x: 3, z: -6, w: 2, l: 2)
        root.addChildNode(makeBuilding(width: 1.5, height: 1, length: 1.5, color: P.slate, emissionColor: P.lime, at: SCNVector3(-10, 0, 3)))
        registerBox(manager, x: -10, z: 3, w: 1.5, l: 1.5)
        root.addChildNode(makeBuilding(width: 3, height: 0.4, length: 2, color: UIColor.darkGray, emissionColor: P.lime, at: SCNVector3(5, 0, 6)))
        registerBox(manager, x: 5, z: 6, w: 3, l: 2)
        
        // Tower base obstacle
        registerBox(manager, x: -4, z: -4, w: 1.2, l: 1.2)
        
        // Cable runs across rooftop
        for z: Float in [-2, 3, 7] {
            root.addChildNode(makePipe(from: SCNVector3(-12, 0.3, z), to: SCNVector3(12, 0.3, z), radius: 0.04, color: P.lime))
        }
        
        // Sign
        root.addChildNode(makeSignPanel(color: P.lime, width: 5, height: 1.2, at: SCNVector3(-6, 5, -10)))
        
        // Ambient packets floating across the rooftop
        makeAmbientPacket(in: root, bounds: manager.worldBounds, accentColor: P.lime, yRange: 1.5...8.0, flowDirection: SCNVector3(0, 1, 0))
        
        manager.resetPlayerPosition(to: SCNVector3(8, 0, 5))
    }
    
    // MARK: - Router Station (Act 2b)
    // Underground subway station — platforms, rails, overhead pipes, signage
    private static func buildRouterStation(in manager: SceneManager) {
        manager.worldBounds = CGSize(width: 32, height: 20)
        let root = manager.scene.rootNode
        
        let floor = makeGroundPlane(width: 36, length: 24, baseColor: UIColor(red: 0.06, green: 0.05, blue: 0.1, alpha: 1), accentColor: P.amber)
        root.addChildNode(floor)
        
        // Ceiling
        let ceiling = SCNPlane(width: 36, height: 24)
        let ceilMat = SCNMaterial()
        ceilMat.diffuse.contents = UIColor(red: 0.06, green: 0.05, blue: 0.08, alpha: 1)
        ceilMat.isDoubleSided = true
        ceiling.materials = [ceilMat]
        let ceilNode = SCNNode(geometry: ceiling)
        ceilNode.eulerAngles = SCNVector3(-Float.pi / 2, 0, 0)
        ceilNode.position = SCNVector3(0, 6, 0)
        root.addChildNode(ceilNode)
        
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
            wMat.diffuse.contents = UIColor(red: 0.08, green: 0.06, blue: 0.12, alpha: 1)
            wMat.metalness.contents = 0.3
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
        
        // Spot lights from ceiling
        for x: Float in [-8, 0, 8] {
            let spot = SCNLight()
            spot.type = .spot
            spot.color = P.amber
            spot.intensity = 200
            spot.spotInnerAngle = 15
            spot.spotOuterAngle = 50
            let sNode = SCNNode()
            sNode.light = spot
            sNode.position = SCNVector3(x, 5.8, 0)
            sNode.eulerAngles = SCNVector3(-Float.pi / 2, 0, 0)
            root.addChildNode(sNode)
        }
        
        root.addChildNode(makeSignPanel(color: P.amber, at: SCNVector3(0, 4.5, -9.5)))
        
        // Packets rushing through the station
        makeAmbientPacket(in: root, bounds: manager.worldBounds, accentColor: P.amber, yRange: 0.5...3.0, flowDirection: SCNVector3(1, 0, 0))
        
        manager.resetPlayerPosition(to: SCNVector3(-10, 0, 0))
    }
    
    // MARK: - Ocean Cable (Act 3)
    // Deep underwater — bioluminescence, coral, glass fiber tube, caustics
    private static func buildOceanCable(in manager: SceneManager) {
        manager.worldBounds = CGSize(width: 36, height: 16)
        let root = manager.scene.rootNode
        
        // Deep ocean floor — sandy/murky
        let oceanFloor = SCNPlane(width: 40, height: 30)
        let floorMat = SCNMaterial()
        floorMat.diffuse.contents = UIColor(red: 0.03, green: 0.05, blue: 0.12, alpha: 1)
        floorMat.roughness.contents = 0.9
        oceanFloor.materials = [floorMat]
        let floorNode = SCNNode(geometry: oceanFloor)
        floorNode.eulerAngles = SCNVector3(-Float.pi / 2, 0, 0)
        floorNode.position = SCNVector3(0, -0.01, 0)
        root.addChildNode(floorNode)
        
        // Underwater atmosphere
        manager.scene.background.contents = UIColor(red: 0.01, green: 0.02, blue: 0.08, alpha: 1)
        manager.scene.fogColor = UIColor(red: 0.01, green: 0.04, blue: 0.12, alpha: 1)
        manager.scene.fogStartDistance = 15
        manager.scene.fogEndDistance = 40
        
        // Fiber optic cable — horizontal glowing cylinder
        let cable = SCNCylinder(radius: 1.5, height: 30)
        let cableMat = SCNMaterial()
        cableMat.diffuse.contents = UIColor(red: 0.0, green: 0.15, blue: 0.25, alpha: 0.3)
        cableMat.emission.contents = P.cyan.withAlphaComponent(0.15)
        cableMat.transparency = 0.35
        cableMat.isDoubleSided = true
        cable.materials = [cableMat]
        let cableNode = SCNNode(geometry: cable)
        cableNode.position = SCNVector3(0, 1.5, 0)
        cableNode.eulerAngles = SCNVector3(0, 0, Float.pi / 2)
        root.addChildNode(cableNode)
        
        // Light pulses inside cable
        for i in 0..<5 {
            let pulse = SCNSphere(radius: 0.3)
            let pMat = SCNMaterial()
            pMat.diffuse.contents = P.cyan
            pMat.emission.contents = P.cyan
            pulse.materials = [pMat]
            let pNode = SCNNode(geometry: pulse)
            pNode.position = SCNVector3(-15 + Float(i) * 7, 1.5, 0)
            root.addChildNode(pNode)
            
            // Glow around pulse
            let pLight = SCNLight()
            pLight.type = .omni
            pLight.color = P.cyan
            pLight.intensity = 100
            pLight.attenuationStartDistance = 0.5
            pLight.attenuationEndDistance = 3
            pNode.light = pLight
            
            let travel = SCNAction.moveBy(x: 32, y: 0, z: 0, duration: Double(3 + i))
            let reset = SCNAction.moveBy(x: -32, y: 0, z: 0, duration: 0)
            pNode.runAction(SCNAction.repeatForever(SCNAction.sequence([travel, reset])))
        }
        
        // Coral formations — colorful bumpy shapes
        let coralData: [(Float, Float, UIColor, CGFloat)] = [
            (-12, -5, P.coral, 1.2),  (-8, 5, P.magenta, 0.9),
            (5, -4, P.violet, 1.0),   (10, 5, P.coral, 1.3),
            (14, -2, P.magenta, 0.8), (-5, -6, P.violet, 0.7),
            (3, 6, P.coral, 1.1),
        ]
        for (cx, cz, color, size) in coralData {
            let coralNode = SCNNode()
            // Base rock
            let rock = SCNSphere(radius: size)
            let rMat = SCNMaterial()
            rMat.diffuse.contents = UIColor(red: 0.12, green: 0.08, blue: 0.06, alpha: 1)
            rMat.roughness.contents = 1.0
            rock.materials = [rMat]
            let rNode = SCNNode(geometry: rock)
            rNode.position = SCNVector3(0, Float(size) * 0.5, 0)
            rNode.scale = SCNVector3(1, 0.6, 1)
            coralNode.addChildNode(rNode)
            
            // Glowing coral tips
            for _ in 0..<3 {
                let tip = SCNCylinder(radius: CGFloat.random(in: 0.06...0.12), height: CGFloat.random(in: 0.4...0.8))
                let tMat = SCNMaterial()
                tMat.diffuse.contents = color.withAlphaComponent(0.6)
                tMat.emission.contents = color
                tip.materials = [tMat]
                let tNode = SCNNode(geometry: tip)
                tNode.position = SCNVector3(Float.random(in: -0.3...0.3), Float(size) * 0.4 + Float.random(in: 0.2...0.5), Float.random(in: -0.3...0.3))
                coralNode.addChildNode(tNode)
            }
            
            coralNode.position = SCNVector3(cx, 0, cz)
            root.addChildNode(coralNode)
            registerBox(manager, x: cx, z: cz, w: size * 2, l: size * 2)
        }
        
        // Bubbles
        for _ in 0..<20 {
            let bubble = SCNSphere(radius: CGFloat.random(in: 0.04...0.12))
            let bMat = SCNMaterial()
            bMat.diffuse.contents = UIColor.white.withAlphaComponent(0.2)
            bMat.emission.contents = UIColor.white.withAlphaComponent(0.05)
            bubble.materials = [bMat]
            let bNode = SCNNode(geometry: bubble)
            bNode.position = SCNVector3(Float.random(in: -15...15), Float.random(in: 0.5...5), Float.random(in: -6...6))
            root.addChildNode(bNode)
            
            let rise = SCNAction.moveBy(x: 0, y: CGFloat.random(in: 3...7), z: 0, duration: Double.random(in: 5...12))
            let resetB = SCNAction.moveBy(x: 0, y: -CGFloat.random(in: 3...7), z: 0, duration: 0)
            bNode.runAction(SCNAction.repeatForever(SCNAction.sequence([rise, resetB])))
        }
        
        // Caustic light from above
        let causticLight = SCNLight()
        causticLight.type = .spot
        causticLight.color = UIColor(red: 0.15, green: 0.5, blue: 0.7, alpha: 1)
        causticLight.intensity = 250
        causticLight.spotInnerAngle = 25
        causticLight.spotOuterAngle = 70
        let causticNode = SCNNode()
        causticNode.light = causticLight
        causticNode.position = SCNVector3(0, 12, 0)
        causticNode.eulerAngles = SCNVector3(-Float.pi / 2, 0, 0)
        root.addChildNode(causticNode)
        
        // Bioluminescent particles
        for _ in 0..<10 {
            root.addChildNode(makeDataParticle(
                color: [P.cyan, P.magenta, P.violet].randomElement()!,
                at: SCNVector3(Float.random(in: -14...14), Float.random(in: 1...5), Float.random(in: -6...6)),
                size: CGFloat.random(in: 0.05...0.12)
            ))
        }
        
        root.addChildNode(makeSignPanel(color: P.cyan, at: SCNVector3(0, 5, -7)))
        
        // Data packets drifting through the deep ocean
        makeAmbientPacket(in: root, bounds: manager.worldBounds, accentColor: P.cyan, yRange: 0.8...5.0, flowDirection: SCNVector3(1, 0, 0))
        
        manager.resetPlayerPosition(to: SCNVector3(-14, 0, 0))
    }
    
    // MARK: - DNS Library (Act 4)
    // Mystical library — towering shelves, floating books, purple haze
    private static func buildDNSLibrary(in manager: SceneManager) {
        manager.worldBounds = CGSize(width: 32, height: 24)
        let root = manager.scene.rootNode
        
        // Restore atmosphere
        manager.scene.background.contents = UIColor(red: 0.03, green: 0.01, blue: 0.06, alpha: 1)
        manager.scene.fogColor = UIColor(red: 0.04, green: 0.02, blue: 0.08, alpha: 1)
        manager.scene.fogStartDistance = 25
        manager.scene.fogEndDistance = 60
        
        // Polished dark floor
        let floor = makeGroundPlane(width: 36, length: 28, baseColor: UIColor(red: 0.05, green: 0.03, blue: 0.08, alpha: 1), accentColor: P.violet)
        root.addChildNode(floor)
        
        // Towering bookshelves arranged in rows
        let shelfPositions: [(x: Float, z: Float, h: CGFloat)] = [
            (-12, -8, 7), (-12, -3, 5), (-12, 2, 8), (-12, 7, 6),
            (-6, -6, 5), (-6, 3, 7),
            (6, -7, 6), (6, 0, 8), (6, 6, 5),
            (12, -5, 7), (12, 2, 6), (12, 7, 8),
        ]
        
        let shelfColor = UIColor(red: 0.18, green: 0.1, blue: 0.06, alpha: 1)
        for shelf in shelfPositions {
            let shelfNode = SCNNode()
            
            // Frame — dark wood
            let frame = SCNBox(width: 2.2, height: shelf.h, length: 0.7, chamferRadius: 0.03)
            let frameMat = SCNMaterial()
            frameMat.diffuse.contents = shelfColor
            frameMat.roughness.contents = 0.7
            frameMat.metalness.contents = 0.1
            frame.materials = [frameMat]
            let frameNode = SCNNode(geometry: frame)
            frameNode.position = SCNVector3(0, Float(shelf.h / 2), 0)
            shelfNode.addChildNode(frameNode)
            
            // Books — colorful spines
            let bookCount = max(1, Int(shelf.h) - 1)
            for row in 0..<bookCount {
                for col in 0..<4 {
                    let bookColor: UIColor = [P.coral, P.violet, P.cyan, P.amber, P.magenta, P.lime].randomElement()!
                    let book = SCNBox(width: 0.3, height: 0.6, length: 0.5, chamferRadius: 0.01)
                    let bMat = SCNMaterial()
                    bMat.diffuse.contents = bookColor.withAlphaComponent(0.5)
                    bMat.emission.contents = bookColor.withAlphaComponent(0.1)
                    book.materials = [bMat]
                    let bNode = SCNNode(geometry: book)
                    bNode.position = SCNVector3(Float(col) * 0.4 - 0.6, Float(row) + 0.5, 0)
                    shelfNode.addChildNode(bNode)
                }
            }
            
            shelfNode.position = SCNVector3(shelf.x, 0, shelf.z)
            root.addChildNode(shelfNode)
            registerBox(manager, x: shelf.x, z: shelf.z, w: 2.2, l: 0.7)
        }
        
        // Central reading desk
        let desk = SCNBox(width: 4, height: 0.8, length: 2.5, chamferRadius: 0.08)
        let deskMat = SCNMaterial()
        deskMat.diffuse.contents = UIColor(red: 0.22, green: 0.13, blue: 0.08, alpha: 1)
        deskMat.roughness.contents = 0.6
        deskMat.metalness.contents = 0.15
        desk.materials = [deskMat]
        let deskNode = SCNNode(geometry: desk)
        deskNode.position = SCNVector3(0, 0.4, 0)
        root.addChildNode(deskNode)
        registerBox(manager, x: 0, z: 0, w: 4, l: 2.5)
        
        // Desk lamp light
        let deskLight = SCNLight()
        deskLight.type = .omni
        deskLight.color = P.violet
        deskLight.intensity = 300
        deskLight.attenuationStartDistance = 1
        deskLight.attenuationEndDistance = 6
        let deskLightNode = SCNNode()
        deskLightNode.light = deskLight
        deskLightNode.position = SCNVector3(0, 2, 0)
        root.addChildNode(deskLightNode)
        
        // Floating knowledge orbs
        for _ in 0..<12 {
            let orb = makeDataParticle(
                color: [P.violet, P.magenta, P.cyan].randomElement()!,
                at: SCNVector3(Float.random(in: -14...14), Float.random(in: 3...9), Float.random(in: -10...10)),
                size: CGFloat.random(in: 0.08...0.2)
            )
            root.addChildNode(orb)
        }
        
        root.addChildNode(makeSignPanel(color: P.violet, at: SCNVector3(0, 8, -12)))
        
        // Knowledge packets floating between the shelves
        makeAmbientPacket(in: root, bounds: manager.worldBounds, accentColor: P.violet, yRange: 2.0...7.0, flowDirection: SCNVector3(0, 0, 1))
        
        manager.resetPlayerPosition(to: SCNVector3(-12, 0, 0))
    }
    
    // MARK: - Return Journey (Act 5)
    // Urgent high-speed corridor — amber/coral streaks, flashing lights, tunnel rush
    private static func buildReturnJourney(in manager: SceneManager) {
        manager.worldBounds = CGSize(width: 30, height: 16)
        let root = manager.scene.rootNode
        
        // Hot atmosphere
        manager.scene.background.contents = UIColor(red: 0.06, green: 0.02, blue: 0.01, alpha: 1)
        manager.scene.fogColor = UIColor(red: 0.08, green: 0.03, blue: 0.02, alpha: 1)
        manager.scene.fogStartDistance = 15
        manager.scene.fogEndDistance = 45
        
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
