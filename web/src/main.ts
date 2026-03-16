import { GameState } from './game.ts'
import { Renderer } from './renderer.ts'
import { UIManager } from './ui.ts'

// ─── Init ────────────────────────────────────────────────────────────────────
const canvas = document.getElementById('canvas') as HTMLCanvasElement

// Read safe-area-inset-bottom via CSS env()
const safeEl = document.createElement('div')
safeEl.style.cssText = 'position:fixed;bottom:0;height:env(safe-area-inset-bottom,0px);pointer-events:none'
document.body.appendChild(safeEl)
const safeBottom = () => safeEl.getBoundingClientRect().height || 0

const state    = new GameState()
const renderer = new Renderer(canvas)
const ui       = new UIManager(state)

renderer.safeBottom = safeBottom()

// ─── Wire GameState callbacks ────────────────────────────────────────────────
state.onHUDChange   = () => ui.updateHUD()
state.onDockChange  = (loc) => loc ? ui.showDockButton(loc) : ui.hideDockButton()
state.onStationOpen = () => { ui.openStation(); ui.updateHUD() }
state.onStationClose = () => { ui.closeStation(); ui.updateHUD() }
state.onNotification = (msg) => ui.showNotification(msg)

// If we start docked (first launch), open station immediately
if (state.currentLocation) {
  ui.openStation()
}
ui.updateHUD()

// ─── Joystick touch handling ─────────────────────────────────────────────────
let joystickTouchId: number | null = null

function getJoystickCenter() {
  return renderer.joystickCenter()
}

function updateJoystick(clientX: number, clientY: number) {
  const jc   = getJoystickCenter()
  const dx   = clientX - jc.x
  const dy   = clientY - jc.y
  const dist = Math.sqrt(dx * dx + dy * dy)
  const baseR = 52

  let vx: number, vy: number, kx: number, ky: number
  if (dist <= baseR) {
    vx = dx / baseR; vy = dy / baseR; kx = dx; ky = dy
  } else {
    const angle = Math.atan2(dy, dx)
    vx = Math.cos(angle); vy = Math.sin(angle)
    kx = vx * baseR;     ky = vy * baseR
  }

  state.joystick        = { x: vx, y: vy }
  renderer.joystickKnob  = { x: kx, y: ky }
  renderer.joystickActive = true
}

function resetJoystick() {
  state.joystick         = { x: 0, y: 0 }
  renderer.joystickKnob  = { x: 0, y: 0 }
  renderer.joystickActive = false
  joystickTouchId = null
}

canvas.addEventListener('touchstart', (e) => {
  e.preventDefault()
  for (const touch of Array.from(e.changedTouches)) {
    if (joystickTouchId !== null) continue
    const jc   = getJoystickCenter()
    const dx   = touch.clientX - jc.x
    const dy   = touch.clientY - jc.y
    const dist = Math.sqrt(dx * dx + dy * dy)
    if (dist <= 52 + 20) {  // +20 px buffer for easy grab
      joystickTouchId = touch.identifier
      updateJoystick(touch.clientX, touch.clientY)
    }
  }
}, { passive: false })

canvas.addEventListener('touchmove', (e) => {
  e.preventDefault()
  for (const touch of Array.from(e.changedTouches)) {
    if (touch.identifier === joystickTouchId) {
      updateJoystick(touch.clientX, touch.clientY)
    }
  }
}, { passive: false })

canvas.addEventListener('touchend', (e) => {
  for (const touch of Array.from(e.changedTouches)) {
    if (touch.identifier === joystickTouchId) {
      resetJoystick()
    }
  }
}, { passive: false })

canvas.addEventListener('touchcancel', () => resetJoystick(), { passive: false })

// ─── Window resize ────────────────────────────────────────────────────────────
window.addEventListener('resize', () => {
  renderer.resize()
  renderer.safeBottom = safeBottom()
})

// ─── Game loop ────────────────────────────────────────────────────────────────
let lastTime = performance.now()

function loop(now: number) {
  const dt = Math.min((now - lastTime) / 1000, 0.1)  // cap at 100ms
  lastTime = now

  state.tick(dt)
  renderer.render(state)

  requestAnimationFrame(loop)
}

requestAnimationFrame(loop)
