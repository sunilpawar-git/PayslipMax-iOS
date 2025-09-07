import Foundation
import PDFKit

/// Enhanced parser for earnings and deductions that orchestrates modular components
/// This class follows the Single Responsibility Principle by delegating to specialized components
class EnhancedEarningsDeductionsParser {
    private let abbreviationManager: AbbreviationManager
    private let learningSystem: AbbreviationLearningSystem

    // Component dependencies - injected for better testability and modularity
    private let earningsProcessor: EarningsSectionProcessor
    private let deductionsProcessor: DeductionsSectionProcessor
    private let validator: EarningsDeductionsValidator

    init(abbreviationManager: AbbreviationManager) {
        self.abbreviationManager = abbreviationManager
        self.learningSystem = AbbreviationLearningSystem(abbreviationManager: abbreviationManager)

        // Initialize components with shared dependencies
        self.earningsProcessor = EarningsSectionProcessor(
            abbreviationManager: abbreviationManager,
            learningSystem: learningSystem
        )
        self.deductionsProcessor = DeductionsSectionProcessor(
            abbreviationManager: abbreviationManager,
            learningSystem: learningSystem
        )
        self.validator = EarningsDeductionsValidator(abbreviationManager: abbreviationManager)
    }
    
    /// Extracts earnings and deductions data from the payslip text
    /// - Parameter pageText: The text of the payslip page
    /// - Returns: Structured earnings and deductions data
    func extractEarningsDeductions(from pageText: String) -> EarningsDeductionsData {
        var data = EarningsDeductionsData()

        // Extract and process earnings section
        if let earningsSectionText = SectionParserHelper.extractSection(from: pageText, sectionType: .earnings) {
            let earningsItems = earningsProcessor.extractItems(from: "Description Amount\n" + earningsSectionText)

            // Filter out totals from raw data and store
            var filteredEarningsItems = earningsItems
            filteredEarningsItems.removeValue(forKey: "GROSS_PAY")
            data.rawEarnings = filteredEarningsItems

            // Process earnings items
            earningsProcessor.processItems(earningsItems, into: &data)

            // Extract Gross Pay total if present
            if let grossPay = SectionParserHelper.extractTotalValue(from: earningsSectionText, totalPattern: "GROSS PAY") {
                data.grossPay = grossPay
            }
        }

        // Extract and process deductions section
        if let deductionsSectionText = SectionParserHelper.extractSection(from: pageText, sectionType: .deductions) {
            let deductionsItems = deductionsProcessor.extractItems(from: "Description Amount\n" + deductionsSectionText)

            // Filter out totals from raw data and store
            var filteredDeductionsItems = deductionsItems
            filteredDeductionsItems.removeValue(forKey: "TOTAL_DEDUCTIONS")
            data.rawDeductions = filteredDeductionsItems

            // Process deductions items
            deductionsProcessor.processItems(deductionsItems, into: &data)

            // Extract Total Deductions if present
            if let totalDeductions = SectionParserHelper.extractTotalValue(from: deductionsSectionText, totalPattern: "TOTAL DEDUCTIONS") {
                data.totalDeductions = totalDeductions
            }
        }

        // Apply validation and cleanup
        validator.validateAndAdjustData(&data)
        validator.removeDuplicateEntries(&data)
        validator.calculateMiscValues(&data)

        return data
    }
    
    /// Returns the abbreviation learning system used by this parser
    /// - Returns: The abbreviation learning system
    func getLearningSystem() -> AbbreviationLearningSystem {
        return learningSystem
    }
} 