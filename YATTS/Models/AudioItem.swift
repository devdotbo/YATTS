import Foundation
import SwiftData

@Model
final class AudioItem {
    var id: UUID
    var title: String
    var textContent: String
    var audioFilePath: String // Legacy: for single file items
    var duration: TimeInterval
    var lastPlaybackPosition: TimeInterval
    var createdAt: Date
    var fileSize: Int64
    
    // Chunking support
    @Relationship(deleteRule: .cascade, inverse: \AudioChunk.audioItem)
    var chunks: [AudioChunk] = []
    var totalChunks: Int = 0
    var downloadedChunks: Int = 0
    var isChunked: Bool = false
    var lastPlayedChunkIndex: Int = 0
    
    // Computed properties
    var isFullyDownloaded: Bool {
        if isChunked {
            return downloadedChunks == totalChunks
        }
        return true // Legacy single files are always "fully downloaded"
    }
    
    var totalDuration: TimeInterval {
        if isChunked {
            return chunks.reduce(0) { $0 + $1.duration }
        }
        return duration
    }
    
    var downloadProgress: Double {
        guard totalChunks > 0 else { return 1.0 }
        return Double(downloadedChunks) / Double(totalChunks)
    }
    
    init(
        title: String,
        textContent: String,
        audioFilePath: String = "",
        duration: TimeInterval = 0,
        lastPlaybackPosition: TimeInterval = 0,
        fileSize: Int64 = 0,
        isChunked: Bool = false
    ) {
        self.id = UUID()
        self.title = title
        self.textContent = textContent
        self.audioFilePath = audioFilePath
        self.duration = duration
        self.lastPlaybackPosition = lastPlaybackPosition
        self.createdAt = Date()
        self.fileSize = fileSize
        self.isChunked = isChunked
    }
    
    func updateChunkProgress() {
        downloadedChunks = chunks.filter { $0.isDownloaded }.count
        fileSize = chunks.reduce(0) { total, chunk in
            if chunk.isDownloaded {
                return total + FileStorageService.shared.calculateFileSize(at: chunk.audioFilePath)
            }
            return total
        }
    }
}