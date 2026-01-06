//
//  HUDView.swift
//  Ping
//
//  Heads-up display showing latency, protocol, and zone info
//

import SwiftUI

struct HUDView: View {
    let latency: Int
    let maxLatency: Int
    let currentZone: Zone
    let protocolMode: ProtocolMode
    let movementStyle: MovementStyle
    let isPaused: Bool
    
    let onToggleProtocol: () -> Void
    let onToggleMovement: () -> Void
    let onPause: () -> Void
    
    var body: some View {
        VStack {
            // Top Bar
            HStack(alignment: .top) {
                // Latency Display
                latencyView
                
                Spacer()
                
                // Zone Indicator
                zoneIndicator
                
                Spacer()
                
                // Pause Button
                Button(action: onPause) {
                    Image(systemName: isPaused ? "play.fill" : "pause.fill")
                        .font(.title2)
                        .foregroundColor(.white)
                        .padding(12)
                        .background(Color.white.opacity(0.2))
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)
            
            Spacer()
            
            // Bottom Controls
            HStack(spacing: 20) {
                // Protocol Toggle
                Button(action: onToggleProtocol) {
                    HStack(spacing: 8) {
                        Image(systemName: protocolMode == .https ? "lock.fill" : "lock.open.fill")
                        Text(protocolMode == .https ? "HTTPS" : "HTTP")
                            .font(.system(.caption, design: .monospaced))
                    }
                    .foregroundColor(protocolMode == .https ? .yellow : .red)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.black.opacity(0.5))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(protocolMode == .https ? Color.yellow : Color.red, lineWidth: 2)
                            )
                    )
                }
                
                // Movement Style Toggle
                Button(action: onToggleMovement) {
                    HStack(spacing: 8) {
                        Image(systemName: movementStyle == .tcp ? "checkmark.circle.fill" : "bolt.fill")
                        Text(movementStyle == .tcp ? "TCP" : "UDP")
                            .font(.system(.caption, design: .monospaced))
                    }
                    .foregroundColor(movementStyle == .tcp ? .green : .purple)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.black.opacity(0.5))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(movementStyle == .tcp ? Color.green : Color.purple, lineWidth: 2)
                            )
                    )
                }
                
                Spacer()
                
                // Instructions
                VStack(alignment: .trailing, spacing: 4) {
                    Text("HOLD to thrust")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(.gray)
                    Text("RELEASE to fall")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(.gray)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 20)
        }
    }
    
    // MARK: - Latency View
    private var latencyView: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("PING")
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundColor(.gray)
            
            HStack(spacing: 4) {
                Text("\(latency)")
                    .font(.system(size: 28, weight: .bold, design: .monospaced))
                    .foregroundColor(latencyColor)
                Text("ms")
                    .font(.system(size: 14, design: .monospaced))
                    .foregroundColor(latencyColor.opacity(0.7))
            }
            
            // Latency bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.3))
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(latencyColor)
                        .frame(width: geo.size.width * latencyProgress)
                }
            }
            .frame(width: 100, height: 6)
        }
    }
    
    private var latencyColor: Color {
        let ratio = Double(latency) / Double(maxLatency)
        if ratio < 0.4 {
            return .green
        } else if ratio < 0.7 {
            return .yellow
        } else {
            return .red
        }
    }
    
    private var latencyProgress: CGFloat {
        min(CGFloat(latency) / CGFloat(maxLatency), 1.0)
    }
    
    // MARK: - Zone Indicator
    private var zoneIndicator: some View {
        VStack(spacing: 4) {
            Text("ZONE")
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundColor(.gray)
            
            Text(currentZone.name.uppercased())
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .foregroundColor(currentZone.accentColor)
            
            // Zone progress dots
            HStack(spacing: 8) {
                ForEach(Zone.allCases, id: \.rawValue) { zone in
                    Circle()
                        .fill(zone.rawValue <= currentZone.rawValue ? zone.accentColor : Color.gray.opacity(0.3))
                        .frame(width: 8, height: 8)
                }
            }
        }
    }
}

#Preview {
    ZStack {
        Color.black
        HUDView(
            latency: 150,
            maxLatency: 500,
            currentZone: .ispDns,
            protocolMode: .https,
            movementStyle: .tcp,
            isPaused: false,
            onToggleProtocol: {},
            onToggleMovement: {},
            onPause: {}
        )
    }
}
