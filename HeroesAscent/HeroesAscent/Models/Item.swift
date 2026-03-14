import Foundation

enum ItemType: String, Codable, CaseIterable {
    case weapon    = "weapon"
    case armor     = "armor"
    case accessory = "accessory"

    var displayName: String {
        switch self {
        case .weapon:    return "Weapon"
        case .armor:     return "Armor"
        case .accessory: return "Accessory"
        }
    }

    var slotEmoji: String {
        switch self {
        case .weapon:    return "⚔️"
        case .armor:     return "🛡️"
        case .accessory: return "💎"
        }
    }
}

struct Item: Codable, Identifiable, Equatable {
    let id: String
    let name: String
    let type: ItemType
    let attackBonus: Int
    let defenseBonus: Int
    let hpBonus: Int
    let price: Int
    let requiredLevel: Int
    let emoji: String
    let flavorText: String

    var statSummary: String {
        var parts: [String] = []
        if attackBonus  != 0 { parts.append("+\(attackBonus) ATK") }
        if defenseBonus != 0 { parts.append("+\(defenseBonus) DEF") }
        if hpBonus      != 0 { parts.append("+\(hpBonus) HP") }
        return parts.isEmpty ? "No bonus" : parts.joined(separator: "  ")
    }

    static let catalog: [Item] = [
        // MARK: Weapons
        Item(id: "stick",     name: "Wooden Stick",   type: .weapon, attackBonus: 2,  defenseBonus: 0, hpBonus: 0,   price: 0,    requiredLevel: 1,  emoji: "🪵", flavorText: "Better than bare hands"),
        Item(id: "sword1",    name: "Iron Sword",     type: .weapon, attackBonus: 8,  defenseBonus: 0, hpBonus: 0,   price: 80,   requiredLevel: 1,  emoji: "🗡️", flavorText: "A trusty iron blade"),
        Item(id: "sword2",    name: "Steel Sword",    type: .weapon, attackBonus: 20, defenseBonus: 0, hpBonus: 0,   price: 280,  requiredLevel: 5,  emoji: "⚔️", flavorText: "Forged by master smiths"),
        Item(id: "sword3",    name: "Runic Blade",    type: .weapon, attackBonus: 42, defenseBonus: 0, hpBonus: 0,   price: 900,  requiredLevel: 12, emoji: "🔯", flavorText: "Etched with ancient power"),
        Item(id: "sword4",    name: "Dragon Slayer",  type: .weapon, attackBonus: 80, defenseBonus: 0, hpBonus: 0,   price: 3000, requiredLevel: 22, emoji: "🔱", flavorText: "Forged from dragon scales"),
        Item(id: "sword5",    name: "Void Blade",     type: .weapon, attackBonus: 140,defenseBonus: 0, hpBonus: 0,   price: 9000, requiredLevel: 35, emoji: "⚡", flavorText: "Born from the void itself"),

        // MARK: Armor
        Item(id: "robe",      name: "Cloth Robe",     type: .armor, attackBonus: 0, defenseBonus: 3,  hpBonus: 20,  price: 0,    requiredLevel: 1,  emoji: "👘", flavorText: "Barely counts as armor"),
        Item(id: "leather",   name: "Leather Vest",   type: .armor, attackBonus: 0, defenseBonus: 8,  hpBonus: 50,  price: 120,  requiredLevel: 1,  emoji: "🦺", flavorText: "Tough enough for beginners"),
        Item(id: "chain",     name: "Chainmail",      type: .armor, attackBonus: 0, defenseBonus: 20, hpBonus: 100, price: 450,  requiredLevel: 6,  emoji: "🛡️", flavorText: "Rings of interlocked steel"),
        Item(id: "plate",     name: "Plate Armor",    type: .armor, attackBonus: 0, defenseBonus: 40, hpBonus: 200, price: 1400, requiredLevel: 14, emoji: "⚜️", flavorText: "Nearly impenetrable"),
        Item(id: "dragon_sc", name: "Dragon Scale",   type: .armor, attackBonus: 0, defenseBonus: 75, hpBonus: 400, price: 4500, requiredLevel: 25, emoji: "🐲", flavorText: "Shed by a great dragon"),
        Item(id: "void_mail", name: "Void Plate",     type: .armor, attackBonus: 0, defenseBonus: 130,hpBonus: 700, price: 12000,requiredLevel: 38, emoji: "🌑", flavorText: "Armor woven from darkness"),

        // MARK: Accessories
        Item(id: "pebble",    name: "Lucky Pebble",   type: .accessory, attackBonus: 1,  defenseBonus: 1,  hpBonus: 10,  price: 0,    requiredLevel: 1,  emoji: "🪨", flavorText: "Found on the road"),
        Item(id: "ring_atk",  name: "Warrior's Ring", type: .accessory, attackBonus: 6,  defenseBonus: 0,  hpBonus: 0,   price: 180,  requiredLevel: 1,  emoji: "💍", flavorText: "Sharpens the fighting spirit"),
        Item(id: "ring_def",  name: "Guardian Ring",  type: .accessory, attackBonus: 0,  defenseBonus: 6,  hpBonus: 40,  price: 180,  requiredLevel: 1,  emoji: "🔮", flavorText: "Protects the wearer"),
        Item(id: "amulet1",   name: "Hero's Amulet",  type: .accessory, attackBonus: 15, defenseBonus: 8,  hpBonus: 80,  price: 700,  requiredLevel: 9,  emoji: "📿", flavorText: "Balanced power and defense"),
        Item(id: "crest",     name: "Champion Crest", type: .accessory, attackBonus: 30, defenseBonus: 18, hpBonus: 160, price: 2200, requiredLevel: 18, emoji: "🏆", flavorText: "Mark of a true champion"),
        Item(id: "void_eye",  name: "Void Eye",       type: .accessory, attackBonus: 60, defenseBonus: 35, hpBonus: 300, price: 7000, requiredLevel: 32, emoji: "👁️", flavorText: "Sees beyond reality"),
    ]

    static func items(ofType type: ItemType) -> [Item] {
        catalog.filter { $0.type == type }
    }

    static func item(id: String) -> Item? {
        catalog.first { $0.id == id }
    }
}
