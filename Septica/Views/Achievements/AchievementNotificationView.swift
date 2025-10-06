import SwiftUI

/// Achievement unlock notification banner
/// Displays when player unlocks an achievement
struct AchievementNotificationView: View {
    let achievement: RomanianAchievement
    @State private var isVisible = false
    @State private var offset: CGFloat = -200

    var body: some View {
        HStack(spacing: 16) {
            // Achievement badge icon
            ZStack {
                Circle()
                    .fill(badgeColor.gradient)
                    .frame(width: 60, height: 60)

                Image(systemName: achievement.badge.iconName)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
            }

            // Achievement details
            VStack(alignment: .leading, spacing: 4) {
                Text("Achievement Unlocked!")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)

                Text(achievement.titleKey)
                    .font(.headline)
                    .fontWeight(.bold)

                Text(achievement.descriptionKey)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)

                HStack(spacing: 12) {
                    Label("\(achievement.experiencePoints) XP", systemImage: "star.fill")
                        .font(.caption)
                        .foregroundColor(.orange)

                    Label("\(achievement.culturalPoints) CP", systemImage: "bookmark.fill")
                        .font(.caption)
                        .foregroundColor(.purple)
                }
            }

            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(uiColor: .systemBackground))
                .shadow(color: badgeColor.opacity(0.3), radius: 10, x: 0, y: 5)
        )
        .padding(.horizontal)
        .offset(y: offset)
        .opacity(isVisible ? 1 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                isVisible = true
                offset = 0
            }

            // Auto-dismiss after 4 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                withAnimation(.easeInOut(duration: 0.3)) {
                    offset = -200
                    isVisible = false
                }
            }
        }
    }

    private var badgeColor: Color {
        switch achievement.badge.tint {
        case .bronze:
            return Color.brown
        case .silver:
            return Color.gray
        case .gold:
            return Color.yellow
        case .cultural:
            return Color.purple
        }
    }
}

/// Achievement notification overlay modifier
struct AchievementNotificationModifier: ViewModifier {
    @StateObject private var achievementService = AchievementTrackingService.shared
    @State private var currentNotification: AchievementUnlock?
    @State private var notificationQueue: [AchievementUnlock] = []

    func body(content: Content) -> some View {
        ZStack(alignment: .top) {
            content

            if let notification = currentNotification {
                AchievementNotificationView(achievement: notification.achievement)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(1000)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .achievementUnlocked)) { notification in
            if let unlock = notification.object as? AchievementUnlock {
                handleAchievementUnlock(unlock)
            }
        }
        .onChange(of: achievementService.recentlyUnlocked) { newUnlocks in
            for unlock in newUnlocks where !notificationQueue.contains(where: { $0.id == unlock.id }) {
                notificationQueue.append(unlock)
            }
            showNextNotification()
        }
    }

    private func handleAchievementUnlock(_ unlock: AchievementUnlock) {
        notificationQueue.append(unlock)
        showNextNotification()
    }

    private func showNextNotification() {
        guard currentNotification == nil, !notificationQueue.isEmpty else { return }

        currentNotification = notificationQueue.removeFirst()

        // Clear notification after display duration
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.5) {
            currentNotification = nil

            // Show next notification if available
            if !notificationQueue.isEmpty {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    showNextNotification()
                }
            }
        }
    }
}

extension View {
    /// Add achievement notification overlay to any view
    func achievementNotifications() -> some View {
        modifier(AchievementNotificationModifier())
    }
}
