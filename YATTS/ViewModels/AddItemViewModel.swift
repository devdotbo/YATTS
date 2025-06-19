import Foundation
import SwiftData
import SwiftUI

@MainActor
final class AddItemViewModel: ObservableObject {
    @Published var text = ""
    @Published var isProcessing = false
    @Published var errorMessage: String?
    @Published var showError = false
    
    private let openAIService = OpenAIService()
    private let fileService = FileStorageService.shared
    
    var canGenerate: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isProcessing
    }
    
    var characterCount: String {
        "\(text.count) characters"
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
        
        do {
            openAIService.configure(with: settings.openAIAPIKey)
            
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
                fileSize: fileSize
            )
            
            context.insert(audioItem)
            try context.save()
            
            text = ""
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
        
        isProcessing = false
    }
}