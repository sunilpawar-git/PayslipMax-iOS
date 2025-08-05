import Foundation
import CoreGraphics

/// Simplified PCDA (Principal Controller of Defence Accounts) table parser
/// Uses spatial analysis instead of complex regex patterns for better accuracy
/// Supports all historical PCDA formats with enhanced table detection
public protocol SimplifiedPCDATableParserProtocol {
    func extractTableData(from textElements: [TextElement]) -> ([String: Double], [String: Double])
    func extractTableData(from text: String) -> ([String: Double], [String: Double])
}

public class SimplifiedPCDATableParser: SimplifiedPCDATableParserProtocol {
    
    // MARK: - Dependencies
    
    private let tableDetector: SimpleTableDetectorProtocol
    private let spatialAnalyzer: SpatialTextAnalyzerProtocol
    
    // MARK: - Configuration
    
    private static let earningCodes = Set([
        "BPAY", "DA", "DP", "HRA", "TA", "MISC", "CEA", "TPT", 
        "WASHIA", "OUTFITA", "MSP", "ARR-RSHNA", "RSHNA", 
        "RH12", "TPTA", "TPTADA", "BASIC", "PAY"
    ])
    
    private static let deductionCodes = Set([
        "DSOP", "DSOPF", "AGIF", "ITAX", "IT", "SBI", "PLI", "AFNB", 
        "AOBA", "PLIA", "HOSP", "CDA", "CGEIS", "DEDN", "INCM", "TAX",
        "EDUC", "CESS", "BARRACK", "DAMAGE"
    ])
    
    private static let headerPatterns = [
        "CREDIT", "DEBIT", "CR.", "DR.", "EARNINGS", "DEDUCTIONS", "CREDITS", "DEBITS"
    ]
    
    // MARK: - Initialization
    
    public init(
        tableDetector: SimpleTableDetectorProtocol = SimpleTableDetector(),
        spatialAnalyzer: SpatialTextAnalyzerProtocol = SpatialTextAnalyzer()
    ) {
        self.tableDetector = tableDetector
        self.spatialAnalyzer = spatialAnalyzer
    }
    
    // MARK: - Public Methods
    
    public func extractTableData(from textElements: [TextElement]) -> ([String: Double], [String: Double]) {
        print("SimplifiedPCDATableParser: Processing \(textElements.count) text elements")
        
        // First, try spatial table analysis
        if let spatialResult = extractUsingSpatialAnalysis(textElements: textElements) {
            print("SimplifiedPCDATableParser: Spatial analysis successful")
            return spatialResult
        }
        
        // Fallback to text-based analysis
        let combinedText = textElements.map { $0.text }.joined(separator: " ")
        return extractTableData(from: combinedText)
    }
    
    public func extractTableData(from text: String) -> ([String: Double], [String: Double]) {
        print("SimplifiedPCDATableParser: Processing text-based PCDA format")
        
        var earnings: [String: Double] = [:]
        var deductions: [String: Double] = [:]
        
        // Detect PCDA table structure
        guard isPCDAFormat(text) else {
            print("SimplifiedPCDATableParser: Not a PCDA format")
            return (earnings, deductions)
        }
        
        // Extract using simplified patterns
        extractFromSimplifiedPatterns(
            text: text,
            earnings: &earnings,
            deductions: &deductions
        )
        
        return (earnings, deductions)
    }
    
    // MARK: - Private Methods
    
    private func extractUsingSpatialAnalysis(textElements: [TextElement]) -> ([String: Double], [String: Double])? {
        // Detect table structure
        guard let tableStructure = tableDetector.detectTableStructure(from: textElements) else {
            print("SimplifiedPCDATableParser: No table structure detected")
            return nil
        }
        
        // Create spatial table structure
        guard let spatialTable = spatialAnalyzer.associateTextWithCells(
            textElements: textElements,
            tableStructure: tableStructure
        ) else {
            print("SimplifiedPCDATableParser: Failed to create spatial table")
            return nil
        }
        
        print("SimplifiedPCDATableParser: Created spatial table with \(spatialTable.rowCount) rows, \(spatialTable.columnCount) columns")
        
        var earnings: [String: Double] = [:]
        var deductions: [String: Double] = [:]
        
        // Identify PCDA-specific column patterns
        let (creditColumns, debitColumns) = identifyPCDAColumns(spatialTable)
        
        if !creditColumns.isEmpty || !debitColumns.isEmpty {
            extractFromPCDAColumns(
                spatialTable: spatialTable,
                creditColumns: creditColumns,
                debitColumns: debitColumns,
                earnings: &earnings,
                deductions: &deductions
            )
        }
        
        return earnings.isEmpty && deductions.isEmpty ? nil : (earnings, deductions)
    }
    
    private func identifyPCDAColumns(_ spatialTable: SpatialTableStructure) -> ([Int], [Int]) {
        var creditColumns: [Int] = []
        var debitColumns: [Int] = []
        
        // Check headers first
        if let headers = spatialTable.headers {
            for (index, header) in headers.enumerated() {
                let headerUpper = header.uppercased()
                if headerUpper.contains("CREDIT") || headerUpper.contains("CR.") || 
                   headerUpper.contains("EARNINGS") {
                    creditColumns.append(index)
                } else if headerUpper.contains("DEBIT") || headerUpper.contains("DR.") || 
                         headerUpper.contains("DEDUCTIONS") {
                    debitColumns.append(index)
                }
            }
        }
        
        // If no headers found, analyze content patterns
        if creditColumns.isEmpty && debitColumns.isEmpty {
            for columnIndex in 0..<spatialTable.columnCount {
                let columnCells = spatialTable.cellsInColumn(columnIndex)
                
                let hasEarningCodes = columnCells.contains { cell in
                    Self.earningCodes.contains { code in
                        cell.mergedText.uppercased().contains(code)
                    }
                }
                
                let hasDeductionCodes = columnCells.contains { cell in
                    Self.deductionCodes.contains { code in
                        cell.mergedText.uppercased().contains(code)
                    }
                }
                
                if hasEarningCodes {
                    creditColumns.append(columnIndex)
                } else if hasDeductionCodes {
                    debitColumns.append(columnIndex)
                }
            }
        }
        
        print("SimplifiedPCDATableParser: Credit columns: \(creditColumns), Debit columns: \(debitColumns)")
        return (creditColumns, debitColumns)
    }
    
    private func extractFromPCDAColumns(
        spatialTable: SpatialTableStructure,
        creditColumns: [Int],
        debitColumns: [Int],
        earnings: inout [String: Double],
        deductions: inout [String: Double]
    ) {
        let startRow = spatialTable.headers != nil ? 1 : 0
        
        for rowIndex in startRow..<spatialTable.rowCount {
            // Process both credit and debit columns
            for columnIndex in creditColumns {
                if let cell = spatialTable.cell(at: rowIndex, column: columnIndex) {
                    let extractedData = extractPCDAData(from: cell.mergedText)
                    for (code, amount) in extractedData { earnings[code] = amount }
                }
            }
            
            for columnIndex in debitColumns {
                if let cell = spatialTable.cell(at: rowIndex, column: columnIndex) {
                    let extractedData = extractPCDAData(from: cell.mergedText)
                    for (code, amount) in extractedData { deductions[code] = amount }
                }
            }
        }
    }
    
    private func extractPCDAData(from text: String) -> [(String, Double)] {
        let words = text.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
        
        // Check if this follows "multiple codes with single amount at end" pattern
        // E.g., "BPAY DA MSP 60000" where all but last are codes and last is amount
        if let lastWord = words.last, let amount = Double(lastWord) {
            let allButLast = Array(words.dropLast())
            let codes = allButLast.filter { $0.range(of: "^[A-Za-z]+$", options: .regularExpression) != nil }
            
            // If all words before the amount are codes, this is the "multiple codes, single amount" pattern
            if codes.count == allButLast.count && codes.count > 1 {
                let amountPerCode = amount / Double(codes.count)
                return codes.map { ($0, amountPerCode) }
            }
        }
        
        // Try regex for individual code-amount pairs like "BPAY 30000 DA 10000" or "Salary 40000 Tax 3000"
        let pairPattern = "([A-Za-z]+)\\s+(\\d+(?:\\.\\d+)?)"
        if let regex = try? NSRegularExpression(pattern: pairPattern, options: []) {
            let matches = regex.matches(in: text, options: [], range: NSRange(0..<text.count))
            let pairs = matches.compactMap { match -> (String, Double)? in
                guard match.numberOfRanges >= 3 else { return nil }
                let nsText = text as NSString
                let code = nsText.substring(with: match.range(at: 1))
                let amountStr = nsText.substring(with: match.range(at: 2))
                return Double(amountStr).map { (code, $0) }
            }
            
            if !pairs.isEmpty {
                return pairs
            }
        }
        
        // Single code with single amount at end
        if let lastWord = words.last, let amount = Double(lastWord), words.count == 2 {
            let code = words[0]
            if code.range(of: "^[A-Za-z]+$", options: .regularExpression) != nil {
                return [(code, amount)]
            }
        }
        
        return []
    }
    
    private func isPCDAFormat(_ text: String) -> Bool {
        let upperText = text.uppercased()
        return Self.headerPatterns.contains { upperText.contains($0) } || 
               upperText.contains("PCDA") || upperText.contains("PRINCIPAL CONTROLLER")
    }
    
    private func extractFromSimplifiedPatterns(
        text: String,
        earnings: inout [String: Double],
        deductions: inout [String: Double]
    ) {
        text.components(separatedBy: .newlines)
            .compactMap { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .forEach { line in
                extractPCDAData(from: line).forEach { (code, amount) in
                    let upperCode = code.uppercased()
                    
                    // Check exact match first, then partial matches
                    if Self.earningCodes.contains(upperCode) {
                        earnings[code] = amount
                    } else if Self.deductionCodes.contains(upperCode) {
                        deductions[code] = amount
                    } else if Self.earningCodes.contains(where: { $0.contains(upperCode) || upperCode.contains($0) }) {
                        earnings[code] = amount
                    } else if Self.deductionCodes.contains(where: { $0.contains(upperCode) || upperCode.contains($0) }) {
                        deductions[code] = amount
                    } else {
                        // For generic terms, classify based on common patterns
                        if isLikelyEarning(upperCode) {
                            earnings[code] = amount
                        } else if isLikelyDeduction(upperCode) {
                            deductions[code] = amount
                        } else {
                            // Default to earnings for unclassified items
                            earnings[code] = amount
                        }
                    }
                }
            }
    }
    
    private func isLikelyEarning(_ code: String) -> Bool {
        let earningPatterns = ["SALARY", "BASIC", "PAY", "ALLOWANCE", "BONUS", "WAGE"]
        return earningPatterns.contains { code.contains($0) }
    }
    
    private func isLikelyDeduction(_ code: String) -> Bool {
        let deductionPatterns = ["TAX", "DEDUCTION", "RECOVERY", "LOAN", "INSURANCE", "FUND"]
        return deductionPatterns.contains { code.contains($0) }
    }
}