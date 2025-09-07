import Foundation

/// Protocol-based processor for deductions sections
/// Handles extraction and processing of deductions data from payslip text
class DeductionsSectionProcessor: SectionProcessorProtocol {
    private let abbreviationManager: AbbreviationManager
    private let learningSystem: AbbreviationLearningSystem

    var sectionType: ProcessorSectionType { .deductions }

    init(abbreviationManager: AbbreviationManager, learningSystem: AbbreviationLearningSystem) {
        self.abbreviationManager = abbreviationManager
        self.learningSystem = learningSystem
    }

    /// Extract items from the deductions section text
    /// - Parameter sectionText: The text content of the deductions section
    /// - Returns: Dictionary of extracted deductions items with amounts
    func extractItems(from sectionText: String) -> [String: Double] {
        var items: [String: Double] = [:]

        // Split the text into lines and find content
        let lines = sectionText.components(separatedBy: .newlines)
        var startIndex = 0

        // Find the header line
        for (index, line) in lines.enumerated() {
            if line.contains("Description") && line.contains("Amount") {
                startIndex = index + 1
                break
            }
        }

        // Process content lines
        for lineIndex in startIndex..<lines.count {
            let line = lines[lineIndex].trimmingCharacters(in: .whitespacesAndNewlines)

            // Skip empty lines and headers
            guard !line.isEmpty,
                  !line.hasPrefix("Description"),
                  !line.hasPrefix("Amount") else {
                continue
            }

            // Parse the line
            if let (itemName, amount) = parseLine(line) {
                let normalizedName = itemName.uppercased()

                // Handle special cases
                if normalizedName.contains("TOTAL DEDUCTIONS") {
                    items["TOTAL_DEDUCTIONS"] = amount
                } else {
                    // Map to standard fields or preserve original
                    switch normalizedName {
                    case "DSOP", "DEDUCTION FOR SAVINGS":
                        items["DSOP"] = amount
                    case "AGIF", "ARMY GROUP INSURANCE":
                        items["AGIF"] = amount
                    case "ITAX", "INCOME TAX":
                        items["ITAX"] = amount
                    case "CGHS", "CENTRAL GOVERNMENT HEALTH SCHEME":
                        items["CGHS"] = amount
                    default:
                        items[itemName] = amount
                    }
                }
            }
        }

        return items
    }

    /// Process deductions items and categorize them into the data structure
    /// - Parameters:
    ///   - items: Dictionary of deductions items to process
    ///   - data: The data structure to update with processed deductions
    func processItems(_ items: [String: Double], into data: inout EarningsDeductionsData) {
        for (key, value) in items {
            // Special handling for Total Deductions
            if key.uppercased() == "TOTAL_DEDUCTIONS" {
                data.totalDeductions = value
                continue
            }

            let upperKey = key.uppercased()
            let abbreviationType = abbreviationManager.getType(for: upperKey)

            // Process based on key type
            switch upperKey {
            case "DSOP":
                data.dsop = value
            case "AGIF":
                data.agif = value
            case "ITAX":
                data.itax = value
            case "CGHS":
                data.knownDeductions["CGHS"] = value
            default:
                processByType(upperKey, value: value, type: abbreviationType, into: &data)
            }
        }
    }

    // MARK: - Private Methods

    /// Parse a single line to extract item name and amount
    /// - Parameter line: The line to parse
    /// - Returns: Tuple of item name and amount, or nil if parsing fails
    private func parseLine(_ line: String) -> (String, Double)? {
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

    /// Process an item based on its abbreviation type
    /// - Parameters:
    ///   - key: The item key
    ///   - value: The item value
    ///   - type: The abbreviation type
    ///   - data: The data structure to update
    private func processByType(_ key: String, value: Double, type: AbbreviationManager.AbbreviationType, into data: inout EarningsDeductionsData) {
        switch type {
        case .deduction:
            data.knownDeductions[key] = value
        case .earning:
            data.knownEarnings[key] = value
        case .unknown:
            data.unknownDeductions[key] = value
            learningSystem.trackUnknownAbbreviation(key, context: "deductions", value: value)
            abbreviationManager.trackUnknownAbbreviation(key, value: value)
        }
    }
}
