import Foundation

/// Looks up ARASAAC pictograms for a term, with language fallback (RF-09, RF-10, RF-11).
nonisolated struct ArasaacService {

    private let client: NetworkClient
    private let baseURL = "https://api.arasaac.org/api/pictograms"

    init(client: NetworkClient = URLSessionClient()) {
        self.client = client
    }

    /// Builds the image URL for a pictogram id.
    static func imageURL(forID id: Int) -> URL? {
        URL(string: "https://static.arasaac.org/pictograms/\(id)/\(id)_300.png")
    }

    /// Searches Swedish first; falls back to English when there are no results.
    func findCandidates(for term: String) async throws -> [ArasaacPictogramDTO] {
        let inSwedish = try await search(term: term, language: "sv")   // RF-10
        if !inSwedish.isEmpty { return inSwedish }
        return try await search(term: term, language: "en")            // RF-11
    }

    private func search(term: String, language: String) async throws -> [ArasaacPictogramDTO] {
        guard let encoded = term.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed),
              let url = URL(string: "\(baseURL)/\(language)/search/\(encoded)")
        else {
            return []
        }

        let data: Data
        do {
            data = try await client.send(URLRequest(url: url))
        } catch {
            throw PictogramError.networkFailure   // RF-14
        }

        // A search with no results may return a body that doesn't decode:
        // treat that as an empty list, not an error.
        return (try? JSONDecoder().decode([ArasaacPictogramDTO].self, from: data)) ?? []
    }
}
