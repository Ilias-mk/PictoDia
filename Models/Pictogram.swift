import Foundation

/// A pictogram paired with the event it represents.
nonisolated struct Pictogram: Identifiable, Codable {
    let id: Int              // ARASAAC pictogram id
    let imageURL: URL?       // nil when showing the generic fallback icon
    let label: String
    let isGeneric: Bool      // RF-13: true when no pictogram was found
}
