import Foundation

/// Picks the best pictogram for each event in a single LLM call (RF-12).
nonisolated struct PictogramSelectionService {

    private let client: NetworkClient
    private let endpoint = URL(string: "https://api.anthropic.com/v1/messages")!

    init(client: NetworkClient = URLSessionClient()) {
        self.client = client
    }

    /// Takes each event with its candidates and returns the chosen id per event.
    func choose(candidatesPerEvent: [(event: String, candidates: [ArasaacPictogramDTO])]) async throws -> [String: Int] {

        let withCandidates = candidatesPerEvent.filter { !$0.candidates.isEmpty }
        guard !withCandidates.isEmpty else { return [:] }

        let body = AnthropicRequest(
            model: "claude-sonnet-5",
            maxTokens: 1024,
            messages: [AnthropicMessage(role: "user", content: buildPrompt(withCandidates))]
        )

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(APIConfig.anthropicKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.httpBody = try JSONEncoder().encode(body)

        let data: Data
        do {
            data = try await client.send(request)
        } catch {
            throw PictogramError.networkFailure   // RF-14
        }

        guard let response = try? JSONDecoder().decode(AnthropicResponse.self, from: data),
              let text = response.content.first(where: { $0.type == "text" })?.text,
              let jsonData = text.data(using: .utf8),
              let selections = try? JSONDecoder().decode([String: Int].self, from: jsonData)
        else {
            return [:]   // No valid selection: each event falls back to its first candidate
        }

        return selections
    }

    private func buildPrompt(_ items: [(event: String, candidates: [ArasaacPictogramDTO])]) -> String {
        let blocks = items.map { item in
            let options = item.candidates.map { dto in
                "  - id \(dto.id): \"\(dto.primaryTerm ?? "")\" (schematic: \(dto.schematic), aac: \(dto.aac))"
            }.joined(separator: "\n")
            return "Event: \"\(item.event)\"\n\(options)"
        }.joined(separator: "\n\n")

        return """
        For each event, choose the id of the pictogram that best represents it \
        visually for a person with autism. Prefer clear, unambiguous pictograms.

        \(blocks)

        Reply ONLY with valid JSON, no extra text, mapping each event to its \
        chosen id:
        {"event name": 1234}
        """
    }
}
