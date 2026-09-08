import Foundation

/// Errores del dictado por voz (RF-30, RF-31).
nonisolated enum SpeechRecognitionError: LocalizedError, Equatable {
    case permisoDenegado
    case suecoNoDisponible
    case falloDeReconocimiento

    var errorDescription: String? {
        switch self {
        case .permisoDenegado:
            return "PictoDia necesita acceso al micrófono y al reconocimiento de voz. Puedes activarlos en Ajustes."
        case .suecoNoDisponible:
            return "El reconocimiento de voz en sueco no está disponible en este dispositivo."
        case .falloDeReconocimiento:
            return "No se pudo procesar el audio. Inténtalo de nuevo."
        }
    }

    /// Solo el permiso denegado justifica ofrecer un enlace a Ajustes (RF-30).
    var ofreceAjustes: Bool {
        self == .permisoDenegado
    }
}
