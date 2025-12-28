import Foundation
import SwiftUI

/// ViewModel for simplified payslip detail view
/// Handles user edits to miscellaneous breakdowns and data persistence
@MainActor
class SimplifiedPayslipViewModel: ObservableObject {
    @Published var payslip: SimplifiedPayslip

    private let dataService: SimplifiedPayslipDataService

    // MARK: - Initialization

    init(payslip: SimplifiedPayslip, dataService: SimplifiedPayslipDataService) {
        self.payslip = payslip
        self.dataService = dataService
    }

    // MARK: - Update Methods

    /// Updates the breakdown of Other Earnings and recalculates total
    func updateOtherEarnings(_ breakdown: [String: Double]) async {
        payslip.otherEarningsBreakdown = breakdown
        payslip.otherEarnings = breakdown.values.reduce(0, +)
        payslip.isEdited = true

        // Recalculate gross pay
        recalculateGrossPay()

        // Recalculate net remittance
        recalculateNetRemittance()

        await savePayslip()
    }

    /// Updates the breakdown of Other Deductions and recalculates total
    func updateOtherDeductions(_ breakdown: [String: Double]) async {
        payslip.otherDeductionsBreakdown = breakdown
        payslip.otherDeductions = breakdown.values.reduce(0, +)
        payslip.isEdited = true

        // Recalculate total deductions
        recalculateTotalDeductions()

        // Recalculate net remittance
        recalculateNetRemittance()

        await savePayslip()
    }

    // MARK: - Calculation Methods

    /// Recalculates gross pay based on core earnings + other earnings
    private func recalculateGrossPay() {
        let coreEarnings = payslip.basicPay + payslip.dearnessAllowance + payslip.militaryServicePay
        payslip.grossPay = coreEarnings + payslip.otherEarnings
    }

    /// Recalculates total deductions based on core deductions + other deductions
    private func recalculateTotalDeductions() {
        let coreDeductions = payslip.dsop + payslip.agif + payslip.incomeTax
        payslip.totalDeductions = coreDeductions + payslip.otherDeductions
    }

    /// Recalculates net remittance
    private func recalculateNetRemittance() {
        payslip.netRemittance = payslip.grossPay - payslip.totalDeductions
    }

    /// Recalculates confidence score after manual edits
    private func recalculateConfidence() async {
        let calculator = ConfidenceCalculator()

        let input = ConfidenceInput(
            basicPay: payslip.basicPay,
            dearnessAllowance: payslip.dearnessAllowance,
            militaryServicePay: payslip.militaryServicePay,
            grossPay: payslip.grossPay,
            dsop: payslip.dsop,
            agif: payslip.agif,
            incomeTax: payslip.incomeTax,
            totalDeductions: payslip.totalDeductions,
            netRemittance: payslip.netRemittance
        )
        let confidenceResult = await calculator.calculate(input)

        // Extract overall confidence score
        let newConfidence = confidenceResult.overall

        // If user edited, cap confidence at 90% since it's partially manual
        if payslip.isEdited {
            payslip.parsingConfidence = min(0.90, newConfidence)
        } else {
            payslip.parsingConfidence = newConfidence
        }
    }

    // MARK: - Persistence

    /// Saves the payslip to the data store
    private func savePayslip() async {
        do {
            try await dataService.save(payslip)
        } catch {
            print("Error saving payslip: \(error.localizedDescription)")
        }
    }
}

// MARK: - Simplified Payslip Data Service Protocol

/// Protocol for simplified payslip data persistence operations
/// @MainActor ensures thread safety for SwiftData operations
@MainActor
protocol SimplifiedPayslipDataService {
    func save(_ payslip: SimplifiedPayslip) async throws
    func fetchAll() async -> [SimplifiedPayslip]
    func delete(_ payslip: SimplifiedPayslip) async throws
}

