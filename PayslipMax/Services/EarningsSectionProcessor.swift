import Foundation

/// Protocol-based processor for earnings sections
/// Handles extraction and processing of earnings data from payslip text
class EarningsSectionProcessor: SectionProcessorProtocol {
    private let abbreviationManager: AbbreviationManager
    private let learningSystem: AbbreviationLearningSystem

    var sectionType: ProcessorSectionType { .earnings }

    init(abbreviationManager: AbbreviationManager, learningSystem: AbbreviationLearningSystem) {
        self.abbreviationManager = abbreviationManager
        self.learningSystem = learningSystem
    }

    /// Extract items from the earnings section text
    /// - Parameter sectionText: The text content of the earnings section
    /// - Returns: Dictionary of extracted earnings items with amounts
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
                if normalizedName.contains("GROSS PAY") {
                    items["GROSS_PAY"] = amount
                } else {
                    // Map to standard fields or preserve original
                    switch normalizedName {
                    case "BPAY", "BASIC PAY", "BASIC":
                        items["BPAY"] = amount
                    case "DA", "DEARNESS ALLOWANCE":
                        items["DA"] = amount
                    case "MSP", "MILITARY SERVICE PAY":
                        items["MSP"] = amount
                    case "HRA", "HOUSE RENT ALLOWANCE":
                        items["HRA"] = amount
                    default:
                        items[itemName] = amount
                    }
                }
            }
        }

        return items
    }

    /// Process earnings items and categorize them into the data structure
    /// - Parameters:
    ///   - items: Dictionary of earnings items to process
    ///   - data: The data structure to update with processed earnings
    func processItems(_ items: [String: Double], into data: inout EarningsDeductionsData) {
        for (key, value) in items {
            // Special handling for Gross Pay
            if key.uppercased() == "GROSS_PAY" {
                data.grossPay = value
                continue
            }

            let upperKey = key.uppercased()
            let abbreviationType = abbreviationManager.getType(for: upperKey)

            // Process based on key type
            switch upperKey {
            case "BPAY":
                data.bpay = value
            case "DA":
                data.da = value
            case "MSP":
                data.msp = value
            case "HRA":
                data.knownEarnings["HRA"] = value
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
        case .earning:
            data.knownEarnings[key] = value
        case .deduction:
            data.knownDeductions[key] = value
        case .unknown:
            data.unknownEarnings[key] = value
            learningSystem.trackUnknownAbbreviation(key, context: "earnings", value: value)
            abbreviationManager.trackUnknownAbbreviation(key, value: value)
        }
    }
}
