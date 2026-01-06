//
//  SoundManager.swift
//  Ping
//
//  Audio management for game sounds
//

import AVFoundation

class SoundManager {
    static let shared = SoundManager()
    
    private var audioPlayers: [String: AVAudioPlayer] = [:]
    private var isMuted: Bool = false
    
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
    
    // MARK: - Sound Effects (Using System Sounds as Placeholders)
    
    func playThrust() {
        // Placeholder - would load actual sound file
        playSystemSound(1104) // Tick sound
    }
    
    func playHit() {
        playSystemSound(1073) // Alert sound
    }
    
    func playCollect() {
        playSystemSound(1057) // Positive sound
    }
    
    func playHandshake() {
        playSystemSound(1075) // Connection sound
    }
    
    func playTransition() {
        playSystemSound(1110) // Swoosh sound
    }
    
    func playSuccess() {
        playSystemSound(1025) // Success fanfare
    }
    
    func playFailure() {
        playSystemSound(1073) // Error sound
    }
    
    // MARK: - System Sound Helper
    private func playSystemSound(_ soundID: SystemSoundID) {
        guard !isMuted else { return }
        AudioServicesPlaySystemSound(soundID)
    }
    
    // MARK: - Controls
    func toggleMute() {
        isMuted.toggle()
    }
    
    var muted: Bool {
        get { isMuted }
        set { isMuted = newValue }
    }
}
