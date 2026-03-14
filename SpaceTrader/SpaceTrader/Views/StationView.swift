import SwiftUI

struct StationView: View {
    @EnvironmentObject var vm: GameViewModel
    @State private var selectedTab: StationTab = .trade

    enum StationTab: String, CaseIterable {
        case trade    = "Trade"
        case upgrades = "Upgrades"
        case log      = "Log"
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // ── Station header ──────────────────────────────────
                if let loc = vm.currentLocation {
                    VStack(spacing: 4) {
                        HStack(spacing: 8) {
                            Text(loc.type.emoji).font(.system(size: 28))
                            VStack(alignment: .leading, spacing: 2) {
                                Text(loc.name)
                                    .font(.system(size: 20, weight: .black))
                                Text(loc.type.displayName)
                                    .font(.system(size: 12))
                                    .foregroundColor(.gray)
                            }
                            Spacer()
                            // Credits badge
                            VStack(spacing: 1) {
                                Text("💰 \(vm.ship.credits)cr")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(Color(hex: "#FFD700"))
                                Text("Cargo \(vm.ship.cargoUsed)/\(vm.ship.maxCargo)")
                                    .font(.system(size: 10))
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 12)
                        .padding(.bottom, 6)

                        // Surplus / demand teaser
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 6) {
                                Text("Sells cheap:").font(.system(size: 10)).foregroundColor(.gray)
                                ForEach(loc.type.surplusCommodities, id: \.self) { cid in
                                    if let c = Commodity.find(cid) {
                                        Text("\(c.emoji)\(c.name)")
                                            .font(.system(size: 10, weight: .semibold))
                                            .foregroundColor(.green)
                                            .padding(.horizontal, 6).padding(.vertical, 2)
                                            .background(Capsule().fill(Color.green.opacity(0.15)))
                                    }
                                }
                                Text("Buys well:").font(.system(size: 10)).foregroundColor(.gray).padding(.leading, 4)
                                ForEach(loc.type.demandCommodities, id: \.self) { cid in
                                    if let c = Commodity.find(cid) {
                                        Text("\(c.emoji)\(c.name)")
                                            .font(.system(size: 10, weight: .semibold))
                                            .foregroundColor(.orange)
                                            .padding(.horizontal, 6).padding(.vertical, 2)
                                            .background(Capsule().fill(Color.orange.opacity(0.15)))
                                    }
                                }
                            }
                            .padding(.horizontal, 16)
                        }
                        .padding(.bottom, 8)
                    }
                    .background(Color.white.opacity(0.05))
                }

                // ── Tabs ────────────────────────────────────────────
                Picker("Tab", selection: $selectedTab) {
                    ForEach(StationTab.allCases, id: \.self) { tab in
                        Text(tab.rawValue).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)

                Divider().background(Color.white.opacity(0.1))

                // ── Tab content ─────────────────────────────────────
                Group {
                    switch selectedTab {
                    case .trade:    TradeView()
                    case .upgrades: ShipUpgradesView()
                    case .log:      LogView()
                    }
                }
                .environmentObject(vm)

                // ── Undock ──────────────────────────────────────────
                Button(action: { vm.undock() }) {
                    Label("Undock & Fly", systemImage: "arrow.up.circle.fill")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(14)
                        .background(Color.cyan)
                        .cornerRadius(14)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .background(Color(hex: "#0D0D1A").ignoresSafeArea())
            .preferredColorScheme(.dark)
        }
    }
}
