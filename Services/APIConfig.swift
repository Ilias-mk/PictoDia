import Foundation

/// Reads the API key from the build configuration (Secrets.xcconfig).
nonisolated enum APIConfig {
    static var anthropicKey: String {
        guard let key = Bundle.main.object(forInfoDictionaryKey: "ANTHROPIC_API_KEY") as? String,
              !key.isEmpty else {
            assertionFailure("Missing ANTHROPIC_API_KEY. Copy Secrets.xcconfig.example to Secrets.xcconfig and fill it in.")
            return ""
        }
        return key
    }
}
