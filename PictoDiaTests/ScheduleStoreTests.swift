import XCTest
@testable import PictoDia

final class ScheduleStoreTests: XCTestCase {

    private var directory: URL!
    private var store: ScheduleStore!

    override func setUp() {
        super.setUp()
        directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        store = ScheduleStore(directory: directory)
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: directory)
        super.tearDown()
    }

    private func schedule(_ name: String) -> SavedSchedule {
        SavedSchedule(
            name: name,
            pictograms: [
                Pictogram(id: 4626, imageURL: URL(string: "https://example.com/a.png"), label: "Frukost", isGeneric: false)
            ]
        )
    }

    func testStartsEmpty() {
        XCTAssertTrue(store.loadAll().isEmpty)
    }

    func testSavesAndLoads() {
        store.save(schedule("Skoldag"))

        let all = store.loadAll()
        XCTAssertEqual(all.count, 1)
        XCTAssertEqual(all.first?.name, "Skoldag")
        XCTAssertEqual(all.first?.pictograms.first?.id, 4626)   // RF-36
    }

    func testDetectsDuplicateName() {
        store.save(schedule("Skoldag"))

        XCTAssertTrue(store.nameExists("skoldag "))   // RF-34, normalized
        XCTAssertFalse(store.nameExists("Helgdag"))
    }

    func testOverwritesInsteadOfDuplicating() {
        store.save(schedule("Skoldag"))
        store.save(schedule("Skoldag"))

        XCTAssertEqual(store.loadAll().count, 1)   // RF-34
    }

    func testDeletesByID() {
        let first = schedule("Skoldag")
        store.save(first)
        store.save(schedule("Helgdag"))

        store.delete(id: first.id)

        let all = store.loadAll()
        XCTAssertEqual(all.count, 1)               // RF-37
        XCTAssertEqual(all.first?.name, "Helgdag")
    }

    func testDetectsLimitReached() {
        for i in 0..<ScheduleStore.maxSchedules {
            store.save(schedule("Schema \(i)"))
        }

        XCTAssertTrue(store.limitReached(for: "Nytt schema"))   // RF-39
        XCTAssertFalse(store.limitReached(for: "Schema 0"))     // overwriting is still allowed
    }

    func testPersistsAcrossInstances() {
        store.save(schedule("Skoldag"))

        let another = ScheduleStore(directory: directory)

        XCTAssertEqual(another.loadAll().count, 1)
    }
}
