import Foundation

/// Elige, mediante una única llamada al LLM, el mejor pictograma para cada evento (RF-12).
nonisolated struct PictogramaSelectionService {

    private let cliente: NetworkClient
    private let endpoint = URL(string: "https://api.anthropic.com/v1/messages")!

    init(cliente: NetworkClient = URLSessionClient()) {
        self.cliente = cliente
    }

    /// Recibe cada evento con sus candidatos y devuelve el id elegido por evento (o nil si ninguno encaja).
    func elegir(candidatosPorEvento: [(evento: String, candidatos: [ArasaacPictogramDTO])]) async throws -> [String: Int] {

        let conCandidatos = candidatosPorEvento.filter { !$0.candidatos.isEmpty }
        guard !conCandidatos.isEmpty else { return [:] }

        let requestBody = AnthropicRequest(
            model: "claude-sonnet-4-6",
            maxTokens: 1024,
            messages: [AnthropicMessage(role: "user", content: construirPrompt(conCandidatos))]
        )

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(APIConfig.anthropicKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.httpBody = try JSONEncoder().encode(requestBody)

        let data: Data
        do {
            data = try await cliente.enviar(request)
        } catch {
            throw PictogramaError.falloDeRed   // RF-14
        }

        guard let respuesta = try? JSONDecoder().decode(AnthropicResponse.self, from: data),
              let texto = respuesta.content.first(where: { $0.type == "text" })?.text,
              let jsonData = texto.data(using: .utf8),
              let selecciones = try? JSONDecoder().decode([String: Int].self, from: jsonData)
        else {
            return [:]   // Sin selección válida: cada evento caerá al primer candidato
        }

        return selecciones
    }

    private func construirPrompt(_ items: [(evento: String, candidatos: [ArasaacPictogramDTO])]) -> String {
        let bloques = items.map { item in
            let opciones = item.candidatos.map { dto in
                "  - id \(dto.id): \"\(dto.terminoPrincipal ?? "")\" (esquemático: \(dto.schematic), aac: \(dto.aac))"
            }.joined(separator: "\n")
            return "Evento: \"\(item.evento)\"\n\(opciones)"
        }.joined(separator: "\n\n")

        return """
        Para cada evento, elige el id del pictograma que mejor lo representa \
        visualmente para una persona con autismo. Prefiere pictogramas claros \
        y poco ambiguos.

        \(bloques)

        Responde SOLO con JSON válido, sin texto adicional, mapeando cada \
        evento a su id elegido:
        {"nombre del evento": 1234}
        """
    }
}//
//  PictogramaSelectionService.swift
//  PictoDia
//
//  Created by Ilias Mohamed on 2026-09-03.
//

