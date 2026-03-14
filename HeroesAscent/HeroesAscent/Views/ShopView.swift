import SwiftUI

struct ShopView: View {
    @EnvironmentObject var vm: GameViewModel
    @State private var selectedType: ItemType = .weapon

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("🏪 Shop")
                        .font(.system(size: 22, weight: .black))
                    Text("Level \(vm.hero.level) Hero")
                        .font(.system(size: 12)).foregroundColor(.gray)
                }
                Spacer()
                goldDisplay
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 10)

            // Category picker
            Picker("Category", selection: $selectedType) {
                ForEach(ItemType.allCases, id: \.self) { type in
                    Text("\(type.slotEmoji) \(type.displayName)").tag(type)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 16)
            .padding(.bottom, 10)

            Divider().background(Color.white.opacity(0.1))

            // Item list
            ScrollView {
                LazyVStack(spacing: 10) {
                    ForEach(Item.items(ofType: selectedType)) { item in
                        ShopItemRow(item: item)
                    }
                }
                .padding(16)
                .padding(.bottom, 90)
            }
        }
    }

    private var goldDisplay: some View {
        HStack(spacing: 6) {
            Text("💰")
            Text("\(vm.hero.gold)g")
                .font(.system(size: 18, weight: .black))
                .foregroundColor(Color(hex: "#FFD700"))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(Color(hex: "#FFD700").opacity(0.15))
        .cornerRadius(10)
    }
}

struct ShopItemRow: View {
    @EnvironmentObject var vm: GameViewModel
    let item: Item

    var isOwned: Bool   { vm.ownedItemIDs.contains(item.id) }
    var isEquipped: Bool {
        vm.equippedItems[item.type]?.id == item.id
    }
    var canAfford: Bool  { vm.hero.gold >= item.price }
    var meetsLevel: Bool { vm.hero.level >= item.requiredLevel }
    var canBuy: Bool     { !isOwned && canAfford && meetsLevel }

    var body: some View {
        HStack(spacing: 12) {
            // Icon
            Text(item.emoji)
                .font(.system(size: 36))
                .frame(width: 48, height: 48)
                .background(
                    Circle().fill(
                        isEquipped ? Color(hex: "#6C63FF").opacity(0.3) :
                        isOwned    ? Color.white.opacity(0.08) :
                                     Color.white.opacity(0.04)
                    )
                )

            // Info
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(item.name).font(.system(size: 14, weight: .bold))
                    if isEquipped {
                        Text("EQUIPPED")
                            .font(.system(size: 9, weight: .black))
                            .foregroundColor(Color(hex: "#6C63FF"))
                            .padding(.horizontal, 5).padding(.vertical, 2)
                            .background(Color(hex: "#6C63FF").opacity(0.2))
                            .cornerRadius(4)
                    }
                }
                Text(item.statSummary)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Color(hex: "#A78BFA"))
                Text(item.flavorText)
                    .font(.system(size: 11))
                    .foregroundColor(.gray)
                if !meetsLevel && !isOwned {
                    Text("Requires Level \(item.requiredLevel)")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.red.opacity(0.8))
                }
            }

            Spacer()

            // Action
            VStack(spacing: 6) {
                if isOwned {
                    Button {
                        vm.equipItem(item)
                    } label: {
                        Text(isEquipped ? "✓" : "Equip")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(isEquipped ? .gray : .white)
                            .frame(width: 56, height: 30)
                            .background(
                                isEquipped
                                    ? Color.gray.opacity(0.2)
                                    : Color(hex: "#6C63FF").opacity(0.5)
                            )
                            .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                    .disabled(isEquipped)
                } else {
                    Button {
                        vm.buyItem(item)
                    } label: {
                        Text(item.price == 0 ? "Free" : "\(item.price)g")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(canBuy ? Color(hex: "#FFD700") : .gray)
                            .frame(width: 56, height: 30)
                            .background(
                                canBuy
                                    ? Color(hex: "#FFD700").opacity(0.2)
                                    : Color.white.opacity(0.06)
                            )
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .strokeBorder(
                                        canBuy
                                            ? Color(hex: "#FFD700").opacity(0.5)
                                            : Color.white.opacity(0.1),
                                        lineWidth: 1
                                    )
                            )
                    }
                    .buttonStyle(.plain)
                    .disabled(!canBuy)
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(
                    isEquipped ? Color(hex: "#6C63FF").opacity(0.1) : Color.white.opacity(0.05)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(
                            isEquipped ? Color(hex: "#6C63FF").opacity(0.4) : Color.white.opacity(0.08),
                            lineWidth: 1
                        )
                )
        )
        .opacity(meetsLevel || isOwned ? 1.0 : 0.55)
    }
}
