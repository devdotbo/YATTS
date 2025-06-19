import Foundation
import SwiftData

@Model
final class Settings {
    var openAIAPIKey: String
    var selectedVoice: String
    var selectedModel: String
    
    init(
        openAIAPIKey: String = "",
        selectedVoice: String = "alloy",
        selectedModel: String = "tts-1"
    ) {
        self.openAIAPIKey = openAIAPIKey
        self.selectedVoice = selectedVoice
        self.selectedModel = selectedModel
    }
    
    static var supportedVoices: [String] {
        ["alloy", "echo", "fable", "onyx", "nova", "shimmer"]
    }
    
    static var supportedModels: [String] {
        ["tts-1", "tts-1-hd"]
    }
}