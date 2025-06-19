import Foundation
import AVFoundation
import SwiftUI

@MainActor
final class AudioPlayerService: NSObject, ObservableObject {
    static let shared = AudioPlayerService()
    
    @Published var isPlaying = false
    @Published var currentTime: TimeInterval = 0
    @Published var duration: TimeInterval = 0
    @Published var currentItem: AudioItem?
    
    private var audioPlayer: AVAudioPlayer?
    private var timer: Timer?
    
    override private init() {
        super.init()
        setupAudioSession()
    }
    
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(
                .playback,
                mode: .spokenAudio,
                options: [.allowBluetooth, .allowAirPlay]
            )
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to setup audio session: \(error)")
        }
    }
    
    func play(audioItem: AudioItem) {
        currentItem = audioItem
        
        let url = URL(fileURLWithPath: audioItem.audioFilePath)
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.delegate = self
            audioPlayer?.prepareToPlay()
            
            duration = audioPlayer?.duration ?? 0
            audioItem.duration = duration
            
            if audioItem.lastPlaybackPosition > 0 && audioItem.lastPlaybackPosition < duration {
                audioPlayer?.currentTime = audioItem.lastPlaybackPosition
            }
            
            audioPlayer?.play()
            isPlaying = true
            startTimer()
        } catch {
            print("Failed to play audio: \(error)")
        }
    }
    
    func pause() {
        audioPlayer?.pause()
        isPlaying = false
        stopTimer()
        saveCurrentPosition()
    }
    
    func resume() {
        audioPlayer?.play()
        isPlaying = true
        startTimer()
    }
    
    func togglePlayPause() {
        if isPlaying {
            pause()
        } else if audioPlayer != nil {
            resume()
        }
    }
    
    func skip(seconds: Double) {
        guard let player = audioPlayer else { return }
        let newTime = player.currentTime + seconds
        if newTime >= 0 && newTime <= duration {
            player.currentTime = newTime
            currentTime = newTime
            saveCurrentPosition()
        }
    }
    
    func seek(to time: TimeInterval) {
        guard let player = audioPlayer else { return }
        player.currentTime = time
        currentTime = time
        saveCurrentPosition()
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            self.updateCurrentTime()
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private func updateCurrentTime() {
        currentTime = audioPlayer?.currentTime ?? 0
    }
    
    private func saveCurrentPosition() {
        if let item = currentItem {
            item.lastPlaybackPosition = currentTime
        }
    }
    
    func stop() {
        audioPlayer?.stop()
        audioPlayer = nil
        isPlaying = false
        currentTime = 0
        duration = 0
        stopTimer()
        saveCurrentPosition()
        currentItem = nil
    }
}

extension AudioPlayerService: AVAudioPlayerDelegate {
    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor in
            self.isPlaying = false
            self.currentTime = 0
            self.stopTimer()
            if let item = self.currentItem {
                item.lastPlaybackPosition = 0
            }
        }
    }
}