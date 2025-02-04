import Foundation
import PDFKit
import VisionKit
import SwiftData
import SwiftUI

@MainActor
class PDFUploadManager: ObservableObject {
    @Published private(set) var selectedPDF: PDFDocument?
    @Published private(set) var isShowingPicker = false
    @Published private(set) var isShowingPreview = false
    @Published private(set) var isShowingError = false
    @Published private(set) var errorMessage: String?
    
    func handleSelectedPDF(at url: URL) {
        print("🔍 Starting PDF handling process")
        
        let securityAccessGranted = url.startAccessingSecurityScopedResource()
        defer {
            if securityAccessGranted {
                url.stopAccessingSecurityScopedResource()
            }
        }
        
        do {
            guard let document = PDFDocument(url: url) else {
                throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Could not create PDF document"])
            }
            
            selectedPDF = document
            showPreview()
        } catch {
            setError(error.localizedDescription)
        }
    }
    
    // State management methods
    func showPicker() {
        isShowingPicker = true
    }
    
    func hidePicker() {
        isShowingPicker = false
    }
    
    func showPreview() {
        isShowingPreview = true
    }
    
    func hidePreview() {
        isShowingPreview = false
    }
    
    func setError(_ message: String) {
        errorMessage = message
        isShowingError = true
    }
    
    func clearError() {
        errorMessage = nil
        isShowingError = false
    }
    
    func scanDocument() {
        // Implement document scanning
    }
    
    func processScannedDocument(_ document: PDFDocument) {
        // Implement document processing
    }
    
    func extractPayslipData(from text: String) -> Payslip? {
        // Implement data extraction
        nil
    }
} 