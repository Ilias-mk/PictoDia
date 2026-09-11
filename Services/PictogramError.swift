import Foundation

/// Errors from pictogram lookup and selection (RF-14).
nonisolated enum PictogramError: LocalizedError, Equatable {
    case networkFailure

    var errorDescription: String? {
        switch self {
        case .networkFailure:
            return "Det gick inte att ladda schemat. Kontrollera din anslutning och försök igen."
        }
    }
}
