import Foundation

/// Result of splitting JCO/OR payslip text into logical sections
struct JCOORSplitResult {
    /// Text from the Credits (left) column -- earnings line items
    let creditText: String
    /// Text from the Debits (right) column -- deduction line items
    let debitText: String
    /// Summary text containing totals (TOTAL CREDITS, TOTAL DEBITS, bank amount)
    let summaryText: String
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

    /// Splits the text into credit, debit, and summary sections.
    /// Returns nil if the text does not match JCO/OR layout.
    func split(_ text: String) -> JCOORSplitResult? {
        guard isJCOORLayout(text) else { return nil }

        let bodyText = extractBodyAfterMarker(text)
        let (lineItems, summary) = separateTotalsFromItems(bodyText)

        let creditLines = extractCreditLines(from: lineItems)
        let debitLines = extractDebitLines(from: lineItems)

        return JCOORSplitResult(
            creditText: creditLines.joined(separator: "\n"),
            debitText: debitLines.joined(separator: "\n"),
            summaryText: summary
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

    /// Known credit-side (earnings) pay codes for classification
    private static let creditCodes: Set<String> = [
        "BPAY", "DA", "MSP", "TPAL", "HRA", "HRALF", "LRA", "PMHA",
        "CLPAY", "CL PAY", "GSPAY", "RISK", "RUMCIG", "RH11", "RH12",
        "BAND PAY", "BASIC PAY", "DEARNESS ALLOWANCE"
    ]

    /// Known debit-side (deduction) pay codes for classification
    private static let debitCodes: Set<String> = [
        "DSOP", "AGIF", "PLI", "ITAX", "INCOME TAX", "CGEIS", "CGHS",
        "ECHS", "AFPF", "GPF", "NPS", "LOAN", "LOANS", "E-TICKETING"
    ]

    private func extractCreditLines(from text: String) -> [String] {
        classifyLines(from: text, matchingCodes: Self.creditCodes)
    }

    private func extractDebitLines(from text: String) -> [String] {
        classifyLines(from: text, matchingCodes: Self.debitCodes)
    }

    /// Classifies each line by checking if it contains any of the target pay codes
    private func classifyLines(from text: String, matchingCodes: Set<String>) -> [String] {
        let lines = text.components(separatedBy: .newlines)
        var matched: [String] = []

        for line in lines {
            let upper = line.uppercased()
            if matchingCodes.contains(where: { upper.contains($0) }) {
                matched.append(line)
            }
        }
        return matched
    }
}
