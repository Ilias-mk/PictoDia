import Foundation

/// Abstracción de la capa de red, para poder sustituirla en tests.
nonisolated protocol NetworkClient {
    func enviar(_ request: URLRequest) async throws -> Data
}

/// Implementación real, usada en producción.
nonisolated struct URLSessionClient: NetworkClient {
    func enviar(_ request: URLRequest) async throws -> Data {
        let (data, _) = try await URLSession.shared.data(for: request)
        return data
    }
}
//  NetworkClient.swift
//  PictoDia
//
//  Created by Ilias Mohamed on 2026-09-03.
//

