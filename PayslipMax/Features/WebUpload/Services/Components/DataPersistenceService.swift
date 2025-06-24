import Foundation

// MARK: - Data Persistence Service Protocol

protocol DataPersistenceServiceProtocol {
    func saveUploads(_ uploads: [WebUploadInfo])
    func loadSavedUploads() async throws -> [WebUploadInfo]
    func updateUpload(_ upload: WebUploadInfo, in uploads: inout [WebUploadInfo])
    func getPendingUploads(from uploads: [WebUploadInfo]) -> [WebUploadInfo]
    func getAllUploads(from uploads: [WebUploadInfo]) -> [WebUploadInfo]
}

// MARK: - Data Persistence Service Implementation

final class DataPersistenceService: DataPersistenceServiceProtocol {
    
    // MARK: - Dependencies
    
    private let fileManager: FileManager
    private let uploadDirectory: URL
    
    // MARK: - Initialization
    
    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
        
        // Create the upload directory
        let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        self.uploadDirectory = documentsDirectory.appendingPathComponent("WebUploads")
        
        // Ensure directory exists
        try? fileManager.createDirectory(at: uploadDirectory, withIntermediateDirectories: true, attributes: nil)
    }
    
    // MARK: - Upload Management
    
    func saveUploads(_ uploads: [WebUploadInfo]) {
        do {
            let data = try JSONEncoder().encode(uploads)
            let savePath = uploadDirectory.appendingPathComponent("uploads.json")
            print("DataPersistenceService: Saving uploads to \(savePath.path)")
            try data.write(to: savePath)
            print("DataPersistenceService: Successfully saved \(uploads.count) uploads")
        } catch {
            print("DataPersistenceService: Failed to save uploads: \(error)")
        }
    }
    
    func loadSavedUploads() async throws -> [WebUploadInfo] {
        let savePath = uploadDirectory.appendingPathComponent("uploads.json")
        
        guard fileManager.fileExists(atPath: savePath.path) else {
            print("DataPersistenceService: No saved uploads file found")
            return []
        }
        
        do {
            let data = try Data(contentsOf: savePath)
            let uploads = try JSONDecoder().decode([WebUploadInfo].self, from: data)
            print("DataPersistenceService: Successfully loaded \(uploads.count) uploads")
            return uploads
        } catch {
            print("DataPersistenceService: Failed to load saved uploads: \(error)")
            return []
        }
    }
    
    func updateUpload(_ upload: WebUploadInfo, in uploads: inout [WebUploadInfo]) {
        print("DataPersistenceService: Updating upload - ID: \(upload.id), StringID: \(upload.stringID ?? "nil"), Status: \(upload.status), LocalURL: \(upload.localURL?.path ?? "nil")")
        
        // Try to find the upload either by UUID or by string ID
        let index = uploads.firstIndex { existingUpload in
            if existingUpload.id == upload.id {
                return true
            }
            if let uploadStringID = upload.stringID,
               let existingStringID = existingUpload.stringID,
               uploadStringID == existingStringID {
                return true
            }
            return false
        }
        
        if let index = index {
            // Update existing
            print("DataPersistenceService: Updating existing upload at index \(index)")
            uploads[index] = upload
        } else {
            // Add new
            print("DataPersistenceService: Adding new upload")
            uploads.append(upload)
        }
        
        // Save the updated list
        saveUploads(uploads)
    }
    
    func getPendingUploads(from uploads: [WebUploadInfo]) -> [WebUploadInfo] {
        // Return uploads that are not yet processed
        return uploads.filter { $0.status != .processed }
    }
    
    func getAllUploads(from uploads: [WebUploadInfo]) -> [WebUploadInfo] {
        // Return all uploads without filtering
        return uploads
    }
} 