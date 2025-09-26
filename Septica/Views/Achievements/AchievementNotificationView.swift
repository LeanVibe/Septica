import SwiftUI

struct AchievementNotificationView: View {
    let achievement: RomanianAchievement

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: achievement.badge.iconName)
                .font(.largeTitle)
            Text(achievement.titleKey)
                .font(.headline)
            Text(achievement.descriptionKey)
                .font(.subheadline)
        }
        .padding()
    }
}
