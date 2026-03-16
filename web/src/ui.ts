import { GameState } from './game.ts'
import {
  COMMODITY_CATALOG, LOCATION_TYPE_INFO, ShipUpgrade,
  shipMaxSpeed, shipMaxCargo, shipMaxFuel, shipScannerRange,
  shipCargoUsed, shipFuelPercent, shipIsDocked, shipCargoQty,
  upgradeLevel, upgradeCost, upgradeDisplayName, upgradeEmoji, upgradeNextDesc,
  CommodityCategory, Location, findCommodity,
} from './models.ts'

const ALL_UPGRADES: ShipUpgrade[] = ['engine', 'cargo', 'scanner', 'fuelTank']
const ALL_CATS: CommodityCategory[] = ['Mineral', 'Consumable', 'Tech', 'Luxury']

export class UIManager {
  private state: GameState
  private currentTab: 'trade' | 'upgrades' | 'log' = 'trade'
  private currentCategory: CommodityCategory | null = null

  // DOM elements
  private hudCredits  = document.getElementById('hud-credits')!
  private hudFuelBar  = document.getElementById('fuel-bar')!
  private hudFuelPct  = document.getElementById('hud-fuel-pct')!
  private speedPill   = document.getElementById('speed-pill')!
  private hudSpeed    = document.getElementById('hud-speed')!
  private dockBtn     = document.getElementById('dock-btn')!
  private dockName    = document.getElementById('dock-name')!
  private fuelWarn    = document.getElementById('fuel-warn')!
  private notifEl     = document.getElementById('notification')!
  private stationEl   = document.getElementById('station')!

  constructor(state: GameState) {
    this.state = state
    this.bindEvents()
  }

  // ── HUD ──────────────────────────────────────────────────────────────────
  updateHUD(): void {
    const s  = this.state.ship
    const fp = shipFuelPercent(s)

    this.hudCredits.textContent = s.credits.toLocaleString()

    const barW = Math.max(0, Math.min(100, fp * 100))
    this.hudFuelBar.style.width      = barW + '%'
    this.hudFuelBar.style.background = fp > 0.35 ? '#22C55E' : fp > 0.15 ? '#F59E0B' : '#EF4444'
    this.hudFuelPct.textContent = Math.round(fp * 100) + '%'

    if (!shipIsDocked(s)) {
      const throttle = Math.sqrt(this.state.joystick.x ** 2 + this.state.joystick.y ** 2)
      const spd = Math.round(shipMaxSpeed(s) * throttle)
      if (spd > 10) {
        this.speedPill.style.display  = ''
        this.hudSpeed.textContent = String(spd)
      } else {
        this.speedPill.style.display = 'none'
      }
    } else {
      this.speedPill.style.display = 'none'
    }

    this.fuelWarn.style.display = (s.fuel < 5 && !shipIsDocked(s)) ? '' : 'none'
  }

  // ── Dock button ──────────────────────────────────────────────────────────
  showDockButton(loc: Location): void {
    this.dockName.textContent = loc.name
    this.dockBtn.style.display = 'block'
  }

  hideDockButton(): void {
    this.dockBtn.style.display = 'none'
  }

  // ── Notification toast ───────────────────────────────────────────────────
  showNotification(msg: string): void {
    if (!msg) { this.notifEl.classList.remove('show'); return }
    this.notifEl.textContent = msg
    this.notifEl.classList.add('show')
  }

  // ── Station sheet ────────────────────────────────────────────────────────
  openStation(): void {
    this.currentTab = 'trade'
    this.dockBtn.style.display = 'none'
    this.renderStation()
    this.stationEl.classList.add('open')
  }

  closeStation(): void {
    this.stationEl.classList.remove('open')
  }

  private renderStation(): void {
    const s   = this.state
    const loc = s.currentLocation
    if (!loc) return
    const info = LOCATION_TYPE_INFO[loc.type]

    const surplusTags = info.surplusCommodities
      .map(id => findCommodity(id))
      .filter(Boolean)
      .map(c => `<span class="tag green">${c!.emoji}${c!.name}</span>`)
      .join('')

    const demandTags = info.demandCommodities
      .map(id => findCommodity(id))
      .filter(Boolean)
      .map(c => `<span class="tag orange">${c!.emoji}${c!.name}</span>`)
      .join('')

    this.stationEl.innerHTML = `
      <div class="station-header">
        <div style="display:flex;align-items:center;gap:8px">
          <span style="font-size:28px">${info.emoji}</span>
          <div>
            <h2>${loc.name}</h2>
            <p>${info.displayName}</p>
          </div>
        </div>
        <div class="credits-cargo">
          💰 ${s.ship.credits.toLocaleString()}cr
          <small>Cargo ${shipCargoUsed(s.ship)}/${shipMaxCargo(s.ship)}</small>
        </div>
        <div class="surplus-row" style="margin-top:8px">
          ${surplusTags ? `<span class="tag" style="color:#6b7280;background:none;padding-left:0">Sells cheap:</span>${surplusTags}` : ''}
          ${demandTags  ? `<span class="tag" style="color:#6b7280;background:none">Buys well:</span>${demandTags}` : ''}
        </div>
      </div>
      <div class="tabs">
        <button class="tab ${this.currentTab === 'trade'    ? 'active' : ''}" data-tab="trade">Trade</button>
        <button class="tab ${this.currentTab === 'upgrades' ? 'active' : ''}" data-tab="upgrades">Upgrades</button>
        <button class="tab ${this.currentTab === 'log'      ? 'active' : ''}" data-tab="log">Log</button>
      </div>
      <div class="tab-content" id="tab-content">
        ${this.renderTabContent()}
      </div>
      <button class="undock-btn" id="undock-btn">↑ Undock &amp; Fly</button>
    `

    document.getElementById('undock-btn')?.addEventListener('click', () => {
      this.state.undock()
    })
    this.stationEl.querySelectorAll('.tab').forEach(btn => {
      btn.addEventListener('click', () => {
        const tab = (btn as HTMLElement).dataset.tab as 'trade' | 'upgrades' | 'log'
        this.currentTab = tab
        this.stationEl.querySelectorAll('.tab').forEach(b => b.classList.remove('active'))
        btn.classList.add('active')
        const content = document.getElementById('tab-content')
        if (content) content.innerHTML = this.renderTabContent()
        this.bindTabEvents()
      })
    })
    this.bindTabEvents()
  }

  private renderTabContent(): string {
    switch (this.currentTab) {
      case 'trade':    return this.renderTrade()
      case 'upgrades': return this.renderUpgrades()
      case 'log':      return this.renderLog()
    }
  }

  // ── Trade tab ────────────────────────────────────────────────────────────
  private renderTrade(): string {
    const s   = this.state
    const loc = s.currentLocation
    if (!loc) return ''

    const isFull  = s.ship.fuel >= shipMaxFuel(s.ship) - 0.5
    const fuelCost = Math.max(1, Math.floor((shipMaxFuel(s.ship) - s.ship.fuel) * 2))
    const canFuel  = !isFull && s.ship.credits >= fuelCost

    const refuelStrip = `
      <div class="refuel-strip${canFuel ? '' : ' disabled'}" id="refuel-strip">
        <span>⛽ Fuel: ${Math.round(s.ship.fuel)} / ${shipMaxFuel(s.ship)}</span>
        <span class="cost">${isFull ? 'Full' : canFuel ? `Refuel ${fuelCost}cr` : 'No credits'}</span>
      </div>`

    const chips = `
      <div class="chips">
        <button class="chip${this.currentCategory === null ? ' active' : ''}" data-cat="">All</button>
        ${ALL_CATS.map(c => `<button class="chip${this.currentCategory === c ? ' active' : ''}" data-cat="${c}">${c}</button>`).join('')}
      </div>`

    const filteredIds = this.currentCategory
      ? COMMODITY_CATALOG.filter(c => c.category === this.currentCategory).map(c => c.id)
      : COMMODITY_CATALOG.map(c => c.id)

    // Sell section (cargo we're carrying)
    const cargoRows = s.ship.cargo
      .filter(item => filteredIds.includes(item.commodityId))
      .map(item => {
        const c    = findCommodity(item.commodityId)!
        const m    = loc.market.find(m => m.commodityId === item.commodityId)!
        const good = m.sellPrice > c.basePrice * 0.95
        return `
          <div class="comm-row sell-row">
            <span class="comm-emoji">${c.emoji}</span>
            <div class="comm-info"><div class="comm-name">${c.name}</div><div class="comm-cat">${c.category}</div></div>
            <div class="comm-price">
              <div class="price-val${good ? ' good' : ''}">Sell ${m.sellPrice}cr${good ? ' ↑' : ''}</div>
              <div class="price-stock">Have: ${item.quantity}</div>
            </div>
            <div class="trade-btns">
              <button class="trade-btn sell1" data-action="sell1" data-id="${c.id}">-1</button>
              <button class="trade-btn sellall" data-action="sellall" data-id="${c.id}">All</button>
            </div>
          </div>`
      }).join('')

    // Buy section
    const buyRows = filteredIds.map(id => {
      const c    = findCommodity(id)!
      const m    = loc.market.find(m => m.commodityId === id)!
      const good = m.buyPrice < c.basePrice
      return `
        <div class="comm-row">
          <span class="comm-emoji">${c.emoji}</span>
          <div class="comm-info"><div class="comm-name">${c.name}</div><div class="comm-cat">${c.category}</div></div>
          <div class="comm-price">
            <div class="price-val${good ? ' good' : ''}">Buy ${m.buyPrice}cr${good ? ' ↓' : ''}</div>
            <div class="price-stock">Stock: ${m.stationStock}</div>
          </div>
          <div class="trade-btns">
            <button class="trade-btn buy" data-action="buy1" data-id="${c.id}">+1</button>
          </div>
        </div>`
    }).join('')

    return `${refuelStrip}${chips}
      <div class="commodity-list">
        ${cargoRows ? `<div class="section-label">Your Cargo — Tap to Sell</div>${cargoRows}<hr style="border-color:rgba(255,255,255,0.08);margin:8px 0">` : ''}
        <div class="section-label">Buy from Station</div>
        ${buyRows}
      </div>`
  }

  // ── Upgrades tab ─────────────────────────────────────────────────────────
  private renderUpgrades(): string {
    const s = this.state
    const statCard = `
      <div class="ship-card">
        <h3>🛸 Your Ship</h3>
        <div class="stat-row"><span class="label">🚀 Max Speed</span><span class="val">${shipMaxSpeed(s.ship)} u/s</span></div>
        <div class="stat-row"><span class="label">📦 Cargo</span><span class="val">${shipCargoUsed(s.ship)}/${shipMaxCargo(s.ship)} slots</span></div>
        <div class="stat-row"><span class="label">📡 Scanner</span><span class="val">${shipScannerRange(s.ship)} units</span></div>
        <div class="stat-row"><span class="label">⛽ Fuel</span><span class="val">${Math.round(s.ship.fuel)}/${shipMaxFuel(s.ship)}</span></div>
        <div class="stat-row"><span class="label">🌍 Discovered</span><span class="val">${s.universe.filter(l => l.isDiscovered).length}/${s.universe.length}</span></div>
      </div>`

    const upgradeCards = ALL_UPGRADES.map(type => {
      const lv      = upgradeLevel(s.ship, type)
      const cost    = upgradeCost(s.ship, type)
      const maxed   = lv >= 5
      const canAfford = cost !== null && s.ship.credits >= cost
      const dots    = Array.from({length: 5}, (_, i) =>
        `<span class="dot${i < lv ? ' filled' : ''}"></span>`).join('')

      return `
        <div class="upgrade-card">
          <div class="upgrade-header">
            <span class="upgrade-icon">${upgradeEmoji(type)}</span>
            <div style="flex:1">
              <div style="display:flex;align-items:center;justify-content:space-between">
                <span class="upgrade-title">${upgradeDisplayName(type)}</span>
                <div class="level-dots">${dots}</div>
              </div>
              <div class="upgrade-desc">Level ${lv}${maxed ? ' — MAX' : ''}</div>
            </div>
          </div>
          <div class="upgrade-footer">
            <span class="${maxed ? 'upgrade-max' : 'upgrade-next'}">${maxed ? 'MAX LEVEL' : upgradeNextDesc(s.ship, type)}</span>
            ${!maxed ? `<button class="upgrade-btn" data-action="upgrade" data-type="${type}" ${canAfford ? '' : 'disabled'}>
              💰 ${cost?.toLocaleString()}cr
            </button>` : ''}
          </div>
        </div>`
    }).join('')

    return `<div style="padding:14px">
      ${statCard}
      ${upgradeCards}
      <button class="new-game-btn" id="new-game-btn">🗑️ New Game</button>
    </div>`
  }

  // ── Log tab ───────────────────────────────────────────────────────────────
  private renderLog(): string {
    if (this.state.journal.length === 0) {
      return '<p style="padding:40px 14px;text-align:center;color:#6b7280;font-size:13px">No entries yet. Start exploring!</p>'
    }
    const icons: Record<string, string> = { discovery:'🔭', trade:'💰', upgrade:'⬆️', arrival:'🛸', system:'📋' }
    const rows = this.state.journal.map(e => {
      const ago = formatAgo(e.timestamp)
      return `
        <div class="log-entry">
          <span class="log-icon">${icons[e.type] ?? '📋'}</span>
          <div><div class="log-msg">${e.message}</div><div class="log-time">${ago}</div></div>
        </div>`
    }).join('')
    return `<div class="log-list">${rows}</div>`
  }

  // ── Event binding ─────────────────────────────────────────────────────────
  private bindEvents(): void {
    document.getElementById('dock-btn')?.addEventListener('click', () => this.state.dock())
    document.getElementById('reset-btn')?.addEventListener('click', () => {
      if (confirm('Start new game? All progress will be lost.')) this.state.reset()
    })
  }

  /** Bind events inside the current tab content (re-called on tab switch) */
  bindTabEvents(): void {
    const content = document.getElementById('tab-content')
    if (!content) return

    content.addEventListener('click', (e) => {
      const target = (e.target as HTMLElement).closest('[data-action]') as HTMLElement | null
      if (!target) return
      const action = target.dataset.action
      const id     = target.dataset.id ?? ''
      const type   = target.dataset.type as ShipUpgrade | undefined

      switch (action) {
        case 'buy1':    this.state.buy(id, 1);  this.refreshTradeContent(); break
        case 'sell1':   this.state.sell(id, 1); this.refreshTradeContent(); break
        case 'sellall': {
          const qty = this.state.ship.cargo.find(c => c.commodityId === id)?.quantity ?? 0
          if (qty > 0) this.state.sell(id, qty)
          this.refreshTradeContent(); break
        }
        case 'upgrade':
          if (type) { this.state.upgrade(type); this.refreshStationHeader(); this.refreshTabContent() }
          break
        case 'new-game':
          if (confirm('Start new game? All progress will be lost.')) this.state.reset()
          break
      }
    })

    content.querySelector('#refuel-strip')?.addEventListener('click', () => {
      this.state.refuel(); this.refreshTradeContent()
    })
    content.querySelector('#new-game-btn')?.addEventListener('click', () => {
      if (confirm('Start new game? All progress will be lost.')) this.state.reset()
    })

    content.querySelectorAll('.chip').forEach(btn => {
      btn.addEventListener('click', () => {
        const cat = (btn as HTMLElement).dataset.cat as CommodityCategory | ''
        this.currentCategory = cat === '' ? null : cat
        this.refreshTradeContent()
      })
    })
  }

  private refreshTradeContent(): void {
    const content = document.getElementById('tab-content')
    if (!content || this.currentTab !== 'trade') return
    content.innerHTML = this.renderTrade()
    this.bindTabEvents()
    this.refreshStationHeader()
  }

  private refreshTabContent(): void {
    const content = document.getElementById('tab-content')
    if (!content) return
    content.innerHTML = this.renderTabContent()
    this.bindTabEvents()
    this.refreshStationHeader()
  }

  private refreshStationHeader(): void {
    // Update credits/cargo badge without full re-render
    const badge = this.stationEl.querySelector('.credits-cargo')
    if (badge) {
      const s = this.state
      badge.innerHTML = `💰 ${s.ship.credits.toLocaleString()}cr<small>Cargo ${shipCargoUsed(s.ship)}/${shipMaxCargo(s.ship)}</small>`
    }
  }

  /** Called when station data changes externally (e.g. after docking) */
  refreshStation(): void {
    if (this.stationEl.classList.contains('open')) {
      this.renderStation()
    }
  }
}

function formatAgo(timestamp: number): string {
  const s = Math.floor((Date.now() - timestamp) / 1000)
  if (s < 60)  return 'just now'
  if (s < 3600) return `${Math.floor(s / 60)}m ago`
  return `${Math.floor(s / 3600)}h ago`
}
