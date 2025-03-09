import SwiftUI
import UIKit

/// A custom share sheet for sharing text content.
struct CustomShareSheet: UIViewControllerRepresentable {
    let text: String
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        // Create a temporary file for sharing
        let tempDir = FileManager.default.temporaryDirectory
        let fileName = "Payslip_Details.txt"
        let fileURL = tempDir.appendingPathComponent(fileName)
        
        do {
            try text.write(to: fileURL, atomically: true, encoding: .utf8)
            
            // Use the file URL for sharing
            let activityVC = UIActivityViewController(
                activityItems: [fileURL],
                applicationActivities: nil
            )
            
            // Configure the activity view controller
            activityVC.excludedActivityTypes = [
                .assignToContact,
                .addToReadingList
            ]
            
            // Set completion handler
            activityVC.completionWithItemsHandler = { (activityType, completed, returnedItems, error) in
                if let error = error {
                    print("Share error: \(error.localizedDescription)")
                }
                
                // Clean up the temporary file
                try? FileManager.default.removeItem(at: fileURL)
            }
            
            return activityVC
        } catch {
            print("Error creating share file: \(error)")
            
            // Fallback to sharing text directly
            let activityVC = UIActivityViewController(
                activityItems: [text],
                applicationActivities: nil
            )
            return activityVC
        }
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
        // No updates needed
    }
} 