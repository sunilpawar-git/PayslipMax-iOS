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
    private let pcdaParser: SimplifiedPCDATableParserProtocol
    private let pcdaValidator: PCDAFinancialValidatorProtocol
    
    // MARK: - Initialization
    
    init(tableDetector: SimpleTableDetectorProtocol = SimpleTableDetector(),
         spatialAnalyzer: SpatialTextAnalyzerProtocol = SpatialTextAnalyzer(),
         pcdaParser: SimplifiedPCDATableParserProtocol = SimplifiedPCDATableParser(),
         pcdaValidator: PCDAFinancialValidatorProtocol = PCDAFinancialValidator()) {
        self.tableDetector = tableDetector
        self.spatialAnalyzer = spatialAnalyzer
        self.pcdaParser = pcdaParser
        self.pcdaValidator = pcdaValidator
    }
    
    // MARK: - Constants
    
    /// Known earning codes in military payslips (enhanced for PCDA format)
    private let earningCodes = Set([
        "BPAY", "DA", "DP", "HRA", "TA", "MISC", "CEA", "TPT", 
        "WASHIA", "OUTFITA", "MSP", "ARR-RSHNA", "RSHNA", 
        "RH12", "TPTA", "TPTADA", "BASIC", "PAY", "A/O", "TRAN", "ALLC",
        "TPTIN", "L", "FEE", "FUR", "FURNITURE", "LICENSE"
    ])
    
    /// Known deduction codes in military payslips (enhanced for PCDA format)
    private let deductionCodes = Set([
        "DSOP", "DSOPF", "AGIF", "ITAX", "IT", "SBI", "PLI", "AFNB", 
        "AOBA", "PLIA", "HOSP", "CDA", "CGEIS", "DEDN", "INCM", "TAX",
        "EDUC", "CESS", "BARRACK", "DAMAGE", "R/O", "ELKT", "L", "FEE", "FUR",
        "SUBN", "FUND", "RECOVERY"
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
        
        #if DEBUG
        print("MilitaryFinancialDataExtractor: Starting tabular data extraction from \(text.count) characters")
        #endif
        
        // Check for PCDA format
        if text.contains("PCDA") || text.contains("Principal Controller of Defence Accounts") || text.contains("PRINCIPAL CONTROLLER OF DEFENCE ACCOUNTS") {
            #if DEBUG
            print("MilitaryFinancialDataExtractor: Detected PCDA format for tabular data extraction")
            #endif
            
            // Extract using PCDA patterns
            extractPCDATabularData(from: text, earnings: &earnings, deductions: &deductions)
            
            // Process total reconciliation
            reconcileTotals(from: text, earnings: &earnings, deductions: &deductions)
        } else {
            print("MilitaryFinancialDataExtractor: PCDA format not detected in text")
            print("MilitaryFinancialDataExtractor: Text preview: \(String(text.prefix(200)))")
        }
        
        #if DEBUG
        print("MilitaryFinancialDataExtractor: Final result - earnings: \(earnings.count), deductions: \(deductions.count)")
        #endif
        return (earnings, deductions)
    }
    
    /// Enhanced extraction method using table structure detection - Phase 6.3 Integration
    ///
    /// This method implements the complete Phase 6.3 pipeline with PCDA table structure detection,
    /// spatial cell association, row-wise processing, and financial validation.
    /// Falls back to text-based extraction if any step fails.
    ///
    /// - Parameter textElements: Array of text elements with spatial positioning
    /// - Returns: A tuple containing earnings and deductions dictionaries
    func extractMilitaryTabularData(from textElements: [TextElement]?) -> ([String: Double], [String: Double]) {
        guard let textElements = textElements, !textElements.isEmpty else {
            print("MilitaryFinancialDataExtractor: No text elements provided, cannot perform spatial analysis")
            return ([:], [:])
        }
        
        print("MilitaryFinancialDataExtractor: Starting Phase 6.3 spatial table analysis with \(textElements.count) text elements")
        
        // Phase 6.3 Step 1: Detect PCDA table structure specifically
        guard let pcdaTable = tableDetector.detectPCDATableStructure(from: textElements) else {
            print("MilitaryFinancialDataExtractor: No PCDA table structure detected, trying general table detection")
            return fallbackToGeneralTableDetection(textElements: textElements)
        }
        
        print("MilitaryFinancialDataExtractor: PCDA table structure detected with \(pcdaTable.dataRowCount) data rows")
        
        // Phase 6.3 Step 2: Associate text with cells spatially
        guard let spatialTable = spatialAnalyzer.associateTextWithPCDACells(
            textElements: textElements, 
            pcdaStructure: pcdaTable
        ) else {
            print("MilitaryFinancialDataExtractor: Failed to create PCDA spatial table structure")
            return fallbackToGeneralTableDetection(textElements: textElements)
        }
        
        print("MilitaryFinancialDataExtractor: Created PCDA spatial table with \(spatialTable.dataRows.count) data rows")
        
        // Phase 6.3 Step 3: Process each row for credit/debit pairs
        var allCredits: [String: Double] = [:]
        var allDebits: [String: Double] = [:]
        
        for row in spatialTable.dataRows {
            // Extract credit data from the row
            if let creditDesc = row.creditDescription?.mergedText,
               let creditAmountText = row.creditAmount?.mergedText,
               let creditAmount = Double(creditAmountText) {
                let cleanDescription = cleanMilitaryDescription(creditDesc)
                if creditAmount > 0 {
                    allCredits[cleanDescription] = creditAmount
                    print("MilitaryFinancialDataExtractor: Extracted credit - \(cleanDescription): \(creditAmount)")
                }
            }
            
            // Extract debit data from the row
            if let debitDesc = row.debitDescription?.mergedText,
               let debitAmountText = row.debitAmount?.mergedText,
               let debitAmount = Double(debitAmountText) {
                let cleanDescription = cleanMilitaryDescription(debitDesc)
                if debitAmount > 0 {
                    allDebits[cleanDescription] = debitAmount
                    print("MilitaryFinancialDataExtractor: Extracted debit - \(cleanDescription): \(debitAmount)")
                }
            }
        }
        
        print("MilitaryFinancialDataExtractor: Processed PCDA rows - credits: \(allCredits.count), debits: \(allDebits.count)")
        
        // Phase 6.3 Step 4: Validate extraction using PCDA financial rules
        let validation = pcdaValidator.validatePCDAExtraction(credits: allCredits, debits: allDebits, remittance: nil)
        
        if validation.isValid {
            print("MilitaryFinancialDataExtractor: PCDA validation PASSED - extraction successful")
            return (allCredits, allDebits)
        } else {
            print("MilitaryFinancialDataExtractor: PCDA validation FAILED: \(validation.message ?? "Unknown error")")
            return fallbackTextBasedExtraction(textElements: textElements)
        }
    }
    
    /// Fallback to general table detection when PCDA-specific detection fails
    private func fallbackToGeneralTableDetection(textElements: [TextElement]) -> ([String: Double], [String: Double]) {
        print("MilitaryFinancialDataExtractor: Attempting general table structure detection")
        
        // Attempt general table structure detection
        if let tableStructure = tableDetector.detectTableStructure(from: textElements) {
            print("MilitaryFinancialDataExtractor: General table structure detected - \(tableStructure.rows.count) rows, \(tableStructure.columns.count) columns")
            
            let (earnings, deductions) = extractFromTableStructure(tableStructure: tableStructure, textElements: textElements)
            
            // Validate that we extracted meaningful data
            if !earnings.isEmpty || !deductions.isEmpty {
                print("MilitaryFinancialDataExtractor: General spatial extraction successful - earnings: \(earnings.count), deductions: \(deductions.count)")
                return (earnings, deductions)
            } else {
                print("MilitaryFinancialDataExtractor: General spatial extraction yielded no results")
            }
        } else {
            print("MilitaryFinancialDataExtractor: No general table structure detected")
        }
        
        // Try simplified PCDA parser with text elements as final spatial attempt
        print("MilitaryFinancialDataExtractor: Trying simplified PCDA parser with spatial text elements")
        let (pcdaEarnings, pcdaDeductions) = pcdaParser.extractTableData(from: textElements)
        
        if !pcdaEarnings.isEmpty || !pcdaDeductions.isEmpty {
            print("MilitaryFinancialDataExtractor: PCDA spatial parser successful - earnings: \(pcdaEarnings.count), deductions: \(pcdaDeductions.count)")
            return (pcdaEarnings, pcdaDeductions)
        }
        
        // Final fallback to text-based extraction
        return fallbackTextBasedExtraction(textElements: textElements)
    }
    
    /// Fallback text-based extraction when all spatial methods fail
    private func fallbackTextBasedExtraction(textElements: [TextElement]) -> ([String: Double], [String: Double]) {
        print("MilitaryFinancialDataExtractor: All spatial methods failed, using fallback text-based extraction")
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
        // First try to extract using CREDIT SIDE/DEBIT SIDE format
        if text.contains("CREDIT SIDE:") && text.contains("DEBIT SIDE:") {
            print("MilitaryFinancialDataExtractor: Detected CREDIT SIDE/DEBIT SIDE format")
            extractFromCreditDebitSections(from: text, earnings: &earnings, deductions: &deductions)
            
            // If we got results, return
            if !earnings.isEmpty || !deductions.isEmpty {
                print("MilitaryFinancialDataExtractor: CREDIT SIDE/DEBIT SIDE extraction successful - earnings: \(earnings.count), deductions: \(deductions.count)")
                return
            }
        }
        
        // Use simplified PCDA parser with enhanced spatial analysis
        print("MilitaryFinancialDataExtractor: Trying simplified PCDA parser")
        let (pcdaEarnings, pcdaDeductions) = pcdaParser.extractTableData(from: text)
        
        if !pcdaEarnings.isEmpty || !pcdaDeductions.isEmpty {
            print("MilitaryFinancialDataExtractor: Simplified PCDA parser successful - earnings: \(pcdaEarnings.count), deductions: \(pcdaDeductions.count)")
            earnings.merge(pcdaEarnings) { _, new in new }
            deductions.merge(pcdaDeductions) { _, new in new }
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
    
    /// Extracts data from CREDIT SIDE/DEBIT SIDE format
    private func extractFromCreditDebitSections(from text: String, earnings: inout [String: Double], deductions: inout [String: Double]) {
        let lines = text.components(separatedBy: .newlines)
        var inCreditSection = false
        var inDebitSection = false
        
        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Check for section headers
            if trimmedLine.contains("CREDIT SIDE:") {
                inCreditSection = true
                inDebitSection = false
                continue
            } else if trimmedLine.contains("DEBIT SIDE:") {
                inCreditSection = false
                inDebitSection = true
                continue
            } else if trimmedLine.contains("Total") || trimmedLine.contains("Net") {
                // Stop processing at totals
                inCreditSection = false
                inDebitSection = false
                continue
            }
            
            // Skip empty lines and headers
            if trimmedLine.isEmpty || trimmedLine.contains("PRINCIPAL CONTROLLER") || trimmedLine.contains("Statement of Account") {
                continue
            }
            
            // Extract amount and description from line
            if let (description, amount) = extractDescriptionAndAmount(from: trimmedLine) {
                if inCreditSection {
                    earnings[description] = amount
                    print("MilitaryFinancialDataExtractor: Found credit - \(description): \(amount)")
                } else if inDebitSection {
                    deductions[description] = amount
                    print("MilitaryFinancialDataExtractor: Found debit - \(description): \(amount)")
                }
            }
        }
    }
    
    /// Extracts description and amount from a line
    private func extractDescriptionAndAmount(from line: String) -> (String, Double)? {
        // Pattern for "Description Amount" format
        // e.g., "Basic Pay 136400" or "Transport Allowance 5256"
        let components = line.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
        
        // Look for the last numeric component
        guard let lastComponent = components.last,
              let amount = Double(lastComponent) else {
            return nil
        }
        
        // Join all components except the last one as the description
        let descriptionComponents = Array(components.dropLast())
        guard !descriptionComponents.isEmpty else {
            return nil
        }
        
        let description = descriptionComponents.joined(separator: " ")
        return (description, amount)
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
    
    // MARK: - Enhanced PCDA Integration Methods (Phase 6.2)
    
    /// Enhanced extraction method with integrated PCDA processing and validation
    /// Implements the complete Phase 6.2 pipeline with spatial analysis and financial validation
    func extractMilitaryTabularDataWithValidation(from textElements: [TextElement]) -> (credits: [String: Double], debits: [String: Double], validation: PCDAValidationResult) {
        // Step 1: Detect PCDA table structure
        guard let pcdaStructure = tableDetector.detectPCDATableStructure(from: textElements) else {
            print("MilitaryFinancialDataExtractor: No PCDA table structure detected, falling back to general extraction")
            let (earnings, deductions) = extractMilitaryTabularData(from: textElements)
            let validation = pcdaValidator.validatePCDAExtraction(credits: earnings, debits: deductions, remittance: nil)
            return (earnings, deductions, validation)
        }
        
        print("MilitaryFinancialDataExtractor: PCDA table structure detected with \(pcdaStructure.dataRowCount) data rows")
        
        // Step 2: Associate text with cells spatially
        guard let pcdaSpatialTable = spatialAnalyzer.associateTextWithPCDACells(
            textElements: textElements,
            pcdaStructure: pcdaStructure
        ) else {
            print("MilitaryFinancialDataExtractor: Failed to create PCDA spatial table")
            let (earnings, deductions) = extractMilitaryTabularData(from: textElements)
            let validation = pcdaValidator.validatePCDAExtraction(credits: earnings, debits: deductions, remittance: nil)
            return (earnings, deductions, validation)
        }
        
        // Step 3: Process each row for credit/debit pairs
        var allCredits: [String: Double] = [:]
        var allDebits: [String: Double] = [:]
        
        for pcdaRow in pcdaSpatialTable.dataRows {
            if let creditData = pcdaRow.getCreditData() {
                let cleanDescription = cleanMilitaryDescription(creditData.description)
                if let amount = creditData.amount, amount > 0 {
                    allCredits[cleanDescription] = amount
                    print("MilitaryFinancialDataExtractor: Extracted credit - \(cleanDescription): \(amount)")
                }
            }
            
            if let debitData = pcdaRow.getDebitData() {
                let cleanDescription = cleanMilitaryDescription(debitData.description)
                if let amount = debitData.amount, amount > 0 {
                    allDebits[cleanDescription] = amount
                    print("MilitaryFinancialDataExtractor: Extracted debit - \(cleanDescription): \(amount)")
                }
            }
        }
        
        // Step 4: Validate extraction using PCDA rules
        let validation = pcdaValidator.validatePCDAExtraction(
            credits: allCredits,
            debits: allDebits,
            remittance: nil // Could be extracted separately if available
        )
        
        print("MilitaryFinancialDataExtractor: PCDA validation result: \(validation.isValid ? "PASSED" : "FAILED")")
        if let message = validation.message {
            print("MilitaryFinancialDataExtractor: Validation message: \(message)")
        }
        
        // Step 5: Handle validation failure with fallback
        if !validation.isValid {
            print("MilitaryFinancialDataExtractor: PCDA validation failed, attempting fallback extraction")
            let (fallbackEarnings, fallbackDeductions) = fallbackTextBasedExtraction(textElements: textElements)
            
            // Re-validate fallback results
            let fallbackValidation = pcdaValidator.validatePCDAExtraction(
                credits: fallbackEarnings,
                debits: fallbackDeductions,
                remittance: nil
            )
            
            // Use fallback if it validates better
            if fallbackValidation.isValid && !validation.isValid {
                return (fallbackEarnings, fallbackDeductions, fallbackValidation)
            }
        }
        
        return (allCredits, allDebits, validation)
    }
    
    /// Cleans military description text for standardization
    private func cleanMilitaryDescription(_ description: String) -> String {
        return description
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "  ", with: " ")
            .uppercased()
    }
    
    
} 