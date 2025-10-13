import Foundation

/// Service for migrating existing PayslipItem objects to SimplifiedPayslip
/// Handles conversion of complex 243-code parsed data to simplified essential-only model
class PayslipMigrationService {
    
    // MARK: - Migration
    
    /// Migrates a PayslipItem to SimplifiedPayslip
    /// - Parameter payslipItem: The legacy PayslipItem to migrate
    /// - Returns: A new SimplifiedPayslip with extracted essential data
    func migrate(_ payslipItem: PayslipItem) -> SimplifiedPayslip {
        // Extract core earnings
        let basicPay = extractValue(for: "BPAY", from: payslipItem.earnings)
        let dearnessAllowance = extractValue(for: "DA", from: payslipItem.earnings)
        let militaryServicePay = extractValue(for: "MSP", from: payslipItem.earnings)
        
        // Use credits as gross pay
        let grossPay = payslipItem.credits
        
        // Calculate other earnings
        let coreEarningsTotal = basicPay + dearnessAllowance + militaryServicePay
        let otherEarnings = max(0, grossPay - coreEarningsTotal)
        
        // Extract core deductions
        let dsop = payslipItem.dsop
        let agif = extractValue(for: "AGIF", from: payslipItem.deductions)
        let incomeTax = payslipItem.tax
        
        // Use debits as total deductions
        let totalDeductions = payslipItem.debits
        
        // Calculate other deductions
        let coreDeductionsTotal = dsop + agif + incomeTax
        let otherDeductions = max(0, totalDeductions - coreDeductionsTotal)
        
        // Calculate net remittance
        let netRemittance = grossPay - totalDeductions
        
        // Build breakdowns from remaining codes
        let otherEarningsBreakdown = buildEarningsBreakdown(
            from: payslipItem.earnings,
            excluding: ["BPAY", "BP", "DA", "MSP"]
        )
        
        let otherDeductionsBreakdown = buildDeductionsBreakdown(
            from: payslipItem.deductions,
            excluding: ["DSOP", "AGIF", "ITAX", "IT"]
        )
        
        // Create simplified payslip
        return SimplifiedPayslip(
            id: payslipItem.id,
            timestamp: payslipItem.timestamp,
            name: payslipItem.name,
            month: payslipItem.month,
            year: payslipItem.year,
            basicPay: basicPay,
            dearnessAllowance: dearnessAllowance,
            militaryServicePay: militaryServicePay,
            otherEarnings: otherEarnings,
            grossPay: grossPay,
            dsop: dsop,
            agif: agif,
            incomeTax: incomeTax,
            otherDeductions: otherDeductions,
            totalDeductions: totalDeductions,
            netRemittance: netRemittance,
            otherEarningsBreakdown: otherEarningsBreakdown,
            otherDeductionsBreakdown: otherDeductionsBreakdown,
            parsingConfidence: 0.8, // Migrated data gets 80% confidence
            pdfData: payslipItem.pdfData,
            source: "Migrated from Legacy",
            isEdited: false
        )
    }
    
    /// Migrates multiple PayslipItems to SimplifiedPayslips
    /// - Parameter payslipItems: Array of legacy PayslipItems
    /// - Returns: Array of SimplifiedPayslips
    func migrateAll(_ payslipItems: [PayslipItem]) -> [SimplifiedPayslip] {
        return payslipItems.map { migrate($0) }
    }
    
    // MARK: - Helper Methods
    
    /// Extracts a value for a specific key from a dictionary
    /// Handles multiple variations of the same key (e.g., "BPAY", "BP")
    private func extractValue(for key: String, from dictionary: [String: Double]) -> Double {
        // Try exact match first
        if let value = dictionary[key] {
            return value
        }
        
        // Try common variations
        let variations: [String: [String]] = [
            "BPAY": ["BPAY", "BP", "Basic Pay"],
            "DA": ["DA", "Dearness Allowance"],
            "MSP": ["MSP", "Military Service Pay"],
            "DSOP": ["DSOP", "DSOPP"],
            "AGIF": ["AGIF", "AGIF FUND"],
            "ITAX": ["ITAX", "IT", "Income Tax", "TAX"]
        ]
        
        if let keyVariations = variations[key] {
            for variation in keyVariations {
                if let value = dictionary[variation] {
                    return value
                }
            }
        }
        
        return 0.0
    }
    
    /// Builds earnings breakdown excluding core components
    private func buildEarningsBreakdown(
        from earnings: [String: Double],
        excluding: [String]
    ) -> [String: Double] {
        var breakdown: [String: Double] = [:]
        
        for (key, value) in earnings {
            let upperKey = key.uppercased()
            
            // Skip if this is a core component
            if excluding.contains(where: { upperKey.contains($0) }) {
                continue
            }
            
            // Add to breakdown
            breakdown[key] = value
        }
        
        return breakdown
    }
    
    /// Builds deductions breakdown excluding core components
    private func buildDeductionsBreakdown(
        from deductions: [String: Double],
        excluding: [String]
    ) -> [String: Double] {
        var breakdown: [String: Double] = [:]
        
        for (key, value) in deductions {
            let upperKey = key.uppercased()
            
            // Skip if this is a core component
            if excluding.contains(where: { upperKey.contains($0) }) {
                continue
            }
            
            // Add to breakdown
            breakdown[key] = value
        }
        
        return breakdown
    }
}

