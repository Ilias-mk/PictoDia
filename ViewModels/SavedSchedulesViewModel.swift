import Foundation

/// Manages the list of saved schedules (RF-35, RF-37).
@MainActor
@Observable
final class SavedSchedulesViewModel {

    private(set) var schedules: [SavedSchedule] = []

    private let store: ScheduleStore

    init(store: ScheduleStore = ScheduleStore()) {
        self.store = store
    }

    /// Reloads the list from disk.
    func load() {
        schedules = store.loadAll()
    }

    /// Deletes the schedules at the given positions and reloads (RF-37).
    func delete(at indices: IndexSet) {
        for index in indices {
            store.delete(id: schedules[index].id)
        }
        load()
    }
}
