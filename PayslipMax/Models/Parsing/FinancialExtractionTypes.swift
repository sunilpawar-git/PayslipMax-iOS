import Foundation

/// Result of financial data extraction with contextual validation
struct FinancialExtractionResult: Codable {
    /// Extracted earnings data
    let earnings: [String: Double]
    /// Extracted deductions data
    let deductions: [String: Double]
    /// All contextual matches found
    let matchCount: Int
    /// Overall confidence score
    let confidence: Double
    /// Extraction timestamp
    let extractedAt: Date
    
    /// Initializes a financial extraction result
    /// - Parameters:
    ///   - earnings: Earnings data
    ///   - deductions: Deductions data
    ///   - matches: Contextual matches
    ///   - confidence: Overall confidence
    init(
        earnings: [String: Double],
        deductions: [String: Double],
        matches: [ContextualMatch],
        confidence: Double
    ) {
        self.earnings = earnings
        self.deductions = deductions
        self.matchCount = matches.count
        self.confidence = min(1.0, max(0.0, confidence))
        self.extractedAt = Date()
    }
    
    // MARK: - Convenience Properties
    
    /// Total earnings amount
    var totalEarnings: Double {
        return earnings.values.reduce(0, +)
    }
    
    /// Total deductions amount
    var totalDeductions: Double {
        return deductions.values.reduce(0, +)
    }
    
    /// Net pay (earnings minus deductions)
    var netPay: Double {
        return totalEarnings - totalDeductions
    }
    
    /// Total number of financial items extracted
    var totalItemCount: Int {
        return earnings.count + deductions.count
    }
    
    /// Whether this extraction has meaningful data
    var hasSignificantData: Bool {
        return totalItemCount >= 3 && confidence >= 0.5
    }
    
    /// Quality assessment of the extraction
    var qualityAssessment: ExtractionQuality {
        switch (confidence, totalItemCount) {
        case (0.8..., 5...):
            return .excellent
        case (0.6..., 3...):
            return .good
        case (0.4..., 2...):
            return .fair
        case (0.2..., 1...):
            return .poor
        default:
            return .failed
        }
    }
}

/// Quality levels for financial extraction
enum ExtractionQuality: String, Codable, CaseIterable {
    /// Excellent extraction (high confidence, many items)
    case excellent = "Excellent"
    /// Good extraction (decent confidence, some items)
    case good = "Good"
    /// Fair extraction (moderate confidence, few items)
    case fair = "Fair"
    /// Poor extraction (low confidence, minimal items)
    case poor = "Poor"
    /// Failed extraction (very low confidence or no items)
    case failed = "Failed"

    var description: String {
        return rawValue
    }
}
