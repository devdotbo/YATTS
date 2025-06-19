import Foundation
import SwiftData
import SwiftUI

@MainActor
final class AudioListViewModel: ObservableObject {
    @Published var showDeleteAlert = false
    @Published var itemToDelete: AudioItem?
    
    private let fileService = FileStorageService.shared
    
    func deleteItem(_ item: AudioItem, from context: ModelContext) {
        do {
            try fileService.deleteAudioFile(at: item.audioFilePath)
            context.delete(item)
            try context.save()
        } catch {
            print("Failed to delete item: \(error)")
        }
    }
    
    func confirmDelete(_ item: AudioItem) {
        itemToDelete = item
        showDeleteAlert = true
    }
    
    func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    func formatFileSize(_ size: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: size)
    }
    
    func getTotalStorageUsed() -> String {
        let totalSize = fileService.totalStorageUsed()
        return formatFileSize(totalSize)
    }
}