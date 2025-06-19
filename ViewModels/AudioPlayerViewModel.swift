import Foundation
import SwiftUI
import SwiftData

@MainActor
final class AudioPlayerViewModel: ObservableObject {
    let audioService = AudioPlayerService.shared
    
    var isPlaying: Bool {
        audioService.isPlaying
    }
    
    var currentTime: TimeInterval {
        audioService.currentTime
    }
    
    var duration: TimeInterval {
        audioService.duration
    }
    
    var progress: Double {
        duration > 0 ? currentTime / duration : 0
    }
    
    func play(audioItem: AudioItem) {
        audioService.play(audioItem: audioItem)
    }
    
    func togglePlayPause() {
        audioService.togglePlayPause()
    }
    
    func skip15Seconds() {
        audioService.skip(seconds: 15)
    }
    
    func seek(to value: Double) {
        let time = value * duration
        audioService.seek(to: time)
    }
    
    func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    func savePosition(for item: AudioItem?, in context: ModelContext) {
        if let item = item {
            item.lastPlaybackPosition = currentTime
            try? context.save()
        }
    }
}