import Foundation

/// Persists saved schedules as JSON in a local file (RF-35, RF-36).
nonisolated struct ScheduleStore {

    static let maxSchedules = 20   // RF-38

    private let url: URL

    init(directory: URL? = nil) {
        let folder = directory ?? FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        self.url = folder.appendingPathComponent("schedules.json")
    }

    /// Returns all saved schedules, newest first.
    func loadAll() -> [SavedSchedule] {
        guard let data = try? Data(contentsOf: url),
              let schedules = try? JSONDecoder().decode([SavedSchedule].self, from: data)
        else {
            return []
        }
        return schedules.sorted { $0.savedAt > $1.savedAt }
    }

    /// True when a schedule with that name already exists (RF-34).
    func nameExists(_ name: String) -> Bool {
        let normalized = name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return loadAll().contains {
            $0.name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == normalized
        }
    }

    /// True when the limit is reached and the name doesn't already exist (RF-39).
    func limitReached(for name: String) -> Bool {
        loadAll().count >= Self.maxSchedules && !nameExists(name)
    }

    /// Saves a schedule, replacing any with the same name (RF-34).
    func save(_ schedule: SavedSchedule) {
        let normalized = schedule.name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        var current = loadAll().filter {
            $0.name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() != normalized
        }
        current.append(schedule)
        write(current)
    }

    /// Deletes a schedule by id (RF-37).
    func delete(id: UUID) {
        write(loadAll().filter { $0.id != id })
    }

    private func write(_ schedules: [SavedSchedule]) {
        guard let data = try? JSONEncoder().encode(schedules) else { return }
        try? data.write(to: url, options: .atomic)
    }
}
