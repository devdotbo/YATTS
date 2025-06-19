import Foundation
import SwiftData
import SwiftUI
import AVFoundation

@MainActor
final class AddItemViewModel: ObservableObject {
    @Published var text = ""
    @Published var isProcessing = false
    @Published var errorMessage: String?
    @Published var showError = false
    @Published var processingMessage = ""
    @Published var currentChunk = 0
    @Published var totalChunks = 0
    @Published var downloadProgress: Double = 0.0
    
    private let openAIService = OpenAIService()
    private let fileService = FileStorageService.shared
    
    var canGenerate: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && 
        !isProcessing
    }
    
    var characterCount: String {
        let count = text.count
        if count > OpenAIService.maxCharacterLimit {
            let chunks = openAIService.splitTextIntoChunks(text).count
            return "\(count) characters (\(chunks) chunks)"
        } else {
            return "\(count) characters"
        }
    }
    
    var isOverLimit: Bool {
        false // We can now handle any length with chunking
    }
    
    func generateTitle(from text: String) -> String {
        let lines = text.components(separatedBy: .newlines)
        let firstLine = lines.first?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        
        if !firstLine.isEmpty {
            return String(firstLine.prefix(50))
        } else {
            let words = text.split(separator: " ").prefix(5).joined(separator: " ")
            return words.isEmpty ? "Untitled Audio" : String(words.prefix(50))
        }
    }
    
    func generateAudio(settings: Settings, context: ModelContext) async {
        guard canGenerate else { return }
        
        isProcessing = true
        errorMessage = nil
        processingMessage = "Analyzing text..."
        
        // Load API key from environment if not set in settings
        var apiKey = settings.openAIAPIKey
        if apiKey.isEmpty, let envKey = EnvironmentLoader.loadAPIKey() {
            apiKey = envKey
            settings.openAIAPIKey = envKey
            try? context.save()
        }
        
        guard !apiKey.isEmpty else {
            errorMessage = "Please configure your OpenAI API key in Settings"
            showError = true
            isProcessing = false
            return
        }
        
        openAIService.configure(with: apiKey)
        
        // Split text into chunks
        let chunks = openAIService.splitTextIntoChunks(text)
        totalChunks = chunks.count
        
        if chunks.count == 1 {
            // Single chunk - use legacy approach
            await generateSingleAudio(text: text, settings: settings, context: context)
        } else {
            // Multiple chunks
            await generateChunkedAudio(chunks: chunks, settings: settings, context: context)
        }
    }
    
    private func generateSingleAudio(text: String, settings: Settings, context: ModelContext) async {
        processingMessage = "Generating audio..."
        
        do {
            let audioData = try await openAIService.convertTextToSpeech(
                text: text,
                voice: settings.selectedVoice,
                model: settings.selectedModel
            )
            
            let filename = "\(UUID().uuidString).mp3"
            let fileURL = try fileService.saveAudioFile(data: audioData, filename: filename)
            let fileSize = fileService.calculateFileSize(at: fileURL.path)
            
            let audioItem = AudioItem(
                title: generateTitle(from: text),
                textContent: text,
                audioFilePath: fileURL.path,
                fileSize: fileSize,
                isChunked: false
            )
            
            context.insert(audioItem)
            try context.save()
            
            text = ""
            processingMessage = ""
            isProcessing = false
        } catch {
            errorMessage = error.localizedDescription
            showError = true
            isProcessing = false
        }
    }
    
    private func generateChunkedAudio(chunks: [OpenAIService.TextChunk], settings: Settings, context: ModelContext) async {
        processingMessage = "Creating \(chunks.count) audio chunks..."
        
        // Create the audio item first
        let audioItem = AudioItem(
            title: generateTitle(from: text),
            textContent: text,
            isChunked: true
        )
        audioItem.totalChunks = chunks.count
        
        context.insert(audioItem)
        
        do {
            try context.save()
            
            // Process each chunk
            for (index, chunk) in chunks.enumerated() {
                currentChunk = index + 1
                processingMessage = "Generating chunk \(currentChunk) of \(totalChunks)..."
                downloadProgress = Double(index) / Double(chunks.count)
                
                do {
                    // Generate audio for chunk
                    let audioData = try await openAIService.convertChunkToSpeech(
                        chunk: chunk,
                        voice: settings.selectedVoice,
                        model: settings.selectedModel
                    )
                    
                    // Save chunk file
                    let fileURL = try fileService.saveChunkFile(
                        data: audioData,
                        itemId: audioItem.id,
                        chunkIndex: chunk.index
                    )
                    
                    // Create chunk model
                    let audioChunk = AudioChunk(
                        index: chunk.index,
                        audioFilePath: fileURL.path,
                        isDownloaded: true,
                        textContent: chunk.text
                    )
                    
                    // Get duration by creating temporary player
                    if let player = try? AVAudioPlayer(contentsOf: fileURL) {
                        audioChunk.duration = player.duration
                    }
                    
                    audioChunk.audioItem = audioItem
                    audioItem.chunks.append(audioChunk)
                    
                    // Update progress
                    audioItem.updateChunkProgress()
                    try context.save()
                    
                } catch {
                    print("Failed to generate chunk \(index): \(error)")
                    // Continue with other chunks even if one fails
                }
            }
            
            // Final update
            audioItem.updateChunkProgress()
            audioItem.duration = audioItem.totalDuration
            try context.save()
            
            text = ""
            processingMessage = ""
            currentChunk = 0
            totalChunks = 0
            downloadProgress = 0
            isProcessing = false
            
        } catch {
            errorMessage = error.localizedDescription
            showError = true
            isProcessing = false
            
            // Clean up partial data
            context.delete(audioItem)
            try? context.save()
        }
    }
}