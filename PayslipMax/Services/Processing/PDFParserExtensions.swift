import Foundation
import PDFKit

// MARK: - Parser Extensions

// Extension to make PageAwarePayslipParser conform to PayslipParser protocol
extension PageAwarePayslipParser: PayslipParser {
    var name: String {
        return "PageAwareParser"
    }
    
    func evaluateConfidence(for payslipItem: PayslipItem) -> ParsingConfidence {
        // Evaluate confidence based on completeness of data
        var score = 0
        
        // Check personal details
        if !payslipItem.name.isEmpty && !payslipItem.accountNumber.isEmpty {
            score += 1
        }
        
        // Check earnings and deductions
        if payslipItem.credits > 0 && payslipItem.debits > 0 {
            score += 1
        }
        
        // Check if standard fields are present
        if payslipItem.earnings["BPAY"] != nil && 
           payslipItem.deductions["DSOP"] != nil {
            score += 1
        }
        
        // Determine confidence level based on score
        if score >= 3 {
            return .high
        } else if score >= 2 {
            return .medium
        } else {
            return .low
        }
    }
}

// Extension to make EnhancedEarningsDeductionsParser conform to PayslipParser protocol
extension EnhancedEarningsDeductionsParser: PayslipParser {
    var name: String {
        return "EnhancedEarningsDeductionsParser"
    }
    
    func parsePayslip(pdfDocument: PDFDocument) -> PayslipItem? {
        // Extract text from all pages
        var fullText = ""
        for i in 0..<pdfDocument.pageCount {
            guard let page = pdfDocument.page(at: i) else { continue }
            fullText += page.string ?? ""
        }
        
        // If no text was extracted, return nil
        if fullText.isEmpty {
            print("Failed to extract text from PDF")
            return nil
        }
        
        // Create a basic PayslipItem with earnings and deductions data
        let earningsDeductionsData = extractEarningsDeductions(from: fullText)
        
        let payslipItem = PayslipItem(
            id: UUID(),
            timestamp: Date(),
            month: getMonth(),
            year: getYear(),
            credits: earningsDeductionsData.grossPay,
            debits: earningsDeductionsData.totalDeductions,
            dsop: earningsDeductionsData.dsop,
            tax: earningsDeductionsData.itax,
            name: "Unknown",
            accountNumber: "Unknown",
            panNumber: "Unknown",
            pdfData: nil
        )
        
        return payslipItem
    }
    
    // Helper methods
    private func getMonth() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMMM"
        return dateFormatter.string(from: Date())
    }
    
    private func getYear() -> Int {
        let calendar = Calendar.current
        return calendar.component(.year, from: Date())
    }
    
    func evaluateConfidence(for payslipItem: PayslipItem) -> ParsingConfidence {
        // Evaluate confidence based on completeness of data
        var score = 0
        
        // Check if we have earnings and deductions
        if payslipItem.credits > 0 && payslipItem.debits > 0 {
            score += 1
        }
        
        // Check if standard fields are present
        if payslipItem.earnings["BPAY"] != nil && 
           payslipItem.deductions["DSOP"] != nil {
            score += 1
        }
        
        // Check if we have a reasonable number of items
        if payslipItem.earnings.count >= 3 && payslipItem.deductions.count >= 3 {
            score += 1
        }
        
        // Determine confidence level based on score
        if score >= 3 {
            return .high
        } else if score >= 2 {
            return .medium
        } else {
            return .low
        }
    }
} 