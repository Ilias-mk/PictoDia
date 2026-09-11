import XCTest
@testable import PictoDia

/// Fake client returning predefined data or errors, without touching the network.
struct FakeClient: NetworkClient {
    var dataToReturn: Data?
    var errorToThrow: Error?

    func send(_ request: URLRequest) async throws -> Data {
        if let error = errorToThrow { throw error }
        return dataToReturn ?? Data()
    }
}

final class EventExtractionServiceTests: XCTestCase {

    /// Wraps a JSON payload the way the API would return it.
    private func apiResponse(withJSON json: String) -> Data {
        let escaped = json.replacingOccurrences(of: "\"", with: "\\\"")
        return """
        {"content": [{"type": "text", "text": "\(escaped)"}]}
        """.data(using: .utf8)!
    }

    func testExtractsEventsInOrder() async throws {
        let json = """
        {"events": [{"text": "Läkare", "suggestedOrder": 1}, {"text": "Frukost", "suggestedOrder": 0}]}
        """
        let client = FakeClient(dataToReturn: apiResponse(withJSON: json))
        let service = EventExtractionService(client: client)

        let events = try await service.extractEvents(from: "Vi ska till läkaren, men först frukost")

        XCTAssertEqual(events.count, 2)
        XCTAssertEqual(events[0].text, "Frukost")   // RF-04: inferred order
        XCTAssertEqual(events[1].text, "Läkare")
    }

    func testThrowsNoConnectionOnNetworkFailure() async {
        let client = FakeClient(errorToThrow: URLError(.notConnectedToInternet))
        let service = EventExtractionService(client: client)

        do {
            _ = try await service.extractEvents(from: "Frukost sedan skola")
            XCTFail("Expected noConnection")
        } catch {
            XCTAssertEqual(error as? EventExtractionError, .noConnection)   // RF-06
        }
    }

    func testThrowsNoEventsWhenListIsEmpty() async {
        let client = FakeClient(dataToReturn: apiResponse(withJSON: #"{"events": []}"#))
        let service = EventExtractionService(client: client)

        do {
            _ = try await service.extractEvents(from: "asdfgh")
            XCTFail("Expected noEventsDetected")
        } catch {
            XCTAssertEqual(error as? EventExtractionError, .noEventsDetected)   // RF-05
        }
    }

    func testCapsAtSevenEvents() async throws {
        let eventsJSON = (0..<10).map { #"{"text": "Event \#($0)", "suggestedOrder": \#($0)}"# }.joined(separator: ", ")
        let client = FakeClient(dataToReturn: apiResponse(withJSON: #"{"events": [\#(eventsJSON)]}"#))
        let service = EventExtractionService(client: client)

        let events = try await service.extractEvents(from: "En lång dag")

        XCTAssertEqual(events.count, 7)   // RF-07 / RF-08
    }
}
