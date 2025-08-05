import Foundation
import CoreGraphics

/// Protocol for military financial data extraction services
protocol MilitaryFinancialDataExtractorProtocol {
    func extractMilitaryTabularData(from text: String) -> ([String: Double], [String: Double])
    func extractMilitaryTabularData(from textElements: [TextElement]?) -> ([String: Double], [String: Double])
}

/// Service responsible for extracting financial data from military payslips
///
/// This service handles the complex task of extracting earnings and deductions from
/// military payslip formats, particularly PCDA (Principal Controller of Defence Accounts)
/// format which uses specific coding patterns and tabular data layouts.
class MilitaryFinancialDataExtractor: MilitaryFinancialDataExtractorProtocol {
    
    // MARK: - Dependencies
    
    private let tableDetector: SimpleTableDetectorProtocol
    private let spatialAnalyzer: SpatialTextAnalyzerProtocol
    
    // MARK: - Initialization
    
    init(tableDetector: SimpleTableDetectorProtocol = SimpleTableDetector(),
         spatialAnalyzer: SpatialTextAnalyzerProtocol = SpatialTextAnalyzer()) {
        self.tableDetector = tableDetector
        self.spatialAnalyzer = spatialAnalyzer
    }
    
    // MARK: - Constants
    
    /// Known earning codes in military payslips
    private let earningCodes = Set([
        "BPAY", "DA", "DP", "HRA", "TA", "MISC", "CEA", "TPT", 
        "WASHIA", "OUTFITA", "MSP", "ARR-RSHNA", "RSHNA", 
        "RH12", "TPTA", "TPTADA"
    ])
    
    /// Known deduction codes in military payslips
    private let deductionCodes = Set([
        "DSOP", "AGIF", "ITAX", "IT", "SBI", "PLI", "AFNB", 
        "AOBA", "PLIA", "HOSP", "CDA", "CGEIS", "DEDN"
    ])
    
    // MARK: - Public Methods
    
    /// Extracts structured earnings and deductions data from military payslip text.
    ///
    /// This method performs sophisticated pattern matching to extract financial components
    /// from military payslips, particularly those following PCDA (Principal Controller of
    /// Defence Accounts) formatting standards.
    ///
    /// ## Military Payslip Format Recognition
    ///
    /// The method specifically handles:
    /// - **PCDA Format**: Standard format used by Indian Armed Forces
    /// - **Two-column layouts**: `BPAY 123456.00 DSOP 12345.00`
    /// - **Single-column layouts**: `ITAX 5000.00`
    /// - **Summary sections**: Total deductions, gross pay, net remittance
    ///
    /// ## Extraction Process
    ///
    /// 1. **Format Detection**: Identifies PCDA or military-specific markers
    /// 2. **Pattern Matching**: Uses regex to extract code-value pairs
    /// 3. **Classification**: Categorizes codes as earnings or deductions using known military codes
    /// 4. **Validation**: Cross-references totals with explicit gross/net amounts
    /// 5. **Reconciliation**: Adjusts for discrepancies between calculated and stated totals
    ///
    /// The method handles common OCR irregularities and format variations while maintaining
    /// accuracy in financial data extraction.
    ///
    /// - Parameter text: The complete payslip text content.
    /// - Returns: A tuple containing:
    ///   - The first dictionary maps earning component names (String) to their amounts (Double)
    ///   - The second dictionary maps deduction component names (String) to their amounts (Double)
    func extractMilitaryTabularData(from text: String) -> ([String: Double], [String: Double]) {
        var earnings: [String: Double] = [:]
        var deductions: [String: Double] = [:]
        
        print("MilitaryFinancialDataExtractor: Starting tabular data extraction from \(text.count) characters")
        
        // Check for PCDA format
        if text.contains("PCDA") || text.contains("Principal Controller of Defence Accounts") {
            print("MilitaryFinancialDataExtractor: Detected PCDA format for tabular data extraction")
            
            // Extract using PCDA patterns
            extractPCDATabularData(from: text, earnings: &earnings, deductions: &deductions)
            
            // Process total reconciliation
            reconcileTotals(from: text, earnings: &earnings, deductions: &deductions)
        } else {
            print("MilitaryFinancialDataExtractor: PCDA format not detected in text")
            print("MilitaryFinancialDataExtractor: Text preview: \(String(text.prefix(200)))")
        }
        
        print("MilitaryFinancialDataExtractor: Final result - earnings: \(earnings.count), deductions: \(deductions.count)")
        return (earnings, deductions)
    }
    
    /// Enhanced extraction method using table structure detection
    ///
    /// This method uses spatial analysis to detect table structures and extract financial data
    /// more accurately than regex-based approaches. Falls back to text-based extraction if
    /// table detection fails.
    ///
    /// - Parameter textElements: Array of text elements with spatial positioning
    /// - Returns: A tuple containing earnings and deductions dictionaries
    func extractMilitaryTabularData(from textElements: [TextElement]?) -> ([String: Double], [String: Double]) {
        guard let textElements = textElements, !textElements.isEmpty else {
            print("MilitaryFinancialDataExtractor: No text elements provided, cannot perform spatial analysis")
            return ([:], [:])
        }
        
        print("MilitaryFinancialDataExtractor: Starting spatial table analysis with \(textElements.count) text elements")
        
        // Attempt table structure detection
        if let tableStructure = tableDetector.detectTableStructure(from: textElements) {
            print("MilitaryFinancialDataExtractor: Table structure detected - \(tableStructure.rows.count) rows, \(tableStructure.columns.count) columns")
            
            let (earnings, deductions) = extractFromTableStructure(tableStructure: tableStructure, textElements: textElements)
            
            // Validate that we extracted meaningful data
            if !earnings.isEmpty || !deductions.isEmpty {
                print("MilitaryFinancialDataExtractor: Spatial extraction successful - earnings: \(earnings.count), deductions: \(deductions.count)")
                return (earnings, deductions)
            } else {
                print("MilitaryFinancialDataExtractor: Spatial extraction yielded no results, falling back to text-based extraction")
            }
        } else {
            print("MilitaryFinancialDataExtractor: No table structure detected, falling back to text-based extraction")
        }
        
        // Fallback to text-based extraction
        let combinedText = textElements.map { $0.text }.joined(separator: " ")
        return extractMilitaryTabularData(from: combinedText)
    }
    
    // MARK: - Private Methods
    
    /// Extracts financial data from detected table structure using spatial analysis
    private func extractFromTableStructure(tableStructure: TableStructure, textElements: [TextElement]) -> ([String: Double], [String: Double]) {
        var earnings: [String: Double] = [:]
        var deductions: [String: Double] = [:]
        
        // Use spatial analyzer to associate text with table cells
        guard let spatialTable = spatialAnalyzer.associateTextWithCells(
            textElements: textElements, 
            tableStructure: tableStructure
        ) else {
            print("MilitaryFinancialDataExtractor: Failed to create spatial table structure")
            return (earnings, deductions)
        }
        
        print("MilitaryFinancialDataExtractor: Created spatial table with \(spatialTable.rowCount) rows, \(spatialTable.columnCount) columns")
        
        // Look for header patterns to identify earnings and deductions columns
        let (earningsColumns, deductionsColumns) = identifyFinancialColumnsFromSpatialTable(spatialTable)
        
        // Extract data from identified columns
        extractDataFromSpatialTable(
            spatialTable: spatialTable,
            earningsColumns: earningsColumns,
            deductionsColumns: deductionsColumns,
            earnings: &earnings,
            deductions: &deductions
        )
        
        return (earnings, deductions)
    }
    
    /// Maps text elements to table cells based on spatial positioning
    private func mapTextElementsToTableCells(textElements: [TextElement], tableStructure: TableStructure) -> [Int: [Int: [TextElement]]] {
        var cellMapping: [Int: [Int: [TextElement]]] = [:]
        
        for element in textElements {
            if let (rowIndex, columnIndex) = findTableCell(for: element, in: tableStructure) {
                if cellMapping[rowIndex] == nil {
                    cellMapping[rowIndex] = [:]
                }
                if cellMapping[rowIndex]![columnIndex] == nil {
                    cellMapping[rowIndex]![columnIndex] = []
                }
                cellMapping[rowIndex]![columnIndex]!.append(element)
            }
        }
        
        return cellMapping
    }
    
    /// Finds the table cell (row, column) for a given text element
    private func findTableCell(for element: TextElement, in tableStructure: TableStructure) -> (Int, Int)? {
        // Find the row
        let elementCenterY = element.bounds.midY
        var rowIndex: Int?
        
        for (index, row) in tableStructure.rows.enumerated() {
            if elementCenterY >= row.bounds.minY && elementCenterY <= row.bounds.maxY {
                rowIndex = index
                break
            }
        }
        
        // Find the column
        let elementCenterX = element.bounds.midX
        var columnIndex: Int?
        
        for (index, column) in tableStructure.columns.enumerated() {
            if elementCenterX >= column.bounds.minX && elementCenterX <= column.bounds.maxX {
                columnIndex = index
                break
            }
        }
        
        if let row = rowIndex, let column = columnIndex {
            return (row, column)
        }
        
        return nil
    }
    
    /// Identifies the header row containing column labels
    private func identifyHeaderRow(cellMapping: [Int: [Int: [TextElement]]], tableStructure: TableStructure) -> Int? {
        for rowIndex in 0..<tableStructure.rows.count {
            if let rowData = cellMapping[rowIndex] {
                let rowText = rowData.values.flatMap { $0 }.map { $0.text.uppercased() }.joined(separator: " ")
                
                // Look for common header patterns
                if rowText.contains("CREDIT") || rowText.contains("DEBIT") ||
                   rowText.contains("EARNINGS") || rowText.contains("DEDUCTIONS") ||
                   rowText.contains("DESCRIPTION") || rowText.contains("AMOUNT") {
                    return rowIndex
                }
            }
        }
        
        // If no explicit header found, assume first row
        return 0
    }
    
    /// Identifies columns containing earnings and deductions
    private func identifyFinancialColumns(cellMapping: [Int: [Int: [TextElement]]], tableStructure: TableStructure, headerRowIndex: Int) -> (Int?, Int?) {
        var earningsColumn: Int?
        var deductionsColumn: Int?
        
        if let headerRow = cellMapping[headerRowIndex] {
            for (columnIndex, elements) in headerRow {
                let columnText = elements.map { $0.text.uppercased() }.joined(separator: " ")
                
                if columnText.contains("CREDIT") || columnText.contains("EARNINGS") {
                    earningsColumn = columnIndex
                } else if columnText.contains("DEBIT") || columnText.contains("DEDUCTIONS") {
                    deductionsColumn = columnIndex
                }
            }
        }
        
        return (earningsColumn, deductionsColumn)
    }
    
    /// Extracts financial data from identified columns
    private func extractDataFromColumns(cellMapping: [Int: [Int: [TextElement]]], tableStructure: TableStructure, earningsColumn: Int?, deductionsColumn: Int?, earnings: inout [String: Double], deductions: inout [String: Double]) {
        
        // Process each row after the header
        for rowIndex in 1..<tableStructure.rows.count {
            guard let rowData = cellMapping[rowIndex] else { continue }
            
            // Extract earnings data
            if let earningsCol = earningsColumn, let earningsElements = rowData[earningsCol] {
                processFinancialColumn(elements: earningsElements, isEarnings: true, earnings: &earnings, deductions: &deductions)
            }
            
            // Extract deductions data
            if let deductionsCol = deductionsColumn, let deductionsElements = rowData[deductionsCol] {
                processFinancialColumn(elements: deductionsElements, isEarnings: false, earnings: &earnings, deductions: &deductions)
            }
        }
    }
    
    /// Processes financial data from a specific column
    private func processFinancialColumn(elements: [TextElement], isEarnings: Bool, earnings: inout [String: Double], deductions: inout [String: Double]) {
        for element in elements {
            let text = element.text.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Try to extract code-value pairs
            if let (code, value) = extractCodeValuePair(from: text) {
                if isEarnings {
                    earnings[code] = value
                } else {
                    deductions[code] = value
                }
            }
        }
    }
    
    /// Identifies financial columns from spatial table structure
    private func identifyFinancialColumnsFromSpatialTable(_ spatialTable: SpatialTableStructure) -> ([Int], [Int]) {
        var earningsColumns: [Int] = []
        var deductionsColumns: [Int] = []
        
        // Use headers if available
        if let headers = spatialTable.headers {
            for (index, header) in headers.enumerated() {
                let headerLower = header.lowercased()
                if headerLower.contains("credit") || headerLower.contains("earning") {
                    earningsColumns.append(index)
                } else if headerLower.contains("debit") || headerLower.contains("deduction") {
                    deductionsColumns.append(index)
                }
            }
        }
        
        // If no headers found, analyze content patterns
        if earningsColumns.isEmpty && deductionsColumns.isEmpty {
            for columnIndex in 0..<spatialTable.columnCount {
                let columnCells = spatialTable.cellsInColumn(columnIndex)
                let hasEarningCodes = columnCells.contains { cell in
                    earningCodes.contains { code in
                        cell.mergedText.uppercased().contains(code)
                    }
                }
                let hasDeductionCodes = columnCells.contains { cell in
                    deductionCodes.contains { code in
                        cell.mergedText.uppercased().contains(code)
                    }
                }
                
                if hasEarningCodes {
                    earningsColumns.append(columnIndex)
                } else if hasDeductionCodes {
                    deductionsColumns.append(columnIndex)
                }
            }
        }
        
        print("MilitaryFinancialDataExtractor: Identified earnings columns: \(earningsColumns), deductions columns: \(deductionsColumns)")
        return (earningsColumns, deductionsColumns)
    }
    
    /// Extracts financial data from spatial table structure
    private func extractDataFromSpatialTable(
        spatialTable: SpatialTableStructure,
        earningsColumns: [Int],
        deductionsColumns: [Int],
        earnings: inout [String: Double],
        deductions: inout [String: Double]
    ) {
        // Skip first row if it contains headers
        let startRowIndex = spatialTable.headers != nil ? 1 : 0
        
        for rowIndex in startRowIndex..<spatialTable.rowCount {
            let rowCells = spatialTable.cellsInRow(rowIndex)
            
            // Process earnings columns
            for columnIndex in earningsColumns {
                if let cell = spatialTable.cell(at: rowIndex, column: columnIndex) {
                    processFinancialCell(cell: cell, isEarning: true, spatialTable: spatialTable, earnings: &earnings, deductions: &deductions)
                }
            }
            
            // Process deductions columns
            for columnIndex in deductionsColumns {
                if let cell = spatialTable.cell(at: rowIndex, column: columnIndex) {
                    processFinancialCell(cell: cell, isEarning: false, spatialTable: spatialTable, earnings: &earnings, deductions: &deductions)
                }
            }
            
            // For military payslips with paired columns (code-amount pairs)
            if earningsColumns.isEmpty && deductionsColumns.isEmpty {
                processRowForCodeValuePairs(rowCells: rowCells, earnings: &earnings, deductions: &deductions)
            }
        }
    }
    
    /// Processes a financial cell for code-value extraction
    private func processFinancialCell(
        cell: TableCell,
        isEarning: Bool,
        spatialTable: SpatialTableStructure,
        earnings: inout [String: Double],
        deductions: inout [String: Double]
    ) {
        let cellText = cell.mergedText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Try to extract code-value pair from the cell
        if let (code, amount) = extractCodeValuePair(from: cellText) {
            if isEarning {
                earnings[code] = amount
            } else {
                deductions[code] = amount
            }
        } else {
            // Check if this is a code in one cell that should be paired with adjacent cell
            let codePattern = "^[A-Z]{2,8}$"
            if cellText.range(of: codePattern, options: .regularExpression) != nil {
                // Look for amount in adjacent cells
                if let amount = findAdjacentAmount(for: cell, in: spatialTable) {
                    if isEarning {
                        earnings[cellText] = amount
                    } else {
                        deductions[cellText] = amount
                    }
                }
            }
        }
    }
    
    /// Processes a row for military payslip code-value pairs
    private func processRowForCodeValuePairs(
        rowCells: [TableCell],
        earnings: inout [String: Double],
        deductions: inout [String: Double]
    ) {
        for cell in rowCells {
            let cellText = cell.mergedText
            
            // Check if cell contains both code and amount
            if let (code, amount) = extractCodeValuePair(from: cellText) {
                if earningCodes.contains(code) {
                    earnings[code] = amount
                } else if deductionCodes.contains(code) {
                    deductions[code] = amount
                }
            }
        }
    }
    
    /// Finds amount in adjacent cells for a given code cell
    private func findAdjacentAmount(for cell: TableCell, in spatialTable: SpatialTableStructure) -> Double? {
        // Check cell to the right (next column)
        if let rightCell = spatialTable.cell(at: cell.row, column: cell.column + 1) {
            if let amount = Double(rightCell.mergedText.trimmingCharacters(in: .whitespacesAndNewlines)) {
                return amount
            }
        }
        
        // Check cell to the left (previous column)
        if cell.column > 0, let leftCell = spatialTable.cell(at: cell.row, column: cell.column - 1) {
            if let amount = Double(leftCell.mergedText.trimmingCharacters(in: .whitespacesAndNewlines)) {
                return amount
            }
        }
        
        return nil
    }
    
    /// Extracts code-value pairs from text
    private func extractCodeValuePair(from text: String) -> (String, Double)? {
        // Pattern for code followed by amount (e.g., "BPAY 50000.00")
        let pattern = "([A-Z]+)\\s+(\\d+(?:\\.\\d+)?)"
        
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []),
              let match = regex.firstMatch(in: text, options: [], range: NSRange(location: 0, length: text.count)),
              match.numberOfRanges >= 3 else {
            return nil
        }
        
        let nsText = text as NSString
        let code = nsText.substring(with: match.range(at: 1))
        let valueString = nsText.substring(with: match.range(at: 2))
        
        if let value = Double(valueString) {
            return (code, value)
        }
        
        return nil
    }
    
    /// Extracts financial data using PCDA-specific patterns
    private func extractPCDATabularData(from text: String, earnings: inout [String: Double], deductions: inout [String: Double]) {
        // Check for structured Credit/Debit table format (ALL payslips prior to November 2023)
        // This covers various historical formats including pre-2020, 2020-2022, and 2023 formats
        if (text.uppercased().contains("CREDIT") && text.uppercased().contains("DEBIT")) ||
           text.contains("Amount in INR") ||
           (text.contains("Basic Pay") && text.contains("DSOPF")) ||
           (text.contains("Cr.") && text.contains("Dr.")) ||  // Alternative format used in older payslips
           (text.contains("Credits") && text.contains("Debits")) ||  // Plural format
           (text.uppercased().contains("EARNINGS") && text.uppercased().contains("DEDUCTIONS")) ||  // Alternative naming
           text.contains("STATEMENT OF ACCOUNT") ||  // Common in older PCDA formats
           (text.contains("PCDA") && text.contains("TABLE")) {  // Explicit PCDA table format
            print("MilitaryFinancialDataExtractor: Detected structured Credit/Debit table format")
            let parser = PCDATableParser()
            let (parsedEarnings, parsedDeductions) = parser.extractTableData(from: text)
            earnings.merge(parsedEarnings) { _, new in new }
            deductions.merge(parsedDeductions) { _, new in new }
            return
        }
        
        // Define patterns for earnings and deductions
        // PCDA format typically has patterns like:
        // BPAY      123456.00     DSOP       12345.00
        
        // Match lines with two columns of data
        let twoColumnPattern = "([A-Z]+)\\s+(\\d+(?:\\.\\d+)?)\\s+([A-Z]+)\\s+(\\d+(?:\\.\\d+)?)"
        // Match lines with one column of data  
        let oneColumnPattern = "([A-Z]+)\\s+(\\d+(?:\\.\\d+)?)"
        
        // Process two-column data (earnings and deductions on same line)
        extractTwoColumnData(from: text, pattern: twoColumnPattern, earnings: &earnings, deductions: &deductions)
        
        // Process one-column data
        extractOneColumnData(from: text, pattern: oneColumnPattern, earnings: &earnings, deductions: &deductions)
    }


    

    
    /// Extracts data from two-column format lines
    private func extractTwoColumnData(from text: String, pattern: String, earnings: inout [String: Double], deductions: inout [String: Double]) {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else { return }
        
        let nsText = text as NSString
        let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: nsText.length))
        
        for match in matches {
            if match.numberOfRanges >= 5 {
                // First code-value pair
                let code1Range = match.range(at: 1)
                let value1Range = match.range(at: 2)
                
                // Second code-value pair
                let code2Range = match.range(at: 3)
                let value2Range = match.range(at: 4)
                
                let code1 = nsText.substring(with: code1Range)
                let code2 = nsText.substring(with: code2Range)
                
                let value1Str = nsText.substring(with: value1Range)
                let value2Str = nsText.substring(with: value2Range)
                
                // Convert values to doubles
                let value1 = Double(value1Str) ?? 0.0
                let value2 = Double(value2Str) ?? 0.0
                
                // Categorize as earnings or deductions based on known codes
                categorizeFinancialData(code: code1, value: value1, earnings: &earnings, deductions: &deductions)
                categorizeFinancialData(code: code2, value: value2, earnings: &earnings, deductions: &deductions)
            }
        }
    }
    
    /// Extracts data from single-column format lines
    private func extractOneColumnData(from text: String, pattern: String, earnings: inout [String: Double], deductions: inout [String: Double]) {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else { return }
        
        let nsText = text as NSString
        let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: nsText.length))
        
        for match in matches {
            if match.numberOfRanges >= 3 {
                let codeRange = match.range(at: 1)
                let valueRange = match.range(at: 2)
                
                let code = nsText.substring(with: codeRange)
                let valueStr = nsText.substring(with: valueRange)
                let value = Double(valueStr) ?? 0.0
                
                // Categorize as earnings or deductions based on known codes
                categorizeFinancialData(code: code, value: value, earnings: &earnings, deductions: &deductions)
            }
        }
    }
    
    /// Categorizes financial codes as earnings or deductions
    private func categorizeFinancialData(code: String, value: Double, earnings: inout [String: Double], deductions: inout [String: Double]) {
        if earningCodes.contains(code) {
            earnings[code] = value
        } else if deductionCodes.contains(code) {
            deductions[code] = value
        }
    }
    
    /// Reconciles extracted data with explicit totals found in the document
    private func reconcileTotals(from text: String, earnings: inout [String: Double], deductions: inout [String: Double]) {
        // Process total deductions
        reconcileTotalDeductions(from: text, deductions: &deductions)
        
        // Process net remittance calculations
        reconcileNetRemittance(from: text, earnings: &earnings, deductions: deductions)
        
        // Process explicit gross pay
        reconcileGrossPay(from: text, earnings: &earnings)
    }
    
    /// Reconciles total deductions with individual deduction items
    private func reconcileTotalDeductions(from text: String, deductions: inout [String: Double]) {
        let totalDeductionPatterns = [
            "Total Deductions\\s+(\\d+\\.\\d+)",
            "Gross Deductions\\s+(\\d+\\.\\d+)"
        ]
        
        for pattern in totalDeductionPatterns {
            if let totalDeductions = extractNumericValue(from: text, pattern: pattern) {
                let calculatedTotal = deductions.values.reduce(0, +)
                if abs(totalDeductions - calculatedTotal) > 1.0 && deductions.count > 0 {
                    // If there's a mismatch, add an "Other" category for the difference
                    deductions["OTHER"] = totalDeductions - calculatedTotal
                }
            }
        }
    }
    
    /// Reconciles net remittance with calculated values
    private func reconcileNetRemittance(from text: String, earnings: inout [String: Double], deductions: [String: Double]) {
        let netAmountPatterns = [
            "Net Remittance\\s+(\\d+\\.\\d+)",
            "Net Amount\\s+(\\d+\\.\\d+)",
            "Net Payable\\s+(\\d+\\.\\d+)"
        ]
        
        for pattern in netAmountPatterns {
            if let netAmount = extractNumericValue(from: text, pattern: pattern) {
                let totalDeductions = deductions.values.reduce(0, +)
                let grossPay = netAmount + totalDeductions
                
                if earnings.isEmpty {
                    earnings["GROSS PAY"] = grossPay
                } else {
                    let calculatedTotal = earnings.values.reduce(0, +)
                    if abs(grossPay - calculatedTotal) > 1.0 {
                        adjustEarningsForGrossPay(grossPay: grossPay, calculatedTotal: calculatedTotal, earnings: &earnings)
                    }
                }
                break
            }
        }
    }
    
    /// Reconciles explicit gross pay with calculated earnings
    private func reconcileGrossPay(from text: String, earnings: inout [String: Double]) {
        let grossPayPatterns = [
            "Gross Pay\\s+(\\d+\\.\\d+)",
            "Gross Earnings\\s+(\\d+\\.\\d+)",
            "Total Earnings\\s+(\\d+\\.\\d+)"
        ]
        
        for pattern in grossPayPatterns {
            if let grossPay = extractNumericValue(from: text, pattern: pattern) {
                if earnings.isEmpty {
                    earnings["GROSS PAY"] = grossPay
                } else {
                    let calculatedTotal = earnings.values.reduce(0, +)
                    if abs(grossPay - calculatedTotal) > 1.0 {
                        adjustEarningsForGrossPay(grossPay: grossPay, calculatedTotal: calculatedTotal, earnings: &earnings)
                    }
                }
                break
            }
        }
    }
    
    /// Adjusts earnings to match explicit gross pay
    private func adjustEarningsForGrossPay(grossPay: Double, calculatedTotal: Double, earnings: inout [String: Double]) {
        if calculatedTotal == 0 {
            earnings["GROSS PAY"] = grossPay
        } else if calculatedTotal < grossPay {
            // Add an "Other" category for the difference
            earnings["OTHER"] = grossPay - calculatedTotal
        } else {
            // Adjust the largest earning component to make the total match
            if let (key, value) = earnings.max(by: { $0.value < $1.value }) {
                let adjustment = grossPay - calculatedTotal
                earnings[key] = value + adjustment
            }
        }
    }
    
    /// Extracts a numeric value using a regex pattern
    private func extractNumericValue(from text: String, pattern: String) -> Double? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []),
              let match = regex.firstMatch(in: text, options: [], range: NSRange(location: 0, length: text.count)),
              match.numberOfRanges > 1 else {
            return nil
        }
        
        let range = match.range(at: 1)
        guard range.location != NSNotFound,
              let range = Range(range, in: text) else {
            return nil
        }
        
        let valueStr = String(text[range]).trimmingCharacters(in: .whitespacesAndNewlines)
        return Double(valueStr)
    }
    
} 