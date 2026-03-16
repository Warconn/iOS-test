import SwiftUI

struct ContentView: View {
    @EnvironmentObject var vm: GameViewModel

    var body: some View {
        SpaceFlightView()
            .ignoresSafeArea()
            .sheet(isPresented: $vm.showingStation) {
                StationView()
                    .environmentObject(vm)
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
            }
    }
}
