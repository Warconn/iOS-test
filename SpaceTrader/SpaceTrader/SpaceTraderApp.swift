import SwiftUI

@main
struct SpaceTraderApp: App {
    @StateObject private var gameViewModel = GameViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(gameViewModel)
                .preferredColorScheme(.dark)
        }
    }
}
