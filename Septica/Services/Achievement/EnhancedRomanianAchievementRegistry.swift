import Foundation

/// Backwards compatible façade that previously provided a large catalogue of achievements.
/// The simplified system now defers to `AchievementRegistry` which already seeds a small set
/// of achievements suitable for development builds.
final class EnhancedRomanianAchievementRegistry {
    static let shared = EnhancedRomanianAchievementRegistry()

    private let registry: AchievementRegistry

    private init(registry: AchievementRegistry = .shared) {
        self.registry = registry
        if registry.all().isEmpty {
            RomanianCulturalAchievementManager.bootstrapSampleAchievements(into: registry)
        }
    }

    func allAchievements() -> [RomanianAchievement] {
        registry.all()
    }

    func achievements(in category: AchievementCategory) -> [RomanianAchievement] {
        registry.achievements(for: category)
    }
}
