import SwiftUI

struct PayslipsView: View {
    // MARK: - State and ObservedObjects
    @ObservedObject private var viewModel: PayslipsViewModel

    // MARK: - Initializer
    init(viewModel: PayslipsViewModel) {
        self.viewModel = viewModel

        // Register for performance monitoring - moved to onAppear to fix warning
        // Don't call ViewPerformanceTracker here as it causes a publishing warning
    }

    // MARK: - Main View Body
    var body: some View {
        // Use NavigationStack for better performance than NavigationView
        NavigationStack {
            mainContentView
                .navigationTitle("Payslips")
                .navigationBarTitleDisplayMode(.large)

        }
        .alert(item: $viewModel.error) { error in
            Alert(title: Text("Error"), message: Text(error.localizedDescription), dismissButton: .default(Text("OK")))
        }
        .task {
            // Only load if we haven't already
            if viewModel.filteredPayslips.isEmpty {
                await viewModel.loadPayslips()
            }
        }
        .onAppear {
            // Simplified onAppear - let the global system handle coordination
            print("📱 PayslipsList appeared")

            #if DEBUG
            ViewPerformanceTracker.shared.trackRenderStart(for: "PayslipsView")
            #endif

            Task {
                // Simple refresh without complex delays and notifications
                await viewModel.loadPayslips()
            }
        }
        .onDisappear {
            #if DEBUG
            ViewPerformanceTracker.shared.trackRenderEnd(for: "PayslipsView")
            #endif
        }
        .trackPerformance(name: "PayslipsView")
    }

    // MARK: - Computed Views for Better Organization

    @ViewBuilder
    private var mainContentView: some View {
        if viewModel.groupedPayslips.isEmpty && !viewModel.isLoading {
            EmptyStateView()
        } else {
            PayslipListView(viewModel: viewModel)
        }
    }

}
