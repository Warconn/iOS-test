import SwiftUI

struct HeroView: View {
    @EnvironmentObject var vm: GameViewModel
    @State private var showResetAlert = false

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                heroCard
                if vm.hero.statPoints > 0 { statAllocationCard }
                statsCard
                equipmentCard
                achievementsCard
                resetButton
            }
            .padding(16)
            .padding(.bottom, 90)
        }
    }

    // MARK: – Hero card
    private var heroCard: some View {
        VStack(spacing: 10) {
            Text("🧙").font(.system(size: 64))
            Text(vm.hero.name)
                .font(.system(size: 24, weight: .black))
                .foregroundColor(.white)
            Text("Level \(vm.hero.level) Hero")
                .font(.system(size: 14))
                .foregroundColor(Color(hex: "#A78BFA"))

            VStack(spacing: 6) {
                HStack {
                    Text("❤️ HP").font(.system(size: 12)).foregroundColor(.gray)
                    Spacer()
                    Text("\(vm.hero.currentHP) / \(vm.hero.maxHP)").font(.system(size: 12, weight: .semibold))
                }
                StatBar(value: vm.hero.hpPercent, color: Color(hex: "#22C55E"), height: 12)

                HStack {
                    Text("✨ EXP").font(.system(size: 12)).foregroundColor(.gray)
                    Spacer()
                    Text("\(vm.hero.experience) / \(vm.hero.experienceToNextLevel)").font(.system(size: 12, weight: .semibold))
                }
                StatBar(value: vm.hero.experiencePercent, color: Color(hex: "#6C63FF"), height: 8)
            }

            HStack(spacing: 20) {
                Label("\(vm.hero.gold)g", systemImage: "circle.fill")
                    .foregroundColor(Color(hex: "#FFD700"))
                    .font(.system(size: 13, weight: .semibold))
                Label("Zone \(vm.progress.currentZone)", systemImage: "map")
                    .foregroundColor(.gray)
                    .font(.system(size: 13))
                Label("\(vm.progress.totalKills) kills", systemImage: "xmark.circle")
                    .foregroundColor(.gray)
                    .font(.system(size: 13))
            }
        }
        .padding(16)
        .cardStyle()
    }

    // MARK: – Stat allocation
    private var statAllocationCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("🎉 Stat Points Available")
                    .font(.system(size: 15, weight: .bold))
                Spacer()
                Text("\(vm.hero.statPoints)")
                    .font(.system(size: 20, weight: .black))
                    .foregroundColor(Color(hex: "#FFD700"))
            }

            ForEach(StatType.allCases, id: \.self) { stat in
                HStack {
                    Text(stat.icon).font(.system(size: 18))
                    VStack(alignment: .leading, spacing: 2) {
                        Text(stat.rawValue).font(.system(size: 13, weight: .semibold))
                        Text(stat.description).font(.system(size: 11)).foregroundColor(.gray)
                    }
                    Spacer()
                    Button {
                        vm.allocateStat(stat)
                    } label: {
                        Text("+")
                            .font(.system(size: 18, weight: .bold))
                            .frame(width: 36, height: 36)
                            .background(Circle().fill(Color(hex: "#FFD700").opacity(0.25)))
                            .foregroundColor(Color(hex: "#FFD700"))
                    }
                    .buttonStyle(.plain)
                }
                .padding(10)
                .background(Color.white.opacity(0.05))
                .cornerRadius(10)
            }
        }
        .padding(16)
        .cardStyle(borderColor: Color(hex: "#FFD700").opacity(0.4))
    }

    // MARK: – Stats
    private var statsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Combat Stats").font(.system(size: 15, weight: .bold)).foregroundColor(.gray)
            statRow("⚔️ Attack",  "\(vm.hero.totalAttack)  (base \(vm.hero.baseAttack) +\(vm.hero.attackBonus))")
            statRow("🛡️ Defense", "\(vm.hero.totalDefense) (base \(vm.hero.baseDefense) +\(vm.hero.defenseBonus))")
            statRow("❤️ Max HP",  "\(vm.hero.maxHP) (base \(100 + (vm.hero.level-1)*15) +\(vm.hero.hpBonus))")
            statRow("⚡ Crit",    "\(Int(vm.hero.critChance * 100))% chance (2× damage)")
        }
        .padding(16)
        .cardStyle()
    }

    private func statRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label).font(.system(size: 13)).foregroundColor(.white.opacity(0.85))
            Spacer()
            Text(value).font(.system(size: 12, weight: .semibold)).foregroundColor(Color(hex: "#A78BFA"))
        }
    }

    // MARK: – Equipment
    private var equipmentCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Equipped Items").font(.system(size: 15, weight: .bold)).foregroundColor(.gray)
            ForEach(ItemType.allCases, id: \.self) { type in
                HStack {
                    Text(type.slotEmoji).font(.system(size: 18))
                    Text(type.displayName).font(.system(size: 13)).foregroundColor(.gray)
                    Spacer()
                    if let item = vm.equippedItems[type] {
                        HStack(spacing: 4) {
                            Text(item.emoji).font(.system(size: 14))
                            Text(item.name).font(.system(size: 13, weight: .semibold))
                        }
                    } else {
                        Text("Empty").font(.system(size: 13)).foregroundColor(.gray.opacity(0.5))
                    }
                }
                .padding(10)
                .background(Color.white.opacity(0.04))
                .cornerRadius(8)
            }
        }
        .padding(16)
        .cardStyle()
    }

    // MARK: – Achievements
    private var achievementsCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Journey Stats").font(.system(size: 15, weight: .bold)).foregroundColor(.gray)
            statRow("🗺️ Highest Zone",   "Zone \(vm.progress.highestZone)")
            statRow("⚔️ Total Kills",    "\(vm.progress.totalKills)")
            statRow("💰 Gold Earned",    "\(vm.progress.totalGoldEarned)g")
            statRow("💥 Damage Dealt",   "\(vm.progress.totalDamageDealt)")
        }
        .padding(16)
        .cardStyle()
    }

    // MARK: – Reset
    private var resetButton: some View {
        Button {
            showResetAlert = true
        } label: {
            Text("🗑️ Reset Game")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.red.opacity(0.8))
                .frame(maxWidth: .infinity)
                .padding(12)
                .background(Color.red.opacity(0.1))
                .cornerRadius(12)
                .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Color.red.opacity(0.25), lineWidth: 1))
        }
        .buttonStyle(.plain)
        .alert("Reset Game?", isPresented: $showResetAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Reset", role: .destructive) { vm.resetGame() }
        } message: {
            Text("All progress will be permanently lost.")
        }
    }
}

// MARK: – Card modifier
extension View {
    func cardStyle(borderColor: Color = Color.white.opacity(0.1)) -> some View {
        self
            .background(Color.white.opacity(0.06))
            .cornerRadius(16)
            .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(borderColor, lineWidth: 1))
    }
}
