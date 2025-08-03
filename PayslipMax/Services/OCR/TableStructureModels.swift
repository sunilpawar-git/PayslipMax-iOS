import Foundation
import Vision
import CoreGraphics

// MARK: - Enhanced Table Structure Models for Military Payslip Processing

/// Enhanced column header information for military payslips
struct ColumnHeader {
    let text: String
    let type: HeaderType
    let columnIndex: Int
    let boundingBox: CGRect
    let confidence: Double
    
    /// Position within the table structure
    var position: CellPosition {
        return CellPosition(row: 0, column: columnIndex)
    }
}

/// Types of column headers found in military payslips
enum HeaderType {
    case earnings       // Credit columns (Basic Pay, DA, HRA, etc.)
    case deductions     // Debit columns (IT, Professional Tax, etc.)
    case description    // Description/Code columns
    case amount         // Generic amount columns
    case unknown        // Unidentified header type
    
    /// Military-specific header patterns
    static let militaryEarningsPatterns = [
        "CREDIT", "CREDITS", "EARNINGS", "INCOME", "ALLOWANCES",
        "BASIC PAY", "DA", "HRA", "TRANSPORT", "MEDICAL"
    ]
    
    static let militaryDeductionsPatterns = [
        "DEBIT", "DEBITS", "DEDUCTIONS", "OUTGOINGS", "RECOVERIES",
        "IT", "PROFESSIONAL TAX", "DSOP", "CGEGIS", "NPS"
    ]
}

/// Financial data grouping for military payslip analysis
struct FinancialGroup {
    let rowIndex: Int
    let cells: [CellData]
    let extractedPairs: [FinancialPair]
    let groupType: FinancialGroupType
    
    /// Calculate total value for this financial group
    var totalValue: Double {
        return extractedPairs.reduce(0.0) { $0 + $1.value }
    }
    
    /// Determine if this group contains valid financial data
    var isValid: Bool {
        return !extractedPairs.isEmpty && extractedPairs.allSatisfy { $0.value > 0 }
    }
}

/// Types of financial groups in military payslips
enum FinancialGroupType {
    case allowance      // Earning/allowance line items
    case deduction      // Deduction line items
    case total          // Total/summary lines
    case unknown        // Unclassified financial data
}

/// Code-value pair extracted from military payslip
struct FinancialPair {
    let code: String
    let value: Double
    let codeCell: CellData
    let valueCell: CellData
    let pairType: FinancialPairType
    
    /// Validation for military-specific codes
    var isValidMilitaryCode: Bool {
        let militaryCodes = ["DA", "HRA", "CCA", "IT", "PT", "DSOP", "CGEGIS", "NPS"]
        return militaryCodes.contains(code.uppercased())
    }
    
    /// Format value for display
    var formattedValue: String {
        return String(format: "%.2f", value)
    }
}

/// Types of financial pairs in military context
enum FinancialPairType {
    case basicPay       // Basic Pay entry
    case allowance      // Various allowances (DA, HRA, etc.)
    case taxDeduction   // Tax-related deductions
    case statutoryDeduction // Statutory deductions (NPS, CGEGIS)
    case other          // Other financial entries
}

/// Table region information for document layout analysis
struct TableRegion {
    let boundingBox: CGRect
    let regionType: TableRegionType
    let confidence: Double
    let cellCount: Int
    
    /// Calculate region area
    var area: CGFloat {
        return boundingBox.width * boundingBox.height
    }
    
    /// Determine if region is large enough to be significant
    var isSignificant: Bool {
        return area > 0.01 && cellCount > 4 // Minimum threshold for table regions
    }
}

/// Types of table regions in military payslips
enum TableRegionType {
    case header         // Header section with column titles
    case dataRows       // Main data section with financial entries
    case totals         // Summary/totals section
    case footer         // Footer information
    case unknown        // Unidentified region
}

/// Cell type classification for military payslip processing
enum CellType {
    case header         // Column header cell
    case code           // Code/description cell
    case amount         // Numeric amount cell
    case total          // Total/summary cell
    case empty          // Empty cell
    case unknown        // Unclassified cell
    
    /// Determine cell type from text content
    static func classify(text: String) -> CellType {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Check if empty
        if trimmedText.isEmpty {
            return .empty
        }
        
        // Check for numeric content (amount cells)
        if isNumericAmount(trimmedText) {
            if isTotal(trimmedText) {
                return .total
            }
            return .amount
        }
        
        // Check for header patterns
        if isHeaderText(trimmedText) {
            return .header
        }
        
        // Default to code for non-numeric text
        return .code
    }
    
    private static func isNumericAmount(_ text: String) -> Bool {
        let numericPattern = #"^\d+(?:\.\d{1,2})?$"#
        return text.range(of: numericPattern, options: .regularExpression) != nil
    }
    
    private static func isTotal(_ text: String) -> Bool {
        let totalPatterns = ["TOTAL", "SUM", "NET", "GROSS"]
        return totalPatterns.contains { text.uppercased().contains($0) }
    }
    
    private static func isHeaderText(_ text: String) -> Bool {
        let headerPatterns = HeaderType.militaryEarningsPatterns + HeaderType.militaryDeductionsPatterns
        return headerPatterns.contains { text.uppercased().contains($0) }
    }
}

/// Enhanced structured table data with military-specific features
struct EnhancedStructuredTableData {
    var cells: [CellData] = []
    var headers: [ColumnHeader] = []
    var financialGroups: [FinancialGroup] = []
    var regions: [TableRegion] = []
    
    /// Add cell data with automatic classification
    mutating func addCellData(_ cellData: CellData) {
        cells.append(cellData)
    }
    
    /// Get cells by type
    func cells(ofType type: CellType) -> [CellData] {
        return cells.filter { CellType.classify(text: $0.text) == type }
    }
    
    /// Calculate overall extraction confidence
    var overallConfidence: Double {
        guard !cells.isEmpty else { return 0.0 }
        let totalConfidence = cells.reduce(0.0) { $0 + Double($1.confidence) }
        return totalConfidence / Double(cells.count)
    }
    
    /// Validate military payslip structure
    var isMilitaryPayslipValid: Bool {
        // Must have headers, financial groups, and reasonable confidence
        return !headers.isEmpty && 
               !financialGroups.isEmpty && 
               overallConfidence > 0.6 &&
               hasRequiredMilitaryHeaders()
    }
    
    private func hasRequiredMilitaryHeaders() -> Bool {
        let hasEarnings = headers.contains { $0.type == .earnings }
        let hasDeductions = headers.contains { $0.type == .deductions }
        return hasEarnings || hasDeductions
    }
}

/// Military-specific validation result
struct MilitaryTableValidationResult {
    let hasCorrectStructure: Bool
    let hasFinancialData: Bool
    let hasMilitaryHeaders: Bool
    let formatCompliance: Double
    let extractedItemsCount: Int
    
    /// Overall validation score
    var overallScore: Double {
        let structureWeight = hasCorrectStructure ? 0.3 : 0.0
        let dataWeight = hasFinancialData ? 0.3 : 0.0
        let headerWeight = hasMilitaryHeaders ? 0.2 : 0.0
        let complianceWeight = formatCompliance * 0.2
        
        return structureWeight + dataWeight + headerWeight + complianceWeight
    }
    
    /// Determine if validation passed
    var isValid: Bool {
        return overallScore > 0.7
    }
}