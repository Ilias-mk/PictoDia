import Foundation

/// A single discrete step in the day's plan.
nonisolated struct Event: Identifiable {
    let id = UUID()
    var order: Int
    var text: String
    var approximateTime: String?
}
