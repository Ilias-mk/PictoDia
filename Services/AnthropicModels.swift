import Foundation

// MARK: - Request

nonisolated struct AnthropicRequest: Codable {
    let model: String
    let maxTokens: Int
    let messages: [AnthropicMessage]

    enum CodingKeys: String, CodingKey {
        case model
        case maxTokens = "max_tokens"
        case messages
    }
}

nonisolated struct AnthropicMessage: Codable {
    let role: String
    let content: String
}

// MARK: - Response

nonisolated struct AnthropicResponse: Codable {
    let content: [AnthropicContentBlock]
}

nonisolated struct AnthropicContentBlock: Codable {
    let type: String
    let text: String?
}

// MARK: - The shape we ask the model to return inside its text response

nonisolated struct ExtractedEventDTO: Codable {
    let text: String
    let suggestedOrder: Int
}

nonisolated struct ExtractedEventsDTO: Codable {
    let events: [ExtractedEventDTO]
}
