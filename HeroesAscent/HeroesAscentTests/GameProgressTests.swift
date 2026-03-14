import XCTest
@testable import HeroesAscent

final class GameProgressTests: XCTestCase {

    var progress: GameProgress!

    override func setUp() {
        super.setUp()
        progress = GameProgress()
    }

    // MARK: – Initial state
    func testInitialZone() {
        XCTAssertEqual(progress.currentZone, 1)
    }

    func testInitialKills() {
        XCTAssertEqual(progress.enemiesKilledInZone, 0)
        XCTAssertEqual(progress.totalKills, 0)
    }

    func testInitialAutoAttackDisabled() {
        XCTAssertFalse(progress.autoAttackEnabled)
    }

    func testInitialHighestZone() {
        XCTAssertEqual(progress.highestZone, 1)
    }

    // MARK: – Next enemy index
    func testNextEnemyIndexStartsAtOne() {
        XCTAssertEqual(progress.nextEnemyIndex, 1)
    }

    func testNextEnemyIndexAfterKill() {
        progress.enemiesKilledInZone = 1
        XCTAssertEqual(progress.nextEnemyIndex, 2)
    }

    func testNextEnemyIndexTenIsBoss() {
        progress.enemiesKilledInZone = 9
        XCTAssertEqual(progress.nextEnemyIndex, 10)
    }

    func testIsNextEnemyBoss() {
        progress.enemiesKilledInZone = 9
        XCTAssertTrue(progress.isNextEnemyBoss)
    }

    func testIsNextEnemyNotBoss() {
        progress.enemiesKilledInZone = 0
        XCTAssertFalse(progress.isNextEnemyBoss)
        progress.enemiesKilledInZone = 8
        XCTAssertFalse(progress.isNextEnemyBoss)
    }

    func testEnemyIndexWrapsAfterBoss() {
        progress.enemiesKilledInZone = 10 // after killing boss, reset to 0 in game logic
        progress.enemiesKilledInZone = 0
        XCTAssertEqual(progress.nextEnemyIndex, 1)
    }

    // MARK: – Codable round-trip
    func testGameProgressCodable() throws {
        progress.currentZone = 3
        progress.totalKills = 42
        progress.autoAttackEnabled = true
        let data = try JSONEncoder().encode(progress)
        let decoded = try JSONDecoder().decode(GameProgress.self, from: data)
        XCTAssertEqual(decoded.currentZone, 3)
        XCTAssertEqual(decoded.totalKills, 42)
        XCTAssertTrue(decoded.autoAttackEnabled)
    }

    // MARK: – StatType
    func testStatTypeCaseIterable() {
        XCTAssertEqual(StatType.allCases.count, 3)
    }

    func testStatTypeDisplayNames() {
        for stat in StatType.allCases {
            XCTAssertFalse(stat.rawValue.isEmpty)
            XCTAssertFalse(stat.icon.isEmpty)
            XCTAssertFalse(stat.description.isEmpty)
        }
    }

    func testStatTypeCodable() throws {
        let stat = StatType.attack
        let data = try JSONEncoder().encode(stat)
        let decoded = try JSONDecoder().decode(StatType.self, from: data)
        XCTAssertEqual(stat, decoded)
    }
}
