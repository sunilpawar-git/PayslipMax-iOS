import Foundation

// MARK: - Helper Methods

extension PayslipDisplayNameConstants {

    static func getDisplayName(for internalKey: String) -> String? {
        return displayNameMappings[internalKey]
    }

    static func hasExplicitMapping(for internalKey: String) -> Bool {
        return displayNameMappings.keys.contains(internalKey)
    }

    static func getDualSectionKeys(for baseKey: String) -> [String] {
        let earningsKey = "\(baseKey)_EARNINGS"
        let deductionsKey = "\(baseKey)_DEDUCTIONS"

        var keys: [String] = []
        if displayNameMappings.keys.contains(earningsKey) {
            keys.append(earningsKey)
        }
        if displayNameMappings.keys.contains(deductionsKey) {
            keys.append(deductionsKey)
        }

        return keys
    }
}
