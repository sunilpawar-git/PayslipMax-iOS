import Foundation
import PDFKit

/// A concrete processing step for creating PayslipItem instances
@MainActor
class PayslipCreationProcessingStep: PayslipProcessingStep {
    typealias Input = (Data, [String: Double], String?, Int?)
    typealias Output = PayslipItem
    
    /// The data extraction service
    private let dataExtractionService: DataExtractionService
    
    /// Initialize with required services
    /// - Parameter dataExtractionService: Service for extracting data from text
    init(dataExtractionService: DataExtractionService) {
        self.dataExtractionService = dataExtractionService
    }
    
    /// Process the input by creating a PayslipItem
    /// - Parameter input: Tuple of (PDF data, financial data, month, year)
    /// - Returns: Success with PayslipItem or failure with error
    func process(_ input: (Data, [String: Double], String?, Int?)) async -> Result<PayslipItem, PDFProcessingError> {
        let startTime = Date()
        defer {
            print("[PayslipCreationStep] Completed in \(Date().timeIntervalSince(startTime)) seconds")
        }
        
        let (pdfData, financialData, month, year) = input
        
        // Get the necessary values from the financial data
        let credits = financialData["credits"] ?? 0.0
        let debits = financialData["debits"] ?? 0.0
        let dsop = financialData["DSOP"] ?? 0.0
        let tax = financialData["ITAX"] ?? 0.0
        
        // Determine the month and year
        let currentDate = Date()
        let calendar = Calendar.current
        let currentYear = calendar.component(.year, from: currentDate)
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMMM"
        let currentMonth = dateFormatter.string(from: currentDate)
        
        // Use provided month/year or fallback to current
        let payslipMonth = month ?? currentMonth
        let payslipYear = year ?? currentYear
        
        // Create the payslip item
        let payslip = PayslipItem(
            id: UUID(),
            month: payslipMonth,
            year: payslipYear,
            credits: credits,
            debits: debits,
            dsop: dsop,
            tax: tax,
            name: "Military Personnel",
            accountNumber: "",
            panNumber: "",
            timestamp: Date(),
            pdfData: pdfData
        )
        
        // Create earnings dictionary from extracted data
        var earnings = [String: Double]()
        if let bpay = financialData["BPAY"] { earnings["BPAY"] = bpay }
        if let da = financialData["DA"] { earnings["DA"] = da }
        if let msp = financialData["MSP"] { earnings["MSP"] = msp }
        if let rh12 = financialData["RH12"] { earnings["RH12"] = rh12 }
        if let tpta = financialData["TPTA"] { earnings["TPTA"] = tpta }
        if let tptada = financialData["TPTADA"] { earnings["TPTADA"] = tptada }
        
        // Create deductions dictionary from extracted data
        var deductions = [String: Double]()
        if let dsop = financialData["DSOP"] { deductions["DSOP"] = dsop }
        if let agif = financialData["AGIF"] { deductions["AGIF"] = agif }
        if let itax = financialData["ITAX"] { deductions["ITAX"] = itax }
        if let ehcess = financialData["EHCESS"] { deductions["EHCESS"] = ehcess }
        
        // Calculate other allowances if total is greater than sum of individual components
        let knownEarnings = earnings.values.reduce(0, +)
        if credits > knownEarnings && knownEarnings > 0 {
            let otherAllowances = credits - knownEarnings
            if otherAllowances > 0 {
                earnings["Other Allowances"] = otherAllowances
            }
        }
        
        // Calculate other deductions if total is greater than sum of individual components
        let knownDeductions = deductions.values.reduce(0, +)
        if debits > knownDeductions && knownDeductions > 0 {
            let otherDeductions = debits - knownDeductions
            if otherDeductions > 0 {
                deductions["Other Deductions"] = otherDeductions
            }
        }
        
        // Add these to the payslip
        payslip.earnings = earnings
        payslip.deductions = deductions
        
        print("[PayslipCreationStep] Created payslip with extracted data - credits: \(credits), debits: \(debits)")
        return .success(payslip)
    }
} 