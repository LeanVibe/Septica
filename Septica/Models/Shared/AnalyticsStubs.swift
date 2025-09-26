import Foundation

struct RealTimeMetrics {
    var averageProcessingTime: TimeInterval = 0
    var lastUpdated: Date = Date()
}

struct LearningProgressMetrics {
    var culturalProgress: Float = 0
    var strategyProgress: Float = 0
}

enum AuthenticityLevel: String, CaseIterable {
    case emerging
    case growing
    case master
}
