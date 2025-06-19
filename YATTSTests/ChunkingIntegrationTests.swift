import XCTest
import SwiftData
@testable import YATTS

final class ChunkingIntegrationTests: XCTestCase {
    var modelContainer: ModelContainer!
    var context: ModelContext!
    var viewModel: AddItemViewModel!
    
    override func setUp() async throws {
        try await super.setUp()
        
        // Create in-memory model container for testing
        let schema = Schema([
            AudioItem.self,
            AudioChunk.self,
            Settings.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        modelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
        context = ModelContext(modelContainer)
        
        await MainActor.run {
            viewModel = AddItemViewModel()
        }
    }
    
    override func tearDown() {
        viewModel = nil
        context = nil
        modelContainer = nil
        super.tearDown()
    }
    
    // MARK: - Full Flow Tests
    
    func testGenerateSingleChunkAudio() async throws {
        guard let apiKey = EnvironmentLoader.loadAPIKey(), !apiKey.isEmpty else {
            throw XCTSkip("No API key available for testing")
        }
        
        // Create settings
        let settings = Settings(openAIAPIKey: apiKey)
        context.insert(settings)
        try context.save()
        
        // Set short text
        await MainActor.run {
            viewModel.text = "This is a short test text for audio generation."
        }
        
        // Generate audio
        await viewModel.generateAudio(settings: settings, context: context)
        
        // Verify audio item was created
        let descriptor = FetchDescriptor<AudioItem>()
        let items = try context.fetch(descriptor)
        
        XCTAssertEqual(items.count, 1)
        let item = items[0]
        
        XCTAssertFalse(item.isChunked)
        XCTAssertEqual(item.chunks.count, 0)
        XCTAssertGreaterThan(item.fileSize, 0)
        XCTAssertTrue(FileManager.default.fileExists(atPath: item.audioFilePath))
    }
    
    func testGenerateChunkedAudio() async throws {
        guard let apiKey = EnvironmentLoader.loadAPIKey(), !apiKey.isEmpty else {
            throw XCTSkip("No API key available for testing")
        }
        
        // Create settings
        let settings = Settings(openAIAPIKey: apiKey)
        context.insert(settings)
        try context.save()
        
        // Create long text (>4096 chars)
        let longText = """
        The history of artificial intelligence (AI) began in antiquity, with myths, stories and rumors of artificial beings endowed with intelligence or consciousness by master craftsmen. The seeds of modern AI were planted by philosophers who attempted to describe the process of human thinking as the mechanical manipulation of symbols. This work culminated in the invention of the programmable digital computer in the 1940s, a machine based on the abstract essence of mathematical reasoning. This device and the ideas behind it inspired a handful of scientists to begin seriously discussing the possibility of building an electronic brain.
        
        The field of AI research was founded at a workshop held on the campus of Dartmouth College, USA during the summer of 1956. Those who attended would become the leaders of AI research for decades. Many of them predicted that a machine as intelligent as a human being would exist in no more than a generation, and they were given millions of dollars to make this vision come true.
        
        Eventually, it became obvious that commercial developers and researchers had grossly underestimated the difficulty of the project. In 1974, in response to the criticism from James Lighthill and ongoing pressure from congress, the U.S. and British governments stopped funding undirected research into artificial intelligence, and the difficult years that followed would later be known as an "AI winter". Seven years later, a visionary initiative by the Japanese Government inspired governments and industry to provide AI with billions of dollars, but by the late 1980s the investors became disillusioned and withdrew funding again.
        
        Investment and interest in AI boomed in the first decades of the 21st century when machine learning was successfully applied to many problems in academia and industry due to new methods, the application of powerful computer hardware, and the collection of immense data sets. By 2022, artificial intelligence technology was widespread, used in everyday applications such as speech recognition on mobile phones, recommendation systems on streaming services, and advanced driver assistance systems in automobiles.
        
        """ + String(repeating: "This is additional text to make the content longer and test the chunking functionality properly. ", count: 50)
        
        await MainActor.run {
            viewModel.text = longText
        }
        
        // Verify character count shows chunks
        let characterCount = await MainActor.run { viewModel.characterCount }
        XCTAssertTrue(characterCount.contains("chunks"))
        
        // Generate audio
        await viewModel.generateAudio(settings: settings, context: context)
        
        // Wait for processing to complete
        while await viewModel.isProcessing {
            try await Task.sleep(nanoseconds: 100_000_000) // 0.1 second
        }
        
        // Verify audio item was created with chunks
        let descriptor = FetchDescriptor<AudioItem>()
        let items = try context.fetch(descriptor)
        
        XCTAssertEqual(items.count, 1)
        let item = items[0]
        
        XCTAssertTrue(item.isChunked)
        XCTAssertGreaterThan(item.chunks.count, 1)
        XCTAssertEqual(item.totalChunks, item.chunks.count)
        XCTAssertEqual(item.downloadedChunks, item.chunks.count)
        XCTAssertTrue(item.isFullyDownloaded)
        
        // Verify all chunk files exist
        for chunk in item.chunks {
            XCTAssertTrue(FileManager.default.fileExists(atPath: chunk.audioFilePath))
            XCTAssertTrue(chunk.isDownloaded)
            XCTAssertGreaterThan(chunk.duration, 0)
        }
        
        // Verify chunks are ordered correctly
        let sortedChunks = item.chunks.sorted { $0.index < $1.index }
        for (index, chunk) in sortedChunks.enumerated() {
            XCTAssertEqual(chunk.index, index)
        }
    }
    
    func testProgressTracking() async throws {
        guard let apiKey = EnvironmentLoader.loadAPIKey(), !apiKey.isEmpty else {
            throw XCTSkip("No API key available for testing")
        }
        
        let settings = Settings(openAIAPIKey: apiKey)
        context.insert(settings)
        try context.save()
        
        // Create text that will result in exactly 2 chunks
        let text1 = String(repeating: "First chunk content. ", count: 180) // ~3600 chars
        let text2 = String(repeating: "Second chunk content. ", count: 180) // ~3800 chars
        let twoChunkText = text1 + text2
        
        await MainActor.run {
            viewModel.text = twoChunkText
        }
        
        var progressUpdates: [Double] = []
        var chunkUpdates: [(current: Int, total: Int)] = []
        
        // Start observing progress
        let progressTask = Task {
            while await viewModel.isProcessing {
                let progress = await viewModel.downloadProgress
                let current = await viewModel.currentChunk
                let total = await viewModel.totalChunks
                
                progressUpdates.append(progress)
                if current > 0 && total > 0 {
                    chunkUpdates.append((current, total))
                }
                
                try await Task.sleep(nanoseconds: 50_000_000) // 0.05 second
            }
        }
        
        // Generate audio
        await viewModel.generateAudio(settings: settings, context: context)
        
        // Wait for completion
        await progressTask.value
        
        // Verify progress was tracked
        XCTAssertGreaterThan(progressUpdates.count, 0)
        XCTAssertGreaterThan(chunkUpdates.count, 0)
        
        // Verify chunk updates were sequential
        for (index, update) in chunkUpdates.enumerated() {
            if index > 0 {
                XCTAssertGreaterThanOrEqual(update.current, chunkUpdates[index - 1].current)
            }
        }
    }
}