import Foundation
import CoreGraphics

// MARK: – Deterministic seeded RNG (Knuth LCG)
struct SeededRandom {
    private var state: UInt64

    init(seed: UInt64 = 42) { state = seed == 0 ? 1 : seed }

    mutating func nextUInt64() -> UInt64 {
        state = state &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
        return state
    }

    mutating func nextDouble() -> Double {
        Double(nextUInt64()) / Double(UInt64.max)
    }

    mutating func nextFloat(in range: ClosedRange<CGFloat>) -> CGFloat {
        range.lowerBound + CGFloat(nextDouble()) * (range.upperBound - range.lowerBound)
    }

    mutating func nextInt(in range: Range<Int>) -> Int {
        guard range.count > 0 else { return range.lowerBound }
        return range.lowerBound + Int(nextUInt64() % UInt64(range.count))
    }

    mutating func pick<T>(from array: [T]) -> T {
        array[nextInt(in: 0..<array.count)]
    }
}

// MARK: – CGPoint helpers
extension CGPoint {
    func distance(to other: CGPoint) -> CGFloat {
        let dx = x - other.x, dy = y - other.y
        return sqrt(dx * dx + dy * dy)
    }
    var magnitude: CGFloat { sqrt(x * x + y * y) }
}

// MARK: – Universe generation

enum Universe {
    static let size: CGFloat = 8000
    static let minimumSpacing: CGFloat = 280
    static let locationCount: Int = 75
    static let universeSeed: UInt64 = 0xDEADBEEF_C0FFEE42

    // Name components
    private static let prefixes = [
        "Alpha","Beta","Nova","Proxima","Kepler","Vega","Sirius","Rigel",
        "Altair","Castor","Deneb","Antares","Spica","Zeta","Theta","Delta",
        "Epsilon","Mira","Arcturus","Capella","Algol","Regulus","Canopus",
        "Pollux","Hadar","Achernar","Acrux","Betelgeuse","Aldebaran","Orion",
    ]
    private static let suffixes = [
        "Prime","Station","Colony","Outpost","Haven","Nexus","Base","Port",
        "Depot","Hub","IV","VII","II","IX","Major","Minor","Terminus",
        "Crossing","Relay","Gate","Forge","Deep","Drift","Rise","Reach",
    ]

    static func generate() -> [Location] {
        var rng = SeededRandom(seed: universeSeed)
        var locations: [Location] = []

        // 1. Always start with Trading Hub at the center
        let startMarket = Location.buildMarket(type: .tradingHub, seed: rng.nextUInt64())
        let start = Location(
            id: "start",
            name: "Sol Nexus",
            type: .tradingHub,
            posX: size / 2,
            posY: size / 2,
            isDiscovered: true,
            visitCount: 1,
            market: startMarket,
            lastMarketSeed: 0
        )
        locations.append(start)

        // 2. Define type distribution
        let typePool: [LocationType] = [
            .miningColony, .miningColony, .miningColony,
            .agriculturalWorld, .agriculturalWorld, .agriculturalWorld,
            .industrialHub, .industrialHub, .industrialHub,
            .researchStation, .researchStation,
            .fuelDepot, .fuelDepot, .fuelDepot,
            .luxuryResort, .luxuryResort,
            .tradingHub, .tradingHub,
        ]

        // 3. Poisson-disk-like rejection sampling
        var usedNames: Set<String> = ["Sol Nexus"]
        var attempts = 0
        while locations.count < locationCount && attempts < locationCount * 40 {
            attempts += 1
            let px = rng.nextFloat(in: 200...size - 200)
            let py = rng.nextFloat(in: 200...size - 200)
            let pos = CGPoint(x: px, y: py)

            guard locations.allSatisfy({ $0.position.distance(to: pos) >= minimumSpacing }) else { continue }

            let type = rng.pick(from: typePool)
            var name = buildName(rng: &rng)
            var nameRetries = 0
            while usedNames.contains(name) && nameRetries < 10 {
                name = buildName(rng: &rng)
                nameRetries += 1
            }
            usedNames.insert(name)
            let seed = rng.nextUInt64()
            let loc = Location(
                id: "loc_\(locations.count)",
                name: name,
                type: type,
                posX: px,
                posY: py,
                isDiscovered: false,
                visitCount: 0,
                market: Location.buildMarket(type: type, seed: seed),
                lastMarketSeed: seed
            )
            locations.append(loc)
        }

        return locations
    }

    private static func buildName(rng: inout SeededRandom) -> String {
        "\(rng.pick(from: prefixes)) \(rng.pick(from: suffixes))"
    }

    /// Returns locations within discovery range of a point.
    static func locationsNear(_ point: CGPoint, range: CGFloat, in universe: [Location]) -> [Location] {
        universe.filter { $0.position.distance(to: point) <= range }
    }
}
