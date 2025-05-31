import SwiftUI
import PDFKit
import Charts
import Vision
import VisionKit
import UIKit

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
    @State private var shouldShowCharts = false
    @State private var cachedChartData: [PayslipChartData] = []
    
    init(viewModel: HomeViewModel? = nil) {
        // Use provided viewModel or create one from DIContainer
        let model = viewModel ?? DIContainer.shared.makeHomeViewModel()
        self._viewModel = StateObject(wrappedValue: model)
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
            .homeTestingSetup()
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
            .onReceive(viewModel.$payslipData) { newValue in
                updateChartData(newValue)
            }
            .onChange(of: tabSelection.wrappedValue) { oldValue, newValue in
                handleTabChange(from: oldValue, to: newValue)
            }
            .onDisappear {
                viewModel.cancelLoading()
            }
            .accessibilityIdentifier("home_view")
            .trackRenderTime(name: "HomeView")
            .trackPerformance(viewName: "HomeView")
    }
    
    private var mainContent: some View {
        ZStack {
            backgroundLayers
            scrollContent
        }
    }
    
    private var backgroundLayers: some View {
        ZStack {
            Color(.systemBackground)
                .edgesIgnoringSafeArea(.all)
            
            Color(red: 0, green: 0, blue: 0.5)
                .edgesIgnoringSafeArea(.all) 
                .frame(height: UIScreen.main.bounds.height * 0.4)
                .frame(maxHeight: .infinity, alignment: .top)
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
        .trackPerformance(viewName: "HomeScrollView")
    }
    
    private var headerSection: some View {
        HomeHeaderView(
            onUploadTapped: { showingDocumentPicker = true },
            onScanTapped: { showingScanner = true },
            onManualTapped: { viewModel.showManualEntry() }
        )
        .id("home-header")
        .trackPerformance(viewName: "HomeHeaderView")
    }
    
    private var mainContentSection: some View {
        VStack(spacing: 20) {
            countdownSection
            recentPayslipsSection
            chartsSection
            tipsSection
        }
        .padding()
        .background(Color(.systemBackground))
        .id("home-content-section")
        .trackPerformance(viewName: "HomeContentSection")
    }
    
    private var countdownSection: some View {
        PayslipCountdownView()
            .padding(.horizontal, 8)
            .padding(.top, 10)
            .accessibilityIdentifier("countdown_view")
            .id("countdown-view")
            .trackPerformance(viewName: "PayslipCountdownView")
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
                    .trackPerformance(viewName: "RecentActivityView")
            }
        }
    }
    
    @ViewBuilder
    private var chartsSection: some View {
        if shouldShowCharts && !cachedChartData.isEmpty {
            ChartsView(data: cachedChartData, payslips: cachedRecentPayslips)
                .accessibilityIdentifier("charts_view")
                .id("charts-view-\(cachedChartData.count)")
                .trackPerformance(viewName: "ChartsView")
        } else if !shouldShowCharts && cachedChartData.isEmpty {
            EmptyStateView()
                .accessibilityIdentifier("empty_state_view")
                .id("empty-state")
                .trackPerformance(viewName: "EmptyStateView")
        }
    }
    
    private var tipsSection: some View {
        InvestmentTipsView()
            .accessibilityIdentifier("tips_view")
            .id("tips-view")
            .trackPerformance(viewName: "InvestmentTipsView")
    }
    
    private func initializeCachedState() {
        if !viewModel.recentPayslips.isEmpty {
            cachedRecentPayslips = viewModel.recentPayslips
            shouldShowRecentPayslips = true
        }
        
        if !viewModel.payslipData.isEmpty {
            cachedChartData = viewModel.payslipData
            shouldShowCharts = true
        }
    }
    
    private func updateRecentPayslips(_ newValue: [AnyPayslip]) {
        if !newValue.isEmpty {
            cachedRecentPayslips = newValue
            withAnimation(.easeInOut(duration: 0.2)) {
                shouldShowRecentPayslips = true
            }
        } else if cachedRecentPayslips.isEmpty {
            shouldShowRecentPayslips = false
        }
    }
    
    private func updateChartData(_ newValue: [PayslipChartData]) {
        if !newValue.isEmpty {
            cachedChartData = newValue
            withAnimation(.easeInOut(duration: 0.2)) {
                shouldShowCharts = true
            }
        } else if cachedChartData.isEmpty {
            shouldShowCharts = false
        }
    }
    
    private func handleTabChange(from oldValue: Int, to newValue: Int) {
        if oldValue == 0 && newValue != 0 {
            viewModel.cancelLoading()
        }
    }
    
    // Handle document picked from document picker
    private func handleDocumentPicked(url: URL) {
        // Process the document
        print("HomeView: Processing document from \(url.absoluteString)")
        Task {
            await viewModel.processPayslipPDF(from: url)
        }
    }
}

// MARK: - Preview

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}

// MARK: - Supporting Types
// All supporting types have been moved to their own files
// - HomeSheetModifiers
// - HomeNavigation
// - HomeActionSheet
// - HomeTestingSetup

// MARK: - Modifier to handle optional accessibility identifiers

struct AccessibilityModifier: ViewModifier {
    let id: String?
    
    func body(content: Content) -> some View {
        if let id = id {
            content.accessibilityIdentifier(id)
        } else {
            content
        }
    }
}

// MARK: - Charts View
// ChartsView is now moved to Components/ChartsView.swift

// MARK: - Scanner View
// ScannerView is now moved to Utilities/ScannerView.swift
// struct ScannerView: UIViewControllerRepresentable {
//     let onScanCompleted: (UIImage) -> Void
//     
//     func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
//         let scanner = VNDocumentCameraViewController()
//         scanner.delegate = context.coordinator
//         return scanner
//     }
//     
//     func updateUIViewController(_ uiViewController: VNDocumentCameraViewController, context: Context) {}
//     
//     func makeCoordinator() -> Coordinator {
//         Coordinator(self)
//     }
//     
//     class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {
//         let parent: ScannerView
//         
//         init(_ parent: ScannerView) {
//             self.parent = parent
//         }
//         
//         func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentScan) {
//             guard scan.pageCount > 0 else { return }
//             let image = scan.imageOfPage(at: 0)
//             parent.onScanCompleted(image)
//             controller.dismiss(animated: true)
//         }
//         
//         func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
//             controller.dismiss(animated: true)
//         }
//         
//         func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFailWithError error: Error) {
//             ErrorLogger.log(error)
//             controller.dismiss(animated: true)
//         }
//     }
// }

// MARK: - Manual Entry View
// ManualEntryView is now moved to Components/ManualEntryView.swift

// MARK: - Payslip Countdown View

// PayslipCountdownView is now moved to its own file in Components/PayslipCountdownView.swift
// struct PayslipCountdownView: View {
//     @State private var daysRemaining: Int = 0
//     @Environment(\.colorScheme) var colorScheme
//     
//     var body: some View {
//         HStack(spacing: 16) {
//             HStack(spacing: 12) {
//                 Image(systemName: "calendar")
//                     .font(.system(size: 22, weight: .semibold))
//                     .foregroundColor(.white)
//                     .frame(width: 26)
//                 
//                 Text("Days till Next Payslip")
//                     .font(.system(size: 17, weight: .semibold))
//                     .foregroundColor(.white)
//                     .lineLimit(1)
//                     .fixedSize(horizontal: true, vertical: false)
//             }
//             
//             Spacer(minLength: 32)
//             
//             Text("\(daysRemaining) Days")
//                 .font(.system(size: 17, weight: .bold))
//                 .foregroundColor(.white)
//                 .lineLimit(1)
//                 .fixedSize(horizontal: true, vertical: false)
//         }
//         .padding(.vertical, 16)
//         .padding(.horizontal, 24)
//         .frame(maxWidth: .infinity, minHeight: 56)
//         .background(
//             RoundedRectangle(cornerRadius: 14)
//                 .fill(
//                     LinearGradient(
//                         gradient: Gradient(colors: [
//                             Color(red: 0.2, green: 0.5, blue: 1.0),
//                             Color(red: 0.3, green: 0.6, blue: 1.0)
//                         ]),
//                         startPoint: .leading,
//                         endPoint: .trailing
//                     )
//                 )
//                 .shadow(color: Color.black.opacity(0.15), radius: 5, x: 0, y: 2)
//         )
//         .onAppear {
//             updateDaysRemaining()
//         }
//     }
//     
//     private func updateDaysRemaining() {
//         let calendar = Calendar.current
//         let now = Date()
//         
//         // Get the current month's last day
//         guard let lastDayOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: calendar.startOfDay(for: now))),
//               let lastDay = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: lastDayOfMonth) else {
//             return
//         }
//         
//         // Calculate days remaining
//         if let days = calendar.dateComponents([.day], from: now, to: lastDay).day {
//             daysRemaining = max(days + 1, 0) // Add 1 to include the current day
//         }
//         
//         // Set up a timer to update daily
//         Timer.scheduledTimer(withTimeInterval: 86400, repeats: true) { _ in // 86400 seconds = 24 hours
//             updateDaysRemaining()
//         }
//     }
// } 

// Track tab changes to properly handle loading state
struct TabSelectionKey: EnvironmentKey {
    static let defaultValue: Binding<Int> = .constant(0)
}

extension EnvironmentValues {
    var tabSelection: Binding<Int> {
        get { self[TabSelectionKey.self] }
        set { self[TabSelectionKey.self] = newValue }
    }
} 
