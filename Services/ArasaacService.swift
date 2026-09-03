import Foundation

/// Busca pictogramas en ARASAAC para un término, con fallback de idioma (RF-09, RF-10, RF-11).
nonisolated struct ArasaacService {

    private let cliente: NetworkClient
    private let baseURL = "https://api.arasaac.org/api/pictograms"

    init(cliente: NetworkClient = URLSessionClient()) {
        self.cliente = cliente
    }

    /// Construye la URL de imagen de un pictograma a partir de su id.
    static func urlImagen(paraID id: Int) -> URL? {
        URL(string: "https://static.arasaac.org/pictograms/\(id)/\(id)_300.png")
    }

    /// Busca candidatos primero en sueco; si no hay resultados, reintenta en inglés.
    func buscarCandidatos(para termino: String) async throws -> [ArasaacPictogramDTO] {
        let enSueco = try await buscar(termino: termino, idioma: "sv")   // RF-10
        if !enSueco.isEmpty { return enSueco }
        return try await buscar(termino: termino, idioma: "en")          // RF-11
    }

    private func buscar(termino: String, idioma: String) async throws -> [ArasaacPictogramDTO] {
        guard let codificado = termino.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed),
              let url = URL(string: "\(baseURL)/\(idioma)/search/\(codificado)")
        else {
            return []
        }

        let data: Data
        do {
            data = try await cliente.enviar(URLRequest(url: url))
        } catch {
            throw PictogramaError.falloDeRed   // RF-14
        }

        // Una búsqueda sin resultados puede devolver un cuerpo no decodificable:
        // se trata como lista vacía, no como error.
        return (try? JSONDecoder().decode([ArasaacPictogramDTO].self, from: data)) ?? []
    }
}//
//  ArasaacService.swift
//  PictoDia
//
//  Created by Ilias Mohamed on 2026-09-03.
//

