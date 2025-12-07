import SwiftUI

struct PayslipsView: View {
    // MARK: - State and ObservedObjects
    @ObservedObject private var viewModel: PayslipsViewModel
    @State private var isShowingLegend = false
    @State private var legendAnchor: CGRect = .zero

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
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        XRayLegendChip(isShowingLegend: $isShowingLegend, anchor: $legendAnchor)
                            .background(
                                GeometryReader { geo in
                                    Color.clear
                                        .preference(key: LegendAnchorKey.self, value: geo.frame(in: .global))
                                }
                            )
                    }
                }
                .onPreferenceChange(LegendAnchorKey.self) { rect in
                    legendAnchor = rect
                }
        }
        .alert(item: $viewModel.error) { error in
            Alert(title: Text("Error"), message: Text(error.userMessage), dismissButton: .default(Text("OK")))
        }
        .sheet(isPresented: $viewModel.showShareSheet) {
            if !viewModel.shareText.isEmpty {
                ShareSheet(items: [viewModel.shareText])
            }
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
        .overlay {
            if isShowingLegend {
                LegendOverlay(isShowingLegend: $isShowingLegend, anchor: legendAnchor)
                    .transition(.opacity.combined(with: .scale(scale: 0.98)))
                    .animation(.easeInOut(duration: 0.2), value: isShowingLegend)
            }
        }
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

// MARK: - Legend Overlay

private struct LegendOverlay: View {
    @Binding var isShowingLegend: Bool
    let anchor: CGRect

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Tap catcher for dismissal
                Color.black.opacity(0.001)
                    .ignoresSafeArea()
                    .onTapGesture { isShowingLegend = false }

                let cardWidth: CGFloat = 280
                let xPos = clampedX(anchor: anchor, width: cardWidth, screenWidth: geo.size.width)
                let yPos = anchor.maxY > 0 ? anchor.maxY + 8 : 68

                XRayLegendRow()
                    .padding(14)
                    .frame(maxWidth: cardWidth, alignment: .leading)
                    .background(FintechColors.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .shadow(color: FintechColors.shadow.opacity(0.25), radius: 12, x: 0, y: 6)
                    .position(x: xPos, y: yPos)
            }
        }
        .accessibilityElement(children: .contain)
    }

    private func clampedX(anchor: CGRect, width: CGFloat, screenWidth: CGFloat) -> CGFloat {
        let minX = width / 2 + 12
        let maxX = screenWidth - width / 2 - 12
        let anchorMid = anchor.midX == 0 ? (screenWidth - width / 2 - 16) : anchor.midX
        return min(max(anchorMid, minX), maxX)
    }
}

private struct LegendAnchorKey: PreferenceKey {
    static var defaultValue: CGRect = .zero
    static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
        value = nextValue()
    }
}
