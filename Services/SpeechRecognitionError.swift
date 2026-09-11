import Foundation

/// Errors from voice dictation (RF-30, RF-31).
nonisolated enum SpeechRecognitionError: LocalizedError, Equatable {
    case permissionDenied
    case swedishUnavailable
    case recognitionFailed

    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "PictoDia behöver tillgång till mikrofonen och taligenkänning. Du kan aktivera det i Inställningar."
        case .swedishUnavailable:
            return "Taligenkänning på svenska är inte tillgänglig på den här enheten."
        case .recognitionFailed:
            return "Det gick inte att tolka ljudet. Försök igen."
        }
    }

    /// Only a denied permission is worth offering a Settings shortcut for (RF-30).
    var offersSettings: Bool {
        self == .permissionDenied
    }
}
