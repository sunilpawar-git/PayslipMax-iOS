import Foundation

/// A training sample for PDF extraction.
struct TrainingSample: Codable {
    /// The unique identifier for the sample.
    let id: String
    
    /// The timestamp when the sample was created.
    let timestamp: Date
    
    /// The filename of the PDF.
    let pdfFilename: String
    
    /// The data extracted from the PDF.
    let extractedData: ExtractedDataSnapshot
    
    /// The raw text extracted from the PDF.
    let extractedText: String
    
    /// Whether the extraction is correct.
    var isCorrect: Bool?
    
    /// User corrections for the extraction.
    var userCorrections: ExtractedDataSnapshot?
} 