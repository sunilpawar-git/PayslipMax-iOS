import Vision
import CoreGraphics
import UIKit

/// Enhanced geometric analysis for table structure recognition with tabular intelligence
class GeometricTextAnalyzer {
    
    // MARK: - Dependencies
    private let tableDetector: TableStructureDetector
    private let cellExtractor: CellExtractionService
    private let dataProcessor: TabularDataProcessor
    
    // MARK: - Initialization
    init(
        tableDetector: TableStructureDetector = TableStructureDetector(),
        cellExtractor: CellExtractionService = CellExtractionService(),
        dataProcessor: TabularDataProcessor = TabularDataProcessor()
    ) {
        self.tableDetector = tableDetector
        self.cellExtractor = cellExtractor
        self.dataProcessor = dataProcessor
    }
    
    // MARK: - Table Structure Building
    func buildTableStructure(
        textRectangles: [VNRecognizedTextObservation],
        documentSegments: [VNRectangleObservation]
    ) -> TableStructure {
        
        // 1. Identify potential table regions
        let tableRegions = identifyTableRegions(documentSegments)
        
        // 2. Analyze text alignment patterns
        let alignmentGroups = analyzeTextAlignment(textRectangles)
        
        // 3. Detect column boundaries
        let columnBoundaries = detectColumnBoundaries(alignmentGroups)
        
        // 4. Identify row structures
        let rowStructures = identifyRowStructures(textRectangles, columnBoundaries)
        
        return TableStructure(
            regions: tableRegions,
            columns: columnBoundaries,
            rows: rowStructures,
            cells: buildCellMatrix(rowStructures, columnBoundaries)
        )
    }
    
    // MARK: - Spatial Text Association
    func associateTextWithTableStructure(
        _ textResult: GeometricTextResult,
        _ tableStructure: TableStructure
    ) -> StructuredTableData {
        
        var structuredData = StructuredTableData()
        
        // Associate each text observation with table cells
        for observation in textResult.observations {
            if let cell = findContainingCell(observation.boundingBox, in: tableStructure) {
                let cellData = CellData(
                    text: observation.topCandidates(1).first?.string ?? "",
                    confidence: observation.confidence,
                    boundingBox: observation.boundingBox,
                    cellPosition: cell.position
                )
                structuredData.addCellData(cellData)
            }
        }
        
        // Identify column headers (Credit/Debit detection)
        structuredData.headers = identifyColumnHeaders(structuredData, tableStructure)
        
        // Group related financial data
        structuredData.financialGroups = groupFinancialData(structuredData)
        
        return structuredData
    }
    
    // MARK: - Column Header Detection (From Phase 2 Guide)
    private func identifyColumnHeaders(
        _ data: StructuredTableData,
        _ structure: TableStructure
    ) -> [ColumnHeader] {
        
        var headers: [ColumnHeader] = []
        
        // Look for common military payslip headers
        let headerPatterns = [
            "CREDIT", "CREDITS", "EARNINGS", "INCOME",
            "DEBIT", "DEBITS", "DEDUCTIONS", "OUTGOINGS"
        ]
        
        for cell in data.cells {
            let cellText = cell.text.uppercased()
            
            for pattern in headerPatterns {
                if cellText.contains(pattern) {
                    let headerType: HeaderType = pattern.contains("CREDIT") || pattern.contains("EARNING") ? .earnings : .deductions
                    
                    headers.append(ColumnHeader(
                        text: cell.text,
                        type: headerType,
                        columnIndex: cell.cellPosition.column,
                        boundingBox: cell.boundingBox,
                        confidence: Double(cell.confidence)
                    ))
                }
            }
        }
        
        return headers
    }
    
    // MARK: - Financial Data Grouping (From Phase 2 Guide)
    private func groupFinancialData(_ data: StructuredTableData) -> [FinancialGroup] {
        var groups: [FinancialGroup] = []
        
        // Group cells by rows to identify financial line items
        let rowGroups = Dictionary(grouping: data.cells) { $0.cellPosition.row }
        
        for (rowIndex, cellsInRow) in rowGroups.sorted(by: { $0.key < $1.key }) {
            if cellsInRow.count >= 2 { // Minimum for code-value pair
                let extractedPairs = extractFinancialPairs(from: cellsInRow)
                let groupType = determineFinancialGroupType(cellsInRow)
                
                let group = FinancialGroup(
                    rowIndex: rowIndex,
                    cells: cellsInRow,
                    extractedPairs: extractedPairs,
                    groupType: groupType
                )
                groups.append(group)
            }
        }
        
        return groups
    }
    
    private func extractFinancialPairs(from cells: [CellData]) -> [FinancialPair] {
        var pairs: [FinancialPair] = []
        
        // Sort cells by column position
        let sortedCells = cells.sorted { $0.cellPosition.column < $1.cellPosition.column }
        
        // Extract code-value pairs
        for i in stride(from: 0, to: sortedCells.count - 1, by: 2) {
            let codeCell = sortedCells[i]
            let valueCell = sortedCells[i + 1]
            
            // Validate that value cell contains numeric data
            if let value = extractNumericValue(from: valueCell.text) {
                let pairType = determinePairType(code: codeCell.text)
                
                pairs.append(FinancialPair(
                    code: codeCell.text.trimmingCharacters(in: .whitespacesAndNewlines),
                    value: value,
                    codeCell: codeCell,
                    valueCell: valueCell,
                    pairType: pairType
                ))
            }
        }
        
        return pairs
    }
    
    private func extractNumericValue(from text: String) -> Double? {
        let numericPattern = #"(\d+(?:\.\d+)?)"#
        guard let regex = try? NSRegularExpression(pattern: numericPattern),
              let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
              let range = Range(match.range(at: 1), in: text) else {
            return nil
        }
        
        return Double(String(text[range]))
    }
    
    private func determineFinancialGroupType(_ cells: [CellData]) -> FinancialGroupType {
        let combinedText = cells.map { $0.text.uppercased() }.joined(separator: " ")
        
        if combinedText.contains("TOTAL") || combinedText.contains("SUM") {
            return .total
        } else if combinedText.contains("DEBIT") || combinedText.contains("DEDUCTION") {
            return .deduction
        } else if combinedText.contains("CREDIT") || combinedText.contains("ALLOWANCE") {
            return .allowance
        }
        
        return .unknown
    }
    
    private func determinePairType(code: String) -> FinancialPairType {
        let upperCode = code.uppercased()
        
        if upperCode.contains("BASIC PAY") || upperCode == "BP" {
            return .basicPay
        } else if ["DA", "HRA", "CCA", "TA"].contains(upperCode) {
            return .allowance
        } else if ["IT", "PT", "TAX"].contains(where: { upperCode.contains($0) }) {
            return .taxDeduction
        } else if ["DSOP", "CGEGIS", "NPS", "GPF"].contains(upperCode) {
            return .statutoryDeduction
        }
        
        return .other
    }
    
    // MARK: - Enhanced Tabular Intelligence Processing
    func performCompleteTableAnalysis(
        observations: [VNRecognizedTextObservation],
        originalImage: UIImage,
        imageSize: CGSize
    ) async -> CompleteTableAnalysisResult {
        
        let startTime = Date()
        
        // 1. Detect table structure using advanced algorithms
        let detectedStructure = tableDetector.detectTableStructure(
            from: observations,
            in: imageSize
        )
        
        // 2. Extract text from detected cells
        let cellExtractionResult = await cellExtractor.extractTextFromCells(
            detectedStructure.cellMatrix,
            originalImage: originalImage
        )
        
        // 3. Process tabular data for financial information
        let tabularProcessingResult = dataProcessor.processTabularData(
            cellExtractionResult,
            tableStructure: detectedStructure
        )
        
        let processingTime = Date().timeIntervalSince(startTime)
        
        return CompleteTableAnalysisResult(
            detectedStructure: detectedStructure,
            extractedCells: cellExtractionResult,
            processedData: tabularProcessingResult,
            overallConfidence: calculateOverallConfidence(
                detectedStructure.confidence,
                cellExtractionResult.overallConfidence,
                tabularProcessingResult.confidence
            ),
            processingMetrics: EnhancedProcessingMetrics(
                totalProcessingTime: processingTime,
                structureDetectionTime: 0.0, // Would be measured in actual implementation
                cellExtractionTime: cellExtractionResult.metrics.totalProcessingTime,
                dataProcessingTime: tabularProcessingResult.metrics.processingTime,
                textObservationCount: observations.count,
                cellsProcessed: cellExtractionResult.metrics.totalCellsProcessed,
                financialEntriesFound: tabularProcessingResult.financialEntries.count
            )
        )
    }
    
    // MARK: - Text Geometry Analysis
    func analyzeTextGeometry(
        observations: [VNRecognizedTextObservation],
        tableStructure: TableStructure
    ) -> GeometricTextResult {
        
        let combinedText = observations.compactMap { observation in
            observation.topCandidates(1).first?.string
        }.joined(separator: " ")
        
        let averageConfidence = observations.reduce(0.0) { sum, observation in
            sum + Double(observation.confidence)
        } / Double(max(observations.count, 1))
        
        return GeometricTextResult(
            text: combinedText,
            observations: observations,
            confidence: averageConfidence,
            metrics: ProcessingMetrics(
                processingTime: 0.0,
                memoryUsage: 0,
                textDetectionCount: observations.count
            )
        )
    }
    
    // MARK: - Military Payslip Specific Analysis
    func analyzeMilitaryPayslipStructure(
        observations: [VNRecognizedTextObservation],
        originalImage: UIImage,
        imageSize: CGSize
    ) async -> MilitaryPayslipAnalysisResult {
        
        // Perform complete table analysis
        let completeAnalysis = await performCompleteTableAnalysis(
            observations: observations,
            originalImage: originalImage,
            imageSize: imageSize
        )
        
        // Extract military-specific insights
        let militaryInsights = extractMilitaryInsights(from: completeAnalysis.processedData)
        
        // Validate PCDA compliance
        let pcdaCompliance = validatePCDACompliance(completeAnalysis.processedData)
        
        return MilitaryPayslipAnalysisResult(
            completeAnalysis: completeAnalysis,
            militaryInsights: militaryInsights,
            pcdaCompliance: pcdaCompliance,
            confidence: min(completeAnalysis.overallConfidence, militaryInsights.confidence)
        )
    }
    
    // MARK: - Private Helper Methods
    private func identifyTableRegions(_ documentSegments: [VNRectangleObservation]) -> [TableRegion] {
        return documentSegments.compactMap { segment in
            let boundingBox = segment.boundingBox
            let aspectRatio = boundingBox.width / boundingBox.height
            
            // Identify table-like regions based on aspect ratio and size
            if aspectRatio > 1.2 && boundingBox.height > 0.1 {
                return TableRegion(
                    boundingBox: boundingBox,
                    regionType: .dataRows,
                    confidence: 0.8, // VNRectangleObservation doesn't have confidence
                    cellCount: estimateCellCountFromBoundingBox(boundingBox)
                )
            }
            return nil
        }
    }
    
    private func estimateCellCountFromBoundingBox(_ boundingBox: CGRect) -> Int {
        let area = boundingBox.width * boundingBox.height
        
        // Rough estimation based on bounding box size
        if area > 0.5 {
            return 20 // Large table region
        } else if area > 0.2 {
            return 10 // Medium table region
        } else {
            return 5  // Small table region
        }
    }
    
    private func analyzeTextAlignment(_ textRectangles: [VNRecognizedTextObservation]) -> [AlignmentGroup] {
        var alignmentGroups: [AlignmentGroup] = []
        
        // Group text by vertical alignment (similar Y coordinates)
        let groupedByY = Dictionary(grouping: textRectangles) { observation in
            Int(observation.boundingBox.midY * 100) // Group by approximate Y position
        }
        
        for (_, observations) in groupedByY {
            if observations.count >= 2 {
                let group = AlignmentGroup(
                    observations: observations,
                    alignmentType: .horizontal,
                    averageY: observations.reduce(0.0) { sum, obs in
                        sum + obs.boundingBox.midY
                    } / Double(observations.count)
                )
                alignmentGroups.append(group)
            }
        }
        
        return alignmentGroups
    }
    
    private func detectColumnBoundaries(_ alignmentGroups: [AlignmentGroup]) -> [ColumnBoundary] {
        var columnBoundaries: [ColumnBoundary] = []
        
        // Analyze X positions across all alignment groups
        var xPositions: [Double] = []
        
        for group in alignmentGroups {
            for observation in group.observations {
                xPositions.append(observation.boundingBox.minX)
                xPositions.append(observation.boundingBox.maxX)
            }
        }
        
        // Create column boundaries from X positions
        let sortedPositions = Array(Set(xPositions)).sorted()
        
        for (index, position) in sortedPositions.enumerated() {
            columnBoundaries.append(ColumnBoundary(
                xPosition: position,
                columnIndex: index,
                confidence: 0.8
            ))
        }
        
        return columnBoundaries
    }
    
    private func identifyRowStructures(
        _ textRectangles: [VNRecognizedTextObservation],
        _ columnBoundaries: [ColumnBoundary]
    ) -> [RowStructure] {
        
        // Group text rectangles by Y position to identify rows
        let groupedByY = Dictionary(grouping: textRectangles) { observation in
            Int(observation.boundingBox.midY * 100)
        }
        
        var rowStructures: [RowStructure] = []
        
        for (_, observations) in groupedByY.sorted(by: { $0.key > $1.key }) {
            let averageY = observations.reduce(0.0) { sum, obs in
                sum + obs.boundingBox.midY
            } / Double(observations.count)
            
            let rowStructure = RowStructure(
                yPosition: averageY,
                observations: observations,
                cellCount: min(observations.count, columnBoundaries.count)
            )
            
            rowStructures.append(rowStructure)
        }
        
        return rowStructures
    }
    
    private func buildCellMatrix(
        _ rowStructures: [RowStructure],
        _ columnBoundaries: [ColumnBoundary]
    ) -> [[TableCell]] {
        
        var cellMatrix: [[TableCell]] = []
        
        for (rowIndex, row) in rowStructures.enumerated() {
            var rowCells: [TableCell] = []
            
            for (colIndex, _) in columnBoundaries.enumerated() {
                let cell = TableCell(
                    position: CellPosition(row: rowIndex, column: colIndex),
                    boundingBox: CGRect(x: 0, y: 0, width: 0.1, height: 0.05),
                    observations: row.observations,
                    cellType: .code,
                    confidence: 0.8
                )
                rowCells.append(cell)
            }
            cellMatrix.append(rowCells)
        }
        
        return cellMatrix
    }
    
    private func findContainingCell(
        _ boundingBox: CGRect,
        in tableStructure: TableStructure
    ) -> TableCell? {
        
        for row in tableStructure.cells {
            for cell in row {
                if cell.boundingBox.intersects(boundingBox) {
                    return cell
                }
            }
        }
        
        return nil
    }
    
    // MARK: - Enhanced Helper Methods
    private func calculateOverallConfidence(
        _ structureConfidence: Double,
        _ cellConfidence: Double,
        _ processingConfidence: Double
    ) -> Double {
        
        // Weighted average with structure detection being most important
        let weights: [Double] = [0.4, 0.3, 0.3]
        let confidences = [structureConfidence, cellConfidence, processingConfidence]
        
        return zip(weights, confidences).reduce(0.0) { sum, pair in
            sum + (pair.0 * pair.1)
        }
    }
    
    private func extractMilitaryInsights(from processedData: TabularProcessingResult) -> MilitaryInsights {
        let militaryData = processedData.militaryData
        
        // Calculate military-specific metrics
        let basicPayPercentage = calculateBasicPayPercentage(militaryData)
        let allowanceBreakdown = calculateAllowanceBreakdown(militaryData)
        let deductionAnalysis = analyzeDeductions(militaryData)
        
        return MilitaryInsights(
            basicPayPercentage: basicPayPercentage,
            allowanceBreakdown: allowanceBreakdown,
            deductionAnalysis: deductionAnalysis,
            payScale: detectPayScale(militaryData),
            serviceYears: estimateServiceYears(militaryData),
            confidence: calculateMilitaryInsightsConfidence(militaryData)
        )
    }
    
    private func validatePCDACompliance(_ processedData: TabularProcessingResult) -> PCDAComplianceResult {
        var compliance = PCDAComplianceResult()
        
        // Check for PCDA format requirements
        compliance.hasCorrectStructure = processedData.structureAnalysis.confidence > 0.7
        compliance.hasFinancialTotals = processedData.calculatedTotals.entryCount > 0
        compliance.hasMandatoryFields = hasMandatoryPCDAFields(processedData)
        compliance.formatConsistency = calculateFormatConsistency(processedData)
        
        compliance.overallScore = (
            (compliance.hasCorrectStructure ? 0.25 : 0.0) +
            (compliance.hasFinancialTotals ? 0.25 : 0.0) +
            (compliance.hasMandatoryFields ? 0.25 : 0.0) +
            (compliance.formatConsistency * 0.25)
        )
        
        return compliance
    }
    
    private func calculateBasicPayPercentage(_ militaryData: MilitaryPayslipData) -> Double {
        guard let basicPay = militaryData.basicPay else { return 0.0 }
        
        let totalEarnings = militaryData.allowances.reduce(basicPay.value) { sum, allowance in
            sum + allowance.credits.reduce(0.0) { $0 + $1.value }
        }
        
        return totalEarnings > 0 ? (basicPay.value / totalEarnings) * 100 : 0.0
    }
    
    private func calculateAllowanceBreakdown(_ militaryData: MilitaryPayslipData) -> [String: Double] {
        var breakdown: [String: Double] = [:]
        
        for allowance in militaryData.allowances {
            let totalAmount = allowance.credits.reduce(0.0) { $0 + $1.value }
            breakdown[allowance.code] = totalAmount
        }
        
        return breakdown
    }
    
    private func analyzeDeductions(_ militaryData: MilitaryPayslipData) -> DeductionAnalysis {
        let totalDeductions = militaryData.deductions.reduce(0.0) { sum, deduction in
            sum + deduction.debits.reduce(0.0) { $0 + $1.value }
        }
        
        let taxDeductions = militaryData.deductions.filter { $0.type == .tax }
            .reduce(0.0) { sum, deduction in
                sum + deduction.debits.reduce(0.0) { $0 + $1.value }
            }
        
        return DeductionAnalysis(
            totalDeductions: totalDeductions,
            taxDeductions: taxDeductions,
            otherDeductions: totalDeductions - taxDeductions,
            deductionCount: militaryData.deductions.count
        )
    }
    
    private func detectPayScale(_ militaryData: MilitaryPayslipData) -> String? {
        // Military pay scale detection logic
        guard let basicPay = militaryData.basicPay else { return nil }
        
        let payAmount = basicPay.value
        
        // Common military pay scales (simplified)
        switch payAmount {
        case 15000...20000:
            return "Scale A"
        case 20000...30000:
            return "Scale B"
        case 30000...50000:
            return "Scale C"
        default:
            return "Unknown"
        }
    }
    
    private func estimateServiceYears(_ militaryData: MilitaryPayslipData) -> Int? {
        // Service years estimation based on pay and allowances
        // This is a simplified estimation
        return nil
    }
    
    private func calculateMilitaryInsightsConfidence(_ militaryData: MilitaryPayslipData) -> Double {
        var score = 0.0
        
        if militaryData.basicPay != nil { score += 0.3 }
        if !militaryData.allowances.isEmpty { score += 0.3 }
        if !militaryData.deductions.isEmpty { score += 0.2 }
        if !militaryData.branchIndicators.isEmpty { score += 0.2 }
        
        return score
    }
    
    private func hasMandatoryPCDAFields(_ processedData: TabularProcessingResult) -> Bool {
        let entries = processedData.financialEntries
        
        // Check for mandatory fields in PCDA format
        let hasBasicPay = entries.contains { $0.code.contains("BP") || $0.description.contains("BASIC PAY") }
        let hasFinancialData = !entries.isEmpty
        let hasStructure = processedData.structureAnalysis.rowCount > 0
        
        return hasBasicPay && hasFinancialData && hasStructure
    }
    
    private func calculateFormatConsistency(_ processedData: TabularProcessingResult) -> Double {
        let entries = processedData.financialEntries
        guard !entries.isEmpty else { return 0.0 }
        
        let validEntries = entries.filter { $0.validationResult.isValid }
        return Double(validEntries.count) / Double(entries.count)
    }
}

// MARK: - Supporting Data Models
struct TableStructure {
    let regions: [TableRegion]
    let columns: [ColumnBoundary]
    let rows: [RowStructure]
    let cells: [[TableCell]]
}

struct StructuredTableData {
    var cells: [CellData] = []
    var headers: [ColumnHeader] = []
    var financialGroups: [FinancialGroup] = []
    
    mutating func addCellData(_ cellData: CellData) {
        cells.append(cellData)
    }
}

struct CellData {
    let text: String
    let confidence: Float
    let boundingBox: CGRect
    let cellPosition: CellPosition
}

struct CellPosition: Hashable {
    let row: Int
    let column: Int
}

struct TableCell {
    let position: CellPosition
    let boundingBox: CGRect
    let observations: [VNRecognizedTextObservation]
    let cellType: CellType
    let confidence: Double
    
    // Legacy compatibility - VNRecognizedTextObservation inherits from VNTextObservation
    var observation: VNRecognizedTextObservation? {
        return observations.first
    }
}

struct AlignmentGroup {
    let observations: [VNRecognizedTextObservation]
    let alignmentType: AlignmentType
    let averageY: Double
}

struct ColumnBoundary {
    let xPosition: Double
    let columnIndex: Int
    let confidence: Float
}

struct RowStructure {
    let yPosition: Double
    let observations: [VNRecognizedTextObservation]
    let cellCount: Int
}

enum AlignmentType {
    case horizontal
    case vertical
}

// MARK: - Enhanced Analysis Results
struct CompleteTableAnalysisResult {
    let detectedStructure: DetectedTableStructure
    let extractedCells: CellExtractionResult
    let processedData: TabularProcessingResult
    let overallConfidence: Double
    let processingMetrics: EnhancedProcessingMetrics
}

struct MilitaryPayslipAnalysisResult {
    let completeAnalysis: CompleteTableAnalysisResult
    let militaryInsights: MilitaryInsights
    let pcdaCompliance: PCDAComplianceResult
    let confidence: Double
}

struct MilitaryInsights {
    let basicPayPercentage: Double
    let allowanceBreakdown: [String: Double]
    let deductionAnalysis: DeductionAnalysis
    let payScale: String?
    let serviceYears: Int?
    let confidence: Double
}

struct DeductionAnalysis {
    let totalDeductions: Double
    let taxDeductions: Double
    let otherDeductions: Double
    let deductionCount: Int
}

struct PCDAComplianceResult {
    var hasCorrectStructure: Bool = false
    var hasFinancialTotals: Bool = false
    var hasMandatoryFields: Bool = false
    var formatConsistency: Double = 0.0
    var overallScore: Double = 0.0
}

struct EnhancedProcessingMetrics {
    let totalProcessingTime: TimeInterval
    let structureDetectionTime: TimeInterval
    let cellExtractionTime: TimeInterval
    let dataProcessingTime: TimeInterval
    let textObservationCount: Int
    let cellsProcessed: Int
    let financialEntriesFound: Int
}