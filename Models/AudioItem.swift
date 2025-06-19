import Foundation
import SwiftData

@Model
final class AudioItem {
    var id: UUID
    var title: String
    var textContent: String
    var audioFilePath: String
    var duration: TimeInterval
    var lastPlaybackPosition: TimeInterval
    var createdAt: Date
    var fileSize: Int64
    
    init(
        title: String,
        textContent: String,
        audioFilePath: String,
        duration: TimeInterval = 0,
        lastPlaybackPosition: TimeInterval = 0,
        fileSize: Int64 = 0
    ) {
        self.id = UUID()
        self.title = title
        self.textContent = textContent
        self.audioFilePath = audioFilePath
        self.duration = duration
        self.lastPlaybackPosition = lastPlaybackPosition
        self.createdAt = Date()
        self.fileSize = fileSize
    }
}