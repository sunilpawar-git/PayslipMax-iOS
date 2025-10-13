import SwiftUI
import SwiftData

/// Main list component for displaying payslips with sections and interactions
struct PayslipListView: View {
    @ObservedObject private var viewModel: PayslipsViewModel
    @Environment(\.modelContext) private var modelContext

    @State private var isShowingConfirmDelete = false
    @State private var payslipToDelete: AnyPayslip?

    init(viewModel: PayslipsViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(viewModel.sortedSectionKeys, id: \.self) { key in
                    if let payslipsInSection = viewModel.groupedPayslips[key], !payslipsInSection.isEmpty {
                        ForEach(Array(payslipsInSection.enumerated()), id: \.element.id) { index, payslip in
                            VStack(spacing: 0) {
                                UnifiedPayslipRowView(
                                    payslip: payslip,
                                    sectionTitle: key,
                                    isFirstInSection: index == 0,
                                    viewModel: viewModel
                                )
                                .accessibilityIdentifier("payslip_row_\(payslip.id)")
                                .contextMenu {
                                    Button(role: .destructive) {
                                        payslipToDelete = payslip
                                        isShowingConfirmDelete = true
                                    } label: {
                                        Label("Delete Payslip", systemImage: "trash")
                                    }
                                    .accessibilityIdentifier("delete_button_\(payslip.id)")
                                }

                                // Add subtle separator between payslips (except for last item)
                                if index < payslipsInSection.count - 1 {
                                    Rectangle()
                                        .fill(FintechColors.divider.opacity(0.3))
                                        .frame(height: 0.5)
                                        .padding(.leading, 60) // Indent separator to align with content
                                }
                            }
                        }

                        // Add section spacing between different months
                        if key != viewModel.sortedSectionKeys.last {
                            Rectangle()
                                .fill(Color.clear)
                                .frame(height: 24)
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
        }
        .background(FintechColors.appBackground)
        .animation(.default, value: viewModel.filteredPayslips.count)
        .refreshable {
            // Use async/await pattern for refreshing
            await viewModel.loadPayslips()
            // Also notify other components to refresh
            PayslipEvents.notifyRefreshRequired()
        }
        .confirmationDialog(
            "Are you sure you want to delete this payslip?",
            isPresented: $isShowingConfirmDelete,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                if let payslip = payslipToDelete {
                    deletePayslip(payslip)
                    payslipToDelete = nil
                }
            }
            Button("Cancel", role: .cancel) {
                payslipToDelete = nil
            }
        } message: {
            Text("This action cannot be undone.")
        }
    }

    // MARK: - Private Actions

    private func sharePayslip(_ payslip: AnyPayslip) {
        if let payslipItem = payslip as? PayslipItem {
            viewModel.sharePayslip(payslipItem)
        } else {
            // Handle case where payslip is not a PayslipItem
            print("Cannot share payslip that is not a PayslipItem")
        }
    }

    private func deletePayslip(_ payslip: AnyPayslip) {
        viewModel.deletePayslip(payslip, from: modelContext)

        // Force an immediate refresh after deletion
        Task {
            // Short delay to let deletion finish
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 second
            await viewModel.loadPayslips()
        }
    }
}
