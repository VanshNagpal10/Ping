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
    
    /// Dark metallic building with neon edge trim and window lights
    private static func makeBuilding(
        width: CGFloat, height: CGFloat, length: CGFloat,
        color: UIColor, emissionColor: UIColor,
        at position: SCNVector3
    ) -> SCNNode {
        let box = SCNBox(width: width, height: height, length: length, chamferRadius: 0.05)
        let mat = SCNMaterial()
        mat.diffuse.contents = color
        mat.emission.contents = emissionColor.withAlphaComponent(0.05)
        mat.roughness.contents = 0.5
        mat.metalness.contents = 0.4
        box.materials = [mat]
        
        let node = SCNNode(geometry: box)
        node.position = SCNVector3(position.x, position.y + Float(height / 2), position.z)
        
        // Neon edge wire overlay
        let wireBox = SCNBox(width: width + 0.04, height: height + 0.04, length: length + 0.04, chamferRadius: 0.06)
        let wireMat = SCNMaterial()
        wireMat.diffuse.contents = UIColor.clear
        wireMat.emission.contents = emissionColor
        wireMat.fillMode = .lines
        wireMat.transparency = 0.25
        wireBox.materials = [wireMat]
        let wireNode = SCNNode(geometry: wireBox)
        node.addChildNode(wireNode)
        
        // Window lights on front face
        let windowRows = max(1, Int(height) - 1)
        let windowCols = max(1, Int(width / 0.8))
        for row in 0..<windowRows {
            for col in 0..<windowCols {
                let win = SCNBox(width: 0.25, height: 0.15, length: 0.01, chamferRadius: 0)
                let wMat = SCNMaterial()
                let winColor = [emissionColor, emissionColor, P.amber, P.magenta].randomElement()!
                wMat.diffuse.contents = winColor.withAlphaComponent(0.6)
                wMat.emission.contents = winColor
                win.materials = [wMat]
                let wNode = SCNNode(geometry: win)
                wNode.position = SCNVector3(
                    Float(col) * 0.7 - Float(windowCols) * 0.35 + 0.35,
                    Float(row) * 0.8 - Float(height / 2) + 0.8,
                    Float(length / 2) + 0.01
                )
                node.addChildNode(wNode)
                
                // Random blink
                if Bool.random() {
                    let blink = SCNAction.sequence([
                        SCNAction.wait(duration: Double.random(in: 0...5)),
                        SCNAction.fadeOpacity(to: 0.2, duration: 0.3),
                        SCNAction.fadeOpacity(to: 1.0, duration: 0.3),
                        SCNAction.wait(duration: Double.random(in: 2...6))
                    ])
                    wNode.runAction(SCNAction.repeatForever(blink))
                }
            }
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
    
    /// Ambient NPC packet — a small cube/sphere that drifts through the scene on its own
    private static func makeAmbientPacket(in root: SCNNode, bounds: CGSize, accentColor: UIColor, yRange: ClosedRange<Float> = 1.0...4.0) {
        let colors: [UIColor] = [P.cyan, P.magenta, P.amber, P.lime, P.violet, P.coral]
        let count = Int.random(in: 10...16)
        let halfW = Float(bounds.width) / 2 - 2
        let halfH = Float(bounds.height) / 2 - 2
        
        for i in 0..<count {
            let isBox = i % 3 == 0
            let size = CGFloat.random(in: 0.12...0.28)
            let color = colors.randomElement()!
            
            let geo: SCNGeometry
            if isBox {
                let box = SCNBox(width: size, height: size, length: size, chamferRadius: size * 0.15)
                geo = box
            } else {
                let sphere = SCNSphere(radius: size * 0.5)
                sphere.segmentCount = 8
                geo = sphere
            }
            
            let mat = SCNMaterial()
            mat.diffuse.contents = color.withAlphaComponent(0.6)
            mat.emission.contents = color.withAlphaComponent(0.4)
            mat.transparency = 0.8
            geo.materials = [mat]
            
            let node = SCNNode(geometry: geo)
            let startX = Float.random(in: -halfW...halfW)
            let startY = Float.random(in: yRange)
            let startZ = Float.random(in: -halfH...halfH)
            node.position = SCNVector3(startX, startY, startZ)
            
            // Small glow
            if i % 4 == 0 {
                let glow = SCNLight()
                glow.type = .omni
                glow.color = color
                glow.intensity = 15
                glow.attenuationStartDistance = 0.2
                glow.attenuationEndDistance = 1.5
                node.light = glow
            }
            
            // Drift path — random waypoint movement
            let speed = Double.random(in: 6...14)
            let dx = CGFloat.random(in: -8...8)
            let dy = CGFloat.random(in: -1...1)
            let dz = CGFloat.random(in: -8...8)
            let drift1 = SCNAction.moveBy(x: dx, y: dy, z: dz, duration: speed)
            let drift2 = drift1.reversed()
            node.runAction(SCNAction.repeatForever(SCNAction.sequence([drift1, drift2])))
            
            // Gentle spin
            let spinAxis = SCNVector4(Float.random(in: -1...1), 1, Float.random(in: -1...1), Float(CGFloat.random(in: 0.3...1.5)))
            let spin = SCNAction.rotate(by: CGFloat.pi * 2, around: SCNVector3(spinAxis.x, spinAxis.y, spinAxis.z), duration: Double.random(in: 4...10))
            node.runAction(SCNAction.repeatForever(spin))
            
            // Subtle pulse opacity
            let fadeOut = SCNAction.fadeOpacity(to: CGFloat.random(in: 0.3...0.6), duration: Double.random(in: 1.5...3))
            let fadeIn = SCNAction.fadeOpacity(to: 0.9, duration: Double.random(in: 1.5...3))
            node.runAction(SCNAction.repeatForever(SCNAction.sequence([fadeOut, fadeIn])))
            
            root.addChildNode(node)
        }
    }
    
    // MARK: - CPU City (Act 1)
    // Dense cyberpunk metropolis — dark alleys, neon signs, pipes, cables
    private static func buildCPUCity(in manager: SceneManager) {
        manager.worldBounds = CGSize(width: 36, height: 24)
        let root = manager.scene.rootNode
        
        // Ground
        let floor = makeGroundPlane(width: 40, length: 30, accentColor: P.cyan)
        root.addChildNode(floor)
        
        // Skyline buildings — dark with neon trim
        let buildings: [(x: Float, z: Float, w: CGFloat, h: CGFloat, l: CGFloat)] = [
            (-12, -8, 3.5, 5, 3),    (-7, -9, 2.5, 7, 2),
            (-2, -7, 4, 4, 2.5),     (5, -8, 2, 8, 3),
            (9, -5, 3, 6, 2.5),      (13, -7, 2, 5, 2),
            (-10, 6, 3, 4, 3.5),     (-5, 7, 2, 3, 2),
            (4, 6, 3, 5, 2),         (10, 4, 2.5, 7, 3),
            (14, 2, 2, 4, 2),        (-14, -3, 2, 3, 2),
        ]
        
        for b in buildings {
            let building = makeBuilding(
                width: b.w, height: b.h, length: b.l,
                color: P.charcoal, emissionColor: P.cyan,
                at: SCNVector3(b.x, 0, b.z)
            )
            root.addChildNode(building)
            registerBox(manager, x: b.x, z: b.z, w: b.w, l: b.l)
        }
        
        // Overhead pipes connecting buildings
        let pipePositions: [(SCNVector3, SCNVector3)] = [
            (SCNVector3(-12, 4, -6), SCNVector3(-2, 4, -6)),
            (SCNVector3(5, 5, -6), SCNVector3(13, 5, -6)),
            (SCNVector3(-10, 3, 5), SCNVector3(4, 3, 5)),
        ]
        for (start, end) in pipePositions {
            root.addChildNode(makePipe(from: start, to: end, radius: 0.08, color: P.cyan))
        }
        
        // Vertical pipes on walls
        for x: Float in [-15, -11, 9, 14] {
            let vPipe = SCNCylinder(radius: 0.05, height: 6)
            let vpMat = SCNMaterial()
            vpMat.diffuse.contents = UIColor(red: 0.15, green: 0.13, blue: 0.22, alpha: 1)
            vpMat.metalness.contents = 0.7
            vPipe.materials = [vpMat]
            let vpNode = SCNNode(geometry: vPipe)
            vpNode.position = SCNVector3(x, 3, Float.random(in: -9 ... -6))
            root.addChildNode(vpNode)
        }
        
        // Circuit traces on floor — glowing pathways
        let traceMat = SCNMaterial()
        traceMat.diffuse.contents = P.cyan.withAlphaComponent(0.15)
        traceMat.emission.contents = P.cyan
        let traceLines: [(x1: Float, z1: Float, x2: Float, z2: Float)] = [
            (-15, 0, 15, 0), (0, -12, 0, 12),
            (-10, -4, 10, -4), (-10, 4, 10, 4),
        ]
        for t in traceLines {
            let dx = t.x2 - t.x1
            let dz = t.z2 - t.z1
            let len = sqrt(dx * dx + dz * dz)
            let line = SCNBox(width: CGFloat(len), height: 0.005, length: 0.06, chamferRadius: 0)
            line.materials = [traceMat]
            let node = SCNNode(geometry: line)
            node.position = SCNVector3((t.x1 + t.x2) / 2, 0.01, (t.z1 + t.z2) / 2)
            if abs(dz) > abs(dx) { node.eulerAngles = SCNVector3(0, Float.pi / 2, 0) }
            root.addChildNode(node)
        }
        
        // Floating data particles
        for _ in 0..<15 {
            let particle = makeDataParticle(
                color: [P.cyan, P.magenta, P.amber].randomElement()!,
                at: SCNVector3(Float.random(in: -14...14), Float.random(in: 2...7), Float.random(in: -10...10)),
                size: CGFloat.random(in: 0.06...0.15)
            )
            root.addChildNode(particle)
        }
        
        // Scattered ground clutter — small boxes, barrels
        for _ in 0..<8 {
            let clutter = SCNBox(width: CGFloat.random(in: 0.3...0.6), height: CGFloat.random(in: 0.2...0.5), length: CGFloat.random(in: 0.3...0.6), chamferRadius: 0.02)
            let cMat = SCNMaterial()
            cMat.diffuse.contents = UIColor(red: 0.1, green: 0.08, blue: 0.12, alpha: 1)
            cMat.metalness.contents = 0.3
            clutter.materials = [cMat]
            let cNode = SCNNode(geometry: clutter)
            cNode.position = SCNVector3(Float.random(in: -13...13), Float(clutter.height / 2), Float.random(in: -8...8))
            cNode.eulerAngles = SCNVector3(0, Float.random(in: 0...Float.pi * 2), 0)
            root.addChildNode(cNode)
        }
        
        // Neon sign panel floating above
        root.addChildNode(makeSignPanel(color: P.cyan, at: SCNVector3(0, 8, -12)))
        
        // Scene-specific spot lights for dramatic shadows
        let spotCyan = SCNLight()
        spotCyan.type = .spot
        spotCyan.color = P.cyan
        spotCyan.intensity = 300
        spotCyan.spotInnerAngle = 20
        spotCyan.spotOuterAngle = 60
        spotCyan.castsShadow = true
        let spotNode = SCNNode()
        spotNode.light = spotCyan
        spotNode.position = SCNVector3(-8, 8, -2)
        spotNode.eulerAngles = SCNVector3(-Float.pi / 3, 0, 0)
        root.addChildNode(spotNode)
        
        // Ambient NPC packets drifting through the city
        makeAmbientPacket(in: root, bounds: manager.worldBounds, accentColor: P.cyan)
        
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
        makeAmbientPacket(in: root, bounds: manager.worldBounds, accentColor: P.lime, yRange: 1.5...8.0)
        
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
        makeAmbientPacket(in: root, bounds: manager.worldBounds, accentColor: P.amber, yRange: 0.5...3.0)
        
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
        makeAmbientPacket(in: root, bounds: manager.worldBounds, accentColor: P.cyan, yRange: 0.8...5.0)
        
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
        makeAmbientPacket(in: root, bounds: manager.worldBounds, accentColor: P.violet, yRange: 2.0...7.0)
        
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
        makeAmbientPacket(in: root, bounds: manager.worldBounds, accentColor: P.coral, yRange: 0.5...3.5)
        
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
