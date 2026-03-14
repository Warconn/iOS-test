import Foundation

enum CombatPhase: Equatable {
    case battle
    case victory
    case defeat
    case bossWarning
}

struct BattleLogEntry: Identifiable {
    let id = UUID()
    let message: String
    let type: LogEntryType

    enum LogEntryType {
        case playerHit, playerCrit, enemyHit, heal, system, levelUp
    }

    var color: String {
        switch type {
        case .playerHit:  return "playerHit"
        case .playerCrit: return "playerCrit"
        case .enemyHit:   return "enemyHit"
        case .heal:       return "heal"
        case .system:     return "system"
        case .levelUp:    return "levelUp"
        }
    }
}

struct GameProgress: Codable, Equatable {
    var currentZone: Int = 1
    var enemiesKilledInZone: Int = 0
    var totalKills: Int = 0
    var highestZone: Int = 1
    var autoAttackEnabled: Bool = false
    var totalDamageDealt: Int = 0
    var totalGoldEarned: Int = 0

    /// 1-based enemy index within the current zone (1–10, 10 = boss)
    var nextEnemyIndex: Int {
        (enemiesKilledInZone % 10) + 1
    }

    var isNextEnemyBoss: Bool {
        nextEnemyIndex == 10
    }
}

struct FloatingNumber: Identifiable {
    let id = UUID()
    let value: Int
    let isCrit: Bool
    let isHeal: Bool
    var opacity: Double = 1.0
    var yOffset: Double = 0.0
}
