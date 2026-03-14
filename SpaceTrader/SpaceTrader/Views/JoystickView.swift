import SwiftUI

struct JoystickView: View {
    @Binding var vector: CGPoint

    private let baseRadius: CGFloat = 52
    private let knobRadius: CGFloat = 24

    @State private var knobOffset: CGSize = .zero
    @State private var isActive: Bool = false

    var body: some View {
        ZStack {
            // Outer ring
            Circle()
                .strokeBorder(Color.white.opacity(isActive ? 0.45 : 0.2), lineWidth: 1.5)
                .frame(width: baseRadius * 2, height: baseRadius * 2)

            // Base fill
            Circle()
                .fill(Color.white.opacity(isActive ? 0.12 : 0.06))
                .frame(width: baseRadius * 2, height: baseRadius * 2)

            // Direction crosshairs (subtle)
            Path { p in
                p.move(to: CGPoint(x: baseRadius, y: 8));    p.addLine(to: CGPoint(x: baseRadius, y: baseRadius * 2 - 8))
                p.move(to: CGPoint(x: 8, y: baseRadius));    p.addLine(to: CGPoint(x: baseRadius * 2 - 8, y: baseRadius))
            }
            .stroke(Color.white.opacity(0.08), lineWidth: 0.8)

            // Knob
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.cyan.opacity(0.9), Color.blue.opacity(0.7)],
                        center: .topLeading,
                        startRadius: 0,
                        endRadius: knobRadius * 2
                    )
                )
                .frame(width: knobRadius * 2, height: knobRadius * 2)
                .shadow(color: .cyan.opacity(0.5), radius: 6)
                .offset(knobOffset)
        }
        .frame(width: baseRadius * 2, height: baseRadius * 2)
        .contentShape(Circle())
        .gesture(
            DragGesture(minimumDistance: 0, coordinateSpace: .local)
                .onChanged { value in
                    isActive = true
                    // Translate so (0,0) = center of joystick base
                    let dx = value.location.x - baseRadius
                    let dy = value.location.y - baseRadius
                    let dist = sqrt(dx * dx + dy * dy)

                    if dist <= baseRadius {
                        knobOffset = CGSize(width: dx, height: dy)
                        vector = CGPoint(x: dx / baseRadius, y: dy / baseRadius)
                    } else {
                        let angle = atan2(dy, dx)
                        let cx = cos(angle) * baseRadius
                        let cy = sin(angle) * baseRadius
                        knobOffset = CGSize(width: cx, height: cy)
                        vector = CGPoint(x: cos(angle), y: sin(angle))
                    }
                }
                .onEnded { _ in
                    isActive = false
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.6)) {
                        knobOffset = .zero
                    }
                    vector = .zero
                }
        )
    }
}
