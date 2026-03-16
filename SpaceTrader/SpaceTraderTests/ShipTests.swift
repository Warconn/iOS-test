import XCTest
@testable import SpaceTrader

final class ShipTests: XCTestCase {

    var ship: Ship!

    override func setUp() {
        super.setUp()
        ship = Ship()
    }

    // MARK: – Initial state

    func testInitialCredits() { XCTAssertEqual(ship.credits, 500) }
    func testInitialCargoEmpty() { XCTAssertTrue(ship.cargo.isEmpty) }
    func testInitialFuelPositive() { XCTAssertGreaterThan(ship.fuel, 0) }
    func testInitialLevelsAreOne() {
        XCTAssertEqual(ship.engineLevel,   1)
        XCTAssertEqual(ship.cargoLevel,    1)
        XCTAssertEqual(ship.scannerLevel,  1)
        XCTAssertEqual(ship.fuelTankLevel, 1)
    }
    func testInitialDockedAtStart() { XCTAssertEqual(ship.currentLocationId, "start") }

    // MARK: – Computed stats

    func testMaxSpeedLevel1() { XCTAssertEqual(ship.maxSpeed, 240) }
    func testMaxCargoLevel1() { XCTAssertEqual(ship.maxCargo, 8) }
    func testScannerRangeLevel1() { XCTAssertEqual(ship.scannerRange, 1500) }
    func testMaxFuelLevel1() { XCTAssertEqual(ship.maxFuel, 110, accuracy: 0.001) }

    func testMaxSpeedIncreasesWithEngine() {
        ship.engineLevel = 3
        XCTAssertEqual(ship.maxSpeed, 340)
    }

    func testMaxCargoIncreasesWithLevel() {
        ship.cargoLevel = 2
        XCTAssertEqual(ship.maxCargo, 12)
    }

    // MARK: – Position (posX/posY)

    func testPositionCGPoint() {
        ship.posX = 100; ship.posY = 200
        XCTAssertEqual(ship.position, CGPoint(x: 100, y: 200))
    }

    func testSetPositionViaProperty() {
        ship.position = CGPoint(x: 300, y: 400)
        XCTAssertEqual(ship.posX, 300)
        XCTAssertEqual(ship.posY, 400)
    }

    // MARK: – Cargo

    func testAddCargoNewItem() {
        ship.addCargo("ore", quantity: 3)
        XCTAssertEqual(ship.cargoQuantity(of: "ore"), 3)
        XCTAssertEqual(ship.cargoUsed, 3)
    }

    func testAddCargoStacksExisting() {
        ship.addCargo("ore", quantity: 2)
        ship.addCargo("ore", quantity: 3)
        XCTAssertEqual(ship.cargoQuantity(of: "ore"), 5)
    }

    func testAddMultipleCommodities() {
        ship.addCargo("ore", quantity: 2)
        ship.addCargo("food", quantity: 3)
        XCTAssertEqual(ship.cargoUsed, 5)
        XCTAssertEqual(ship.cargo.count, 2)
    }

    func testRemoveCargo() {
        ship.addCargo("ore", quantity: 5)
        let success = ship.removeCargo("ore", quantity: 3)
        XCTAssertTrue(success)
        XCTAssertEqual(ship.cargoQuantity(of: "ore"), 2)
    }

    func testRemoveAllCargoRemovesEntry() {
        ship.addCargo("ore", quantity: 3)
        ship.removeCargo("ore", quantity: 3)
        XCTAssertEqual(ship.cargo.count, 0)
    }

    func testRemoveMoreThanOwnedFails() {
        ship.addCargo("ore", quantity: 2)
        let success = ship.removeCargo("ore", quantity: 5)
        XCTAssertFalse(success)
        XCTAssertEqual(ship.cargoQuantity(of: "ore"), 2)  // unchanged
    }

    func testRemoveMissingItemFails() {
        let success = ship.removeCargo("nonexistent", quantity: 1)
        XCTAssertFalse(success)
    }

    func testCargoFreeDecreasesOnAdd() {
        let before = ship.cargoFree
        ship.addCargo("ore", quantity: 2)
        XCTAssertEqual(ship.cargoFree, before - 2)
    }

    func testCargoQuantityForMissingItem() {
        XCTAssertEqual(ship.cargoQuantity(of: "xyz"), 0)
    }

    // MARK: – Upgrade

    func testUpgradeEngineIncreasesLevel() {
        ship.upgrade(.engine)
        XCTAssertEqual(ship.engineLevel, 2)
    }

    func testUpgradeMaxLevelCapsAt5() {
        ship.engineLevel = 5
        ship.upgrade(.engine)
        XCTAssertEqual(ship.engineLevel, 5)
    }

    func testUpgradeFuelTankRefillsPartially() {
        ship.fuel = 50
        ship.fuelTankLevel = 1  // maxFuel = 110
        ship.upgrade(.fuelTank) // maxFuel → 140
        XCTAssertGreaterThan(ship.fuel, 50)
    }

    func testUpgradeAllTypes() {
        for type_ in ShipUpgrade.allCases {
            var s = Ship()
            s.upgrade(type_)
            XCTAssertEqual(s.upgradeLevel(for: type_), 2)
        }
    }

    func testUpgradeCostExistsForAllLevels() {
        for type_ in ShipUpgrade.allCases {
            for level in 1...4 {
                XCTAssertNotNil(type_.cost(toUpgradeFrom: level), "\(type_) level \(level) cost missing")
            }
        }
    }

    func testUpgradeCostNilAtMaxLevel() {
        for type_ in ShipUpgrade.allCases {
            XCTAssertNil(type_.cost(toUpgradeFrom: 5))
        }
    }

    func testNextLevelDescriptionNotEmpty() {
        for type_ in ShipUpgrade.allCases {
            XCTAssertFalse(ship.nextLevelDescription(for: type_).isEmpty)
        }
    }

    // MARK: – Fuel percent

    func testFuelPercentFullAtInit() {
        // fuel = 110, maxFuel = 110
        XCTAssertEqual(ship.fuelPercent, 1.0, accuracy: 0.01)
    }

    func testFuelPercentHalfway() {
        ship.fuel = ship.maxFuel / 2
        XCTAssertEqual(ship.fuelPercent, 0.5, accuracy: 0.01)
    }

    // MARK: – Codable

    func testShipCodableRoundTrip() throws {
        ship.credits = 1234
        ship.addCargo("crystals", quantity: 5)
        ship.engineLevel = 3
        let data = try JSONEncoder().encode(ship)
        let back = try JSONDecoder().decode(Ship.self, from: data)
        XCTAssertEqual(back.credits, 1234)
        XCTAssertEqual(back.cargoQuantity(of: "crystals"), 5)
        XCTAssertEqual(back.engineLevel, 3)
    }

    // MARK: – isDocked

    func testIsDockedWhenLocationSet() {
        ship.currentLocationId = "some_loc"
        XCTAssertTrue(ship.isDocked)
    }

    func testNotDockedWhenNil() {
        ship.currentLocationId = nil
        XCTAssertFalse(ship.isDocked)
    }
}
