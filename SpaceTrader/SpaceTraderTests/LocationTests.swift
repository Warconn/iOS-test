import XCTest
@testable import SpaceTrader

final class LocationTests: XCTestCase {

    // MARK: – LocationType

    func testAllLocationTypesHaveDisplayNames() {
        for t in LocationType.allCases { XCTAssertFalse(t.displayName.isEmpty) }
    }

    func testAllLocationTypesHaveEmojis() {
        for t in LocationType.allCases { XCTAssertFalse(t.emoji.isEmpty) }
    }

    func testAllLocationTypesHaveMapColors() {
        for t in LocationType.allCases { XCTAssertFalse(t.mapColorHex.isEmpty) }
    }

    func testMiningColonyProducesOre() {
        XCTAssertTrue(LocationType.miningColony.surplusCommodities.contains("ore"))
    }

    func testMiningColonyNeedsFood() {
        XCTAssertTrue(LocationType.miningColony.demandCommodities.contains("food"))
    }

    func testAgriculturalWorldProducesFood() {
        XCTAssertTrue(LocationType.agriculturalWorld.surplusCommodities.contains("food"))
    }

    func testIndustrialHubProducesComponents() {
        XCTAssertTrue(LocationType.industrialHub.surplusCommodities.contains("components"))
    }

    func testIndustrialHubNeedsOre() {
        XCTAssertTrue(LocationType.industrialHub.demandCommodities.contains("ore"))
    }

    func testFuelDepotProducesFuelCells() {
        XCTAssertTrue(LocationType.fuelDepot.surplusCommodities.contains("fuel_cells"))
    }

    func testTradingHubHasNoSpecialty() {
        XCTAssertTrue(LocationType.tradingHub.surplusCommodities.isEmpty)
        XCTAssertTrue(LocationType.tradingHub.demandCommodities.isEmpty)
    }

    func testPriceTierForSurplusCommodity() {
        let tier = LocationType.miningColony.priceTier(for: "ore")
        XCTAssertEqual(tier, .surplus)
    }

    func testPriceTierForDemandCommodity() {
        let tier = LocationType.miningColony.priceTier(for: "food")
        XCTAssertEqual(tier, .demand)
    }

    func testPriceTierForNeutralCommodity() {
        let tier = LocationType.miningColony.priceTier(for: "luxury_goods")
        XCTAssertEqual(tier, .neutral)
    }

    func testIsStationFlags() {
        XCTAssertTrue(LocationType.tradingHub.isStation)
        XCTAssertTrue(LocationType.researchStation.isStation)
        XCTAssertFalse(LocationType.miningColony.isStation)
        XCTAssertFalse(LocationType.agriculturalWorld.isStation)
    }

    // MARK: – Market building

    func testBuildMarketHasAllCommodities() {
        let market = Location.buildMarket(type: .miningColony, seed: 123)
        XCTAssertEqual(market.count, Commodity.catalog.count)
    }

    func testBuildMarketSurplusIsChapForBuyer() {
        let market = Location.buildMarket(type: .miningColony, seed: 456)
        let oreListing = market.first { $0.commodityId == "ore" }
        XCTAssertNotNil(oreListing)
        let ore = Commodity.find("ore")!
        // Surplus buy price should be well below base (before fluctuation: ~55% of base)
        XCTAssertLessThan(Double(oreListing!.buyPrice), Double(ore.basePrice) * 0.80)
    }

    func testBuildMarketDemandIsExpensiveForBuyer() {
        let market = Location.buildMarket(type: .miningColony, seed: 789)
        let foodListing = market.first { $0.commodityId == "food" }
        XCTAssertNotNil(foodListing)
        let food = Commodity.find("food")!
        XCTAssertGreaterThan(Double(foodListing!.buyPrice), Double(food.basePrice))
    }

    func testBuildMarketSellPriceLessThanBuyPrice() {
        let market = Location.buildMarket(type: .tradingHub, seed: 999)
        for listing in market {
            XCTAssertLessThan(listing.sellPrice, listing.buyPrice,
                              "Station always sells at a premium: sell < buy (\(listing.commodityId))")
        }
    }

    func testMarketListingCodable() throws {
        let market = Location.buildMarket(type: .industrialHub, seed: 0)
        let data   = try JSONEncoder().encode(market)
        let back   = try JSONDecoder().decode([MarketListing].self, from: data)
        XCTAssertEqual(market.count, back.count)
        XCTAssertEqual(market[0].buyPrice, back[0].buyPrice)
    }

    // MARK: – Commodity.PriceTier equality (needed for tests above)
}

extension Commodity.PriceTier: Equatable {}
