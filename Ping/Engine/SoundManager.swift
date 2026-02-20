//
//  SoundManager.swift
//  Ping - Packet World
//
//  Manages ambient sounds and haptic feedback
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
        
        // Ensure you add these .mp3 files to your Xcode project!
        guard let url = Bundle.main.url(forResource: filename, withExtension: "mp3") else {
            print("Missing audio file: \(filename).mp3")
            return
        }
        
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.volume = volume
            player.play()
            
            // Store reference so it plays fully, then clean up finished ones
            sfxPlayers.append(player)
            sfxPlayers.removeAll { !$0.isPlaying }
        } catch {
            print("Failed to play \(filename): \(error.localizedDescription)")
        }
    }
    
    private func playBGM(filename: String) {
        guard let url = Bundle.main.url(forResource: filename, withExtension: "mp3") else {
            print("Missing BGM file: \(filename).mp3")
            return
        }
        
        do {
            // Prevent restarting the track if it's already playing the same one
            if let currentUrl = bgmPlayer?.url, currentUrl == url, bgmPlayer?.isPlaying == true {
                return
            }
            
            bgmPlayer = try AVAudioPlayer(contentsOf: url)
            bgmPlayer?.numberOfLoops = -1 // Loop infinitely
            bgmPlayer?.volume = 0.3       // Keep music quiet so SFX pop
            
            if !isMuted {
                bgmPlayer?.play()
            }
        } catch {
            print("Failed to play BGM: \(error.localizedDescription)")
        }
    }
    
    // MARK: - 8-bit Talking Effect
    func playTalkingSound() {
        guard !isMuted else { return }
        
        playSoundEffect(filename: "typewriter", volume: 0.5)
        
        let generator = UIImpactFeedbackGenerator(style: .soft)
        generator.impactOccurred()
    }
    
    // MARK: - Scene Ambient Sounds
    func playAmbientSound(for scene: StoryScene) {
        // We switch the Background Music based on the scene you are in
        switch scene {
        case .frozenCafe, .feedLoaded:
            playBGM(filename: "cafe_ambient")
        case .cpuCity:
            playBGM(filename: "cyber_bgm")
        case .oceanCable:
            playBGM(filename: "underwater_hum")
        case .dnsLibrary:
            playBGM(filename: "library_chimes")
        default:
            bgmPlayer?.stop()
        }
        
        // Keep your original haptic triggers
        guard !isMuted else { return }
        let style: UIImpactFeedbackGenerator.FeedbackStyle = scene == .dnsLibrary ? .rigid : .light
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }
    
    // MARK: - UI Sounds
    func playButtonSound() {
        playSoundEffect(filename: "blip")
        
        guard !isMuted else { return }
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
    
    func playTermLearnedSound() {
        playSoundEffect(filename: "achievement")
        
        guard !isMuted else { return }
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
    
    func playPortalSound() {
        playSoundEffect(filename: "warp")
        
        guard !isMuted else { return }
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()
    }
    
    func playMissionCompleteSound() {
        playSoundEffect(filename: "mission_win")
        
        guard !isMuted else { return }
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
    
    func toggleMute() {
        isMuted.toggle()
    }
}
