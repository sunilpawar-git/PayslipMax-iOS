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
        VStack(spacing: 10) {
            List {
                ForEach(viewModel.sortedSectionKeys, id: \.self) { key in
                    if let payslipsInSection = viewModel.groupedPayslips[key], !payslipsInSection.isEmpty {
                        Section {
                            ForEach(Array(payslipsInSection.enumerated()), id: \.element.id) { index, payslip in
                                PayslipListRowContent(
                                    payslip: payslip,
                                    viewModel: viewModel
                                )
                                .background(
                                    NavigationLink {
                                        PayslipDetailView(viewModel: PayslipDetailViewModel(
                                            payslip: payslip,
                                            allPayslips: viewModel.payslips
                                        ))
                                    } label: {
                                        EmptyView()
                                    }
                                    .opacity(0)
                                )
                                .accessibilityIdentifier("payslip_row_\(payslip.id)")
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    Button(role: .destructive) {
                                        payslipToDelete = payslip
                                        isShowingConfirmDelete = true
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                    .accessibilityIdentifier("delete_button_\(payslip.id)")
                                }
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                                .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                            }
                        } header: {
                            Text(key)
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundColor(FintechColors.textPrimary)
                                .textCase(nil)
                        }
                        .listSectionSeparator(.hidden)
                    }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
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

// MARK: - PayslipListRowContent

/// Content view for payslip row in list (without NavigationLink wrapper)
struct PayslipListRowContent: View {
    let payslip: AnyPayslip
    let viewModel: PayslipsViewModel
    @Environment(\.colorScheme) private var colorScheme

    // Cache expensive calculations
    @State private var formattedNetAmount: String = ""

    // X-Ray support
    private var xRaySettings: any XRaySettingsServiceProtocol {
        viewModel.xRaySettings
    }

    var body: some View {
        HStack(spacing: 16) {
            // Left side: Icon and basic info
            HStack(spacing: 12) {
                // Document icon with subtle background
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(FintechColors.primaryBlue.opacity(0.1))
                        .frame(width: 40, height: 40)

                    Image(systemName: "doc.text.fill")
                        .foregroundColor(FintechColors.primaryBlue)
                        .font(.system(size: 18))
                }

                VStack(alignment: .leading, spacing: 4) {
                    // Employee name or fallback
                    Text(payslip.name.isEmpty ? "Payslip" : formatName(payslip.name))
                        .font(.headline)
                        .fontWeight(.medium)
                        .foregroundColor(FintechColors.textPrimary)
                        .lineLimit(1)

                    // Subtle subtitle
                    Text("Net Remittance")
                        .font(.subheadline)
                        .foregroundColor(FintechColors.textSecondary)
                }
            }

            Spacer()

            // Right side: Financial amount with trend styling
            VStack(alignment: .trailing, spacing: 2) {
                Text(formattedNetAmount)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(FintechColors.getAccessibleColor(for: getNetAmount(for: payslip)))

                PayslipNetIndicatorView(netAmount: getNetAmount(for: payslip))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(cardBackgroundColor)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(xRayStrokeColor ?? Color.clear, lineWidth: xRayStrokeColor == nil ? 0 : 1)
        )
        .overlay(alignment: .leading) {
            if let accent = xRayAccentColor {
                RoundedRectangle(cornerRadius: 16)
                    .fill(accent)
                    .frame(width: 4)
                    .padding(.vertical, 12)
            }
        }
        .shadow(
            color: FintechColors.shadow.opacity(0.08),
            radius: 8,
            x: 0,
            y: 2
        )
        .onAppear {
            self.formattedNetAmount = formatCurrency(getNetAmount(for: payslip))
        }
    }

    // MARK: - Computed Properties

    /// Dynamic card background color based on X-Ray comparison
    private var cardBackgroundColor: Color {
        xRayVisualStyle?.fill ?? FintechColors.cardBackground
    }

    private var xRayStrokeColor: Color? {
        xRayVisualStyle?.accent.opacity(colorScheme == .dark ? 0.75 : 0.55)
    }

    private var xRayAccentColor: Color? {
        xRayVisualStyle?.accent.opacity(colorScheme == .dark ? 0.9 : 0.75)
    }

    private var xRayVisualStyle: (fill: Color, accent: Color)? {
        guard xRaySettings.isXRayEnabled,
              let comparison = viewModel.comparisonResults[payslip.id],
              comparison.previousPayslip != nil else {
            return nil
        }

        if comparison.hasIncreasedNetRemittance {
            return (FintechColors.xRayPositiveTint, FintechColors.xRayPositiveAccent)
        } else if comparison.hasDecreasedNetRemittance {
            return (FintechColors.xRayNegativeTint, FintechColors.xRayNegativeAccent)
        }

        return nil
    }

    // MARK: - Helper Methods

    // Helper to format name (removes single-character components at the end)
    private func formatName(_ name: String) -> String {
        let components = name.components(separatedBy: " ")
        if components.count > 1, components.last?.count == 1 {
            return components.dropLast().joined(separator: " ")
        }
        return name
    }

    // Helper methods to work with AnyPayslip
    private func getNetAmount(for payslip: AnyPayslip) -> Double {
        return payslip.credits - payslip.debits
    }

    // Format currency to avoid dependency on ViewModel
    private func formatCurrency(_ value: Double) -> String {
        let absValue = abs(value)

        if absValue >= 1_00_000 { // 1 Lakh or more
            let lakhs = absValue / 1_00_000
            if lakhs >= 10 {
                return "₹\(String(format: "%.0f", lakhs))L"
            } else {
                // Truncate to 2 decimal places instead of rounding
                let truncatedLakhs = floor(lakhs * 100) / 100
                return "₹\(String(format: "%.2f", truncatedLakhs))L"
            }
        } else if absValue >= 1_000 { // 1 Thousand or more
            let thousands = absValue / 1_000
            if thousands >= 10 {
                return "₹\(String(format: "%.0f", thousands))K"
            } else {
                // Truncate to 2 decimal places instead of rounding
                let truncatedThousands = floor(thousands * 100) / 100
                return "₹\(String(format: "%.2f", truncatedThousands))K"
            }
        } else {
            return "₹\(String(format: "%.0f", absValue))"
        }
    }
}

