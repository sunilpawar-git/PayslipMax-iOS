import Foundation
import PDFKit

/// Adapter that wraps SimplifiedPayslipParser to conform to PayslipProcessorProtocol
/// This allows the new simplified parser to work within the existing processing pipeline
class SimplifiedPayslipProcessorAdapter: PayslipProcessorProtocol {
    
    // MARK: - Properties
    
    private let simplifiedParser: SimplifiedPayslipParser
    private let confidenceCalculator: ConfidenceCalculator
    
    var handlesFormat: PayslipFormat {
        return .defense
    }
    
    // MARK: - Initialization
    
    init() {
        self.simplifiedParser = SimplifiedPayslipParser()
        self.confidenceCalculator = ConfidenceCalculator()
    }
    
    // MARK: - PayslipProcessorProtocol Implementation
    
    func processPayslip(from text: String) throws -> PayslipItem {
        print("[SimplifiedPayslipProcessorAdapter] 🚀 Using SIMPLIFIED parser (10 essential fields)")
        
        guard text.count >= 100 else {
            throw PayslipError.invalidData
        }
        
        // Use the simplified parser to extract essential fields (async call run synchronously in this context)
        let simplifiedPayslip: SimplifiedPayslip
        let group = DispatchGroup()
        group.enter()
        
        var tempPayslip: SimplifiedPayslip? = nil
        Task {
            tempPayslip = await simplifiedParser.parse(text, pdfData: Data())
            group.leave()
        }
        group.wait()
        
        guard let parsedPayslip = tempPayslip else {
            throw PayslipError.invalidData
        }
        simplifiedPayslip = parsedPayslip
        
        // Convert SimplifiedPayslip to PayslipItem for backward compatibility
        let payslipItem = try convertToPayslipItem(simplifiedPayslip)
        
        print("[SimplifiedPayslipProcessorAdapter] ✅ Parsing complete - Confidence: \(Int(simplifiedPayslip.parsingConfidence * 100))%")
        print("[SimplifiedPayslipProcessorAdapter] BPAY: ₹\(simplifiedPayslip.basicPay), DA: ₹\(simplifiedPayslip.dearnessAllowance), MSP: ₹\(simplifiedPayslip.militaryServicePay)")
        print("[SimplifiedPayslipProcessorAdapter] Gross: ₹\(simplifiedPayslip.grossPay), Deductions: ₹\(simplifiedPayslip.totalDeductions), Net: ₹\(simplifiedPayslip.netRemittance)")
        
        return payslipItem
    }
    
    func canProcess(text: String) -> Double {
        // Simplified parser can handle defense payslips
        // Look for key defense indicators
        let defenseIndicators = ["BPAY", "DSOP", "AGIF", "MSP", "Defence", "PCDA"]
        let foundIndicators = defenseIndicators.filter { text.contains($0) }.count
        return Double(foundIndicators) / Double(defenseIndicators.count)
    }
    
    // MARK: - Private Helpers
    
    /// Converts SimplifiedPayslip to PayslipItem for backward compatibility with existing UI
    private func convertToPayslipItem(_ simplified: SimplifiedPayslip) throws -> PayslipItem {
        // Map simplified fields to earnings dictionary
        var earnings: [String: Double] = [:]
        earnings["Basic Pay"] = simplified.basicPay
        earnings["Dearness Allowance"] = simplified.dearnessAllowance
        earnings["Military Service Pay"] = simplified.militaryServicePay
        
        // Add "Other Earnings" as a distinct category (user-editable)
        if simplified.otherEarnings > 0 {
            earnings["Other Earnings"] = simplified.otherEarnings
        }
        
        // Add breakdown for other earnings if user has edited them
        for (key, value) in simplified.otherEarningsBreakdown {
            earnings[key] = value
        }
        
        // Map simplified fields to deductions dictionary
        var deductions: [String: Double] = [:]
        deductions["DSOP"] = simplified.dsop
        deductions["AGIF"] = simplified.agif
        deductions["Income Tax"] = simplified.incomeTax
        
        // Add "Other Deductions" as a distinct category (user-editable)
        if simplified.otherDeductions > 0 {
            deductions["Other Deductions"] = simplified.otherDeductions
        }
        
        // Add breakdown for other deductions if user has edited them
        for (key, value) in simplified.otherDeductionsBreakdown {
            deductions[key] = value
        }
        
        // Create PayslipItem with simplified data
        let payslipItem = PayslipItem(
            id: UUID(),
            timestamp: Date(),
            month: simplified.month,
            year: simplified.year,
            credits: simplified.grossPay,
            debits: simplified.totalDeductions,
            dsop: simplified.dsop,
            tax: simplified.incomeTax,
            earnings: earnings,
            deductions: deductions,
            name: simplified.name,
            pdfData: simplified.pdfData,
            source: "SimplifiedParser_v1.0",
            metadata: [
                "parsingConfidence": String(format: "%.2f", simplified.parsingConfidence),
                "parserVersion": "1.0",
                "parsingDate": ISO8601DateFormatter().string(from: Date())
            ]
        )
        
        return payslipItem
    }
}

