import Foundation

final class OpenAIService {
    private var apiKey: String?
    private let baseURL = "https://api.openai.com/v1/audio/speech"
    static let maxCharacterLimit = 4096
    
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
        
        guard text.count <= Self.maxCharacterLimit else {
            throw OpenAIError.textTooLong(limit: Self.maxCharacterLimit, actual: text.count)
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
            if let errorData = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let error = errorData["error"] as? [String: Any],
               let message = error["message"] as? String {
                throw OpenAIError.apiError(message: message, statusCode: httpResponse.statusCode)
            }
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
    case textTooLong(limit: Int, actual: Int)
    case apiError(message: String, statusCode: Int)
    
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
        case .textTooLong(let limit, let actual):
            return "Text is too long: \(actual) characters (limit: \(limit) characters)"
        case .apiError(let message, let statusCode):
            return "API Error (\(statusCode)): \(message)"
        }
    }
}