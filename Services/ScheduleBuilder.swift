import Foundation

/// Builds the visual schedule, using the cache to avoid repeated lookups.
nonisolated struct ScheduleBuilder {

    private let arasaac: ArasaacService
    private let selection: PictogramSelectionService
    private let cache: PictogramCache

    init(arasaac: ArasaacService = ArasaacService(),
         selection: PictogramSelectionService = PictogramSelectionService(),
         cache: PictogramCache = UserDefaultsPictogramCache()) {
        self.arasaac = arasaac
        self.selection = selection
        self.cache = cache
    }

    /// Returns one pictogram per event, in order. Throws .networkFailure with no partial results (RF-14).
    func build(from events: [Event]) async throws -> [Pictogram] {

        // 1. Split cached from pending (RF-19, RF-21).
        var cached: [String: CacheResult] = [:]
        var pending: [Event] = []

        for event in events {
            if let hit = cache.get(for: event.text) {
                cached[event.text] = hit
            } else {
                pending.append(event)
            }
        }

        // 2. Look up candidates only for the pending ones (RF-21).
        var candidatesPerEvent: [(event: String, candidates: [ArasaacPictogramDTO])] = []
        for event in pending {
            let candidates = try await arasaac.findCandidates(for: event.text)
            candidatesPerEvent.append((event: event.text, candidates: candidates))
        }

        // 3. One LLM call, only if there's anything to choose from (RF-12).
        let chosen = candidatesPerEvent.isEmpty
            ? [:]
            : try await selection.choose(candidatesPerEvent: candidatesPerEvent)

        // 4. Build each event's pictogram, in order.
        return events.map { event in
            if let hit = cached[event.text] {
                return pictogram(from: hit, for: event)
            }

            let candidates = candidatesPerEvent
                .first { $0.event == event.text }?
                .candidates ?? []

            guard !candidates.isEmpty else {
                cache.save(.notFound, for: event.text)   // RF-22
                return genericPictogram(for: event)      // RF-13
            }

            let chosenID = chosen[event.text]
            let dto = candidates.first { $0.id == chosenID } ?? candidates[0]

            cache.save(.found(id: dto.id), for: event.text)   // RF-18
            return pictogram(from: .found(id: dto.id), for: event)
        }
    }

    /// Builds a pictogram from a result, cached or freshly fetched.
    private func pictogram(from result: CacheResult, for event: Event) -> Pictogram {
        switch result {
        case .notFound:
            return genericPictogram(for: event)
        case .found(let id):
            guard let url = ArasaacService.imageURL(forID: id) else {
                return genericPictogram(for: event)
            }
            return Pictogram(id: id, imageURL: url, label: event.text, isGeneric: false)
        }
    }

    /// Fallback pictogram when none is available (RF-13).
    private func genericPictogram(for event: Event) -> Pictogram {
        Pictogram(id: -event.order - 1, imageURL: nil, label: event.text, isGeneric: true)
    }
}
