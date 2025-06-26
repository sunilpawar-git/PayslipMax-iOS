import SwiftUI

// MARK: - Premium Benchmarks Section

struct PremiumBenchmarksSection: View {
    @ObservedObject var analyticsEngine: AdvancedAnalyticsCoordinator
    
    var body: some View {
        VStack(spacing: 16) {
            if analyticsEngine.benchmarkData.isEmpty {
                PremiumEmptyStateView(
                    icon: "chart.bar.xaxis",
                    title: "No Benchmark Data",
                    description: "Upload more payslips to compare with industry standards"
                )
            } else {
                ForEach(analyticsEngine.benchmarkData, id: \.category) { benchmark in
                    BenchmarkCard(benchmark: benchmark)
                }
            }
        }
    }
} 