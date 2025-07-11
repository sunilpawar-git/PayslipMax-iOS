import Foundation
import PDFKit

/// A processing pipeline step responsible for constructing a `PayslipItem` instance
/// from processed financial data and metadata.
/// It synthesizes the final model object, applying fallback logic for missing date information
/// and calculating derived fields like "Other Allowances" or "Other Deductions".
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
    
    /// Processes the input tuple to create a finalized `PayslipItem`.
    /// Uses provided financial data, month, and year. Falls back to the current month/year if not provided.
    /// Calculates "Other Allowances" and "Other Deductions" based on the difference between reported totals
    /// and the sum of known itemized components.
    /// - Parameter input: A tuple containing (`pdfData`, `financialData`, `month?`, `year?`).
    /// - Returns: A `Result` containing the created `PayslipItem` on success, or a `PDFProcessingError` on failure (though this specific step usually succeeds if input is valid).
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
        let payslipItem = PayslipItem(
            id: UUID(),
            timestamp: Date(),
            month: payslipMonth,
            year: payslipYear,
            credits: credits,
            debits: debits,
            dsop: dsop,
            tax: tax,
            name: "Military Personnel",
            accountNumber: "",
            panNumber: "",
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
        // Add newly supported earning codes
        if let arrRshna = financialData["ARR-RSHNA"] { earnings["ARR-RSHNA"] = arrRshna }
        if let rshna = financialData["RSHNA"] { earnings["RSHNA"] = rshna }
        if let hra = financialData["HRA"] { earnings["HRA"] = hra }
        if let ta = financialData["TA"] { earnings["TA"] = ta }
        if let cea = financialData["CEA"] { earnings["CEA"] = cea }
        if let tpt = financialData["TPT"] { earnings["TPT"] = tpt }
        if let washia = financialData["WASHIA"] { earnings["WASHIA"] = washia }
        if let outfita = financialData["OUTFITA"] { earnings["OUTFITA"] = outfita }
        
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
        payslipItem.earnings = earnings
        payslipItem.deductions = deductions
        
        print("[PayslipCreationStep] Created payslip with extracted data - credits: \(credits), debits: \(debits)")
        return .success(payslipItem)
    }
} 