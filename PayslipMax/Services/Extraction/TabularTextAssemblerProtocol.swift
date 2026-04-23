import Foundation
import CoreGraphics

// MARK: - Assembled Column Result

/// Represents text content from a single column of a tabular payslip,
/// preserving line-by-line ordering for downstream regex parsing.
struct AssembledColumn: Sendable, Equatable {
    /// The column's text lines joined with newlines, suitable for regex parsing
    let text: String

    /// The normalized x-range of this column (0.0–1.0)
    let xRange: ClosedRange<CGFloat>

    /// Number of text blocks that contributed to this column
    let blockCount: Int
}

// MARK: - Tabular Assembly Result

/// The result of assembling OCR text blocks into a two-column tabular structure,
/// matching the Credits (left) and Debits (right) layout of military payslips.
struct TabularAssemblyResult: Sendable, Equatable {
    /// Left column text (Credits / Earnings in military payslips)
    let leftColumn: AssembledColumn

    /// Right column text (Debits / Deductions in military payslips)
    let rightColumn: AssembledColumn

    /// Full-width text that spans both columns (headers, totals, etc.)
    let fullWidthText: String

    /// The detected midpoint dividing left and right columns (0.0–1.0)
    let columnDivider: CGFloat

    /// Whether the assembly detected a clear two-column structure
    let isTabularLayoutDetected: Bool

    /// Confidence in the column split quality (0.0–1.0).
    /// Low values indicate that one side has very few blocks or the gap was marginal.
    let columnSplitConfidence: Double
}

// MARK: - Protocol

/// Assembles positioned OCR text blocks into column-separated text streams.
/// Designed for military JCO/OR payslips with "ACCOUNTS AT A GLANCE"
/// two-column layout (Credits left, Debits right).
///
/// The assembler uses the horizontal (x) position of each text block to
/// classify it as belonging to the left column, right column, or spanning both.
protocol TabularTextAssemblerProtocol: Sendable {
    /// Assembles OCR text blocks into a two-column structure.
    /// Always returns a result; callers should check `isTabularLayoutDetected`
    /// and `columnSplitConfidence` to decide how to use the output.
    func assemble(from ocrResult: StructuredOCRResult) -> TabularAssemblyResult
}
