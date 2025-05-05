import Foundation
import Combine

#if DEBUG

/// Mock implementation of WebUploadServiceProtocol for testing
class MockWebUploadService: WebUploadServiceProtocol {
    /// Mock uploads
    private var mockUploads: [WebUploadInfo] = []
    /// Subject for uploads publisher
    private let uploadSubject = CurrentValueSubject<[WebUploadInfo], Never>([])
    /// Mock device token
    private var mockDeviceToken: String = "MOCK-DEVICE-TOKEN-12345"
    /// Mock passwords
    private var passwords: [UUID: String] = [:]

    /// Track uploads via publisher
    var uploadsPublisher: AnyPublisher<[WebUploadInfo], Never> {
        uploadSubject.eraseToAnyPublisher()
    }
    
    /// Mock error to throw if needed
    var mockError: Error?
    
    /// Create some sample uploads for testing
    init(createSampleUploads: Bool = true) {
        if createSampleUploads {
            let sampleUploads = [
                WebUploadInfo(
                    id: UUID(),
                    filename: "Sample_Payslip_1.pdf",
                    uploadedAt: Date().addingTimeInterval(-3600), // 1 hour ago
                    fileSize: 56789,
                    isPasswordProtected: false,
                    source: "www.payslipmax.com",
                    status: .pending
                ),
                WebUploadInfo(
                    id: UUID(),
                    filename: "Protected_Payslip.pdf",
                    uploadedAt: Date().addingTimeInterval(-7200), // 2 hours ago
                    fileSize: 123456,
                    isPasswordProtected: true,
                    source: "www.payslipmax.com",
                    status: .requiresPassword
                ),
                WebUploadInfo(
                    id: UUID(),
                    filename: "Processed_File.pdf",
                    uploadedAt: Date().addingTimeInterval(-86400), // 1 day ago
                    fileSize: 98765,
                    isPasswordProtected: false,
                    source: "www.payslipmax.com",
                    status: .processed
                )
            ]
            
            mockUploads = sampleUploads
            uploadSubject.send(mockUploads)
        }
    }
    
    /// Register device for receiving web uploads
    func registerDevice() async throws -> String {
        if let error = mockError {
            throw error
        }
        return mockDeviceToken
    }
    
    /// Download file from the web service
    func downloadFile(from uploadInfo: WebUploadInfo) async throws -> URL {
        if let error = mockError {
            throw error
        }
        
        // Update the status
        var updatedInfo = uploadInfo
        updatedInfo.status = .downloaded
        updatedInfo.localURL = URL(string: "file:///mock/path/\(uploadInfo.filename)")
        
        // Update in the array
        if let index = mockUploads.firstIndex(where: { $0.id == uploadInfo.id }) {
            mockUploads[index] = updatedInfo
        } else {
            mockUploads.append(updatedInfo)
        }
        
        // Send the update
        uploadSubject.send(mockUploads)
        
        return URL(string: "file:///mock/path/\(uploadInfo.filename)")!
    }
    
    /// Process a downloaded file
    func processDownloadedFile(uploadInfo: WebUploadInfo, password: String?) async throws {
        if let error = mockError {
            throw error
        }
        
        // Check if password is required
        if uploadInfo.isPasswordProtected {
            if password == nil {
                // Simulate password required error
                let updatedInfo = uploadInfo
                if let index = mockUploads.firstIndex(where: { $0.id == uploadInfo.id }) {
                    mockUploads[index] = updatedInfo
                }
                uploadSubject.send(mockUploads)
                throw PDFProcessingError.passwordRequired
            }
            
            // Check if password is correct (for testing, any non-empty password is "correct")
            if password!.isEmpty {
                throw PDFProcessingError.incorrectPassword
            }
        }
        
        // Process successfully
        var updatedInfo = uploadInfo
        updatedInfo.status = .processed
        
        // Update in the array
        if let index = mockUploads.firstIndex(where: { $0.id == uploadInfo.id }) {
            mockUploads[index] = updatedInfo
        }
        
        // Send the update
        uploadSubject.send(mockUploads)
    }
    
    /// Get list of pending uploads
    func getPendingUploads() async -> [WebUploadInfo] {
        return mockUploads.filter { $0.status != .processed }
    }
    
    /// Save password for a password-protected PDF
    func savePassword(for uploadId: UUID, password: String) throws {
        if let error = mockError {
            throw error
        }
        
        passwords[uploadId] = password
        
        // Update the upload status if it exists
        if let index = mockUploads.firstIndex(where: { $0.id == uploadId }) {
            var updatedUpload = mockUploads[index]
            if updatedUpload.status == .requiresPassword {
                updatedUpload.status = .pending
                mockUploads[index] = updatedUpload
            }
        }
        
        uploadSubject.send(mockUploads)
    }
    
    /// Get saved password for a PDF if available
    func getPassword(for uploadId: UUID) -> String? {
        return passwords[uploadId]
    }
}

/// Mock implementation of SecureStorageProtocol for testing
class MockSecureStorage: SecureStorageProtocol {
    /// Storage for mock data
    private var storage: [String: Data] = [:]
    /// Storage for mock strings
    private var stringStorage: [String: String] = [:]
    
    /// Save data securely
    func saveData(key: String, data: Data) throws {
        storage[key] = data
    }
    
    /// Retrieve data securely
    func getData(key: String) throws -> Data? {
        return storage[key]
    }
    
    /// Save string securely
    func saveString(key: String, value: String) throws {
        stringStorage[key] = value
    }
    
    /// Retrieve string securely
    func getString(key: String) throws -> String? {
        return stringStorage[key]
    }
    
    /// Delete item from secure storage
    func deleteItem(key: String) throws {
        storage.removeValue(forKey: key)
        stringStorage.removeValue(forKey: key)
    }
}

#endif 