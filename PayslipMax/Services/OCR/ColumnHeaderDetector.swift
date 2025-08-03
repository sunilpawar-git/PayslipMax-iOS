import Foundation
import Vision
import CoreGraphics

/// Advanced column header detection for military payslips
class ColumnHeaderDetector {
    
    // MARK: - Properties
    private let confidenceThreshold: Double = 0.7
    private let headerRowThreshold: Double = 0.15 // Top 15% of document considered header area
    
    // Military-specific header patterns with priorities
    private let earningsPatterns: [(pattern: String, priority: Int)] = [
        ("CREDIT", 10), ("CREDITS", 10), ("EARNINGS", 9),
        ("ALLOWANCES", 8), ("INCOME", 7), ("BASIC PAY", 9),
        ("DA", 6), ("HRA", 6), ("CCA", 5), ("TA", 5)
    ]
    
    private let deductionsPatterns: [(pattern: String, priority: Int)] = [
        ("DEBIT", 10), ("DEBITS", 10), ("DEDUCTIONS", 9),
        ("OUTGOINGS", 7), ("RECOVERIES", 6), ("IT", 8),
        ("PROFESSIONAL TAX", 7), ("DSOP", 6), ("CGEGIS", 6), ("NPS", 6)
    ]
    
    private let descriptionPatterns: [(pattern: String, priority: Int)] = [
        ("CODE", 8), ("DESCRIPTION", 9), ("PARTICULARS", 7),
        ("DETAILS", 6), ("ITEM", 5), ("TYPE", 4)
    ]
    
    // MARK: - Main Detection Methods
    
    /// Detect column headers in table structure
    func detectColumnHeaders(
        observations: [VNRecognizedTextObservation],
        tableStructure: TableStructure
    ) -> [ColumnHeader] {
        
        // Filter observations to header region
        let headerObservations = filterHeaderObservations(observations)
        
        // Analyze header patterns
        let headerCandidates = analyzeHeaderPatterns(headerObservations)
        
        // Map to table columns
        let mappedHeaders = mapHeadersToColumns(headerCandidates, tableStructure)
        
        // Validate and score headers
        let validatedHeaders = validateHeaders(mappedHeaders, tableStructure)
        
        return validatedHeaders
    }
    
    /// Identify Credit/Debit structure in military payslips
    func identifyCreditDebitStructure(
        headers: [ColumnHeader]
    ) -> CreditDebitStructure {
        
        var creditColumns: [ColumnHeader] = []
        var debitColumns: [ColumnHeader] = []
        var descriptionColumns: [ColumnHeader] = []
        
        for header in headers {
            switch header.type {
            case .earnings:
                creditColumns.append(header)
            case .deductions:
                debitColumns.append(header)
            case .description:
                descriptionColumns.append(header)
            case .amount:
                // Classify generic amount columns based on position
                if isLikelyCreditColumn(header, existingCredits: creditColumns) {
                    creditColumns.append(header)
                } else {
                    debitColumns.append(header)
                }
            case .unknown:
                break
            }
        }
        
        return CreditDebitStructure(
            creditColumns: creditColumns,
            debitColumns: debitColumns,
            descriptionColumns: descriptionColumns,
            isValid: validateCreditDebitStructure(creditColumns, debitColumns, descriptionColumns)
        )
    }
    
    /// Enhanced header classification with military domain knowledge
    func classifyHeaders(
        observations: [VNRecognizedTextObservation]
    ) -> [HeaderClassification] {
        
        var classifications: [HeaderClassification] = []
        
        for observation in observations {
            guard let text = observation.topCandidates(1).first?.string else { continue }
            
            let classification = classifyHeaderText(
                text: text,
                observation: observation
            )
            
            classifications.append(classification)
        }
        
        // Sort by confidence and position
        return classifications.sorted { first, second in
            if first.confidence != second.confidence {
                return first.confidence > second.confidence
            }
            return first.observation.boundingBox.midX < second.observation.boundingBox.midX
        }
    }
    
    // MARK: - Header Filtering and Analysis
    
    /// Filter observations to likely header region
    private func filterHeaderObservations(
        _ observations: [VNRecognizedTextObservation]
    ) -> [VNRecognizedTextObservation] {
        
        // Find document bounds
        guard !observations.isEmpty else { return [] }
        
        let allBounds = observations.map { $0.boundingBox }
        let maxY = allBounds.map { $0.maxY }.max() ?? 1.0
        let headerThresholdY = maxY - headerRowThreshold
        
        // Filter to top region
        return observations.filter { observation in
            observation.boundingBox.midY >= headerThresholdY
        }
    }
    
    /// Analyze header patterns in text observations
    private func analyzeHeaderPatterns(
        _ observations: [VNRecognizedTextObservation]
    ) -> [HeaderCandidate] {
        
        var candidates: [HeaderCandidate] = []
        
        for observation in observations {
            guard let text = observation.topCandidates(1).first?.string else { continue }
            
            let analysis = analyzeHeaderText(text)
            
            if analysis.isLikelyHeader {
                let candidate = HeaderCandidate(
                    observation: observation,
                    text: text,
                    type: analysis.type,
                    confidence: analysis.confidence,
                    priority: analysis.priority
                )
                candidates.append(candidate)
            }
        }
        
        return candidates
    }
    
    /// Analyze individual header text
    private func analyzeHeaderText(_ text: String) -> HeaderAnalysis {
        let normalizedText = text.uppercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Check earnings patterns
        for (pattern, priority) in earningsPatterns {
            if normalizedText.contains(pattern) {
                return HeaderAnalysis(
                    type: .earnings,
                    confidence: calculatePatternConfidence(pattern, in: normalizedText),
                    priority: priority,
                    isLikelyHeader: true
                )
            }
        }
        
        // Check deductions patterns
        for (pattern, priority) in deductionsPatterns {
            if normalizedText.contains(pattern) {
                return HeaderAnalysis(
                    type: .deductions,
                    confidence: calculatePatternConfidence(pattern, in: normalizedText),
                    priority: priority,
                    isLikelyHeader: true
                )
            }
        }
        
        // Check description patterns
        for (pattern, priority) in descriptionPatterns {
            if normalizedText.contains(pattern) {
                return HeaderAnalysis(
                    type: .description,
                    confidence: calculatePatternConfidence(pattern, in: normalizedText),
                    priority: priority,
                    isLikelyHeader: true
                )
            }
        }
        
        // Check for generic amount headers
        if isGenericAmountHeader(normalizedText) {
            return HeaderAnalysis(
                type: .amount,
                confidence: 0.6,
                priority: 3,
                isLikelyHeader: true
            )
        }
        
        return HeaderAnalysis(
            type: .unknown,
            confidence: 0.0,
            priority: 0,
            isLikelyHeader: false
        )
    }
    
    /// Calculate pattern matching confidence
    private func calculatePatternConfidence(_ pattern: String, in text: String) -> Double {
        if text == pattern {
            return 1.0 // Exact match
        } else if text.contains(pattern) {
            return Double(pattern.count) / Double(text.count) // Partial match ratio
        }
        return 0.0
    }
    
    /// Check if text represents a generic amount header
    private func isGenericAmountHeader(_ text: String) -> Bool {
        let amountPatterns = ["AMOUNT", "VALUE", "RUPEES", "RS.", "₹"]
        return amountPatterns.contains { text.contains($0) }
    }
    
    // MARK: - Header Mapping and Validation
    
    /// Map header candidates to table columns
    private func mapHeadersToColumns(
        _ candidates: [HeaderCandidate],
        _ tableStructure: TableStructure
    ) -> [ColumnHeader] {
        
        var mappedHeaders: [ColumnHeader] = []
        
        for candidate in candidates {
            if let columnIndex = findColumnIndex(
                for: candidate.observation,
                in: tableStructure
            ) {
                let header = ColumnHeader(
                    text: candidate.text,
                    type: candidate.type,
                    columnIndex: columnIndex,
                    boundingBox: candidate.observation.boundingBox,
                    confidence: candidate.confidence
                )
                mappedHeaders.append(header)
            }
        }
        
        return mappedHeaders
    }
    
    /// Find column index for observation
    private func findColumnIndex(
        for observation: VNRecognizedTextObservation,
        in tableStructure: TableStructure
    ) -> Int? {
        
        let observationX = observation.boundingBox.midX
        let tolerance: Double = 0.05 // 5% tolerance
        
        // Find closest column boundary
        var closestDistance: Double = Double.infinity
        var closestColumnIndex: Int?
        
        for boundary in tableStructure.columns {
            let distance = abs(observationX - boundary.xPosition)
            if distance < closestDistance && distance <= tolerance {
                closestDistance = distance
                closestColumnIndex = boundary.columnIndex
            }
        }
        
        return closestColumnIndex
    }
    
    /// Validate detected headers
    private func validateHeaders(
        _ headers: [ColumnHeader],
        _ tableStructure: TableStructure
    ) -> [ColumnHeader] {
        
        var validatedHeaders: [ColumnHeader] = []
        
        for header in headers {
            if isValidHeader(header, tableStructure) {
                validatedHeaders.append(header)
            }
        }
        
        // Remove duplicates by column index
        return removeDuplicateColumns(validatedHeaders)
    }
    
    /// Check if header is valid
    private func isValidHeader(
        _ header: ColumnHeader,
        _ tableStructure: TableStructure
    ) -> Bool {
        
        // Confidence check
        if header.confidence < confidenceThreshold {
            return false
        }
        
        // Column index bounds check
        if header.columnIndex < 0 || header.columnIndex >= tableStructure.columns.count {
            return false
        }
        
        // Position validation
        if !isInHeaderRegion(header.boundingBox) {
            return false
        }
        
        return true
    }
    
    /// Check if bounding box is in header region
    private func isInHeaderRegion(_ boundingBox: CGRect) -> Bool {
        return boundingBox.midY >= (1.0 - headerRowThreshold)
    }
    
    /// Remove duplicate headers for same column
    private func removeDuplicateColumns(_ headers: [ColumnHeader]) -> [ColumnHeader] {
        var seenColumns: Set<Int> = []
        var uniqueHeaders: [ColumnHeader] = []
        
        for header in headers.sorted(by: { $0.confidence > $1.confidence }) {
            if !seenColumns.contains(header.columnIndex) {
                seenColumns.insert(header.columnIndex)
                uniqueHeaders.append(header)
            }
        }
        
        return uniqueHeaders
    }
    
    // MARK: - Credit/Debit Structure Analysis
    
    /// Check if column is likely a credit column
    private func isLikelyCreditColumn(
        _ header: ColumnHeader,
        existingCredits: [ColumnHeader]
    ) -> Bool {
        
        // Position-based heuristic: credit columns often come before debit columns
        let averageCreditPosition = existingCredits.isEmpty ? 0.0 : 
            existingCredits.map { Double($0.columnIndex) }.reduce(0, +) / Double(existingCredits.count)
        
        return Double(header.columnIndex) <= averageCreditPosition + 1.0
    }
    
    /// Validate Credit/Debit structure
    private func validateCreditDebitStructure(
        _ creditColumns: [ColumnHeader],
        _ debitColumns: [ColumnHeader],
        _ descriptionColumns: [ColumnHeader]
    ) -> Bool {
        
        // Must have at least one credit or debit column
        let hasFinancialColumns = !creditColumns.isEmpty || !debitColumns.isEmpty
        
        // Should have at least one description column
        let hasDescriptionColumn = !descriptionColumns.isEmpty
        
        // Reasonable column distribution
        let totalColumns = creditColumns.count + debitColumns.count + descriptionColumns.count
        let isReasonableDistribution = totalColumns >= 2 && totalColumns <= 8
        
        return hasFinancialColumns && hasDescriptionColumn && isReasonableDistribution
    }
    
    /// Classify individual header text
    private func classifyHeaderText(
        text: String,
        observation: VNRecognizedTextObservation
    ) -> HeaderClassification {
        
        let analysis = analyzeHeaderText(text)
        
        return HeaderClassification(
            text: text,
            type: analysis.type,
            confidence: analysis.confidence,
            observation: observation,
            priority: analysis.priority
        )
    }
}

// MARK: - Supporting Data Models

/// Header candidate for analysis
private struct HeaderCandidate {
    let observation: VNRecognizedTextObservation
    let text: String
    let type: HeaderType
    let confidence: Double
    let priority: Int
}

/// Header text analysis result
private struct HeaderAnalysis {
    let type: HeaderType
    let confidence: Double
    let priority: Int
    let isLikelyHeader: Bool
}

/// Credit/Debit structure result
struct CreditDebitStructure {
    let creditColumns: [ColumnHeader]
    let debitColumns: [ColumnHeader]
    let descriptionColumns: [ColumnHeader]
    let isValid: Bool
    
    /// Total number of detected columns
    var totalColumns: Int {
        return creditColumns.count + debitColumns.count + descriptionColumns.count
    }
    
    /// Structure confidence based on column distribution
    var confidence: Double {
        if !isValid { return 0.0 }
        
        let expectedBalance = abs(Double(creditColumns.count) - Double(debitColumns.count)) <= 2.0
        let hasDescriptions = !descriptionColumns.isEmpty
        
        var score = 0.0
        if expectedBalance { score += 0.5 }
        if hasDescriptions { score += 0.3 }
        if totalColumns >= 3 { score += 0.2 }
        
        return score
    }
}

/// Header classification result
struct HeaderClassification {
    let text: String
    let type: HeaderType
    let confidence: Double
    let observation: VNRecognizedTextObservation
    let priority: Int
}