import SwiftUI

struct BattleView: View {
    @EnvironmentObject var vm: GameViewModel
    @State private var enemyShake: Bool = false
    @State private var heroFlash: Bool = false
    @State private var tapScale: CGFloat = 1.0
    @State private var showBossWarning: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            heroHeader
            Divider().background(Color.white.opacity(0.1))
            battleArena
            Divider().background(Color.white.opacity(0.1))
            skillsRow
            Divider().background(Color.white.opacity(0.1))
            battleLogView
        }
        .onChange(of: vm.currentEnemy.currentHP) { _ in
            withAnimation(.default) { enemyShake = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { enemyShake = false }
        }
        .onChange(of: vm.hero.currentHP) { _ in
            withAnimation { heroFlash = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { heroFlash = false }
        }
        .onChange(of: vm.phase) { phase in
            if phase == .bossWarning { showBossWarning = true }
            if phase == .battle      { showBossWarning = false }
        }
        .overlay {
            if showBossWarning { bossWarningOverlay }
            if vm.phase == .defeat    { defeatOverlay }
            if vm.phase == .victory   { victoryFlash }
        }
    }

    // MARK: – Hero header bar
    private var heroHeader: some View {
        VStack(spacing: 4) {
            HStack {
                Text("⚔️ Lv.\(vm.hero.level)  \(vm.currentEnemy.zoneName)")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.gray)
                Spacer()
                Text("💰 \(vm.hero.gold)g")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Color(hex: "#FFD700"))
            }

            HStack(spacing: 6) {
                Text("❤️").font(.system(size: 12))
                StatBar(value: vm.hero.hpPercent, color: hpColor, height: 12)
                Text("\(vm.hero.currentHP)/\(vm.hero.maxHP)")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
                    .frame(width: 72, alignment: .trailing)
            }
            .opacity(heroFlash ? 0.5 : 1.0)

            HStack(spacing: 6) {
                Text("✨").font(.system(size: 12))
                StatBar(value: vm.hero.experiencePercent, color: Color(hex: "#6C63FF"), height: 8)
                Text("\(vm.hero.experience)/\(vm.hero.experienceToNextLevel) XP")
                    .font(.system(size: 10))
                    .foregroundColor(.gray)
                    .frame(width: 72, alignment: .trailing)
            }

            if vm.hero.statPoints > 0 {
                Text("🎉 \(vm.hero.statPoints) stat point\(vm.hero.statPoints > 1 ? "s" : "") available! → Hero tab")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(Color(hex: "#FFD700"))
                    .padding(.top, 2)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color.white.opacity(0.03))
    }

    private var hpColor: Color {
        switch vm.hero.hpPercent {
        case 0.5...: return Color(hex: "#22C55E")
        case 0.25...: return Color(hex: "#F59E0B")
        default: return Color(hex: "#EF4444")
        }
    }

    // MARK: – Battle arena
    private var battleArena: some View {
        ZStack {
            // Tap area – entire zone
            Rectangle()
                .fill(Color.clear)
                .contentShape(Rectangle())
                .onTapGesture {
                    guard vm.phase == .battle else { return }
                    withAnimation(.spring(response: 0.15, dampingFraction: 0.4)) {
                        tapScale = 0.88
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                        withAnimation(.spring()) { tapScale = 1.0 }
                    }
                    vm.tapAttack()
                }

            VStack(spacing: 8) {
                // Enemy emoji
                Text(vm.currentEnemy.emoji)
                    .font(.system(size: 90))
                    .scaleEffect(tapScale)
                    .offset(x: enemyShake ? CGFloat.random(in: -5...5) : 0,
                            y: enemyShake ? CGFloat.random(in: -3...3) : 0)
                    .shadow(color: vm.currentEnemy.isBoss ? .red.opacity(0.4) : .clear, radius: 20)
                    .animation(.easeInOut(duration: 0.08).repeatCount(4, autoreverses: true), value: enemyShake)

                VStack(spacing: 3) {
                    HStack {
                        if vm.currentEnemy.isBoss {
                            Text("👑 BOSS").font(.system(size: 11, weight: .black)).foregroundColor(.red)
                        }
                        Text(vm.currentEnemy.name)
                            .font(.system(size: vm.currentEnemy.isBoss ? 18 : 16, weight: .bold))
                            .foregroundColor(vm.currentEnemy.isBoss ? .red : .white)
                    }
                    Text("Level \(vm.currentEnemy.level)")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                }

                HStack(spacing: 6) {
                    Text("💔").font(.system(size: 12))
                    StatBar(value: vm.currentEnemy.hpPercent, color: Color(hex: "#EF4444"), height: 14)
                    Text("\(vm.currentEnemy.currentHP)/\(vm.currentEnemy.maxHP)")
                        .font(.system(size: 10))
                        .foregroundColor(.gray)
                        .frame(width: 80, alignment: .trailing)
                }
                .padding(.horizontal, 24)

                if vm.phase == .battle {
                    Text("TAP TO ATTACK")
                        .font(.system(size: 11, weight: .heavy))
                        .foregroundColor(Color(hex: "#FFD700").opacity(0.7))
                        .padding(.top, 4)
                }
            }

            // Floating damage numbers
            floatingNumbersOverlay
        }
        .frame(maxWidth: .infinity)
        .frame(height: 260)
    }

    private var floatingNumbersOverlay: some View {
        ZStack {
            ForEach(vm.floatingNumbers) { fn in
                FloatingDamageView(number: fn)
                    .offset(x: CGFloat.random(in: -50...50), y: -30)
            }
        }
    }

    // MARK: – Skills row
    private var skillsRow: some View {
        HStack(spacing: 12) {
            ForEach(Skill.catalog) { skill in
                SkillButton(skill: skill)
            }
            Spacer()
            autoAttackToggle
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    private var autoAttackToggle: some View {
        Button {
            vm.toggleAutoAttack()
        } label: {
            VStack(spacing: 2) {
                Text(vm.progress.autoAttackEnabled ? "⚡" : "💤")
                    .font(.system(size: 22))
                Text("Auto")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundColor(vm.progress.autoAttackEnabled ? Color(hex: "#22C55E") : .gray)
            }
            .frame(width: 52, height: 52)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(vm.progress.autoAttackEnabled
                          ? Color(hex: "#22C55E").opacity(0.25)
                          : Color.white.opacity(0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(vm.progress.autoAttackEnabled
                                          ? Color(hex: "#22C55E").opacity(0.6)
                                          : Color.white.opacity(0.15), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: – Battle log
    private var battleLogView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 3) {
                ForEach(vm.battleLog) { entry in
                    Text(entry.message)
                        .font(.system(size: 12))
                        .foregroundColor(logColor(for: entry.type))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
        }
        .frame(maxHeight: 110)
        .background(Color.black.opacity(0.3))
    }

    private func logColor(for type: BattleLogEntry.LogEntryType) -> Color {
        switch type {
        case .playerHit:  return .white.opacity(0.85)
        case .playerCrit: return Color(hex: "#FFD700")
        case .enemyHit:   return Color(hex: "#F87171")
        case .heal:       return Color(hex: "#4ADE80")
        case .levelUp:    return Color(hex: "#A78BFA")
        case .system:     return .gray
        }
    }

    // MARK: – Overlays
    private var bossWarningOverlay: some View {
        ZStack {
            Color.black.opacity(0.7).ignoresSafeArea()
            VStack(spacing: 12) {
                Text("⚠️").font(.system(size: 60))
                Text("BOSS INCOMING!").font(.system(size: 28, weight: .black)).foregroundColor(.red)
                Text("Prepare yourself…").foregroundColor(.gray)
            }
        }
        .transition(.opacity)
    }

    private var defeatOverlay: some View {
        ZStack {
            Color.black.opacity(0.75).ignoresSafeArea()
            VStack(spacing: 10) {
                Text("💀").font(.system(size: 60))
                Text("DEFEATED").font(.system(size: 26, weight: .black)).foregroundColor(.red)
                Text("Respawning…").foregroundColor(.gray).font(.system(size: 14))
            }
        }
        .transition(.opacity)
    }

    private var victoryFlash: some View {
        Color(hex: "#FFD700").opacity(0.15)
            .ignoresSafeArea()
            .allowsHitTesting(false)
            .transition(.opacity)
    }
}

// MARK: – Skill button
struct SkillButton: View {
    @EnvironmentObject var vm: GameViewModel
    let skill: Skill

    var isUnlocked: Bool { vm.isSkillUnlocked(skill) }
    var level: Int { vm.hero.skills[skill.id] ?? 0 }
    var canUse: Bool { vm.canUseSkill(skill) && isUnlocked && level > 0 && vm.phase == .battle }
    var remaining: Double { vm.cooldownRemaining(for: skill) }

    var body: some View {
        Button {
            vm.useSkill(skill)
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(canUse
                          ? Color(hex: "#6C63FF").opacity(0.35)
                          : Color.white.opacity(0.06))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(
                                canUse ? Color(hex: "#6C63FF") : Color.white.opacity(0.12),
                                lineWidth: 1
                            )
                    )

                // Cooldown overlay
                if remaining > 0 && level > 0 {
                    let fraction = remaining / skill.cooldown
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.black.opacity(0.55))
                    Text(String(format: "%.0f", remaining))
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                }

                VStack(spacing: 2) {
                    Text(skill.emoji).font(.system(size: 22))
                    Text(isUnlocked ? (level > 0 ? "Lv.\(level)" : "Learn") : "Lv.\(skill.unlockHeroLevel)")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundColor(isUnlocked ? .white.opacity(0.7) : .gray)
                }
            }
            .frame(width: 52, height: 52)
            .opacity(isUnlocked ? 1.0 : 0.4)
        }
        .buttonStyle(.plain)
        .disabled(!canUse)
    }
}

// MARK: – Floating damage number
struct FloatingDamageView: View {
    let number: FloatingNumber
    @State private var opacity: Double = 1
    @State private var yOffset: Double = 0

    var body: some View {
        Text(number.isHeal ? "+\(number.value)" : "-\(number.value)")
            .font(.system(size: number.isCrit ? 22 : 16, weight: .black))
            .foregroundColor(
                number.isHeal ? Color(hex: "#4ADE80") :
                number.isCrit ? Color(hex: "#FFD700") :
                                Color(hex: "#F87171")
            )
            .shadow(color: .black, radius: 2)
            .offset(y: yOffset)
            .opacity(opacity)
            .onAppear {
                withAnimation(.easeOut(duration: 1.1)) {
                    yOffset = -80
                    opacity = 0
                }
            }
    }
}
