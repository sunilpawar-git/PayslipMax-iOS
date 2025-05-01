import SwiftUI
import UIKit

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    var completion: (() -> Void)? = nil
    @Environment(\.presentationMode) private var presentationMode
    
    // Track temporary URLs that need cleanup
    private var temporaryURLs: [URL] {
        items.compactMap { item -> URL? in
            if let url = item as? URL, url.path.contains(FileManager.default.temporaryDirectory.path) {
                return url
            }
            return nil
        }
    }
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        // Create the activity view controller with the items
        let controller = UIActivityViewController(
            activityItems: items,
            applicationActivities: nil
        )
        
        // Configure excluded activity types (optional)
        controller.excludedActivityTypes = [
            .assignToContact,
            .addToReadingList
        ]
        
        // Configure for iPad
        if let popoverController = controller.popoverPresentationController {
            popoverController.sourceView = UIView() // Required for iPad
            popoverController.sourceRect = CGRect(x: UIScreen.main.bounds.midX, y: UIScreen.main.bounds.midY, width: 0, height: 0)
            popoverController.permittedArrowDirections = []
            popoverController.delegate = context.coordinator
        }
        
        // Set completion handler to dismiss the sheet and call the completion handler
        controller.completionWithItemsHandler = { (activityType, completed, returnedItems, error) in
            if let error = error {
                Logger.error("Share error: \(error.localizedDescription)", category: "ShareSheet")
            }
            
            // Clean up temporary files
            for url in temporaryURLs {
                do {
                    try FileManager.default.removeItem(at: url)
                    Logger.info("Cleaned up temporary file: \(url.path)", category: "ShareSheet")
                } catch {
                    Logger.error("Failed to clean up temporary file: \(error.localizedDescription)", category: "ShareSheet")
                }
            }
            
            // Dismiss the sheet
            DispatchQueue.main.async {
                // Always dismiss controller when done
                self.presentationMode.wrappedValue.dismiss()
                // Call completion handler if provided
                completion?()
            }
        }
        
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
        // No updates needed
    }
    
    // Add coordinator for iPad presentation
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIPopoverPresentationControllerDelegate {
        let parent: ShareSheet
        
        init(_ parent: ShareSheet) {
            self.parent = parent
        }
        
        func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
            // Ensure dismissal works on iPads too
            DispatchQueue.main.async {
                self.parent.presentationMode.wrappedValue.dismiss()
                self.parent.completion?()
            }
        }
    }
}

#if DEBUG
// Preview provider for SwiftUI previews
struct ShareSheet_Previews: PreviewProvider {
    static var previews: some View {
        Text("Share Sheet Demo")
            .sheet(isPresented: .constant(true)) {
                ShareSheet(items: ["Sample text to share"])
            }
    }
}
#endif 