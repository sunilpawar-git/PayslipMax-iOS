import Foundation
import CoreGraphics

/// Helper class for classifying document sections based on spatial clustering
/// Extracted from SpatialAnalyzer to maintain 300-line limit compliance
@MainActor
final class SpatialSectionClassifier {
    
    // MARK: - Properties
    
    private let configuration: SpatialAnalysisConfiguration
    
    /// Helper for section analysis operations
    private let analysisHelper: SectionAnalysisHelper
    
    // MARK: - Initialization
    
    init(configuration: SpatialAnalysisConfiguration) {
        self.configuration = configuration
        self.analysisHelper = SectionAnalysisHelper()
    }
    
    // MARK: - Section Classification Methods
    
    /// Classifies elements into earnings and deductions sections
    /// Enhanced for payslip-specific financial data categorization
    func classifyIntoSections(
        _ elements: [PositionalElement]
    ) async throws -> SectionClassificationResult {
        
        guard !elements.isEmpty else {
            throw SpatialAnalysisError.insufficientElements(count: 0)
        }
        
        var earningsElements: [PositionalElement] = []
        var deductionsElements: [PositionalElement] = []
        var otherElements: [PositionalElement] = []
        
        // Step 1: Find section headers to establish boundaries
        let headerElements = elements.filter { element in
            let text = element.text.uppercased()
            return text.contains("EARNINGS") || text.contains("DEDUCTIONS") || 
                   text.contains("INCOME") || text.contains("ALLOWANCES")
        }
        
        // Step 2: If we have clear section headers, use position-based classification
        if let earningsHeader = headerElements.first(where: { $0.text.uppercased().contains("EARNINGS") || $0.text.uppercased().contains("INCOME") }),
           let deductionsHeader = headerElements.first(where: { $0.text.uppercased().contains("DEDUCTIONS") }) {
            
            // Use Y-position to separate sections
            let sectionBoundary = (earningsHeader.center.y + deductionsHeader.center.y) / 2
            
            for element in elements {
                if element.center.y <= sectionBoundary {
                    if analysisHelper.isFinancialElement(element) {
                        earningsElements.append(element)
                    } else {
                        otherElements.append(element)
                    }
                } else {
                    if analysisHelper.isFinancialElement(element) {
                        deductionsElements.append(element)
                    } else {
                        otherElements.append(element)
                    }
                }
            }
        } else {
            // Step 3: Use content-based classification when no clear headers
            for element in elements {
                let classification = analysisHelper.classifyElementByContent(element)
                
                switch classification {
                case .earnings:
                    earningsElements.append(element)
                case .deductions:
                    deductionsElements.append(element)
                case .unknown:
                    otherElements.append(element)
                }
            }
        }
        
        // Step 4: Calculate confidence based on classification quality
        let confidence = analysisHelper.calculateSectionClassificationConfidence(
            earningsElements: earningsElements,
            deductionsElements: deductionsElements,
            otherElements: otherElements
        )
        
        return SectionClassificationResult(
            earningsElements: earningsElements,
            deductionsElements: deductionsElements,
            otherElements: otherElements,
            confidence: confidence
        )
    }
    
    /// Groups elements into logical sections based on spatial clustering
    func groupIntoSections(
        _ elements: [PositionalElement],
        clusteringDistance: CGFloat?
    ) async throws -> [ElementSection] {
        guard !elements.isEmpty else {
            throw SpatialAnalysisError.insufficientElements(count: 0)
        }
        
        let maxDistance = clusteringDistance ?? configuration.sectionClusteringDistance
        
        var sections: [ElementSection] = []
        var unprocessedElements = elements
        
        while !unprocessedElements.isEmpty {
            let seed = unprocessedElements.removeFirst()
            var sectionElements: [PositionalElement] = [seed]
            
            // Find all elements within clustering distance
            var i = 0
            while i < unprocessedElements.count {
                let candidate = unprocessedElements[i]
                
                // Check if candidate is close to any element in current section
                let isInSection = sectionElements.contains { sectionElement in
                    sectionElement.distanceTo(candidate) <= maxDistance
                }
                
                if isInSection {
                    sectionElements.append(candidate)
                    unprocessedElements.remove(at: i)
                } else {
                    i += 1
                }
            }
            
            // Classify section type based on content
            let sectionType = classifySectionType(elements: sectionElements)
            let confidence = calculateSectionConfidence(elements: sectionElements, type: sectionType)
            
            let section = ElementSection(
                elements: sectionElements,
                sectionType: sectionType,
                confidence: confidence,
                metadata: [
                    "elementCount": String(sectionElements.count),
                    "clusteringDistance": String(describing: maxDistance)
                ]
            )
            
            sections.append(section)
        }
        
        return sections
    }
    
    /// Classifies section type based on element content
    func classifySectionType(elements: [PositionalElement]) -> SectionType {
        let texts = elements.map { $0.text.lowercased() }
        let combinedText = texts.joined(separator: " ")
        
        // Look for earnings keywords
        if combinedText.contains("earnings") || combinedText.contains("income") || 
           combinedText.contains("bpay") || combinedText.contains("basic pay") ||
           combinedText.contains("da") || combinedText.contains("msp") {
            return .earnings
        }
        
        // Look for deductions keywords
        if combinedText.contains("deductions") || combinedText.contains("tax") ||
           combinedText.contains("dsop") || combinedText.contains("agif") ||
           combinedText.contains("itax") || combinedText.contains("ehcess") {
            return .deductions
        }
        
        // Look for header indicators
        if elements.first?.bounds.minY ?? 0 < 100 || // Near top of page
           elements.contains(where: { $0.isBold }) {
            return .header
        }
        
        // Look for personal info indicators
        if combinedText.contains("name") || combinedText.contains("employee") ||
           combinedText.contains("designation") || combinedText.contains("unit") {
            return .personalInfo
        }
        
        // Look for table indicators
        if elements.count >= 6 && analysisHelper.hasTableLikeStructure(elements: elements) {
            return .table
        }
        
        return .unknown
    }
    
    /// Calculates confidence for section classification
    func calculateSectionConfidence(elements: [PositionalElement], type: SectionType) -> Double {
        var confidence: Double = 0.5
        
        // Size of section affects confidence
        if elements.count >= 5 {
            confidence += 0.2
        } else if elements.count >= 10 {
            confidence += 0.3
        }
        
        // Specific type indicators
        switch type {
        case .earnings:
            confidence += analysisHelper.hasEarningsPattern(elements: elements) ? 0.3 : 0.1
        case .deductions:
            confidence += analysisHelper.hasDeductionsPattern(elements: elements) ? 0.3 : 0.1
        case .header:
            confidence += analysisHelper.isTopOfPage(elements: elements) ? 0.2 : 0.1
        case .personalInfo:
            confidence += analysisHelper.hasPersonalInfoPattern(elements: elements) ? 0.2 : 0.1
        case .table:
            confidence += analysisHelper.hasTableLikeStructure(elements: elements) ? 0.3 : 0.1
        case .unknown:
            confidence -= 0.1
        default:
            break
        }
        
        // Spatial coherence factor
        if analysisHelper.hasGoodSpatialCoherence(elements: elements) {
            confidence += 0.1
        }
        
        return min(1.0, max(0.0, confidence))
    }
    
}
