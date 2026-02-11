//
//  SoundManager.swift
//  Ping - Packet World
//
//  Manages ambient sounds and haptic feedback
//

import SwiftUI
import AVFoundation

@MainActor
class SoundManager {
    static let shared = SoundManager()
    
    var isMuted: Bool = false
    
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
    
    // MARK: - 8-bit Talking Effect
    func playTalkingSound() {
        guard !isMuted else { return }
        let generator = UIImpactFeedbackGenerator(style: .soft)
        generator.impactOccurred()
    }
    
    // MARK: - Scene Ambient Sounds
    func playAmbientSound(for scene: StoryScene) {
        guard !isMuted else { return }
        
        switch scene {
        case .cpuCity:
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
        case .oceanCable:
            let generator = UIImpactFeedbackGenerator(style: .soft)
            generator.impactOccurred()
        case .dnsLibrary:
            let generator = UIImpactFeedbackGenerator(style: .rigid)
            generator.impactOccurred()
        default:
            break
        }
    }
    
    // MARK: - UI Sounds
    func playButtonSound() {
        guard !isMuted else { return }
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
    
    func playTermLearnedSound() {
        guard !isMuted else { return }
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
    
    func playPortalSound() {
        guard !isMuted else { return }
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()
    }
    
    func playMissionCompleteSound() {
        guard !isMuted else { return }
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
    
    func toggleMute() {
        isMuted.toggle()
    }
}
