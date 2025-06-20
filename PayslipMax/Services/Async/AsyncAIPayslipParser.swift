import Foundation
import PDFKit
import Vision

/// Async-first AI payslip parser that eliminates DispatchSemaphore usage.
/// This replaces the synchronous AIPayslipParser for new async workflows.
/// 
/// Follows the single responsibility principle established in Phase 2B refactoring.
class AsyncAIPayslipParser {
    
    // MARK: - Properties
    
    private var userCorrections: [String: String] = [:]
    
    // MARK: - Public Methods
    
    /// Returns the parser name for identification
    func getParserName() -> String {
        return "AsyncVisionPayslipParser"
    }
    
    /// Parses a PDF document into a PayslipItem asynchronously
    func parsePayslip(pdfDocument: PDFDocument) async throws -> PayslipItem? {
        // ✅ CLEAN: Direct async call - no semaphores!
        return try await parseInternal(pdfDocument: pdfDocument)
    }
    
    /// Evaluates the confidence level of the parsing result
    func evaluateConfidence(for payslipItem: PayslipItem) -> ParsingConfidence {
        // Basic confidence evaluation based on required fields
        if payslipItem.name != "Unknown" && 
           payslipItem.month != "Unknown" && 
           payslipItem.credits > 0 && 
           payslipItem.debits > 0 {
            return .high
        } else if payslipItem.name != "Unknown" && 
                  (payslipItem.credits > 0 || payslipItem.debits > 0) {
            return .medium
        } else {
            return .low
        }
    }
    
    /// Applies a user correction to improve future parsing
    func applyUserCorrection(originalText: String, correctedText: String) {
        userCorrections[originalText] = correctedText
    }
    
    // MARK: - Private Methods
    
    /// Internal async implementation of the parsing logic
    private func parseInternal(pdfDocument: PDFDocument) async throws -> PayslipItem {
        var allText = ""
        
        // Extract text from all pages using structured concurrency
        try await withThrowingTaskGroup(of: (Int, String?).self) { group in
            // Add tasks for each page
            for pageIndex in 0..<pdfDocument.pageCount {
                group.addTask {
                    guard let page = pdfDocument.page(at: pageIndex) else {
                        return (pageIndex, nil)
                    }
                    
                    let text = try await self.extractText(from: page)
                    return (pageIndex, text)
                }
            }
            
            // Collect results in order
            var pageTexts: [String?] = Array(repeating: nil, count: pdfDocument.pageCount)
            
            for try await (pageIndex, text) in group {
                pageTexts[pageIndex] = text
            }
            
            // Combine all text
            allText = pageTexts.compactMap { $0 }.joined(separator: "\n")
        }
        
        // Parse components
        let personalInfo = await extractPersonalInfo(from: allText)
        let earnings = await extractEarnings(from: allText)
        let deductions = await extractDeductions(from: allText)
        let _ = await extractNetRemittance(from: allText)
        let dsop = await extractDSOP(from: allText)
        let tax = await extractIncomeTax(from: allText)
        
        // Create PayslipItem
        let payslip = PayslipItem(
            month: personalInfo.month ?? "Unknown",
            year: personalInfo.year ?? Calendar.current.component(.year, from: Date()),
            credits: earnings.values.reduce(0, +),
            debits: deductions.values.reduce(0, +),
            dsop: dsop,
            tax: tax,
            name: personalInfo.name ?? "Unknown",
            accountNumber: personalInfo.accountNumber ?? "Unknown",
            panNumber: personalInfo.panNumber ?? "Unknown"
        )
        
        payslip.earnings = earnings
        payslip.deductions = deductions
        
        return payslip
    }
    
    /// Extracts text from a PDF page using Vision framework asynchronously
    private func extractText(from page: PDFPage) async throws -> String? {
        let pageRect = page.bounds(for: .mediaBox)
        let renderer = UIGraphicsImageRenderer(size: pageRect.size)
        let image = renderer.image { ctx in
            UIColor.white.set()
            ctx.fill(CGRect(origin: .zero, size: pageRect.size))
            ctx.cgContext.translateBy(x: 0, y: pageRect.size.height)
            ctx.cgContext.scaleBy(x: 1.0, y: -1.0)
            page.draw(with: .mediaBox, to: ctx.cgContext)
        }
        
        // ✅ CLEAN: Use async Vision API without blocking
        return try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(returning: nil)
                    return
                }
                
                let text = observations.compactMap { observation -> String? in
                    observation.topCandidates(1).first?.string
                }.joined(separator: "\n")
                
                continuation.resume(returning: text)
            }
            
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            
            do {
                try VNImageRequestHandler(cgImage: image.cgImage!, options: [:])
                    .perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    /// Extracts personal information from text asynchronously
    private func extractPersonalInfo(from text: String) async -> (name: String?, accountNumber: String?, panNumber: String?, month: String?, year: Int?) {
        // ✅ CLEAN: CPU-intensive work with yield points
        await Task.yield()
        
        let name = text.match(pattern: "Name:\\s*([^\\n]+)")
        let accountNumber = text.match(pattern: "A/C(?:\\s+No)?[.:]?\\s*([^\\n]+)")
        let panNumber = text.match(pattern: "PAN\\s*(?:No)?[.:]?\\s*([^\\n]+)")
        
        await Task.yield()
        
        // Extract month and year
        let months = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"]
        var month: String?
        var year: Int?
        
        for monthName in months {
            if text.contains(monthName) {
                month = monthName
                if let yearStr = text.match(pattern: "\\b(20\\d{2})\\b"),
                   let yearInt = Int(yearStr) {
                    year = yearInt
                }
                break
            }
        }
        
        return (name, accountNumber, panNumber, month, year)
    }
    
    /// Extracts earnings from text asynchronously
    private func extractEarnings(from text: String) async -> [String: Double] {
        var earnings: [String: Double] = [:]
        
        // Standard components
        let standardComponents = [
            "Basic Pay",
            "Grade Pay",
            "Military Service Pay",
            "Dearness Allowance",
            "Transport Allowance",
            "House Rent Allowance"
        ]
        
        // ✅ CLEAN: Process components with yield points
        for component in standardComponents {
            await Task.yield()
            
            if let amount = await extractAmount(for: component, from: text) {
                earnings[component] = amount
            }
        }
        
        return earnings
    }
    
    /// Extracts deductions from text asynchronously
    private func extractDeductions(from text: String) async -> [String: Double] {
        var deductions: [String: Double] = [:]
        
        // Standard components
        let standardComponents = [
            "DSOP Fund",
            "AGIF",
            "Income Tax",
            "AFMS",
            "ACWF"
        ]
        
        // ✅ CLEAN: Process components with yield points
        for component in standardComponents {
            await Task.yield()
            
            if let amount = await extractAmount(for: component, from: text) {
                deductions[component] = amount
            }
        }
        
        return deductions
    }
    
    /// Extracts amount for a specific component asynchronously
    private func extractAmount(for component: String, from text: String) async -> Double? {
        await Task.yield()
        
        // Try multiple patterns for the component
        let patterns = [
            "\(component)\\s*[:\\-]?\\s*([0-9,]+\\.?[0-9]*)",
            "\(component).*?([0-9,]+\\.?[0-9]*)",
            "([0-9,]+\\.?[0-9]*).*?\(component)"
        ]
        
        for pattern in patterns {
            if let amountStr = text.match(pattern: pattern) {
                let cleanAmount = amountStr.replacingOccurrences(of: ",", with: "")
                if let amount = Double(cleanAmount) {
                    return amount
                }
            }
        }
        
        return nil
    }
    
    /// Extracts net remittance asynchronously
    private func extractNetRemittance(from text: String) async -> Double {
        await Task.yield()
        
        if let amountStr = text.match(pattern: "Net\\s+Remittance[:\\-]?\\s*([0-9,]+\\.?[0-9]*)") {
            let cleanAmount = amountStr.replacingOccurrences(of: ",", with: "")
            return Double(cleanAmount) ?? 0.0
        }
        
        return 0.0
    }
    
    /// Extracts DSOP amount asynchronously
    private func extractDSOP(from text: String) async -> Double {
        await Task.yield()
        
        if let amountStr = text.match(pattern: "DSOP[:\\-]?\\s*([0-9,]+\\.?[0-9]*)") {
            let cleanAmount = amountStr.replacingOccurrences(of: ",", with: "")
            return Double(cleanAmount) ?? 0.0
        }
        
        return 0.0
    }
    
    /// Extracts income tax amount asynchronously
    private func extractIncomeTax(from text: String) async -> Double {
        await Task.yield()
        
        if let amountStr = text.match(pattern: "Income\\s+Tax[:\\-]?\\s*([0-9,]+\\.?[0-9]*)") {
            let cleanAmount = amountStr.replacingOccurrences(of: ",", with: "")
            return Double(cleanAmount) ?? 0.0
        }
        
        return 0.0
    }
}

// Note: String.match(pattern:) extension is defined in AIPayslipParser.swift

// MARK: - Supporting Types

// Note: ParsingConfidence is defined in ParsingModels.swift

/// Errors specific to async AI parsing
enum AsyncAIParsingError: Error, LocalizedError {
    case visionProcessingFailed
    case textExtractionFailed
    case dataParsingFailed
    case invalidDocument
    
    var errorDescription: String? {
        switch self {
        case .visionProcessingFailed:
            return "Vision framework processing failed"
        case .textExtractionFailed:
            return "Failed to extract text from document"
        case .dataParsingFailed:
            return "Failed to parse extracted data"
        case .invalidDocument:
            return "Invalid or corrupted document"
        }
    }
} 