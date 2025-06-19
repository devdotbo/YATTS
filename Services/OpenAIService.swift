import Foundation
import OpenAI

final class OpenAIService {
    private var openAI: OpenAI?
    
    func configure(with apiKey: String) {
        openAI = OpenAI(apiToken: apiKey)
    }
    
    func convertTextToSpeech(
        text: String,
        voice: String = "alloy",
        model: String = "tts-1"
    ) async throws -> Data {
        guard let openAI = openAI else {
            throw OpenAIError.missingAPIKey
        }
        
        let query = AudioSpeechQuery(
            model: model == "tts-1-hd" ? .tts_1_hd : .tts_1,
            input: text,
            voice: AudioSpeechVoice(rawValue: voice) ?? .alloy,
            responseFormat: .mp3,
            speed: 1.0
        )
        
        let result = try await openAI.audioCreateSpeech(query: query)
        return result.audio
    }
    
    func validateAPIKey(_ key: String) async -> Bool {
        configure(with: key)
        do {
            _ = try await convertTextToSpeech(
                text: "Test",
                voice: "alloy",
                model: "tts-1"
            )
            return true
        } catch {
            return false
        }
    }
}

enum OpenAIError: LocalizedError {
    case missingAPIKey
    
    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "Please configure your OpenAI API key in Settings"
        }
    }
}