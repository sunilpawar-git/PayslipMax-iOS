import Foundation

/// Utility class for parsing payslip sections
/// Contains helper methods for extracting and processing section data
class SectionParserHelper {

    /// Extract a section from the full payslip text based on section type
    /// - Parameters:
    ///   - pageText: The full payslip text
    ///   - sectionType: The type of section to extract
    /// - Returns: The extracted section text, or nil if not found
    static func extractSection(from pageText: String, sectionType: ProcessorSectionType) -> String? {
        let pattern = sectionType.headerPattern

        // Find the section
        guard let sectionRange = pageText.range(of: pattern, options: .regularExpression) else {
            return nil
        }

        let sectionStart = pageText.index(after: sectionRange.upperBound)

        // Find the end of the section (either the start of the next section or end of text)
        var sectionEnd = pageText.endIndex
        let nextSectionName = sectionType == .earnings ? "DEDUCTIONS" : nil

        if let nextSectionName = nextSectionName,
           let nextRange = pageText.range(of: nextSectionName, options: .regularExpression) {
            sectionEnd = nextRange.lowerBound
        }

        // Extract the section text
        guard sectionStart < sectionEnd else { return nil }

        return String(pageText[sectionStart..<sectionEnd])
    }

    /// Extract the total value from a section (e.g., Gross Pay, Total Deductions)
    /// - Parameters:
    ///   - sectionText: The section text to search
    ///   - totalPattern: The pattern to match for the total (e.g., "GROSS PAY", "TOTAL DEDUCTIONS")
    /// - Returns: The extracted total value, or nil if not found
    static func extractTotalValue(from sectionText: String, totalPattern: String) -> Double? {
        let lines = sectionText.split(separator: "\n")

        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmedLine.uppercased().contains(totalPattern) {
                let components = trimmedLine.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
                if let amountStr = components.last,
                   let amount = Double(amountStr.replacingOccurrences(of: ",", with: "")) {
                    return amount
                }
            }
        }

        return nil
    }

    /// Clean and normalize section text for processing
    /// - Parameter sectionText: The raw section text
    /// - Returns: Cleaned and normalized text
    static func normalizeSectionText(_ sectionText: String) -> String {
        let lines = sectionText.components(separatedBy: .newlines)
        let cleanedLines = lines.map { line in
            line.trimmingCharacters(in: .whitespacesAndNewlines)
        }.filter { !$0.isEmpty }

        return cleanedLines.joined(separator: "\n")
    }

    /// Find the content start index in a section (after headers)
    /// - Parameter lines: Array of lines in the section
    /// - Returns: The index where content starts, or 0 if not found
    static func findContentStartIndex(in lines: [String]) -> Int {
        for (index, line) in lines.enumerated() {
            if line.contains("Description") && line.contains("Amount") {
                return index + 1
            }
        }
        return 0
    }

    /// Check if a line should be skipped during parsing
    /// - Parameter line: The line to check
    /// - Returns: True if the line should be skipped
    static func shouldSkipLine(_ line: String) -> Bool {
        let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedLine.isEmpty ||
               trimmedLine.hasPrefix("Description") ||
               trimmedLine.hasPrefix("Amount")
    }

    /// Parse a line to extract item name and amount
    /// - Parameter line: The line to parse
    /// - Returns: Tuple of item name and amount, or nil if parsing fails
    static func parseLine(_ line: String) -> (String, Double)? {
        let components = line.components(separatedBy: .whitespaces).filter { !$0.isEmpty }

        // Need at least 2 components (name and amount)
        guard components.count >= 2,
              let lastComponent = components.last,
              let amount = Double(lastComponent.replacingOccurrences(of: ",", with: "")) else {
            return nil
        }

        // Everything except the last component is the item name
        let nameComponents = components.dropLast()
        let itemName = nameComponents.joined(separator: " ").trimmingCharacters(in: .whitespacesAndNewlines)

        guard !itemName.isEmpty else { return nil }

        return (itemName, amount)
    }

    /// Normalize item names for consistent processing
    /// - Parameter itemName: The raw item name
    /// - Returns: Normalized item name
    static func normalizeItemName(_ itemName: String) -> String {
        return itemName.uppercased().trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Check if an item name represents a total value
    /// - Parameters:
    ///   - itemName: The item name to check
    ///   - sectionType: The section type context
    /// - Returns: True if the item represents a total
    static func isTotalItem(_ itemName: String, sectionType: ProcessorSectionType) -> Bool {
        let normalizedName = normalizeItemName(itemName)
        switch sectionType {
        case .earnings:
            return normalizedName.contains("GROSS PAY")
        case .deductions:
            return normalizedName.contains("TOTAL DEDUCTIONS")
        }
    }
}
