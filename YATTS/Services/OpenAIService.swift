import Foundation

final class OpenAIService {
    private var apiKey: String?
    private let baseURL = "https://api.openai.com/v1/audio/speech"
    
    func configure(with apiKey: String) {
        self.apiKey = apiKey
    }
    
    func convertTextToSpeech(
        text: String,
        voice: String = "alloy",
        model: String = "tts-1"
    ) async throws -> Data {
        guard let apiKey = apiKey, !apiKey.isEmpty else {
            throw OpenAIError.missingAPIKey
        }
        
        guard let url = URL(string: baseURL) else {
            throw OpenAIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "model": model,
            "input": text,
            "voice": voice,
            "response_format": "mp3",
            "speed": 1.0
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw OpenAIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw OpenAIError.httpError(statusCode: httpResponse.statusCode)
        }
        
        return data
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
    case invalidURL
    case invalidResponse
    case httpError(statusCode: Int)
    
    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "Please configure your OpenAI API key in Settings"
        case .invalidURL:
            return "Invalid API URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .httpError(let statusCode):
            return "HTTP error: \(statusCode)"
        }
    }
}