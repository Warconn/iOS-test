import Foundation
import CoreGraphics

// MARK: – Location type

enum LocationType: String, Codable, CaseIterable {
    case tradingHub       = "tradingHub"
    case miningColony     = "miningColony"
    case agriculturalWorld = "agriculturalWorld"
    case industrialHub    = "industrialHub"
    case researchStation  = "researchStation"
    case fuelDepot        = "fuelDepot"
    case luxuryResort     = "luxuryResort"

    var displayName: String {
        switch self {
        case .tradingHub:        return "Trading Hub"
        case .miningColony:      return "Mining Colony"
        case .agriculturalWorld: return "Agricultural World"
        case .industrialHub:     return "Industrial Hub"
        case .researchStation:   return "Research Station"
        case .fuelDepot:         return "Fuel Depot"
        case .luxuryResort:      return "Luxury Resort"
        }
    }

    var emoji: String {
        switch self {
        case .tradingHub:        return "🏪"
        case .miningColony:      return "⛏️"
        case .agriculturalWorld: return "🌾"
        case .industrialHub:     return "🏭"
        case .researchStation:   return "🔬"
        case .fuelDepot:         return "⛽"
        case .luxuryResort:      return "💎"
        }
    }

    var mapColorHex: String {
        switch self {
        case .tradingHub:        return "#FFD700"
        case .miningColony:      return "#9E9E9E"
        case .agriculturalWorld: return "#4CAF50"
        case .industrialHub:     return "#FF9800"
        case .researchStation:   return "#2196F3"
        case .fuelDepot:         return "#FFEB3B"
        case .luxuryResort:      return "#E040FB"
        }
    }

    var isStation: Bool {
        switch self {
        case .tradingHub, .researchStation, .fuelDepot: return true
        default: return false
        }
    }

    /// IDs of commodities this location type PRODUCES (cheap to buy, poor sell)
    var surplusCommodities: [String] {
        switch self {
        case .tradingHub:        return []  // balanced
        case .miningColony:      return ["ore", "crystals", "rare_metals"]
        case .agriculturalWorld: return ["food", "medicine"]
        case .industrialHub:     return ["components", "fuel_cells"]
        case .researchStation:   return ["ai_cores", "exotic_matter"]
        case .fuelDepot:         return ["fuel_cells"]
        case .luxuryResort:      return ["luxury_goods"]
        }
    }

    /// IDs of commodities this location type NEEDS (expensive to buy, great to sell)
    var demandCommodities: [String] {
        switch self {
        case .tradingHub:        return []  // balanced
        case .miningColony:      return ["food", "medicine", "components"]
        case .agriculturalWorld: return ["components", "ai_cores", "fuel_cells"]
        case .industrialHub:     return ["ore", "rare_metals", "food"]
        case .researchStation:   return ["food", "rare_metals", "components"]
        case .fuelDepot:         return ["ore", "components", "food"]
        case .luxuryResort:      return ["food", "medicine", "ai_cores", "exotic_matter"]
        }
    }

    func priceTier(for commodityId: String) -> Commodity.PriceTier {
        if surplusCommodities.contains(commodityId) { return .surplus }
        if demandCommodities.contains(commodityId)  { return .demand  }
        return .neutral
    }
}

// MARK: – Market listing

struct MarketListing: Codable, Equatable {
    let commodityId: String
    var buyPrice: Int    // Player PAYS this to buy from station
    var sellPrice: Int   // Player RECEIVES this when selling to station
    var stationStock: Int  // Units available to buy (regenerates over time)

    /// Apply small random fluctuation ±8% without crossing tier boundaries
    mutating func fluctuate(using rng: inout SeededRandom) {
        let factor = 1.0 + (rng.nextDouble() * 0.16 - 0.08)
        buyPrice  = max(1, Int(Double(buyPrice)  * factor))
        sellPrice = max(1, Int(Double(sellPrice) * factor))
    }
}

// MARK: – Location

struct Location: Identifiable, Codable {
    let id: String
    let name: String
    let type: LocationType
    var posX: CGFloat   // Universe coordinates (0…8000)
    var posY: CGFloat
    var isDiscovered: Bool = false
    var visitCount: Int = 0
    var market: [MarketListing]
    var lastMarketSeed: UInt64 = 0

    var position: CGPoint { CGPoint(x: posX, y: posY) }

    static func buildMarket(type: LocationType, seed: UInt64) -> [MarketListing] {
        var rng = SeededRandom(seed: seed)
        return Commodity.catalog.map { commodity in
            let tier = type.priceTier(for: commodity.id)
            var listing = MarketListing(
                commodityId: commodity.id,
                buyPrice:  commodity.buyPrice(tier: tier),
                sellPrice: commodity.sellPrice(tier: tier),
                stationStock: tier == .surplus ? rng.nextInt(in: 20..<60) : rng.nextInt(in: 5..<20)
            )
            listing.fluctuate(using: &rng)
            return listing
        }
    }

    mutating func refreshMarket() {
        lastMarketSeed = lastMarketSeed &+ 1
        var rng = SeededRandom(seed: lastMarketSeed)
        for i in 0..<market.count {
            market[i].fluctuate(using: &rng)
            // Restock
            let commodity = Commodity.catalog[i]
            let tier = type.priceTier(for: commodity.id)
            if market[i].stationStock < 5 {
                market[i].stationStock += tier == .surplus ? 20 : 8
            }
        }
    }

    func listing(for commodityId: String) -> MarketListing? {
        market.first { $0.commodityId == commodityId }
    }
}
