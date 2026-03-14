import Foundation

struct Enemy: Codable, Identifiable {
    var id: UUID = UUID()
    var name: String
    var level: Int
    var maxHP: Int
    var currentHP: Int
    var attack: Int
    var defense: Int
    var experienceReward: Int
    var goldReward: Int
    var isBoss: Bool = false
    var emoji: String
    var zoneName: String

    var hpPercent: Double {
        guard maxHP > 0 else { return 0 }
        return Double(currentHP) / Double(maxHP)
    }

    var isDead: Bool { currentHP <= 0 }

    /// Returns actual damage dealt to the enemy.
    @discardableResult
    mutating func takeDamage(_ rawDamage: Int) -> Int {
        let reduced = max(1, rawDamage - defense)
        currentHP = max(0, currentHP - reduced)
        return reduced
    }

    static func generate(zone: Int, enemyIndex: Int) -> Enemy {
        let isBoss = enemyIndex % 10 == 0
        let level = max(1, (zone - 1) * 10 + enemyIndex)
        let data = ZoneData.forZone(zone)

        let baseHP = 60 + level * 25
        let baseAtk = 6 + level * 3
        let baseDef = 1 + level / 3

        let hpMult = isBoss ? 5.0 : 1.0
        let atkMult = isBoss ? 2.5 : 1.0
        let rewMult = isBoss ? 6.0 : 1.0

        let name = isBoss ? data.bossName : data.enemyNames.randomElement()!
        let emoji = isBoss ? data.bossEmoji : data.enemyEmojis.randomElement()!

        return Enemy(
            name: name,
            level: level,
            maxHP: Int(Double(baseHP) * hpMult),
            currentHP: Int(Double(baseHP) * hpMult),
            attack: Int(Double(baseAtk) * atkMult),
            defense: baseDef,
            experienceReward: Int(Double(level * 18) * rewMult),
            goldReward: Int(Double(level * 6 + Int.random(in: 1...12)) * rewMult),
            isBoss: isBoss,
            emoji: emoji,
            zoneName: data.zoneName
        )
    }
}

struct ZoneData {
    let zoneName: String
    let enemyNames: [String]
    let bossName: String
    let enemyEmojis: [String]
    let bossEmoji: String

    static func forZone(_ zone: Int) -> ZoneData {
        switch zone {
        case 1:
            return ZoneData(
                zoneName: "Verdant Forest",
                enemyNames: ["Slime", "Forest Goblin", "Giant Rat", "Wild Wolf"],
                bossName: "Forest Troll",
                enemyEmojis: ["🟢", "👺", "🐀", "🐺"],
                bossEmoji: "👹"
            )
        case 2:
            return ZoneData(
                zoneName: "Haunted Crypt",
                enemyNames: ["Skeleton", "Zombie", "Wraith", "Dark Mage"],
                bossName: "Lich King",
                enemyEmojis: ["💀", "🧟", "👻", "🧙"],
                bossEmoji: "☠️"
            )
        case 3:
            return ZoneData(
                zoneName: "Inferno Cavern",
                enemyNames: ["Imp", "Fire Elemental", "Hellhound", "Demon"],
                bossName: "Dragon",
                enemyEmojis: ["😈", "🔥", "🐕", "👿"],
                bossEmoji: "🐉"
            )
        case 4:
            return ZoneData(
                zoneName: "Frozen Wastes",
                enemyNames: ["Ice Golem", "Frost Witch", "Blizzard Wolf", "Yeti"],
                bossName: "Frost Queen",
                enemyEmojis: ["🧊", "🧙‍♀️", "🐺", "🦣"],
                bossEmoji: "👸"
            )
        case 5:
            return ZoneData(
                zoneName: "Void Realm",
                enemyNames: ["Shadow Wraith", "Void Walker", "Chaos Mage", "Nightmare"],
                bossName: "Chaos Lord",
                enemyEmojis: ["🌑", "⚫", "🧙‍♂️", "😱"],
                bossEmoji: "🌀"
            )
        default:
            let tier = ((zone - 1) / 5) + 1
            return ZoneData(
                zoneName: "Abyss Tier \(tier)",
                enemyNames: ["Elite Wraith", "Void Knight", "Abyssal Mage", "Dark Titan"],
                bossName: "Abyssal Lord",
                enemyEmojis: ["🌑", "⚔️", "💜", "🗿"],
                bossEmoji: "💀"
            )
        }
    }
}
