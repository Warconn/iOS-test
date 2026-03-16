import {
  Ship, makeShip, Location, JournalEntry, makeJournalEntry,
  ShipUpgrade, FUEL_CONSUMPTION_RATE,
  shipMaxSpeed, shipMaxFuel, shipScannerRange, shipIsDocked, shipCargoFree,
  shipCargoQty, addCargo, removeCargo, upgradeCost, applyUpgrade,
  upgradeLevel, upgradeDisplayName, refreshMarket, dist2d, findCommodity,
} from './models.ts'
import { generateUniverse, generateStars, BackgroundStar, UNIVERSE_SIZE } from './universe.ts'

const SAVE_KEY = 'spacetrader_web_v2'
const DOCK_RANGE = 200
const UNDOCK_COOLDOWN = 2000  // ms

export class GameState {
  ship: Ship
  universe: Location[]
  journal: JournalEntry[] = []
  stars: BackgroundStar[]

  // Joystick vector set by input handler
  joystick = { x: 0, y: 0 }

  // Runtime state (not saved)
  nearbyLocation: Location | null = null
  notification: string | null = null
  notifTimer: ReturnType<typeof setTimeout> | null = null
  lastUndockTime = 0

  // Callbacks wired by main
  onHUDChange?: () => void
  onDockChange?: (loc: Location | null) => void
  onStationOpen?: (loc: Location) => void
  onStationClose?: () => void
  onNotification?: (msg: string) => void

  constructor() {
    const saved = GameState.load()
    if (saved) {
      this.ship     = { velX: 0, velY: 0, ...saved.ship }  // migrate missing drift fields
      this.universe = saved.universe
      this.journal  = saved.journal
    } else {
      this.ship     = makeShip()
      this.universe = generateUniverse()
      this.ship.posX = this.universe[0].posX
      this.ship.posY = this.universe[0].posY
    }
    this.stars = generateStars()
    this.discoverNear()
  }

  // ── Tick (called each frame with delta time in seconds) ─────────────────
  tick(dt: number): void {
    if (shipIsDocked(this.ship)) return

    const throttle = Math.sqrt(this.joystick.x ** 2 + this.joystick.y ** 2)

    // Update heading: face joystick when thrusting, else face velocity direction when drifting
    if (throttle > 0.05) {
      this.ship.heading = Math.atan2(this.joystick.y, this.joystick.x) + Math.PI / 2
    } else if (Math.abs(this.ship.velX) > 5 || Math.abs(this.ship.velY) > 5) {
      this.ship.heading = Math.atan2(this.ship.velY, this.ship.velX) + Math.PI / 2
    }

    // Apply thrust (joystick active + has fuel)
    if (throttle > 0.05 && this.ship.fuel > 0) {
      const targetVelX = this.joystick.x * shipMaxSpeed(this.ship)
      const targetVelY = this.joystick.y * shipMaxSpeed(this.ship)
      const accel = 6.0
      this.ship.velX += (targetVelX - this.ship.velX) * accel * dt
      this.ship.velY += (targetVelY - this.ship.velY) * accel * dt
      this.ship.fuel = Math.max(0, this.ship.fuel - throttle * FUEL_CONSUMPTION_RATE * dt)
    } else {
      // Drift decay — 20% velocity remains after 1 second
      const drag = Math.pow(0.20, dt)
      this.ship.velX *= drag
      this.ship.velY *= drag
      if (Math.abs(this.ship.velX) < 0.5) this.ship.velX = 0
      if (Math.abs(this.ship.velY) < 0.5) this.ship.velY = 0
    }

    // Apply velocity to position
    const currentSpeed = Math.sqrt(this.ship.velX ** 2 + this.ship.velY ** 2)
    if (currentSpeed > 0.1) {
      const bound = UNIVERSE_SIZE - 50
      this.ship.posX = Math.max(50, Math.min(bound, this.ship.posX + this.ship.velX * dt))
      this.ship.posY = Math.max(50, Math.min(bound, this.ship.posY + this.ship.velY * dt))
    }

    this.discoverNear()

    // Dock proximity check
    const dockable = this.universe.find(l =>
      l.isDiscovered && dist2d(l.posX, l.posY, this.ship.posX, this.ship.posY) < DOCK_RANGE
    ) ?? null

    if (dockable?.id !== this.nearbyLocation?.id) {
      this.nearbyLocation = dockable
      this.onDockChange?.(dockable)
    }

    this.onHUDChange?.()
  }

  // ── Discovery ────────────────────────────────────────────────────────────
  private discoverNear(): void {
    const range = shipScannerRange(this.ship)
    for (const loc of this.universe) {
      if (loc.isDiscovered) continue
      if (dist2d(loc.posX, loc.posY, this.ship.posX, this.ship.posY) <= range) {
        loc.isDiscovered = true
        this.postNotification(`Discovered ${loc.name}!`)
        this.journal.unshift(makeJournalEntry(`Discovered ${loc.name} · ${loc.type}`, 'discovery'))
      }
    }
  }

  // ── Docking ──────────────────────────────────────────────────────────────
  dock(): void {
    const loc = this.nearbyLocation
    if (!loc) return
    this.joystick = { x: 0, y: 0 }
    this.ship.velX = 0
    this.ship.velY = 0
    this.ship.currentLocationId = loc.id
    const i = this.universe.findIndex(l => l.id === loc.id)
    if (i >= 0) {
      this.universe[i].visitCount++
      refreshMarket(this.universe[i])
    }
    this.journal.unshift(makeJournalEntry(`Arrived at ${loc.name}`, 'arrival'))
    this.save()
    this.onStationOpen?.(loc)
    this.onHUDChange?.()
  }

  undock(): void {
    this.ship.currentLocationId = null
    this.lastUndockTime = Date.now()
    this.nearbyLocation = null
    this.onDockChange?.(null)
    this.onStationClose?.()
    this.save()
    this.onHUDChange?.()
  }

  get currentLocation(): Location | undefined {
    if (!this.ship.currentLocationId) return undefined
    return this.universe.find(l => l.id === this.ship.currentLocationId)
  }

  // ── Trading ───────────────────────────────────────────────────────────────
  buy(commodityId: string, qty: number): void {
    const loc = this.currentLocation
    if (!loc) return
    const mi = loc.market.findIndex(m => m.commodityId === commodityId)
    if (mi < 0) return
    const listing = loc.market[mi]
    const cost = listing.buyPrice * qty
    if (this.ship.credits < cost) return
    if (shipCargoFree(this.ship) < qty) return
    if (listing.stationStock < qty) return
    this.ship.credits -= cost
    addCargo(this.ship, commodityId, qty)
    loc.market[mi].stationStock -= qty
    const name = findCommodity(commodityId)?.name ?? commodityId
    this.journal.unshift(makeJournalEntry(`Bought ${qty}× ${name} for ${cost}cr`, 'trade'))
    this.postNotification(`Bought ${qty}× ${name}`)
    this.save()
    this.onHUDChange?.()
  }

  sell(commodityId: string, qty: number): void {
    const loc = this.currentLocation
    if (!loc) return
    const mi = loc.market.findIndex(m => m.commodityId === commodityId)
    if (mi < 0) return
    if (shipCargoQty(this.ship, commodityId) < qty) return
    const revenue = loc.market[mi].sellPrice * qty
    this.ship.credits += revenue
    removeCargo(this.ship, commodityId, qty)
    loc.market[mi].stationStock += qty
    const name = findCommodity(commodityId)?.name ?? commodityId
    this.journal.unshift(makeJournalEntry(`Sold ${qty}× ${name} for ${revenue}cr`, 'trade'))
    this.postNotification(`Sold ${qty}× ${name} for ${revenue}cr`)
    this.save()
    this.onHUDChange?.()
  }

  refuel(): void {
    const loc = this.currentLocation
    if (!loc) return
    const needed = shipMaxFuel(this.ship) - this.ship.fuel
    if (needed < 0.5) return
    const cost = Math.max(1, Math.floor(needed * 2.0))
    if (this.ship.credits < cost) return
    this.ship.credits -= cost
    this.ship.fuel = shipMaxFuel(this.ship)
    this.journal.unshift(makeJournalEntry(`Refuelled for ${cost}cr at ${loc.name}`, 'system'))
    this.postNotification(`Refuelled for ${cost}cr`)
    this.save()
    this.onHUDChange?.()
  }

  // ── Upgrades ─────────────────────────────────────────────────────────────
  upgrade(type: ShipUpgrade): void {
    const cost = upgradeCost(this.ship, type)
    if (cost === null || this.ship.credits < cost) return
    this.ship.credits -= cost
    applyUpgrade(this.ship, type)
    const lv = upgradeLevel(this.ship, type)
    this.journal.unshift(makeJournalEntry(`Upgraded ${upgradeDisplayName(type)} to level ${lv}`, 'upgrade'))
    this.postNotification(`${upgradeDisplayName(type)} Lv.${lv} installed!`)
    this.save()
    this.onHUDChange?.()
  }

  // ── Notifications ────────────────────────────────────────────────────────
  postNotification(msg: string): void {
    if (this.notifTimer) clearTimeout(this.notifTimer)
    this.notification = msg
    this.onNotification?.(msg)
    this.notifTimer = setTimeout(() => {
      this.notification = null
      this.onNotification?.('')
    }, 2500)
  }

  // ── Persistence ──────────────────────────────────────────────────────────
  save(): void {
    try {
      const data = { ship: this.ship, universe: this.universe, journal: this.journal.slice(0, 100) }
      localStorage.setItem(SAVE_KEY, JSON.stringify(data))
    } catch { /* ignore storage errors */ }
  }

  static load(): { ship: Ship; universe: Location[]; journal: JournalEntry[] } | null {
    try {
      const raw = localStorage.getItem(SAVE_KEY)
      if (!raw) return null
      return JSON.parse(raw)
    } catch { return null }
  }

  reset(): void {
    localStorage.removeItem(SAVE_KEY)
    this.ship     = makeShip()
    this.universe = generateUniverse()
    this.journal  = []
    this.joystick = { x: 0, y: 0 }
    this.nearbyLocation = null
    this.ship.posX = this.universe[0].posX
    this.ship.posY = this.universe[0].posY
    this.discoverNear()
    this.onStationOpen?.(this.universe[0])
    this.onHUDChange?.()
  }
}
