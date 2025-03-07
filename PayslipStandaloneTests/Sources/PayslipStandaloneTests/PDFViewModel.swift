import Foundation

@MainActor
class PDFViewModel: ObservableObject {
    @Published var isProcessing = false
    @Published var extractedPayslip: StandalonePayslipItem?
    @Published var error: Error?
    
    private let pdfService: PDFServiceProtocol
    
    init(pdfService: PDFServiceProtocol) {
        self.pdfService = pdfService
    }
    
    func processPDF(at url: URL) async {
        isProcessing = true
        error = nil
        extractedPayslip = nil
        
        do {
            // Ensure the service is initialized
            if !pdfService.isInitialized {
                try await pdfService.initialize()
            }
            
            // Process the PDF
            let processedData = try await pdfService.process(url)
            
            // Extract payslip data
            extractedPayslip = try await pdfService.extract(processedData)
        } catch {
            self.error = error
        }
        
        isProcessing = false
    }
    
    func reset() {
        isProcessing = false
        extractedPayslip = nil
        error = nil
    }
} 