import Foundation

/// Manages abbreviations for military payslips
class AbbreviationManager: ObservableObject {
    /// Types of abbreviations
    enum AbbreviationType: String, Codable, CaseIterable {
        case earning
        case deduction
        case unknown
    }
    
    /// Information about an abbreviation
    struct AbbreviationInfo: Identifiable, Codable {
        let id: UUID
        let abbreviation: String
        let fullName: String
        let type: AbbreviationType
        let isUserDefined: Bool
        let dateAdded: Date
        let notes: String?
        
        init(abbreviation: String, fullName: String, type: AbbreviationType, 
             isUserDefined: Bool = false, notes: String? = nil) {
            self.id = UUID()
            self.abbreviation = abbreviation
            self.fullName = fullName
            self.type = type
            self.isUserDefined = isUserDefined
            self.dateAdded = Date()
            self.notes = notes
        }
    }
    
    /// Published properties
    @Published private(set) var abbreviations: [AbbreviationInfo] = []
    @Published private(set) var recentUnknownAbbreviations: [String: Double] = [:]
    
    /// UserDefaults keys
    private let userDefaultsKey = "savedAbbreviations"
    private let unknownAbbreviationsKey = "unknownAbbreviations"
    
    /// Initialization
    init() {
        loadAbbreviations()
        loadDefaultAbbreviations()
    }
    
    /// Load saved abbreviations from UserDefaults
    private func loadAbbreviations() {
        if let data = UserDefaults.standard.data(forKey: userDefaultsKey),
           let savedAbbreviations = try? JSONDecoder().decode([AbbreviationInfo].self, from: data) {
            abbreviations = savedAbbreviations
        }
        
        if let data = UserDefaults.standard.data(forKey: unknownAbbreviationsKey),
           let unknownAbbrs = try? JSONDecoder().decode([String: Double].self, from: data) {
            recentUnknownAbbreviations = unknownAbbrs
        }
    }
    
    /// Load default abbreviations if none exist
    private func loadDefaultAbbreviations() {
        if abbreviations.isEmpty {
            // Add standard earnings
            addSystemAbbreviation(abbreviation: "BPAY", fullName: "Basic Pay", type: .earning)
            addSystemAbbreviation(abbreviation: "DA", fullName: "Dearness Allowance", type: .earning)
            addSystemAbbreviation(abbreviation: "MSP", fullName: "Military Service Pay", type: .earning)
            
            // Add standard deductions
            addSystemAbbreviation(abbreviation: "DSOP", fullName: "Defence Services Officers Provident Fund", type: .deduction)
            addSystemAbbreviation(abbreviation: "AGIF", fullName: "Army Group Insurance Fund", type: .deduction)
            addSystemAbbreviation(abbreviation: "ITAX", fullName: "Income Tax", type: .deduction)
        }
    }
    
    /// Save abbreviations to UserDefaults
    private func saveAbbreviations() {
        if let data = try? JSONEncoder().encode(abbreviations) {
            UserDefaults.standard.set(data, forKey: userDefaultsKey)
        }
    }
    
    /// Save unknown abbreviations to UserDefaults
    private func saveUnknownAbbreviations() {
        if let data = try? JSONEncoder().encode(recentUnknownAbbreviations) {
            UserDefaults.standard.set(data, forKey: unknownAbbreviationsKey)
        }
    }
    
    /// Add a system-defined abbreviation
    func addSystemAbbreviation(abbreviation: String, fullName: String, type: AbbreviationType) {
        let newAbbr = AbbreviationInfo(
            abbreviation: abbreviation,
            fullName: fullName,
            type: type,
            isUserDefined: false
        )
        
        if !abbreviations.contains(where: { $0.abbreviation == abbreviation }) {
            abbreviations.append(newAbbr)
            saveAbbreviations()
        }
    }
    
    /// Add a user-defined abbreviation
    func addUserDefinedAbbreviation(abbreviation: String, fullName: String, 
                                   type: AbbreviationType, notes: String? = nil) {
        let newAbbr = AbbreviationInfo(
            abbreviation: abbreviation,
            fullName: fullName,
            type: type,
            isUserDefined: true,
            notes: notes
        )
        
        // Remove from unknown list if present
        recentUnknownAbbreviations.removeValue(forKey: abbreviation)
        saveUnknownAbbreviations()
        
        // If already exists, update it
        if let index = abbreviations.firstIndex(where: { $0.abbreviation == abbreviation }) {
            abbreviations[index] = newAbbr
        } else {
            abbreviations.append(newAbbr)
        }
        
        saveAbbreviations()
    }
    
    /// Track an unknown abbreviation
    func trackUnknownAbbreviation(_ abbreviation: String, value: Double) {
        // Only track if not already known
        if !abbreviations.contains(where: { $0.abbreviation == abbreviation }) {
            recentUnknownAbbreviations[abbreviation] = value
            saveUnknownAbbreviations()
        }
    }
    
    /// Get abbreviation type
    func getType(for abbreviation: String) -> AbbreviationType {
        if let abbr = abbreviations.first(where: { $0.abbreviation == abbreviation }) {
            return abbr.type
        }
        return .unknown
    }
    
    /// Get full name for abbreviation
    func getFullName(for abbreviation: String) -> String? {
        return abbreviations.first(where: { $0.abbreviation == abbreviation })?.fullName
    }
} 