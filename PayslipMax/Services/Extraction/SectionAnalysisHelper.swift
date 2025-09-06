import Foundation
import CoreGraphics

/// Helper service for section analysis operations
/// Extracted from SpatialSectionClassifier to maintain 300-line limit compliance
final class SectionAnalysisHelper {
    
    // MARK: - Public Interface
    
    /// Checks if elements have table-like structure
    /// - Parameter elements: Elements to analyze
    /// - Returns: True if elements form a table structure
    func hasTableLikeStructure(elements: [PositionalElement]) -> Bool {
        // Group by approximate Y position
        let rowGroups = elements.groupedByRows(tolerance: 20)
        
        // Should have multiple rows with similar element counts
        let rowElementCounts = rowGroups.values.map { $0.count }
        let avgElementCount = rowElementCounts.reduce(0, +) / rowElementCounts.count
        
        let consistentRows = rowElementCounts.filter { abs($0 - avgElementCount) <= 1 }.count
        
        return rowGroups.count >= 2 && consistentRows >= rowGroups.count / 2
    }
    
    /// Checks if elements have earnings-related patterns
    /// - Parameter elements: Elements to analyze
    /// - Returns: True if elements contain earnings patterns
    func hasEarningsPattern(elements: [PositionalElement]) -> Bool {
        let texts = elements.map { $0.text.uppercased() }
        let earningsKeywords = ["BPAY", "DA", "MSP", "BASIC", "ALLOWANCE", "RH12", "TPTA"]
        
        return earningsKeywords.contains { keyword in
            texts.contains { $0.contains(keyword) }
        }
    }
    
    /// Checks if elements have deductions-related patterns
    /// - Parameter elements: Elements to analyze
    /// - Returns: True if elements contain deductions patterns
    func hasDeductionsPattern(elements: [PositionalElement]) -> Bool {
        let texts = elements.map { $0.text.uppercased() }
        let deductionsKeywords = ["DSOP", "AGIF", "ITAX", "TAX", "DEDUCTION", "EHCESS"]
        
        return deductionsKeywords.contains { keyword in
            texts.contains { $0.contains(keyword) }
        }
    }
    
    /// Checks if elements are near the top of the page (header region)
    /// - Parameter elements: Elements to analyze
    /// - Returns: True if elements are in header region
    func isTopOfPage(elements: [PositionalElement]) -> Bool {
        let avgY = elements.reduce(0) { $0 + $1.center.y } / CGFloat(elements.count)
        return avgY < 150 // Top 150 points of page
    }
    
    /// Checks if elements have personal information patterns
    /// - Parameter elements: Elements to analyze
    /// - Returns: True if elements contain personal info patterns
    func hasPersonalInfoPattern(elements: [PositionalElement]) -> Bool {
        let texts = elements.map { $0.text.uppercased() }
        let personalKeywords = ["NAME", "EMPLOYEE", "DESIGNATION", "UNIT", "SERVICE", "RANK"]
        
        return personalKeywords.contains { keyword in
            texts.contains { $0.contains(keyword) }
        }
    }
    
    /// Checks if elements have good spatial coherence (close together)
    /// - Parameter elements: Elements to analyze
    /// - Returns: True if elements are spatially coherent
    func hasGoodSpatialCoherence(elements: [PositionalElement]) -> Bool {
        guard elements.count > 1 else { return true }
        
        // Calculate bounding box for all elements
        let boundingBox = elements.boundingBox()
        let density = Double(elements.count) / Double(boundingBox.width * boundingBox.height)
        
        // Good coherence if elements are reasonably dense
        return density > 0.001
    }
    
    /// Checks if an element contains financial data
    /// - Parameter element: Element to check
    /// - Returns: True if element contains financial data
    func isFinancialElement(_ element: PositionalElement) -> Bool {
        let text = element.text.uppercased()
        let financialKeywords = ["BPAY", "DA", "MSP", "RH12", "TPTA", "TPTADA", 
                               "DSOP", "AGIF", "ITAX", "EHCESS", "BASIC", "ALLOWANCE"]
        
        return financialKeywords.contains { keyword in
            text.contains(keyword)
        } || text.range(of: "\\d+", options: .regularExpression) != nil
    }
    
    /// Classifies an element by its content into earnings, deductions, or unknown
    /// - Parameter element: Element to classify
    /// - Returns: Classification type for the element
    func classifyElementByContent(_ element: PositionalElement) -> FinancialElementType {
        let text = element.text.uppercased()
        
        // Check for earnings indicators
        let earningsKeywords = ["BPAY", "DA", "MSP", "RH12", "TPTA", "TPTADA", "BASIC", "DEARNESS", "MEDICAL"]
        if earningsKeywords.contains(where: { text.contains($0) }) {
            return .earnings
        }
        
        // Check for deductions indicators
        let deductionsKeywords = ["DSOP", "AGIF", "ITAX", "EHCESS", "TAX", "DEDUCTION", "PROVIDENT"]
        if deductionsKeywords.contains(where: { text.contains($0) }) {
            return .deductions
        }
        
        return .unknown
    }
    
    /// Calculates confidence for section classification
    /// - Parameters:
    ///   - earningsElements: Elements classified as earnings
    ///   - deductionsElements: Elements classified as deductions
    ///   - otherElements: Elements not classified
    /// - Returns: Confidence score (0.0 to 1.0)
    func calculateSectionClassificationConfidence(
        earningsElements: [PositionalElement],
        deductionsElements: [PositionalElement],
        otherElements: [PositionalElement]
    ) -> Double {
        
        let totalElements = earningsElements.count + deductionsElements.count + otherElements.count
        guard totalElements > 0 else { return 0.0 }
        
        // Base confidence from classification ratio
        let classifiedElements = earningsElements.count + deductionsElements.count
        let classificationRatio = Double(classifiedElements) / Double(totalElements)
        
        // Bonus for balanced sections
        let balanceBonus: Double
        if earningsElements.count > 0 && deductionsElements.count > 0 {
            let ratio = Double(min(earningsElements.count, deductionsElements.count)) / 
                       Double(max(earningsElements.count, deductionsElements.count))
            balanceBonus = ratio * 0.2
        } else {
            balanceBonus = 0.0
        }
        
        // Penalty for too many unclassified elements
        let unclassifiedPenalty = Double(otherElements.count) / Double(totalElements) * 0.3
        
        let confidence = (classificationRatio * 0.8) + balanceBonus - unclassifiedPenalty
        
        return min(1.0, max(0.0, confidence))
    }
}
