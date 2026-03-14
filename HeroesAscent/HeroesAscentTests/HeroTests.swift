import XCTest
@testable import HeroesAscent

final class HeroTests: XCTestCase {

    var hero: Hero!

    override func setUp() {
        super.setUp()
        hero = Hero()
    }

    // MARK: – Initial state
    func testInitialStats() {
        XCTAssertEqual(hero.level, 1)
        XCTAssertEqual(hero.experience, 0)
        XCTAssertEqual(hero.experienceToNextLevel, 100)
        XCTAssertEqual(hero.currentHP, 100)
        XCTAssertEqual(hero.maxHP, 100)
        XCTAssertEqual(hero.baseAttack, 10)
        XCTAssertEqual(hero.baseDefense, 5)
        XCTAssertEqual(hero.statPoints, 0)
        XCTAssertFalse(hero.isDead)
    }

    func testInitialGoldIsPositive() {
        XCTAssertGreaterThan(hero.gold, 0)
    }

    // MARK: – Experience & leveling
    func testGainExperienceNoLevelUp() {
        let leveled = hero.gainExperience(50)
        XCTAssertFalse(leveled)
        XCTAssertEqual(hero.experience, 50)
        XCTAssertEqual(hero.level, 1)
    }

    func testGainExperienceCausesLevelUp() {
        let leveled = hero.gainExperience(100)
        XCTAssertTrue(leveled)
        XCTAssertEqual(hero.level, 2)
        XCTAssertGreaterThan(hero.statPoints, 0)
    }

    func testExperienceCarriesOverAfterLevelUp() {
        _ = hero.gainExperience(150)
        XCTAssertEqual(hero.experience, 50)
        XCTAssertEqual(hero.level, 2)
    }

    func testExperienceToNextLevelIncreasesAfterLevelUp() {
        let before = hero.experienceToNextLevel
        _ = hero.gainExperience(100)
        XCTAssertGreaterThan(hero.experienceToNextLevel, before)
    }

    func testStatPointsAwardedOnLevelUp() {
        _ = hero.gainExperience(1000)
        XCTAssertGreaterThan(hero.statPoints, 0)
    }

    func testBaseStatsIncreaseOnLevelUp() {
        let atkBefore = hero.baseAttack
        let defBefore = hero.baseDefense
        _ = hero.gainExperience(100)
        XCTAssertGreaterThan(hero.baseAttack, atkBefore)
        XCTAssertGreaterThan(hero.baseDefense, defBefore)
    }

    func testMaxHPIncreasesOnLevelUp() {
        let hpBefore = hero.maxHP
        _ = hero.gainExperience(100)
        XCTAssertGreaterThan(hero.maxHP, hpBefore)
    }

    func testMultipleLevelUps() {
        // Gain enough XP for several level ups
        for _ in 0..<10 {
            _ = hero.gainExperience(10000)
        }
        XCTAssertGreaterThan(hero.level, 1)
    }

    // MARK: – Damage
    func testTakeDamageReducesHP() {
        hero.takeDamage(20)
        XCTAssertLessThan(hero.currentHP, 100)
    }

    func testTakeDamageIsReducedByDefense() {
        let before = hero.currentHP
        let actual = hero.takeDamage(10) // defense = 5, so reduced = 5
        XCTAssertEqual(actual, 5)
        XCTAssertEqual(hero.currentHP, before - 5)
    }

    func testTakeDamageMinimumIsOne() {
        // If attack < defense, still deal 1
        let actual = hero.takeDamage(1) // defense 5 > 1 → min 1
        XCTAssertEqual(actual, 1)
    }

    func testHeroDeathWhenHPReachesZero() {
        hero.takeDamage(10000)
        XCTAssertTrue(hero.isDead)
        XCTAssertEqual(hero.currentHP, 0)
    }

    func testHPDoesNotGoBelowZero() {
        hero.takeDamage(10000)
        XCTAssertGreaterThanOrEqual(hero.currentHP, 0)
    }

    // MARK: – Healing
    func testHealRestoresHP() {
        hero.takeDamage(50)
        let hpAfterDamage = hero.currentHP
        hero.heal(20)
        XCTAssertGreaterThan(hero.currentHP, hpAfterDamage)
    }

    func testHealDoesNotExceedMaxHP() {
        hero.heal(9999)
        XCTAssertEqual(hero.currentHP, hero.maxHP)
    }

    func testHealExactlyToMax() {
        hero.takeDamage(30)
        hero.heal(30)
        XCTAssertEqual(hero.currentHP, hero.maxHP)
    }

    // MARK: – Stat allocation
    func testAllocateAttackStat() {
        hero.statPoints = 1
        let before = hero.baseAttack
        hero.allocateStat(.attack)
        XCTAssertEqual(hero.baseAttack, before + 3)
        XCTAssertEqual(hero.statPoints, 0)
    }

    func testAllocateDefenseStat() {
        hero.statPoints = 1
        let before = hero.baseDefense
        hero.allocateStat(.defense)
        XCTAssertEqual(hero.baseDefense, before + 2)
        XCTAssertEqual(hero.statPoints, 0)
    }

    func testAllocateHPStat() {
        hero.statPoints = 1
        let before = hero.maxHP
        hero.allocateStat(.hp)
        XCTAssertEqual(hero.maxHP, before + 25)
        XCTAssertEqual(hero.statPoints, 0)
    }

    func testCannotAllocateWithNoStatPoints() {
        hero.statPoints = 0
        let before = hero.baseAttack
        hero.allocateStat(.attack)
        XCTAssertEqual(hero.baseAttack, before)
    }

    // MARK: – Total stats with bonuses
    func testTotalAttackIncludesBonus() {
        hero.attackBonus = 15
        XCTAssertEqual(hero.totalAttack, hero.baseAttack + 15)
    }

    func testTotalDefenseIncludesBonus() {
        hero.defenseBonus = 10
        XCTAssertEqual(hero.totalDefense, hero.baseDefense + 10)
    }

    // MARK: – Experience percent
    func testExperiencePercentStartsAtZero() {
        XCTAssertEqual(hero.experiencePercent, 0.0, accuracy: 0.001)
    }

    func testExperiencePercentHalfway() {
        _ = hero.gainExperience(50)
        XCTAssertEqual(hero.experiencePercent, 0.5, accuracy: 0.001)
    }

    // MARK: – HP percent
    func testHPPercentFull() {
        XCTAssertEqual(hero.hpPercent, 1.0, accuracy: 0.001)
    }

    func testHPPercentHalfway() {
        hero.takeDamage(hero.maxHP / 2 + hero.totalDefense) // account for defense
        XCTAssertLessThan(hero.hpPercent, 1.0)
    }
}
