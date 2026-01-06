//
//  IntroView.swift
//  Ping
//
//  Act 1: The fake iPhone screen with social media app
//

import SwiftUI

struct IntroView: View {
    let onStartGame: () -> Void
    
    @State private var showApp = false
    @State private var buttonScale: CGFloat = 1.0
    @State private var shimmer = false
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [Color(red: 0.1, green: 0.1, blue: 0.15), Color(red: 0.05, green: 0.05, blue: 0.1)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                // Decorative circuit lines
                CircuitBackground()
                    .opacity(0.3)
                
                VStack(spacing: 40) {
                    // Title
                    VStack(spacing: 8) {
                        Text("PING")
                            .font(.system(size: 48, weight: .bold, design: .monospaced))
                            .foregroundColor(.cyan)
                            .shadow(color: .cyan, radius: 20)
                        
                        Text("A Packet's Odyssey")
                            .font(.system(size: 18, weight: .light, design: .serif))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .opacity(showApp ? 1 : 0)
                    .offset(y: showApp ? 0 : -20)
                    
                    // Fake phone
                    PhoneFrame {
                        FakeSocialApp(onUpload: onStartGame)
                    }
                    .scaleEffect(showApp ? 1 : 0.9)
                    .opacity(showApp ? 1 : 0)
                    
                    // Instructions
                    VStack(spacing: 8) {
                        Text("Tap the button to begin your journey through the internet")
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundColor(.gray)
                        
                        HStack(spacing: 20) {
                            InstructionBadge(icon: "hand.tap.fill", text: "Hold to Fly")
                            InstructionBadge(icon: "lock.shield.fill", text: "Toggle HTTPS")
                            InstructionBadge(icon: "clock.fill", text: "Beat the Timeout")
                        }
                    }
                    .opacity(showApp ? 1 : 0)
                }
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                showApp = true
            }
        }
    }
}

// MARK: - Phone Frame
struct PhoneFrame<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        ZStack {
            // Phone body
            RoundedRectangle(cornerRadius: 40)
                .fill(Color.black)
                .frame(width: 280, height: 520)
                .overlay(
                    RoundedRectangle(cornerRadius: 40)
                        .stroke(
                            LinearGradient(
                                colors: [.gray.opacity(0.8), .gray.opacity(0.3)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 3
                        )
                )
                .shadow(color: .black.opacity(0.5), radius: 20, y: 10)
            
            // Screen
            RoundedRectangle(cornerRadius: 30)
                .fill(Color.white)
                .frame(width: 260, height: 500)
                .overlay(
                    content
                        .clipShape(RoundedRectangle(cornerRadius: 30))
                )
            
            // Notch
            VStack {
                Capsule()
                    .fill(Color.black)
                    .frame(width: 100, height: 25)
                Spacer()
            }
            .frame(height: 500)
        }
    }
}

// MARK: - Fake Social App
struct FakeSocialApp: View {
    let onUpload: () -> Void
    
    @State private var pulseButton = false
    
    var body: some View {
        ZStack {
            // App background
            LinearGradient(
                colors: [Color(red: 0.98, green: 0.98, blue: 1.0), Color(red: 0.95, green: 0.95, blue: 0.98)],
                startPoint: .top,
                endPoint: .bottom
            )
            
            VStack(spacing: 0) {
                // Status bar
                HStack {
                    Text("9:41")
                        .font(.system(size: 12, weight: .semibold))
                    Spacer()
                    HStack(spacing: 4) {
                        Image(systemName: "wifi")
                        Image(systemName: "battery.100")
                    }
                    .font(.system(size: 11))
                }
                .foregroundColor(.black)
                .padding(.horizontal, 20)
                .padding(.top, 35)
                .padding(.bottom, 8)
                
                // App header
                HStack {
                    Text("PetPix")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(.purple)
                    Spacer()
                    Image(systemName: "bell.fill")
                        .foregroundColor(.purple)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
                
                Divider()
                
                // Feed content
                ScrollView {
                    VStack(spacing: 16) {
                        // Post placeholder
                        PostCard()
                        
                        // Upload section
                        VStack(spacing: 16) {
                            Text("Ready to share?")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.gray)
                            
                            // Cat photo placeholder
                            ZStack {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.orange.opacity(0.1))
                                    .frame(height: 100)
                                
                                VStack {
                                    Text("🐱")
                                        .font(.system(size: 40))
                                    Text("cat_photo.jpg")
                                        .font(.system(size: 10, design: .monospaced))
                                        .foregroundColor(.gray)
                                }
                            }
                            .padding(.horizontal, 16)
                            
                            // Upload button
                            Button(action: onUpload) {
                                HStack {
                                    Image(systemName: "arrow.up.circle.fill")
                                    Text("Upload Cat Photo")
                                        .font(.system(size: 14, weight: .bold))
                                }
                                .foregroundColor(.white)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 14)
                                .background(
                                    LinearGradient(
                                        colors: [.purple, .pink],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(25)
                                .shadow(color: .purple.opacity(0.4), radius: 8, y: 4)
                                .scaleEffect(pulseButton ? 1.05 : 1.0)
                            }
                            .onAppear {
                                withAnimation(.easeInOut(duration: 1).repeatForever(autoreverses: true)) {
                                    pulseButton = true
                                }
                            }
                        }
                        .padding(.top, 20)
                    }
                }
                
                // Bottom tab bar
                HStack(spacing: 0) {
                    ForEach(["house.fill", "magnifyingglass", "plus.square", "heart", "person.circle"], id: \.self) { icon in
                        Spacer()
                        Image(systemName: icon)
                            .font(.system(size: 22))
                            .foregroundColor(icon == "house.fill" ? .purple : .gray)
                        Spacer()
                    }
                }
                .padding(.vertical, 12)
                .background(Color.white)
                .shadow(color: .black.opacity(0.05), radius: 5, y: -2)
            }
        }
        .frame(width: 260, height: 500)
    }
}

// MARK: - Post Card
struct PostCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Circle()
                    .fill(Color.blue.opacity(0.3))
                    .frame(width: 32, height: 32)
                    .overlay(Text("🐕").font(.system(size: 16)))
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("doggo_lover")
                        .font(.system(size: 12, weight: .semibold))
                    Text("2 min ago")
                        .font(.system(size: 9))
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                Image(systemName: "ellipsis")
                    .foregroundColor(.gray)
            }
            .padding(.horizontal, 12)
            
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [.blue.opacity(0.2), .green.opacity(0.2)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(height: 80)
                .overlay(
                    Text("🐶")
                        .font(.system(size: 30))
                )
            
            HStack(spacing: 16) {
                HStack(spacing: 4) {
                    Image(systemName: "heart.fill")
                        .foregroundColor(.red)
                    Text("42")
                }
                HStack(spacing: 4) {
                    Image(systemName: "bubble.right")
                    Text("8")
                }
                Spacer()
            }
            .font(.system(size: 12))
            .foregroundColor(.gray)
            .padding(.horizontal, 12)
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Instruction Badge
struct InstructionBadge: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 12))
            Text(text)
                .font(.system(size: 10, design: .monospaced))
        }
        .foregroundColor(.cyan.opacity(0.8))
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .stroke(Color.cyan.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Circuit Background
struct CircuitBackground: View {
    var body: some View {
        GeometryReader { geo in
            Path { path in
                // Horizontal lines
                for i in stride(from: 0, to: geo.size.height, by: 50) {
                    path.move(to: CGPoint(x: 0, y: i))
                    path.addLine(to: CGPoint(x: geo.size.width * 0.3, y: i))
                    path.addLine(to: CGPoint(x: geo.size.width * 0.35, y: i + 20))
                    path.addLine(to: CGPoint(x: geo.size.width * 0.7, y: i + 20))
                }
                
                // Vertical lines
                for i in stride(from: 0, to: geo.size.width, by: 80) {
                    path.move(to: CGPoint(x: i, y: 0))
                    path.addLine(to: CGPoint(x: i, y: geo.size.height * 0.4))
                }
            }
            .stroke(Color.cyan.opacity(0.2), lineWidth: 1)
        }
    }
}

#Preview {
    IntroView(onStartGame: {})
}
