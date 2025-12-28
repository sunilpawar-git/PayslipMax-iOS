import Foundation

/// Protocol for parsing contact information from document sections
protocol ContactInfoSectionParserProtocol {
    /// Parse contact information from a document section
    /// - Parameter section: The document section containing contact information
    /// - Returns: Dictionary of contact information fields and their values
    func parseContactSection(_ section: DocumentSection) -> [String: String]
}

/// Service responsible for parsing contact information from payslip document sections
class ContactInfoSectionParser: ContactInfoSectionParserProtocol {

    // MARK: - Public Methods

    /// Parse contact information from a document section
    /// - Parameter section: The document section containing contact information
    /// - Returns: Dictionary of contact information fields and their values
    func parseContactSection(_ section: DocumentSection) -> [String: String] {
        var result: [String: String] = [:]
        let nsString = section.text as NSString

        extractContactRoles(from: section, nsString: nsString, into: &result)
        extractLabeledPhones(from: section, nsString: nsString, into: &result)
        extractStandalonePhones(from: section, nsString: nsString, into: &result)
        extractEmails(from: section, nsString: nsString, into: &result)
        extractWebsite(from: section, into: &result)

        return result
    }

    // MARK: - Private Helper Methods

    private func extractContactRoles(
        from section: DocumentSection,
        nsString: NSString,
        into result: inout [String: String]
    ) {
        let pattern = "(SAO\\s*\\(?LW\\)?|AAO\\s*\\(?LW\\)?|SAO\\s*\\(?TW\\)?|AAO\\s*\\(?TW\\)?|PRO\\s*CIVIL|PRO\\s*ARMY|HELP\\s*DESK)[^0-9]*([0-9][0-9\\-\\s]+)"
        let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive])
        let matches = regex?.matches(in: section.text, options: [], range: NSRange(location: 0, length: nsString.length)) ?? []

        for match in matches where match.numberOfRanges >= 3 {
            let roleRange = match.range(at: 1)
            let phoneRange = match.range(at: 2)
            let role = nsString.substring(with: roleRange)
            let phone = nsString.substring(with: phoneRange).trimmingCharacters(in: .whitespacesAndNewlines)
            let key = mapRoleToKey(role)
            result[key] = "\(role): \(phone)"
        }
    }

    private func mapRoleToKey(_ role: String) -> String {
        let roleUpper = role.uppercased().replacingOccurrences(of: " ", with: "")
        switch roleUpper {
        case "SAO(LW)", "SAOLW": return "SAOLW"
        case "AAO(LW)", "AAOLW": return "AAOLW"
        case "SAO(TW)", "SAOTW": return "SAOTW"
        case "AAO(TW)", "AAOTW": return "AAOTW"
        case "PROCIVIL": return "ProCivil"
        case "PROARMY": return "ProArmy"
        case "HELPDESK": return "HelpDesk"
        default: return roleUpper.replacingOccurrences(of: "[^A-Za-z0-9]", with: "", options: .regularExpression)
        }
    }

    private func extractLabeledPhones(
        from section: DocumentSection,
        nsString: NSString,
        into result: inout [String: String]
    ) {
        let pattern = "([A-Za-z\\s]+)\\s*[:-]\\s*([0-9][0-9\\-\\s]+)"
        let regex = try? NSRegularExpression(pattern: pattern, options: [])
        let matches = regex?.matches(in: section.text, options: [], range: NSRange(location: 0, length: nsString.length)) ?? []

        for match in matches where match.numberOfRanges >= 3 {
            let labelRange = match.range(at: 1)
            let phoneRange = match.range(at: 2)
            let label = nsString.substring(with: labelRange).trimmingCharacters(in: .whitespacesAndNewlines)
            let phone = nsString.substring(with: phoneRange).trimmingCharacters(in: .whitespacesAndNewlines)

            if !result.values.contains(where: { $0.contains(phone) }) {
                let key = label.replacingOccurrences(of: " ", with: "")
                result[key] = "\(label): \(phone)"
            }
        }
    }

    private func extractStandalonePhones(
        from section: DocumentSection,
        nsString: NSString,
        into result: inout [String: String]
    ) {
        let pattern = "\\(?([0-9][0-9\\-\\s]{7,})\\)?"
        let regex = try? NSRegularExpression(pattern: pattern, options: [])
        let matches = regex?.matches(in: section.text, options: [], range: NSRange(location: 0, length: nsString.length)) ?? []

        for (index, match) in matches.enumerated() where match.numberOfRanges >= 2 {
            let phoneRange = match.range(at: 1)
            let phone = nsString.substring(with: phoneRange).trimmingCharacters(in: .whitespacesAndNewlines)

            if !result.values.contains(where: { $0.contains(phone) }) {
                result["phone\(index + 1)"] = phone
            }
        }
    }

    private func extractEmails(
        from section: DocumentSection,
        nsString: NSString,
        into result: inout [String: String]
    ) {
        let pattern = "([a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,})"
        let regex = try? NSRegularExpression(pattern: pattern, options: [])
        let matches = regex?.matches(in: section.text, options: [], range: NSRange(location: 0, length: nsString.length)) ?? []

        for (index, match) in matches.enumerated() where match.numberOfRanges >= 2 {
            let emailRange = match.range(at: 1)
            let email = nsString.substring(with: emailRange)
            let key = categorizeEmail(email, index: index)
            result[key] = email
        }
    }

    private func categorizeEmail(_ email: String, index: Int) -> String {
        if email.contains("tada") { return "emailTADA" }
        if email.contains("ledger") { return "emailLedger" }
        if email.contains("rankpay") { return "emailRankPay" }
        if email.contains("general") { return "emailGeneral" }
        return "email\(index + 1)"
    }

    private func extractWebsite(from section: DocumentSection, into result: inout [String: String]) {
        let patterns = [
            "(?:website|web)[^:]*:[^\\n]*([a-zA-Z0-9.-]+\\.[a-zA-Z]{2,})",
            "(?:https?://)?(?:www\\.)?([a-zA-Z0-9.-]+\\.[a-zA-Z]{2,})"
        ]

        for pattern in patterns {
            if let match = section.text.range(of: pattern, options: .regularExpression) {
                let matchText = String(section.text[match])
                if let domainRange = matchText.range(of: "([a-zA-Z0-9.-]+\\.[a-zA-Z]{2,})", options: .regularExpression) {
                    let domain = String(matchText[domainRange]).trimmingCharacters(in: .whitespacesAndNewlines)
                    result["website"] = domain
                    break
                }
            }
        }
    }
}
