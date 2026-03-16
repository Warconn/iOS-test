import { SeededRandom, LocationType, Location, buildMarket } from './models.ts'

// ─── Universe constants (identical to Swift) ─────────────────────────────────
export const UNIVERSE_SIZE      = 8000
export const MIN_SPACING        = 280
export const LOCATION_COUNT     = 75
export const UNIVERSE_SEED      = 0xDEADBEEFC0FFEE42n  // same as Swift

// ─── Background star (screen-space, generated once) ──────────────────────────
export interface BackgroundStar { x: number; y: number; size: number; opacity: number }

export function generateStars(count = 220, w = 430, h = 900): BackgroundStar[] {
  const out: BackgroundStar[] = []
  for (let i = 0; i < count; i++) {
    out.push({
      x: Math.random() * w,
      y: Math.random() * h,
      size: 0.6 + Math.random() * 1.6,
      opacity: 0.15 + Math.random() * 0.7,
    })
  }
  return out
}

// ─── Location name generation ─────────────────────────────────────────────────
const PREFIXES = [
  'Alpha','Beta','Nova','Proxima','Kepler','Vega','Sirius','Rigel',
  'Altair','Castor','Deneb','Antares','Spica','Zeta','Theta','Delta',
  'Epsilon','Mira','Arcturus','Capella','Algol','Regulus','Canopus',
  'Pollux','Hadar','Achernar','Acrux','Betelgeuse','Aldebaran','Orion',
]
const SUFFIXES = [
  'Prime','Station','Colony','Outpost','Haven','Nexus','Base','Port',
  'Depot','Hub','IV','VII','II','IX','Major','Minor','Terminus',
  'Crossing','Relay','Gate','Forge','Deep','Drift','Rise','Reach',
]

function buildName(rng: SeededRandom): string {
  return `${rng.pick(PREFIXES)} ${rng.pick(SUFFIXES)}`
}

// ─── Universe generation (deterministic, same seed as Swift) ─────────────────
export function generateUniverse(): Location[] {
  const rng = new SeededRandom(UNIVERSE_SEED)
  const locations: Location[] = []

  // 1. Starting hub at center
  const startSeed = rng.nextUInt64()
  locations.push({
    id: 'start',
    name: 'Sol Nexus',
    type: 'tradingHub',
    posX: UNIVERSE_SIZE / 2,
    posY: UNIVERSE_SIZE / 2,
    isDiscovered: true,
    visitCount: 1,
    market: buildMarket('tradingHub', startSeed),
    lastMarketSeed: 0,
  })

  // 2. Type pool (same distribution as Swift)
  const typePool: LocationType[] = [
    'miningColony','miningColony','miningColony',
    'agriculturalWorld','agriculturalWorld','agriculturalWorld',
    'industrialHub','industrialHub','industrialHub',
    'researchStation','researchStation',
    'fuelDepot','fuelDepot','fuelDepot',
    'luxuryResort','luxuryResort',
    'tradingHub','tradingHub',
  ]

  // 3. Rejection-sampling placement
  let attempts = 0
  while (locations.length < LOCATION_COUNT && attempts < LOCATION_COUNT * 40) {
    attempts++
    const px = rng.nextFloat(200, UNIVERSE_SIZE - 200)
    const py = rng.nextFloat(200, UNIVERSE_SIZE - 200)
    const tooClose = locations.some(l => {
      const dx = l.posX - px, dy = l.posY - py
      return Math.sqrt(dx * dx + dy * dy) < MIN_SPACING
    })
    if (tooClose) continue

    const type = rng.pick(typePool)
    const name = buildName(rng)
    const seed = rng.nextUInt64()
    locations.push({
      id: `loc_${locations.length}`,
      name,
      type,
      posX: px,
      posY: py,
      isDiscovered: false,
      visitCount: 0,
      market: buildMarket(type, seed),
      lastMarketSeed: 0,
    })
  }

  return locations
}
