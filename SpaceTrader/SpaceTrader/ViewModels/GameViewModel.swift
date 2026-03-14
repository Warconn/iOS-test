import SwiftUI
import CoreGraphics

@MainActor
final class GameViewModel: ObservableObject {

    // MARK: – Published state
    @Published var ship: Ship
    @Published var universe: [Location]
    @Published var joystickVector: CGPoint = .zero
    @Published var nearbyLocation: Location? = nil
    @Published var showingStation: Bool = false
    @Published var journal: [JournalEntry] = []
    @Published var notification: String? = nil
    @Published var backgroundStars: [BackgroundStar] = []

    // MARK: – Private
    private var gameTimer: Timer?
    private var lastTick: Date = Date()
    private let saveKey = "spacetrader_v1"
    private var notificationTimer: Timer?

    struct BackgroundStar: Identifiable {
        let id = UUID()
        let x, y, size: CGFloat
        let opacity: Double
    }

    // MARK: – Init
    init() {
        if let save = Self.load() {
            ship     = save.ship
            universe = save.universe
            journal  = save.journal
        } else {
            ship     = Ship()
            universe = Universe.generate()
            // Discover starting neighbors
            var s = Ship()
            let start = universe.first { $0.id == "start" }!
            s.position = start.position
            ship = s
        }

        // Generate random background stars (screen-space, not world-space)
        backgroundStars = (0..<220).map { _ in
            BackgroundStar(
                x: CGFloat.random(in: 0...430),
                y: CGFloat.random(in: 0...900),
                size: CGFloat.random(in: 0.6...2.2),
                opacity: Double.random(in: 0.15...0.85)
            )
        }

        discoverNear(ship.position, range: ship.scannerRange)
        startGameLoop()
    }

    // MARK: – Game loop

    func startGameLoop() {
        let timer = Timer(timeInterval: 1.0 / 30.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in self?.tick() }
        }
        RunLoop.main.add(timer, forMode: .common)
        gameTimer = timer
        lastTick = Date()
    }

    private func tick() {
        let now  = Date()
        let dt   = min(now.timeIntervalSince(lastTick), 0.1) // cap at 100ms
        lastTick = now

        guard !ship.isDocked else { return }

        let throttle = joystickVector.magnitude
        guard throttle > 0.05 else { return }

        // Move ship
        let speed  = ship.maxSpeed * CGFloat(throttle)
        let normX  = joystickVector.x / max(throttle, 0.001)
        let normY  = joystickVector.y / max(throttle, 0.001)
        let newX   = (ship.posX + normX * speed * CGFloat(dt)).clamped(to: 50...Universe.size - 50)
        let newY   = (ship.posY + normY * speed * CGFloat(dt)).clamped(to: 50...Universe.size - 50)
        ship.posX  = newX
        ship.posY  = newY

        // Update heading (visual direction ship faces)
        ship.heading = atan2(joystickVector.y, joystickVector.x) + .pi / 2

        // Consume fuel
        if ship.fuel > 0 {
            ship.fuel = max(0, ship.fuel - throttle * ship.fuelConsumptionRate * dt)
        }

        // Discover locations in scanner range
        discoverNear(ship.position, range: ship.scannerRange)

        // Check for dockable location
        let dockable = universe.first {
            $0.isDiscovered && $0.position.distance(to: ship.position) < 55
        }
        if dockable?.id != nearbyLocation?.id {
            withAnimation(.easeInOut(duration: 0.3)) { nearbyLocation = dockable }
        }
    }

    private func discoverNear(_ pos: CGPoint, range: CGFloat) {
        for i in 0..<universe.count {
            guard !universe[i].isDiscovered else { continue }
            if universe[i].position.distance(to: pos) <= range {
                universe[i].isDiscovered = true
                postNotification("Discovered \(universe[i].name)!")
                journal.insert(JournalEntry("Discovered \(universe[i].name) · \(universe[i].type.displayName)", type: .discovery), at: 0)
            }
        }
    }

    // MARK: – Docking

    func dock() {
        guard let loc = nearbyLocation else { return }
        gameTimer?.invalidate()
        gameTimer = nil
        joystickVector = .zero
        ship.currentLocationId = loc.id
        if let i = universe.firstIndex(where: { $0.id == loc.id }) {
            universe[i].visitCount += 1
            universe[i].refreshMarket()
        }
        journal.insert(JournalEntry("Arrived at \(loc.name)", type: .arrival), at: 0)
        showingStation = true
        save()
    }

    func undock() {
        ship.currentLocationId = nil
        showingStation = false
        lastTick = Date()
        startGameLoop()
    }

    // MARK: – Trading

    func buy(commodityId: String, quantity: Int) {
        guard let locId = ship.currentLocationId,
              let li = universe.firstIndex(where: { $0.id == locId }),
              let mi = universe[li].market.firstIndex(where: { $0.commodityId == commodityId })
        else { return }

        let listing = universe[li].market[mi]
        let totalCost = listing.buyPrice * quantity
        guard ship.credits >= totalCost, ship.cargoFree >= quantity,
              listing.stationStock >= quantity else { return }

        ship.credits -= totalCost
        ship.addCargo(commodityId, quantity: quantity)
        universe[li].market[mi].stationStock -= quantity
        let name = Commodity.find(commodityId)?.name ?? commodityId
        journal.insert(JournalEntry("Bought \(quantity)× \(name) for \(totalCost)cr", type: .trade), at: 0)
        postNotification("Bought \(quantity)× \(name)")
        save()
    }

    func sell(commodityId: String, quantity: Int) {
        guard let locId = ship.currentLocationId,
              let li = universe.firstIndex(where: { $0.id == locId }),
              let mi = universe[li].market.firstIndex(where: { $0.commodityId == commodityId })
        else { return }

        let listing = universe[li].market[mi]
        guard ship.cargoQuantity(of: commodityId) >= quantity else { return }

        let revenue = listing.sellPrice * quantity
        ship.credits += revenue
        ship.removeCargo(commodityId, quantity: quantity)
        universe[li].market[mi].stationStock += quantity
        let name = Commodity.find(commodityId)?.name ?? commodityId
        journal.insert(JournalEntry("Sold \(quantity)× \(name) for \(revenue)cr", type: .trade), at: 0)
        postNotification("Sold \(quantity)× \(name) for \(revenue)cr")
        save()
    }

    func refuel() {
        guard let locId = ship.currentLocationId else { return }
        let fuelNeeded = ship.maxFuel - ship.fuel
        guard fuelNeeded > 0.5 else { return }
        let cost = max(1, Int(fuelNeeded * 2.0))   // 2cr per fuel unit
        guard ship.credits >= cost else { return }
        ship.credits -= cost
        ship.fuel = ship.maxFuel
        journal.insert(JournalEntry("Refuelled for \(cost)cr at \(currentLocation?.name ?? "station")", type: .system), at: 0)
        postNotification("Refuelled for \(cost)cr")
        save()
    }

    // MARK: – Upgrades

    func upgrade(_ type: ShipUpgrade) {
        let level = ship.upgradeLevel(for: type)
        guard level < 5, let cost = type.cost(toUpgradeFrom: level) else { return }
        guard ship.credits >= cost else { return }
        ship.credits -= cost
        ship.upgrade(type)
        journal.insert(JournalEntry("Upgraded \(type.displayName) to level \(ship.upgradeLevel(for: type))", type: .upgrade), at: 0)
        postNotification("\(type.displayName) Lv.\(ship.upgradeLevel(for: type)) installed!")
        save()
    }

    // MARK: – Helpers

    var currentLocation: Location? {
        guard let id = ship.currentLocationId else { return nil }
        return universe.first { $0.id == id }
    }

    var currentMarket: [MarketListing] {
        currentLocation?.market ?? []
    }

    // MARK: – Notifications

    private func postNotification(_ message: String) {
        notificationTimer?.invalidate()
        withAnimation { notification = message }
        notificationTimer = Timer.scheduledTimer(withTimeInterval: 2.5, repeats: false) { [weak self] _ in
            Task { @MainActor [weak self] in
                withAnimation { self?.notification = nil }
            }
        }
    }

    // MARK: – Persistence

    struct SaveData: Codable {
        var ship: Ship
        var universe: [Location]
        var journal: [JournalEntry]
    }

    func save() {
        guard let data = try? JSONEncoder().encode(SaveData(ship: ship, universe: universe, journal: Array(journal.prefix(100)))) else { return }
        UserDefaults.standard.set(data, forKey: saveKey)
    }

    static func load() -> SaveData? {
        guard let data = UserDefaults.standard.data(forKey: "spacetrader_v1"),
              let save = try? JSONDecoder().decode(SaveData.self, from: data) else { return nil }
        return save
    }

    func resetGame() {
        gameTimer?.invalidate()
        gameTimer = nil
        UserDefaults.standard.removeObject(forKey: saveKey)
        ship = Ship()
        universe = Universe.generate()
        journal = []
        joystickVector = .zero
        nearbyLocation = nil
        showingStation = false
        discoverNear(ship.position, range: ship.scannerRange)
        startGameLoop()
    }

    deinit {
        gameTimer?.invalidate()
        notificationTimer?.invalidate()
    }
}

// MARK: – CGFloat clamping helper
extension CGFloat {
    func clamped(to range: ClosedRange<CGFloat>) -> CGFloat {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
