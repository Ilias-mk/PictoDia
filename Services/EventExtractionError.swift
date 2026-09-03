import Foundation

/// Errores que puede producir el proceso de extracción de eventos (RF-05, RF-06).
nonisolated enum EventExtractionError: LocalizedError, Equatable {
    case sinConexion
    case sinEventosDetectados

    var errorDescription: String? {
        switch self {
        case .sinConexion:
            return "Sin conexión a internet. Inténtalo de nuevo cuando tengas señal."
        case .sinEventosDetectados:
            return "No pude identificar ningún evento en esa frase. ¿Puedes reformularla?"
        }
    }
}//
//  EventExtractionError.swift
//  PictoDia
//
//  Created by Ilias Mohamed on 2026-09-02.
//

