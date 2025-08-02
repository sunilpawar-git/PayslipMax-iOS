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
        
        // Extract specific contact roles with phone numbers - more flexible pattern
        let contactRolePattern = "(SAO\\s*\\(?LW\\)?|AAO\\s*\\(?LW\\)?|SAO\\s*\\(?TW\\)?|AAO\\s*\\(?TW\\)?|PRO\\s*CIVIL|PRO\\s*ARMY|HELP\\s*DESK)[^0-9]*([0-9][0-9\\-\\s]+)"
        let contactRoleRegex = try? NSRegularExpression(pattern: contactRolePattern, options: [.caseInsensitive])
        let nsString = section.text as NSString
        let contactRoleMatches = contactRoleRegex?.matches(in: section.text, options: [], range: NSRange(location: 0, length: nsString.length)) ?? []
        
        for match in contactRoleMatches {
            if match.numberOfRanges >= 3 {
                let roleRange = match.range(at: 1)
                let phoneRange = match.range(at: 2)
                
                let role = nsString.substring(with: roleRange)
                let phone = nsString.substring(with: phoneRange).trimmingCharacters(in: .whitespacesAndNewlines)
                
                // Map the role to the appropriate key
                let key: String
                let roleUpper = role.uppercased().replacingOccurrences(of: " ", with: "")
                switch roleUpper {
                case "SAO(LW)", "SAOLW": key = "SAOLW"
                case "AAO(LW)", "AAOLW": key = "AAOLW"
                case "SAO(TW)", "SAOTW": key = "SAOTW"
                case "AAO(TW)", "AAOTW": key = "AAOTW"
                case "PROCIVIL": key = "ProCivil"
                case "PROARMY": key = "ProArmy"
                case "HELPDESK": key = "HelpDesk"
                default: key = roleUpper.replacingOccurrences(of: "[^A-Za-z0-9]", with: "", options: .regularExpression)
                }
                
                result[key] = "\(role): \(phone)"
            }
        }
        
        // Extract general phone numbers with labels
        let labeledPhonePattern = "([A-Za-z\\s]+)\\s*[:-]\\s*([0-9][0-9\\-\\s]+)"
        let labeledPhoneRegex = try? NSRegularExpression(pattern: labeledPhonePattern, options: [])
        let labeledPhoneMatches = labeledPhoneRegex?.matches(in: section.text, options: [], range: NSRange(location: 0, length: nsString.length)) ?? []
        
        for match in labeledPhoneMatches {
            if match.numberOfRanges >= 3 {
                let labelRange = match.range(at: 1)
                let phoneRange = match.range(at: 2)
                
                let label = nsString.substring(with: labelRange).trimmingCharacters(in: .whitespacesAndNewlines)
                let phone = nsString.substring(with: phoneRange).trimmingCharacters(in: .whitespacesAndNewlines)
                
                // Skip if already added as a specific role
                if !result.values.contains(where: { $0.contains(phone) }) {
                    let key = label.replacingOccurrences(of: " ", with: "")
                    result[key] = "\(label): \(phone)"
                }
            }
        }
        
        // Extract standalone phone numbers
        let phonePattern = "\\(?([0-9][0-9\\-\\s]{7,})\\)?"
        let phoneRegex = try? NSRegularExpression(pattern: phonePattern, options: [])
        let phoneMatches = phoneRegex?.matches(in: section.text, options: [], range: NSRange(location: 0, length: nsString.length)) ?? []
        
        for (index, match) in phoneMatches.enumerated() {
            if match.numberOfRanges >= 2 {
                let phoneRange = match.range(at: 1)
                let phone = nsString.substring(with: phoneRange).trimmingCharacters(in: .whitespacesAndNewlines)
                
                // Only add if not already added as part of a specific role or labeled phone
                if !result.values.contains(where: { $0.contains(phone) }) {
                    result["phone\(index + 1)"] = phone
                }
            }
        }
        
        // Extract email addresses
        let emailPattern = "([a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,})"
        let emailRegex = try? NSRegularExpression(pattern: emailPattern, options: [])
        let emailMatches = emailRegex?.matches(in: section.text, options: [], range: NSRange(location: 0, length: nsString.length)) ?? []
        
        for (index, match) in emailMatches.enumerated() {
            if match.numberOfRanges >= 2 {
                let emailRange = match.range(at: 1)
                let email = nsString.substring(with: emailRange)
                
                // Categorize emails if possible
                if email.contains("tada") {
                    result["emailTADA"] = email
                } else if email.contains("ledger") {
                    result["emailLedger"] = email
                } else if email.contains("rankpay") {
                    result["emailRankPay"] = email
                } else if email.contains("general") {
                    result["emailGeneral"] = email
                } else {
                    result["email\(index + 1)"] = email
                }
            }
        }
        
        // Extract website with more flexible pattern
        let websitePatterns = [
            "(?:website|web)[^:]*:[^\\n]*([a-zA-Z0-9.-]+\\.[a-zA-Z]{2,})",
            "(?:https?://)?(?:www\\.)?([a-zA-Z0-9.-]+\\.[a-zA-Z]{2,})"
        ]
        
        for pattern in websitePatterns {
            if let match = section.text.range(of: pattern, options: .regularExpression) {
                let matchText = String(section.text[match])
                
                // Extract the domain
                if let domainRange = matchText.range(of: "([a-zA-Z0-9.-]+\\.[a-zA-Z]{2,})", options: .regularExpression) {
                    let domain = String(matchText[domainRange])
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                    result["website"] = domain
                    break
                }
            }
        }
        
        return result
    }
}