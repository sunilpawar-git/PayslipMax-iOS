import Foundation

/// Service responsible for legacy format validation and pattern extraction
/// Extracted component for single responsibility - legacy-specific validation
final class LegacyValidationService {
    
    // MARK: - Public Interface
    
    /// Extracts data using legacy civilian patterns
    /// - Parameter text: Text to extract from
    /// - Returns: Dictionary of extracted financial data
    func extractLegacyCivilianPatterns(from text: String) -> [String: Double] {
        var extractedData: [String: Double] = [:]
        
        // Legacy civilian patterns - different from military
        let civilianPatterns: [(key: String, regex: String)] = [
            ("BasicPay", "(?:BASIC\\s+PAY|BASIC\\s+SALARY)\\s*[:-]?\\s*([0-9,.]+)"),
            ("DA", "(?:DEARNESS\\s+ALLOWANCE|DA)\\s*[:-]?\\s*([0-9,.]+)"),
            ("HRA", "(?:HOUSE\\s+RENT\\s+ALLOWANCE|HRA)\\s*[:-]?\\s*([0-9,.]+)"),
            ("TA", "(?:TRANSPORT\\s+ALLOWANCE|TA)\\s*[:-]?\\s*([0-9,.]+)"),
            ("PF", "(?:PROVIDENT\\s+FUND|PF)\\s*[:-]?\\s*([0-9,.]+)"),
            ("IncomeTax", "(?:INCOME\\s+TAX|ITAX|IT)\\s*[:-]?\\s*([0-9,.]+)"),
            ("GrossPay", "(?:GROSS\\s+PAY|TOTAL\\s+EARNINGS)\\s*[:-]?\\s*([0-9,.]+)"),
            ("Deductions", "(?:TOTAL\\s+DEDUCTIONS|NET\\s+DEDUCTIONS)\\s*[:-]?\\s*([0-9,.]+)")
        ]
        
        for (key, pattern) in civilianPatterns {
            if let value = extractAmountWithPattern(pattern, from: text) {
                extractedData[key] = value
                print("[LegacyValidationService] Legacy civilian extracted \(key): \(value)")
            }
        }
        
        return extractedData
    }
    
    /// Applies format-specific validation rules
    /// - Parameters:
    ///   - data: Financial data to validate
    ///   - formatType: Type of payslip format
    /// - Returns: Validated financial data
    func applyLegacyFormatValidation(
        to data: [String: Double],
        formatType: PayslipFormatType
    ) -> [String: Double] {
        
        var validatedData = data
        
        switch formatType {
        case .preNov2023Military:
            // Legacy military formats might have different validation rules
            validatedData = applyLegacyMilitaryValidation(to: validatedData)
            
        case .preNov2023Civilian:
            // Legacy civilian formats have different component names
            validatedData = applyLegacyCivilianValidation(to: validatedData)
            
        case .modernFormat, .unknown:
            // Use standard validation
            break
        }
        
        return validatedData
    }
    
    /// Helper function to extract numerical amount using regex pattern
    /// - Parameters:
    ///   - pattern: Regular expression pattern
    ///   - text: Text to search in
    /// - Returns: Extracted amount or nil if not found
    func extractAmountWithPattern(_ pattern: String, from text: String) -> Double? {
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: [.caseInsensitive])
            let nsString = text as NSString
            let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: nsString.length))
            
            if let match = matches.first, match.numberOfRanges > 1 {
                let valueRange = match.range(at: 1)
                let value = nsString.substring(with: valueRange).trimmingCharacters(in: .whitespacesAndNewlines)
                let cleanValue = value.replacingOccurrences(of: ",", with: "")
                return Double(cleanValue)
            }
        } catch {
            print("[LegacyValidationService] Error with regex pattern \(pattern): \(error.localizedDescription)")
        }
        return nil
    }
    
    // MARK: - Private Implementation
    
    /// Applies validation specific to legacy military formats
    private func applyLegacyMilitaryValidation(to data: [String: Double]) -> [String: Double] {
        var validatedData = data
        
        // Legacy military payslips might have different allowance structures
        // Remove values that are too high for legacy military pay scales
        let legacyMaxBasicPay: Double = 200000 // Lower ceiling for legacy formats
        
        if let basicPay = validatedData["BPAY"], basicPay > legacyMaxBasicPay {
            print("[LegacyValidationService] Removing high basic pay for legacy military: \(basicPay)")
            validatedData.removeValue(forKey: "BPAY")
        }
        
        return validatedData
    }
    
    /// Applies validation specific to legacy civilian formats
    private func applyLegacyCivilianValidation(to data: [String: Double]) -> [String: Double] {
        var validatedData = data
        
        // Legacy civilian payslips have different component relationships
        // Validate HRA against BasicPay (should be reasonable percentage)
        if let basicPay = validatedData["BasicPay"],
           let hra = validatedData["HRA"] {
            let hraRatio = hra / basicPay
            if hraRatio > 0.5 { // HRA shouldn't exceed 50% of basic pay typically
                print("[LegacyValidationService] Warning: HRA ratio \(hraRatio) seems high for civilian payslip")
            }
        }
        
        // Validate total deductions
        if let grossPay = validatedData["GrossPay"],
           let deductions = validatedData["Deductions"] {
            if deductions > grossPay {
                print("[LegacyValidationService] Warning: Total deductions exceed gross pay")
            }
        }
        
        return validatedData
    }
}
