import XCTest
@testable import HeroesAscent

final class ItemTests: XCTestCase {

    // MARK: – Catalog integrity
    func testCatalogIsNotEmpty() {
        XCTAssertFalse(Item.catalog.isEmpty)
    }

    func testAllItemsHaveUniqueIDs() {
        let ids = Item.catalog.map { $0.id }
        let uniqueIDs = Set(ids)
        XCTAssertEqual(ids.count, uniqueIDs.count, "Duplicate item IDs found")
    }

    func testAllItemsHaveNames() {
        for item in Item.catalog {
            XCTAssertFalse(item.name.isEmpty, "Item \(item.id) has empty name")
        }
    }

    func testAllItemsHaveEmojis() {
        for item in Item.catalog {
            XCTAssertFalse(item.emoji.isEmpty, "Item \(item.id) has empty emoji")
        }
    }

    func testAllItemTypesRepresented() {
        let types = Set(Item.catalog.map { $0.type })
        XCTAssertTrue(types.contains(.weapon))
        XCTAssertTrue(types.contains(.armor))
        XCTAssertTrue(types.contains(.accessory))
    }

    func testRequiredLevelIsAtLeastOne() {
        for item in Item.catalog {
            XCTAssertGreaterThanOrEqual(item.requiredLevel, 1, "Item \(item.id) has invalid level")
        }
    }

    func testPriceIsNonNegative() {
        for item in Item.catalog {
            XCTAssertGreaterThanOrEqual(item.price, 0, "Item \(item.id) has negative price")
        }
    }

    func testEachItemHasAtLeastOneStatBonus() {
        for item in Item.catalog {
            let total = item.attackBonus + item.defenseBonus + item.hpBonus
            XCTAssertGreaterThan(total, 0, "Item \(item.id) has no stat bonuses")
        }
    }

    // MARK: – Filtering
    func testFilterByWeapon() {
        let weapons = Item.items(ofType: .weapon)
        XCTAssertFalse(weapons.isEmpty)
        XCTAssertTrue(weapons.allSatisfy { $0.type == .weapon })
    }

    func testFilterByArmor() {
        let armor = Item.items(ofType: .armor)
        XCTAssertFalse(armor.isEmpty)
        XCTAssertTrue(armor.allSatisfy { $0.type == .armor })
    }

    func testFilterByAccessory() {
        let accessories = Item.items(ofType: .accessory)
        XCTAssertFalse(accessories.isEmpty)
        XCTAssertTrue(accessories.allSatisfy { $0.type == .accessory })
    }

    func testFindItemByID() {
        let item = Item.item(id: "sword1")
        XCTAssertNotNil(item)
        XCTAssertEqual(item?.name, "Iron Sword")
    }

    func testFindNonExistentItemReturnsNil() {
        let item = Item.item(id: "does_not_exist_xyz")
        XCTAssertNil(item)
    }

    // MARK: – Stat summary
    func testStatSummaryWeapon() {
        let sword = Item.item(id: "sword1")!
        XCTAssertTrue(sword.statSummary.contains("ATK"))
    }

    func testStatSummaryArmor() {
        let armor = Item.item(id: "leather")!
        XCTAssertTrue(armor.statSummary.contains("DEF"))
    }

    // MARK: – Starter items exist
    func testStarterItemsExist() {
        XCTAssertNotNil(Item.item(id: "stick"), "Starter weapon 'stick' must exist")
        XCTAssertNotNil(Item.item(id: "robe"),  "Starter armor 'robe' must exist")
        XCTAssertNotNil(Item.item(id: "pebble"),"Starter accessory 'pebble' must exist")
    }

    func testStarterItemsAreFree() {
        XCTAssertEqual(Item.item(id: "stick")?.price,  0)
        XCTAssertEqual(Item.item(id: "robe")?.price,   0)
        XCTAssertEqual(Item.item(id: "pebble")?.price, 0)
    }

    // MARK: – ItemType
    func testItemTypeDisplayNames() {
        XCTAssertFalse(ItemType.weapon.displayName.isEmpty)
        XCTAssertFalse(ItemType.armor.displayName.isEmpty)
        XCTAssertFalse(ItemType.accessory.displayName.isEmpty)
    }

    func testItemTypeSlotEmojis() {
        XCTAssertFalse(ItemType.weapon.slotEmoji.isEmpty)
        XCTAssertFalse(ItemType.armor.slotEmoji.isEmpty)
        XCTAssertFalse(ItemType.accessory.slotEmoji.isEmpty)
    }

    func testItemTypeCodable() throws {
        let type = ItemType.weapon
        let data = try JSONEncoder().encode(type)
        let decoded = try JSONDecoder().decode(ItemType.self, from: data)
        XCTAssertEqual(type, decoded)
    }

    // MARK: – Item Codable
    func testItemCodableRoundTrip() throws {
        let item = Item.item(id: "sword2")!
        let data = try JSONEncoder().encode(item)
        let decoded = try JSONDecoder().decode(Item.self, from: data)
        XCTAssertEqual(item, decoded)
    }
}
