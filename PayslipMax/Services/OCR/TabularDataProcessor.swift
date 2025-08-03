import Foundation
import CoreGraphics

/// Advanced processor for converting structured table data into meaningful financial information
class TabularDataProcessor {
    
    // MARK: - Configuration
    private struct ProcessingConfig {
        static let minConfidenceForProcessing: Double = 0.6
        static let headerDetectionThreshold: Double = 0.8
        static let numericValueThreshold: Double = 0.7
        static let currencyPrefixes = ["₹", "Rs.", "Rs", "INR"]
        static let creditKeywords = ["CREDIT", "CREDITS", "EARNINGS", "INCOME", "PAY", "ALLOWANCE"]
        static let debitKeywords = ["DEBIT", "DEBITS", "DEDUCTIONS", "OUTGOINGS", "TAX", "CONTRIBUTION"]
    }
    
    // MARK: - Processing Pipeline
    func processTabularData(
        _ extractionResult: CellExtractionResult,
        tableStructure: DetectedTableStructure
    ) -> TabularProcessingResult {
        
        let startTime = Date()
        
        // 1. Identify table structure and headers
        let structureAnalysis = analyzeTableStructure(extractionResult.extractedCells)
        
        // 2. Detect and classify column headers
        let headerClassification = classifyColumnHeaders(structureAnalysis)
        
        // 3. Extract financial data rows
        let financialRows = extractFinancialRows(extractionResult.extractedCells, headerClassification)
        
        // 4. Process financial entries
        let processedEntries = processFinancialEntries(financialRows, headerClassification)
        
        // 5. Calculate totals and validate consistency
        let calculatedTotals = calculateTotals(processedEntries)
        
        // 6. Perform military-specific processing
        let militaryData = processMilitarySpecificData(processedEntries, structureAnalysis)
        
        let processingTime = Date().timeIntervalSince(startTime)
        
        return TabularProcessingResult(
            structureAnalysis: structureAnalysis,
            headerClassification: headerClassification,
            financialEntries: processedEntries,
            calculatedTotals: calculatedTotals,
            militaryData: militaryData,
            confidence: calculateOverallProcessingConfidence(extractionResult, processedEntries),
            metrics: TabularProcessingMetrics(
                totalCellsProcessed: extractionResult.extractedCells.flatMap { $0 }.count,
                identifiedFinancialEntries: processedEntries.count,
                processingTime: processingTime,
                structureConfidence: structureAnalysis.confidence
            )
        )
    }
    
    // MARK: - Structure Analysis
    private func analyzeTableStructure(_ cells: [[ExtractedCellData]]) -> TableStructureAnalysis {
        guard !cells.isEmpty else {
            return TableStructureAnalysis.empty
        }
        
        let rowCount = cells.count
        let columnCount = cells.first?.count ?? 0
        
        // Identify header row(s)
        let headerRows = identifyHeaderRows(cells)
        
        // Analyze column characteristics
        let columnAnalysis = analyzeColumns(cells)
        
        // Detect table regions (earnings vs deductions)
        let tableRegions = detectTableRegions(cells, columnAnalysis)
        
        return TableStructureAnalysis(
            rowCount: rowCount,
            columnCount: columnCount,
            headerRows: headerRows,
            columnAnalysis: columnAnalysis,
            tableRegions: tableRegions,
            confidence: calculateStructureConfidence(cells, headerRows, columnAnalysis)
        )
    }
    
    private func identifyHeaderRows(_ cells: [[ExtractedCellData]]) -> [Int] {
        var headerRows: [Int] = []
        
        for (rowIndex, row) in cells.enumerated() {
            let headerScore = calculateHeaderScore(row)
            
            if headerScore > ProcessingConfig.headerDetectionThreshold {
                headerRows.append(rowIndex)
            }
        }
        
        return headerRows
    }
    
    private func calculateHeaderScore(_ row: [ExtractedCellData]) -> Double {
        var score = 0.0
        
        for cell in row {
            let text = cell.processedText.uppercased()
            
            // Check for header keywords
            let hasHeaderKeywords = ProcessingConfig.creditKeywords.contains { text.contains($0) } ||
                                  ProcessingConfig.debitKeywords.contains { text.contains($0) } ||
                                  text.contains("CODE") || text.contains("DESCRIPTION") ||
                                  text.contains("AMOUNT") || text.contains("TOTAL")
            
            if hasHeaderKeywords {
                score += 0.3
            }
            
            // Check for all caps text (common in headers)
            if text == cell.processedText && text.count > 2 {
                score += 0.2
            }
            
            // Check cell type
            if cell.cellType == .header {
                score += 0.4
            }
            
            // Check for centered alignment (headers are often centered)
            if isCenteredText(cell) {
                score += 0.1
            }
        }
        
        return score / Double(max(row.count, 1))
    }
    
    private func analyzeColumns(_ cells: [[ExtractedCellData]]) -> [ColumnAnalysis] {
        guard let firstRow = cells.first else { return [] }
        
        var columnAnalyses: [ColumnAnalysis] = []
        
        for columnIndex in 0..<firstRow.count {
            let columnCells = cells.compactMap { row in
                columnIndex < row.count ? row[columnIndex] : nil
            }
            
            let analysis = analyzeColumn(columnCells, index: columnIndex)
            columnAnalyses.append(analysis)
        }
        
        return columnAnalyses
    }
    
    private func analyzeColumn(_ columnCells: [ExtractedCellData], index: Int) -> ColumnAnalysis {
        var numericCells = 0
        var textCells = 0
        var emptyCells = 0
        var totalConfidence = 0.0
        
        var detectedType: ColumnDataType = .text
        var columnPurpose: ColumnPurpose = .unknown
        
        for cell in columnCells {
            totalConfidence += Double(cell.confidence)
            
            if cell.processedText.isEmpty {
                emptyCells += 1
            } else if cell.metadata.hasNumericContent {
                numericCells += 1
            } else {
                textCells += 1
            }
        }
        
        // Determine column type
        if numericCells > columnCells.count / 2 {
            detectedType = .numeric
            columnPurpose = detectNumericColumnPurpose(columnCells)
        } else if textCells > columnCells.count / 2 {
            detectedType = .text
            columnPurpose = detectTextColumnPurpose(columnCells)
        }
        
        let averageConfidence = totalConfidence / Double(max(columnCells.count, 1))
        
        return ColumnAnalysis(
            columnIndex: index,
            dataType: detectedType,
            purpose: columnPurpose,
            confidence: averageConfidence,
            numericCellCount: numericCells,
            textCellCount: textCells,
            emptyCellCount: emptyCells,
            totalCells: columnCells.count
        )
    }
    
    // MARK: - Header Classification
    private func classifyColumnHeaders(_ structureAnalysis: TableStructureAnalysis) -> ColumnClassification {
        var creditColumns: [Int] = []
        var debitColumns: [Int] = []
        var codeColumns: [Int] = []
        var descriptionColumns: [Int] = []
        
        for columnAnalysis in structureAnalysis.columnAnalysis {
            switch columnAnalysis.purpose {
            case .earnings:
                creditColumns.append(columnAnalysis.columnIndex)
            case .deductions:
                debitColumns.append(columnAnalysis.columnIndex)
            case .payCode:
                codeColumns.append(columnAnalysis.columnIndex)
            case .description:
                descriptionColumns.append(columnAnalysis.columnIndex)
            default:
                break
            }
        }
        
        return ColumnClassification(
            creditColumns: creditColumns,
            debitColumns: debitColumns,
            codeColumns: codeColumns,
            descriptionColumns: descriptionColumns,
            confidence: calculateHeaderClassificationConfidence(structureAnalysis)
        )
    }
    
    // MARK: - Financial Data Extraction
    private func extractFinancialRows(
        _ cells: [[ExtractedCellData]],
        _ headerClassification: ColumnClassification
    ) -> [FinancialDataRow] {
        
        var financialRows: [FinancialDataRow] = []
        
        for (rowIndex, row) in cells.enumerated() {
            // Skip header rows
            if isHeaderRow(rowIndex, row) {
                continue
            }
            
            let financialRow = createFinancialDataRow(row, rowIndex, headerClassification)
            
            if financialRow.hasValidFinancialData {
                financialRows.append(financialRow)
            }
        }
        
        return financialRows
    }
    
    private func createFinancialDataRow(
        _ row: [ExtractedCellData],
        _ rowIndex: Int,
        _ headerClassification: ColumnClassification
    ) -> FinancialDataRow {
        
        var codes: [String] = []
        var descriptions: [String] = []
        var credits: [FinancialAmount] = []
        var debits: [FinancialAmount] = []
        
        for cell in row {
            let columnIndex = cell.position.column
            
            if headerClassification.codeColumns.contains(columnIndex) {
                codes.append(cell.processedText)
            } else if headerClassification.descriptionColumns.contains(columnIndex) {
                descriptions.append(cell.processedText)
            } else if headerClassification.creditColumns.contains(columnIndex) {
                if let amount = parseFinancialAmount(cell.processedText) {
                    credits.append(amount)
                }
            } else if headerClassification.debitColumns.contains(columnIndex) {
                if let amount = parseFinancialAmount(cell.processedText) {
                    debits.append(amount)
                }
            }
        }
        
        return FinancialDataRow(
            rowIndex: rowIndex,
            codes: codes,
            descriptions: descriptions,
            credits: credits,
            debits: debits,
            rawCells: row
        )
    }
    
    // MARK: - Financial Entry Processing
    private func processFinancialEntries(
        _ financialRows: [FinancialDataRow],
        _ headerClassification: ColumnClassification
    ) -> [ProcessedFinancialEntry] {
        
        return financialRows.compactMap { row in
            processFinancialRow(row, headerClassification)
        }
    }
    
    private func processFinancialRow(
        _ row: FinancialDataRow,
        _ headerClassification: ColumnClassification
    ) -> ProcessedFinancialEntry? {
        
        guard row.hasValidFinancialData else { return nil }
        
        // Extract primary code and description
        let primaryCode = row.codes.first ?? "UNKNOWN"
        let primaryDescription = row.descriptions.joined(separator: " ")
        
        // Determine entry type
        let entryType: FinancialEntryType = determineEntryType(row, primaryCode, primaryDescription)
        
        // Calculate net amount
        let creditTotal = row.credits.reduce(0.0) { $0 + $1.value }
        let debitTotal = row.debits.reduce(0.0) { $0 + $1.value }
        let netAmount = creditTotal - debitTotal
        
        // Validate entry consistency
        let validationResult = validateFinancialEntry(row, entryType)
        
        return ProcessedFinancialEntry(
            code: primaryCode,
            description: primaryDescription,
            type: entryType,
            credits: row.credits,
            debits: row.debits,
            netAmount: netAmount,
            confidence: calculateEntryConfidence(row),
            validationResult: validationResult,
            sourceRow: row.rowIndex,
            metadata: FinancialEntryMetadata(
                hasMultipleCodes: row.codes.count > 1,
                hasMultipleDescriptions: row.descriptions.count > 1,
                originalCellCount: row.rawCells.count
            )
        )
    }
    
    // MARK: - Total Calculations
    private func calculateTotals(_ entries: [ProcessedFinancialEntry]) -> CalculatedTotals {
        var earningsTotal = 0.0
        var deductionsTotal = 0.0
        var netPay = 0.0
        
        for entry in entries {
            switch entry.type {
            case .earnings, .allowance:
                earningsTotal += entry.credits.reduce(0.0) { $0 + $1.value }
            case .deduction, .tax:
                deductionsTotal += entry.debits.reduce(0.0) { $0 + $1.value }
            case .adjustment:
                netPay += entry.netAmount
            default:
                break
            }
        }
        
        netPay += earningsTotal - deductionsTotal
        
        return CalculatedTotals(
            grossEarnings: earningsTotal,
            totalDeductions: deductionsTotal,
            netPay: netPay,
            entryCount: entries.count,
            confidence: calculateTotalsConfidence(entries)
        )
    }
    
    // MARK: - Military-Specific Processing
    private func processMilitarySpecificData(
        _ entries: [ProcessedFinancialEntry],
        _ structure: TableStructureAnalysis
    ) -> MilitaryPayslipData {
        
        // Extract military-specific codes and values
        let basicPay = extractBasicPay(entries)
        let allowances = extractAllowances(entries)
        let deductions = extractDeductions(entries)
        
        // Identify service branch indicators
        let branchIndicators = identifyBranchIndicators(entries)
        
        return MilitaryPayslipData(
            basicPay: basicPay,
            allowances: allowances,
            deductions: deductions,
            branchIndicators: branchIndicators,
            confidence: calculateMilitaryDataConfidence(entries)
        )
    }
    
    // MARK: - Helper Methods
    private func parseFinancialAmount(_ text: String) -> FinancialAmount? {
        guard !text.isEmpty else { return nil }
        
        // Clean the text for numeric extraction
        var cleanText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Remove currency symbols
        for prefix in ProcessingConfig.currencyPrefixes {
            cleanText = cleanText.replacingOccurrences(of: prefix, with: "")
        }
        
        // Extract numeric value
        let numericPattern = #"[\d,]+\.?\d*"#
        guard let regex = try? NSRegularExpression(pattern: numericPattern),
              let match = regex.firstMatch(in: cleanText, range: NSRange(cleanText.startIndex..., in: cleanText)),
              let range = Range(match.range, in: cleanText) else {
            return nil
        }
        
        let numericString = String(cleanText[range]).replacingOccurrences(of: ",", with: "")
        
        guard let value = Double(numericString), value > 0 else { return nil }
        
        return FinancialAmount(
            value: value,
            currency: detectCurrency(text),
            originalText: text
        )
    }
    
    private func detectCurrency(_ text: String) -> Currency {
        for prefix in ProcessingConfig.currencyPrefixes {
            if text.contains(prefix) {
                return .inr
            }
        }
        return .inr // Default to INR for military payslips
    }
    
    private func determineEntryType(
        _ row: FinancialDataRow,
        _ code: String,
        _ description: String
    ) -> FinancialEntryType {
        
        let combinedText = (code + " " + description).uppercased()
        
        // Check for specific military codes
        if code.starts(with: "BP") || combinedText.contains("BASIC PAY") {
            return .earnings
        }
        
        if combinedText.contains("ALLOWANCE") || combinedText.contains("DA") {
            return .allowance
        }
        
        if combinedText.contains("TAX") || combinedText.contains("INCOME TAX") {
            return .tax
        }
        
        if combinedText.contains("DEDUCTION") || combinedText.contains("RECOVERY") {
            return .deduction
        }
        
        // Default based on presence of credits vs debits
        if !row.credits.isEmpty && row.debits.isEmpty {
            return .earnings
        } else if row.credits.isEmpty && !row.debits.isEmpty {
            return .deduction
        }
        
        return .other
    }
    
    private func detectNumericColumnPurpose(_ cells: [ExtractedCellData]) -> ColumnPurpose {
        // Analyze the position and context to determine purpose
        return .amount
    }
    
    private func detectTextColumnPurpose(_ cells: [ExtractedCellData]) -> ColumnPurpose {
        // Check for common patterns in text columns
        let combinedText = cells.map { $0.processedText.uppercased() }.joined(separator: " ")
        
        if combinedText.contains("CODE") || cells.allSatisfy({ $0.processedText.count <= 6 }) {
            return .payCode
        }
        
        return .description
    }
    
    private func detectTableRegions(_ cells: [[ExtractedCellData]], _ columnAnalysis: [ColumnAnalysis]) -> [TableRegion] {
        // Simplified region detection
        return []
    }
    
    private func calculateStructureConfidence(
        _ cells: [[ExtractedCellData]],
        _ headerRows: [Int],
        _ columnAnalysis: [ColumnAnalysis]
    ) -> Double {
        
        let cellConfidence = cells.flatMap { $0 }.reduce(0.0) { sum, cell in
            sum + Double(cell.confidence)
        } / Double(max(cells.flatMap { $0 }.count, 1))
        
        let structureScore = headerRows.isEmpty ? 0.5 : 0.9
        
        return (cellConfidence + structureScore) / 2.0
    }
    
    private func calculateHeaderClassificationConfidence(_ structure: TableStructureAnalysis) -> Double {
        return structure.confidence
    }
    
    private func isHeaderRow(_ rowIndex: Int, _ row: [ExtractedCellData]) -> Bool {
        return calculateHeaderScore(row) > ProcessingConfig.headerDetectionThreshold
    }
    
    private func isCenteredText(_ cell: ExtractedCellData) -> Bool {
        // Simplified centering detection
        return false
    }
    
    private func calculateEntryConfidence(_ row: FinancialDataRow) -> Double {
        let cellConfidences = row.rawCells.map { Double($0.confidence) }
        return cellConfidences.reduce(0.0, +) / Double(max(cellConfidences.count, 1))
    }
    
    private func validateFinancialEntry(
        _ row: FinancialDataRow,
        _ type: FinancialEntryType
    ) -> FinancialValidationResult {
        // Simplified validation
        return FinancialValidationResult(isValid: true, issues: [])
    }
    
    private func calculateOverallProcessingConfidence(
        _ extraction: CellExtractionResult,
        _ entries: [ProcessedFinancialEntry]
    ) -> Double {
        
        let extractionConfidence = extraction.overallConfidence
        let entriesConfidence = entries.isEmpty ? 0.0 : entries.reduce(0.0) { sum, entry in
            sum + entry.confidence
        } / Double(entries.count)
        
        return (extractionConfidence + entriesConfidence) / 2.0
    }
    
    private func calculateTotalsConfidence(_ entries: [ProcessedFinancialEntry]) -> Double {
        return entries.reduce(0.0) { sum, entry in sum + entry.confidence } / Double(max(entries.count, 1))
    }
    
    private func extractBasicPay(_ entries: [ProcessedFinancialEntry]) -> FinancialAmount? {
        return entries.first { entry in
            entry.code.uppercased().contains("BP") || entry.description.uppercased().contains("BASIC PAY")
        }?.credits.first
    }
    
    private func extractAllowances(_ entries: [ProcessedFinancialEntry]) -> [ProcessedFinancialEntry] {
        return entries.filter { $0.type == .allowance }
    }
    
    private func extractDeductions(_ entries: [ProcessedFinancialEntry]) -> [ProcessedFinancialEntry] {
        return entries.filter { $0.type == .deduction || $0.type == .tax }
    }
    
    private func identifyBranchIndicators(_ entries: [ProcessedFinancialEntry]) -> [String] {
        // Extract military branch indicators from codes and descriptions
        return []
    }
    
    private func calculateMilitaryDataConfidence(_ entries: [ProcessedFinancialEntry]) -> Double {
        return calculateTotalsConfidence(entries)
    }
}

// MARK: - Supporting Data Structures
struct TabularProcessingResult {
    let structureAnalysis: TableStructureAnalysis
    let headerClassification: ColumnClassification
    let financialEntries: [ProcessedFinancialEntry]
    let calculatedTotals: CalculatedTotals
    let militaryData: MilitaryPayslipData
    let confidence: Double
    let metrics: TabularProcessingMetrics
}

struct TableStructureAnalysis {
    let rowCount: Int
    let columnCount: Int
    let headerRows: [Int]
    let columnAnalysis: [ColumnAnalysis]
    let tableRegions: [TableRegion]
    let confidence: Double
    
    static let empty = TableStructureAnalysis(
        rowCount: 0,
        columnCount: 0,
        headerRows: [],
        columnAnalysis: [],
        tableRegions: [],
        confidence: 0.0
    )
}

struct ColumnAnalysis {
    let columnIndex: Int
    let dataType: ColumnDataType
    let purpose: ColumnPurpose
    let confidence: Double
    let numericCellCount: Int
    let textCellCount: Int
    let emptyCellCount: Int
    let totalCells: Int
}

enum ColumnDataType {
    case text
    case numeric
    case mixed
    case empty
}

enum ColumnPurpose {
    case payCode
    case description
    case amount
    case earnings
    case deductions
    case unknown
}

struct ColumnClassification {
    let creditColumns: [Int]
    let debitColumns: [Int]
    let codeColumns: [Int]
    let descriptionColumns: [Int]
    let confidence: Double
}

struct FinancialDataRow {
    let rowIndex: Int
    let codes: [String]
    let descriptions: [String]
    let credits: [FinancialAmount]
    let debits: [FinancialAmount]
    let rawCells: [ExtractedCellData]
    
    var hasValidFinancialData: Bool {
        return !codes.isEmpty || !credits.isEmpty || !debits.isEmpty
    }
}

struct ProcessedFinancialEntry {
    let code: String
    let description: String
    let type: FinancialEntryType
    let credits: [FinancialAmount]
    let debits: [FinancialAmount]
    let netAmount: Double
    let confidence: Double
    let validationResult: FinancialValidationResult
    let sourceRow: Int
    let metadata: FinancialEntryMetadata
}

enum FinancialEntryType {
    case earnings
    case allowance
    case deduction
    case tax
    case adjustment
    case other
}

struct FinancialAmount {
    let value: Double
    let currency: Currency
    let originalText: String
}

enum Currency: Equatable {
    case inr
    case usd
    case other(String)
}

struct FinancialValidationResult {
    let isValid: Bool
    let issues: [String]
}

struct FinancialEntryMetadata {
    let hasMultipleCodes: Bool
    let hasMultipleDescriptions: Bool
    let originalCellCount: Int
}

struct CalculatedTotals {
    let grossEarnings: Double
    let totalDeductions: Double
    let netPay: Double
    let entryCount: Int
    let confidence: Double
}

struct MilitaryPayslipData {
    let basicPay: FinancialAmount?
    let allowances: [ProcessedFinancialEntry]
    let deductions: [ProcessedFinancialEntry]
    let branchIndicators: [String]
    let confidence: Double
}

struct TabularProcessingMetrics {
    let totalCellsProcessed: Int
    let identifiedFinancialEntries: Int
    let processingTime: TimeInterval
    let structureConfidence: Double
}