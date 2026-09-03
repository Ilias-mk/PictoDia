// EventExtractionService.swift
import Foundation

/// Extrae una lista ordenada de eventos a partir de una frase en sueco usando un LLM.
/// Cubre RF-01, RF-03, RF-04, RF-05, RF-06, RF-07, RF-08 de spec.md.
nonisolated struct EventExtractionService {

    private let apiKey = APIConfig.anthropicKey
    private let endpoint = URL(string: "https://api.anthropic.com/v1/messages")!
    private let maxEventos = 7 // RF-07
    private let cliente: NetworkClient

    init(cliente: NetworkClient = URLSessionClient()) {
        self.cliente = cliente
    }
    
    func extraerEventos(desde frase: String) async throws -> [Evento] {
        let requestBody = AnthropicRequest(
            model: "claude-sonnet-4-6",
            maxTokens: 1024,
            messages: [AnthropicMessage(role: "user", content: construirPrompt(frase: frase))]
        )

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.httpBody = try JSONEncoder().encode(requestBody)

        let data: Data
        do {
            data = try await cliente.enviar(request)
        } catch {
            throw EventExtractionError.sinConexion // RF-06
        }
        let respuesta = try JSONDecoder().decode(AnthropicResponse.self, from: data)

        guard let textoJSON = respuesta.content.first(where: { $0.type == "text" })?.text,
              let jsonData = textoJSON.data(using: .utf8),
              let dto = try? JSONDecoder().decode(EventosExtraidosDTO.self, from: jsonData),
              !dto.eventos.isEmpty
        else {
            throw EventExtractionError.sinEventosDetectados // RF-05
        }

        let ordenados = dto.eventos
            .sorted { $0.ordenSugerido < $1.ordenSugerido } // RF-04
            .prefix(maxEventos) // RF-07 / RF-08

        return ordenados.enumerated().map { index, dto in
            Evento(orden: index, descripcion: dto.descripcion, horaAproximada: nil)
        }
    }

    private func construirPrompt(frase: String) -> String {
        """
        Analiza la siguiente frase en sueco de un cuidador describiendo el plan del \
        día de una persona con autismo. Extrae los eventos discretos y ordénalos de \
        forma lógica/cronológica aunque no se mencionen en ese orden. Responde SOLO \
        con JSON válido en este formato exacto, sin texto adicional:
        {"eventos": [{"descripcion": "...", "ordenSugerido": 0}]}

        Frase: "\(frase)"
        """
    }
}
