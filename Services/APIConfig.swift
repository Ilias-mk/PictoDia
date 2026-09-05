import Foundation

/// Lee la API key desde la configuración de compilación (Secrets.xcconfig).
nonisolated enum APIConfig {
    static var anthropicKey: String {
        guard let key = Bundle.main.object(forInfoDictionaryKey: "ANTHROPIC_API_KEY") as? String,
              !key.isEmpty else {
            assertionFailure("Falta ANTHROPIC_API_KEY. Copia Secrets.xcconfig.example a Secrets.xcconfig y rellénala.")
            return ""
        }
        return key
    }
}
