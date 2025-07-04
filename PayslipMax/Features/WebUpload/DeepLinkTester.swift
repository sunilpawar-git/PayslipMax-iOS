import Foundation
import SwiftUI

/// Helper for testing deep links in debug builds
@MainActor
struct DeepLinkTester {
    // Note: Deep link handling is now done through NavigationCoordinator
    // This tester focuses on the web upload functionality
    
    /// Test handling of a web upload deep link
    static func testWebUploadDeepLink() async {
        // Create a test URL similar to what the website would generate
        let urlString = "payslipmax://upload?id=upload_68394f0d7fbc83.79452754&filename=6836e5a8af525_03+Mar+2024.pdf&size=119865&timestamp=1748586253&hash=e0a0f9e13342ef66d468def82e602c7058b2f211dcae105ccfb0dac5f6925b8e&token=6bcfe6fe339f08c8c459abb8283f26deeccb2e331e35b0097f3c4d29d85fb88a&protected=false&source=website"
        
        guard let url = URL(string: urlString) else {
            print("Failed to create URL from string")
            return
        }
        
        // Process the URL directly
        let coordinator = DIContainer.shared.makeWebUploadDeepLinkHandler()
        let handled = coordinator.processURL(url)
        print("Deep link handled: \(handled)")
    }
    
    /// Test a direct download
    static func testDirectDownload() async {
        let uploadInfo = WebUploadInfo(
            stringID: "test12345",
            filename: "direct_test.pdf",
            uploadedAt: Date(),
            fileSize: 120000,
            isPasswordProtected: false,
            source: "web",
            status: .pending,
            secureToken: "testtokenxyz"
        )
        
        let service = DIContainer.shared.makeWebUploadService()
        do {
            print("Starting direct download test...")
            let url = try await service.downloadFile(from: uploadInfo)
            print("Download succeeded to: \(url.path)")
            
            let exists = FileManager.default.fileExists(atPath: url.path)
            print("File exists: \(exists)")
            
            if exists {
                // Check file size
                let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
                if let size = attributes[.size] as? Int {
                    print("File size: \(size) bytes")
                }
            }
        } catch {
            print("Download test failed with error: \(error)")
        }
    }
    
    /// Test processing a downloaded file
    static func testProcessDownloadedFile() async {
        let uploads = await DIContainer.shared.makeWebUploadService().getPendingUploads()
        print("Found \(uploads.count) pending uploads")
        
        for upload in uploads {
            print("Upload: ID=\(upload.id), StringID=\(upload.stringID ?? "nil"), Status=\(upload.status)")
            if let localURL = upload.localURL {
                print("  - LocalURL: \(localURL.path)")
                let exists = FileManager.default.fileExists(atPath: localURL.path)
                print("  - File exists: \(exists)")
            } else {
                print("  - No local URL")
            }
        }
        
        // Try to process the first pending upload
        if let upload = uploads.first(where: { $0.status == .downloaded || $0.status == .pending }) {
            print("Attempting to process upload: \(upload.id)")
            do {
                try await DIContainer.shared.makeWebUploadService().processDownloadedFile(uploadInfo: upload, password: nil)
                print("Processing succeeded")
            } catch {
                print("Processing failed with error: \(error)")
            }
        } else {
            print("No suitable upload found for processing test")
        }
    }
}

/// SwiftUI View for testing deep links
struct DeepLinkTesterView: View {
    @State private var lastTestedURL = ""
    @State private var urlToTest = "payslipmax://upload?id=6819ecb162f8d&filename=test.pdf&size=119688&source=web&token=eb8b7c095cf8b3babca806440ada88db&protected=false"
    @State private var testResult = ""
    @State private var showActions = false
    
    @State private var webUploadHandler: WebUploadDeepLinkHandler?
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Deep Link Tester")
                .font(.title)
                .padding()
            
            TextField("Enter URL to test", text: $urlToTest, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .padding()
            
            HStack {
                Button("Test Deep Link") {
                    testDeepLink()
                }
                .buttonStyle(.borderedProminent)
                
                Button("More Tests") {
                    showActions = true
                }
                .buttonStyle(.bordered)
                .actionSheet(isPresented: $showActions) {
                    ActionSheet(
                        title: Text("Select Test"),
                        buttons: [
                            .default(Text("Test Direct Download")) {
                                Task {
                                    await testDirectDownload()
                                }
                            },
                            .default(Text("Test File Processing")) {
                                Task {
                                    await testFileProcessing()
                                }
                            },
                            .default(Text("List Uploads Directory")) {
                                Task {
                                    await listUploadsDirectory()
                                }
                            },
                            .cancel()
                        ]
                    )
                }
            }
            
            if !testResult.isEmpty {
                VStack(alignment: .leading) {
                    Text("Result:")
                        .font(.headline)
                    
                    ScrollView {
                        Text(testResult)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                    }
                    .frame(maxHeight: 300)
                }
                .padding()
            }
        }
        .padding()
        .task {
            // Initialize the handler on the main actor
            webUploadHandler = DIContainer.shared.makeWebUploadDeepLinkHandler()
        }
    }
    
    private func testDeepLink() {
        guard let url = URL(string: urlToTest), let handler = webUploadHandler else {
            testResult = "Error: Invalid URL or handler not initialized"
            return
        }
        
        lastTestedURL = urlToTest
        let handled = handler.processURL(url)
        testResult = "URL: \(url.absoluteString)\nHandled: \(handled)"
    }
    
    private func testDirectDownload() async {
        testResult = "Starting direct download test...\n"
        let service = DIContainer.shared.makeWebUploadService()
        let uploadInfo = WebUploadInfo(
            stringID: "manual_test_\(Int(Date().timeIntervalSince1970))",
            filename: "manual_test.pdf",
            uploadedAt: Date(),
            fileSize: 120000,
            isPasswordProtected: false,
            source: "test",
            status: .pending,
            secureToken: "test_token_\(Int(Date().timeIntervalSince1970))"
        )
        
        do {
            testResult += "Attempting download...\n"
            let url = try await service.downloadFile(from: uploadInfo)
            testResult += "Download succeeded to: \(url.path)\n"
            
            let exists = FileManager.default.fileExists(atPath: url.path)
            testResult += "File exists: \(exists)\n"
            
            if exists {
                // Check file size
                let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
                if let size = attributes[.size] as? Int {
                    testResult += "File size: \(size) bytes\n"
                }
            }
        } catch {
            testResult += "Download failed with error: \(error.localizedDescription)\n"
        }
    }
    
    private func testFileProcessing() async {
        testResult = "Testing file processing...\n"
        let service = DIContainer.shared.makeWebUploadService()
        let uploads = await service.getPendingUploads()
        testResult += "Found \(uploads.count) pending uploads\n"
        
        for upload in uploads {
            testResult += "- Upload: ID=\(upload.id), StringID=\(upload.stringID ?? "nil"), Status=\(upload.status)\n"
            if let localURL = upload.localURL {
                testResult += "  - LocalURL: \(localURL.path)\n"
                let exists = FileManager.default.fileExists(atPath: localURL.path)
                testResult += "  - File exists: \(exists)\n"
            } else {
                testResult += "  - No local URL\n"
            }
        }
        
        // Try to process the first pending upload
        if let upload = uploads.first(where: { $0.status == .downloaded || $0.status == .pending }) {
            testResult += "Attempting to process upload: \(upload.id)\n"
            do {
                try await service.processDownloadedFile(uploadInfo: upload, password: nil)
                testResult += "Processing succeeded\n"
            } catch {
                testResult += "Processing failed with error: \(error.localizedDescription)\n"
            }
        } else {
            testResult += "No suitable upload found for processing test\n"
        }
    }
    
    private func listUploadsDirectory() async {
        testResult = "Listing uploads directory...\n"
        
        // Get the uploads directory
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let uploadsDirectory = documentsDirectory.appendingPathComponent("WebUploads", isDirectory: true)
        
        do {
            let fileURLs = try FileManager.default.contentsOfDirectory(at: uploadsDirectory, 
                                                                       includingPropertiesForKeys: [.fileSizeKey, .creationDateKey],
                                                                       options: .skipsHiddenFiles)
            
            testResult += "Directory: \(uploadsDirectory.path)\n"
            testResult += "Found \(fileURLs.count) files:\n"
            
            for fileURL in fileURLs.sorted(by: { $0.lastPathComponent < $1.lastPathComponent }) {
                let attrs = try FileManager.default.attributesOfItem(atPath: fileURL.path)
                let size = attrs[.size] as? Int64 ?? 0
                let created = attrs[.creationDate] as? Date ?? Date()
                let formatter = DateFormatter()
                formatter.dateStyle = .short
                formatter.timeStyle = .short
                
                testResult += "- \(fileURL.lastPathComponent): \(size) bytes, created \(formatter.string(from: created))\n"
            }
        } catch {
            testResult += "Error listing directory: \(error.localizedDescription)\n"
        }
    }
}

#Preview {
    DeepLinkTesterView()
} 