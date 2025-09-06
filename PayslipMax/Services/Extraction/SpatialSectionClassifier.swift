import Foundation
import CoreGraphics

/// Helper class for classifying document sections based on spatial clustering
/// Extracted from SpatialAnalyzer to maintain 300-line limit compliance
@MainActor
final class SpatialSectionClassifier {
    
    // MARK: - Properties
    
    private let configuration: SpatialAnalysisConfiguration
    
    // MARK: - Initialization
    
    init(configuration: SpatialAnalysisConfiguration) {
        self.configuration = configuration
    }
    
    // MARK: - Section Classification Methods
    
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
        if elements.count >= 6 && hasTableLikeStructure(elements: elements) {
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
            confidence += hasEarningsPattern(elements: elements) ? 0.3 : 0.1
        case .deductions:
            confidence += hasDeductionsPattern(elements: elements) ? 0.3 : 0.1
        case .header:
            confidence += isTopOfPage(elements: elements) ? 0.2 : 0.1
        case .personalInfo:
            confidence += hasPersonalInfoPattern(elements: elements) ? 0.2 : 0.1
        case .table:
            confidence += hasTableLikeStructure(elements: elements) ? 0.3 : 0.1
        case .unknown:
            confidence -= 0.1
        default:
            break
        }
        
        // Spatial coherence factor
        if hasGoodSpatialCoherence(elements: elements) {
            confidence += 0.1
        }
        
        return min(1.0, max(0.0, confidence))
    }
    
    // MARK: - Private Helper Methods
    
    /// Checks if elements have table-like structure
    private func hasTableLikeStructure(elements: [PositionalElement]) -> Bool {
        // Group by approximate Y position
        let rowGroups = elements.groupedByRows(tolerance: 20)
        
        // Should have multiple rows with similar element counts
        let rowElementCounts = rowGroups.values.map { $0.count }
        let avgElementCount = rowElementCounts.reduce(0, +) / rowElementCounts.count
        
        let consistentRows = rowElementCounts.filter { abs($0 - avgElementCount) <= 1 }.count
        
        return rowGroups.count >= 2 && consistentRows >= rowGroups.count / 2
    }
    
    /// Checks if elements have earnings-related patterns
    private func hasEarningsPattern(elements: [PositionalElement]) -> Bool {
        let texts = elements.map { $0.text.uppercased() }
        let earningsKeywords = ["BPAY", "DA", "MSP", "BASIC", "ALLOWANCE", "RH12", "TPTA"]
        
        return earningsKeywords.contains { keyword in
            texts.contains { $0.contains(keyword) }
        }
    }
    
    /// Checks if elements have deductions-related patterns
    private func hasDeductionsPattern(elements: [PositionalElement]) -> Bool {
        let texts = elements.map { $0.text.uppercased() }
        let deductionsKeywords = ["DSOP", "AGIF", "ITAX", "TAX", "DEDUCTION", "EHCESS"]
        
        return deductionsKeywords.contains { keyword in
            texts.contains { $0.contains(keyword) }
        }
    }
    
    /// Checks if elements are near the top of the page (header region)
    private func isTopOfPage(elements: [PositionalElement]) -> Bool {
        let avgY = elements.reduce(0) { $0 + $1.center.y } / CGFloat(elements.count)
        return avgY < 150 // Top 150 points of page
    }
    
    /// Checks if elements have personal information patterns
    private func hasPersonalInfoPattern(elements: [PositionalElement]) -> Bool {
        let texts = elements.map { $0.text.uppercased() }
        let personalKeywords = ["NAME", "EMPLOYEE", "DESIGNATION", "UNIT", "SERVICE", "RANK"]
        
        return personalKeywords.contains { keyword in
            texts.contains { $0.contains(keyword) }
        }
    }
    
    /// Checks if elements have good spatial coherence (close together)
    private func hasGoodSpatialCoherence(elements: [PositionalElement]) -> Bool {
        guard elements.count > 1 else { return true }
        
        // Calculate bounding box for all elements
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
        
        let boundingBox = CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
        let density = Double(elements.count) / Double(boundingBox.width * boundingBox.height)
        
        // Good coherence if elements are reasonably dense
        return density > 0.001
    }
}
