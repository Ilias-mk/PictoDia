import Foundation

/// Stores and retrieves the pictogram chosen for an event text (RF-18, RF-19).
nonisolated protocol PictogramCache {
    /// Returns the cached id, .notFound when we know none exists, or nil when never looked up.
    func get(for event: String) -> CacheResult?
    func save(_ result: CacheResult, for event: String)
}

/// Distinguishes "this pictogram" from "we already looked and there is none" (RF-22).
nonisolated enum CacheResult: Equatable {
    case found(id: Int)
    case notFound
}

/// Persistent implementation backed by UserDefaults.
nonisolated struct UserDefaultsPictogramCache: PictogramCache {

    private let key = "pictogramCache"
    private let defaults: UserDefaults
    private static let notFoundMarker = -1

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    /// RF-20: lowercase and trimmed, so "Frukost" and "frukost " match.
    private func normalize(_ text: String) -> String {
        text.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    private var map: [String: Int] {
        defaults.dictionary(forKey: key) as? [String: Int] ?? [:]
    }

    func get(for event: String) -> CacheResult? {
        guard let value = map[normalize(event)] else { return nil }
        return value == Self.notFoundMarker ? .notFound : .found(id: value)
    }

    func save(_ result: CacheResult, for event: String) {
        var current = map
        switch result {
        case .found(let id):
            current[normalize(event)] = id
        case .notFound:
            current[normalize(event)] = Self.notFoundMarker
        }
        defaults.set(current, forKey: key)   // RF-23: no expiry
    }
}
