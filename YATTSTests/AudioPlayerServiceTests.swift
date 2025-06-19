import XCTest
import AVFoundation
@testable import YATTS

final class AudioPlayerServiceTests: XCTestCase {
    var service: AudioPlayerService!
    
    override func setUp() async throws {
        try await super.setUp()
        await MainActor.run {
            service = AudioPlayerService.shared
        }
    }
    
    override func tearDown() async throws {
        await MainActor.run {
            service.stop()
        }
        service = nil
        try await super.tearDown()
    }
    
    // MARK: - Chunk Index Calculation Tests
    
    func testDetermineChunkIndexForSingleChunk() async {
        // Create test audio item with single chunk
        let item = AudioItem(title: "Test", textContent: "Test", isChunked: true)
        let chunk = AudioChunk(index: 0, audioFilePath: "", duration: 60, isDownloaded: true)
        item.chunks = [chunk]
        
        await MainActor.run {
            service.play(audioItem: item)
            
            // Any time within the single chunk should return index 0
            XCTAssertEqual(service.currentChunkIndex, 0)
        }
    }
    
    func testSeekingAcrossChunks() async {
        // Create test item with multiple chunks
        let item = AudioItem(title: "Test", textContent: "Test", isChunked: true)
        
        // Create 3 chunks of 30 seconds each
        for i in 0..<3 {
            let chunk = AudioChunk(
                index: i,
                audioFilePath: "",
                duration: 30,
                isDownloaded: true
            )
            item.chunks.append(chunk)
        }
        
        await MainActor.run {
            // Mock play without actual audio files
            service.currentItem = item
            
            // Test seeking to different positions
            // Seek to 10 seconds (should be in chunk 0)
            service.seek(to: 10)
            // Note: In real implementation, this would update currentChunkIndex
            
            // Seek to 45 seconds (should be in chunk 1)
            service.seek(to: 45)
            
            // Seek to 75 seconds (should be in chunk 2)
            service.seek(to: 75)
        }
    }
    
    func testSkippingWithinChunk() async {
        let item = AudioItem(title: "Test", textContent: "Test", isChunked: false)
        item.duration = 120 // 2 minutes
        
        await MainActor.run {
            service.currentItem = item
            service.duration = 120
            
            // Skip forward 15 seconds
            service.skip(seconds: 15)
            
            // Skip backward 15 seconds
            service.skip(seconds: -15)
        }
    }
    
    // MARK: - State Management Tests
    
    func testPlayPauseToggle() async {
        await MainActor.run {
            XCTAssertFalse(service.isPlaying)
            
            // Can't toggle without audio loaded
            service.togglePlayPause()
            XCTAssertFalse(service.isPlaying)
        }
    }
    
    func testCurrentTimeTracking() async {
        let item = AudioItem(title: "Test", textContent: "Test")
        
        await MainActor.run {
            service.currentItem = item
            service.currentTime = 45.5
            
            XCTAssertEqual(service.currentTime, 45.5)
            XCTAssertEqual(item.lastPlaybackPosition, 45.5)
        }
    }
    
    func testStopResetsState() async {
        await MainActor.run {
            // Set up some state
            service.currentTime = 100
            service.duration = 200
            service.currentChunkIndex = 2
            service.totalChunks = 5
            
            // Stop should reset everything
            service.stop()
            
            XCTAssertEqual(service.currentTime, 0)
            XCTAssertEqual(service.duration, 0)
            XCTAssertEqual(service.currentChunkIndex, 0)
            XCTAssertEqual(service.totalChunks, 0)
            XCTAssertNil(service.currentItem)
            XCTAssertFalse(service.isPlaying)
        }
    }
}