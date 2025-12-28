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

        let localURL = try validateLocalURL(uploadInfo)
        var updatedInfo = uploadInfo

        do {
            print("FileProcessingService: Starting PDF processing for file at \(localURL.path)")

            let pdfProcessingService = await DIContainer.shared.makePDFProcessingService()
            let (data, requiresPassword) = try await checkPasswordProtection(url: localURL, password: password)

            if requiresPassword {
                handlePasswordProtection(uploadInfo: uploadInfo)
                throw PDFProcessingError.passwordProtected
            }

            let payslipResult = await pdfProcessingService.processPDFData(data)
            return try await handleProcessingResult(payslipResult, data: data, localURL: localURL, updatedInfo: &updatedInfo)

        } catch let error as PDFProcessingError where error == .passwordProtected {
            handlePasswordRequiredError(uploadInfo: uploadInfo)
            throw error
        } catch {
            print("FileProcessingService: Failed to process PDF: \(error)")
            updatedInfo.status = .failed
            uploadUpdateHandler(updatedInfo)
            throw error
        }
    }

    // MARK: - Password Protection Checking

    func checkPasswordProtection(url: URL, password: String?) async throws -> (Data, Bool) {
        print("FileProcessingService: Checking password protection for file at \(url.path)")

        let pdfProcessingService = await DIContainer.shared.makePDFProcessingService()

        let pdfData: Data
        do {
            pdfData = try Data(contentsOf: url)
        } catch {
            print("FileProcessingService: Failed to load PDF data: \(error)")
            throw NSError(domain: "WebUploadErrorDomain", code: 5, userInfo: [NSLocalizedDescriptionKey: "Could not load PDF data"])
        }

        if await pdfProcessingService.isPasswordProtected(pdfData) {
            return try await handlePasswordProtectedPDF(pdfData: pdfData, password: password, service: pdfProcessingService)
        }

        return (pdfData, false)
    }

    // MARK: - Private Helpers

    private func validateLocalURL(_ uploadInfo: WebUploadInfo) throws -> URL {
        guard let localURL = uploadInfo.localURL else {
            print("FileProcessingService: LocalURL is nil for upload \(uploadInfo.id)")
            throw NSError(domain: "WebUploadErrorDomain", code: 3, userInfo: [NSLocalizedDescriptionKey: "File not downloaded"])
        }

        guard fileManager.fileExists(atPath: localURL.path) else {
            print("FileProcessingService: File does not exist at path: \(localURL.path)")
            throw NSError(domain: "WebUploadErrorDomain", code: 4, userInfo: [NSLocalizedDescriptionKey: "File not found at expected location"])
        }

        return localURL
    }

    private func handlePasswordProtection(uploadInfo: WebUploadInfo) {
        print("FileProcessingService: PDF is password protected")
        let passwordProtectedInfo = WebUploadInfo(
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
        uploadUpdateHandler(passwordProtectedInfo)
    }

    private func handlePasswordRequiredError(uploadInfo: WebUploadInfo) {
        print("FileProcessingService: PDF is password protected")
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
    }

    private func handleProcessingResult(
        _ result: Result<PayslipItem, PDFProcessingError>,
        data: Data,
        localURL: URL,
        updatedInfo: inout WebUploadInfo
    ) async throws -> WebUploadInfo {
        switch result {
        case .success(let payslipItem):
            return try await handleSuccessfulProcessing(payslipItem: payslipItem, data: data, updatedInfo: &updatedInfo)
        case .failure(let error):
            return try await handleFailedProcessing(error: error, data: data, localURL: localURL, updatedInfo: &updatedInfo)
        }
    }

    private func handleSuccessfulProcessing(
        payslipItem: PayslipItem,
        data: Data,
        updatedInfo: inout WebUploadInfo
    ) async throws -> WebUploadInfo {
        print("FileProcessingService: Successfully extracted PayslipItem with ID: \(payslipItem.id)")

        if payslipItem.pdfData == nil || payslipItem.pdfData!.isEmpty {
            payslipItem.pdfData = data
        }

        let repository = await DIContainer.shared.makeSendablePayslipRepository()
        let payslipDTO = PayslipDTO(from: payslipItem)
        _ = try await repository.savePayslip(payslipDTO)
        print("FileProcessingService: Successfully saved PayslipItem to database")

        updatedInfo.status = .processed
        uploadUpdateHandler(updatedInfo)
        print("FileProcessingService: Successfully processed file")

        return updatedInfo
    }

    private func handleFailedProcessing(
        error: PDFProcessingError,
        data: Data,
        localURL: URL,
        updatedInfo: inout WebUploadInfo
    ) async throws -> WebUploadInfo {
        print("FileProcessingService: Failed to extract payslip data: \(error)")

        let dateComponents = Calendar.current.dateComponents([.month, .year], from: Date())
        let currentMonth = Calendar.current.monthSymbols[dateComponents.month! - 1]
        let currentYear = dateComponents.year!

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

        let repository = await DIContainer.shared.makeSendablePayslipRepository()
        let payslipDTO = PayslipDTO(from: payslipItem)
        _ = try await repository.savePayslip(payslipDTO)
        print("FileProcessingService: Saved basic PayslipItem to database with ID: \(payslipItem.id)")

        updatedInfo.status = .processed
        uploadUpdateHandler(updatedInfo)
        print("FileProcessingService: Marked as processed with basic data")

        return updatedInfo
    }

    private func handlePasswordProtectedPDF(
        pdfData: Data,
        password: String?,
        service: PDFProcessingServiceProtocol
    ) async throws -> (Data, Bool) {
        print("FileProcessingService: PDF is password protected")

        guard let providedPassword = password, !providedPassword.isEmpty else {
            return (Data(), true)
        }

        print("FileProcessingService: Attempting to unlock PDF with provided password")
        let unlockResult = await service.unlockPDF(pdfData, password: providedPassword)

        switch unlockResult {
        case .success(let unlockedData):
            print("FileProcessingService: Successfully unlocked PDF")
            return (unlockedData, false)
        case .failure:
            print("FileProcessingService: Failed to unlock PDF with provided password")
            return (Data(), true)
        }
    }
}
