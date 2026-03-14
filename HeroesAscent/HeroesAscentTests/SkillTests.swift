import XCTest
@testable import HeroesAscent

final class SkillTests: XCTestCase {

    // MARK: – Catalog
    func testSkillCatalogNotEmpty() {
        XCTAssertFalse(Skill.catalog.isEmpty)
    }

    func testAllSkillsHaveUniqueIDs() {
        let ids = Skill.catalog.map { $0.id }
        XCTAssertEqual(ids.count, Set(ids).count)
    }

    func testAllSkillsHaveNames() {
        for skill in Skill.catalog {
            XCTAssertFalse(skill.name.isEmpty)
        }
    }

    func testAllSkillsHaveEmojis() {
        for skill in Skill.catalog {
            XCTAssertFalse(skill.emoji.isEmpty)
        }
    }

    func testMaxLevelIsPositive() {
        for skill in Skill.catalog {
            XCTAssertGreaterThan(skill.maxLevel, 0)
        }
    }

    func testCooldownIsPositive() {
        for skill in Skill.catalog {
            XCTAssertGreaterThan(skill.cooldown, 0)
        }
    }

    func testUnlockLevelIsPositive() {
        for skill in Skill.catalog {
            XCTAssertGreaterThan(skill.unlockHeroLevel, 0)
        }
    }

    // MARK: – Named skills exist
    func testPowerStrikeExists() {
        XCTAssertNotNil(Skill.catalog.first { $0.id == SkillIDs.powerStrike })
    }

    func testHealExists() {
        XCTAssertNotNil(Skill.catalog.first { $0.id == SkillIDs.heal })
    }

    func testRageExists() {
        XCTAssertNotNil(Skill.catalog.first { $0.id == SkillIDs.rage })
    }

    // MARK: – Effect descriptions
    func testPowerStrikeDescriptionAtLevel1() {
        let skill = Skill.catalog.first { $0.id == SkillIDs.powerStrike }!
        let desc = skill.effectDescription(atLevel: 1)
        XCTAssertFalse(desc.isEmpty)
        XCTAssertTrue(desc.contains("ATK") || desc.contains("%"))
    }

    func testHealDescriptionAtLevel1() {
        let skill = Skill.catalog.first { $0.id == SkillIDs.heal }!
        let desc = skill.effectDescription(atLevel: 1)
        XCTAssertFalse(desc.isEmpty)
    }

    func testRageDescriptionAtLevel1() {
        let skill = Skill.catalog.first { $0.id == SkillIDs.rage }!
        let desc = skill.effectDescription(atLevel: 1)
        XCTAssertFalse(desc.isEmpty)
    }

    func testEffectDescriptionAtLevel0IsNotLearned() {
        let skill = Skill.catalog.first { $0.id == SkillIDs.powerStrike }!
        let desc = skill.effectDescription(atLevel: 0)
        XCTAssertTrue(desc.contains("Not learned"))
    }

    // MARK: – Next level description
    func testNextLevelDescriptionNilAtMaxLevel() {
        let skill = Skill.catalog.first { $0.id == SkillIDs.powerStrike }!
        let next = skill.nextLevelDescription(atLevel: skill.maxLevel)
        XCTAssertNil(next)
    }

    func testNextLevelDescriptionNotNilBelowMax() {
        let skill = Skill.catalog.first { $0.id == SkillIDs.powerStrike }!
        let next = skill.nextLevelDescription(atLevel: 0)
        XCTAssertNotNil(next)
    }

    // MARK: – Upgrade cost
    func testUpgradeCostIncreasesWithLevel() {
        let skill = Skill.catalog.first { $0.id == SkillIDs.powerStrike }!
        let cost0 = skill.upgradeCost(0)
        let cost1 = skill.upgradeCost(1)
        XCTAssertLessThan(cost0, cost1)
    }

    func testUpgradeCostIsPositive() {
        for skill in Skill.catalog {
            for level in 0..<skill.maxLevel {
                XCTAssertGreaterThan(skill.upgradeCost(level), 0)
            }
        }
    }

    // MARK: – Codable
    func testSkillCodableRoundTrip() throws {
        let skill = Skill.catalog.first!
        let data = try JSONEncoder().encode(skill)
        let decoded = try JSONDecoder().decode(Skill.self, from: data)
        XCTAssertEqual(skill.id,   decoded.id)
        XCTAssertEqual(skill.name, decoded.name)
        XCTAssertEqual(skill.maxLevel, decoded.maxLevel)
    }
}
