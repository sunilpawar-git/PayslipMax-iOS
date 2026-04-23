import Foundation

/// Result of splitting JCO/OR payslip text into logical sections
struct JCOORSplitResult {
    /// Text from the Credits (left) column -- earnings line items
    let creditText: String
    /// Text from the Debits (right) column -- deduction line items
    let debitText: String
    /// Summary text containing totals (TOTAL CREDITS, TOTAL DEBITS, bank amount)
    let summaryText: String
    /// Lines that could not be classified as credit or debit (passed to regex engine unmodified)
    let miscText: String
}

/// Splits flat PDFKit-extracted text from JCO/OR payslips into
/// credit (earnings) and debit (deductions) sections using structural markers.
final class JCOORTextSectionSplitter {

    private let layoutMarkers: [String] = [
        "ACCOUNTS AT A GLANCE",
        "एक नज़र में खाते"
    ]

    /// Keywords that mark the start of the summary/totals block (SSOT for detection + splitting)
    private static let summaryKeywords: [(english: String, hindi: String)] = [
        ("TOTAL CREDITS", "कुल जमा"),
        ("TOTAL DEBITS", "कुल नामे")
    ]

    /// Checks if the text appears to follow a JCO/OR tabular layout
    func isJCOORLayout(_ text: String) -> Bool {
        let upper = text.uppercased()

        for marker in layoutMarkers where upper.contains(marker.uppercased()) {
            return true
        }

        return Self.summaryKeywords.allSatisfy { keyword in
            upper.contains(keyword.english) || text.contains(keyword.hindi)
        }
    }

    /// Splits the text into credit, debit, misc, and summary sections.
    /// Returns nil if the text does not match JCO/OR layout.
    func split(_ text: String) -> JCOORSplitResult? {
        guard isJCOORLayout(text) else { return nil }

        let bodyText = extractBodyAfterMarker(text)
        let (lineItems, summary) = separateTotalsFromItems(bodyText)

        let classified = classifyAllLines(from: lineItems)

        return JCOORSplitResult(
            creditText: classified.credits.joined(separator: "\n"),
            debitText: classified.debits.joined(separator: "\n"),
            summaryText: summary,
            miscText: classified.misc.joined(separator: "\n")
        )
    }

    /// Extracts text after the "ACCOUNTS AT A GLANCE" marker, or returns full text
    private func extractBodyAfterMarker(_ text: String) -> String {
        for marker in layoutMarkers {
            if let range = text.range(
                of: marker,
                options: .caseInsensitive
            ) {
                return String(text[range.upperBound...]).trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
        return text
    }

    /// Separates totals/summary lines from individual line items
    private func separateTotalsFromItems(_ text: String) -> (items: String, summary: String) {
        let lines = text.components(separatedBy: .newlines)
        var itemLines: [String] = []
        var summaryLines: [String] = []
        var inSummary = false

        for line in lines {
            let upper = line.uppercased().trimmingCharacters(in: .whitespaces)
            let isSummaryLine = Self.summaryKeywords.contains { keyword in
                upper.contains(keyword.english) || line.contains(keyword.hindi)
            } || upper.contains("AMOUNT CREDITED")

            if isSummaryLine {
                inSummary = true
            }

            if inSummary {
                summaryLines.append(line)
            } else if !isHeaderLine(upper) {
                itemLines.append(line)
            }
        }

        return (
            items: itemLines.joined(separator: "\n"),
            summary: summaryLines.joined(separator: "\n")
        )
    }

    private func isHeaderLine(_ upper: String) -> Bool {
        let headerKeywords = ["CREDITS", "DEBITS", "जमा", "नामे"]
        let trimmed = upper.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return true }

        let words = trimmed.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
        return words.count <= 3 && headerKeywords.contains(where: { trimmed.contains($0) })
    }

    // Pay code sets are intentionally not duplicated here; they live in PayCodeCatalogue (SSOT).

    private struct ClassifiedLines {
        let credits: [String]
        let debits: [String]
        let misc: [String]
    }

    /// Classifies all item lines.
    /// A line may appear in BOTH credits and debits when it contains both types
    /// (common in two-column PDFKit output where both sides land on one line).
    /// Lines matching neither are preserved in misc so the regex engine can still find them.
    private func classifyAllLines(from text: String) -> ClassifiedLines {
        let lines = text.components(separatedBy: .newlines)
        var credits: [String] = []
        var debits: [String] = []
        var misc: [String] = []

        for line in lines {
            let upper = line.uppercased()
            let trimmed = upper.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty else { continue }

            let isCredit = PayCodeCatalogue.isCredit(upper)
            let isDebit = PayCodeCatalogue.isDebit(upper)

            if isCredit { credits.append(line) }
            if isDebit { debits.append(line) }
            if !isCredit && !isDebit { misc.append(line) }
        }
        return ClassifiedLines(credits: credits, debits: debits, misc: misc)
    }
}
