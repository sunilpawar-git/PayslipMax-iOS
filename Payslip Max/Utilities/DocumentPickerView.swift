import SwiftUI
import UIKit
import UniformTypeIdentifiers

/// A UIViewControllerRepresentable for picking PDF documents
struct DocumentPickerView: UIViewControllerRepresentable {
    let onDocumentPicked: (URL) -> Void
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.pdf])
        picker.delegate = context.coordinator
        picker.allowsMultipleSelection = false
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let parent: DocumentPickerView
        
        init(_ parent: DocumentPickerView) {
            self.parent = parent
        }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let originalURL = urls.first else { return }
            
            print("Document picked: \(originalURL.absoluteString)")
            
            // Start accessing the security-scoped resource
            let didStartAccessing = originalURL.startAccessingSecurityScopedResource()
            
            defer {
                // Make sure to release the security-scoped resource when finished
                if didStartAccessing {
                    originalURL.stopAccessingSecurityScopedResource()
                }
            }
            
            do {
                // Create a unique filename in the app's temporary directory
                let tempDirectoryURL = FileManager.default.temporaryDirectory
                let uniqueFilename = UUID().uuidString + ".pdf"
                let destinationURL = tempDirectoryURL.appendingPathComponent(uniqueFilename)
                
                print("Copying file to: \(destinationURL.absoluteString)")
                
                // Copy the file to our app's temporary directory
                try FileManager.default.copyItem(at: originalURL, to: destinationURL)
                
                // Verify the file was copied successfully
                guard FileManager.default.fileExists(atPath: destinationURL.path) else {
                    print("Error: File was not copied successfully")
                    throw NSError(domain: "DocumentPickerError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to copy file to temporary location"])
                }
                
                // Get file attributes to verify size
                let attributes = try FileManager.default.attributesOfItem(atPath: destinationURL.path)
                if let fileSize = attributes[.size] as? NSNumber {
                    print("Copied file size: \(fileSize) bytes")
                }
                
                // Now we can safely use this URL without permission issues
                DispatchQueue.main.async {
                    self.parent.onDocumentPicked(destinationURL)
                }
            } catch {
                print("Error copying file: \(error.localizedDescription)")
                
                // If copying fails, try to create a direct data copy
                do {
                    let fileData = try Data(contentsOf: originalURL)
                    print("Read \(fileData.count) bytes directly from original URL")
                    
                    let tempDirectoryURL = FileManager.default.temporaryDirectory
                    let uniqueFilename = UUID().uuidString + ".pdf"
                    let destinationURL = tempDirectoryURL.appendingPathComponent(uniqueFilename)
                    
                    try fileData.write(to: destinationURL)
                    print("Wrote data directly to: \(destinationURL.absoluteString)")
                    
                    // Verify the file was written successfully
                    guard FileManager.default.fileExists(atPath: destinationURL.path) else {
                        print("Error: File was not written successfully")
                        throw NSError(domain: "DocumentPickerError", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to write file data to temporary location"])
                    }
                    
                    // Get file attributes to verify size
                    let attributes = try FileManager.default.attributesOfItem(atPath: destinationURL.path)
                    if let fileSize = attributes[.size] as? NSNumber {
                        print("Written file size: \(fileSize) bytes")
                    }
                    
                    DispatchQueue.main.async {
                        self.parent.onDocumentPicked(destinationURL)
                    }
                } catch {
                    print("Error creating direct data copy: \(error.localizedDescription)")
                    // Last resort: try with the original URL
                    DispatchQueue.main.async {
                        self.parent.onDocumentPicked(originalURL)
                    }
                }
            }
        }
    }
} 