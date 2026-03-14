import XCTest
@testable import SpaceTrader

final class UniverseTests: XCTestCase {

    var locations: [Location]!

    override func setUp() {
        super.setUp()
        locations = Universe.generate()
    }

    // MARK: – Count & structure

    func testGeneratesCorrectCount() {
        XCTAssertEqual(locations.count, Universe.locationCount)
    }

    func testFirstLocationIsStartingHub() {
        let start = locations.first { $0.id == "start" }
        XCTAssertNotNil(start)
        XCTAssertEqual(start?.type, .tradingHub)
    }

    func testStartIsNearCenter() {
        let start = locations.first { $0.id == "start" }!
        let center = Universe.size / 2
        XCTAssertEqual(start.posX, center, accuracy: 1)
        XCTAssertEqual(start.posY, center, accuracy: 1)
    }

    func testStartIsDiscovered() {
        let start = locations.first { $0.id == "start" }!
        XCTAssertTrue(start.isDiscovered)
    }

    func testAllOtherLocationsUndiscovered() {
        let others = locations.filter { $0.id != "start" }
        XCTAssertTrue(others.allSatisfy { !$0.isDiscovered })
    }

    func testAllIDsUnique() {
        let ids = locations.map { $0.id }
        XCTAssertEqual(ids.count, Set(ids).count)
    }

    // MARK: – Positions

    func testAllPositionsWithinBounds() {
        for loc in locations {
            XCTAssertGreaterThanOrEqual(loc.posX, 0)
            XCTAssertLessThanOrEqual(loc.posX, Universe.size)
            XCTAssertGreaterThanOrEqual(loc.posY, 0)
            XCTAssertLessThanOrEqual(loc.posY, Universe.size)
        }
    }

    func testMinimumSpacingRespected() {
        for i in 0..<locations.count {
            for j in (i+1)..<locations.count {
                let dist = locations[i].position.distance(to: locations[j].position)
                XCTAssertGreaterThanOrEqual(dist, Universe.minimumSpacing - 1,
                    "Locations \(i) and \(j) too close: \(dist)")
            }
        }
    }

    // MARK: – Names

    func testAllNamesNonEmpty() {
        for loc in locations { XCTAssertFalse(loc.name.isEmpty, "Location \(loc.id) has empty name") }
    }

    func testNamesAreUnique() {
        let names = locations.map { $0.name }
        // Allow up to 5% collisions in random generation
        let uniqueCount = Set(names).count
        XCTAssertGreaterThan(uniqueCount, locations.count - 5)
    }

    // MARK: – Types

    func testAllDefinedTypesUsed() {
        let usedTypes = Set(locations.map { $0.type })
        // At 75 locations, all 7 types should appear
        for type_ in LocationType.allCases {
            XCTAssertTrue(usedTypes.contains(type_), "No location of type \(type_) generated")
        }
    }

    // MARK: – Markets

    func testAllLocationsHaveMarkets() {
        for loc in locations {
            XCTAssertFalse(loc.market.isEmpty, "Location \(loc.id) has empty market")
        }
    }

    func testAllMarketsHaveAllCommodities() {
        for loc in locations {
            XCTAssertEqual(loc.market.count, Commodity.catalog.count,
                           "Location \(loc.id) market incomplete")
        }
    }

    func testAllMarketPricesPositive() {
        for loc in locations {
            for listing in loc.market {
                XCTAssertGreaterThan(listing.buyPrice, 0)
                XCTAssertGreaterThan(listing.sellPrice, 0)
            }
        }
    }

    // MARK: – Determinism

    func testGenerationIsDeterministic() {
        let second = Universe.generate()
        XCTAssertEqual(locations.count, second.count)
        for (a, b) in zip(locations, second) {
            XCTAssertEqual(a.id,   b.id)
            XCTAssertEqual(a.posX, b.posX, accuracy: 0.01)
            XCTAssertEqual(a.posY, b.posY, accuracy: 0.01)
            XCTAssertEqual(a.name, b.name)
        }
    }

    // MARK: – SeededRandom

    func testSeededRandomIsDeterministic() {
        var r1 = SeededRandom(seed: 12345)
        var r2 = SeededRandom(seed: 12345)
        for _ in 0..<100 {
            XCTAssertEqual(r1.nextDouble(), r2.nextDouble())
        }
    }

    func testSeededRandomRangeInBounds() {
        var rng = SeededRandom(seed: 999)
        for _ in 0..<1000 {
            let v = rng.nextInt(in: 0..<10)
            XCTAssertGreaterThanOrEqual(v, 0)
            XCTAssertLessThan(v, 10)
        }
    }

    func testSeededRandomDoubleInZeroOne() {
        var rng = SeededRandom(seed: 42)
        for _ in 0..<1000 {
            let v = rng.nextDouble()
            XCTAssertGreaterThanOrEqual(v, 0)
            XCTAssertLessThanOrEqual(v, 1)
        }
    }

    // MARK: – CGPoint distance

    func testCGPointDistance() {
        let a = CGPoint(x: 0, y: 0)
        let b = CGPoint(x: 3, y: 4)
        XCTAssertEqual(a.distance(to: b), 5, accuracy: 0.001)
    }

    func testCGPointMagnitude() {
        let p = CGPoint(x: 3, y: 4)
        XCTAssertEqual(p.magnitude, 5, accuracy: 0.001)
    }

    func testLocationsNearFilter() {
        let center = CGPoint(x: Universe.size / 2, y: Universe.size / 2)
        let near   = Universe.locationsNear(center, range: 500, in: locations)
        XCTAssertFalse(near.isEmpty)
        for loc in near {
            XCTAssertLessThanOrEqual(loc.position.distance(to: center), 500)
        }
    }
}
