import Foundation

/// Service responsible for processing downloaded PDFs and extracting payslip data
protocol WebUploadPDFProcessingServiceProtocol {
    /// Process a downloaded PDF file
    func processDownloadedFile(uploadInfo: WebUploadInfo, password: String?) async throws
    
    /// Check if a PDF is password protected and validate password
    func checkPasswordProtection(url: URL, password: String?) async throws -> (Data, Bool)
    
    /// Extract payslip data from PDF data
    func extractPayslipData(from data: Data) async -> Result<PayslipItem, Error>
}

/// Implementation of PDF processing service for web uploads
class WebUploadPDFProcessingService: WebUploadPDFProcessingServiceProtocol {
    private let pdfService: PDFServiceProtocol
    private let uploadUpdateHandler: (WebUploadInfo) -> Void
    
    init(
        pdfService: PDFServiceProtocol,
        uploadUpdateHandler: @escaping (WebUploadInfo) -> Void
    ) {
        self.pdfService = pdfService
        self.uploadUpdateHandler = uploadUpdateHandler
    }
    
    func processDownloadedFile(uploadInfo: WebUploadInfo, password: String?) async throws {
        print("PDFProcessingService: Starting processing for upload: \(uploadInfo.id)")
        
        guard let localURL = uploadInfo.localURL else {
            print("PDFProcessingService: No local URL available for upload")
            throw WebUploadPDFProcessingError.missingLocalFile
        }
        
        var updatedInfo = uploadInfo
        updatedInfo.status = .downloaded
        uploadUpdateHandler(updatedInfo)
        
        do {
            // Check password protection and get PDF data
            let (data, requiresPassword) = try await checkPasswordProtection(url: localURL, password: password)
            
            if requiresPassword {
                print("PDFProcessingService: PDF is password protected")
                let passwordProtectedInfo = createPasswordProtectedInfo(from: updatedInfo)
                uploadUpdateHandler(passwordProtectedInfo)
                throw WebUploadPDFProcessingError.passwordProtected
            }
            
            // Extract payslip data from the PDF
            let payslipResult = await extractPayslipData(from: data)
            
            switch payslipResult {
            case .success(let payslipItem):
                try await processSuccessfulExtraction(payslipItem: payslipItem, uploadInfo: updatedInfo, pdfData: data)
                
            case .failure(let error):
                try await processFailedExtraction(uploadInfo: updatedInfo, pdfData: data, error: error)
            }
            
        } catch let error as WebUploadPDFProcessingError where error == .passwordProtected {
            print("PDFProcessingService: PDF is password protected")
            updatedInfo.status = .requiresPassword
            let mutableInfo = createPasswordProtectedInfo(from: uploadInfo)
            uploadUpdateHandler(mutableInfo)
            throw error
        } catch {
            print("PDFProcessingService: Failed to process PDF: \(error)")
            updatedInfo.status = .failed
            uploadUpdateHandler(updatedInfo)
            throw error
        }
    }
    
    func checkPasswordProtection(url: URL, password: String?) async throws -> (Data, Bool) {
        print("PDFProcessingService: Checking password protection for file at \(url.path)")
        
        // Get the PDF processing service for password handling
        let pdfProcessingService = await DIContainer.shared.makePDFProcessingService()
        
        // Load the PDF data
        let pdfData: Data
        do {
            pdfData = try Data(contentsOf: url)
        } catch {
            print("PDFProcessingService: Failed to load PDF data: \(error)")
            throw WebUploadPDFProcessingError.fileLoadError(error)
        }
        
        // Check if it's password protected
        if await pdfProcessingService.isPasswordProtected(pdfData) {
            print("PDFProcessingService: PDF is password protected")
            
            // If no password provided, indicate it needs a password
            guard let providedPassword = password, !providedPassword.isEmpty else {
                return (Data(), true)
            }
            
            // Try to unlock with the provided password
            print("PDFProcessingService: Attempting to unlock PDF with provided password")
            let unlockResult = await pdfProcessingService.unlockPDF(pdfData, password: providedPassword)
            
            switch unlockResult {
            case .success(let unlockedData):
                print("PDFProcessingService: Successfully unlocked PDF")
                return (unlockedData, false)
            case .failure:
                print("PDFProcessingService: Failed to unlock PDF with provided password")
                return (Data(), true)
            }
        }
        
        // Not password protected
        return (pdfData, false)
    }
    
    func extractPayslipData(from data: Data) async -> Result<PayslipItem, any Error> {
        print("PDFProcessingService: Extracting payslip data from PDF")
        
        let pdfProcessingService = await DIContainer.shared.makePDFProcessingService()
        let result = await pdfProcessingService.processPDFData(data)
        
        // Map the result to convert PDFProcessingError to any Error
        return result.mapError { error in error as any Error }
    }
    
    // MARK: - Private Methods
    
    private func createPasswordProtectedInfo(from uploadInfo: WebUploadInfo) -> WebUploadInfo {
        return WebUploadInfo(
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
    }
    
    private func processSuccessfulExtraction(
        payslipItem: PayslipItem, 
        uploadInfo: WebUploadInfo, 
        pdfData: Data
    ) async throws {
        print("PDFProcessingService: Successfully extracted PayslipItem with ID: \(payslipItem.id)")
        
        // Ensure the payslip has the PDF data attached
        if payslipItem.pdfData == nil || payslipItem.pdfData!.isEmpty {
            payslipItem.pdfData = pdfData
        }
        
        // Save to data service
        let dataService = await DIContainer.shared.dataService
        try await dataService.save(payslipItem)
        print("PDFProcessingService: Successfully saved PayslipItem to database")

        // Update the status to processed
        var updatedInfo = uploadInfo
        updatedInfo.status = .processed
        uploadUpdateHandler(updatedInfo)
        print("PDFProcessingService: Successfully processed file")
    }
    
    private func processFailedExtraction(
        uploadInfo: WebUploadInfo, 
        pdfData: Data, 
        error: Error
    ) async throws {
        print("PDFProcessingService: Failed to extract payslip data: \(error)")
        
        // Create a basic PayslipItem with the PDF data
        let currentDate = Date()
        let calendar = Calendar.current
        let currentMonth = String(calendar.component(.month, from: currentDate))
        let currentYear = calendar.component(.year, from: currentDate)
        
        let payslipItem = PayslipItem(
            id: UUID(),
            timestamp: currentDate,
            month: currentMonth,
            year: currentYear,
            credits: 0,
            debits: 0,
            dsop: 0,
            tax: 0,
            name: uploadInfo.filename,
            accountNumber: "",
            panNumber: "",
            pdfData: pdfData,
            source: "Web Upload"
        )
        
        // Save basic PayslipItem to data service
        let dataService = await DIContainer.shared.dataService
        try await dataService.save(payslipItem)
        print("PDFProcessingService: Saved basic PayslipItem to database with ID: \(payslipItem.id)")
        
        // Mark as processed even though we couldn't extract detailed data
        var updatedInfo = uploadInfo
        updatedInfo.status = .processed
        uploadUpdateHandler(updatedInfo)
        print("PDFProcessingService: Marked as processed with basic data")
    }
}

// MARK: - Error Types

enum WebUploadPDFProcessingError: Error, LocalizedError, Equatable {
    case missingLocalFile
    case fileLoadError(Error)
    case passwordProtected
    case processingFailed(Error)
    
    var errorDescription: String? {
        switch self {
        case .missingLocalFile:
            return "No local file available for processing"
        case .fileLoadError(let error):
            return "Failed to load PDF file: \(error.localizedDescription)"
        case .passwordProtected:
            return "PDF requires a password to process"
        case .processingFailed(let error):
            return "Failed to process PDF: \(error.localizedDescription)"
        }
    }
    
    static func == (lhs: WebUploadPDFProcessingError, rhs: WebUploadPDFProcessingError) -> Bool {
        switch (lhs, rhs) {
        case (.missingLocalFile, .missingLocalFile):
            return true
        case (.passwordProtected, .passwordProtected):
            return true
        case (.fileLoadError, .fileLoadError):
            return true
        case (.processingFailed, .processingFailed):
            return true
        default:
            return false
        }
    }
} 