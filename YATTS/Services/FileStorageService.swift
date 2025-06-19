import Foundation

final class FileStorageService {
    static let shared = FileStorageService()
    
    private init() {}
    
    private var documentsDirectory: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    }
    
    private var audioDirectory: URL {
        documentsDirectory.appendingPathComponent("AudioFiles", isDirectory: true)
    }
    
    func setupAudioDirectory() throws {
        try FileManager.default.createDirectory(
            at: audioDirectory,
            withIntermediateDirectories: true
        )
    }
    
    // MARK: - Chunk Management
    
    func getItemDirectory(for itemId: UUID) -> URL {
        audioDirectory.appendingPathComponent(itemId.uuidString, isDirectory: true)
    }
    
    func setupItemDirectory(for itemId: UUID) throws {
        let itemDirectory = getItemDirectory(for: itemId)
        try FileManager.default.createDirectory(
            at: itemDirectory,
            withIntermediateDirectories: true
        )
    }
    
    func saveChunkFile(data: Data, itemId: UUID, chunkIndex: Int) throws -> URL {
        try setupItemDirectory(for: itemId)
        let filename = "chunk_\(chunkIndex).mp3"
        let fileURL = getItemDirectory(for: itemId).appendingPathComponent(filename)
        try data.write(to: fileURL)
        return fileURL
    }
    
    func deleteAllChunks(for itemId: UUID) throws {
        let itemDirectory = getItemDirectory(for: itemId)
        if FileManager.default.fileExists(atPath: itemDirectory.path) {
            try FileManager.default.removeItem(at: itemDirectory)
        }
    }
    
    func getChunkURL(itemId: UUID, chunkIndex: Int) -> URL {
        let filename = "chunk_\(chunkIndex).mp3"
        return getItemDirectory(for: itemId).appendingPathComponent(filename)
    }
    
    // MARK: - Legacy Single File Support
    
    func saveAudioFile(data: Data, filename: String) throws -> URL {
        try setupAudioDirectory()
        let fileURL = audioDirectory.appendingPathComponent(filename)
        try data.write(to: fileURL)
        return fileURL
    }
    
    func deleteAudioFile(at path: String) throws {
        let url = URL(fileURLWithPath: path)
        if FileManager.default.fileExists(atPath: url.path) {
            // Check if it's a directory (chunked item) or file (legacy)
            var isDirectory: ObjCBool = false
            if FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory) {
                try FileManager.default.removeItem(at: url)
            }
        }
    }
    
    func getAudioFileURL(for filename: String) -> URL {
        audioDirectory.appendingPathComponent(filename)
    }
    
    func calculateFileSize(at path: String) -> Int64 {
        let url = URL(fileURLWithPath: path)
        
        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory) else {
            return 0
        }
        
        if isDirectory.boolValue {
            // Calculate total size of all files in directory
            guard let files = try? FileManager.default.contentsOfDirectory(
                at: url,
                includingPropertiesForKeys: [.fileSizeKey]
            ) else { return 0 }
            
            return files.reduce(0) { total, file in
                let size = (try? file.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0
                return total + Int64(size)
            }
        } else {
            // Single file
            guard let attributes = try? FileManager.default.attributesOfItem(atPath: url.path),
                  let fileSize = attributes[.size] as? Int64 else {
                return 0
            }
            return fileSize
        }
    }
    
    func totalStorageUsed() -> Int64 {
        guard let items = try? FileManager.default.contentsOfDirectory(
            at: audioDirectory,
            includingPropertiesForKeys: [.fileSizeKey, .isDirectoryKey]
        ) else { return 0 }
        
        return items.reduce(0) { total, item in
            let size = calculateFileSize(at: item.path)
            return total + size
        }
    }
}