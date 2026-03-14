import SwiftUI

struct ContentView: View {
    @EnvironmentObject var vm: GameViewModel
    @State private var selectedTab: Int = 0

    var body: some View {
        ZStack(alignment: .bottom) {
            // Background gradient
            LinearGradient(
                colors: [Color(hex: "#0D0D1A"), Color(hex: "#1A0D2E")],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            // Tab content
            TabView(selection: $selectedTab) {
                BattleView()
                    .tag(0)
                HeroView()
                    .tag(1)
                ShopView()
                    .tag(2)
                SkillsView()
                    .tag(3)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            // Custom bottom tab bar
            BottomTabBar(selectedTab: $selectedTab)
        }
        .ignoresSafeArea(edges: .bottom)
    }
}

struct BottomTabBar: View {
    @Binding var selectedTab: Int
    @EnvironmentObject var vm: GameViewModel

    private let tabs: [(icon: String, label: String)] = [
        ("⚔️", "Battle"),
        ("🧙", "Hero"),
        ("🏪", "Shop"),
        ("🎯", "Skills"),
    ]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(tabs.indices, id: \.self) { i in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) { selectedTab = i }
                } label: {
                    VStack(spacing: 3) {
                        Text(tabs[i].icon).font(.system(size: 22))
                        Text(tabs[i].label)
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(selectedTab == i ? Color(hex: "#FFD700") : .gray)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        selectedTab == i
                            ? Color.white.opacity(0.07)
                            : Color.clear
                    )
                }
                .overlay(alignment: .top) {
                    if i == 1 && vm.hero.statPoints > 0 {
                        Circle().fill(.red).frame(width: 8, height: 8)
                            .offset(x: 14, y: 2)
                    }
                }
            }
        }
        .background(
            Color(hex: "#1A1A2E")
                .shadow(color: .black.opacity(0.6), radius: 8, y: -2)
        )
        .padding(.bottom, 0)
    }
}

// MARK: – Color extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: (a, r, g, b) = (255, (int >> 8)*17, (int >> 4 & 0xF)*17, (int & 0xF)*17)
        case 6: (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:(a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red:   Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: – Shared progress bar
struct StatBar: View {
    let value: Double      // 0–1
    let color: Color
    let height: CGFloat

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: height / 2)
                    .fill(Color.white.opacity(0.12))
                RoundedRectangle(cornerRadius: height / 2)
                    .fill(color)
                    .frame(width: geo.size.width * max(0, min(1, value)))
                    .animation(.easeInOut(duration: 0.3), value: value)
            }
        }
        .frame(height: height)
    }
}
