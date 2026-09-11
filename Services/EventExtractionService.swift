import Foundation

/// Extracts an ordered list of events from a Swedish sentence using an LLM.
/// Covers RF-01, RF-03, RF-04, RF-05, RF-06, RF-07, RF-08.
nonisolated struct EventExtractionService {

    private let client: NetworkClient
    private let endpoint = URL(string: "https://api.anthropic.com/v1/messages")!
    private let maxEvents = 7   // RF-07

    init(client: NetworkClient = URLSessionClient()) {
        self.client = client
    }

    func extractEvents(from sentence: String) async throws -> [Event] {
        let body = AnthropicRequest(
            model: "claude-sonnet-5",
            maxTokens: 1024,
            messages: [AnthropicMessage(role: "user", content: buildPrompt(sentence: sentence))]
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
            throw EventExtractionError.noConnection   // RF-06
        }

        let response = try JSONDecoder().decode(AnthropicResponse.self, from: data)

        guard let jsonText = response.content.first(where: { $0.type == "text" })?.text,
              let jsonData = jsonText.data(using: .utf8),
              let dto = try? JSONDecoder().decode(ExtractedEventsDTO.self, from: jsonData),
              !dto.events.isEmpty
        else {
            throw EventExtractionError.noEventsDetected   // RF-05
        }

        let ordered = dto.events
            .sorted { $0.suggestedOrder < $1.suggestedOrder }   // RF-04
            .prefix(maxEvents)                                  // RF-07 / RF-08

        return ordered.enumerated().map { index, dto in
            Event(order: index, text: dto.text, approximateTime: nil)
        }
    }

    private func buildPrompt(sentence: String) -> String {
        """
        Analyze the following Swedish sentence, in which a caregiver describes \
        the day's plan for a person with autism. Extract the discrete events and \
        order them logically and chronologically, even if they are not mentioned \
        in that order.

        Each description must be one or two words at most: the simplest possible \
        term, with no time or place modifiers. For example, from "gå till läkaren \
        på eftermiddagen" the correct description is "läkare", not the full phrase.

        Reply ONLY with valid JSON in exactly this format, with no extra text:
        {"events": [{"text": "...", "suggestedOrder": 0}]}

        Sentence: "\(sentence)"
        """
    }
}
