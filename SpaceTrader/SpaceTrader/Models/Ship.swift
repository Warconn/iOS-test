import Foundation
import CoreGraphics

// MARK: – Cargo

struct CargoItem: Codable, Identifiable {
    var id: String { commodityId }
    let commodityId: String
    var quantity: Int
}

// MARK: – Upgrade

enum ShipUpgrade: String, Codable, CaseIterable {
    case engine   = "engine"
    case cargo    = "cargo"
    case scanner  = "scanner"
    case fuelTank = "fuelTank"

    var displayName: String {
        switch self {
        case .engine:   return "Engine"
        case .cargo:    return "Cargo Hold"
        case .scanner:  return "Scanner"
        case .fuelTank: return "Fuel Tank"
        }
    }

    var emoji: String {
        switch self {
        case .engine:   return "🚀"
        case .cargo:    return "📦"
        case .scanner:  return "📡"
        case .fuelTank: return "⛽"
        }
    }

    var description: String {
        switch self {
        case .engine:   return "Increases max speed"
        case .cargo:    return "Adds 4 cargo slots"
        case .scanner:  return "Increases discovery range"
        case .fuelTank: return "Increases max fuel capacity"
        }
    }

    static let upgradeCosts: [Int] = [800, 2200, 5500, 13000]  // Level 2→3→4→5

    func cost(toUpgradeFrom level: Int) -> Int? {
        guard level >= 1 && level < 5 else { return nil }
        return Self.upgradeCosts[level - 1]
    }
}

// MARK: – Journal entry

struct JournalEntry: Identifiable, Codable {
    let id: UUID
    let timestamp: Date
    let message: String
    let type: EntryType

    enum EntryType: String, Codable {
        case discovery, trade, upgrade, arrival, system
    }

    init(_ message: String, type: EntryType = .system) {
        self.id        = UUID()
        self.timestamp = Date()
        self.message   = message
        self.type      = type
    }
}

// MARK: – Ship

struct Ship: Codable {
    // Position stored as scalars for Codable safety
    var posX: CGFloat = 12500
    var posY: CGFloat = 12500
    var heading: CGFloat = 0  // radians; 0 = up, increases clockwise

    // Physics drift velocity (world units / second)
    var velX: CGFloat = 0
    var velY: CGFloat = 0

    var credits: Int = 500
    var cargo: [CargoItem] = []
    var fuel: Double = 110.0

    // Upgrade levels (1–5)
    var engineLevel:   Int = 1
    var cargoLevel:    Int = 1
    var scannerLevel:  Int = 1
    var fuelTankLevel: Int = 1

    var currentLocationId: String? = "start"  // nil = in space

    // MARK: Computed properties

    var position: CGPoint {
        get { CGPoint(x: posX, y: posY) }
        set { posX = newValue.x; posY = newValue.y }
    }

    /// Max travel speed in universe units per second
    var maxSpeed: CGFloat { CGFloat(190 + engineLevel * 50) }
    // 1→240  2→290  3→340  4→390  5→440

    var maxCargo: Int { 4 + cargoLevel * 4 }
    // 1→8  2→12  3→16  4→20  5→24

    var scannerRange: CGFloat { CGFloat(1000 + scannerLevel * 500) }
    // 1→1500  2→2000  3→2500  4→3000  5→3500

    var maxFuel: Double { Double(80 + fuelTankLevel * 30) }
    // 1→110  2→140  3→170  4→200  5→230

    var fuelConsumptionRate: Double { 0.3 }  // units per second at full throttle

    var cargoUsed: Int { cargo.reduce(0) { $0 + $1.quantity } }
    var cargoFree: Int { maxCargo - cargoUsed }
    var fuelPercent: Double { maxFuel > 0 ? fuel / maxFuel : 0 }
    var isDocked: Bool { currentLocationId != nil }

    // MARK: Cargo operations

    mutating func addCargo(_ id: String, quantity: Int) {
        if let i = cargo.firstIndex(where: { $0.commodityId == id }) {
            cargo[i].quantity += quantity
        } else {
            cargo.append(CargoItem(commodityId: id, quantity: quantity))
        }
    }

    @discardableResult
    mutating func removeCargo(_ id: String, quantity: Int) -> Bool {
        guard let i = cargo.firstIndex(where: { $0.commodityId == id }),
              cargo[i].quantity >= quantity else { return false }
        cargo[i].quantity -= quantity
        if cargo[i].quantity == 0 { cargo.remove(at: i) }
        return true
    }

    func cargoQuantity(of id: String) -> Int {
        cargo.first { $0.commodityId == id }?.quantity ?? 0
    }

    // MARK: Upgrade

    mutating func upgrade(_ type: ShipUpgrade) {
        switch type {
        case .engine:   engineLevel   = min(5, engineLevel + 1)
        case .cargo:    cargoLevel    = min(5, cargoLevel + 1)
        case .scanner:  scannerLevel  = min(5, scannerLevel + 1)
        case .fuelTank:
            fuelTankLevel = min(5, fuelTankLevel + 1)
            fuel = min(fuel + 30, maxFuel)  // refill the additional capacity
        }
    }

    func upgradeLevel(for type: ShipUpgrade) -> Int {
        switch type {
        case .engine:   return engineLevel
        case .cargo:    return cargoLevel
        case .scanner:  return scannerLevel
        case .fuelTank: return fuelTankLevel
        }
    }

    func nextLevelDescription(for type: ShipUpgrade) -> String {
        let next = upgradeLevel(for: type) + 1
        switch type {
        case .engine:   return "Max speed: \(190 + next * 50) u/s"
        case .cargo:    return "Cargo slots: \(4 + next * 4)"
        case .scanner:  return "Scanner range: \(1000 + next * 500) units"
        case .fuelTank: return "Max fuel: \(80 + next * 30)"
        }
    }
}
