// ─── Seeded Deterministic RNG (Knuth LCG — mirrors Swift SeededRandom) ──────
// Same multipliers as Swift, bigint for correct 64-bit wrapping arithmetic.
export class SeededRandom {
  private state: bigint

  constructor(seed: bigint = 42n) {
    this.state = seed === 0n ? 1n : seed
  }

  nextUInt64(): bigint {
    this.state =
      (this.state * 6364136223846793005n + 1442695040888963407n) &
      0xffffffffffffffffn
    return this.state
  }

  nextDouble(): number {
    return Number(this.nextUInt64()) / 18446744073709551615
  }

  nextFloat(min: number, max: number): number {
    return min + this.nextDouble() * (max - min)
  }

  nextInt(min: number, max: number): number {
    const range = max - min
    return min + Number(this.nextUInt64() % BigInt(range))
  }

  pick<T>(arr: T[]): T {
    return arr[this.nextInt(0, arr.length)]
  }
}

// ─── Commodity ───────────────────────────────────────────────────────────────
export type CommodityCategory = 'Mineral' | 'Consumable' | 'Tech' | 'Luxury'

export interface Commodity {
  id: string
  name: string
  emoji: string
  basePrice: number
  category: CommodityCategory
}

export const COMMODITY_CATALOG: Commodity[] = [
  { id: 'ore',           name: 'Raw Ore',      emoji: '🪨', basePrice: 45,  category: 'Mineral'    },
  { id: 'crystals',      name: 'Crystals',      emoji: '💎', basePrice: 120, category: 'Mineral'    },
  { id: 'rare_metals',   name: 'Rare Metals',   emoji: '🔩', basePrice: 200, category: 'Mineral'    },
  { id: 'food',          name: 'Food Rations',  emoji: '🌾', basePrice: 30,  category: 'Consumable' },
  { id: 'medicine',      name: 'Medicine',      emoji: '💊', basePrice: 85,  category: 'Consumable' },
  { id: 'fuel_cells',    name: 'Fuel Cells',    emoji: '⚡', basePrice: 65,  category: 'Consumable' },
  { id: 'components',    name: 'Components',    emoji: '⚙️', basePrice: 155, category: 'Tech'       },
  { id: 'ai_cores',      name: 'AI Cores',      emoji: '🤖', basePrice: 360, category: 'Tech'       },
  { id: 'luxury_goods',  name: 'Luxury Goods',  emoji: '💫', basePrice: 290, category: 'Luxury'     },
  { id: 'exotic_matter', name: 'Exotic Matter', emoji: '🌀', basePrice: 520, category: 'Luxury'     },
]

export function findCommodity(id: string): Commodity | undefined {
  return COMMODITY_CATALOG.find(c => c.id === id)
}

export type PriceTier = 'surplus' | 'neutral' | 'demand'

export function buyMultiplier(tier: PriceTier): number {
  return tier === 'surplus' ? 0.55 : tier === 'demand' ? 1.55 : 1.05
}
export function sellMultiplier(tier: PriceTier): number {
  return tier === 'surplus' ? 0.40 : tier === 'demand' ? 1.45 : 0.90
}
export function commodityBuyPrice(c: Commodity, tier: PriceTier): number {
  return Math.max(1, Math.floor(c.basePrice * buyMultiplier(tier)))
}
export function commoditySellPrice(c: Commodity, tier: PriceTier): number {
  return Math.max(1, Math.floor(c.basePrice * sellMultiplier(tier)))
}

// ─── Market ──────────────────────────────────────────────────────────────────
export interface MarketListing {
  commodityId: string
  buyPrice: number
  sellPrice: number
  stationStock: number
}

// ─── Location types ──────────────────────────────────────────────────────────
export type LocationType =
  | 'tradingHub' | 'miningColony' | 'agriculturalWorld'
  | 'industrialHub' | 'researchStation' | 'fuelDepot' | 'luxuryResort'

export interface LocationTypeInfo {
  displayName: string
  emoji: string
  mapColor: string
  isStation: boolean
  surplusCommodities: string[]
  demandCommodities: string[]
}

export const LOCATION_TYPE_INFO: Record<LocationType, LocationTypeInfo> = {
  tradingHub:        { displayName: 'Trading Hub',        emoji: '🏪', mapColor: '#FFD700', isStation: true,  surplusCommodities: [],                              demandCommodities: [] },
  miningColony:      { displayName: 'Mining Colony',      emoji: '⛏️', mapColor: '#9E9E9E', isStation: false, surplusCommodities: ['ore','crystals','rare_metals'], demandCommodities: ['food','medicine','components'] },
  agriculturalWorld: { displayName: 'Agricultural World', emoji: '🌾', mapColor: '#4CAF50', isStation: false, surplusCommodities: ['food','medicine'],              demandCommodities: ['components','ai_cores','fuel_cells'] },
  industrialHub:     { displayName: 'Industrial Hub',     emoji: '🏭', mapColor: '#FF9800', isStation: false, surplusCommodities: ['components','fuel_cells'],      demandCommodities: ['ore','rare_metals','food'] },
  researchStation:   { displayName: 'Research Station',   emoji: '🔬', mapColor: '#2196F3', isStation: true,  surplusCommodities: ['ai_cores','exotic_matter'],     demandCommodities: ['food','rare_metals','components'] },
  fuelDepot:         { displayName: 'Fuel Depot',         emoji: '⛽', mapColor: '#FFEB3B', isStation: true,  surplusCommodities: ['fuel_cells'],                   demandCommodities: ['ore','components','food'] },
  luxuryResort:      { displayName: 'Luxury Resort',      emoji: '💎', mapColor: '#E040FB', isStation: false, surplusCommodities: ['luxury_goods'],                 demandCommodities: ['food','medicine','ai_cores','exotic_matter'] },
}

export function priceTierFor(type: LocationType, commodityId: string): PriceTier {
  const info = LOCATION_TYPE_INFO[type]
  if (info.surplusCommodities.includes(commodityId)) return 'surplus'
  if (info.demandCommodities.includes(commodityId))  return 'demand'
  return 'neutral'
}

export function buildMarket(type: LocationType, seed: bigint): MarketListing[] {
  const rng = new SeededRandom(seed)
  return COMMODITY_CATALOG.map(c => {
    const tier = priceTierFor(type, c.id)
    const factor = 1.0 + (rng.nextDouble() * 0.16 - 0.08)
    return {
      commodityId: c.id,
      buyPrice:    Math.max(1, Math.floor(commodityBuyPrice(c, tier)  * factor)),
      sellPrice:   Math.max(1, Math.floor(commoditySellPrice(c, tier) * factor)),
      stationStock: tier === 'surplus' ? rng.nextInt(20, 60) : rng.nextInt(5, 20),
    }
  })
}

// ─── Location ────────────────────────────────────────────────────────────────
export interface Location {
  id: string
  name: string
  type: LocationType
  posX: number
  posY: number
  isDiscovered: boolean
  visitCount: number
  market: MarketListing[]
  lastMarketSeed: number  // simple counter; increments on each dock
}

export function refreshMarket(loc: Location): void {
  loc.lastMarketSeed++
  const rng = new SeededRandom(BigInt(loc.lastMarketSeed))
  for (let i = 0; i < loc.market.length; i++) {
    const factor = 1.0 + (rng.nextDouble() * 0.16 - 0.08)
    loc.market[i].buyPrice  = Math.max(1, Math.floor(loc.market[i].buyPrice  * factor))
    loc.market[i].sellPrice = Math.max(1, Math.floor(loc.market[i].sellPrice * factor))
    const tier = priceTierFor(loc.type, COMMODITY_CATALOG[i].id)
    if (loc.market[i].stationStock < 5) {
      loc.market[i].stationStock += tier === 'surplus' ? 20 : 8
    }
  }
}

export function locListing(loc: Location, commodityId: string): MarketListing | undefined {
  return loc.market.find(m => m.commodityId === commodityId)
}

// ─── Ship ────────────────────────────────────────────────────────────────────
export type ShipUpgrade = 'engine' | 'cargo' | 'scanner' | 'fuelTank'

export interface CargoItem { commodityId: string; quantity: number }

export interface Ship {
  posX: number; posY: number
  heading: number
  credits: number
  cargo: CargoItem[]
  fuel: number
  engineLevel: number
  cargoLevel: number
  scannerLevel: number
  fuelTankLevel: number
  currentLocationId: string | null
}

export function makeShip(): Ship {
  return {
    posX: 4000, posY: 4000, heading: 0,
    credits: 500, cargo: [], fuel: 110,
    engineLevel: 1, cargoLevel: 1, scannerLevel: 1, fuelTankLevel: 1,
    currentLocationId: 'start',
  }
}

export const FUEL_CONSUMPTION_RATE = 3.0

export function shipMaxSpeed(s: Ship):      number  { return 150 + s.engineLevel   * 60 }
export function shipMaxCargo(s: Ship):      number  { return   4 + s.cargoLevel    * 4  }
export function shipScannerRange(s: Ship):  number  { return 700 + s.scannerLevel  * 350 }
export function shipMaxFuel(s: Ship):       number  { return  80 + s.fuelTankLevel * 30 }
export function shipCargoUsed(s: Ship):     number  { return s.cargo.reduce((n, c) => n + c.quantity, 0) }
export function shipCargoFree(s: Ship):     number  { return shipMaxCargo(s) - shipCargoUsed(s) }
export function shipFuelPercent(s: Ship):   number  { return shipMaxFuel(s) > 0 ? s.fuel / shipMaxFuel(s) : 0 }
export function shipIsDocked(s: Ship):      boolean { return s.currentLocationId !== null }
export function shipCargoQty(s: Ship, id: string): number {
  return s.cargo.find(c => c.commodityId === id)?.quantity ?? 0
}

export function addCargo(s: Ship, id: string, qty: number): void {
  const item = s.cargo.find(c => c.commodityId === id)
  if (item) { item.quantity += qty } else { s.cargo.push({ commodityId: id, quantity: qty }) }
}

export function removeCargo(s: Ship, id: string, qty: number): boolean {
  const idx = s.cargo.findIndex(c => c.commodityId === id)
  if (idx < 0 || s.cargo[idx].quantity < qty) return false
  s.cargo[idx].quantity -= qty
  if (s.cargo[idx].quantity === 0) s.cargo.splice(idx, 1)
  return true
}

export const UPGRADE_COSTS = [800, 2200, 5500, 13000]  // L1→L2 … L4→L5

export function upgradeLevel(s: Ship, t: ShipUpgrade): number {
  return t === 'engine' ? s.engineLevel : t === 'cargo' ? s.cargoLevel :
         t === 'scanner' ? s.scannerLevel : s.fuelTankLevel
}
export function upgradeCost(s: Ship, t: ShipUpgrade): number | null {
  const lv = upgradeLevel(s, t)
  return lv >= 5 ? null : UPGRADE_COSTS[lv - 1]
}
export function applyUpgrade(s: Ship, t: ShipUpgrade): void {
  switch (t) {
    case 'engine':   s.engineLevel   = Math.min(5, s.engineLevel + 1);   break
    case 'cargo':    s.cargoLevel    = Math.min(5, s.cargoLevel + 1);    break
    case 'scanner':  s.scannerLevel  = Math.min(5, s.scannerLevel + 1);  break
    case 'fuelTank':
      s.fuelTankLevel = Math.min(5, s.fuelTankLevel + 1)
      s.fuel = Math.min(s.fuel + 30, shipMaxFuel(s))
      break
  }
}
export function upgradeDisplayName(t: ShipUpgrade): string {
  return t === 'engine' ? 'Engine' : t === 'cargo' ? 'Cargo Hold' :
         t === 'scanner' ? 'Scanner' : 'Fuel Tank'
}
export function upgradeEmoji(t: ShipUpgrade): string {
  return t === 'engine' ? '🚀' : t === 'cargo' ? '📦' : t === 'scanner' ? '📡' : '⛽'
}
export function upgradeNextDesc(s: Ship, t: ShipUpgrade): string {
  const n = upgradeLevel(s, t) + 1
  switch (t) {
    case 'engine':   return `Max speed: ${150 + n * 60} u/s`
    case 'cargo':    return `Cargo slots: ${4 + n * 4}`
    case 'scanner':  return `Scanner range: ${700 + n * 350} units`
    case 'fuelTank': return `Max fuel: ${80 + n * 30}`
  }
}

// ─── Journal ─────────────────────────────────────────────────────────────────
export type JournalEntryType = 'discovery' | 'trade' | 'upgrade' | 'arrival' | 'system'
export interface JournalEntry {
  id: number
  timestamp: number
  message: string
  type: JournalEntryType
}

let _jid = 0
export function makeJournalEntry(msg: string, type: JournalEntryType = 'system'): JournalEntry {
  return { id: ++_jid, timestamp: Date.now(), message: msg, type }
}

// ─── Utilities ───────────────────────────────────────────────────────────────
export function dist2d(ax: number, ay: number, bx: number, by: number): number {
  const dx = ax - bx, dy = ay - by
  return Math.sqrt(dx * dx + dy * dy)
}
