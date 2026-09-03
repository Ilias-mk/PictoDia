import Foundation

/// Errores del proceso de búsqueda y selección de pictogramas (RF-14).
nonisolated enum PictogramaError: LocalizedError, Equatable {
    case falloDeRed

    var errorDescription: String? {
        switch self {
        case .falloDeRed:
            return "No se pudo cargar la agenda visual. Comprueba tu conexión e inténtalo de nuevo."
        }
    }
}
