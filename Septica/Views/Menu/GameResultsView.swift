import SwiftUI

struct GameResultsView: View {
    let history: [CompletedGameRecord]

    var body: some View {
        List(history, id: \.id) { record in
            VStack(alignment: .leading) {
                Text("Game: \(record.id.uuidString)")
                Text("Duration: \(record.endTime.timeIntervalSince(record.startTime), specifier: "%.0f")s")
                    .font(.caption)
            }
        }
        .navigationTitle("Results")
    }
}
