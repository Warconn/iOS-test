import XCTest
@testable import HeroesAscent

final class EnemyTests: XCTestCase {

    // MARK: – Generation
    func testEnemyGenerationBasicZone1() {
        let enemy = Enemy.generate(zone: 1, enemyIndex: 1)
        XCTAssertFalse(enemy.isDead)
        XCTAssertGreaterThan(enemy.maxHP, 0)
        XCTAssertGreaterThan(enemy.attack, 0)
        XCTAssertGreaterThanOrEqual(enemy.defense, 0)
        XCTAssertGreaterThan(enemy.experienceReward, 0)
        XCTAssertGreaterThan(enemy.goldReward, 0)
        XCTAssertFalse(enemy.isBoss)
    }

    func testEnemyIndexTenIsBoss() {
        let enemy = Enemy.generate(zone: 1, enemyIndex: 10)
        XCTAssertTrue(enemy.isBoss)
    }

    func testNonTenIndexIsNotBoss() {
        for index in [1, 2, 3, 5, 7, 9] {
            let enemy = Enemy.generate(zone: 1, enemyIndex: index)
            XCTAssertFalse(enemy.isBoss, "Enemy at index \(index) should not be boss")
        }
    }

    func testBossHasMoreHPThanRegular() {
        let regular = Enemy.generate(zone: 1, enemyIndex: 1)
        let boss    = Enemy.generate(zone: 1, enemyIndex: 10)
        XCTAssertGreaterThan(boss.maxHP, regular.maxHP)
    }

    func testBossHasMoreRewardsThanRegular() {
        let regular = Enemy.generate(zone: 1, enemyIndex: 1)
        let boss    = Enemy.generate(zone: 1, enemyIndex: 10)
        XCTAssertGreaterThan(boss.experienceReward, regular.experienceReward)
        XCTAssertGreaterThan(boss.goldReward, regular.goldReward)
    }

    func testHigherZoneEnemiesAreStronger() {
        let zone1 = Enemy.generate(zone: 1, enemyIndex: 1)
        let zone3 = Enemy.generate(zone: 3, enemyIndex: 1)
        XCTAssertGreaterThan(zone3.maxHP, zone1.maxHP)
        XCTAssertGreaterThan(zone3.attack, zone1.attack)
    }

    func testHigherZoneEnemiesGiveMoreRewards() {
        let zone1 = Enemy.generate(zone: 1, enemyIndex: 1)
        let zone3 = Enemy.generate(zone: 3, enemyIndex: 1)
        XCTAssertGreaterThan(zone3.experienceReward, zone1.experienceReward)
        XCTAssertGreaterThan(zone3.goldReward, zone1.goldReward)
    }

    func testEnemyHasEmojiAndName() {
        let enemy = Enemy.generate(zone: 1, enemyIndex: 1)
        XCTAssertFalse(enemy.name.isEmpty)
        XCTAssertFalse(enemy.emoji.isEmpty)
    }

    func testAllZonesGenerateEnemies() {
        for zone in 1...6 {
            for index in [1, 5, 10] {
                let enemy = Enemy.generate(zone: zone, enemyIndex: index)
                XCTAssertGreaterThan(enemy.maxHP, 0)
                XCTAssertFalse(enemy.name.isEmpty)
            }
        }
    }

    // MARK: – Damage
    func testTakeDamageReducesHP() {
        var enemy = Enemy.generate(zone: 1, enemyIndex: 1)
        let initial = enemy.currentHP
        enemy.takeDamage(10)
        XCTAssertLessThan(enemy.currentHP, initial)
    }

    func testTakeDamageMinimumIsOne() {
        var enemy = Enemy.generate(zone: 1, enemyIndex: 1)
        enemy.defense = 1000 // huge defense
        let initial = enemy.currentHP
        let actual = enemy.takeDamage(1)
        XCTAssertEqual(actual, 1)
        XCTAssertEqual(enemy.currentHP, initial - 1)
    }

    func testEnemyDiesWhenHPReachesZero() {
        var enemy = Enemy.generate(zone: 1, enemyIndex: 1)
        enemy.takeDamage(999999)
        XCTAssertTrue(enemy.isDead)
        XCTAssertEqual(enemy.currentHP, 0)
    }

    func testCurrentHPDoesNotGoBelowZero() {
        var enemy = Enemy.generate(zone: 1, enemyIndex: 1)
        enemy.takeDamage(999999)
        XCTAssertGreaterThanOrEqual(enemy.currentHP, 0)
    }

    func testHPPercentFullWhenUndamaged() {
        let enemy = Enemy.generate(zone: 1, enemyIndex: 1)
        XCTAssertEqual(enemy.hpPercent, 1.0, accuracy: 0.001)
    }

    func testHPPercentDecreasesAfterDamage() {
        var enemy = Enemy.generate(zone: 1, enemyIndex: 1)
        enemy.takeDamage(enemy.maxHP / 2)
        XCTAssertLessThan(enemy.hpPercent, 1.0)
    }

    func testHPPercentZeroWhenDead() {
        var enemy = Enemy.generate(zone: 1, enemyIndex: 1)
        enemy.currentHP = 0
        XCTAssertEqual(enemy.hpPercent, 0.0, accuracy: 0.001)
    }

    // MARK: – Zone data
    func testZoneDataZone1HasCorrectName() {
        let data = ZoneData.forZone(1)
        XCTAssertEqual(data.zoneName, "Verdant Forest")
    }

    func testZoneDataZone1HasEnemies() {
        let data = ZoneData.forZone(1)
        XCTAssertFalse(data.enemyNames.isEmpty)
        XCTAssertFalse(data.enemyEmojis.isEmpty)
        XCTAssertFalse(data.bossName.isEmpty)
        XCTAssertFalse(data.bossEmoji.isEmpty)
    }

    func testZoneDataBeyondDefinedReturnsDefault() {
        let data = ZoneData.forZone(99)
        XCTAssertFalse(data.zoneName.isEmpty)
        XCTAssertFalse(data.enemyNames.isEmpty)
    }
}
