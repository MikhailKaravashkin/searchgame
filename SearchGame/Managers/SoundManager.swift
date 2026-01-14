import Foundation
import AVFoundation
import SpriteKit

class SoundManager {
    
    static let shared = SoundManager()
    
    private var backgroundMusicPlayer: AVAudioPlayer?
    private var audioPlayers: [String: AVAudioPlayer] = [:]
    
    private(set) var isMusicEnabled = true
    private(set) var isSoundEnabled = true
    
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
    
    // MARK: - Background Music
    
    func playBackgroundMusic() {
        guard isMusicEnabled else { return }
        
        // Для начала используем генерированный тон
        // TODO: заменить на реальный аудиофайл
        backgroundMusicPlayer?.stop()
    }
    
    func stopBackgroundMusic() {
        backgroundMusicPlayer?.stop()
    }
    
    // MARK: - Sound Effects
    
    func playItemFound() {
        guard isSoundEnabled else { return }
        playSystemSound(frequency: 800, duration: 0.15)
    }
    
    func playVictory() {
        guard isSoundEnabled else { return }
        // Играем последовательность нот
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.0) { [weak self] in
            self?.playSystemSound(frequency: 523, duration: 0.15) // C
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [weak self] in
            self?.playSystemSound(frequency: 659, duration: 0.15) // E
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.playSystemSound(frequency: 784, duration: 0.3) // G
        }
    }
    
    func playInteraction(type: String) {
        guard isSoundEnabled else { return }
        
        switch type {
        case "pig":
            playSystemSound(frequency: 400, duration: 0.2)
        case "cat":
            playSystemSound(frequency: 1000, duration: 0.1)
        case "dog":
            playSystemSound(frequency: 300, duration: 0.2)
        default:
            playSystemSound(frequency: 600, duration: 0.1)
        }
    }
    
    // MARK: - Settings
    
    func toggleMusic() {
        isMusicEnabled.toggle()
        if isMusicEnabled {
            playBackgroundMusic()
        } else {
            stopBackgroundMusic()
        }
    }
    
    func toggleSound() {
        isSoundEnabled.toggle()
    }
    
    // MARK: - Private Helpers
    
    private func playSystemSound(frequency: Float, duration: TimeInterval) {
        // Создаём синусоидальный тон программно
        let sampleRate = 44100.0
        let samples = Int(sampleRate * duration)
        
        var audioBuffer = [Int16]()
        let amplitude: Float = 0.3
        
        for i in 0..<samples {
            let time = Float(i) / Float(sampleRate)
            let value = sin(2.0 * .pi * frequency * time) * amplitude
            audioBuffer.append(Int16(value * Float(Int16.max)))
        }
        
        // Играем через AudioToolbox
        AudioServicesPlaySystemSound(1104) // Fallback system sound
    }
}
