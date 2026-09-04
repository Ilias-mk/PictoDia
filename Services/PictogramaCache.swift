import Foundation

/// Almacena y recupera el pictograma elegido para un texto de evento (RF-18, RF-19).
nonisolated protocol PictogramaCache {
    /// Devuelve el id cacheado, .noHayPictograma si se sabe que no existe, o nil si nunca se buscó.
    func obtener(para evento: String) -> ResultadoCache?
    func guardar(_ resultado: ResultadoCache, para evento: String)
}

/// Distingue "hay este pictograma" de "ya buscamos y no hay ninguno" (RF-22).
nonisolated enum ResultadoCache: Equatable {
    case encontrado(id: Int)
    case noHayPictograma
}

/// Implementación persistente sobre UserDefaults.
nonisolated struct UserDefaultsPictogramaCache: PictogramaCache {

    private let clave = "pictogramaCache"
    private let defaults: UserDefaults
    private static let marcaNegativa = -1

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    /// RF-20: minúsculas y sin espacios sobrantes, para que "Frukost" y "frukost " coincidan.
    private func normalizar(_ texto: String) -> String {
        texto.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    private var mapa: [String: Int] {
        defaults.dictionary(forKey: clave) as? [String: Int] ?? [:]
    }

    func obtener(para evento: String) -> ResultadoCache? {
        guard let valor = mapa[normalizar(evento)] else { return nil }
        return valor == Self.marcaNegativa ? .noHayPictograma : .encontrado(id: valor)
    }

    func guardar(_ resultado: ResultadoCache, para evento: String) {
        var actual = mapa
        switch resultado {
        case .encontrado(let id):
            actual[normalizar(evento)] = id
        case .noHayPictograma:
            actual[normalizar(evento)] = Self.marcaNegativa
        }
        defaults.set(actual, forKey: clave)   // RF-23: sin caducidad
    }
}//
//  PictogramaCache.swift
//  PictoDia
//
//  Created by Ilias Mohamed on 2026-09-04.
//

