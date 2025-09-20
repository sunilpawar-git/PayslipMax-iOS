//
//  QuizDataLoaders.swift
//  PayslipMax
//
// ⚠️ ARCHITECTURE REMINDER: Keep this file under 300 lines
// Current: [LINE_COUNT]/300 lines
// Next action at 250 lines: Extract components

import Foundation

/// Implementation of data loading operations for quiz generation
final class QuizDataLoader: QuizDataLoaderProtocol {
    // MARK: - Dependencies

    private let financialSummaryViewModel: FinancialSummaryViewModel
    private let repository: SendablePayslipRepository

    // MARK: - Initialization

    /// Initializes the data loader with required dependencies
    /// - Parameters:
    ///   - financialSummaryViewModel: ViewModel for managing financial summary data
    ///   - repository: Repository for Sendable payslip operations
    init(
        financialSummaryViewModel: FinancialSummaryViewModel,
        repository: SendablePayslipRepository
    ) {
        self.financialSummaryViewModel = financialSummaryViewModel
        self.repository = repository
    }

    // MARK: - QuizDataLoaderProtocol Implementation

    /// Loads payslip data into the financial summary view model
    func loadPayslipData() async throws {
        // Fetch payslips from Sendable repository
        let payslips = try await repository.fetchAllPayslips()
        print("QuizDataLoader: Loaded \(payslips.count) payslips from repository")

        // Update the financial summary view model with the loaded payslips
        await financialSummaryViewModel.updatePayslips(payslips)
    }
}

/// Factory for creating quiz data loader instances
final class QuizDataLoaderFactory {
    /// Creates a configured quiz data loader instance
    /// - Parameters:
    ///   - financialSummaryViewModel: ViewModel for financial summary data
    ///   - repository: Repository for Sendable payslip operations
    /// - Returns: Configured QuizDataLoader instance
    static func createDataLoader(
        financialSummaryViewModel: FinancialSummaryViewModel,
        repository: SendablePayslipRepository
    ) -> QuizDataLoaderProtocol {
        return QuizDataLoader(
            financialSummaryViewModel: financialSummaryViewModel,
            repository: repository
        )
    }
}
