import SwiftUI

struct TradeView: View {
    @EnvironmentObject var vm: GameViewModel
    @State private var selectedCategory: CommodityCategory? = nil

    var filteredCommodities: [Commodity] {
        guard let cat = selectedCategory else { return Commodity.catalog }
        return Commodity.catalog.filter { $0.category == cat }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Refuel strip
            refuelStrip

            // Category filter
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    categoryChip(nil, label: "All")
                    ForEach(CommodityCategory.allCases, id: \.self) { cat in
                        categoryChip(cat, label: cat.rawValue)
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
            }

            Divider().background(Color.white.opacity(0.08))

            // Commodity list
            ScrollView {
                LazyVStack(spacing: 8) {
                    // Cargo items first (sell section)
                    if !vm.ship.cargo.isEmpty {
                        sectionHeader("Your Cargo — Tap to Sell")
                        ForEach(vm.ship.cargo) { item in
                            if let commodity = Commodity.find(item.commodityId),
                               filteredCommodities.contains(where: { $0.id == commodity.id }) {
                                CommodityRow(commodity: commodity, cargoQty: item.quantity, mode: .sell)
                            }
                        }
                        Divider().background(Color.white.opacity(0.08)).padding(.vertical, 4)
                    }

                    sectionHeader("Buy from Station")
                    ForEach(filteredCommodities) { commodity in
                        let cargoQty = vm.ship.cargoQuantity(of: commodity.id)
                        CommodityRow(commodity: commodity, cargoQty: cargoQty, mode: .buy)
                    }
                }
                .padding(.horizontal, 14)
                .padding(.bottom, 20)
            }
        }
    }

    private var refuelStrip: some View {
        let cost = max(1, Int((vm.ship.maxFuel - vm.ship.fuel) * 2.0))
        let isFull = vm.ship.fuel >= vm.ship.maxFuel - 0.5
        return Button(action: { vm.refuel() }) {
            HStack {
                Text("⛽ Fuel: \(String(format: "%.0f", vm.ship.fuel)) / \(String(format: "%.0f", vm.ship.maxFuel))")
                    .font(.system(size: 13, weight: .semibold))
                Spacer()
                if isFull {
                    Text("Full").font(.system(size: 13)).foregroundColor(.gray)
                } else {
                    Text("Refuel \(cost)cr")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(vm.ship.credits >= cost ? .cyan : .gray)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color.white.opacity(0.04))
        }
        .buttonStyle(.plain)
        .disabled(isFull || vm.ship.credits < cost)
    }

    private func categoryChip(_ cat: CommodityCategory?, label: String) -> some View {
        Button(action: { selectedCategory = cat }) {
            Text(label)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(selectedCategory == cat ? .black : .white.opacity(0.7))
                .padding(.horizontal, 10).padding(.vertical, 5)
                .background(Capsule().fill(selectedCategory == cat ? Color.cyan : Color.white.opacity(0.1)))
        }
        .buttonStyle(.plain)
    }

    private func sectionHeader(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .bold))
            .foregroundColor(.gray)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 4)
    }
}

// MARK: – Commodity row

enum TradeMode { case buy, sell }

struct CommodityRow: View {
    @EnvironmentObject var vm: GameViewModel
    let commodity: Commodity
    let cargoQty: Int
    let mode: TradeMode

    var listing: MarketListing? {
        vm.currentLocation?.listing(for: commodity.id)
    }

    var body: some View {
        guard let listing else { return AnyView(EmptyView()) }
        return AnyView(
            HStack(spacing: 10) {
                Text(commodity.emoji).font(.system(size: 26))

                VStack(alignment: .leading, spacing: 2) {
                    Text(commodity.name).font(.system(size: 13, weight: .semibold))
                    Text(commodity.category.rawValue)
                        .font(.system(size: 10)).foregroundColor(.gray)
                }

                Spacer()

                // Price info
                VStack(alignment: .trailing, spacing: 2) {
                    if mode == .buy {
                        priceTag(label: "Buy", price: listing.buyPrice, isGood: isCheap(listing.buyPrice, base: commodity.basePrice))
                        Text("Stock: \(listing.stationStock)").font(.system(size: 9)).foregroundColor(.gray)
                    } else {
                        priceTag(label: "Sell", price: listing.sellPrice, isGood: isHighSell(listing.sellPrice, base: commodity.basePrice))
                        Text("Have: \(cargoQty)").font(.system(size: 9)).foregroundColor(.gray)
                    }
                }

                // +/- buttons
                HStack(spacing: 4) {
                    if mode == .sell {
                        tradeButton("-", color: .orange) { vm.sell(commodityId: commodity.id, quantity: 1) }
                    }
                    tradeButton(mode == .buy ? "+" : "All", color: mode == .buy ? .cyan : .red) {
                        if mode == .buy {
                            vm.buy(commodityId: commodity.id, quantity: 1)
                        } else {
                            vm.sell(commodityId: commodity.id, quantity: cargoQty)
                        }
                    }
                }
            }
            .padding(10)
            .background(RoundedRectangle(cornerRadius: 12).fill(rowBackground))
            .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(rowBorder, lineWidth: 1))
        )
    }

    private var rowBackground: Color {
        if mode == .sell { return Color.orange.opacity(0.07) }
        return Color.white.opacity(0.04)
    }

    private var rowBorder: Color {
        if mode == .sell { return Color.orange.opacity(0.2) }
        return Color.white.opacity(0.07)
    }

    private func priceTag(label: String, price: Int, isGood: Bool) -> some View {
        HStack(spacing: 3) {
            Text(label).font(.system(size: 9)).foregroundColor(.gray)
            Text("\(price)cr")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(isGood ? Color(hex: "#22C55E") : .white.opacity(0.85))
            if isGood { Text("↑").font(.system(size: 10)).foregroundColor(Color(hex: "#22C55E")) }
        }
    }

    private func tradeButton(_ label: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(color)
                .frame(width: 36, height: 32)
                .background(RoundedRectangle(cornerRadius: 8).fill(color.opacity(0.18)))
        }
        .buttonStyle(.plain)
    }

    private func isCheap(_ price: Int, base: Int) -> Bool { price < base }
    private func isHighSell(_ price: Int, base: Int) -> Bool { price > Int(Double(base) * 0.95) }
}

// MARK: – Log view (embedded in station)

struct LogView: View {
    @EnvironmentObject var vm: GameViewModel

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 8) {
                if vm.journal.isEmpty {
                    Text("No entries yet. Start exploring!")
                        .font(.system(size: 13)).foregroundColor(.gray)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 40)
                }
                ForEach(vm.journal) { entry in
                    HStack(alignment: .top, spacing: 10) {
                        Text(entryIcon(entry.type)).font(.system(size: 14))
                        VStack(alignment: .leading, spacing: 2) {
                            Text(entry.message).font(.system(size: 12))
                            Text(entry.timestamp, style: .relative)
                                .font(.system(size: 10)).foregroundColor(.gray)
                        }
                    }
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.04)))
                }
            }
            .padding(14)
            .padding(.bottom, 20)
        }
    }

    private func entryIcon(_ type: JournalEntry.EntryType) -> String {
        switch type {
        case .discovery: return "🔭"
        case .trade:     return "💰"
        case .upgrade:   return "⬆️"
        case .arrival:   return "🛸"
        case .system:    return "📋"
        }
    }
}
