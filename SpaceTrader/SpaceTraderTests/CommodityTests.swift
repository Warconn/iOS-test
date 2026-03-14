import XCTest
@testable import SpaceTrader

final class CommodityTests: XCTestCase {

    func testCatalogNotEmpty() {
        XCTAssertFalse(Commodity.catalog.isEmpty)
    }

    func testCatalogHasTenItems() {
        XCTAssertEqual(Commodity.catalog.count, 10)
    }

    func testAllIDsUnique() {
        let ids = Commodity.catalog.map { $0.id }
        XCTAssertEqual(ids.count, Set(ids).count)
    }

    func testAllNamesNonEmpty() {
        for c in Commodity.catalog { XCTAssertFalse(c.name.isEmpty, "Empty name for \(c.id)") }
    }

    func testAllEmojisNonEmpty() {
        for c in Commodity.catalog { XCTAssertFalse(c.emoji.isEmpty, "Empty emoji for \(c.id)") }
    }

    func testAllBasePricesPositive() {
        for c in Commodity.catalog { XCTAssertGreaterThan(c.basePrice, 0) }
    }

    func testAllCategoriesRepresented() {
        let cats = Set(Commodity.catalog.map { $0.category })
        XCTAssertTrue(cats.contains(.mineral))
        XCTAssertTrue(cats.contains(.consumable))
        XCTAssertTrue(cats.contains(.tech))
        XCTAssertTrue(cats.contains(.luxury))
    }

    func testFindByIDReturnsCorrectCommodity() {
        let c = Commodity.find("ore")
        XCTAssertNotNil(c)
        XCTAssertEqual(c?.name, "Raw Ore")
    }

    func testFindMissingIDReturnsNil() {
        XCTAssertNil(Commodity.find("does_not_exist_xyz"))
    }

    // MARK: Pricing tiers

    func testSurplusBuyPriceLessThanBase() {
        let c = Commodity.find("ore")!
        let buyPrice = c.buyPrice(tier: .surplus)
        XCTAssertLessThan(buyPrice, c.basePrice)
    }

    func testSurplusSellPriceLessOrEqualBuyPrice() {
        for c in Commodity.catalog {
            let buy  = c.buyPrice(tier: .surplus)
            let sell = c.sellPrice(tier: .surplus)
            XCTAssertLessThanOrEqual(sell, buy, "Sell should not exceed buy for surplus (\(c.id))")
        }
    }

    func testDemandBuyPriceGreaterThanBase() {
        let c = Commodity.find("ore")!
        XCTAssertGreaterThan(c.buyPrice(tier: .demand), c.basePrice)
    }

    func testDemandSellPriceGreaterThanBase() {
        let c = Commodity.find("ore")!
        XCTAssertGreaterThan(c.sellPrice(tier: .demand), c.basePrice)
    }

    func testNeutralBuyPriceNearBase() {
        let c = Commodity.find("ore")!
        let buy = c.buyPrice(tier: .neutral)
        XCTAssertGreaterThanOrEqual(buy, c.basePrice)         // slight markup
        XCTAssertLessThan(Double(buy), Double(c.basePrice) * 1.20) // not too expensive
    }

    func testAllTierPricesArePositive() {
        for c in Commodity.catalog {
            for tier in [Commodity.PriceTier.surplus, .neutral, .demand] {
                XCTAssertGreaterThan(c.buyPrice(tier: tier),  0)
                XCTAssertGreaterThan(c.sellPrice(tier: tier), 0)
            }
        }
    }

    func testTradeProfitabilityRouteExists() {
        // Buy ore at mining surplus price, sell at industrial demand price → profit
        let ore = Commodity.find("ore")!
        let buyAtMining    = ore.buyPrice(tier: .surplus)
        let sellAtIndustry = ore.sellPrice(tier: .demand)
        XCTAssertGreaterThan(sellAtIndustry, buyAtMining, "Trade route must be profitable")
    }

    func testCommodityCodable() throws {
        let c    = Commodity.find("crystals")!
        let data = try JSONEncoder().encode(c)
        let back = try JSONDecoder().decode(Commodity.self, from: data)
        XCTAssertEqual(c, back)
    }
}
