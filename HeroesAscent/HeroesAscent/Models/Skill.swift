import Foundation

struct Skill: Identifiable, Codable, Equatable {
    let id: String
    let name: String
    let description: String
    let emoji: String
    let maxLevel: Int
    let unlockHeroLevel: Int
    let cooldown: TimeInterval

    var upgradeCost: (Int) -> Int { { level in (level + 1) * 150 } }

    func effectDescription(atLevel level: Int) -> String {
        guard level > 0 else { return "Not learned yet" }
        switch id {
        case SkillIDs.powerStrike:
            let pct = 100 + level * 60
            return "Deal \(pct)% ATK damage · \(Int(cooldown))s cooldown"
        case SkillIDs.heal:
            let pct = 15 + level * 10
            return "Restore \(pct)% of Max HP · \(Int(cooldown))s cooldown"
        case SkillIDs.rage:
            let dur = 3 + level
            return "2× attack speed for \(dur)s · \(Int(cooldown))s cooldown"
        default:
            return description
        }
    }

    func nextLevelDescription(atLevel currentLevel: Int) -> String? {
        guard currentLevel < maxLevel else { return nil }
        return effectDescription(atLevel: currentLevel + 1)
    }

    static let catalog: [Skill] = [
        Skill(
            id: SkillIDs.powerStrike,
            name: "Power Strike",
            description: "Channel power into a single devastating blow",
            emoji: "💥",
            maxLevel: 5,
            unlockHeroLevel: 5,
            cooldown: 8
        ),
        Skill(
            id: SkillIDs.heal,
            name: "Battle Heal",
            description: "Focus inner energy to restore health mid-combat",
            emoji: "💚",
            maxLevel: 5,
            unlockHeroLevel: 10,
            cooldown: 15
        ),
        Skill(
            id: SkillIDs.rage,
            name: "Berserker Rage",
            description: "Enter a battle frenzy that doubles attack speed",
            emoji: "😤",
            maxLevel: 5,
            unlockHeroLevel: 20,
            cooldown: 25
        ),
    ]
}

enum SkillIDs {
    static let powerStrike = "powerStrike"
    static let heal        = "heal"
    static let rage        = "rage"
}
