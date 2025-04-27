import Foundation
import Vision
import PDFKit
import SwiftUI

/// A modern Vision-based payslip parser that uses Apple's Vision framework
class VisionPayslipParser: PayslipParser {
    // MARK: - Properties
    
    /// Dictionary to store user corrections for learning
    private var userCorrections: [String: String] = [:]
    
    /// Name of the parser for identification
    var name: String {
        return "VisionPayslipParser"
    }
    
    // MARK: - Protocol Methods
    
    /// Parses a PDF document into a PayslipItem
    /// - Parameter pdfDocument: The PDF document to parse
    /// - Returns: A PayslipItem if parsing is successful, nil otherwise
    func parsePayslip(pdfDocument: PDFDocument) -> PayslipItem? {
        // Use Task to handle async/await in a sync context
        var result: PayslipItem?
        let semaphore = DispatchSemaphore(value: 0)
        
        Task {
            do {
                result = try await parseInternal(pdfDocument: pdfDocument)
                semaphore.signal()
            } catch {
                print("Error parsing payslip: \(error)")
                semaphore.signal()
            }
        }
        
        // Wait for the async task to complete
        semaphore.wait()
        return result
    }
    
    /// Evaluates the confidence level of the parsing result
    /// - Parameter payslipItem: The parsed PayslipItem
    /// - Returns: The confidence level of the parsing result
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
    
    // MARK: - Internal Methods
    
    /// Internal async implementation of the parsing logic
    private func parseInternal(pdfDocument: PDFDocument) async throws -> PayslipItem {
        var allText = ""
        
        // Extract text from all pages
        for pageIndex in 0..<pdfDocument.pageCount {
            guard let page = pdfDocument.page(at: pageIndex),
                  let text = try await extractText(from: page) else { continue }
            allText += text + "\n"
        }
        
        // Parse components
        let personalInfo = extractPersonalInfo(from: allText)
        let earnings = extractEarnings(from: allText)
        let deductions = extractDeductions(from: allText)
        let _ = extractNetRemittance(from: allText)
        let dsop = extractDSOP(from: allText)
        let tax = extractIncomeTax(from: allText)
        
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
    
    /// Applies a user correction to improve future parsing
    /// - Parameters:
    ///   - originalText: The original incorrectly recognized text
    ///   - correctedText: The user-provided correct text
    func applyUserCorrection(originalText: String, correctedText: String) {
        userCorrections[originalText] = correctedText
    }
    
    // MARK: - Private Methods
    
    /// Extracts text from a PDF page using Vision framework
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
    
    /// Extracts personal information from text
    private func extractPersonalInfo(from text: String) -> (name: String?, accountNumber: String?, panNumber: String?, month: String?, year: Int?) {
        let name = text.match(pattern: "Name:\\s*([^\\n]+)")
        let accountNumber = text.match(pattern: "A/C(?:\\s+No)?[.:]?\\s*([^\\n]+)")
        let panNumber = text.match(pattern: "PAN\\s*(?:No)?[.:]?\\s*([^\\n]+)")
        
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
    
    /// Extracts earnings from text
    private func extractEarnings(from text: String) -> [String: Double] {
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
        
        for component in standardComponents {
            if let amount = extractAmount(for: component, from: text) {
                earnings[component] = amount
            }
        }
        
        return earnings
    }
    
    /// Extracts deductions from text
    private func extractDeductions(from text: String) -> [String: Double] {
        var deductions: [String: Double] = [:]
        
        // Standard components
        let standardComponents = [
            "DSOP Fund",
            "AGIF",
            "Income Tax",
            "AFMS",
            "ACWF"
        ]
        
        for component in standardComponents {
            if let amount = extractAmount(for: component, from: text) {
                deductions[component] = amount
            }
        }
        
        return deductions
    }
    
    /// Extracts net remittance from text
    private func extractNetRemittance(from text: String) -> Double {
        let patterns = [
            "Net\\s+Remittance\\s*:?\\s*Rs\\.?\\s*(\\d+(?:,\\d+)*(?:\\.\\d+)?)",
            "Net\\s+Amount\\s*:?\\s*Rs\\.?\\s*(\\d+(?:,\\d+)*(?:\\.\\d+)?)"
        ]
        
        for pattern in patterns {
            if let amountStr = text.match(pattern: pattern)?.replacingOccurrences(of: ",", with: ""),
               let amount = Double(amountStr) {
                return amount
            }
        }
        
        return 0
    }
    
    /// Extracts DSOP amount from text
    private func extractDSOP(from text: String) -> Double {
        let patterns = [
            "DSOP\\s+Fund\\s*:?\\s*Rs\\.?\\s*(\\d+(?:,\\d+)*(?:\\.\\d+)?)",
            "PF\\s*:?\\s*Rs\\.?\\s*(\\d+(?:,\\d+)*(?:\\.\\d+)?)"
        ]
        
        for pattern in patterns {
            if let amountStr = text.match(pattern: pattern)?.replacingOccurrences(of: ",", with: ""),
               let amount = Double(amountStr) {
                return amount
            }
        }
        
        return 0
    }
    
    /// Extracts income tax amount from text
    private func extractIncomeTax(from text: String) -> Double {
        let patterns = [
            "Income\\s+Tax\\s*:?\\s*Rs\\.?\\s*(\\d+(?:,\\d+)*(?:\\.\\d+)?)",
            "ITAX\\s*:?\\s*Rs\\.?\\s*(\\d+(?:,\\d+)*(?:\\.\\d+)?)"
        ]
        
        for pattern in patterns {
            if let amountStr = text.match(pattern: pattern)?.replacingOccurrences(of: ",", with: ""),
               let amount = Double(amountStr) {
                return amount
            }
        }
        
        return 0
    }
    
    /// Helper function to extract amount for a component
    private func extractAmount(for component: String, from text: String) -> Double? {
        let pattern = "\\(\(component)\\s*:?\\s*Rs\\.?\\s*(\\d+(?:,\\d+)*(?:\\.\\d+)?)"
        if let amountStr = text.match(pattern: pattern)?.replacingOccurrences(of: ",", with: ""),
           let amount = Double(amountStr) {
            return amount
        }
        return nil
    }
}

// MARK: - String Extension

extension String {
    /// Returns the first match of the pattern in the string
    func match(pattern: String) -> String? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]),
              let match = regex.firstMatch(in: self, options: [], range: NSRange(location: 0, length: self.utf16.count)) else {
            return nil
        }
        
        if match.numberOfRanges > 1,
           let range = Range(match.range(at: 1), in: self) {
            return String(self[range]).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return nil
    }
}