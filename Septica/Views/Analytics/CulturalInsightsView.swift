//
//  CulturalInsightsView.swift
//  Septica
//
//  Romanian Cultural Analytics UI Components
//  Beautiful SwiftUI views for displaying cultural insights and analytics data
//

import SwiftUI
import Charts

/// Main view for displaying Romanian cultural analytics and insights
struct CulturalInsightsView: View {
    @StateObject private var analyticsManager: PerformanceAnalyticsManager
    @StateObject private var culturalScoring: CulturalAuthenticityScoring
    @State private var selectedTab: AnalyticsTab = .overview
    @State private var showingDetailedReport = false
    
    init(analyticsManager: PerformanceAnalyticsManager, culturalScoring: CulturalAuthenticityScoring) {
        self._analyticsManager = StateObject(wrappedValue: analyticsManager)
        self._culturalScoring = StateObject(wrappedValue: culturalScoring)
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Romanian Cultural Header
                CulturalHeaderView(
                    authenticityScore: culturalScoring.currentAuthenticityScore,
                    masteryLevel: analyticsManager.culturalMasteryLevel
                )
                .background(RomanianColors.traditionalRed.gradient)
                
                // Analytics Tab Navigation
                AnalyticsTabView(selectedTab: $selectedTab)
                
                // Main Content
                TabView(selection: $selectedTab) {
                    CulturalOverviewView(
                        analyticsManager: analyticsManager,
                        culturalScoring: culturalScoring
                    )
                    .tag(AnalyticsTab.overview)
                    
                    TraditionalPatternsView(
                        patterns: culturalScoring.traditionalPatternScore,
                        insights: analyticsManager.realTimeMetrics
                    )
                    .tag(AnalyticsTab.patterns)
                    
                    RegionalStylesView(
                        regionalScore: culturalScoring.regionalStyleScore,
                        exploredRegions: [] // Would be passed from manager
                    )
                    .tag(AnalyticsTab.regional)
                    
                    CulturalLearningView(
                        learningMetrics: analyticsManager.learningProgressMetrics,
                        recommendations: []
                    )
                    .tag(AnalyticsTab.learning)
                    
                    PerformanceMetricsView(
                        metrics: analyticsManager.realTimeMetrics,
                        performanceScore: analyticsManager.performanceScore
                    )
                    .tag(AnalyticsTab.performance)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            }
            .navigationTitle("Analize Culturale")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Raport Detaliat") {
                        showingDetailedReport = true
                    }
                    .foregroundColor(.white)
                }
            }
        }
        .sheet(isPresented: $showingDetailedReport) {
            DetailedCulturalReportView(analyticsManager: analyticsManager)
        }
    }
}

// MARK: - Cultural Header View

struct CulturalHeaderView: View {
    let authenticityScore: Float
    let masteryLevel: CulturalMasteryLevel
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Autenticitate Culturală")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text("\(Int(authenticityScore * 100))%")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Nivel Cultural")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text(masteryLevel.displayName)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.trailing)
                }
            }
            
            // Authenticity Progress Bar
            ProgressView(value: authenticityScore) {
                Text("Progres către următorul nivel")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
            }
            .tint(.white)
            .scaleEffect(x: 1, y: 2, anchor: .center)
        }
        .padding()
    }
}

// MARK: - Analytics Tab View

enum AnalyticsTab: String, CaseIterable {
    case overview = "Prezentare"
    case patterns = "Modele"
    case regional = "Regional"
    case learning = "Învățare"
    case performance = "Performanță"
    
    var icon: String {
        switch self {
        case .overview: return "chart.bar.fill"
        case .patterns: return "pattern"
        case .regional: return "map.fill"
        case .learning: return "book.fill"
        case .performance: return "speedometer"
        }
    }
}

struct AnalyticsTabView: View {
    @Binding var selectedTab: AnalyticsTab
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 20) {
                ForEach(AnalyticsTab.allCases, id: \.self) { tab in
                    AnalyticsTabButton(
                        tab: tab,
                        isSelected: selectedTab == tab
                    ) {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            selectedTab = tab
                        }
                    }
                }
            }
            .padding(.horizontal)
        }
        .background(Color(.systemGray6))
    }
}

struct AnalyticsTabButton: View {
    let tab: AnalyticsTab
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: tab.icon)
                    .font(.title2)
                    .foregroundColor(isSelected ? RomanianColors.traditionalRed : .secondary)
                
                Text(tab.rawValue)
                    .font(.caption)
                    .foregroundColor(isSelected ? RomanianColors.traditionalRed : .secondary)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? RomanianColors.traditionalRed.opacity(0.1) : Color.clear)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Cultural Overview View

struct CulturalOverviewView: View {
    @ObservedObject var analyticsManager: PerformanceAnalyticsManager
    @ObservedObject var culturalScoring: CulturalAuthenticityScoring
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                // Performance Summary Cards
                HStack(spacing: 16) {
                    CulturalMetricCard(
                        title: "Modele Tradiționale",
                        value: "\(Int(culturalScoring.traditionalPatternScore * 100))%",
                        icon: "pattern",
                        color: RomanianColors.traditionalBlue
                    )
                    
                    CulturalMetricCard(
                        title: "Stil Regional",
                        value: "\(Int(culturalScoring.regionalStyleScore * 100))%",
                        icon: "map",
                        color: RomanianColors.folkloreGreen
                    )
                }
                
                // Authenticity Trend Chart
                CulturalTrendChartView(
                    data: culturalScoring.historicalAuthenticityTrend,
                    title: "Evoluția Autenticității Culturale"
                )
                
                // Recent Cultural Moments
                if !analyticsManager.realTimeMetrics.currentCulturalScore.isZero {
                    RecentCulturalMomentsView()
                }
                
                // Learning Progress
                CulturalLearningProgressView(
                    metrics: analyticsManager.learningProgressMetrics
                )
            }
            .padding()
        }
    }
}

// MARK: - Cultural Metric Card

struct CulturalMetricCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                Spacer()
                
                Text(value)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(color)
            }
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.leading)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(color.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

// MARK: - Cultural Trend Chart

struct CulturalTrendChartView: View {
    let data: [AuthenticityDataPoint]
    let title: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
            
            if #available(iOS 16.0, *) {
                Chart(data, id: \.timestamp) { dataPoint in
                    LineMark(
                        x: .value("Timpul", dataPoint.timestamp),
                        y: .value("Scor", dataPoint.score)
                    )
                    .foregroundStyle(RomanianColors.traditionalRed.gradient)
                    .lineStyle(StrokeStyle(lineWidth: 3))
                    
                    AreaMark(
                        x: .value("Timpul", dataPoint.timestamp),
                        y: .value("Scor", dataPoint.score)
                    )
                    .foregroundStyle(RomanianColors.traditionalRed.opacity(0.1))
                }
                .frame(height: 150)
                .chartYScale(domain: 0...1)
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: 5))
                }
                .chartYAxis {
                    AxisMarks(position: .leading)
                }
            } else {
                // Fallback for iOS 15
                SimpleLineChartView(data: data)
                    .frame(height: 150)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
        )
    }
}

// MARK: - Traditional Patterns View

struct TraditionalPatternsView: View {
    let patterns: Float
    let insights: RealTimeMetrics
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                // Pattern Recognition Summary
                PatternRecognitionSummaryView(patternsScore: patterns)
                
                // Traditional Strategies Breakdown
                TraditionalStrategiesBreakdownView()
                
                // Cultural Pattern Timeline
                CulturalPatternTimelineView()
            }
            .padding()
        }
    }
}

struct PatternRecognitionSummaryView: View {
    let patternsScore: Float
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recunoașterea Modelelor Tradiționale")
                .font(.headline)
            
            HStack {
                VStack(alignment: .leading) {
                    Text("Scor General")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("\(Int(patternsScore * 100))%")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(RomanianColors.traditionalRed)
                }
                
                Spacer()
                
                CircularProgressView(
                    progress: patternsScore,
                    color: RomanianColors.traditionalRed
                )
                .frame(width: 80, height: 80)
            }
            
            // Individual Pattern Scores
            VStack(spacing: 8) {
                PatternScoreRow(title: "Tăierea cu Septe", score: 0.85)
                PatternScoreRow(title: "Timingul Optului", score: 0.72)
                PatternScoreRow(title: "Vânătoarea Punctelor", score: 0.68)
                PatternScoreRow(title: "Jocul Defensiv", score: 0.91)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
        )
    }
}

struct PatternScoreRow: View {
    let title: String
    let score: Float
    
    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
            
            Spacer()
            
            ProgressView(value: score)
                .frame(width: 80)
                .tint(scoreColor)
            
            Text("\(Int(score * 100))%")
                .font(.caption)
                .foregroundColor(scoreColor)
                .frame(width: 35, alignment: .trailing)
        }
    }
    
    private var scoreColor: Color {
        switch score {
        case 0.8...: return .green
        case 0.6..<0.8: return .orange
        default: return .red
        }
    }
}

// MARK: - Regional Styles View

struct RegionalStylesView: View {
    let regionalScore: Float
    let exploredRegions: [RomanianRegion]
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                // Regional Map View
                RomanianRegionalMapView(exploredRegions: exploredRegions)
                
                // Regional Style Breakdown
                RegionalStyleBreakdownView(regionalScore: regionalScore)
                
                // Cultural Heritage Information
                CulturalHeritageInfoView()
            }
            .padding()
        }
    }
}

// MARK: - Cultural Learning View

struct CulturalLearningView: View {
    let learningMetrics: LearningProgressMetrics
    let recommendations: [String]
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                // Learning Progress Summary
                LearningProgressSummaryView(metrics: learningMetrics)
                
                // Recommendations
                CulturalRecommendationsView(recommendations: recommendations)
                
                // Cultural Knowledge Areas
                CulturalKnowledgeAreasView()
            }
            .padding()
        }
    }
}

// MARK: - Performance Metrics View

struct PerformanceMetricsView: View {
    let metrics: RealTimeMetrics
    let performanceScore: Float
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                // Overall Performance Card
                PerformanceOverviewCard(
                    score: performanceScore,
                    metrics: metrics
                )
                
                // Real-time Metrics
                RealTimeMetricsView(metrics: metrics)
                
                // Performance Trends
                PerformanceTrendsView()
            }
            .padding()
        }
    }
}

// MARK: - Supporting Views

struct CircularProgressView: View {
    let progress: Float
    let color: Color
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.2), lineWidth: 8)
            
            Circle()
                .trim(from: 0, to: CGFloat(progress))
                .stroke(color, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 1), value: progress)
            
            Text("\(Int(progress * 100))%")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(color)
        }
    }
}

struct SimpleLineChartView: View {
    let data: [AuthenticityDataPoint]
    
    var body: some View {
        // Simplified line chart for iOS 15 compatibility
        GeometryReader { geometry in
            Path { path in
                guard let firstPoint = data.first else { return }
                
                let width = geometry.size.width
                let height = geometry.size.height
                let stepX = width / CGFloat(data.count - 1)
                
                path.move(to: CGPoint(x: 0, y: height * (1 - CGFloat(firstPoint.score))))
                
                for (index, point) in data.enumerated() {
                    let x = CGFloat(index) * stepX
                    let y = height * (1 - CGFloat(point.score))
                    path.addLine(to: CGPoint(x: x, y: y))
                }
            }
            .stroke(RomanianColors.traditionalRed, lineWidth: 2)
        }
    }
}

// MARK: - Placeholder Views (would be fully implemented)

struct RecentCulturalMomentsView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Momente Culturale Recente")
                .font(.headline)
            
            VStack(spacing: 8) {
                CulturalMomentRow(
                    title: "Tăiere Perfectă cu Septe",
                    description: "Ai demonstrat măiestria tradițională românească",
                    timestamp: Date()
                )
                
                CulturalMomentRow(
                    title: "Stilul Moldovenesc",
                    description: "Joc defensiv și răbdare caracteristică",
                    timestamp: Date().addingTimeInterval(-300)
                )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
        )
    }
}

struct CulturalMomentRow: View {
    let title: String
    let description: String
    let timestamp: Date
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(timestamp, style: .relative)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

// Additional placeholder views would be implemented similarly...
struct CulturalLearningProgressView: View {
    let metrics: LearningProgressMetrics
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Progresul Învățării Culturale")
                .font(.headline)
            
            ProgressView("Progres General", value: metrics.overallProgress)
                .tint(RomanianColors.traditionalBlue)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
        )
    }
}

// Continue with other placeholder views...
struct TraditionalStrategiesBreakdownView: View {
    var body: some View {
        Text("Traditional Strategies Breakdown")
            .padding()
    }
}

struct CulturalPatternTimelineView: View {
    var body: some View {
        Text("Cultural Pattern Timeline")
            .padding()
    }
}

struct RomanianRegionalMapView: View {
    let exploredRegions: [RomanianRegion]
    
    var body: some View {
        Text("Romanian Regional Map")
            .padding()
    }
}

struct RegionalStyleBreakdownView: View {
    let regionalScore: Float
    
    var body: some View {
        Text("Regional Style Breakdown")
            .padding()
    }
}

struct CulturalHeritageInfoView: View {
    var body: some View {
        Text("Cultural Heritage Information")
            .padding()
    }
}

struct LearningProgressSummaryView: View {
    let metrics: LearningProgressMetrics
    
    var body: some View {
        Text("Learning Progress Summary")
            .padding()
    }
}

struct CulturalRecommendationsView: View {
    let recommendations: [String]
    
    var body: some View {
        Text("Cultural Recommendations")
            .padding()
    }
}

struct CulturalKnowledgeAreasView: View {
    var body: some View {
        Text("Cultural Knowledge Areas")
            .padding()
    }
}

struct PerformanceOverviewCard: View {
    let score: Float
    let metrics: RealTimeMetrics
    
    var body: some View {
        Text("Performance Overview")
            .padding()
    }
}

struct RealTimeMetricsView: View {
    let metrics: RealTimeMetrics
    
    var body: some View {
        Text("Real-time Metrics")
            .padding()
    }
}

struct PerformanceTrendsView: View {
    var body: some View {
        Text("Performance Trends")
            .padding()
    }
}

struct DetailedCulturalReportView: View {
    @ObservedObject var analyticsManager: PerformanceAnalyticsManager
    
    var body: some View {
        NavigationView {
            Text("Detailed Cultural Report")
                .navigationTitle("Raport Cultural Detaliat")
                .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - Romanian Color Extensions

extension RomanianColors {
    static let traditionalRed = Color(red: 0.9, green: 0.2, blue: 0.2)
    static let traditionalBlue = Color(red: 0.0, green: 0.3, blue: 0.6)
    static let folkloreGreen = Color(red: 0.2, green: 0.7, blue: 0.3)
    static let heritageGold = Color(red: 1.0, green: 0.8, blue: 0.0)
}

// MARK: - Supporting Data Structures

struct AuthenticityDataPoint {
    let timestamp: Date
    let score: Float
    let level: AuthenticityLevel
}

// This would be expanded with full implementations of all views and supporting structures