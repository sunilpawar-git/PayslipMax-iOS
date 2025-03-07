import Foundation
import SwiftData
import PDFKit
import Vision

final class PDFServiceImpl: PDFServiceProtocol {
    // MARK: - Properties
    private let security: SecurityServiceProtocol
    var isInitialized: Bool = false
    
    // MARK: - Initialization
    init(security: SecurityServiceProtocol) {
        self.security = security
    }
    
    func initialize() async throws {
        try await security.initialize()
        isInitialized = true
    }
    
    // MARK: - PDFServiceProtocol
    func process(_ url: URL) async throws -> Data {
        guard isInitialized else {
            throw PDFError.notInitialized
        }
        
        do {
            // Load PDF
            guard let document = PDFDocument(url: url) else {
                throw PDFError.invalidPDF
            }
            
            // Convert to data
            guard let data = document.dataRepresentation() else {
                throw PDFError.conversionFailed
            }
            
            // Encrypt before storing
            return try await security.encrypt(data)
        } catch {
            throw PDFError.processingFailed(error)
        }
    }
    
    func extract(_ data: Data) async throws -> Any {
        guard isInitialized else {
            throw PDFError.notInitialized
        }
        
        do {
            // Decrypt data
            let decryptedData = try await security.decrypt(data)
            
            // Create PDF document
            guard let document = PDFDocument(data: decryptedData) else {
                throw PDFError.invalidPDF
            }
            
            // Extract text from PDF
            let payslipData = try await extractPayslipData(from: document)
            return payslipData
            
        } catch {
            throw PDFError.extractionFailed(error)
        }
    }
    
    // MARK: - Private Methods
    private func extractPayslipData(from document: PDFDocument) async throws -> PayslipItem {
        var extractedText = ""
        
        // Extract text from each page
        for i in 0..<document.pageCount {
            guard let page = document.page(at: i) else { continue }
            extractedText += page.string ?? ""
        }
        
        let text = extractedText
        return try parsePayslipData(from: text)
    }
    
    private func parsePayslipData(from text: String) throws -> PayslipItem {
        // Create a new PayslipItem with all required parameters
        let payslip = PayslipItem(
            id: UUID(),  // Generate new UUID
            month: "1",    // Default month as string
            year: Calendar.current.component(.year, from: Date()),
            credits: 0,  // Will be updated in parsing
            debits: 0,   // Will be updated in parsing
            dspof: 0,    // Corrected parameter name from dsopf to dspof
            tax: 0,      // Will be updated in parsing
            location: "", // Default or will be updated in parsing
            name: "",    // Will be updated in parsing
            accountNumber: "", // Default or will be updated in parsing
            panNumber: "",    // Default or will be updated in parsing
            timestamp: Date() // Default timestamp
        )
        
        // Basic parsing example
        let lines = text.components(separatedBy: .newlines)
        for line in lines {
            if line.contains("Name:") {
                payslip.name = line.replacingOccurrences(of: "Name:", with: "").trimmingCharacters(in: .whitespaces)
            }
            if line.contains("Amount:") {
                let amountString = line.replacingOccurrences(of: "Amount:", with: "")
                    .trimmingCharacters(in: .whitespaces)
                if let amount = Double(amountString) {
                    payslip.credits = amount
                }
            }
            if line.contains("Date:") {
                // Parse the date string into a proper Date object
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "dd/MM/yyyy" // Adjust format based on your PDF date format
                
                let dateString = line.replacingOccurrences(of: "Date:", with: "")
                    .trimmingCharacters(in: .whitespaces)
                
                if let parsedDate = dateFormatter.date(from: dateString) {
                    payslip.timestamp = parsedDate
                    // Also update month and year from the parsed date
                    let calendar = Calendar.current
                    payslip.month = String(calendar.component(.month, from: parsedDate)) // Convert month Int to String
                    payslip.year = calendar.component(.year, from: parsedDate)
                } else {
                    // Fallback to current date if parsing fails
                    payslip.timestamp = Date()
                }
            }
            // Add more field parsing as needed
        }
        
        return payslip
    }
    
    // MARK: - Error Types
    enum PDFError: LocalizedError {
        case notInitialized
        case invalidPDF
        case conversionFailed
        case processingFailed(Error)
        case extractionFailed(Error)
        
        var errorDescription: String? {
            switch self {
            case .notInitialized:
                return "PDF service not initialized"
            case .invalidPDF:
                return "Invalid PDF document"
            case .conversionFailed:
                return "Failed to convert PDF"
            case .processingFailed(let error):
                return "Failed to process PDF: \(error.localizedDescription)"
            case .extractionFailed(let error):
                return "Failed to extract data: \(error.localizedDescription)"
            }
        }
    }
} 
