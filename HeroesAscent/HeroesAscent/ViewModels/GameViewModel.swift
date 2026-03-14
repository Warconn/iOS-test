import SwiftUI
import Combine

@MainActor
class GameViewModel: ObservableObject {

    // MARK: – Published state
    @Published var hero: Hero
    @Published var currentEnemy: Enemy
    @Published var progress: GameProgress
    @Published var phase: CombatPhase = .battle
    @Published var battleLog: [BattleLogEntry] = []
    @Published var floatingNumbers: [FloatingNumber] = []
    @Published var skillCooldowns: [String: Date] = [:]
    @Published var isRaging: Bool = false
    @Published var rageEndsAt: Date? = nil
    @Published var equippedItems: [ItemType: Item] = [:]
    @Published var ownedItemIDs: Set<String> = []

    // MARK: – Timers
    private var enemyAttackTimer: Timer?
    private var autoAttackTimer:  Timer?
    private var rageTimer:        Timer?

    private let saveKey = "heroesascent_v2"

    // MARK: – Init
    init() {
        if let saved = Self.loadSave() {
            hero     = saved.hero
            progress = saved.progress
            ownedItemIDs = Set(saved.ownedItemIDs)
            var equipped: [ItemType: Item] = [:]
            for (typeRaw, itemID) in saved.equippedByType {
                if let type_ = ItemType(rawValue: typeRaw),
                   let item  = Item.item(id: itemID) {
                    equipped[type_] = item
                }
            }
            equippedItems = equipped
        } else {
            hero     = Hero()
            progress = GameProgress()
            ownedItemIDs = ["stick", "robe", "pebble"]
            equippedItems = [
                .weapon:    Item.item(id: "stick")!,
                .armor:     Item.item(id: "robe")!,
                .accessory: Item.item(id: "pebble")!,
            ]
        }

        currentEnemy = Enemy.generate(zone: 1, enemyIndex: 1)
        applyEquipment()

        if progress.autoAttackEnabled { startAutoAttack() }
        startEnemyAttackTimer()
    }

    // MARK: – Public combat actions

    func tapAttack() {
        guard phase == .battle else { return }
        performPlayerAttack()
    }

    func useSkill(_ skill: Skill) {
        guard phase == .battle,
              isSkillUnlocked(skill),
              canUseSkill(skill),
              let level = hero.skills[skill.id], level > 0 else { return }

        skillCooldowns[skill.id] = Date()

        switch skill.id {
        case SkillIDs.powerStrike:
            let multiplier = 1.0 + Double(level) * 0.6
            let raw = Int(Double(hero.totalAttack) * multiplier)
            let isCrit = Double.random(in: 0...1) < hero.critChance
            let dmg = isCrit ? raw * 2 : raw
            let actual = currentEnemy.takeDamage(dmg)
            showFloating(actual, isCrit: isCrit, isHeal: false)
            addLog("💥 Power Strike hits for \(actual)!", type: isCrit ? .playerCrit : .playerHit)
            if currentEnemy.isDead { handleEnemyDefeated() }

        case SkillIDs.heal:
            let pct = 0.15 + Double(level) * 0.10
            let amount = Int(Double(hero.maxHP) * pct)
            hero.heal(amount)
            showFloating(amount, isCrit: false, isHeal: true)
            addLog("💚 Healed for \(amount) HP!", type: .heal)

        case SkillIDs.rage:
            let duration = Double(3 + level)
            isRaging = true
            rageEndsAt = Date().addingTimeInterval(duration)
            addLog("😤 Berserker Rage! 2× speed for \(Int(duration))s!", type: .system)
            restartAutoAttack()
            rageTimer?.invalidate()
            rageTimer = Timer.scheduledTimer(withTimeInterval: duration, repeats: false) { [weak self] _ in
                Task { @MainActor [weak self] in
                    self?.isRaging = false
                    self?.rageEndsAt = nil
                    self?.restartAutoAttack()
                }
            }
        default: break
        }
    }

    func buyItem(_ item: Item) {
        guard hero.gold >= item.price,
              hero.level >= item.requiredLevel,
              !ownedItemIDs.contains(item.id) else { return }
        hero.gold -= item.price
        ownedItemIDs.insert(item.id)
        addLog("🛍️ Purchased \(item.name)!", type: .system)
        save()
    }

    func equipItem(_ item: Item) {
        guard ownedItemIDs.contains(item.id) else { return }
        equippedItems[item.type] = item
        applyEquipment()
        addLog("✅ Equipped \(item.name)", type: .system)
        save()
    }

    func upgradeSkill(_ skill: Skill) {
        let current = hero.skills[skill.id] ?? 0
        guard current < skill.maxLevel else { return }
        let cost = skill.upgradeCost(current)
        guard hero.gold >= cost else { return }
        hero.gold -= cost
        hero.skills[skill.id] = current + 1
        let newLevel = current + 1
        addLog("🎯 \(skill.name) upgraded to level \(newLevel)!", type: .system)
        save()
    }

    func allocateStat(_ stat: StatType) {
        hero.allocateStat(stat)
        applyEquipment()
        save()
    }

    func toggleAutoAttack() {
        progress.autoAttackEnabled.toggle()
        if progress.autoAttackEnabled {
            startAutoAttack()
        } else {
            stopAutoAttack()
        }
        save()
    }

    func resetGame() {
        stopAll()
        UserDefaults.standard.removeObject(forKey: saveKey)
        hero = Hero()
        progress = GameProgress()
        ownedItemIDs = ["stick", "robe", "pebble"]
        equippedItems = [
            .weapon:    Item.item(id: "stick")!,
            .armor:     Item.item(id: "robe")!,
            .accessory: Item.item(id: "pebble")!,
        ]
        applyEquipment()
        spawnEnemy(zone: 1, index: 1)
        phase = .battle
        battleLog = []
        floatingNumbers = []
        skillCooldowns = [:]
        isRaging = false
        rageEndsAt = nil
        if progress.autoAttackEnabled { startAutoAttack() }
        startEnemyAttackTimer()
    }

    // MARK: – Skill helpers

    func isSkillUnlocked(_ skill: Skill) -> Bool { hero.level >= skill.unlockHeroLevel }

    func canUseSkill(_ skill: Skill) -> Bool {
        guard let last = skillCooldowns[skill.id] else { return true }
        return Date().timeIntervalSince(last) >= skill.cooldown
    }

    func cooldownRemaining(for skill: Skill) -> Double {
        guard let last = skillCooldowns[skill.id] else { return 0 }
        return max(0, skill.cooldown - Date().timeIntervalSince(last))
    }

    // MARK: – Private combat

    private func performPlayerAttack() {
        let isCrit = Double.random(in: 0...1) < hero.critChance
        let raw = isCrit ? hero.totalAttack * 2 : hero.totalAttack
        let actual = currentEnemy.takeDamage(raw)
        progress.totalDamageDealt += actual
        showFloating(actual, isCrit: isCrit, isHeal: false)
        addLog(isCrit ? "⚡ Critical! \(actual) dmg!" : "You hit for \(actual) dmg", type: isCrit ? .playerCrit : .playerHit)
        if currentEnemy.isDead { handleEnemyDefeated() }
    }

    private func handleEnemyDefeated() {
        stopEnemyAttackTimer()
        stopAutoAttack()

        let xp   = currentEnemy.experienceReward
        let gold = currentEnemy.goldReward
        hero.gold += gold
        progress.totalGoldEarned += gold
        progress.totalKills += 1
        progress.enemiesKilledInZone += 1

        let didLevel = hero.gainExperience(xp)

        if currentEnemy.isBoss {
            addLog("🏆 BOSS SLAIN! +\(xp) XP  +\(gold)g", type: .levelUp)
            progress.currentZone += 1
            progress.enemiesKilledInZone = 0
            if progress.currentZone > progress.highestZone {
                progress.highestZone = progress.currentZone
            }
        } else {
            addLog("✅ Defeated! +\(xp) XP  +\(gold)g", type: .system)
        }

        if didLevel {
            addLog("🎊 LEVEL UP! Now level \(hero.level)!", type: .levelUp)
            applyEquipment() // Recalculate in case items have different bonuses at new level
        }

        save()
        phase = .victory

        let nextZone  = progress.currentZone
        let nextIndex = progress.nextEnemyIndex
        let isBoss    = progress.isNextEnemyBoss

        DispatchQueue.main.asyncAfter(deadline: .now() + (currentEnemy.isBoss ? 2.5 : 1.2)) {
            if isBoss {
                self.phase = .bossWarning
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
                    self.spawnEnemy(zone: nextZone, index: nextIndex)
                    self.phase = .battle
                    self.startEnemyAttackTimer()
                    if self.progress.autoAttackEnabled { self.startAutoAttack() }
                }
            } else {
                self.spawnEnemy(zone: nextZone, index: nextIndex)
                self.phase = .battle
                self.startEnemyAttackTimer()
                if self.progress.autoAttackEnabled { self.startAutoAttack() }
            }
        }
    }

    private func handleHeroDeath() {
        stopAll()
        phase = .defeat
        addLog("💀 Defeated! Respawning…", type: .system)

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            self.hero.currentHP = max(1, self.hero.maxHP / 2)
            self.progress.enemiesKilledInZone = 0
            self.spawnEnemy(zone: self.progress.currentZone, index: 1)
            self.phase = .battle
            self.startEnemyAttackTimer()
            if self.progress.autoAttackEnabled { self.startAutoAttack() }
            self.save()
        }
    }

    private func spawnEnemy(zone: Int, index: Int) {
        currentEnemy = Enemy.generate(zone: zone, enemyIndex: index)
    }

    // MARK: – Timer management

    private func startEnemyAttackTimer() {
        let interval: TimeInterval = 2.0
        enemyAttackTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in self?.enemyTakesATurn() }
        }
    }

    private func stopEnemyAttackTimer() {
        enemyAttackTimer?.invalidate()
        enemyAttackTimer = nil
    }

    private func enemyTakesATurn() {
        guard phase == .battle, !hero.isDead else { return }
        let actual = hero.takeDamage(currentEnemy.attack)
        addLog("⚔️ \(currentEnemy.name) hits you for \(actual)", type: .enemyHit)
        if hero.isDead { handleHeroDeath() }
    }

    private func startAutoAttack() {
        let interval: TimeInterval = isRaging ? 0.4 : 0.9
        autoAttackTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard self?.phase == .battle else { return }
                self?.performPlayerAttack()
            }
        }
    }

    private func stopAutoAttack() {
        autoAttackTimer?.invalidate()
        autoAttackTimer = nil
    }

    private func restartAutoAttack() {
        stopAutoAttack()
        if progress.autoAttackEnabled || isRaging { startAutoAttack() }
    }

    private func stopAll() {
        stopEnemyAttackTimer()
        stopAutoAttack()
        rageTimer?.invalidate()
        rageTimer = nil
    }

    // MARK: – Equipment

    private func applyEquipment() {
        hero.attackBonus  = equippedItems.values.reduce(0) { $0 + $1.attackBonus }
        hero.defenseBonus = equippedItems.values.reduce(0) { $0 + $1.defenseBonus }
        hero.hpBonus      = equippedItems.values.reduce(0) { $0 + $1.hpBonus }
        let newMax = 100 + (hero.level - 1) * 15 + hero.hpBonus
        if newMax > hero.maxHP {
            hero.currentHP += newMax - hero.maxHP
        }
        hero.maxHP = newMax
        hero.currentHP = min(hero.currentHP, hero.maxHP)
    }

    // MARK: – Battle log helpers

    private func addLog(_ message: String, type: BattleLogEntry.LogEntryType) {
        let entry = BattleLogEntry(message: message, type: type)
        battleLog.insert(entry, at: 0)
        if battleLog.count > 12 { battleLog = Array(battleLog.prefix(12)) }
    }

    private func showFloating(_ value: Int, isCrit: Bool, isHeal: Bool) {
        let fn = FloatingNumber(value: value, isCrit: isCrit, isHeal: isHeal)
        floatingNumbers.append(fn)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            self.floatingNumbers.removeAll { $0.id == fn.id }
        }
    }

    // MARK: – Persistence

    struct SaveData: Codable {
        var hero: Hero
        var progress: GameProgress
        var ownedItemIDs: [String]
        var equippedByType: [String: String]
    }

    func save() {
        let equipped = equippedItems.reduce(into: [String: String]()) { dict, pair in
            dict[pair.key.rawValue] = pair.value.id
        }
        let data = SaveData(
            hero: hero,
            progress: progress,
            ownedItemIDs: Array(ownedItemIDs),
            equippedByType: equipped
        )
        if let encoded = try? JSONEncoder().encode(data) {
            UserDefaults.standard.set(encoded, forKey: saveKey)
        }
    }

    static func loadSave() -> SaveData? {
        guard let raw = UserDefaults.standard.data(forKey: "heroesascent_v2"),
              let save = try? JSONDecoder().decode(SaveData.self, from: raw) else { return nil }
        return save
    }

    deinit {
        enemyAttackTimer?.invalidate()
        autoAttackTimer?.invalidate()
        rageTimer?.invalidate()
    }
}
