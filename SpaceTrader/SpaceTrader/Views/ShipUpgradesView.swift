import SwiftUI

struct ShipUpgradesView: View {
    @EnvironmentObject var vm: GameViewModel
    @State private var showResetAlert = false

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                // Ship overview card
                shipCard

                // Upgrade cards
                ForEach(ShipUpgrade.allCases, id: \.self) { upgrade in
                    UpgradeCard(upgrade: upgrade)
                }

                // Reset button
                Button(action: { showResetAlert = true }) {
                    Text("🗑️ New Game")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.red.opacity(0.7))
                        .frame(maxWidth: .infinity)
                        .padding(12)
                        .background(Color.red.opacity(0.08))
                        .cornerRadius(12)
                        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Color.red.opacity(0.2), lineWidth: 1))
                }
                .buttonStyle(.plain)
                .padding(.top, 8)
            }
            .padding(14)
            .padding(.bottom, 20)
        }
        .alert("Start New Game?", isPresented: $showResetAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Reset", role: .destructive) {
                vm.undock()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { vm.resetGame() }
            }
        } message: {
            Text("All progress will be permanently lost.")
        }
    }

    private var shipCard: some View {
        VStack(spacing: 8) {
            HStack {
                Text("🛸 Your Ship")
                    .font(.system(size: 16, weight: .bold))
                Spacer()
                Text("💰 \(vm.ship.credits)cr")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color(hex: "#FFD700"))
            }
            Divider().background(Color.white.opacity(0.1))
            statRow("🚀 Max Speed",  "\(Int(vm.ship.maxSpeed)) u/s")
            statRow("📦 Cargo",      "\(vm.ship.cargoUsed)/\(vm.ship.maxCargo) slots")
            statRow("📡 Scanner",    "\(Int(vm.ship.scannerRange)) units")
            statRow("⛽ Fuel Tank",  "\(String(format: "%.0f", vm.ship.fuel))/\(String(format: "%.0f", vm.ship.maxFuel))")
            statRow("🌍 Discovered", "\(vm.universe.filter(\.isDiscovered).count)/\(vm.universe.count) systems")
        }
        .padding(14)
        .background(Color.white.opacity(0.06))
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(Color.white.opacity(0.1), lineWidth: 1))
    }

    private func statRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label).font(.system(size: 12)).foregroundColor(.gray)
            Spacer()
            Text(value).font(.system(size: 12, weight: .semibold)).foregroundColor(.white.opacity(0.9))
        }
    }
}

// MARK: – Individual upgrade card

struct UpgradeCard: View {
    @EnvironmentObject var vm: GameViewModel
    let upgrade: ShipUpgrade

    var currentLevel: Int { vm.ship.upgradeLevel(for: upgrade) }
    var isMaxed: Bool { currentLevel >= 5 }
    var cost: Int? { upgrade.cost(toUpgradeFrom: currentLevel) }
    var canAfford: Bool { vm.ship.credits >= (cost ?? Int.max) }

    var body: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                Text(upgrade.emoji).font(.system(size: 28))
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(Color.white.opacity(0.07)))

                VStack(alignment: .leading, spacing: 3) {
                    HStack {
                        Text(upgrade.displayName).font(.system(size: 15, weight: .bold))
                        Spacer()
                        levelDots
                    }
                    Text(upgrade.description).font(.system(size: 11)).foregroundColor(.gray)
                }
            }

            Divider().background(Color.white.opacity(0.08))

            HStack {
                // Current → next description
                VStack(alignment: .leading, spacing: 2) {
                    if isMaxed {
                        Text("MAX LEVEL").font(.system(size: 11, weight: .black)).foregroundColor(Color(hex: "#FFD700"))
                    } else {
                        Text("Level \(currentLevel) → \(currentLevel + 1)")
                            .font(.system(size: 10)).foregroundColor(.gray)
                        Text(vm.ship.nextLevelDescription(for: upgrade))
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(Color(hex: "#A78BFA"))
                    }
                }
                Spacer()
                if !isMaxed, let c = cost {
                    Button(action: { vm.upgrade(upgrade) }) {
                        HStack(spacing: 4) {
                            Text("💰").font(.system(size: 13))
                            Text("\(c)cr").font(.system(size: 13, weight: .bold))
                        }
                        .foregroundColor(canAfford ? Color(hex: "#FFD700") : .gray)
                        .padding(.horizontal, 14).padding(.vertical, 8)
                        .background(canAfford ? Color(hex: "#FFD700").opacity(0.18) : Color.white.opacity(0.06))
                        .cornerRadius(10)
                        .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(canAfford ? Color(hex: "#FFD700").opacity(0.5) : Color.clear, lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                    .disabled(!canAfford)
                }
            }
        }
        .padding(14)
        .background(Color.white.opacity(0.05))
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(Color.white.opacity(0.09), lineWidth: 1))
    }

    private var levelDots: some View {
        HStack(spacing: 4) {
            ForEach(1...5, id: \.self) { i in
                Circle()
                    .fill(i <= currentLevel ? Color(hex: "#00E5FF") : Color.white.opacity(0.18))
                    .frame(width: 8, height: 8)
            }
        }
    }
}
