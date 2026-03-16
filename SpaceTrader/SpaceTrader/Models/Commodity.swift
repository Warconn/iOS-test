import Foundation

enum CommodityCategory: String, Codable, CaseIterable {
    case mineral    = "Mineral"
    case consumable = "Consumable"
    case tech       = "Tech"
    case luxury     = "Luxury"
}

struct Commodity: Identifiable, Codable, Equatable {
    let id: String
    let name: String
    let emoji: String
    let basePrice: Int
    let category: CommodityCategory

    static let catalog: [Commodity] = [
        // Minerals
        Commodity(id: "ore",           name: "Raw Ore",       emoji: "🪨", basePrice: 45,  category: .mineral),
        Commodity(id: "crystals",      name: "Crystals",      emoji: "💎", basePrice: 120, category: .mineral),
        Commodity(id: "rare_metals",   name: "Rare Metals",   emoji: "🔩", basePrice: 200, category: .mineral),
        // Consumables
        Commodity(id: "food",          name: "Food Rations",  emoji: "🌾", basePrice: 30,  category: .consumable),
        Commodity(id: "medicine",      name: "Medicine",      emoji: "💊", basePrice: 85,  category: .consumable),
        Commodity(id: "fuel_cells",    name: "Fuel Cells",    emoji: "⚡", basePrice: 65,  category: .consumable),
        // Tech
        Commodity(id: "components",    name: "Components",    emoji: "⚙️", basePrice: 155, category: .tech),
        Commodity(id: "ai_cores",      name: "AI Cores",      emoji: "🤖", basePrice: 360, category: .tech),
        // Luxury
        Commodity(id: "luxury_goods",  name: "Luxury Goods",  emoji: "💫", basePrice: 290, category: .luxury),
        Commodity(id: "exotic_matter", name: "Exotic Matter", emoji: "🌀", basePrice: 520, category: .luxury),
    ]

    static func find(_ id: String) -> Commodity? {
        catalog.first { $0.id == id }
    }
}

// MARK: – Market pricing constants
extension Commodity {
    /// Multipliers applied to basePrice based on supply/demand.
    enum PriceTier {
        case surplus   // Location produces this → cheap to buy, poor sell price
        case neutral   // Normal trade
        case demand    // Location needs this  → expensive to buy, great sell price

        var buyMultiplier:  Double { switch self { case .surplus: 0.55; case .neutral: 1.05; case .demand: 1.55 } }
        var sellMultiplier: Double { switch self { case .surplus: 0.40; case .neutral: 0.90; case .demand: 1.45 } }
    }

    func buyPrice(tier: PriceTier)  -> Int { max(1, Int(Double(basePrice) * tier.buyMultiplier)) }
    func sellPrice(tier: PriceTier) -> Int { max(1, Int(Double(basePrice) * tier.sellMultiplier)) }
}
