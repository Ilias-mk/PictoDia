import Foundation

/// Errors from the event extraction process (RF-05, RF-06).
nonisolated enum EventExtractionError: LocalizedError, Equatable {
    case noConnection
    case noEventsDetected

    var errorDescription: String? {
        switch self {
        case .noConnection:
            return "Ingen internetanslutning. Försök igen när du har täckning."
        case .noEventsDetected:
            return "Jag kunde inte hitta några händelser i den meningen. Kan du formulera om den?"
        }
    }
}
