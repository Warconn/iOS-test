import Foundation

struct Hero: Codable, Equatable {
    var name: String = "Hero"
    var level: Int = 1
    var experience: Int = 0
    var experienceToNextLevel: Int = 100
    var currentHP: Int = 100
    var maxHP: Int = 100
    var baseAttack: Int = 10
    var baseDefense: Int = 5
    var gold: Int = 50
    var statPoints: Int = 0
    var critChance: Double = 0.05

    // Equipment bonuses (recalculated from equipped items)
    var attackBonus: Int = 0
    var defenseBonus: Int = 0
    var hpBonus: Int = 0

    // Skills: skillId → current level (0 = not learned)
    var skills: [String: Int] = [:]

    var totalAttack: Int { baseAttack + attackBonus }
    var totalDefense: Int { baseDefense + defenseBonus }

    var experiencePercent: Double {
        guard experienceToNextLevel > 0 else { return 1.0 }
        return Double(experience) / Double(experienceToNextLevel)
    }

    var hpPercent: Double {
        guard maxHP > 0 else { return 0 }
        return Double(currentHP) / Double(maxHP)
    }

    var isDead: Bool { currentHP <= 0 }

    /// Returns true if the hero leveled up.
    mutating func gainExperience(_ amount: Int) -> Bool {
        experience += amount
        if experience >= experienceToNextLevel {
            levelUp()
            return true
        }
        return false
    }

    mutating func levelUp() {
        experience -= experienceToNextLevel
        level += 1
        experienceToNextLevel = Int(Double(experienceToNextLevel) * 1.3)
        statPoints += 3
        baseAttack += 2
        baseDefense += 1
        let oldMax = maxHP
        maxHP = 100 + (level - 1) * 15 + hpBonus
        currentHP = min(currentHP + (maxHP - oldMax), maxHP) // Partial heal on level up
    }

    mutating func heal(_ amount: Int) {
        currentHP = min(currentHP + amount, maxHP)
    }

    /// Returns actual damage taken.
    @discardableResult
    mutating func takeDamage(_ rawDamage: Int) -> Int {
        let reduced = max(1, rawDamage - totalDefense)
        currentHP = max(0, currentHP - reduced)
        return reduced
    }

    mutating func allocateStat(_ stat: StatType) {
        guard statPoints > 0 else { return }
        statPoints -= 1
        switch stat {
        case .attack:  baseAttack += 3
        case .defense: baseDefense += 2
        case .hp:
            maxHP += 25
            currentHP = min(currentHP + 25, maxHP)
        }
    }
}

enum StatType: String, CaseIterable, Codable {
    case attack  = "Attack"
    case defense = "Defense"
    case hp      = "HP"

    var icon: String {
        switch self {
        case .attack:  return "⚔️"
        case .defense: return "🛡️"
        case .hp:      return "❤️"
        }
    }

    var description: String {
        switch self {
        case .attack:  return "+3 Attack per point"
        case .defense: return "+2 Defense per point"
        case .hp:      return "+25 Max HP per point"
        }
    }
}
