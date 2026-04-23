import Foundation

/// Numeric thresholds used across the scan and OCR pipeline.
/// Extracted to eliminate magic numbers and provide a single place to tune values.
enum ScanThreshold {
    /// Minimum number of digit characters required in OCR text to attempt payslip parsing
    static let minimumDigitCount = 10
    /// Top-band crop ratio used for partial-image OCR pass (keeps header and totals)
    static let topBandHeightRatio: CGFloat = 0.7
    /// Narrower crop used for the LLM-only path
    static let narrowTopBandHeightRatio: CGFloat = 0.45
}
