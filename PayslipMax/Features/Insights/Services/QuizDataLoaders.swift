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
    private let dataService: DataServiceProtocol

    // MARK: - Initialization

    /// Initializes the data loader with required dependencies
    /// - Parameters:
    ///   - financialSummaryViewModel: ViewModel for managing financial summary data
    ///   - dataService: Service for data persistence operations
    init(
        financialSummaryViewModel: FinancialSummaryViewModel,
        dataService: DataServiceProtocol
    ) {
        self.financialSummaryViewModel = financialSummaryViewModel
        self.dataService = dataService
    }

    // MARK: - QuizDataLoaderProtocol Implementation

    /// Loads payslip data into the financial summary view model
    func loadPayslipData() async throws {
        // Initialize data service if needed
        if !(await dataService.isInitialized) {
            try await dataService.initialize()
        }

        // Fetch payslips from data service
        let payslips = try await dataService.fetch(PayslipItem.self)
        print("QuizDataLoader: Loaded \(payslips.count) payslips from data service")

        // Update the financial summary view model with the loaded payslips
        await financialSummaryViewModel.updatePayslips(payslips)
    }
}

/// Factory for creating quiz data loader instances
final class QuizDataLoaderFactory {
    /// Creates a configured quiz data loader instance
    /// - Parameters:
    ///   - financialSummaryViewModel: ViewModel for financial summary data
    ///   - dataService: Data service for persistence operations
    /// - Returns: Configured QuizDataLoader instance
    static func createDataLoader(
        financialSummaryViewModel: FinancialSummaryViewModel,
        dataService: DataServiceProtocol
    ) -> QuizDataLoaderProtocol {
        return QuizDataLoader(
            financialSummaryViewModel: financialSummaryViewModel,
            dataService: dataService
        )
    }
}
