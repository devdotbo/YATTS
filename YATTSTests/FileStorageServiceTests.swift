import XCTest
@testable import YATTS

final class FileStorageServiceTests: XCTestCase {
    var service: FileStorageService!
    let testItemId = UUID()
    
    override func setUp() {
        super.setUp()
        service = FileStorageService.shared
    }
    
    override func tearDown() {
        // Clean up test files
        try? service.deleteAllChunks(for: testItemId)
        super.tearDown()
    }
    
    // MARK: - Chunk File Tests
    
    func testSaveAndRetrieveChunkFile() throws {
        let testData = "Test audio data".data(using: .utf8)!
        let chunkIndex = 0
        
        let fileURL = try service.saveChunkFile(
            data: testData,
            itemId: testItemId,
            chunkIndex: chunkIndex
        )
        
        XCTAssertTrue(FileManager.default.fileExists(atPath: fileURL.path))
        
        // Verify file can be read back
        let retrievedData = try Data(contentsOf: fileURL)
        XCTAssertEqual(retrievedData, testData)
        
        // Verify correct path structure
        XCTAssertTrue(fileURL.path.contains(testItemId.uuidString))
        XCTAssertTrue(fileURL.lastPathComponent == "chunk_\(chunkIndex).mp3")
    }
    
    func testMultipleChunksSameItem() throws {
        let chunks = [
            "Chunk 1 data".data(using: .utf8)!,
            "Chunk 2 data".data(using: .utf8)!,
            "Chunk 3 data".data(using: .utf8)!
        ]
        
        var savedURLs: [URL] = []
        
        // Save multiple chunks
        for (index, data) in chunks.enumerated() {
            let url = try service.saveChunkFile(
                data: data,
                itemId: testItemId,
                chunkIndex: index
            )
            savedURLs.append(url)
        }
        
        // Verify all files exist
        for url in savedURLs {
            XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))
        }
        
        // Verify they're in the same directory
        let directories = Set(savedURLs.map { $0.deletingLastPathComponent().path })
        XCTAssertEqual(directories.count, 1)
    }
    
    func testDeleteAllChunks() throws {
        // Save some chunks first
        for i in 0..<3 {
            let data = "Chunk \(i)".data(using: .utf8)!
            _ = try service.saveChunkFile(
                data: data,
                itemId: testItemId,
                chunkIndex: i
            )
        }
        
        // Verify directory exists
        let itemDirectory = service.getItemDirectory(for: testItemId)
        XCTAssertTrue(FileManager.default.fileExists(atPath: itemDirectory.path))
        
        // Delete all chunks
        try service.deleteAllChunks(for: testItemId)
        
        // Verify directory is gone
        XCTAssertFalse(FileManager.default.fileExists(atPath: itemDirectory.path))
    }
    
    func testCalculateFileSizeForChunkedItem() throws {
        let testData = String(repeating: "a", count: 1000).data(using: .utf8)!
        
        // Save multiple chunks
        for i in 0..<3 {
            _ = try service.saveChunkFile(
                data: testData,
                itemId: testItemId,
                chunkIndex: i
            )
        }
        
        let itemDirectory = service.getItemDirectory(for: testItemId)
        let totalSize = service.calculateFileSize(at: itemDirectory.path)
        
        XCTAssertGreaterThan(totalSize, 0)
        XCTAssertGreaterThanOrEqual(totalSize, Int64(testData.count * 3))
    }
    
    // MARK: - Legacy File Tests
    
    func testSaveAndDeleteLegacyFile() throws {
        let testData = "Legacy audio data".data(using: .utf8)!
        let filename = "test_audio.mp3"
        
        let fileURL = try service.saveAudioFile(data: testData, filename: filename)
        XCTAssertTrue(FileManager.default.fileExists(atPath: fileURL.path))
        
        try service.deleteAudioFile(at: fileURL.path)
        XCTAssertFalse(FileManager.default.fileExists(atPath: fileURL.path))
    }
    
    func testTotalStorageUsed() throws {
        // Save both legacy and chunked files
        let legacyData = "Legacy".data(using: .utf8)!
        _ = try service.saveAudioFile(data: legacyData, filename: "legacy.mp3")
        
        let chunkData = "Chunk".data(using: .utf8)!
        _ = try service.saveChunkFile(
            data: chunkData,
            itemId: testItemId,
            chunkIndex: 0
        )
        
        let totalStorage = service.totalStorageUsed()
        XCTAssertGreaterThan(totalStorage, 0)
    }
    
    func testGetChunkURL() {
        let chunkIndex = 5
        let url = service.getChunkURL(itemId: testItemId, chunkIndex: chunkIndex)
        
        XCTAssertTrue(url.path.contains(testItemId.uuidString))
        XCTAssertEqual(url.lastPathComponent, "chunk_\(chunkIndex).mp3")
    }
}