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
    @Published var currentChunkIndex: Int = 0
    @Published var totalChunks: Int = 0
    
    private var audioPlayer: AVAudioPlayer?
    private var timer: Timer?
    private var chunks: [AudioChunk] = []
    private var chunkStartTimes: [TimeInterval] = []
    
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
    
    // MARK: - Playback Control
    
    func play(audioItem: AudioItem) {
        currentItem = audioItem
        
        if audioItem.isChunked {
            playChunkedItem(audioItem)
        } else {
            playLegacyItem(audioItem)
        }
    }
    
    private func playLegacyItem(_ audioItem: AudioItem) {
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
    
    private func playChunkedItem(_ audioItem: AudioItem) {
        // Sort chunks by index and filter only downloaded ones
        chunks = audioItem.chunks
            .filter { $0.isDownloaded }
            .sorted { $0.index < $1.index }
        
        guard !chunks.isEmpty else {
            print("No downloaded chunks available")
            return
        }
        
        totalChunks = chunks.count
        
        // Calculate chunk start times for seeking
        chunkStartTimes = []
        var accumulatedTime: TimeInterval = 0
        for chunk in chunks {
            chunkStartTimes.append(accumulatedTime)
            accumulatedTime += chunk.duration
        }
        duration = accumulatedTime
        
        // Determine which chunk to start from based on last position
        let startChunkIndex = determineChunkIndex(for: audioItem.lastPlaybackPosition)
        currentChunkIndex = startChunkIndex
        
        // Play the chunk
        playChunk(at: startChunkIndex, startTime: audioItem.lastPlaybackPosition - chunkStartTimes[startChunkIndex])
    }
    
    private func playChunk(at index: Int, startTime: TimeInterval = 0) {
        guard index < chunks.count else {
            // Finished all chunks
            stop()
            return
        }
        
        let chunk = chunks[index]
        let url = URL(fileURLWithPath: chunk.audioFilePath)
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.delegate = self
            audioPlayer?.prepareToPlay()
            
            if startTime > 0 {
                audioPlayer?.currentTime = startTime
            }
            
            audioPlayer?.play()
            isPlaying = true
            currentChunkIndex = index
            
            if timer?.isValid != true {
                startTimer()
            }
        } catch {
            print("Failed to play chunk \(index): \(error)")
        }
    }
    
    private func playNextChunk() {
        guard currentChunkIndex + 1 < chunks.count else {
            // No more chunks
            stop()
            return
        }
        
        currentChunkIndex += 1
        playChunk(at: currentChunkIndex)
    }
    
    // MARK: - Controls
    
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
        
        if let item = currentItem, item.isChunked {
            // Handle chunk-aware skipping
            let currentChunkTime = player.currentTime
            let globalTime = chunkStartTimes[currentChunkIndex] + currentChunkTime
            let newGlobalTime = max(0, min(duration, globalTime + seconds))
            
            let targetChunkIndex = determineChunkIndex(for: newGlobalTime)
            let targetChunkTime = newGlobalTime - chunkStartTimes[targetChunkIndex]
            
            if targetChunkIndex != currentChunkIndex {
                // Need to switch chunks
                playChunk(at: targetChunkIndex, startTime: targetChunkTime)
            } else {
                // Stay in same chunk
                player.currentTime = targetChunkTime
            }
        } else {
            // Legacy single file
            let newTime = player.currentTime + seconds
            if newTime >= 0 && newTime <= duration {
                player.currentTime = newTime
            }
        }
        
        saveCurrentPosition()
    }
    
    func seek(to time: TimeInterval) {
        if let item = currentItem, item.isChunked {
            let targetChunkIndex = determineChunkIndex(for: time)
            let targetChunkTime = time - chunkStartTimes[targetChunkIndex]
            
            if targetChunkIndex != currentChunkIndex {
                playChunk(at: targetChunkIndex, startTime: targetChunkTime)
            } else {
                audioPlayer?.currentTime = targetChunkTime
            }
        } else {
            audioPlayer?.currentTime = time
        }
        
        saveCurrentPosition()
    }
    
    // MARK: - Helpers
    
    private func determineChunkIndex(for globalTime: TimeInterval) -> Int {
        for (index, startTime) in chunkStartTimes.enumerated() {
            if index + 1 < chunkStartTimes.count {
                if globalTime >= startTime && globalTime < chunkStartTimes[index + 1] {
                    return index
                }
            } else {
                // Last chunk
                if globalTime >= startTime {
                    return index
                }
            }
        }
        return 0
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
        if let item = currentItem, item.isChunked {
            let chunkTime = audioPlayer?.currentTime ?? 0
            currentTime = chunkStartTimes[currentChunkIndex] + chunkTime
        } else {
            currentTime = audioPlayer?.currentTime ?? 0
        }
    }
    
    private func saveCurrentPosition() {
        if let item = currentItem {
            item.lastPlaybackPosition = currentTime
            item.lastPlayedChunkIndex = currentChunkIndex
        }
    }
    
    func stop() {
        audioPlayer?.stop()
        audioPlayer = nil
        isPlaying = false
        currentTime = 0
        duration = 0
        currentChunkIndex = 0
        totalChunks = 0
        chunks = []
        chunkStartTimes = []
        stopTimer()
        saveCurrentPosition()
        currentItem = nil
    }
}

extension AudioPlayerService: AVAudioPlayerDelegate {
    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor in
            if let item = self.currentItem, item.isChunked && flag {
                // Play next chunk
                self.playNextChunk()
            } else {
                // Single file finished or error
                self.isPlaying = false
                self.currentTime = 0
                self.stopTimer()
                if let item = self.currentItem {
                    item.lastPlaybackPosition = 0
                }
            }
        }
    }
}