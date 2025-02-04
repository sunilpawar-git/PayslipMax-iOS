import SwiftUI
import SwiftData
import PDFKit // For PDFDocument

@MainActor
final class HomeViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published private(set) var isLoading = false
    @Published private(set) var error: Error?
    @Published var isProcessing = false
    @Published var processingProgress: Double = 0
    
    // MARK: - Services
    let pdfManager: PDFUploadManager
    
    // MARK: - Initialization
    init(pdfManager: PDFUploadManager?) {
        self.pdfManager = pdfManager ?? PDFUploadManager()
    }
    
    // MARK: - Public Methods
    func handlePDFSelection() {
        pdfManager.showPicker()
    }
    
    func startProcessing() {
        isProcessing = true
    }
    
    func stopProcessing() {
        isProcessing = false
    }
    
    // MARK: - Private Methods
    private func setLoading(_ loading: Bool) {
        isLoading = loading
    }
    
    private func handleError(_ error: Error) {
        self.error = error
    }
} 