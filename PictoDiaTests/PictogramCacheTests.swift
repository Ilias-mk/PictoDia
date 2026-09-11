import XCTest
@testable import PictoDia

final class PictogramCacheTests: XCTestCase {

    /// Isolated UserDefaults, so the app's real ones are never touched.
    private var defaults: UserDefaults!
    private var cache: UserDefaultsPictogramCache!

    override func setUp() {
        super.setUp()
        let name = "test-\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: name)!
        cache = UserDefaultsPictogramCache(defaults: defaults)
    }

    func testReturnsNilWhenNeverLookedUp() {
        XCTAssertNil(cache.get(for: "frukost"))
    }

    func testSavesAndRetrievesAnID() {
        cache.save(.found(id: 4626), for: "frukost")

        XCTAssertEqual(cache.get(for: "frukost"), .found(id: 4626))   // RF-18
    }

    func testNormalizesCaseAndWhitespace() {
        cache.save(.found(id: 4626), for: "frukost")

        XCTAssertEqual(cache.get(for: "  FRUKOST "), .found(id: 4626))   // RF-20
    }

    func testSavesNegativeResult() {
        cache.save(.notFound, for: "xyzabc")

        XCTAssertEqual(cache.get(for: "xyzabc"), .notFound)   // RF-22
    }

    func testDistinguishesNotFoundFromNeverLookedUp() {
        cache.save(.notFound, for: "xyzabc")

        XCTAssertNotNil(cache.get(for: "xyzabc"))     // cached
        XCTAssertNil(cache.get(for: "something"))     // never looked up
    }

    func testPersistsAcrossInstances() {
        cache.save(.found(id: 999), for: "skola")

        let another = UserDefaultsPictogramCache(defaults: defaults)

        XCTAssertEqual(another.get(for: "skola"), .found(id: 999))   // RF-23
    }
}
