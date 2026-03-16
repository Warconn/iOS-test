import SwiftUI

struct HUDView: View {
    @EnvironmentObject var vm: GameViewModel

    var body: some View {
        VStack(spacing: 0) {
            // ── Top bar ─────────────────────────────────────────
            HStack(spacing: 12) {
                // Credits
                HStack(spacing: 4) {
                    Text("💰").font(.system(size: 13))
                    Text("\(vm.ship.credits)cr")
                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                        .foregroundColor(Color(hex: "#FFD700"))
                }
                .padding(.horizontal, 10).padding(.vertical, 5)
                .background(Capsule().fill(Color.black.opacity(0.6)))

                Spacer()

                // Fuel
                HStack(spacing: 6) {
                    Text("⛽").font(.system(size: 11))
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.white.opacity(0.12)).frame(width: 70, height: 8)
                        Capsule()
                            .fill(fuelColor)
                            .frame(width: 70 * CGFloat(vm.ship.fuelPercent), height: 8)
                    }
                    Text(String(format: "%.0f%%", vm.ship.fuelPercent * 100))
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(fuelColor)
                        .frame(width: 30, alignment: .trailing)
                }
                .padding(.horizontal, 10).padding(.vertical, 5)
                .background(Capsule().fill(Color.black.opacity(0.6)))
            }
            .padding(.horizontal, 14)
            .padding(.top, 12)

            // ── Speed & location info ────────────────────────────
            HStack {
                if !vm.ship.isDocked {
                    speedBadge
                } else if let loc = vm.currentLocation {
                    HStack(spacing: 4) {
                        Text(loc.type.emoji).font(.system(size: 11))
                        Text("Docked: \(loc.name)")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.white.opacity(0.85))
                    }
                    .padding(.horizontal, 8).padding(.vertical, 3)
                    .background(Capsule().fill(Color.black.opacity(0.5)))
                }
                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.top, 5)

            Spacer()

            // ── Discovery/action notification ────────────────────
            if let note = vm.notification {
                Text(note)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16).padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(Color.black.opacity(0.75))
                            .overlay(Capsule().strokeBorder(Color.cyan.opacity(0.4), lineWidth: 1))
                    )
                    .padding(.bottom, 170)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var speedBadge: some View {
        let currentSpeed = Int(vm.ship.maxSpeed * vm.joystickVector.magnitude)
        return Group {
            if currentSpeed > 10 {
                Text("⚡ \(currentSpeed) u/s")
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundColor(.cyan.opacity(0.8))
                    .padding(.horizontal, 8).padding(.vertical, 3)
                    .background(Capsule().fill(Color.black.opacity(0.5)))
            }
        }
    }

    private var fuelColor: Color {
        switch vm.ship.fuelPercent {
        case 0.35...: return Color(hex: "#22C55E")
        case 0.15...: return Color(hex: "#F59E0B")
        default:      return Color(hex: "#EF4444")
        }
    }
}
