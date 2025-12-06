import SwiftUI
import PDFKit
import Vision
import VisionKit
import UIKit
import SwiftData

// Additional imports for extracted components
@MainActor
struct HomeView: View {
    @StateObject private var viewModel: HomeViewModel
    @State private var showingDocumentPicker = false
    @State private var showingScanner = false
    @State private var showingActionSheet = false
    @Environment(\.tabSelection) private var tabSelection

    // Add a state variable to prevent visual glitch during tab transitions
    @State private var shouldShowRecentPayslips = false
    @State private var cachedRecentPayslips: [AnyPayslip] = []

    // Query for recent payslips
    @Query(
        filter: #Predicate<PayslipItem> { item in
            item.isDeleted == false
        },
        sort: [SortDescriptor(\.timestamp, order: .reverse)]
    ) private var payslips: [PayslipItem]

    init(viewModel: HomeViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        mainContent
            .navigationBarHidden(true)
            .homeSheetModifiers(
                viewModel: viewModel,
                showingDocumentPicker: $showingDocumentPicker,
                showingScanner: $showingScanner,
                onDocumentPicked: handleDocumentPicked
            )
            .homeNavigation(viewModel: viewModel)
            .homeActionSheet(
                showingActionSheet: $showingActionSheet,
                showingDocumentPicker: $showingDocumentPicker,
                showingScanner: $showingScanner,
                onManualEntryTapped: viewModel.showManualEntry
            )
            .alert(item: $viewModel.error) { error in
                Alert(
                    title: Text("Error"),
                    message: Text(error.localizedDescription),
                    dismissButton: .default(Text("OK"))
                )
            }
            .onAppear {
                initializeCachedState()
                Task {
                    viewModel.loadRecentPayslips()
                }
                PerformanceMetrics.shared.recordViewRedraw(for: "HomeView")
            }
            .onReceive(viewModel.$recentPayslips) { newValue in
                updateRecentPayslips(newValue)
            }

            .onChange(of: tabSelection.wrappedValue) { oldValue, newValue in
                handleTabChange(from: oldValue, to: newValue)
            }
            .onDisappear {
                viewModel.cancelLoading()
            }
            .accessibilityIdentifier("home_view")
            .trackRenderTime(name: "HomeView")
            .trackPerformance(name: "HomeView")
    }

    private var mainContent: some View {
        ZStack {
            backgroundLayers
            scrollContent
        }
    }

    private var backgroundLayers: some View {
        GeometryReader { geometry in
            ZStack {
                Color(.systemBackground)
                    .edgesIgnoringSafeArea(.all)

                Color(red: 0, green: 0, blue: 0.5)
                    .edgesIgnoringSafeArea(.all)
                    .frame(height: geometry.size.height * 0.4)
                    .frame(maxHeight: .infinity, alignment: .top)
            }
        }
    }

    private var scrollContent: some View {
        ScrollView {
            VStack(spacing: 0) {
                headerSection
                mainContentSection
            }
        }
        .accessibilityIdentifier("home_scroll_view")
        .background(Color.clear)
        .trackPerformance(name: "HomeScrollView")
    }

    private var headerSection: some View {
        HomeHeaderView(
            onUploadTapped: { showingDocumentPicker = true },
            onScanTapped: { showingScanner = true },
            onManualTapped: { viewModel.showManualEntry() }
        )
        .id("home-header")
        .trackPerformance(name: "HomeHeaderView")
    }

    private var mainContentSection: some View {
        VStack(spacing: 20) {
            countdownSection
            recentPayslipsSection

            // 🎮 Quiz Gamification Section - below recent payslips
            quizGamificationSection

            tipsSection
        }
        .padding()
        .background(Color(.systemBackground))
        .id("home-content-section")
        .trackPerformance(name: "HomeContentSection")
    }

    private var countdownSection: some View {
        PayslipCountdownView()
            .padding(.horizontal, 8)
            .padding(.top, 10)
            .accessibilityIdentifier("countdown_view")
            .id("countdown-view")
            .trackPerformance(name: "PayslipCountdownView")
    }

    @ViewBuilder
    private var recentPayslipsSection: some View {
        if shouldShowRecentPayslips && !cachedRecentPayslips.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text("Recent Payslips")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .padding(.horizontal)
                    .accessibilityIdentifier("recent_payslips_title")

                RecentActivityView(payslips: cachedRecentPayslips)
                    .accessibilityIdentifier("recent_activity_view")
                    .id("recent-activity-\(cachedRecentPayslips.map { $0.id.uuidString }.joined(separator: "-"))")
                    .trackPerformance(name: "RecentActivityView")
            }
        }
    }

    @ViewBuilder
    private var quizGamificationSection: some View {
        if shouldShowRecentPayslips && !cachedRecentPayslips.isEmpty {
            // Always show the quiz section if payslips are available
            HomeQuizSection(
                payslips: cachedRecentPayslips,
                quizViewModel: viewModel.quizViewModel,
                gamificationCoordinator: viewModel.gamificationCoordinator
            )
                .accessibilityIdentifier("home_quiz_section")
                .id("home-quiz-\(cachedRecentPayslips.map { $0.id.uuidString }.joined(separator: "-"))")
                .trackPerformance(name: "HomeQuizSection")
        }
    }

    private var tipsSection: some View {
        InvestmentTipsView()
            .accessibilityIdentifier("tips_view")
            .id("tips-view")
            .trackPerformance(name: "InvestmentTipsView")
    }

    // Helper functions moved to HomeHelpers.swift
}

// MARK: - Helper Functions
extension HomeView {
    private func initializeCachedState() {
        if !viewModel.recentPayslips.isEmpty {
            cachedRecentPayslips = viewModel.recentPayslips
            shouldShowRecentPayslips = true
        }
    }

    private func updateRecentPayslips(_ newValue: [AnyPayslip]) {
        if !newValue.isEmpty {
            cachedRecentPayslips = newValue
            withAnimation(.easeInOut(duration: 0.2)) {
                shouldShowRecentPayslips = true
            }
        } else {
            // Only hide the section if we previously had no payslips
            // This prevents flickering when reloading data after adding a new payslip
            if cachedRecentPayslips.isEmpty {
                withAnimation(.easeInOut(duration: 0.2)) {
                    shouldShowRecentPayslips = false
                }
            }
            // Keep the cached payslips visible during reload to prevent UI flicker
        }
    }

    private func handleTabChange(from oldValue: Int, to newValue: Int) {
        if oldValue == 0 && newValue != 0 {
            viewModel.cancelLoading()
        }
    }

    private func handleDocumentPicked(url: URL) {
        Task { await viewModel.processPayslipPDF(from: url) }
    }
}

// MARK: - Supporting Types
struct AccessibilityModifier: ViewModifier {
    let id: String?
    func body(content: Content) -> some View {
        if let id = id { content.accessibilityIdentifier(id) } else { content }
    }
}

struct TabSelectionKey: EnvironmentKey {
    static let defaultValue: Binding<Int> = .constant(0)
}

extension EnvironmentValues {
    var tabSelection: Binding<Int> {
        get { self[TabSelectionKey.self] }
        set { self[TabSelectionKey.self] = newValue }
    }
}

// MARK: - Preview

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView(viewModel: DIContainer.shared.makeHomeViewModel())
    }
}

// Supporting types moved to HomeHelpers.swift
