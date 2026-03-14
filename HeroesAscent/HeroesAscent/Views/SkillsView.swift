import SwiftUI

struct SkillsView: View {
    @EnvironmentObject var vm: GameViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Header
                VStack(spacing: 4) {
                    Text("🎯 Skills")
                        .font(.system(size: 22, weight: .black))
                    Text("Unlock powerful abilities as you level up")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                    HStack {
                        Text("💰 \(vm.hero.gold)g available")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(Color(hex: "#FFD700"))
                    }
                }
                .padding(.top, 16)

                // Skill cards
                ForEach(Skill.catalog) { skill in
                    SkillCard(skill: skill)
                }

                // Skill usage tips
                tipsCard

                Spacer(minLength: 90)
            }
            .padding(.horizontal, 16)
        }
    }

    private var tipsCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("💡 Skill Tips").font(.system(size: 14, weight: .bold))
            Group {
                tipRow("💥", "Power Strike – Use on bosses for big burst damage")
                tipRow("💚", "Battle Heal – Save for when HP drops below 30%")
                tipRow("😤", "Berserker Rage – Best combined with Auto Attack")
                tipRow("⚔️", "Skills share no cooldown – combine freely!")
            }
        }
        .padding(14)
        .cardStyle()
    }

    private func tipRow(_ emoji: String, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text(emoji).font(.system(size: 14))
            Text(text).font(.system(size: 12)).foregroundColor(.gray)
        }
    }
}

struct SkillCard: View {
    @EnvironmentObject var vm: GameViewModel
    let skill: Skill

    var isUnlocked: Bool  { vm.isSkillUnlocked(skill) }
    var currentLevel: Int { vm.hero.skills[skill.id] ?? 0 }
    var isMaxed: Bool     { currentLevel >= skill.maxLevel }
    var upgradeCost: Int  { skill.upgradeCost(currentLevel) }
    var canAfford: Bool   { vm.hero.gold >= upgradeCost }
    var canLearn: Bool    { isUnlocked && !isMaxed && canAfford }
    var isOnCooldown: Bool { !vm.canUseSkill(skill) && currentLevel > 0 }
    var cooldownLeft: Double { vm.cooldownRemaining(for: skill) }

    var body: some View {
        VStack(spacing: 12) {
            // Top row
            HStack(spacing: 12) {
                // Skill icon with cooldown ring
                ZStack {
                    Circle()
                        .fill(
                            isUnlocked
                                ? Color(hex: "#6C63FF").opacity(0.25)
                                : Color.white.opacity(0.06)
                        )
                        .frame(width: 60, height: 60)

                    if isOnCooldown {
                        Circle()
                            .trim(from: 0, to: CGFloat(cooldownLeft / skill.cooldown))
                            .stroke(Color(hex: "#6C63FF"), lineWidth: 3)
                            .frame(width: 54, height: 54)
                            .rotationEffect(.degrees(-90))
                    }

                    Text(skill.emoji).font(.system(size: 30))

                    if !isUnlocked {
                        Text("🔒")
                            .font(.system(size: 14))
                            .offset(x: 18, y: 18)
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(skill.name)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(isUnlocked ? .white : .gray)
                        Spacer()
                        if isMaxed {
                            Text("MAX").font(.system(size: 10, weight: .black))
                                .foregroundColor(Color(hex: "#FFD700"))
                                .padding(.horizontal, 6).padding(.vertical, 2)
                                .background(Color(hex: "#FFD700").opacity(0.2))
                                .cornerRadius(4)
                        } else {
                            levelDots
                        }
                    }

                    if !isUnlocked {
                        Text("Unlocks at Hero Level \(skill.unlockHeroLevel)")
                            .font(.system(size: 12))
                            .foregroundColor(.orange.opacity(0.8))
                    } else if currentLevel == 0 {
                        Text("Not learned yet")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                    } else {
                        Text(skill.effectDescription(atLevel: currentLevel))
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.85))
                    }
                }
            }

            // Next level preview + upgrade button
            if isUnlocked && !isMaxed {
                Divider().background(Color.white.opacity(0.1))
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(currentLevel == 0 ? "Learn Skill:" : "Upgrade to Lv.\(currentLevel + 1):")
                            .font(.system(size: 11))
                            .foregroundColor(.gray)
                        if let next = skill.nextLevelDescription(atLevel: currentLevel) {
                            Text(next)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(Color(hex: "#A78BFA"))
                        }
                    }
                    Spacer()
                    Button {
                        vm.upgradeSkill(skill)
                    } label: {
                        HStack(spacing: 4) {
                            Text("💰")
                            Text("\(upgradeCost)g")
                                .font(.system(size: 13, weight: .bold))
                        }
                        .foregroundColor(canAfford ? Color(hex: "#FFD700") : .gray)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(
                            canAfford
                                ? Color(hex: "#FFD700").opacity(0.2)
                                : Color.white.opacity(0.06)
                        )
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .strokeBorder(
                                    canAfford ? Color(hex: "#FFD700").opacity(0.5) : Color.clear,
                                    lineWidth: 1
                                )
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(!canAfford)
                }
            }

            if isOnCooldown {
                HStack {
                    Text("⏱ Cooldown: \(String(format: "%.1f", cooldownLeft))s remaining")
                        .font(.system(size: 11))
                        .foregroundColor(.gray)
                    Spacer()
                }
            }
        }
        .padding(14)
        .cardStyle(borderColor: isUnlocked ? Color(hex: "#6C63FF").opacity(0.3) : Color.white.opacity(0.08))
        .opacity(isUnlocked ? 1.0 : 0.6)
    }

    private var levelDots: some View {
        HStack(spacing: 4) {
            ForEach(0..<skill.maxLevel, id: \.self) { i in
                Circle()
                    .fill(i < currentLevel ? Color(hex: "#6C63FF") : Color.white.opacity(0.2))
                    .frame(width: 8, height: 8)
            }
        }
    }
}
