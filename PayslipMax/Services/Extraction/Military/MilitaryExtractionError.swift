import Foundation

/// Custom error types for military payslip extraction
///
/// These specialized error types help identify and handle specific failure modes
/// that may occur when extracting data from military payslips.
enum MilitaryExtractionError: Error {
    /// The provided payslip is not in a recognized military format
    ///
    /// This error indicates that while a document was passed for military payslip extraction,
    /// it lacks the expected structure, markers, or terminology that would identify it as a
    /// legitimate military payslip. This could happen when a civilian payslip or other document
    /// is mistakenly processed by the military extractor.
    case invalidFormat
    
    /// Not enough data was extracted to create a valid PayslipItem
    ///
    /// This error occurs when essential fields (month, year, name, or financial totals)
    /// cannot be located in the document. This might indicate a damaged document, poor OCR quality,
    /// or a payslip format that's significantly different from expected patterns.
    case insufficientData
    
    /// General extraction failure
    ///
    /// This error represents other extraction failures not covered by more specific error types.
    /// It may occur due to unexpected format variations, processing errors, or other technical issues.
    case extractionFailed
} 