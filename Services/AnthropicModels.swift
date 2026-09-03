import Foundation

// MARK: - Lo que enviamos a la API de Anthropic

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

// MARK: - Lo que la API nos devuelve

nonisolated struct AnthropicResponse: Codable {
    let content: [AnthropicContentBlock]
}

nonisolated struct AnthropicContentBlock: Codable {
    let type: String
    let text: String?
}

// MARK: - El formato que le pedimos al LLM que use dentro de su respuesta de texto

nonisolated struct EventoExtraidoDTO: Codable {
    let descripcion: String
    let ordenSugerido: Int
}

nonisolated struct EventosExtraidosDTO: Codable {
    let eventos: [EventoExtraidoDTO]
}//
//  AnthropicModels.swift
//  PictoDia
//
//  Created by Ilias Mohamed on 2026-09-02.
//

