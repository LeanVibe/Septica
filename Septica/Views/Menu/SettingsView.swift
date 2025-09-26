import SwiftUI

struct SettingsView: View {
    @State private var soundEnabled = true

    var body: some View {
        Form {
            Toggle("Sound", isOn: $soundEnabled)
        }
        .navigationTitle("Settings")
    }
}
