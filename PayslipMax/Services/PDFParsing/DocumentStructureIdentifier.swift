import Foundation

/// Represents the structure/format of a payslip document
public enum DocumentStructure {
    case armyFormat
    case navyFormat
    case airForceFormat
    case genericFormat
    case unknown
}

/// Protocol for identifying document structure from text content
protocol DocumentStructureIdentifierProtocol {
    /// Identify the document structure/format based on text content
    /// - Parameter text: The full text of the document
    /// - Returns: The identified document structure
    func identifyDocumentStructure(from text: String) -> DocumentStructure
}

/// Service responsible for identifying the structure and format of payslip documents
class DocumentStructureIdentifier: DocumentStructureIdentifierProtocol {
    
    // MARK: - Public Methods
    
    /// Identify the document structure/format based on text content
    /// - Parameter text: The full text of the document
    /// - Returns: The identified document structure
    func identifyDocumentStructure(from text: String) -> DocumentStructure {
        let normalizedText = text.lowercased()
        
        // Check for Army-specific markers
        if detectArmyFormat(normalizedText) {
            return .armyFormat
        }
        
        // Check for Navy-specific markers
        if detectNavyFormat(normalizedText) {
            return .navyFormat
        }
        
        // Check for Air Force-specific markers
        if detectAirForceFormat(normalizedText) {
            return .airForceFormat
        }
        
        // If we can detect it's a military payslip but not which branch
        if detectGenericMilitaryFormat(normalizedText) {
            return .genericFormat
        }
        
        return .unknown
    }
    
    // MARK: - Private Methods
    
    /// Detect if the document follows Army payslip format
    /// - Parameter normalizedText: The lowercased text content
    /// - Returns: True if Army format is detected
    private func detectArmyFormat(_ normalizedText: String) -> Bool {
        return normalizedText.contains("army pay corps") || 
               normalizedText.contains("army pay")
    }
    
    /// Detect if the document follows Navy payslip format
    /// - Parameter normalizedText: The lowercased text content
    /// - Returns: True if Navy format is detected
    private func detectNavyFormat(_ normalizedText: String) -> Bool {
        return normalizedText.contains("naval pay") || 
               normalizedText.contains("navy pay")
    }
    
    /// Detect if the document follows Air Force payslip format
    /// - Parameter normalizedText: The lowercased text content
    /// - Returns: True if Air Force format is detected
    private func detectAirForceFormat(_ normalizedText: String) -> Bool {
        return normalizedText.contains("air force pay") || 
               normalizedText.contains("iaf pay")
    }
    
    /// Detect if the document follows generic military payslip format
    /// - Parameter normalizedText: The lowercased text content
    /// - Returns: True if generic military format is detected
    private func detectGenericMilitaryFormat(_ normalizedText: String) -> Bool {
        return normalizedText.contains("military pay") || 
               normalizedText.contains("defence pay") ||
               normalizedText.contains("defense pay")
    }
}