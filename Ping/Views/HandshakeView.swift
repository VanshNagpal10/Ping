//
//  HandshakeView.swift
//  Ping
//
//  TCP Handshake mini-game at the server
//

import SwiftUI

struct HandshakeView: View {
    @ObservedObject var engine: GameEngine
    
    @State private var showFortress = false
    @State private var buttonEnabled = true
    @State private var connectionLines: [Bool] = [false, false, false]
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Background
                ServerBackground()
                
                // Server fortress
                ServerFortress()
                    .position(x: geo.size.width * 0.7, y: geo.size.height * 0.5)
                    .scaleEffect(showFortress ? 1 : 0.5)
                    .opacity(showFortress ? 1 : 0)
                
                // Packet (left side)
                PacketView(
                    packet: engine.packet,
                    isThrusting: false
                )
                .position(x: geo.size.width * 0.2, y: geo.size.height * 0.5)
                .scaleEffect(showFortress ? 1 : 0)
                
                // Connection lines
                ConnectionLines(steps: connectionLines)
                    .position(x: geo.size.width * 0.45, y: geo.size.height * 0.5)
                
                // Handshake UI
                VStack(spacing: 30) {
                    // Title
                    Text("TCP HANDSHAKE")
                        .font(.system(size: 24, weight: .bold, design: .monospaced))
                        .foregroundColor(.cyan)
                    
                    Text("Establish connection to server")
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(.gray)
                    
                    Spacer()
                    
                    // Handshake steps visualization
                    HandshakeStepsView(currentStep: engine.handshakeStep, connectionLines: connectionLines)
                    
                    Spacer()
                    
                    // Action button
                    if engine.handshakeStep != .complete {
                        Button(action: performHandshake) {
                            Text(buttonText)
                                .font(.system(size: 18, weight: .bold, design: .monospaced))
                                .foregroundColor(.black)
                                .padding(.horizontal, 40)
                                .padding(.vertical, 16)
                                .background(
                                    engine.handshakeStep == .waiting ?
                                    Color.cyan : Color.green
                                )
                                .cornerRadius(12)
                                .shadow(color: .cyan.opacity(0.5), radius: 10)
                        }
                        .disabled(!buttonEnabled)
                        .opacity(buttonEnabled ? 1 : 0.5)
                    } else {
                        // Success message
                        VStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 40))
                                .foregroundColor(.green)
                            
                            Text("CONNECTION ESTABLISHED")
                                .font(.system(size: 16, weight: .bold, design: .monospaced))
                                .foregroundColor(.green)
                            
                            Text("Downloading payload...")
                                .font(.system(size: 12, design: .monospaced))
                                .foregroundColor(.gray)
                        }
                        .transition(.scale.combined(with: .opacity))
                    }
                    
                    Spacer().frame(height: 40)
                }
                .padding()
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                showFortress = true
            }
        }
    }
    
    private var buttonText: String {
        switch engine.handshakeStep {
        case .waiting: return "CONNECT"
        case .syn: return "SEND SYN"
        case .synAck: return "RECEIVED SYN-ACK"
        case .ack: return "SEND ACK"
        case .complete: return "CONNECTED!"
        }
    }
    
    private func performHandshake() {
        buttonEnabled = false
        
        // Animate connection line
        let stepIndex = engine.handshakeStep.rawValue
        if stepIndex < 3 {
            withAnimation(.easeInOut(duration: 0.3)) {
                connectionLines[stepIndex] = true
            }
        }
        
        // Perform step after short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            engine.performHandshakeStep()
            buttonEnabled = true
        }
    }
}

// MARK: - Server Background
struct ServerBackground: View {
    @State private var gridMove = false
    
    var body: some View {
        ZStack {
            // Dark tech gradient
            LinearGradient(
                colors: [
                    Color(red: 0.05, green: 0.1, blue: 0.15),
                    Color(red: 0.02, green: 0.05, blue: 0.1)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            
            // Moving grid
            GeometryReader { geo in
                VStack(spacing: 30) {
                    ForEach(0..<20, id: \.self) { _ in
                        Rectangle()
                            .fill(Color.blue.opacity(0.1))
                            .frame(height: 1)
                    }
                }
                .offset(y: gridMove ? 30 : 0)
                .animation(.linear(duration: 2).repeatForever(autoreverses: false), value: gridMove)
            }
            
            // Radial glow from server
            RadialGradient(
                colors: [Color.blue.opacity(0.2), Color.clear],
                center: UnitPoint(x: 0.7, y: 0.5),
                startRadius: 0,
                endRadius: 400
            )
        }
        .ignoresSafeArea()
        .onAppear { gridMove = true }
    }
}

// MARK: - Server Fortress
struct ServerFortress: View {
    @State private var glow = false
    
    var body: some View {
        ZStack {
            // Outer glow
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.blue.opacity(0.3))
                .frame(width: 180, height: 250)
                .blur(radius: 30)
                .scaleEffect(glow ? 1.1 : 1.0)
                .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: glow)
            
            // Fortress body
            RoundedRectangle(cornerRadius: 15)
                .fill(
                    LinearGradient(
                        colors: [Color.gray.opacity(0.4), Color.gray.opacity(0.2)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 150, height: 220)
                .overlay(
                    RoundedRectangle(cornerRadius: 15)
                        .stroke(Color.cyan, lineWidth: 2)
                )
            
            // Server racks
            VStack(spacing: 12) {
                ForEach(0..<4, id: \.self) { i in
                    ServerRack(index: i)
                }
            }
            
            // IP Address label
            VStack {
                Spacer()
                Text("200.10.1.1")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(.cyan)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(Color.black.opacity(0.7))
                    .cornerRadius(4)
            }
            .frame(height: 220)
            .padding(.bottom, -20)
        }
        .onAppear { glow = true }
    }
}

struct ServerRack: View {
    let index: Int
    @State private var blink = false
    
    var body: some View {
        HStack(spacing: 4) {
            // Status lights
            ForEach(0..<4, id: \.self) { j in
                Circle()
                    .fill((index + j) % 2 == 0 ? Color.green : Color.orange)
                    .frame(width: 6, height: 6)
                    .opacity(blink && j == index % 4 ? 0.3 : 1.0)
            }
            
            Spacer()
            
            // Slot
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.black.opacity(0.5))
                .frame(width: 60, height: 20)
        }
        .frame(width: 110)
        .padding(8)
        .background(Color.gray.opacity(0.3))
        .cornerRadius(4)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true).delay(Double(index) * 0.2)) {
                blink = true
            }
        }
    }
}

// MARK: - Connection Lines
struct ConnectionLines: View {
    let steps: [Bool]
    
    var body: some View {
        VStack(spacing: 30) {
            ConnectionLine(active: steps[0], label: "SYN", direction: .right)
            ConnectionLine(active: steps[1], label: "SYN-ACK", direction: .left)
            ConnectionLine(active: steps[2], label: "ACK", direction: .right)
        }
    }
}

struct ConnectionLine: View {
    let active: Bool
    let label: String
    let direction: Direction
    
    enum Direction {
        case left, right
    }
    
    var body: some View {
        HStack(spacing: 8) {
            if direction == .left {
                Image(systemName: "arrow.left")
            }
            
            ZStack {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 150, height: 3)
                
                if active {
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [.cyan, .green],
                                startPoint: direction == .right ? .leading : .trailing,
                                endPoint: direction == .right ? .trailing : .leading
                            )
                        )
                        .frame(width: 150, height: 3)
                        .transition(.asymmetric(
                            insertion: .scale(scale: 0, anchor: direction == .right ? .leading : .trailing),
                            removal: .opacity
                        ))
                }
            }
            
            if direction == .right {
                Image(systemName: "arrow.right")
            }
            
            Text(label)
                .font(.system(size: 10, weight: .bold, design: .monospaced))
        }
        .foregroundColor(active ? .green : .gray)
    }
}

// MARK: - Handshake Steps View
struct HandshakeStepsView: View {
    let currentStep: HandshakeStep
    let connectionLines: [Bool]
    
    var body: some View {
        HStack(spacing: 20) {
            ForEach(HandshakeStep.allCases.dropFirst().dropLast(), id: \.rawValue) { step in
                VStack(spacing: 8) {
                    Circle()
                        .fill(stepColor(for: step))
                        .frame(width: 40, height: 40)
                        .overlay(
                            Text("\(step.rawValue)")
                                .font(.system(size: 14, weight: .bold, design: .monospaced))
                                .foregroundColor(.white)
                        )
                        .shadow(color: stepColor(for: step).opacity(0.5), radius: 5)
                    
                    Text(step.label)
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(stepColor(for: step))
                }
            }
        }
    }
    
    private func stepColor(for step: HandshakeStep) -> Color {
        if step.rawValue < currentStep.rawValue {
            return .green
        } else if step.rawValue == currentStep.rawValue {
            return .cyan
        } else {
            return .gray
        }
    }
}

#Preview {
    HandshakeView(engine: GameEngine())
}
