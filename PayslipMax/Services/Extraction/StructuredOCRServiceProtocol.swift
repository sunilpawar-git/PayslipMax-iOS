import Foundation
import CoreGraphics

// MARK: - OCR Text Block Model

/// A single recognized text block with its spatial position on the page.
/// Used by position-aware OCR to enable column detection in tabular payslips.
struct OCRTextBlock: Sendable, Equatable {
    /// The recognized text content (sanitized, no PII stored beyond current session)
    let text: String

    /// Normalized bounding box in Vision coordinates (origin bottom-left, 0.0–1.0)
    let boundingBox: CGRect

    /// Recognition confidence from Apple Vision (0.0–1.0)
    let confidence: Float

    /// Horizontal center of the bounding box (convenience for column classification)
    var centerX: CGFloat { boundingBox.midX }

    /// Vertical center of the bounding box (convenience for row ordering)
    var centerY: CGFloat { boundingBox.midY }
}

// MARK: - Structured OCR Result

/// The result of a structured OCR operation containing all recognized text blocks
/// with their spatial positions on the page.
struct StructuredOCRResult: Sendable, Equatable {
    /// All recognized text blocks, sorted top-to-bottom by Y position
    let blocks: [OCRTextBlock]

    /// Overall recognition confidence (average of all block confidences)
    var averageConfidence: Float {
        guard !blocks.isEmpty else { return 0 }
        return blocks.reduce(Float(0)) { $0 + $1.confidence } / Float(blocks.count)
    }

    /// Whether the result contains enough data for parsing
    var hasMinimumContent: Bool {
        blocks.count >= 3
    }
}

// MARK: - Sorting Utility

extension Array where Element == OCRTextBlock {
    /// Sorts blocks top-to-bottom (highest Y first in Vision coordinates, origin bottom-left).
    func sortedTopToBottom() -> [OCRTextBlock] {
        sorted { $0.boundingBox.origin.y > $1.boundingBox.origin.y }
    }
}

// MARK: - Error

/// Errors surfaced by StructuredOCRServiceProtocol implementations.
/// Distinguishes between a Vision framework error and a page with no text.
enum StructuredOCRError: Error, Equatable, Sendable {
    /// Vision ran successfully but found no text blocks at or above confidence threshold
    case noTextFound
    /// A Vision framework error occurred; the associated value is the error description
    case visionError(String)
}

// MARK: - Protocol

/// Protocol for position-aware OCR that returns text blocks with bounding box information.
/// Unlike flat OCR (which returns a single concatenated string), this preserves spatial
/// positions so downstream consumers can distinguish table columns (Credits vs Debits).
///
/// Security: Implementations must NOT persist or log raw OCR text containing PII.
/// All OCR results are transient and exist only during the parsing session.
protocol StructuredOCRServiceProtocol: Sendable {
    /// Performs OCR on an image and returns text blocks with spatial positions.
    func recognizeText(from imageData: Data) async -> StructuredOCRResult?

    /// Performs OCR on a CGImage and returns text blocks with spatial positions.
    func recognizeText(from cgImage: CGImage) async -> StructuredOCRResult?

    /// Detailed variant that distinguishes Vision errors from empty pages.
    func recognizeTextDetailed(from cgImage: CGImage) async -> Result<StructuredOCRResult, StructuredOCRError>
}
