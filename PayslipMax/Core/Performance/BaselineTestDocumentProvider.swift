import Foundation
import PDFKit

/// Service to provide test documents for baseline measurement
/// 
/// This service creates and manages test documents used for consistent baseline
/// measurement across different parsing system performance tests.
struct BaselineTestDocumentProvider {
    
    // MARK: - Test Document Creation
    
    /// Create a consistent set of test documents for baseline measurement
    static func createTestDocumentSet() async throws -> [Data] {
        print("📚 Creating test document set for baseline measurement")
        
        var testDocuments: [Data] = []
        
        // Try to load the sample payslip from resources
        if let samplePDFURL = Bundle.main.url(forResource: "SamplePayslip", withExtension: "pdf"),
           let sampleData = try? Data(contentsOf: samplePDFURL) {
            testDocuments.append(sampleData)
            print("✅ Added sample payslip document")
        }
        
        // Generate additional test documents for comprehensive measurement
        for i in 1...3 {
            if let generatedDocument = try await generateTestDocument(variant: i) {
                testDocuments.append(generatedDocument)
                print("✅ Added generated test document \(i)")
            }
        }
        
        // Ensure we have at least one test document
        if testDocuments.isEmpty {
            print("⚠️ No test documents available, creating minimal test document")
            testDocuments.append(createMinimalTestDocument())
        }
        
        print("📊 Test document set complete: \(testDocuments.count) documents")
        return testDocuments
    }
    
    // MARK: - Document Generation
    
    /// Generate a test PDF document for measurement purposes
    private static func generateTestDocument(variant: Int) async throws -> Data? {
        // Create a simple PDF document with varying content
        _ = PDFDocument()
        
        // Create a page with test content
        _ = CGRect(x: 0, y: 0, width: 612, height: 792) // Standard letter size
        _ = PDFPage()
        
        // Add some text content based on variant
        _ = generateTestContent(for: variant)
        
        // For now, return nil since we'd need more complex PDF generation
        // In a real implementation, this would create actual PDF content
        return nil
    }
    
    /// Create a minimal test document
    private static func createMinimalTestDocument() -> Data {
        // Create minimal PDF data for testing
        let pdfString = """
        %PDF-1.4
        1 0 obj
        <<
        /Type /Catalog
        /Pages 2 0 R
        >>
        endobj
        2 0 obj
        <<
        /Type /Pages
        /Kids [3 0 R]
        /Count 1
        >>
        endobj
        3 0 obj
        <<
        /Type /Page
        /Parent 2 0 R
        /MediaBox [0 0 612 792]
        >>
        endobj
        xref
        0 4
        0000000000 65535 f 
        0000000010 00000 n 
        0000000053 00000 n 
        0000000100 00000 n 
        trailer
        <<
        /Size 4
        /Root 1 0 R
        >>
        startxref
        164
        %%EOF
        """
        
        return Data(pdfString.utf8)
    }
    
    /// Generate test content for PDF variants
    private static func generateTestContent(for variant: Int) -> String {
        switch variant {
        case 1:
            return """
            MILITARY PAYSLIP - SAMPLE
            Name: John Doe
            Rank: E-5
            Base Pay: $3000.00
            Allowances: $500.00
            Total: $3500.00
            """
        case 2:
            return """
            CIVILIAN PAYSLIP - SAMPLE
            Employee: Jane Smith
            Department: Engineering
            Gross Pay: $4000.00
            Deductions: $800.00
            Net Pay: $3200.00
            """
        case 3:
            return """
            COMPLEX PAYSLIP - SAMPLE
            Multiple deductions and allowances
            Various pay categories
            Overtime calculations
            Year-to-date totals
            """
        default:
            return "BASIC PAYSLIP - SAMPLE"
        }
    }
}
