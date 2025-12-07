// swiftlint:disable no_hardcoded_strings
import Foundation
import CoreGraphics

/// Handles extraction of tabular data structures from payslip text.
///
/// This component focuses on parsing structured tabular data within payslips,
/// particularly for financial information laid out in table format. It was
/// extracted from PatternMatcher to achieve better separation of concerns
/// and comply with the 300-line limit rule.
///
/// ## Single Responsibility
/// The TabularDataExtractor has one clear responsibility: parsing text that
/// contains structured tabular data and extracting financial values organized
/// by earnings and deductions categories.
///
/// ## Extraction Strategy
/// The class recognizes common tabular patterns in payslip documents:
/// - Code-value pairs arranged in columns
/// - Formatted currency amounts
/// - Categorization into earnings vs deductions
/// - **NEW**: Spatial analysis for complex table structures
class TabularDataExtractor: TabularDataExtractorProtocol {

    // MARK: - Properties

    /// Spatial analyzer for understanding table structure
    private let spatialAnalyzer: SpatialAnalyzerProtocol?

    // MARK: - Initialization

    /// Initializes the tabular data extractor
    /// - Parameter spatialAnalyzer: Optional spatial analyzer for enhanced table processing
    init(spatialAnalyzer: SpatialAnalyzerProtocol? = nil) {
        self.spatialAnalyzer = spatialAnalyzer
    }

    // MARK: - Categorization Methods

    /// Extracts tabular structure from text and categorizes financial data.
    ///
    /// This method parses text that contains financial data in a tabular format,
    /// extracting code-value pairs and categorizing them as either earnings or deductions.
    /// It handles various formatting styles commonly found in payslip documents.
    ///
    /// - Parameters:
    ///   - text: The input text containing tabular financial data
    ///   - earnings: An inout dictionary to collect earnings data
    ///   - deductions: An inout dictionary to collect deductions data
    func extractTabularStructure(from text: String, into earnings: inout [String: Double], and deductions: inout [String: Double]) {
        // Look for tabular patterns: Code Amount Code Amount
        let tabularPattern = "([A-Z]{2,6})\\s+([\\d,]+\\.?\\d*)\\s+([A-Z]{2,6})\\s+([\\d,]+\\.?\\d*)"
        let tabularRegex = try? NSRegularExpression(pattern: tabularPattern, options: [])
        let tabularMatches = tabularRegex?.matches(in: text, options: [], range: NSRange(location: 0, length: text.utf16.count)) ?? []

        for match in tabularMatches {
            // First code-amount pair
            if match.numberOfRanges >= 3 {
                let codeRange1 = match.range(at: 1)
                let amountRange1 = match.range(at: 2)

                if let codeSubstring1 = Range(codeRange1, in: text),
                   let amountSubstring1 = Range(amountRange1, in: text) {
                    let code1 = String(text[codeSubstring1])
                    let amountStr1 = String(text[amountSubstring1]).replacingOccurrences(of: ",", with: "")

                    if let amount1 = Double(amountStr1), !shouldExcludeCode(code1) {
                        if isEarningsCode(code1) {
                            earnings[code1] = amount1
                        } else if isDeductionCode(code1) {
                            deductions[code1] = amount1
                        }
                    }
                }
            }

            // Second code-amount pair
            if match.numberOfRanges >= 5 {
                let codeRange2 = match.range(at: 3)
                let amountRange2 = match.range(at: 4)

                if let codeSubstring2 = Range(codeRange2, in: text),
                   let amountSubstring2 = Range(amountRange2, in: text) {
                    let code2 = String(text[codeSubstring2])
                    let amountStr2 = String(text[amountSubstring2]).replacingOccurrences(of: ",", with: "")

                    if let amount2 = Double(amountStr2), !shouldExcludeCode(code2) {
                        if isEarningsCode(code2) {
                            earnings[code2] = amount2
                        } else if isDeductionCode(code2) {
                            deductions[code2] = amount2
                        }
                    }
                }
            }
        }
    }

    // MARK: - Private Categorization Methods

    /// Determines if a code should be excluded from extraction results.
    ///
    /// This method filters out codes that are not meaningful financial data,
    /// such as formatting artifacts, headers, or non-financial identifiers.
    ///
    /// - Parameter code: The financial code to evaluate
    /// - Returns: True if the code should be excluded, false otherwise
    private func shouldExcludeCode(_ code: String) -> Bool {
        let excludedCodes = ["TOTAL", "GROSS", "NET", "CURR", "PREV", "YTD", "DATE", "PAGE"]
        return excludedCodes.contains(code.uppercased())
    }

    /// Determines if a financial code represents earnings/income.
    ///
    /// This method categorizes financial codes based on common military and
    /// civilian payslip patterns, identifying codes that typically represent
    /// income or earnings components.
    ///
    /// - Parameter code: The financial code to categorize
    /// - Returns: True if the code represents earnings, false otherwise
    private func isEarningsCode(_ code: String) -> Bool {
        let earningsCodes = ["BP", "BPAY", "DA", "MSP", "HRA", "CCA", "TA", "MEDICAL", "UNIFORM"]
        return earningsCodes.contains(code.uppercased())
    }

    /// Determines if a financial code represents deductions.
    ///
    /// This method categorizes financial codes based on common military and
    /// civilian payslip patterns, identifying codes that typically represent
    /// deductions or expenses.
    ///
    /// - Parameter code: The financial code to categorize
    /// - Returns: True if the code represents deductions, false otherwise
    private func isDeductionCode(_ code: String) -> Bool {
        let deductionCodes = ["DSOP", "AGIF", "ITAX", "TDS", "INS", "LOAN", "ADVANCE", "PF", "ESI"]
        return deductionCodes.contains(code.uppercased())
    }

    // MARK: - Enhanced Spatial Methods (Phase 2)

    /// Extracts table structure using spatial intelligence from positional elements
    /// This method provides enhanced accuracy for complex tabulated layouts
    /// - Parameter elements: Array of positional elements to analyze
    /// - Returns: Structured table with rows and spatial relationships
    /// - Throws: SpatialAnalysisError if processing fails
    @MainActor
    func extractTableStructure(from elements: [PositionalElement]) async throws -> TableStructure {
        guard let analyzer = spatialAnalyzer else {
            // Fallback to basic structure if no spatial analyzer available
            return createBasicTableStructure(from: elements)
        }

        // Use spatial analyzer to detect rows
        let detectedRows = try await analyzer.detectRows(from: elements, tolerance: nil)

        // Detect column boundaries for the table
        let columnBoundaries = try await analyzer.detectColumnBoundaries(from: elements, minColumnWidth: nil)

        // Create initial table structure
        let tableStructure = TableStructure(
            rows: detectedRows,
            columnBoundaries: columnBoundaries,
            bounds: calculateTableBounds(from: elements),
            metadata: [
                "extractionMethod": "spatial",
                "elementCount": String(elements.count),
                "rowCount": String(detectedRows.count),
                "columnCount": String(columnBoundaries.count + 1)
            ]
        )

        // Detect merged cells for enhanced processing
        let mergedCells = await analyzer.detectMergedCells(in: tableStructure)

        // Add merged cell metadata to table structure
        if !mergedCells.isEmpty {
            var enhancedMetadata = tableStructure.metadata
            enhancedMetadata["mergedCellCount"] = String(mergedCells.count)
            enhancedMetadata["hasMergedCells"] = "true"

            return TableStructure(
                rows: tableStructure.rows,
                columnBoundaries: tableStructure.columnBoundaries,
                bounds: tableStructure.bounds,
                metadata: enhancedMetadata
            )
        }

        return tableStructure
    }

    /// Extracts tabular financial data using spatial intelligence
    /// Enhanced version that leverages spatial relationships for better accuracy
    /// - Parameters:
    ///   - elements: Array of positional elements from the document
    ///   - earnings: Inout dictionary to collect earnings data
    ///   - deductions: Inout dictionary to collect deductions data
    @MainActor
    func extractTabularDataWithSpatialIntelligence(
        from elements: [PositionalElement],
        into earnings: inout [String: Double],
        and deductions: inout [String: Double]
    ) async throws {
        guard let analyzer = spatialAnalyzer else {
            // Fallback to text-based extraction
            let combinedText = elements.map { $0.text }.joined(separator: " ")
            extractTabularStructure(from: combinedText, into: &earnings, and: &deductions)
            return
        }

        // Find element pairs using spatial relationships
        let elementPairs = try await analyzer.findRelatedElements(elements, tolerance: nil)

        // Process high-confidence pairs for financial data
        for pair in elementPairs where pair.isHighConfidence {
            // Extract financial values from the pairs
            if let amount = extractFinancialAmount(from: pair.value.text) {
                let code = cleanFinancialCode(pair.label.text)

                if !shouldExcludeCode(code) {
                    if isEarningsCode(code) {
                        earnings[code] = amount
                    } else if isDeductionCode(code) {
                        deductions[code] = amount
                    }
                }
            }
        }
    }

    // MARK: - Private Spatial Helper Methods

    /// Creates a basic table structure without spatial analysis
    private func createBasicTableStructure(from elements: [PositionalElement]) -> TableStructure {
        // Group elements by approximate Y position for basic row detection
        let rowGroups = elements.groupedByRows(tolerance: 20)
        var tableRows: [TableRow] = []

        for (index, (_, elementsInRow)) in rowGroups.enumerated() {
            if elementsInRow.count >= 2 {
                let row = TableRow(elements: elementsInRow, rowIndex: index)
                tableRows.append(row)
            }
        }

        return TableStructure(
            rows: tableRows.sorted { $0.yPosition < $1.yPosition },
            columnBoundaries: [],
            bounds: calculateTableBounds(from: elements),
            metadata: ["extractionMethod": "basic"]
        )
    }

    /// Calculates the overall bounds of a table from its elements
    private func calculateTableBounds(from elements: [PositionalElement]) -> CGRect {
        guard !elements.isEmpty else { return .zero }

        var minX = CGFloat.greatestFiniteMagnitude
        var maxX = -CGFloat.greatestFiniteMagnitude
        var minY = CGFloat.greatestFiniteMagnitude
        var maxY = -CGFloat.greatestFiniteMagnitude

        for element in elements {
            minX = min(minX, element.bounds.minX)
            maxX = max(maxX, element.bounds.maxX)
            minY = min(minY, element.bounds.minY)
            maxY = max(maxY, element.bounds.maxY)
        }

        return CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
    }

    /// Extracts a financial amount from text
    private func extractFinancialAmount(from text: String) -> Double? {
        let cleanedText = text.replacingOccurrences(of: ",", with: "")
            .replacingOccurrences(of: "₹", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return Double(cleanedText)
    }

    /// Cleans a financial code by removing extra characters
    private func cleanFinancialCode(_ text: String) -> String {
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: ":", with: "")
            .uppercased()
    }
}

// swiftlint:enable no_hardcoded_strings
