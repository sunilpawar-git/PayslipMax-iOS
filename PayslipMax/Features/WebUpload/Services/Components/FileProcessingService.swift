import Foundation
import SwiftUI

// MARK: - File Processing Service Protocol

protocol FileProcessingServiceProtocol {
    func processDownloadedFile(uploadInfo: WebUploadInfo, password: String?) async throws -> WebUploadInfo
    func checkPasswordProtection(url: URL, password: String?) async throws -> (Data, Bool)
}

// MARK: - File Processing Service Implementation

final class FileProcessingService: FileProcessingServiceProtocol {
    
    // MARK: - Dependencies
    
    private let fileManager: FileManager
    private let uploadUpdateHandler: (WebUploadInfo) -> Void
    
    // MARK: - Initialization
    
    init(
        fileManager: FileManager = .default,
        uploadUpdateHandler: @escaping (WebUploadInfo) -> Void
    ) {
        self.fileManager = fileManager
        self.uploadUpdateHandler = uploadUpdateHandler
    }
    
    // MARK: - File Processing
    
    func processDownloadedFile(uploadInfo: WebUploadInfo, password: String?) async throws -> WebUploadInfo {
        print("FileProcessingService: Processing downloaded file - ID: \(uploadInfo.id), StringID: \(uploadInfo.stringID ?? "nil"), LocalURL: \(uploadInfo.localURL?.path ?? "nil")")
        
        guard let localURL = uploadInfo.localURL else {
            print("FileProcessingService: LocalURL is nil for upload \(uploadInfo.id)")
            throw NSError(domain: "WebUploadErrorDomain", code: 3, userInfo: [NSLocalizedDescriptionKey: "File not downloaded"])
        }
        
        // Verify the file exists at the localURL
        guard fileManager.fileExists(atPath: localURL.path) else {
            print("FileProcessingService: File does not exist at path: \(localURL.path)")
            throw NSError(domain: "WebUploadErrorDomain", code: 4, userInfo: [NSLocalizedDescriptionKey: "File not found at expected location"])
        }
        
        var updatedInfo = uploadInfo
        
        do {
            print("FileProcessingService: Starting PDF processing for file at \(localURL.path)")
            
            // Get the current date components for setting month and year in case we need them
            let dateComponents = Calendar.current.dateComponents([.month, .year], from: Date())
            let currentMonth = Calendar.current.monthSymbols[dateComponents.month! - 1] // Convert 1-based month to month name
            let currentYear = dateComponents.year!
            
            // Process the PDF using the PDF processing service to extract data
            let pdfProcessingService = await DIContainer.shared.makePDFProcessingService()
            
            // First check if the PDF is password protected
            let (data, requiresPassword) = try await checkPasswordProtection(url: localURL, password: password)
            
            if requiresPassword {
                // Mark as requiring password and throw the appropriate error
                print("FileProcessingService: PDF is password protected")
                // Create a new instance with updated values
                let passwordProtectedInfo = WebUploadInfo(
                    id: updatedInfo.id,
                    stringID: updatedInfo.stringID,
                    filename: updatedInfo.filename,
                    uploadedAt: updatedInfo.uploadedAt,
                    fileSize: updatedInfo.fileSize,
                    isPasswordProtected: true,
                    source: updatedInfo.source,
                    status: .requiresPassword,
                    secureToken: updatedInfo.secureToken,
                    localURL: updatedInfo.localURL
                )
                uploadUpdateHandler(passwordProtectedInfo)
                throw PDFProcessingError.passwordProtected
            }
            
            // If we got here, we have valid PDF data to process
            let payslipResult = await pdfProcessingService.processPDFData(data)
            
            switch payslipResult {
            case .success(let payslipItem):
                print("FileProcessingService: Successfully extracted PayslipItem with ID: \(payslipItem.id)")
                
                // Ensure the payslip has the PDF data attached
                if payslipItem.pdfData == nil || payslipItem.pdfData!.isEmpty {
                    payslipItem.pdfData = data
                }
                
                // Save to data service
                let dataService = await DIContainer.shared.dataService
                try await dataService.save(payslipItem)
                print("FileProcessingService: Successfully saved PayslipItem to database")
        
                // Update the status to processed
                updatedInfo.status = .processed
                uploadUpdateHandler(updatedInfo)
                print("FileProcessingService: Successfully processed file")
                
                return updatedInfo
                
            case .failure(let error):
                print("FileProcessingService: Failed to extract payslip data: \(error)")
                // Create a basic PayslipItem with the PDF data
                let payslipItem = PayslipItem(
                    id: UUID(),
                    timestamp: Date(),
                    month: currentMonth,
                    year: currentYear,
                    credits: 0,
                    debits: 0,
                    dsop: 0,
                    tax: 0,
                    name: localURL.lastPathComponent,
                    accountNumber: "",
                    panNumber: "",
                    pdfData: data,
                    source: "Web Upload"
                )
                
                // Save basic PayslipItem to data service
                let dataService = await DIContainer.shared.dataService
                try await dataService.save(payslipItem)
                print("FileProcessingService: Saved basic PayslipItem to database with ID: \(payslipItem.id)")
                
                // Mark as processed even though we couldn't extract detailed data
                updatedInfo.status = .processed
                uploadUpdateHandler(updatedInfo)
                print("FileProcessingService: Marked as processed with basic data")
                
                return updatedInfo
            }
            
        } catch let error as PDFProcessingError where error == .passwordProtected {
            // If password is required, update status
            print("FileProcessingService: PDF is password protected")
            updatedInfo.status = .requiresPassword
            // Create a new copy with the password protection flag set to true
            let mutableInfo = WebUploadInfo(
                id: uploadInfo.id,
                stringID: uploadInfo.stringID,
                filename: uploadInfo.filename,
                uploadedAt: uploadInfo.uploadedAt,
                fileSize: uploadInfo.fileSize,
                isPasswordProtected: true,
                source: uploadInfo.source,
                status: .requiresPassword,
                secureToken: uploadInfo.secureToken,
                localURL: uploadInfo.localURL
            )
            uploadUpdateHandler(mutableInfo)
            throw error
        } catch {
            // If processing failed, update status
            print("FileProcessingService: Failed to process PDF: \(error)")
            updatedInfo.status = .failed
            uploadUpdateHandler(updatedInfo)
            throw error
        }
    }
    
    // MARK: - Password Protection Checking
    
    func checkPasswordProtection(url: URL, password: String?) async throws -> (Data, Bool) {
        print("FileProcessingService: Checking password protection for file at \(url.path)")
        
        // Get the PDF processing service for password handling
        let pdfProcessingService = await DIContainer.shared.makePDFProcessingService()
        
        // First try to load the PDF data
        let pdfData: Data
        do {
            pdfData = try Data(contentsOf: url)
        } catch {
            print("FileProcessingService: Failed to load PDF data: \(error)")
            throw NSError(domain: "WebUploadErrorDomain", code: 5, userInfo: [NSLocalizedDescriptionKey: "Could not load PDF data"])
        }
        
        // Check if it's password protected
        if await pdfProcessingService.isPasswordProtected(pdfData) {
            print("FileProcessingService: PDF is password protected")
            
            // If no password provided, indicate it needs a password
            guard let providedPassword = password, !providedPassword.isEmpty else {
                return (Data(), true)
            }
            
            // Try to unlock with the provided password
            print("FileProcessingService: Attempting to unlock PDF with provided password")
            let unlockResult = await pdfProcessingService.unlockPDF(pdfData, password: providedPassword)
            
            switch unlockResult {
            case .success(let unlockedData):
                print("FileProcessingService: Successfully unlocked PDF")
                return (unlockedData, false)
            case .failure:
                print("FileProcessingService: Failed to unlock PDF with provided password")
                return (Data(), true)
            }
        }
        
        // Not password protected
        return (pdfData, false)
    }
} 