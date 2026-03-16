import { GameState } from './game.ts'
import {
  shipIsDocked, shipMaxSpeed, shipScannerRange, shipFuelPercent,
  LOCATION_TYPE_INFO, dist2d,
} from './models.ts'
import { UNIVERSE_SIZE } from './universe.ts'

const SCALE = 0.08  // 1 world unit = 0.08 CSS px; viewport ≈ 4875 wide on 390pt screen

export class Renderer {
  private canvas: HTMLCanvasElement
  private ctx: CanvasRenderingContext2D

  // CSS dimensions (not device pixels)
  private w = 0
  private h = 0
  private dpr = 1

  // Joystick state set by input handler
  joystickKnob  = { x: 0, y: 0 }
  joystickActive = false
  safeBottom = 0

  constructor(canvas: HTMLCanvasElement) {
    this.canvas = canvas
    this.ctx = canvas.getContext('2d')!
    this.resize()
  }

  resize(): void {
    this.dpr = window.devicePixelRatio || 1
    this.w   = window.innerWidth
    this.h   = window.innerHeight
    this.canvas.width  = this.w * this.dpr
    this.canvas.height = this.h * this.dpr
    this.canvas.style.width  = this.w + 'px'
    this.canvas.style.height = this.h + 'px'
  }

  /** Center of joystick base in CSS px */
  joystickCenter(): { x: number; y: number } {
    return {
      x: this.w - 18 - 52,
      y: this.h - 40 - this.safeBottom - 52,
    }
  }

  /** Ship anchor on screen — slightly above center */
  private shipScreen(): { x: number; y: number } {
    return { x: this.w / 2, y: this.h * 0.42 }
  }

  /** World-to-screen coordinate transform */
  private w2s(wx: number, wy: number, ship: { posX: number; posY: number }): { x: number; y: number } {
    const ss = this.shipScreen()
    return {
      x: ss.x + (wx - ship.posX) * SCALE,
      y: ss.y + (wy - ship.posY) * SCALE,
    }
  }

  render(state: GameState): void {
    const ctx = this.ctx
    const dpr = this.dpr
    ctx.setTransform(dpr, 0, 0, dpr, 0, 0)
    ctx.clearRect(0, 0, this.w, this.h)

    // ── 1. Background stars (screen-space) ─────────────────────────────────
    for (const star of state.stars) {
      ctx.beginPath()
      ctx.arc(star.x, star.y, star.size / 2, 0, Math.PI * 2)
      ctx.fillStyle = `rgba(255,255,255,${star.opacity})`
      ctx.fill()
    }

    // ── 2. Scanner range ring ───────────────────────────────────────────────
    const sr = shipScannerRange(state.ship) * SCALE
    const ss = this.shipScreen()
    ctx.beginPath()
    ctx.arc(ss.x, ss.y, sr, 0, Math.PI * 2)
    ctx.strokeStyle = 'rgba(0,229,255,0.07)'
    ctx.lineWidth = 1
    ctx.stroke()

    // ── 3. World locations ──────────────────────────────────────────────────
    for (const loc of state.universe) {
      const sp = this.w2s(loc.posX, loc.posY, state.ship)
      if (sp.x < -80 || sp.x > this.w + 80 || sp.y < -80 || sp.y > this.h + 80) continue

      if (!loc.isDiscovered) {
        // Ghost blip for almost-in-range
        const d = dist2d(loc.posX, loc.posY, state.ship.posX, state.ship.posY)
        if (d < shipScannerRange(state.ship) * 1.4) {
          ctx.beginPath(); ctx.arc(sp.x, sp.y, 1.5, 0, Math.PI * 2)
          ctx.fillStyle = 'rgba(150,150,150,0.25)'; ctx.fill()
        }
        continue
      }

      const info  = LOCATION_TYPE_INFO[loc.type]
      const r     = info.isStation ? 5 : 7
      const color = info.mapColor

      // Docking ring
      if (state.nearbyLocation?.id === loc.id) {
        ctx.beginPath(); ctx.arc(sp.x, sp.y, 22, 0, Math.PI * 2)
        ctx.strokeStyle = 'rgba(0,229,255,0.85)'
        ctx.lineWidth = 1.5
        ctx.setLineDash([5, 4]); ctx.stroke(); ctx.setLineDash([])
      }

      // Glow
      ctx.beginPath(); ctx.arc(sp.x, sp.y, r + 2, 0, Math.PI * 2)
      ctx.fillStyle = color + '33'; ctx.fill()

      // Dot
      ctx.beginPath(); ctx.arc(sp.x, sp.y, r, 0, Math.PI * 2)
      ctx.fillStyle = color; ctx.fill()

      // Label (fade in when within 3000 units)
      const d = dist2d(loc.posX, loc.posY, state.ship.posX, state.ship.posY)
      if (d < 3000) {
        const alpha = Math.min(1, (3000 - d) / 1500)
        ctx.fillStyle = `rgba(255,255,255,${alpha})`
        ctx.font = '600 9px -apple-system, sans-serif'
        ctx.textAlign = 'center'
        ctx.fillText(`${info.emoji} ${loc.name}`, sp.x, sp.y + r + 10)
      }
    }
    ctx.textAlign = 'left'

    // ── 4. Navigation arrows for off-screen discovered locations ────────────
    if (!shipIsDocked(state.ship)) {
      const arrowMargin = 30
      const left = arrowMargin, right = this.w - arrowMargin
      const top = arrowMargin, bottom = this.h - arrowMargin
      const cx = ss.x, cy = ss.y

      for (const loc of state.universe) {
        if (!loc.isDiscovered) continue
        const sp2 = this.w2s(loc.posX, loc.posY, state.ship)
        if (sp2.x >= left && sp2.x <= right && sp2.y >= top && sp2.y <= bottom) continue

        const dx = loc.posX - state.ship.posX
        const dy = loc.posY - state.ship.posY
        const angle = Math.atan2(dy, dx)
        const cosA = Math.cos(angle), sinA = Math.sin(angle)
        const eps = 1e-6

        let tMin = 99999
        if (cosA >  eps) tMin = Math.min(tMin, (right  - cx) / cosA)
        else if (cosA < -eps) tMin = Math.min(tMin, (left   - cx) / cosA)
        if (sinA >  eps) tMin = Math.min(tMin, (bottom - cy) / sinA)
        else if (sinA < -eps) tMin = Math.min(tMin, (top    - cy) / sinA)

        const ax = cx + cosA * tMin
        const ay = cy + sinA * tMin
        const color = LOCATION_TYPE_INFO[loc.type].mapColor
        const arrowSize = 7

        ctx.save()
        ctx.translate(ax, ay)
        ctx.rotate(angle)
        ctx.beginPath()
        ctx.moveTo(arrowSize, 0)
        ctx.lineTo(-arrowSize * 0.6, -arrowSize * 0.5)
        ctx.lineTo(-arrowSize * 0.6,  arrowSize * 0.5)
        ctx.closePath()
        ctx.fillStyle = color + 'E6'
        ctx.fill()
        ctx.restore()

        // Distance label
        const dist = dist2d(loc.posX, loc.posY, state.ship.posX, state.ship.posY)
        const distLabel = dist >= 1000 ? (dist / 1000).toFixed(1) + 'k' : Math.round(dist).toString()
        ctx.fillStyle = 'rgba(255,255,255,0.65)'
        ctx.font = 'bold 7px -apple-system, sans-serif'
        ctx.textAlign = 'center'
        ctx.fillText(distLabel, ax - cosA * 14, ay - sinA * 14 + 3)
        ctx.textAlign = 'left'
      }
    }

    // ── 5. Ship ─────────────────────────────────────────────────────────────
    if (!shipIsDocked(state.ship)) {
      this.drawShip(ss.x, ss.y, state.ship.heading)

      // ── 6. Engine exhaust ───────────────────────────────────────────────
      const throttle = Math.sqrt(state.joystick.x ** 2 + state.joystick.y ** 2)
      if (throttle > 0.08 && state.ship.fuel > 0) {
        this.drawExhaust(ss.x, ss.y, state.ship.heading, throttle)
      }
    }

    // ── 6. Joystick ─────────────────────────────────────────────────────────
    if (!shipIsDocked(state.ship)) {
      const jc = this.joystickCenter()
      this.drawJoystick(jc.x, jc.y, this.joystickKnob, this.joystickActive)
    }
  }

  // ── Drawing helpers ───────────────────────────────────────────────────────

  private drawShip(cx: number, cy: number, heading: number): void {
    const ctx = this.ctx
    ctx.save()
    ctx.translate(cx, cy); ctx.rotate(heading)
    ctx.beginPath()
    ctx.moveTo(0, -12);  ctx.lineTo(7, 8)
    ctx.lineTo(2, 4);    ctx.lineTo(0, 8)
    ctx.lineTo(-2, 4);   ctx.lineTo(-7, 8)
    ctx.closePath()
    ctx.fillStyle   = '#00E5FF'
    ctx.fill()
    ctx.strokeStyle = 'rgba(255,255,255,0.65)'
    ctx.lineWidth   = 0.8
    ctx.stroke()
    ctx.restore()
  }

  private drawExhaust(cx: number, cy: number, heading: number, intensity: number): void {
    const ctx = this.ctx
    const len = 6 + intensity * 20
    ctx.save()
    ctx.translate(cx, cy); ctx.rotate(heading)
    ctx.lineCap = 'round'
    ctx.beginPath()
    ctx.moveTo(-2, 8); ctx.quadraticCurveTo(0, 8 + len, 2, 8)
    ctx.strokeStyle = `rgba(255,165,0,${0.75 * intensity})`
    ctx.lineWidth   = 3 + intensity * 2
    ctx.stroke()
    ctx.beginPath()
    ctx.moveTo(-1, 8); ctx.quadraticCurveTo(0, 8 + len * 0.4, 1, 8)
    ctx.strokeStyle = `rgba(255,255,255,${0.5 * intensity})`
    ctx.lineWidth   = 1.5
    ctx.stroke()
    ctx.restore()
  }

  private drawJoystick(
    cx: number, cy: number,
    knob: { x: number; y: number },
    active: boolean
  ): void {
    const ctx = this.ctx
    const br  = 52  // base radius
    const kr  = 24  // knob radius

    // Base fill
    ctx.beginPath(); ctx.arc(cx, cy, br, 0, Math.PI * 2)
    ctx.fillStyle = active ? 'rgba(255,255,255,0.12)' : 'rgba(255,255,255,0.06)'
    ctx.fill()

    // Outer ring
    ctx.beginPath(); ctx.arc(cx, cy, br, 0, Math.PI * 2)
    ctx.strokeStyle = active ? 'rgba(255,255,255,0.45)' : 'rgba(255,255,255,0.2)'
    ctx.lineWidth = 1.5; ctx.stroke()

    // Crosshairs
    ctx.beginPath()
    ctx.moveTo(cx, cy - br + 8); ctx.lineTo(cx, cy + br - 8)
    ctx.moveTo(cx - br + 8, cy); ctx.lineTo(cx + br - 8, cy)
    ctx.strokeStyle = 'rgba(255,255,255,0.08)'; ctx.lineWidth = 0.8; ctx.stroke()

    // Knob
    const kx = cx + knob.x, ky = cy + knob.y
    const g = ctx.createRadialGradient(kx - kr * 0.4, ky - kr * 0.4, 0, kx, ky, kr * 2)
    g.addColorStop(0, 'rgba(0,229,255,0.9)')
    g.addColorStop(1, 'rgba(0,100,255,0.7)')
    ctx.beginPath(); ctx.arc(kx, ky, kr, 0, Math.PI * 2)
    ctx.fillStyle = g; ctx.fill()

    // Knob glow
    ctx.beginPath(); ctx.arc(kx, ky, kr + 3, 0, Math.PI * 2)
    ctx.strokeStyle = 'rgba(0,229,255,0.35)'; ctx.lineWidth = 5; ctx.stroke()
  }
}
