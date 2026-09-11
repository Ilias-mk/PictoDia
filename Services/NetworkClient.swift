import Foundation

/// Network layer abstraction, so it can be swapped out in tests.
nonisolated protocol NetworkClient {
    func send(_ request: URLRequest) async throws -> Data
}

/// Real implementation, used in production.
nonisolated struct URLSessionClient: NetworkClient {
    func send(_ request: URLRequest) async throws -> Data {
        let (data, _) = try await URLSession.shared.data(for: request)
        return data
    }
}
