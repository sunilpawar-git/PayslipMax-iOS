import Foundation
import SwiftUI
import Combine
import PDFKit

/// A handler for payslip data operations
/// Updated for Swift 6 Sendable compliance using enhanced conversion approach
@MainActor
class PayslipDataHandler {
    /// The sendable repository for thread-safe data operations
    private let repository: SendablePayslipRepository
    /// The legacy data service for non-payslip operations
    private let dataService: DataServiceProtocol

    /// Flag indicating whether the data service is initialized
    private var isServiceInitialized: Bool {
        dataService.isInitialized
    }

    /// Initializes a new payslip data handler
    /// - Parameters:
    ///   - repository: The sendable repository for payslip operations
    ///   - dataService: The data service for other operations
    init(repository: SendablePayslipRepository? = nil, dataService: DataServiceProtocol? = nil) {
        self.repository = repository ?? DIContainer.shared.makeSendablePayslipRepository()
        self.dataService = dataService ?? DIContainer.shared.makeDataService()
    }

    /// Loads recent payslips and converts them to PayslipItem with PDF data
    /// - Returns: An array of PayslipItems with PDF data intact
    func loadRecentPayslips() async throws -> [PayslipItem] {
        // Initialize the data service if it's not already initialized
        if !isServiceInitialized {
            try await dataService.initialize()
        }

        // Fetch fresh payslips from sendable repository (DTOs)
        let payslipDTOs = try await repository.fetchAllPayslips()

        // Convert DTOs to PayslipItems and restore PDF data
        let payslipItems = try await convertDTOsToPayslipItems(payslipDTOs)

        // Only log in non-test environments to reduce test verbosity
        if !ProcessInfo.isRunningInTestEnvironment {
            print("PayslipDataHandler: Loaded \(payslipItems.count) payslips")
        }

        // Sort by date (newest first)
        return payslipItems.sorted { $0.timestamp > $1.timestamp }
    }
    
    /// Converts PayslipDTOs to PayslipItems with PDF data restored
    /// - Parameter dtos: Array of PayslipDTOs to convert
    /// - Returns: Array of PayslipItems with PDF data intact
    private func convertDTOsToPayslipItems(_ dtos: [PayslipDTO]) async throws -> [PayslipItem] {
        var payslipItems: [PayslipItem] = []
        
        for dto in dtos {
            // Create PayslipItem from DTO
            let payslipItem = PayslipItem(from: dto)
            
            // If the DTO doesn't have PDF data (which it doesn't for Sendable compliance),
            // we need to try to restore it from the file system
            if payslipItem.pdfData == nil {
                // Try to load PDF data from PDFManager using the payslip ID
                let pdfManager = PDFManager.shared
                if let pdfURL = pdfManager.getPDFURL(for: dto.id.uuidString) {
                    do {
                        let pdfData = try Data(contentsOf: pdfURL)
                        payslipItem.pdfData = pdfData
                    } catch {
                        // PDF file might not exist or be corrupted - that's okay, 
                        // the PDF generation system will handle it
                        print("Could not load PDF data for payslip \(dto.id): \(error)")
                    }
                }
            }
            
            payslipItems.append(payslipItem)
        }
        
        return payslipItems
    }

    /// Saves a payslip DTO using background-safe repository
    /// - Parameter payslipDTO: The payslip DTO to save
    func savePayslipItem(_ payslipDTO: PayslipDTO) async throws -> UUID {
        // Initialize the data service if it's not already initialized
        if !isServiceInitialized {
            try await dataService.initialize()
        }

        // Save the payslip item using repository
        let savedId = try await repository.savePayslip(payslipDTO)

        // Note: PDF handling would need to be implemented separately
        // as DTOs don't carry binary data for Sendable compliance
        print("[PayslipDataHandler] Successfully saved payslip with ID: \(savedId)")

        return savedId
    }

    /// Backward compatibility method that forwards to savePayslipItem
    /// - Parameter payslipDTO: The payslip DTO to save
    func savePayslip(_ payslipDTO: PayslipDTO) async throws -> UUID {
        return try await savePayslipItem(payslipDTO)
    }

    /// Deletes a payslip by ID using background-safe repository
    /// - Parameter payslipId: The ID of the payslip to delete
    func deletePayslipItem(withId payslipId: UUID) async throws -> Bool {
        // Initialize the data service if it's not already initialized
        if !isServiceInitialized {
            try await dataService.initialize()
        }

        // Delete the payslip item using repository
        return try await repository.deletePayslip(withId: payslipId)
    }

    /// Creates a payslip DTO from manual entry data
    /// - Parameter manualData: The manual entry data
    /// - Returns: A payslip DTO (Sendable)
    func createPayslipItemFromManualData(_ manualData: PayslipManualEntryData) -> PayslipDTO {
        // Calculate totals if they don't match the provided values
        let calculatedCredits = manualData.earnings.values.reduce(0, +)
        let calculatedDebits = manualData.deductions.values.reduce(0, +)

        // Use calculated values if they differ from provided and are greater than 0
        let finalCredits = (calculatedCredits != manualData.credits && calculatedCredits > 0) ? calculatedCredits : manualData.credits
        let finalDebits = (calculatedDebits != manualData.debits && calculatedDebits > 0) ? calculatedDebits : manualData.debits

        return PayslipDTO(
            id: UUID(),
            timestamp: Date(),
            month: manualData.month,
            year: manualData.year,
            credits: finalCredits,
            debits: finalDebits,
            dsop: manualData.dsop,
            tax: manualData.tax,
            earnings: manualData.earnings,
            deductions: manualData.deductions,
            name: manualData.name,
            accountNumber: manualData.accountNumber,
            panNumber: manualData.panNumber,
            source: manualData.source,
            notes: manualData.notes
        )
    }

    /// Creates a payslip from manual entry (alias for createPayslipItemFromManualData)
    /// - Parameter data: The manual entry data
    /// - Returns: A payslip DTO (Sendable)
    func createPayslipFromManualEntry(_ data: PayslipManualEntryData) -> PayslipDTO {
        return createPayslipItemFromManualData(data)
    }
}
