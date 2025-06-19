import Foundation
import SwiftData

@Model
final class AudioChunk {
    var id: UUID
    var index: Int
    var audioFilePath: String
    var duration: TimeInterval
    var isDownloaded: Bool
    var textContent: String
    
    // Relationship
    var audioItem: AudioItem?
    
    init(
        index: Int,
        audioFilePath: String,
        duration: TimeInterval = 0,
        isDownloaded: Bool = false,
        textContent: String = ""
    ) {
        self.id = UUID()
        self.index = index
        self.audioFilePath = audioFilePath
        self.duration = duration
        self.isDownloaded = isDownloaded
        self.textContent = textContent
    }
}