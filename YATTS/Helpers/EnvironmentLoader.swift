import Foundation

final class EnvironmentLoader {
    static func loadAPIKey() -> String? {
        // First check if running tests with environment variable
        if let testAPIKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY"] {
            return testAPIKey
        }
        
        // Otherwise load from .env file
        guard let projectPath = Bundle.main.path(forResource: ".env", ofType: nil) else {
            // Try to load from project root during development
            let fileManager = FileManager.default
            let currentPath = fileManager.currentDirectoryPath
            let envPath = "\(currentPath)/.env"
            
            guard fileManager.fileExists(atPath: envPath),
                  let contents = try? String(contentsOfFile: envPath) else {
                return nil
            }
            
            return parseEnvFile(contents)["OPENAI_API_KEY"]
        }
        
        guard let contents = try? String(contentsOfFile: projectPath) else {
            return nil
        }
        
        return parseEnvFile(contents)["OPENAI_API_KEY"]
    }
    
    private static func parseEnvFile(_ contents: String) -> [String: String] {
        var env = [String: String]()
        
        let lines = contents.components(separatedBy: .newlines)
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty && !trimmed.hasPrefix("#") else { continue }
            
            let parts = trimmed.components(separatedBy: "=")
            guard parts.count == 2 else { continue }
            
            let key = parts[0].trimmingCharacters(in: .whitespaces)
            let value = parts[1].trimmingCharacters(in: .whitespaces)
            env[key] = value
        }
        
        return env
    }
}