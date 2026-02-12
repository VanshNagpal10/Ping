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
    
    /// Creates a glowing grid floor — the signature look
    private static func makeGridFloor(
        width: CGFloat = 40,
        length: CGFloat = 30,
        gridColor: UIColor = P.cyan,
        baseColor: UIColor = P.floorBase
    ) -> SCNNode {
        let floor = SCNNode()
        
        // Base plane
        let plane = SCNPlane(width: width, height: length)
        let baseMat = SCNMaterial()
        baseMat.diffuse.contents = baseColor
        baseMat.roughness.contents = 0.9
        plane.materials = [baseMat]
        let baseNode = SCNNode(geometry: plane)
        baseNode.eulerAngles = SCNVector3(-Float.pi / 2, 0, 0)
        baseNode.position = SCNVector3(0, -0.01, 0)
        floor.addChildNode(baseNode)
        
        // Grid lines (X axis)
        let spacing: Float = 2.0
        let halfW = Float(width) / 2
        let halfL = Float(length) / 2
        
        let lineMat = SCNMaterial()
        lineMat.diffuse.contents = gridColor.withAlphaComponent(0.15)
        lineMat.emission.contents = gridColor.withAlphaComponent(0.25)
        
        var x: Float = -halfW
        while x <= halfW {
            let line = SCNBox(width: 0.03, height: 0.005, length: CGFloat(length), chamferRadius: 0)
            line.materials = [lineMat]
            let node = SCNNode(geometry: line)
            node.position = SCNVector3(x, 0.005, 0)
            floor.addChildNode(node)
            x += spacing
        }
        
        // Grid lines (Z axis)
        var z: Float = -halfL
        while z <= halfL {
            let line = SCNBox(width: CGFloat(width), height: 0.005, length: 0.03, chamferRadius: 0)
            line.materials = [lineMat]
            let node = SCNNode(geometry: line)
            node.position = SCNVector3(0, 0.005, z)
            floor.addChildNode(node)
            z += spacing
        }
        
        return floor
    }
    
    /// Neon-edged building block
    private static func makeBuilding(
        width: CGFloat, height: CGFloat, length: CGFloat,
        color: UIColor, emissionColor: UIColor,
        at position: SCNVector3
    ) -> SCNNode {
        let box = SCNBox(width: width, height: height, length: length, chamferRadius: 0.08)
        let mat = SCNMaterial()
        mat.diffuse.contents = color
        mat.emission.contents = emissionColor.withAlphaComponent(0.2)
        mat.roughness.contents = 0.6
        mat.metalness.contents = 0.3
        box.materials = [mat]
        
        let node = SCNNode(geometry: box)
        node.position = SCNVector3(position.x, position.y + Float(height / 2), position.z)
        
        // Neon edge wire overlay
        let wireBox = SCNBox(width: width + 0.05, height: height + 0.05, length: length + 0.05, chamferRadius: 0.1)
        let wireMat = SCNMaterial()
        wireMat.diffuse.contents = UIColor.clear
        wireMat.emission.contents = emissionColor
        wireMat.fillMode = .lines
        wireMat.transparency = 0.4
        wireBox.materials = [wireMat]
        let wireNode = SCNNode(geometry: wireBox)
        node.addChildNode(wireNode)
        
        return node
    }
    
    /// Glowing pillar
    private static func makePillar(radius: CGFloat, height: CGFloat, color: UIColor, at position: SCNVector3) -> SCNNode {
        let cyl = SCNCylinder(radius: radius, height: height)
        let mat = SCNMaterial()
        mat.diffuse.contents = color.withAlphaComponent(0.6)
        mat.emission.contents = color
        mat.transparency = 0.7
        cyl.materials = [mat]
        let node = SCNNode(geometry: cyl)
        node.position = SCNVector3(position.x, position.y + Float(height / 2), position.z)
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
    
    // MARK: - CPU City (Act 1)
    // Dark metropolis with glowing cyan chip-buildings and circuit traces
    private static func buildCPUCity(in manager: SceneManager) {
        manager.worldBounds = CGSize(width: 36, height: 24)
        let root = manager.scene.rootNode
        
        // Floor with cyan grid
        let floor = makeGridFloor(width: 40, length: 30, gridColor: P.cyan)
        root.addChildNode(floor)
        
        // CPU chip buildings — varying heights for skyline
        let buildings: [(x: Float, z: Float, w: CGFloat, h: CGFloat, l: CGFloat)] = [
            (-10, -6, 3, 4, 3),
            (-6, -8, 2, 6, 2),
            (-2, -5, 4, 3, 2),
            (4, -7, 2.5, 5, 2.5),
            (8, -4, 3, 7, 3),
            (-8, 4, 2, 3.5, 4),
            (-3, 6, 3.5, 4.5, 2),
            (5, 5, 2, 2.5, 3),
            (10, 3, 3, 6, 2),
            (12, -2, 2, 4, 2),
        ]
        
        for b in buildings {
            let building = makeBuilding(
                width: b.w, height: b.h, length: b.l,
                color: P.charcoal, emissionColor: P.cyan,
                at: SCNVector3(b.x, 0, b.z)
            )
            root.addChildNode(building)
            
            // Tiny "window" lights on buildings
            let windowCount = Int(b.h)
            for row in 0..<windowCount {
                for col in 0..<2 {
                    let window = SCNBox(width: 0.3, height: 0.2, length: 0.01, chamferRadius: 0)
                    let wMat = SCNMaterial()
                    wMat.diffuse.contents = [P.cyan, P.amber, P.magenta].randomElement()!
                    wMat.emission.contents = wMat.diffuse.contents
                    window.materials = [wMat]
                    let wNode = SCNNode(geometry: window)
                    wNode.position = SCNVector3(
                        b.x + Float(col) * 0.8 - 0.4,
                        Float(row) + 1.0,
                        b.z + Float(b.l / 2) + 0.01
                    )
                    root.addChildNode(wNode)
                    
                    // Blink animation
                    let delay = Double.random(in: 0...3)
                    let blink = SCNAction.sequence([
                        SCNAction.wait(duration: delay),
                        SCNAction.fadeOpacity(to: 0.3, duration: 0.5),
                        SCNAction.fadeOpacity(to: 1.0, duration: 0.5)
                    ])
                    wNode.runAction(SCNAction.repeatForever(blink))
                }
            }
        }
        
        // Circuit trace lines on the floor
        let traces: [(start: SCNVector3, end: SCNVector3)] = [
            (SCNVector3(-15, 0.02, 0), SCNVector3(15, 0.02, 0)),
            (SCNVector3(0, 0.02, -12), SCNVector3(0, 0.02, 12)),
            (SCNVector3(-10, 0.02, -4), SCNVector3(10, 0.02, -4)),
            (SCNVector3(-10, 0.02, 4), SCNVector3(10, 0.02, 4)),
        ]
        
        let traceMat = SCNMaterial()
        traceMat.diffuse.contents = P.cyan.withAlphaComponent(0.3)
        traceMat.emission.contents = P.cyan
        
        for trace in traces {
            let dx = trace.end.x - trace.start.x
            let dz = trace.end.z - trace.start.z
            let len = sqrt(dx * dx + dz * dz)
            
            let line = SCNBox(width: CGFloat(len), height: 0.01, length: 0.08, chamferRadius: 0)
            line.materials = [traceMat]
            let lineNode = SCNNode(geometry: line)
            lineNode.position = SCNVector3(
                (trace.start.x + trace.end.x) / 2,
                0.02,
                (trace.start.z + trace.end.z) / 2
            )
            let angle = atan2(dz, dx)
            lineNode.eulerAngles = SCNVector3(0, -angle, 0)
            root.addChildNode(lineNode)
        }
        
        // Floating data particles
        for _ in 0..<20 {
            let particle = makeDataParticle(
                color: [P.cyan, P.magenta, P.amber].randomElement()!,
                at: SCNVector3(
                    Float.random(in: -15...15),
                    Float.random(in: 2...8),
                    Float.random(in: -10...10)
                ),
                size: CGFloat.random(in: 0.08...0.2)
            )
            root.addChildNode(particle)
        }
        
        // "CPU CITY" holographic sign panel
        root.addChildNode(makeSignPanel(color: P.cyan, at: SCNVector3(0, 8, -12)))
        
        manager.resetPlayerPosition(to: SCNVector3(-12, 0, 0))
    }
    
    // MARK: - WiFi Antenna (Act 2a)
    // Rooftop with massive antenna, electromagnetic wave rings
    private static func buildWiFiAntenna(in manager: SceneManager) {
        manager.worldBounds = CGSize(width: 30, height: 22)
        let root = manager.scene.rootNode
        
        // Floor — darker with green gridlines
        let floor = makeGridFloor(width: 34, length: 26, gridColor: P.lime)
        root.addChildNode(floor)
        
        // Antenna tower
        let tower = SCNCylinder(radius: 0.3, height: 12)
        let towerMat = SCNMaterial()
        towerMat.diffuse.contents = UIColor.darkGray
        towerMat.metalness.contents = 0.8
        tower.materials = [towerMat]
        let towerNode = SCNNode(geometry: tower)
        towerNode.position = SCNVector3(-4, 6, -4)
        root.addChildNode(towerNode)
        
        // Antenna tip - glowing sphere
        let tipSphere = SCNSphere(radius: 0.5)
        let tipMat = SCNMaterial()
        tipMat.diffuse.contents = P.lime
        tipMat.emission.contents = P.lime
        tipSphere.materials = [tipMat]
        let tipNode = SCNNode(geometry: tipSphere)
        tipNode.position = SCNVector3(-4, 12.5, -4)
        root.addChildNode(tipNode)
        
        // Tip point light
        let tipLight = SCNLight()
        tipLight.type = .omni
        tipLight.color = P.lime
        tipLight.intensity = 800
        tipLight.attenuationStartDistance = 2
        tipLight.attenuationEndDistance = 15
        tipNode.light = tipLight
        
        // WiFi wave rings expanding outward
        for i in 0..<5 {
            let ring = SCNTorus(ringRadius: CGFloat(2 + i * 2), pipeRadius: 0.06)
            let ringMat = SCNMaterial()
            ringMat.diffuse.contents = P.lime.withAlphaComponent(CGFloat(0.6 - Float(i) * 0.1))
            ringMat.emission.contents = P.lime
            ring.materials = [ringMat]
            let ringNode = SCNNode(geometry: ring)
            ringNode.position = SCNVector3(-4, 10, -4)
            root.addChildNode(ringNode)
            
            // Pulse animation
            let delay = Double(i) * 0.6
            let expand = SCNAction.sequence([
                SCNAction.wait(duration: delay),
                SCNAction.scale(to: 1.3, duration: 1.5),
                SCNAction.scale(to: 1.0, duration: 1.5)
            ])
            ringNode.runAction(SCNAction.repeatForever(expand))
        }
        
        // Rooftop structures
        let ventBox = makeBuilding(width: 2, height: 1.5, length: 2, color: P.slate, emissionColor: P.lime, at: SCNVector3(6, 0, -2))
        root.addChildNode(ventBox)
        
        let panel = makeBuilding(width: 4, height: 0.3, length: 2, color: UIColor.darkGray, emissionColor: P.lime, at: SCNVector3(3, 0, 4))
        root.addChildNode(panel)
        
        // Label — neon panel
        root.addChildNode(makeSignPanel(color: P.lime, width: 5, height: 1.2, at: SCNVector3(-6, 5, -10)))
        
        manager.resetPlayerPosition(to: SCNVector3(8, 0, 5))
    }
    
    // MARK: - Router Station (Act 2b)
    // Subway-station feel with glowing track rails and directional signs
    private static func buildRouterStation(in manager: SceneManager) {
        manager.worldBounds = CGSize(width: 32, height: 20)
        let root = manager.scene.rootNode
        
        let floor = makeGridFloor(width: 36, length: 24, gridColor: P.amber)
        root.addChildNode(floor)
        
        // Track rails (glowing amber lines)
        for i in -2...2 {
            let rail = SCNBox(width: 30, height: 0.08, length: 0.12, chamferRadius: 0.02)
            let railMat = SCNMaterial()
            railMat.diffuse.contents = P.amber
            railMat.emission.contents = P.amber
            rail.materials = [railMat]
            let railNode = SCNNode(geometry: rail)
            railNode.position = SCNVector3(0, 0.04, Float(i) * 3)
            root.addChildNode(railNode)
        }
        
        // Platform pillars
        for x in stride(from: -12, through: 12, by: 6) {
            for z in [-8, 8] {
                let pillar = makePillar(radius: 0.25, height: 5, color: P.amber, at: SCNVector3(Float(x), 0, Float(z)))
                root.addChildNode(pillar)
            }
        }
        
        // Platform ceiling beams
        for x in stride(from: -12, through: 12, by: 6) {
            let beam = SCNBox(width: 0.3, height: 0.3, length: 20, chamferRadius: 0)
            let beamMat = SCNMaterial()
            beamMat.diffuse.contents = P.slate
            beamMat.emission.contents = P.amber.withAlphaComponent(0.1)
            beam.materials = [beamMat]
            let beamNode = SCNNode(geometry: beam)
            beamNode.position = SCNVector3(Float(x), 5, 0)
            root.addChildNode(beamNode)
        }
        
        // Direction sign boards — neon panels
        root.addChildNode(makeSignPanel(color: UIColor.systemBlue, width: 3, height: 0.8, at: SCNVector3(-8, 4, -8)))
        root.addChildNode(makeSignPanel(color: UIColor.systemGreen, width: 3, height: 0.8, at: SCNVector3(8, 4, -8)))
        
        // Moving "data train" lights along rails
        for rail in 0..<3 {
            let trainLight = SCNNode()
            let lightGeo = SCNSphere(radius: 0.3)
            let lMat = SCNMaterial()
            lMat.diffuse.contents = P.amber
            lMat.emission.contents = P.amber
            lightGeo.materials = [lMat]
            trainLight.geometry = lightGeo
            trainLight.position = SCNVector3(-15, 0.5, Float(rail - 1) * 3)
            root.addChildNode(trainLight)
            
            let moveAcross = SCNAction.moveBy(x: 30, y: 0, z: 0, duration: Double.random(in: 3...6))
            let reset = SCNAction.moveBy(x: -30, y: 0, z: 0, duration: 0)
            trainLight.runAction(SCNAction.repeatForever(SCNAction.sequence([moveAcross, reset])))
        }
        
        // Title — neon panel
        root.addChildNode(makeSignPanel(color: P.amber, at: SCNVector3(0, 6, -10)))
        
        manager.resetPlayerPosition(to: SCNVector3(-10, 0, 0))
    }
    
    // MARK: - Ocean Cable (Act 3)
    // Deep underwater with glass fiber tube, caustic lighting, marine life
    private static func buildOceanCable(in manager: SceneManager) {
        manager.worldBounds = CGSize(width: 36, height: 16)
        let root = manager.scene.rootNode
        
        // Deep ocean floor
        let oceanFloor = SCNPlane(width: 40, height: 30)
        let floorMat = SCNMaterial()
        floorMat.diffuse.contents = UIColor(red: 0.02, green: 0.04, blue: 0.12, alpha: 1)
        floorMat.roughness.contents = 1.0
        oceanFloor.materials = [floorMat]
        let floorNode = SCNNode(geometry: oceanFloor)
        floorNode.eulerAngles = SCNVector3(-Float.pi / 2, 0, 0)
        floorNode.position = SCNVector3(0, -0.01, 0)
        root.addChildNode(floorNode)
        
        // Override scene background for underwater
        manager.scene.background.contents = UIColor(red: 0.01, green: 0.03, blue: 0.10, alpha: 1)
        manager.scene.fogColor = UIColor(red: 0.01, green: 0.05, blue: 0.15, alpha: 1)
        manager.scene.fogStartDistance = 20
        manager.scene.fogEndDistance = 50
        
        // Fiber optic cable — glowing cylinder
        let cable = SCNCylinder(radius: 1.8, height: 30)
        let cableMat = SCNMaterial()
        cableMat.diffuse.contents = UIColor(red: 0.0, green: 0.3, blue: 0.5, alpha: 0.3)
        cableMat.emission.contents = P.cyan.withAlphaComponent(0.2)
        cableMat.transparency = 0.4
        cableMat.isDoubleSided = true
        cable.materials = [cableMat]
        let cableNode = SCNNode(geometry: cable)
        cableNode.position = SCNVector3(0, 1.5, 0)
        cableNode.eulerAngles = SCNVector3(0, 0, Float.pi / 2)
        root.addChildNode(cableNode)
        
        // Light pulses traveling through cable
        for i in 0..<4 {
            let pulse = SCNSphere(radius: 0.4)
            let pMat = SCNMaterial()
            pMat.diffuse.contents = P.cyan
            pMat.emission.contents = P.cyan
            pulse.materials = [pMat]
            let pNode = SCNNode(geometry: pulse)
            pNode.position = SCNVector3(-15 + Float(i) * 8, 1.5, 0)
            root.addChildNode(pNode)
            
            let travel = SCNAction.moveBy(x: 32, y: 0, z: 0, duration: Double(4 + i))
            let reset = SCNAction.moveBy(x: -32, y: 0, z: 0, duration: 0)
            pNode.runAction(SCNAction.repeatForever(SCNAction.sequence([travel, reset])))
        }
        
        // Underwater particles (bubbles)
        for _ in 0..<30 {
            let bubble = SCNSphere(radius: CGFloat.random(in: 0.05...0.15))
            let bMat = SCNMaterial()
            bMat.diffuse.contents = UIColor.white.withAlphaComponent(0.3)
            bMat.emission.contents = UIColor.white.withAlphaComponent(0.1)
            bubble.materials = [bMat]
            let bNode = SCNNode(geometry: bubble)
            bNode.position = SCNVector3(
                Float.random(in: -15...15),
                Float.random(in: 0.5...6),
                Float.random(in: -6...6)
            )
            root.addChildNode(bNode)
            
            let rise = SCNAction.moveBy(x: 0, y: CGFloat.random(in: 3...8), z: 0, duration: Double.random(in: 4...10))
            let resetB = SCNAction.moveBy(x: 0, y: -CGFloat.random(in: 3...8), z: 0, duration: 0)
            bNode.runAction(SCNAction.repeatForever(SCNAction.sequence([rise, resetB])))
        }
        
        // Ocean rocks / coral formations
        let rockPositions: [SCNVector3] = [
            SCNVector3(-12, 0, -6), SCNVector3(-8, 0, 5),
            SCNVector3(5, 0, -5), SCNVector3(10, 0, 6),
            SCNVector3(14, 0, -3),
        ]
        for pos in rockPositions {
            let rock = SCNSphere(radius: CGFloat.random(in: 0.8...1.5))
            let rMat = SCNMaterial()
            rMat.diffuse.contents = UIColor(red: 0.15, green: 0.12, blue: 0.08, alpha: 1)
            rMat.roughness.contents = 1.0
            rock.materials = [rMat]
            let rNode = SCNNode(geometry: rock)
            rNode.position = SCNVector3(pos.x, Float(rock.radius) * 0.6, pos.z)
            rNode.scale = SCNVector3(1, 0.6, 1) // Flatten into rock shape
            root.addChildNode(rNode)
        }
        
        // Caustic light from above
        let causticLight = SCNLight()
        causticLight.type = .spot
        causticLight.color = UIColor(red: 0.2, green: 0.6, blue: 0.8, alpha: 1)
        causticLight.intensity = 300
        causticLight.spotInnerAngle = 30
        causticLight.spotOuterAngle = 80
        let causticNode = SCNNode()
        causticNode.light = causticLight
        causticNode.position = SCNVector3(0, 15, 0)
        causticNode.eulerAngles = SCNVector3(-Float.pi / 2, 0, 0)
        root.addChildNode(causticNode)
        
        // Title — neon panel
        root.addChildNode(makeSignPanel(color: P.cyan, at: SCNVector3(0, 5, -8)))
        
        manager.resetPlayerPosition(to: SCNVector3(-14, 0, 0))
    }
    
    // MARK: - DNS Library (Act 4)
    // Massive floating bookshelves, mystical purple/violet glow
    private static func buildDNSLibrary(in manager: SceneManager) {
        manager.worldBounds = CGSize(width: 32, height: 24)
        let root = manager.scene.rootNode
        
        // Restore fog
        manager.scene.background.contents = P.void
        manager.scene.fogColor = P.void
        manager.scene.fogStartDistance = 40
        manager.scene.fogEndDistance = 80
        
        let floor = makeGridFloor(width: 36, length: 28, gridColor: P.violet)
        root.addChildNode(floor)
        
        // Towering bookshelves
        let shelfPositions: [(x: Float, z: Float, h: CGFloat)] = [
            (-10, -8, 6), (-10, -4, 5), (-10, 0, 7), (-10, 4, 4), (-10, 8, 6),
            (-5, -6, 5), (-5, 2, 6), (-5, 7, 4),
            (5, -8, 4), (5, -3, 6), (5, 3, 7), (5, 8, 5),
            (10, -6, 6), (10, 0, 5), (10, 5, 7),
        ]
        
        for shelf in shelfPositions {
            let shelfNode = SCNNode()
            
            // Shelf frame
            let frame = SCNBox(width: 2, height: shelf.h, length: 0.6, chamferRadius: 0.05)
            let frameMat = SCNMaterial()
            frameMat.diffuse.contents = UIColor(red: 0.2, green: 0.12, blue: 0.08, alpha: 1)
            frameMat.roughness.contents = 0.8
            frame.materials = [frameMat]
            let frameNode = SCNNode(geometry: frame)
            frameNode.position = SCNVector3(0, Float(shelf.h / 2), 0)
            shelfNode.addChildNode(frameNode)
            
            // Books (colorful rectangles)
            let bookCount = Int(shelf.h)
            for row in 0..<bookCount {
                for col in 0..<4 {
                    let bookColor: UIColor = [P.coral, P.violet, P.cyan, P.amber, P.magenta, P.lime].randomElement()!
                    let book = SCNBox(width: 0.35, height: 0.7, length: 0.5, chamferRadius: 0.02)
                    let bMat = SCNMaterial()
                    bMat.diffuse.contents = bookColor.withAlphaComponent(0.7)
                    bMat.emission.contents = bookColor.withAlphaComponent(0.15)
                    book.materials = [bMat]
                    let bNode = SCNNode(geometry: book)
                    bNode.position = SCNVector3(
                        Float(col) * 0.4 - 0.6,
                        Float(row) * 1.0 + 0.5,
                        0
                    )
                    shelfNode.addChildNode(bNode)
                }
            }
            
            shelfNode.position = SCNVector3(shelf.x, 0, shelf.z)
            root.addChildNode(shelfNode)
        }
        
        // Floating glowing orbs (knowledge particles)
        for _ in 0..<15 {
            let orb = makeDataParticle(
                color: [P.violet, P.magenta].randomElement()!,
                at: SCNVector3(
                    Float.random(in: -14...14),
                    Float.random(in: 3...10),
                    Float.random(in: -10...10)
                ),
                size: CGFloat.random(in: 0.1...0.3)
            )
            root.addChildNode(orb)
        }
        
        // Central reading desk with glowing surface
        let desk = SCNBox(width: 4, height: 0.8, length: 2, chamferRadius: 0.1)
        let deskMat = SCNMaterial()
        deskMat.diffuse.contents = UIColor(red: 0.25, green: 0.15, blue: 0.1, alpha: 1)
        deskMat.emission.contents = P.violet.withAlphaComponent(0.1)
        desk.materials = [deskMat]
        let deskNode = SCNNode(geometry: desk)
        deskNode.position = SCNVector3(0, 0.4, 0)
        root.addChildNode(deskNode)
        
        // Title — neon panel
        root.addChildNode(makeSignPanel(color: P.violet, at: SCNVector3(0, 8, -12)))
        
        manager.resetPlayerPosition(to: SCNVector3(-12, 0, 0))
    }
    
    // MARK: - Return Journey (Act 5)
    // Urgent/fast — speed lines, warm amber/orange glow, everything rushing
    private static func buildReturnJourney(in manager: SceneManager) {
        manager.worldBounds = CGSize(width: 30, height: 16)
        let root = manager.scene.rootNode
        
        // Restore defaults
        manager.scene.background.contents = P.void
        manager.scene.fogColor = P.void
        
        let floor = makeGridFloor(width: 34, length: 20, gridColor: P.coral)
        root.addChildNode(floor)
        
        // Speed tunnel walls
        for side in [-1, 1] as [Float] {
            for i in 0..<10 {
                let wall = SCNBox(width: 0.15, height: 3, length: 0.15, chamferRadius: 0)
                let wMat = SCNMaterial()
                wMat.diffuse.contents = P.coral
                wMat.emission.contents = P.coral
                wMat.transparency = 0.5
                wall.materials = [wMat]
                let wNode = SCNNode(geometry: wall)
                wNode.position = SCNVector3(Float(i) * 3 - 14, 1.5, side * 7)
                root.addChildNode(wNode)
            }
        }
        
        // Speed particles rushing past
        for _ in 0..<25 {
            let speedLine = SCNBox(width: CGFloat.random(in: 2...5), height: 0.05, length: 0.05, chamferRadius: 0)
            let slMat = SCNMaterial()
            slMat.diffuse.contents = P.amber
            slMat.emission.contents = P.amber
            slMat.transparency = CGFloat.random(in: 0.3...0.7)
            speedLine.materials = [slMat]
            let slNode = SCNNode(geometry: speedLine)
            slNode.position = SCNVector3(
                Float.random(in: -15...15),
                Float.random(in: 0.5...4),
                Float.random(in: -6...6)
            )
            root.addChildNode(slNode)
            
            // Rush animation
            let rush = SCNAction.moveBy(x: -30, y: 0, z: 0, duration: Double.random(in: 1...3))
            let resetR = SCNAction.moveBy(x: 30, y: 0, z: 0, duration: 0)
            slNode.runAction(SCNAction.repeatForever(SCNAction.sequence([rush, resetR])))
        }
        
        // Urgency lights
        let urgentLight = SCNLight()
        urgentLight.type = .omni
        urgentLight.color = P.coral
        urgentLight.intensity = 500
        let urgentNode = SCNNode()
        urgentNode.light = urgentLight
        urgentNode.position = SCNVector3(0, 5, 0)
        root.addChildNode(urgentNode)
        
        let flashOn = SCNAction.customAction(duration: 0.5) { node, _ in
            node.light?.intensity = 800
        }
        let flashOff = SCNAction.customAction(duration: 0.5) { node, _ in
            node.light?.intensity = 300
        }
        urgentNode.runAction(SCNAction.repeatForever(SCNAction.sequence([flashOn, flashOff])))
        
        // Title — neon panel
        root.addChildNode(makeSignPanel(color: P.amber, at: SCNVector3(0, 5, -8)))
        
        manager.resetPlayerPosition(to: SCNVector3(-12, 0, 0))
    }
    
    // MARK: - Default Floor (Fallback)
    private static func buildDefaultFloor(in manager: SceneManager) {
        manager.worldBounds = CGSize(width: 30, height: 20)
        let root = manager.scene.rootNode
        let floor = makeGridFloor()
        root.addChildNode(floor)
        manager.resetPlayerPosition()
    }
}
