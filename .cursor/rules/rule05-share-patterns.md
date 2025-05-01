---
description: Document sharing and resource handling best practices
globs: *.swift
alwaysApply: true
---

# Document Sharing and Resource Handling Best Practices

## Share Sheet Implementation

1. **Use UIActivityItemProvider for Resource-Intensive Sharing**
   - Always use `UIActivityItemProvider` when sharing files, PDFs, or resources that require preparation
   - Never block the main thread with synchronous file operations before showing a share sheet
   - Write files to temporary locations in a background-friendly way
   - Specify correct UTI types for shared content using `dataTypeIdentifierForActivityType`
   - Clean up temporary files after sharing completes

2. **PDF Sharing Specifics**
   - Create PDF files in the temporary directory with descriptive filenames
   - Use `com.adobe.pdf` as the type identifier for PDF files
   - Verify PDF data integrity before sharing
   - Handle failures gracefully with fallback to text sharing
   - Include proper filename and extension for maximum compatibility

3. **Share Sheet Configuration**
   - Configure properly for iPad with popover presentation
   - Implement `UIPopoverPresentationControllerDelegate` for iPad dismissal
   - Set appropriate excluded activity types based on content
   - Provide completion handlers to detect when sharing completes

## Resource Handling

1. **Temporary Files**
   - Use `FileManager.default.temporaryDirectory` for sharing files
   - Include unique identifiers in filenames to prevent collisions
   - Implement automatic cleanup in `deinit` or completion handlers
   - Use `@unchecked Sendable` for classes that manage file resources when needed

2. **Memory Management**
   - Stream large files rather than loading entirely in memory
   - Use `autoreleasepool` for processing large batches of data
   - Implement proper cancellation handling for asynchronous operations
   - Cache processed resources appropriately to prevent repeated work

## Implementation Examples

```swift
// EXAMPLE: UIActivityItemProvider for PDF sharing
class PDFShareItemProvider: UIActivityItemProvider, @unchecked Sendable {
    private let pdfData: Data
    private let title: String
    private var temporaryURL: URL
    
    init(pdfData: Data, title: String) {
        self.pdfData = pdfData
        self.title = title.replacingOccurrences(of: " ", with: "_")
        self.temporaryURL = FileManager.default.temporaryDirectory
                                .appendingPathComponent("\(self.title).pdf")
        
        super.init(placeholderItem: self.temporaryURL)
        
        // Write immediately to ensure file exists when needed
        try? self.pdfData.write(to: self.temporaryURL)
    }
    
    override var item: Any {
        return temporaryURL
    }
    
    override func activityViewController(
        _ activityViewController: UIActivityViewController,
        dataTypeIdentifierForActivityType activityType: UIActivity.ActivityType?
    ) -> String {
        return "com.adobe.pdf"
    }
    
    deinit {
        // Clean up temporary file
        try? FileManager.default.removeItem(at: temporaryURL)
    }
}

// Usage:
let pdfProvider = PDFShareItemProvider(pdfData: pdfData, title: "Document")
let activityVC = UIActivityViewController(
    activityItems: [pdfProvider],
    applicationActivities: nil
)
present(activityVC, animated: true)
``` 