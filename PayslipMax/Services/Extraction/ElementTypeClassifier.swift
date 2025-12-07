import Foundation
import CoreGraphics
/// Service responsible for classifying text elements into types
/// Uses pattern recognition and context analysis to determine element types
/// Specialized for military payslip parsing patterns
@MainActor
final class ElementTypeClassifier {
    // MARK: - Properties
    /// Whether the classifier has been initialized
    private var isInitialized: Bool = false

    /// Pattern arrays for element classification
    private let headerPatterns = [
        #"^(EARNINGS|DEDUCTIONS|ALLOWANCES|LEAVE|PAY|STATEMENT).*"#,
        #"^[A-Z\s]{10,}$"#  // All caps, long text
    ]
    private let valuePatterns = [
        #"^\$?[\d,]+\.?\d*$"#,  // Currency/numbers
        #"^[\d,]+\.?\d*$"#,     // Pure numbers
        #"^\d{1,2}/\d{1,2}/\d{2,4}$"#  // Dates
    ]
    private let labelPatterns = [
        #".+:$"#,  // Ends with colon
        #"^[A-Z\s]+$"#  // All caps (but not too long)
    ]

    // MARK: - Initialization
    /// Initializes the element type classifier
    init() {
        // Classifier is ready to use immediately
    }

    /// Initializes the classifier (async for protocol compliance)
    func initialize() async throws {
        isInitialized = true
    }

    // MARK: - Classification Methods

    /// Classifies a text element based on content and context
    /// - Parameters:
    ///   - text: The text content to classify
    ///   - bounds: The element's bounding rectangle
    ///   - context: Surrounding elements for context analysis
    /// - Returns: Tuple of element type and confidence score
    func classify(
        text: String,
        bounds: CGRect,
        context: [PositionalElement]
    ) async -> (type: ElementType, confidence: Double) {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)

        // Quick return for empty text
        guard !trimmedText.isEmpty else {
            return (.unknown, 0.0)
        }

        // Note: Military-specific patterns have been moved to UniversalPayslipProcessor
        // as part of the Universal Parser migration
        // Check for headers (typically larger, all caps, centered)
        if let headerResult = classifyAsHeader(trimmedText, bounds: bounds, context: context) {
            return headerResult
        }

        // Check for values (numeric, currency)
        if let valueResult = classifyAsValue(trimmedText, bounds: bounds, context: context) {
            return valueResult
        }

        // Check for labels (field names, descriptions)
        if let labelResult = classifyAsLabel(trimmedText, bounds: bounds, context: context) {
            return labelResult
        }

        // Check for table cells based on position
        if let tableCellResult = classifyAsTableCell(trimmedText, bounds: bounds, context: context) {
            return tableCellResult
        }

        // Default to unknown with low confidence
        return (.unknown, 0.1)
    }

    // MARK: - Specific Classification Methods

    /// Attempts to classify text as a header
    private func classifyAsHeader(
        _ text: String,
        bounds: CGRect,
        context: [PositionalElement]
    ) -> (ElementType, Double)? {
        var confidence: Double = 0.0

        // Check header patterns
        for pattern in headerPatterns {
            if text.range(of: pattern, options: .regularExpression) != nil {
                confidence = max(confidence, 0.9)
            }
        }

        // Check if text is all uppercase and multiple words
        if text.uppercased() == text && text.contains(" ") && text.count > 5 {
            confidence = max(confidence, 0.7)
        }

        // Headers are typically larger or positioned at top of regions
        if bounds.height > 20 { // Larger text
            confidence += 0.2
        }

        // Headers are often centered or near the top
        let pageWidth: CGFloat = 600 // Approximate A4 width in points
        if abs(bounds.midX - pageWidth/2) < 100 { // Roughly centered
            confidence += 0.1
        }

        return confidence > 0.5 ? (.header, min(confidence, 1.0)) : nil
    }

    /// Attempts to classify text as a value
    private func classifyAsValue(
        _ text: String,
        bounds: CGRect,
        context: [PositionalElement]
    ) -> (ElementType, Double)? {
        var confidence: Double = 0.0

        // Check value patterns
        for pattern in valuePatterns {
            if text.range(of: pattern, options: .regularExpression) != nil {
                confidence = max(confidence, 0.85)
            }
        }

        // Check if it's a simple number
        if Double(text.replacingOccurrences(of: ",", with: "")) != nil {
            confidence = max(confidence, 0.8)
        }

        // Values are often to the right of labels
        let labelsToTheLeft = context.filter { element in
            element.type == .label &&
            element.bounds.maxX < bounds.minX &&
            abs(element.center.y - bounds.midY) < 20
        }

        if !labelsToTheLeft.isEmpty {
            confidence += 0.2
        }

        // Values in military payslips are often right-aligned in columns
        let rightAlignedElements = context.filter { element in
            abs(element.bounds.maxX - bounds.maxX) < 10 &&
            element.bounds != bounds
        }

        if rightAlignedElements.count >= 2 {
            confidence += 0.15
        }

        return confidence > 0.5 ? (.value, min(confidence, 1.0)) : nil
    }

    /// Attempts to classify text as a label
    private func classifyAsLabel(
        _ text: String,
        bounds: CGRect,
        context: [PositionalElement]
    ) -> (ElementType, Double)? {
        var confidence: Double = 0.0

        // Check label patterns
        for pattern in labelPatterns {
            if text.range(of: pattern, options: .regularExpression) != nil {
                confidence = max(confidence, 0.8)
            }
        }

        // Check if it ends with a colon
        if text.hasSuffix(":") {
            confidence = max(confidence, 0.9)
        }

        // Labels are often followed by values to the right
        let valuesToTheRight = context.filter { element in
            element.type == .value &&
            element.bounds.minX > bounds.maxX &&
            abs(element.center.y - bounds.midY) < 20
        }

        if !valuesToTheRight.isEmpty {
            confidence += 0.3
        }

        // Military codes are often labels
        let militaryCodePattern = #"^[A-Z]{2,6}(\s*\([A-Z0-9]+\))?$"#
        if text.range(of: militaryCodePattern, options: .regularExpression) != nil {
            confidence = max(confidence, 0.85)
        }

        // Labels are typically left-aligned in columns
        let leftAlignedElements = context.filter { element in
            abs(element.bounds.minX - bounds.minX) < 10 &&
            element.bounds != bounds
        }

        if leftAlignedElements.count >= 2 {
            confidence += 0.1
        }

        return confidence > 0.5 ? (.label, min(confidence, 1.0)) : nil
    }

    /// Attempts to classify text as a table cell
    private func classifyAsTableCell(
        _ text: String,
        bounds: CGRect,
        context: [PositionalElement]
    ) -> (ElementType, Double)? {
        // Look for elements that are aligned in both rows and columns
        let horizontallyAligned = context.filter { element in
            abs(element.center.y - bounds.midY) < 15 &&
            element.bounds != bounds
        }

        let verticallyAligned = context.filter { element in
            abs(element.center.x - bounds.midX) < 15 &&
            element.bounds != bounds
        }

        // If element has both horizontal and vertical neighbors, likely a table cell
        if horizontallyAligned.count >= 1 && verticallyAligned.count >= 1 {
            return (.tableCell, 0.7)
        }

        // If element is in a grid-like pattern
        if horizontallyAligned.count >= 2 || verticallyAligned.count >= 2 {
            return (.tableCell, 0.6)
        }

        return nil
    }

    // MARK: - Utility Methods

    /// Checks if text matches any pattern in the given array
    private func matchesAnyPattern(_ text: String, patterns: [String]) -> Bool {
        for pattern in patterns {
            if text.range(of: pattern, options: .regularExpression) != nil {
                return true
            }
        }
        return false
    }

    /// Calculates the confidence boost based on spatial context
    private func calculateSpatialConfidence(
        bounds: CGRect,
        context: [PositionalElement],
        expectedType: ElementType
    ) -> Double {
        var confidence: Double = 0.0

        // Check for similar elements nearby
        let similarElements = context.filter { $0.type == expectedType }
        let nearbyElements = similarElements.filter { element in
            let distance = sqrt(
                pow(element.center.x - bounds.midX, 2) +
                pow(element.center.y - bounds.midY, 2)
            )
            return distance < 100 // Within 100 points
        }

        if !nearbyElements.isEmpty {
            confidence += min(0.2, Double(nearbyElements.count) * 0.05)
        }

        return confidence
    }
}
