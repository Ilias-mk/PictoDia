import Foundation

/// A schedule the caregiver saved for reuse.
nonisolated struct SavedSchedule: Identifiable, Codable {
    let id: UUID
    var name: String
    let savedAt: Date
    let pictograms: [Pictogram]

    init(name: String, pictograms: [Pictogram]) {
        self.id = UUID()
        self.name = name
        self.savedAt = Date()
        self.pictograms = pictograms
    }
}
