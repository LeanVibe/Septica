import SwiftUI

struct AchievementView: View {
    @StateObject private var achievementManager = AchievementManager.shared

    var body: some View {
        List(achievementManager.achievements) { achievement in
            VStack(alignment: .leading, spacing: 4) {
                Text(achievement.titleKey)
                    .font(.headline)
                Text(achievement.descriptionKey)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .navigationTitle("Achievements")
    }
}
