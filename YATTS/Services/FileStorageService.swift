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
    
    func saveAudioFile(data: Data, filename: String) throws -> URL {
        try setupAudioDirectory()
        let fileURL = audioDirectory.appendingPathComponent(filename)
        try data.write(to: fileURL)
        return fileURL
    }
    
    func deleteAudioFile(at path: String) throws {
        let url = URL(fileURLWithPath: path)
        if FileManager.default.fileExists(atPath: url.path) {
            try FileManager.default.removeItem(at: url)
        }
    }
    
    func getAudioFileURL(for filename: String) -> URL {
        audioDirectory.appendingPathComponent(filename)
    }
    
    func calculateFileSize(at path: String) -> Int64 {
        let url = URL(fileURLWithPath: path)
        guard let attributes = try? FileManager.default.attributesOfItem(atPath: url.path),
              let fileSize = attributes[.size] as? Int64 else {
            return 0
        }
        return fileSize
    }
    
    func totalStorageUsed() -> Int64 {
        guard let files = try? FileManager.default.contentsOfDirectory(
            at: audioDirectory,
            includingPropertiesForKeys: [.fileSizeKey]
        ) else { return 0 }
        
        return files.reduce(0) { total, file in
            let size = (try? file.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0
            return total + Int64(size)
        }
    }
}