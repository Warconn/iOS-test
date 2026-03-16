import SwiftUI

// MARK: – Main flight screen

struct SpaceFlightView: View {
    @EnvironmentObject var vm: GameViewModel
    @State private var showingStarMap = false

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .bottomTrailing) {
                // ─── Deep space background ────────────────────────────
                Color.black.ignoresSafeArea()

                // ─── Star canvas + world ──────────────────────────────
                SpaceCanvas(size: geo.size)
                    .allowsHitTesting(false)

                // ─── HUD overlay ──────────────────────────────────────
                HUDView()
                    .allowsHitTesting(false)

                // ─── Dock button (appears when near a location) ───────
                if let loc = vm.nearbyLocation, !vm.ship.isDocked {
                    VStack {
                        Spacer()
                        HStack {
                            Button(action: { vm.dock() }) {
                                Label("Dock at \(loc.name)", systemImage: "arrow.down.circle.fill")
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundColor(.black)
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 15)
                                    .background(Capsule().fill(Color.cyan))
                                    .shadow(color: .cyan.opacity(0.6), radius: 10)
                            }
                            .buttonStyle(.plain)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.bottom, 148)  // above joystick
                    }
                    .transition(.scale(scale: 0.8).combined(with: .opacity))
                    .animation(.spring(response: 0.35, dampingFraction: 0.7), value: loc.id)
                }

                // ─── Out-of-fuel warning ──────────────────────────────
                if vm.ship.fuelPercent < 0.15 && !vm.ship.isDocked {
                    VStack {
                        Spacer()
                        Text("⚠️ FUEL CRITICAL — Dock to refuel!")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.red)
                            .padding(.horizontal, 14).padding(.vertical, 6)
                            .background(Capsule().fill(Color.red.opacity(0.18)))
                            .padding(.bottom, 210)
                    }
                }

                // ─── Star Map button (bottom-left) ────────────────────
                if !vm.ship.isDocked {
                    VStack {
                        Spacer()
                        HStack {
                            Button(action: { withAnimation(.easeInOut(duration: 0.25)) { showingStarMap.toggle() } }) {
                                Image(systemName: showingStarMap ? "map.fill" : "map")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(showingStarMap ? .black : .cyan.opacity(0.85))
                                    .frame(width: 44, height: 44)
                                    .background(Circle().fill(showingStarMap ? Color.cyan : Color.black.opacity(0.6)))
                                    .overlay(Circle().strokeBorder(Color.cyan.opacity(0.4), lineWidth: 1))
                            }
                            .buttonStyle(.plain)
                            .padding(.leading, 18)
                            .padding(.bottom, 48)
                            Spacer()
                        }
                    }
                }

                // ─── Joystick ─────────────────────────────────────────
                JoystickView(vector: $vm.joystickVector)
                    .padding(.trailing, 18)
                    .padding(.bottom, 40)
                    .opacity(vm.ship.isDocked ? 0 : 1)

                // ─── Star Map overlay ─────────────────────────────────
                if showingStarMap {
                    StarMapView(isShowing: $showingStarMap)
                        .transition(.opacity.combined(with: .scale(scale: 0.97)))
                }
            }
        }
        .ignoresSafeArea(edges: .bottom)
    }
}

// MARK: – Space Canvas (the game world rendered via SwiftUI Canvas)

struct SpaceCanvas: View {
    @EnvironmentObject var vm: GameViewModel
    let size: CGSize

    private let scale: CGFloat = 0.08  // 1 world unit = 0.08 screen pts; viewport ≈ 4875 wide

    var shipScreen: CGPoint {
        CGPoint(x: size.width / 2, y: size.height * 0.42)
    }

    func w2s(_ world: CGPoint) -> CGPoint {
        CGPoint(
            x: shipScreen.x + (world.x - vm.ship.posX) * scale,
            y: shipScreen.y + (world.y - vm.ship.posY) * scale
        )
    }

    var body: some View {
        Canvas { context, _ in

            // ── 1. Background stars (screen-space, don't move) ──
            for star in vm.backgroundStars {
                let rect = CGRect(x: star.x, y: star.y, width: star.size, height: star.size)
                context.fill(Path(ellipseIn: rect), with: .color(.white.opacity(star.opacity)))
            }

            // ── 2. Scanner range ring ────────────────────────────
            let sr = vm.ship.scannerRange * scale
            let srRect = CGRect(x: shipScreen.x - sr, y: shipScreen.y - sr, width: sr * 2, height: sr * 2)
            context.stroke(Path(ellipseIn: srRect),
                           with: .color(.cyan.opacity(0.07)),
                           style: StrokeStyle(lineWidth: 1))

            // ── 3. World locations ───────────────────────────────
            for loc in vm.universe {
                let sp = w2s(loc.position)
                // Cull off-screen
                guard sp.x > -80 && sp.x < size.width + 80 &&
                      sp.y > -80 && sp.y < size.height + 80 else { continue }

                if !loc.isDiscovered {
                    // Ghost blip for undiscovered within 1.5× scanner range
                    let dist = loc.position.distance(to: vm.ship.position)
                    if dist < vm.ship.scannerRange * 1.4 {
                        let r: CGFloat = 1.5
                        context.fill(Path(ellipseIn: CGRect(x: sp.x-r, y: sp.y-r, width: r*2, height: r*2)),
                                     with: .color(.gray.opacity(0.25)))
                    }
                    continue
                }

                // Docking ring
                if vm.nearbyLocation?.id == loc.id {
                    let rr: CGFloat = 22
                    context.stroke(
                        Path(ellipseIn: CGRect(x: sp.x-rr, y: sp.y-rr, width: rr*2, height: rr*2)),
                        with: .color(.cyan.opacity(0.85)),
                        style: StrokeStyle(lineWidth: 1.5, dash: [5, 4])
                    )
                }

                // Location dot
                let r: CGFloat = loc.type.isStation ? 5 : 7
                let colorHex = loc.type.mapColorHex
                let fillColor = Color(hex: colorHex)
                context.fill(Path(ellipseIn: CGRect(x: sp.x-r, y: sp.y-r, width: r*2, height: r*2)),
                             with: .color(fillColor))
                // Glow
                context.fill(Path(ellipseIn: CGRect(x: sp.x-r-2, y: sp.y-r-2, width: (r+2)*2, height: (r+2)*2)),
                             with: .color(fillColor.opacity(0.2)))

                // Label (fade in as ship approaches)
                let dist = loc.position.distance(to: vm.ship.position)
                if dist < 3000 {
                    let alpha = Double(min(1, (3000 - dist) / 1500))
                    context.draw(
                        Text(loc.type.emoji + " " + loc.name)
                            .font(.system(size: 9, weight: .medium))
                            .foregroundColor(.white.opacity(alpha)),
                        at: CGPoint(x: sp.x, y: sp.y + r + 9)
                    )
                }
            }

            // ── 4. Navigation arrows for off-screen discovered locations ──
            let arrowMargin: CGFloat = 30
            let left = arrowMargin, right = size.width - arrowMargin
            let top = arrowMargin, bottom = size.height - arrowMargin
            let cx = shipScreen.x, cy = shipScreen.y

            for loc in vm.universe where loc.isDiscovered {
                let sp = w2s(loc.position)
                // Skip if on-screen with a bit of buffer
                guard sp.x < left || sp.x > right || sp.y < top || sp.y > bottom else { continue }

                let dx = loc.posX - vm.ship.posX
                let dy = loc.posY - vm.ship.posY
                let angle = atan2(dy, dx)
                let cosA = cos(angle), sinA = sin(angle)
                let eps: CGFloat = 1e-6

                // Find where ray from ship-center hits screen edge
                var tMin: CGFloat = 99999
                if cosA >  eps { tMin = min(tMin, (right  - cx) / cosA) }
                else if cosA < -eps { tMin = min(tMin, (left   - cx) / cosA) }
                if sinA >  eps { tMin = min(tMin, (bottom - cy) / sinA) }
                else if sinA < -eps { tMin = min(tMin, (top    - cy) / sinA) }

                let arrowPos = CGPoint(x: cx + cosA * tMin, y: cy + sinA * tMin)
                let t = CGAffineTransform(translationX: arrowPos.x, y: arrowPos.y).rotated(by: angle)

                let arrowSize: CGFloat = 7
                var arrow = Path()
                arrow.move(to:    CGPoint(x:  arrowSize,       y:  0))
                arrow.addLine(to: CGPoint(x: -arrowSize * 0.6, y: -arrowSize * 0.5))
                arrow.addLine(to: CGPoint(x: -arrowSize * 0.6, y:  arrowSize * 0.5))
                arrow.closeSubpath()

                let color = Color(hex: loc.type.mapColorHex)
                context.fill(arrow.applying(t), with: .color(color.opacity(0.9)))

                // Distance label
                let dist = loc.position.distance(to: vm.ship.position)
                let distLabel = dist >= 1000 ? String(format: "%.1fk", dist / 1000) : "\(Int(dist))"
                context.draw(
                    Text(distLabel)
                        .font(.system(size: 7, weight: .bold))
                        .foregroundColor(.white.opacity(0.65)),
                    at: CGPoint(x: arrowPos.x - cosA * 14, y: arrowPos.y - sinA * 14)
                )
            }

            // ── 5. Ship ──────────────────────────────────────────
            drawShip(&context, at: shipScreen, heading: vm.ship.heading)

            // ── 6. Engine exhaust ────────────────────────────────
            let throttle = vm.joystickVector.magnitude
            if throttle > 0.08 && !vm.ship.isDocked && vm.ship.fuel > 0 {
                drawExhaust(&context, at: shipScreen, heading: vm.ship.heading, intensity: CGFloat(throttle))
            }

        } // end Canvas
    }

    // MARK: Ship drawing

    private func drawShip(_ ctx: inout GraphicsContext, at center: CGPoint, heading: CGFloat) {
        let t = CGAffineTransform(translationX: center.x, y: center.y).rotated(by: heading)
        var body = Path()
        body.move(to:    CGPoint(x:  0, y: -12))   // nose
        body.addLine(to: CGPoint(x:  7, y:  8))    // right wing tip
        body.addLine(to: CGPoint(x:  2, y:  4))    // right inner
        body.addLine(to: CGPoint(x:  0, y:  8))    // center rear
        body.addLine(to: CGPoint(x: -2, y:  4))    // left inner
        body.addLine(to: CGPoint(x: -7, y:  8))    // left wing tip
        body.closeSubpath()

        ctx.fill(body.applying(t), with: .color(Color(hex: "#00E5FF")))
        ctx.stroke(body.applying(t), with: .color(.white.opacity(0.65)), lineWidth: 0.8)
    }

    private func drawExhaust(_ ctx: inout GraphicsContext, at center: CGPoint, heading: CGFloat, intensity: CGFloat) {
        let t = CGAffineTransform(translationX: center.x, y: center.y).rotated(by: heading)
        let len: CGFloat = 6 + intensity * 20
        var flame = Path()
        flame.move(to:      CGPoint(x: -2, y: 8))
        flame.addQuadCurve(to: CGPoint(x: 2, y: 8), control: CGPoint(x: 0, y: 8 + len))
        ctx.stroke(flame.applying(t), with: .color(Color.orange.opacity(0.75 * intensity)), lineWidth: 3 + intensity * 2)

        // Inner white core
        var core = Path()
        core.move(to:      CGPoint(x: -1, y: 8))
        core.addQuadCurve(to: CGPoint(x: 1, y: 8), control: CGPoint(x: 0, y: 8 + len * 0.4))
        ctx.stroke(core.applying(t), with: .color(.white.opacity(0.5 * intensity)), lineWidth: 1.5)
    }
}

// MARK: – Star Map overlay

struct StarMapView: View {
    @EnvironmentObject var vm: GameViewModel
    @Binding var isShowing: Bool

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color.black.opacity(0.93).ignoresSafeArea()

                Canvas { ctx, canvasSize in
                    let padding: CGFloat = 48
                    let mapW = canvasSize.width  - padding * 2
                    let mapH = canvasSize.height - padding * 2
                    let mapScale = min(mapW, mapH) / Universe.size
                    let offX = (canvasSize.width  - Universe.size * mapScale) / 2
                    let offY = (canvasSize.height - Universe.size * mapScale) / 2

                    func toScreen(_ p: CGPoint) -> CGPoint {
                        CGPoint(x: offX + p.x * mapScale, y: offY + p.y * mapScale)
                    }

                    // Map border
                    let borderRect = CGRect(x: offX, y: offY,
                                           width:  Universe.size * mapScale,
                                           height: Universe.size * mapScale)
                    ctx.stroke(Path(borderRect),
                               with: .color(.white.opacity(0.08)),
                               lineWidth: 1)

                    // Locations
                    for loc in vm.universe {
                        let sp = toScreen(loc.position)
                        if !loc.isDiscovered {
                            ctx.fill(Path(ellipseIn: CGRect(x: sp.x-1.5, y: sp.y-1.5, width: 3, height: 3)),
                                     with: .color(.gray.opacity(0.18)))
                            continue
                        }
                        let r: CGFloat = 3.5
                        let color = Color(hex: loc.type.mapColorHex)
                        // Glow
                        ctx.fill(Path(ellipseIn: CGRect(x: sp.x-(r+2), y: sp.y-(r+2), width: (r+2)*2, height: (r+2)*2)),
                                 with: .color(color.opacity(0.2)))
                        // Dot
                        ctx.fill(Path(ellipseIn: CGRect(x: sp.x-r, y: sp.y-r, width: r*2, height: r*2)),
                                 with: .color(color))
                        // Label
                        ctx.draw(
                            Text(loc.type.emoji + " " + loc.name)
                                .font(.system(size: 7, weight: .medium))
                                .foregroundColor(.white.opacity(0.55)),
                            at: CGPoint(x: sp.x, y: sp.y + r + 7)
                        )
                    }

                    // Ship position
                    let shipSP = toScreen(vm.ship.position)
                    let st = CGAffineTransform(translationX: shipSP.x, y: shipSP.y)
                               .rotated(by: vm.ship.heading)
                    var shipShape = Path()
                    shipShape.move(to:    CGPoint(x:  0, y: -5))
                    shipShape.addLine(to: CGPoint(x:  3, y:  3))
                    shipShape.addLine(to: CGPoint(x:  0, y:  2))
                    shipShape.addLine(to: CGPoint(x: -3, y:  3))
                    shipShape.closeSubpath()
                    ctx.fill(shipShape.applying(st), with: .color(.cyan))
                    // Pulse ring around ship
                    ctx.stroke(Path(ellipseIn: CGRect(x: shipSP.x-6, y: shipSP.y-6, width: 12, height: 12)),
                               with: .color(.cyan.opacity(0.5)),
                               lineWidth: 1)
                }

                // Title + close + legend
                VStack(spacing: 0) {
                    HStack {
                        Text("STAR MAP")
                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                            .foregroundColor(.cyan)
                        Spacer()
                        Button(action: { withAnimation(.easeInOut(duration: 0.2)) { isShowing = false } }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.white.opacity(0.55))
                                .font(.system(size: 22))
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)

                    HStack(spacing: 16) {
                        Label("Discovered", systemImage: "circle.fill")
                            .font(.system(size: 9))
                            .foregroundColor(.white.opacity(0.45))
                        Label("Unknown", systemImage: "circle.fill")
                            .font(.system(size: 9))
                            .foregroundColor(.gray.opacity(0.35))
                        Label("Your ship", systemImage: "triangle.fill")
                            .font(.system(size: 9))
                            .foregroundColor(.cyan.opacity(0.7))
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 6)

                    Spacer()
                }
            }
        }
        .ignoresSafeArea()
    }
}

// MARK: – Color(hex:) — shared
extension Color {
    init(hex: String) {
        let h = hex.trimmingCharacters(in: .init(charactersIn: "#"))
        var n: UInt64 = 0
        Scanner(string: h).scanHexInt64(&n)
        let r, g, b: Double
        switch h.count {
        case 6: (r, g, b) = (Double((n >> 16) & 0xFF)/255, Double((n >> 8) & 0xFF)/255, Double(n & 0xFF)/255)
        default: (r, g, b) = (1, 1, 1)
        }
        self.init(red: r, green: g, blue: b)
    }
}
