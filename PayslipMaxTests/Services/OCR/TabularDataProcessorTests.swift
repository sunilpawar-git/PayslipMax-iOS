import XCTest
@testable import PayslipMax

final class TabularDataProcessorTests: XCTestCase {
    
    // MARK: - Properties
    private var processor: TabularDataProcessor!
    
    // MARK: - Setup
    override func setUp() {
        super.setUp()
        processor = TabularDataProcessor()
    }
    
    override func tearDown() {
        processor = nil
        super.tearDown()
    }
    
    // MARK: - Main Processing Tests
    func testProcessTabularData_WithValidData_ReturnsProcessedResult() {
        // Given
        let extractionResult = createMockExtractionResult()
        let tableStructure = createMockTableStructure()
        
        // When
        let result = processor.processTabularData(extractionResult, tableStructure: tableStructure)
        
        // Then
        XCTAssertGreaterThan(result.confidence, 0.0)
        XCTAssertFalse(result.financialEntries.isEmpty)
        XCTAssertGreaterThan(result.calculatedTotals.entryCount, 0)
        XCTAssertGreaterThan(result.metrics.totalCellsProcessed, 0)
    }
    
    func testProcessTabularData_WithMilitaryPayslip_ExtractsMilitaryData() {
        // Given
        let militaryExtractionResult = createMilitaryPayslipExtractionResult()
        let tableStructure = createMockTableStructure()
        
        // When
        let result = processor.processTabularData(militaryExtractionResult, tableStructure: tableStructure)
        
        // Then
        XCTAssertNotNil(result.militaryData.basicPay)
        XCTAssertGreaterThan(result.militaryData.allowances.count, 0)
        XCTAssertGreaterThan(result.militaryData.deductions.count, 0)
        XCTAssertGreaterThan(result.militaryData.confidence, 0.5)
    }
    
    func testProcessTabularData_WithEmptyData_HandlesGracefully() {
        // Given
        let emptyExtractionResult = createEmptyExtractionResult()
        let tableStructure = createMockTableStructure()
        
        // When
        let result = processor.processTabularData(emptyExtractionResult, tableStructure: tableStructure)
        
        // Then
        XCTAssertNotNil(result)
        XCTAssertEqual(result.financialEntries.count, 0)
        XCTAssertEqual(result.calculatedTotals.entryCount, 0)
    }
    
    // MARK: - Structure Analysis Tests
    func testStructureAnalysis_WithValidMatrix_IdentifiesStructure() {
        // Given
        let extractionResult = createStructuredExtractionResult()
        let tableStructure = createMockTableStructure()
        
        // When
        let result = processor.processTabularData(extractionResult, tableStructure: tableStructure)
        
        // Then
        let analysis = result.structureAnalysis
        XCTAssertGreaterThan(analysis.rowCount, 0)
        XCTAssertGreaterThan(analysis.columnCount, 0)
        XCTAssertGreaterThan(analysis.confidence, 0.5)
        XCTAssertFalse(analysis.headerRows.isEmpty)
    }
    
    func testStructureAnalysis_WithHeaderRow_IdentifiesHeaders() {
        // Given
        let extractionWithHeaders = createExtractionResultWithHeaders()
        let tableStructure = createMockTableStructure()
        
        // When
        let result = processor.processTabularData(extractionWithHeaders, tableStructure: tableStructure)
        
        // Then
        let analysis = result.structureAnalysis
        XCTAssertTrue(analysis.headerRows.contains(0)) // First row should be identified as header
        
        let columnAnalysis = analysis.columnAnalysis
        XCTAssertTrue(columnAnalysis.contains { $0.purpose == .earnings })
        XCTAssertTrue(columnAnalysis.contains { $0.purpose == .deductions })
    }
    
    func testStructureAnalysis_WithIrregularStructure_HandlesGracefully() {
        // Given
        let irregularExtractionResult = createIrregularExtractionResult()
        let tableStructure = createMockTableStructure()
        
        // When
        let result = processor.processTabularData(irregularExtractionResult, tableStructure: tableStructure)
        
        // Then
        XCTAssertNotNil(result.structureAnalysis)
        XCTAssertGreaterThanOrEqual(result.structureAnalysis.confidence, 0.0)
    }
    
    // MARK: - Header Classification Tests
    func testHeaderClassification_WithCreditDebitHeaders_ClassifiesCorrectly() {
        // Given
        let extractionWithCreditDebit = createCreditDebitExtractionResult()
        let tableStructure = createMockTableStructure()
        
        // When
        let result = processor.processTabularData(extractionWithCreditDebit, tableStructure: tableStructure)
        
        // Then
        let classification = result.headerClassification
        XCTAssertFalse(classification.creditColumns.isEmpty)
        XCTAssertFalse(classification.debitColumns.isEmpty)
        XCTAssertGreaterThan(classification.confidence, 0.6)
    }
    
    func testHeaderClassification_WithCodeDescriptionHeaders_IdentifiesColumns() {
        // Given
        let extractionWithCodeDesc = createCodeDescriptionExtractionResult()
        let tableStructure = createMockTableStructure()
        
        // When
        let result = processor.processTabularData(extractionWithCodeDesc, tableStructure: tableStructure)
        
        // Then
        let classification = result.headerClassification
        XCTAssertFalse(classification.codeColumns.isEmpty)
        XCTAssertFalse(classification.descriptionColumns.isEmpty)
    }
    
    // MARK: - Financial Entry Processing Tests
    func testFinancialEntryProcessing_WithValidEntries_ProcessesCorrectly() {
        // Given
        let extractionResult = createFinancialEntriesExtractionResult()
        let tableStructure = createMockTableStructure()
        
        // When
        let result = processor.processTabularData(extractionResult, tableStructure: tableStructure)
        
        // Then
        let entries = result.financialEntries
        XCTAssertGreaterThan(entries.count, 0)
        
        // Verify entry structure
        for entry in entries {
            XCTAssertFalse(entry.code.isEmpty)
            XCTAssertNotEqual(entry.type, .other) // Should be classified
            XCTAssertGreaterThan(entry.confidence, 0.0)
        }
    }
    
    func testFinancialEntryProcessing_WithBasicPay_IdentifiesCorrectly() {
        // Given
        let extractionWithBasicPay = createBasicPayExtractionResult()
        let tableStructure = createMockTableStructure()
        
        // When
        let result = processor.processTabularData(extractionWithBasicPay, tableStructure: tableStructure)
        
        // Then
        let basicPayEntry = result.financialEntries.first { entry in
            entry.code.contains("BP") || entry.description.uppercased().contains("BASIC PAY")
        }
        
        XCTAssertNotNil(basicPayEntry)
        XCTAssertEqual(basicPayEntry?.type, .earnings)
        XCTAssertGreaterThan(basicPayEntry?.credits.count ?? 0, 0)
    }
    
    func testFinancialEntryProcessing_WithAllowances_ClassifiesCorrectly() {
        // Given
        let extractionWithAllowances = createAllowancesExtractionResult()
        let tableStructure = createMockTableStructure()
        
        // When
        let result = processor.processTabularData(extractionWithAllowances, tableStructure: tableStructure)
        
        // Then
        let allowanceEntries = result.financialEntries.filter { $0.type == .allowance }
        XCTAssertGreaterThan(allowanceEntries.count, 0)
        
        // Verify allowance identification
        let daEntry = allowanceEntries.first { $0.description.contains("DEARNESS") }
        XCTAssertNotNil(daEntry)
    }
    
    func testFinancialEntryProcessing_WithDeductions_ProcessesCorrectly() {
        // Given
        let extractionWithDeductions = createDeductionsExtractionResult()
        let tableStructure = createMockTableStructure()
        
        // When
        let result = processor.processTabularData(extractionWithDeductions, tableStructure: tableStructure)
        
        // Then
        let deductionEntries = result.financialEntries.filter { $0.type == .deduction || $0.type == .tax }
        XCTAssertGreaterThan(deductionEntries.count, 0)
        
        // Verify tax identification
        let taxEntry = deductionEntries.first { $0.description.uppercased().contains("TAX") }
        XCTAssertNotNil(taxEntry)
        XCTAssertEqual(taxEntry?.type, .tax)
    }
    
    // MARK: - Total Calculations Tests
    func testCalculateTotals_WithValidEntries_CalculatesCorrectly() {
        // Given
        let extractionResult = createBalancedExtractionResult()
        let tableStructure = createMockTableStructure()
        
        // When
        let result = processor.processTabularData(extractionResult, tableStructure: tableStructure)
        
        // Then
        let totals = result.calculatedTotals
        XCTAssertGreaterThan(totals.grossEarnings, 0.0)
        XCTAssertGreaterThan(totals.totalDeductions, 0.0)
        XCTAssertEqual(totals.netPay, totals.grossEarnings - totals.totalDeductions, accuracy: 0.01)
        XCTAssertGreaterThan(totals.confidence, 0.5)
    }
    
    func testCalculateTotals_WithZeroEntries_HandlesCorrectly() {
        // Given
        let extractionWithZeros = createZeroAmountExtractionResult()
        let tableStructure = createMockTableStructure()
        
        // When
        let result = processor.processTabularData(extractionWithZeros, tableStructure: tableStructure)
        
        // Then
        let totals = result.calculatedTotals
        XCTAssertGreaterThanOrEqual(totals.grossEarnings, 0.0)
        XCTAssertGreaterThanOrEqual(totals.totalDeductions, 0.0)
        XCTAssertGreaterThanOrEqual(totals.netPay, 0.0)
    }
    
    // MARK: - Military Specific Processing Tests
    func testMilitaryProcessing_WithBasicPay_ExtractsCorrectly() {
        // Given
        let militaryExtraction = createMilitaryBasicPayExtractionResult()
        let tableStructure = createMockTableStructure()
        
        // When
        let result = processor.processTabularData(militaryExtraction, tableStructure: tableStructure)
        
        // Then
        let militaryData = result.militaryData
        XCTAssertNotNil(militaryData.basicPay)
        XCTAssertEqual(militaryData.basicPay?.currency, .inr)
        XCTAssertGreaterThan(militaryData.basicPay?.value ?? 0.0, 0.0)
    }
    
    func testMilitaryProcessing_WithAllowances_ExtractsAllowances() {
        // Given
        let militaryAllowancesExtraction = createMilitaryAllowancesExtractionResult()
        let tableStructure = createMockTableStructure()
        
        // When
        let result = processor.processTabularData(militaryAllowancesExtraction, tableStructure: tableStructure)
        
        // Then
        let militaryData = result.militaryData
        XCTAssertGreaterThan(militaryData.allowances.count, 0)
        
        // Verify specific military allowances
        let daAllowance = militaryData.allowances.first { $0.description.contains("DEARNESS") }
        XCTAssertNotNil(daAllowance)
        
        let hraAllowance = militaryData.allowances.first { $0.description.contains("HRA") }
        XCTAssertNotNil(hraAllowance)
    }
    
    func testMilitaryProcessing_WithDeductions_ExtractsDeductions() {
        // Given
        let militaryDeductionsExtraction = createMilitaryDeductionsExtractionResult()
        let tableStructure = createMockTableStructure()
        
        // When
        let result = processor.processTabularData(militaryDeductionsExtraction, tableStructure: tableStructure)
        
        // Then
        let militaryData = result.militaryData
        XCTAssertGreaterThan(militaryData.deductions.count, 0)
        
        // Verify specific military deductions
        let pensionDeduction = militaryData.deductions.first { $0.description.contains("PENSION") }
        XCTAssertNotNil(pensionDeduction)
    }
    
    // MARK: - Currency Parsing Tests
    func testCurrencyParsing_WithINRSymbol_ParsesCorrectly() {
        // Given
        let extractionWithINR = createINRExtractionResult()
        let tableStructure = createMockTableStructure()
        
        // When
        let result = processor.processTabularData(extractionWithINR, tableStructure: tableStructure)
        
        // Then
        let entries = result.financialEntries
        let amountsWithINR = entries.flatMap { $0.credits + $0.debits }
        
        XCTAssertTrue(amountsWithINR.allSatisfy { $0.currency == .inr })
    }
    
    func testCurrencyParsing_WithDifferentFormats_Standardizes() {
        // Given
        let extractionWithMixedCurrency = createMixedCurrencyExtractionResult()
        let tableStructure = createMockTableStructure()
        
        // When
        let result = processor.processTabularData(extractionWithMixedCurrency, tableStructure: tableStructure)
        
        // Then
        let entries = result.financialEntries
        let amounts = entries.flatMap { $0.credits + $0.debits }
        
        // All should be standardized to INR
        XCTAssertTrue(amounts.allSatisfy { $0.currency == .inr })
    }
    
    // MARK: - Validation Tests
    func testValidation_WithInconsistentData_IdentifiesIssues() {
        // Given
        let inconsistentExtraction = createInconsistentExtractionResult()
        let tableStructure = createMockTableStructure()
        
        // When
        let result = processor.processTabularData(inconsistentExtraction, tableStructure: tableStructure)
        
        // Then
        let entries = result.financialEntries
        let invalidEntries = entries.filter { !$0.validationResult.isValid }
        
        // Should identify some validation issues
        XCTAssertGreaterThan(invalidEntries.count, 0)
    }
    
    // MARK: - Performance Tests
    func testProcessTabularData_PerformanceWithLargeDataset() {
        // Given
        let largeExtraction = createLargeExtractionResult()
        let tableStructure = createMockTableStructure()
        
        // When & Then
        measure {
            let result = processor.processTabularData(largeExtraction, tableStructure: tableStructure)
            XCTAssertNotNil(result)
        }
    }
    
    func testProcessTabularData_MemoryUsage() {
        // Given
        let mediumExtraction = createMediumExtractionResult()
        let tableStructure = createMockTableStructure()
        
        // When
        let result = processor.processTabularData(mediumExtraction, tableStructure: tableStructure)
        
        // Then
        XCTAssertNotNil(result)
        // Memory usage should be reasonable (verified through instruments)
    }
    
    // MARK: - Edge Cases Tests
    func testProcessTabularData_WithMalformedData_HandlesGracefully() {
        // Given
        let malformedExtraction = createMalformedExtractionResult()
        let tableStructure = createMockTableStructure()
        
        // When
        let result = processor.processTabularData(malformedExtraction, tableStructure: tableStructure)
        
        // Then
        XCTAssertNotNil(result)
        XCTAssertGreaterThanOrEqual(result.confidence, 0.0)
    }
    
    func testProcessTabularData_WithNegativeAmounts_HandlesCorrectly() {
        // Given
        let negativeAmountExtraction = createNegativeAmountExtractionResult()
        let tableStructure = createMockTableStructure()
        
        // When
        let result = processor.processTabularData(negativeAmountExtraction, tableStructure: tableStructure)
        
        // Then
        let entries = result.financialEntries
        let negativeEntries = entries.filter { $0.netAmount < 0 }
        
        XCTAssertGreaterThan(negativeEntries.count, 0) // Should handle negative amounts
    }
}

// MARK: - Mock Data Creation
extension TabularDataProcessorTests {
    
    private func createMockExtractionResult() -> CellExtractionResult {
        let cells = [
            [
                createExtractedCell("CREDIT", position: CellPosition(row: 0, column: 0), type: .header),
                createExtractedCell("DEBIT", position: CellPosition(row: 0, column: 1), type: .header)
            ],
            [
                createExtractedCell("15000.00", position: CellPosition(row: 1, column: 0), type: .amount),
                createExtractedCell("2500.00", position: CellPosition(row: 1, column: 1), type: .amount)
            ]
        ]
        
        return CellExtractionResult(
            extractedCells: cells,
            metrics: CellProcessingMetrics(),
            overallConfidence: 0.8
        )
    }
    
    private func createMilitaryPayslipExtractionResult() -> CellExtractionResult {
        let cells = [
            [
                createExtractedCell("PAY CODE", position: CellPosition(row: 0, column: 0), type: .header),
                createExtractedCell("DESCRIPTION", position: CellPosition(row: 0, column: 1), type: .header),
                createExtractedCell("CREDIT", position: CellPosition(row: 0, column: 2), type: .header),
                createExtractedCell("DEBIT", position: CellPosition(row: 0, column: 3), type: .header)
            ],
            [
                createExtractedCell("BP001", position: CellPosition(row: 1, column: 0), type: .code),
                createExtractedCell("BASIC PAY", position: CellPosition(row: 1, column: 1), type: .code),
                createExtractedCell("15000.00", position: CellPosition(row: 1, column: 2), type: .amount),
                createExtractedCell("0.00", position: CellPosition(row: 1, column: 3), type: .amount)
            ],
            [
                createExtractedCell("DA001", position: CellPosition(row: 2, column: 0), type: .code),
                createExtractedCell("DEARNESS ALLOWANCE", position: CellPosition(row: 2, column: 1), type: .code),
                createExtractedCell("7500.00", position: CellPosition(row: 2, column: 2), type: .amount),
                createExtractedCell("0.00", position: CellPosition(row: 2, column: 3), type: .amount)
            ],
            [
                createExtractedCell("IT001", position: CellPosition(row: 3, column: 0), type: .code),
                createExtractedCell("INCOME TAX", position: CellPosition(row: 3, column: 1), type: .code),
                createExtractedCell("0.00", position: CellPosition(row: 3, column: 2), type: .amount),
                createExtractedCell("2500.00", position: CellPosition(row: 3, column: 3), type: .amount)
            ]
        ]
        
        return CellExtractionResult(
            extractedCells: cells,
            metrics: CellProcessingMetrics(),
            overallConfidence: 0.9
        )
    }
    
    private func createEmptyExtractionResult() -> CellExtractionResult {
        return CellExtractionResult(
            extractedCells: [],
            metrics: CellProcessingMetrics(),
            overallConfidence: 0.0
        )
    }
    
    private func createStructuredExtractionResult() -> CellExtractionResult {
        return createMockExtractionResult()
    }
    
    private func createExtractionResultWithHeaders() -> CellExtractionResult {
        return createMilitaryPayslipExtractionResult()
    }
    
    private func createIrregularExtractionResult() -> CellExtractionResult {
        let cells = [
            [createExtractedCell("HEADER", position: CellPosition(row: 0, column: 0), type: .header)],
            [
                createExtractedCell("Data1", position: CellPosition(row: 1, column: 0), type: .code),
                createExtractedCell("Data2", position: CellPosition(row: 1, column: 1), type: .code)
            ],
            [] // Empty row
        ]
        
        return CellExtractionResult(
            extractedCells: cells,
            metrics: CellProcessingMetrics(),
            overallConfidence: 0.5
        )
    }
    
    private func createCreditDebitExtractionResult() -> CellExtractionResult {
        let cells = [
            [
                createExtractedCell("CREDITS", position: CellPosition(row: 0, column: 0), type: .header),
                createExtractedCell("DEBITS", position: CellPosition(row: 0, column: 1), type: .header)
            ]
        ]
        
        return CellExtractionResult(
            extractedCells: cells,
            metrics: CellProcessingMetrics(),
            overallConfidence: 0.8
        )
    }
    
    private func createCodeDescriptionExtractionResult() -> CellExtractionResult {
        let cells = [
            [
                createExtractedCell("CODE", position: CellPosition(row: 0, column: 0), type: .header),
                createExtractedCell("DESCRIPTION", position: CellPosition(row: 0, column: 1), type: .header)
            ]
        ]
        
        return CellExtractionResult(
            extractedCells: cells,
            metrics: CellProcessingMetrics(),
            overallConfidence: 0.8
        )
    }
    
    private func createFinancialEntriesExtractionResult() -> CellExtractionResult {
        return createMilitaryPayslipExtractionResult()
    }
    
    private func createBasicPayExtractionResult() -> CellExtractionResult {
        let cells = [
            [
                createExtractedCell("BP001", position: CellPosition(row: 0, column: 0), type: .code),
                createExtractedCell("BASIC PAY", position: CellPosition(row: 0, column: 1), type: .code),
                createExtractedCell("15000.00", position: CellPosition(row: 0, column: 2), type: .amount)
            ]
        ]
        
        return CellExtractionResult(
            extractedCells: cells,
            metrics: CellProcessingMetrics(),
            overallConfidence: 0.9
        )
    }
    
    private func createAllowancesExtractionResult() -> CellExtractionResult {
        let cells = [
            [
                createExtractedCell("DA001", position: CellPosition(row: 0, column: 0), type: .code),
                createExtractedCell("DEARNESS ALLOWANCE", position: CellPosition(row: 0, column: 1), type: .code),
                createExtractedCell("7500.00", position: CellPosition(row: 0, column: 2), type: .amount)
            ],
            [
                createExtractedCell("HRA001", position: CellPosition(row: 1, column: 0), type: .code),
                createExtractedCell("HOUSE RENT ALLOWANCE", position: CellPosition(row: 1, column: 1), type: .code),
                createExtractedCell("5000.00", position: CellPosition(row: 1, column: 2), type: .amount)
            ]
        ]
        
        return CellExtractionResult(
            extractedCells: cells,
            metrics: CellProcessingMetrics(),
            overallConfidence: 0.8
        )
    }
    
    private func createDeductionsExtractionResult() -> CellExtractionResult {
        let cells = [
            [
                createExtractedCell("IT001", position: CellPosition(row: 0, column: 0), type: .code),
                createExtractedCell("INCOME TAX", position: CellPosition(row: 0, column: 1), type: .code),
                createExtractedCell("2500.00", position: CellPosition(row: 0, column: 2), type: .amount)
            ],
            [
                createExtractedCell("PF001", position: CellPosition(row: 1, column: 0), type: .code),
                createExtractedCell("PROVIDENT FUND", position: CellPosition(row: 1, column: 1), type: .code),
                createExtractedCell("1800.00", position: CellPosition(row: 1, column: 2), type: .amount)
            ]
        ]
        
        return CellExtractionResult(
            extractedCells: cells,
            metrics: CellProcessingMetrics(),
            overallConfidence: 0.8
        )
    }
    
    private func createBalancedExtractionResult() -> CellExtractionResult {
        return createMilitaryPayslipExtractionResult()
    }
    
    private func createZeroAmountExtractionResult() -> CellExtractionResult {
        let cells = [
            [
                createExtractedCell("CODE", position: CellPosition(row: 0, column: 0), type: .code),
                createExtractedCell("0.00", position: CellPosition(row: 0, column: 1), type: .amount)
            ]
        ]
        
        return CellExtractionResult(
            extractedCells: cells,
            metrics: CellProcessingMetrics(),
            overallConfidence: 0.6
        )
    }
    
    private func createMilitaryBasicPayExtractionResult() -> CellExtractionResult {
        return createBasicPayExtractionResult()
    }
    
    private func createMilitaryAllowancesExtractionResult() -> CellExtractionResult {
        return createAllowancesExtractionResult()
    }
    
    private func createMilitaryDeductionsExtractionResult() -> CellExtractionResult {
        let cells = [
            [
                createExtractedCell("PEN001", position: CellPosition(row: 0, column: 0), type: .code),
                createExtractedCell("PENSION CONTRIBUTION", position: CellPosition(row: 0, column: 1), type: .code),
                createExtractedCell("1500.00", position: CellPosition(row: 0, column: 2), type: .amount)
            ]
        ]
        
        return CellExtractionResult(
            extractedCells: cells,
            metrics: CellProcessingMetrics(),
            overallConfidence: 0.8
        )
    }
    
    private func createINRExtractionResult() -> CellExtractionResult {
        let cells = [
            [
                createExtractedCell("₹15000.00", position: CellPosition(row: 0, column: 0), type: .amount),
                createExtractedCell("₹2500.00", position: CellPosition(row: 0, column: 1), type: .amount)
            ]
        ]
        
        return CellExtractionResult(
            extractedCells: cells,
            metrics: CellProcessingMetrics(),
            overallConfidence: 0.8
        )
    }
    
    private func createMixedCurrencyExtractionResult() -> CellExtractionResult {
        let cells = [
            [
                createExtractedCell("Rs. 15000", position: CellPosition(row: 0, column: 0), type: .amount),
                createExtractedCell("₹2500.00", position: CellPosition(row: 0, column: 1), type: .amount),
                createExtractedCell("INR 1200", position: CellPosition(row: 0, column: 2), type: .amount)
            ]
        ]
        
        return CellExtractionResult(
            extractedCells: cells,
            metrics: CellProcessingMetrics(),
            overallConfidence: 0.7
        )
    }
    
    private func createInconsistentExtractionResult() -> CellExtractionResult {
        let cells = [
            [
                createExtractedCell("INVALID", position: CellPosition(row: 0, column: 0), type: .amount), // Text in numeric cell
                createExtractedCell("", position: CellPosition(row: 0, column: 1), type: .header) // Empty header
            ]
        ]
        
        return CellExtractionResult(
            extractedCells: cells,
            metrics: CellProcessingMetrics(),
            overallConfidence: 0.3
        )
    }
    
    private func createLargeExtractionResult() -> CellExtractionResult {
        var cells: [[ExtractedCellData]] = []
        
        for row in 0..<100 {
            var rowCells: [ExtractedCellData] = []
            for col in 0..<10 {
                let cellType: CellType = row == 0 ? .header : (col % 2 == 0 ? .code : .amount)
                let text = row == 0 ? "HEADER\(col)" : (col % 2 == 0 ? "Code\(row)" : "\(row * 100).00")
                
                rowCells.append(createExtractedCell(text, position: CellPosition(row: row, column: col), type: cellType))
            }
            cells.append(rowCells)
        }
        
        return CellExtractionResult(
            extractedCells: cells,
            metrics: CellProcessingMetrics(),
            overallConfidence: 0.8
        )
    }
    
    private func createMediumExtractionResult() -> CellExtractionResult {
        var cells: [[ExtractedCellData]] = []
        
        for row in 0..<50 {
            var rowCells: [ExtractedCellData] = []
            for col in 0..<5 {
                let cellType: CellType = row == 0 ? .header : (col % 2 == 0 ? .code : .amount)
                let text = row == 0 ? "HEADER\(col)" : (col % 2 == 0 ? "Code\(row)" : "\(row * 50).00")
                
                rowCells.append(createExtractedCell(text, position: CellPosition(row: row, column: col), type: cellType))
            }
            cells.append(rowCells)
        }
        
        return CellExtractionResult(
            extractedCells: cells,
            metrics: CellProcessingMetrics(),
            overallConfidence: 0.8
        )
    }
    
    private func createMalformedExtractionResult() -> CellExtractionResult {
        let cells = [
            [createExtractedCell("", position: CellPosition(row: 0, column: 0), type: .empty)],
            [], // Empty row
            [createExtractedCell("Valid", position: CellPosition(row: 2, column: 0), type: .code)]
        ]
        
        return CellExtractionResult(
            extractedCells: cells,
            metrics: CellProcessingMetrics(),
            overallConfidence: 0.2
        )
    }
    
    private func createNegativeAmountExtractionResult() -> CellExtractionResult {
        let cells = [
            [
                createExtractedCell("ADJ001", position: CellPosition(row: 0, column: 0), type: .code),
                createExtractedCell("ADJUSTMENT", position: CellPosition(row: 0, column: 1), type: .code),
                createExtractedCell("-500.00", position: CellPosition(row: 0, column: 2), type: .amount)
            ]
        ]
        
        return CellExtractionResult(
            extractedCells: cells,
            metrics: CellProcessingMetrics(),
            overallConfidence: 0.8
        )
    }
    
    private func createMockTableStructure() -> DetectedTableStructure {
        return DetectedTableStructure(
            regions: [],
            gridLines: GridLines(horizontal: [], vertical: [], confidence: 0.8),
            cellMatrix: [],
            confidence: 0.8,
            metadata: TableMetadata(
                rowCount: 4,
                columnCount: 4,
                detectionMethod: .geometricAnalysis,
                processingTime: 0.1
            )
        )
    }
    
    private func createExtractedCell(
        _ text: String,
        position: CellPosition,
        type: CellType
    ) -> ExtractedCellData {
        
        return ExtractedCellData(
            position: position,
            rawText: text,
            processedText: text,
            confidence: 0.8,
            cellType: type,
            validationResult: CellValidationResult(isValid: true, errors: [], confidenceAdjustment: 1.0),
            boundingBox: CGRect(x: 0.1, y: 0.8, width: 0.2, height: 0.05),
            textCandidates: [],
            metadata: CellMetadata(
                multiLine: false,
                hasNumericContent: type == .amount,
                languageDetection: .english
            )
        )
    }
}