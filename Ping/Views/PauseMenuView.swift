import SwiftUI

struct PauseMenuView: View {
    @ObservedObject var engine: GameEngine
    
    var body: some View {
        ZStack {
            // Dark blurred background
            Color.black.opacity(0.6)
                .background(.ultraThinMaterial)
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                Text("PAUSED")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .tracking(2)
                
                VStack(spacing: 16) {
                    Button(action: {
                        SoundManager.shared.playButtonSound()
                        withAnimation {
                            engine.showPauseMenu = false
                        }
                    }) {
                        HStack {
                            Image(systemName: "play.fill")
                            Text("Resume Journey")
                        }
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(.black)
                        .frame(width: 200)
                        .padding(.vertical, 14)
                        .background(
                            Capsule().fill(Color.accentColor) // Change to appropriate theme color
                        )
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: {
                        SoundManager.shared.playButtonSound()
                        withAnimation {
                            engine.showPauseMenu = false
                            engine.resetGame()
                        }
                    }) {
                        HStack {
                            Image(systemName: "arrow.counterclockwise")
                            Text("Restart Game")
                        }
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .frame(width: 200)
                        .padding(.vertical, 14)
                        .background(
                            Capsule().fill(Color.white.opacity(0.1))
                        )
                        .overlay(
                            Capsule().stroke(Color.white.opacity(0.3), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(40)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color(red: 0.05, green: 0.05, blue: 0.08).opacity(0.9))
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(Color.cyan.opacity(0.4), lineWidth: 1.5)
                    )
                    .shadow(color: Color.cyan.opacity(0.2), radius: 20)
            )
        }
    }
}
