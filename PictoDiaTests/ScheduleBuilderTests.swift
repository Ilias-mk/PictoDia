import XCTest
@testable import PictoDia

/// Fake client answering based on the request host.
struct FakeMixedClient: NetworkClient {
    var arasaacResponse: Data
    var llmResponse: Data
    var arasaacError: Error?

    func send(_ request: URLRequest) async throws -> Data {
        let url = request.url?.absoluteString ?? ""
        if url.contains("arasaac") {
            if let error = arasaacError { throw error }
            return arasaacResponse
        }
        return llmResponse
    }
}

/// In-memory cache that also counts writes, to verify it is being used.
final class FakeCache: PictogramCache {
    private var map: [String: CacheResult] = [:]
    private(set) var writes = 0

    init(initial: [String: CacheResult] = [:]) {
        self.map = initial
    }

    func get(for event: String) -> CacheResult? {
        map[event.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()]
    }

    func save(_ result: CacheResult, for event: String) {
        map[event.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()] = result
        writes += 1
    }
}

final class ScheduleBuilderTests: XCTestCase {

    private let events = [Event(order: 0, text: "Frukost", approximateTime: nil)]

    private func llmResponse(_ json: String) -> Data {
        let escaped = json.replacingOccurrences(of: "\"", with: "\\\"")
        return #"{"content": [{"type": "text", "text": "\#(escaped)"}]}"#.data(using: .utf8)!
    }

    private let twoCandidates = """
    [{"_id": 4626, "keywords": [{"keyword": "frukost"}], "schematic": false, "aac": true},
     {"_id": 7012, "keywords": [{"keyword": "frukost"}], "schematic": true, "aac": false}]
    """.data(using: .utf8)!

    func testUsesTheIDChosenByTheLLM() async throws {
        let client = FakeMixedClient(
            arasaacResponse: twoCandidates,
            llmResponse: llmResponse(#"{"Frukost": 7012}"#)
        )
        let builder = ScheduleBuilder(
            arasaac: ArasaacService(client: client),
            selection: PictogramSelectionService(client: client),
            cache: FakeCache()
        )

        let pictograms = try await builder.build(from: events)

        XCTAssertEqual(pictograms[0].id, 7012)   // RF-12
        XCTAssertFalse(pictograms[0].isGeneric)
    }

    func testUsesGenericWhenThereAreNoCandidates() async throws {
        let client = FakeMixedClient(
            arasaacResponse: "[]".data(using: .utf8)!,
            llmResponse: llmResponse("{}")
        )
        let builder = ScheduleBuilder(
            arasaac: ArasaacService(client: client),
            selection: PictogramSelectionService(client: client),
            cache: FakeCache()
        )

        let pictograms = try await builder.build(from: events)

        XCTAssertTrue(pictograms[0].isGeneric)   // RF-13
        XCTAssertNil(pictograms[0].imageURL)
    }

    func testThrowsNetworkFailureWithoutPartialResults() async {
        let client = FakeMixedClient(
            arasaacResponse: Data(),
            llmResponse: Data(),
            arasaacError: URLError(.notConnectedToInternet)
        )
        let builder = ScheduleBuilder(
            arasaac: ArasaacService(client: client),
            selection: PictogramSelectionService(client: client),
            cache: FakeCache()
        )

        do {
            _ = try await builder.build(from: events)
            XCTFail("Expected networkFailure")
        } catch {
            XCTAssertEqual(error as? PictogramError, .networkFailure)   // RF-14
        }
    }

    /// A cached event must not touch the network at all.
    func testUsesCacheWithoutHittingTheNetwork() async throws {
        let failingClient = FakeMixedClient(
            arasaacResponse: Data(),
            llmResponse: Data(),
            arasaacError: URLError(.notConnectedToInternet)
        )
        let cache = FakeCache(initial: ["frukost": .found(id: 4626)])
        let builder = ScheduleBuilder(
            arasaac: ArasaacService(client: failingClient),
            selection: PictogramSelectionService(client: failingClient),
            cache: cache
        )

        let pictograms = try await builder.build(from: events)

        XCTAssertEqual(pictograms[0].id, 4626)   // RF-19
        XCTAssertEqual(cache.writes, 0)
    }

    /// With mixed events, only the uncached ones are looked up.
    func testOnlyLooksUpUncachedEvents() async throws {
        let client = FakeMixedClient(
            arasaacResponse: twoCandidates,
            llmResponse: llmResponse(#"{"Skola": 4626}"#)
        )
        let cache = FakeCache(initial: ["frukost": .found(id: 111)])
        let builder = ScheduleBuilder(
            arasaac: ArasaacService(client: client),
            selection: PictogramSelectionService(client: client),
            cache: cache
        )

        let mixed = [
            Event(order: 0, text: "Frukost", approximateTime: nil),
            Event(order: 1, text: "Skola", approximateTime: nil)
        ]
        let pictograms = try await builder.build(from: mixed)

        XCTAssertEqual(pictograms[0].id, 111)    // from cache
        XCTAssertEqual(pictograms[1].id, 4626)   // from the network
        XCTAssertEqual(cache.writes, 1)          // RF-21
    }
}
