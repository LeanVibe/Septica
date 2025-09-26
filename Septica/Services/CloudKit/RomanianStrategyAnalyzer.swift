import Foundation
import Combine

@MainActor
final class RomanianStrategyAnalyzer: ObservableObject {
    @Published private(set) var lastAnalysisDate: Date?
    @Published private(set) var authenticityScore: Float = 0.5

    func analyzeRecentGames(_ records: [CloudKitGameRecord]) {
        lastAnalysisDate = Date()
        authenticityScore = records.isEmpty ? 0.5 : 0.7
    }
}
