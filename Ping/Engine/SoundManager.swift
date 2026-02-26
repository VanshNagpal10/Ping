//
//  SoundManager.swift
//  Ping
//

import SwiftUI
import AVFoundation
import Combine

@MainActor
class SoundManager: ObservableObject {
    static let shared = SoundManager()
    
    @Published var isMuted: Bool = false {
        didSet {
            if isMuted {
                bgmPlayer?.pause()
            } else {
                bgmPlayer?.play()
            }
        }
    }
    
    // Audio Players
    private var bgmPlayer: AVAudioPlayer?
    private var sfxPlayers: [AVAudioPlayer] = []
    private var currentBGMFile: String? = nil
    private var typewriterPlayer: AVAudioPlayer?
    
    private init() {
        setupAudioSession()
    }
    
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to setup audio session: \(error)")
        }
    }
    
    // MARK: - Core Audio Logic
    private func playSoundEffect(filename: String, volume: Float = 0.8) {
        guard !isMuted else { return }
        
        guard let url = Bundle.main.url(forResource: filename, withExtension: "mp3") else {
            print("Missing audio file: \(filename).mp3")
            return
        }
        
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.volume = volume
            player.play()
            
            sfxPlayers.append(player)
            sfxPlayers.removeAll { !$0.isPlaying }
        } catch {
            print("Failed to play \(filename): \(error.localizedDescription)")
        }
    }
    
    private func playBGM(filename: String, volume: Float = 0.3) {
        if currentBGMFile == filename, bgmPlayer?.isPlaying == true {
            return
        }
        
        guard let url = Bundle.main.url(forResource: filename, withExtension: "mp3") else {
            print("Missing BGM file: \(filename).mp3")
            bgmPlayer?.stop()
            currentBGMFile = nil
            return
        }
        
        do {
            bgmPlayer?.stop()
            bgmPlayer = try AVAudioPlayer(contentsOf: url)
            bgmPlayer?.numberOfLoops = -1
            bgmPlayer?.volume = volume
            currentBGMFile = filename
            
            if !isMuted {
                bgmPlayer?.play()
            }
        } catch {
            print("Failed to play BGM: \(error.localizedDescription)")
        }
    }
    
    func stopBGM() {
        bgmPlayer?.stop()
        currentBGMFile = nil
    }
    
    // MARK: - Dialogue Typing
    func playTypingHaptic() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred(intensity: 0.4)
    }
    
    /// Start the typewriter sound for a dialogue line. Stops any previous instance first.
    func startTypewriterSound() {
        stopTypewriterSound()
        
        let generator = UIImpactFeedbackGenerator(style: .soft)
        generator.impactOccurred()
        
        guard !isMuted else { return }
        guard let url = Bundle.main.url(forResource: "typewriter", withExtension: "mp3") else { return }
        
        do {
            typewriterPlayer = try AVAudioPlayer(contentsOf: url)
            typewriterPlayer?.volume = 0.2
            typewriterPlayer?.play()
        } catch {
            print("Failed to play typewriter: \(error.localizedDescription)")
        }
    }
    
    /// Stop the typewriter sound immediately (called when text finishes or user skips)
    func stopTypewriterSound() {
        typewriterPlayer?.stop()
        typewriterPlayer = nil
    }
    
    // MARK: - Scene Ambient Sounds
    func playAmbientSound(for scene: StoryScene) {
        switch scene {
        case .prologue, .feedLoaded:
            // No cafe_ambient file yet  - use cyber_bgm at lower volume as fallback
            playBGM(filename: "cyber_bgm", volume: 0.15)
        case .cpuCity:
            playBGM(filename: "cyber_bgm", volume: 0.25)
        case .wifiAntenna, .routerStation:
            playBGM(filename: "cyber_bgm", volume: 0.2)
        case .oceanCable:
            playBGM(filename: "underwater_hum", volume: 0.3)
        case .dnsLibrary:
            // No library_chimes file yet  - use cyber_bgm at low volume
            playBGM(filename: "cyber_bgm", volume: 0.15)
        case .returnJourney:
            playBGM(filename: "cyber_bgm", volume: 0.3)
        }
        

        let style: UIImpactFeedbackGenerator.FeedbackStyle = scene == .oceanCable ? .rigid : .light
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }
    
    func playTermLearnedSound() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        guard !isMuted else { return }
        playSoundEffect(filename: "achievement", volume: 0.8)
    }
    
    func playPortalSound() {
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()
        
        guard !isMuted else { return }
        // Use achievement sound for portal too (until you add warp.mp3)
        playSoundEffect(filename: "achievement", volume: 0.6)
    }
    
    func playErrorSound() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.error)
        
        guard !isMuted else { return }
        playSoundEffect(filename: "error", volume: 0.7)
    }
    
    func playQuizCorrectSound() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        guard !isMuted else { return }
        playSoundEffect(filename: "achievement", volume: 0.6)
    }
    
    func playQuizWrongSound() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.warning)
        
        guard !isMuted else { return }
        playSoundEffect(filename: "error", volume: 0.5)
    }
    
    func playMissionCompleteSound() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        guard !isMuted else { return }
        playSoundEffect(filename: "achievement", volume: 1.0)
    }
    
    func toggleMute() {
        isMuted.toggle()
    }
}
