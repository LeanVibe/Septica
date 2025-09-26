import SwiftUI

struct MainMenuView: View {
    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                NavigationLink("Start Game") {
                    GameSetupView { _ in }
                }
                NavigationLink("Rules") {
                    RulesView()
                }
                NavigationLink("Settings") {
                    SettingsView()
                }
            }
            .padding()
            .navigationTitle("Septica")
        }
    }
}
