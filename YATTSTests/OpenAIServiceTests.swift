import XCTest
@testable import YATTS

final class OpenAIServiceTests: XCTestCase {
    var service: OpenAIService!
    
    override func setUp() {
        super.setUp()
        service = OpenAIService()
    }
    
    override func tearDown() {
        service = nil
        super.tearDown()
    }
    
    // MARK: - Text Chunking Tests
    
    func testSingleChunkForShortText() {
        let shortText = "This is a short text that should fit in a single chunk."
        let chunks = service.splitTextIntoChunks(shortText)
        
        XCTAssertEqual(chunks.count, 1)
        XCTAssertEqual(chunks[0].text, shortText)
        XCTAssertEqual(chunks[0].index, 0)
    }
    
    func testMultipleChunksForLongText() {
        // Create a text longer than 4096 characters
        let sentence = "This is a test sentence that will be repeated many times. "
        let longText = String(repeating: sentence, count: 100) // ~5700 characters
        
        let chunks = service.splitTextIntoChunks(longText)
        
        XCTAssertGreaterThan(chunks.count, 1)
        
        // Verify each chunk is within limits
        for chunk in chunks {
            XCTAssertLessThanOrEqual(chunk.text.count, OpenAIService.maxCharacterLimit)
        }
        
        // Verify chunks are indexed correctly
        for (index, chunk) in chunks.enumerated() {
            XCTAssertEqual(chunk.index, index)
        }
    }
    
    func testChunkOverlap() {
        // Create text with distinct sentences
        let sentences = (1...100).map { "Sentence number \($0). " }
        let longText = sentences.joined()
        
        let chunks = service.splitTextIntoChunks(longText)
        
        if chunks.count > 1 {
            // Check that second chunk contains overlap from first
            let firstChunkLastSentence = chunks[0].text
                .components(separatedBy: ". ")
                .filter { !$0.isEmpty }
                .last ?? ""
            
            XCTAssertTrue(chunks[1].text.contains(firstChunkLastSentence))
        }
    }
    
    func testEmptyText() {
        let chunks = service.splitTextIntoChunks("")
        XCTAssertEqual(chunks.count, 1)
        XCTAssertEqual(chunks[0].text, "")
    }
    
    func testTextExactlyAtLimit() {
        let text = String(repeating: "a", count: OpenAIService.maxCharacterLimit)
        let chunks = service.splitTextIntoChunks(text)
        
        XCTAssertEqual(chunks.count, 1)
        XCTAssertEqual(chunks[0].text.count, OpenAIService.maxCharacterLimit)
    }
    
    // MARK: - API Tests (Integration)
    
    func testConvertTextToSpeechWithValidAPIKey() async throws {
        // Skip if no API key available
        guard let apiKey = EnvironmentLoader.loadAPIKey(), !apiKey.isEmpty else {
            throw XCTSkip("No API key available for testing")
        }
        
        service.configure(with: apiKey)
        
        let testText = "Hello, this is a test."
        let data = try await service.convertTextToSpeech(
            text: testText,
            voice: "alloy",
            model: "tts-1"
        )
        
        XCTAssertGreaterThan(data.count, 0)
    }
    
    func testConvertChunkToSpeech() async throws {
        guard let apiKey = EnvironmentLoader.loadAPIKey(), !apiKey.isEmpty else {
            throw XCTSkip("No API key available for testing")
        }
        
        service.configure(with: apiKey)
        
        let chunk = OpenAIService.TextChunk(text: "This is chunk number one.", index: 0)
        let data = try await service.convertChunkToSpeech(chunk: chunk)
        
        XCTAssertGreaterThan(data.count, 0)
    }
    
    func testAPIKeyValidation() async throws {
        guard let apiKey = EnvironmentLoader.loadAPIKey(), !apiKey.isEmpty else {
            throw XCTSkip("No API key available for testing")
        }
        
        // Test valid key
        let isValid = await service.validateAPIKey(apiKey)
        XCTAssertTrue(isValid)
        
        // Test invalid key
        let isInvalid = await service.validateAPIKey("invalid-key")
        XCTAssertFalse(isInvalid)
    }
    
    func testTextTooLongError() async {
        service.configure(with: "test-key")
        
        let longText = String(repeating: "a", count: OpenAIService.maxCharacterLimit + 1)
        
        do {
            _ = try await service.convertTextToSpeech(text: longText)
            XCTFail("Should have thrown error for text too long")
        } catch let error as OpenAIError {
            if case .textTooLong = error {
                // Expected error
            } else {
                XCTFail("Wrong error type: \(error)")
            }
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
}