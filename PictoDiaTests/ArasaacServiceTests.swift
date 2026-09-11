import XCTest
@testable import PictoDia

/// Fake client answering differently depending on the language in the URL.
struct FakeClientByLanguage: NetworkClient {
    var swedishResponse: Data
    var englishResponse: Data

    func send(_ request: URLRequest) async throws -> Data {
        let url = request.url?.absoluteString ?? ""
        return url.contains("/sv/") ? swedishResponse : englishResponse
    }
}

final class ArasaacServiceTests: XCTestCase {

    private let emptyList = "[]".data(using: .utf8)!

    private func list(withID id: Int, keyword: String) -> Data {
        """
        [{"_id": \(id), "keywords": [{"keyword": "\(keyword)"}], "schematic": false, "aac": true}]
        """.data(using: .utf8)!
    }

    func testReturnsSwedishResults() async throws {
        let client = FakeClientByLanguage(
            swedishResponse: list(withID: 4626, keyword: "frukost"),
            englishResponse: emptyList
        )
        let service = ArasaacService(client: client)

        let result = try await service.findCandidates(for: "frukost")

        XCTAssertEqual(result.count, 1)          // RF-10
        XCTAssertEqual(result.first?.id, 4626)
    }

    func testFallsBackToEnglishWhenSwedishIsEmpty() async throws {
        let client = FakeClientByLanguage(
            swedishResponse: emptyList,
            englishResponse: list(withID: 999, keyword: "breakfast")
        )
        let service = ArasaacService(client: client)

        let result = try await service.findCandidates(for: "frukost")

        XCTAssertEqual(result.first?.id, 999)    // RF-11
    }

    func testReturnsEmptyWhenNeitherLanguageHasResults() async throws {
        let client = FakeClientByLanguage(swedishResponse: emptyList, englishResponse: emptyList)
        let service = ArasaacService(client: client)

        let result = try await service.findCandidates(for: "xyzabc")

        XCTAssertTrue(result.isEmpty)            // enables RF-13
    }

    func testThrowsNetworkFailure() async {
        let client = FakeClient(errorToThrow: URLError(.timedOut))
        let service = ArasaacService(client: client)

        do {
            _ = try await service.findCandidates(for: "frukost")
            XCTFail("Expected networkFailure")
        } catch {
            XCTAssertEqual(error as? PictogramError, .networkFailure)   // RF-14
        }
    }
}
