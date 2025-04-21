import SwiftUI
import PDFKit

/// Unified enum representing all navigable destinations in the app.
enum AppNavigationDestination: Identifiable, Hashable {
    
    // MARK: - Cases
    
    // Main tab roots (for context, actual tab switching managed by selectedTab)
    case homeTab
    case payslipsTab
    case insightsTab
    case settingsTab

    // Stack Destinations (Pushed onto NavigationStack)
    case payslipDetail(id: UUID)

    // Modal Destinations (Presented via Sheet or FullScreenCover)
    case pdfPreview(document: PDFDocument)
    case privacyPolicy
    case termsOfService
    case changePin
    case addPayslip
    case scanner
    case pinSetup
    case performanceMonitor
    
    // Example Destinations
    case taskDependencyExample
    
    // MARK: - Identifiable
    
    var id: String {
        switch self {
        case .homeTab: return "homeTab"
        case .payslipsTab: return "payslipsTab"
        case .insightsTab: return "insightsTab"
        case .settingsTab: return "settingsTab"
        case .payslipDetail(let id): return "payslipDetail-\(id.uuidString)"
        case .pdfPreview(let document): 
            return "pdfPreview-\(ObjectIdentifier(document).hashValue)"
        case .privacyPolicy: return "privacyPolicy"
        case .termsOfService: return "termsOfService"
        case .changePin: return "changePin"
        case .addPayslip: return "addPayslip"
        case .scanner: return "scanner"
        case .pinSetup: return "pinSetup"
        case .performanceMonitor: return "performanceMonitor"
        case .taskDependencyExample: return "taskDependencyExample"
        }
    }
    
    // MARK: - Hashable & Equatable
    
    // Equatable conformance
    static func == (lhs: AppNavigationDestination, rhs: AppNavigationDestination) -> Bool {
        switch (lhs, rhs) {
        case (.homeTab, .homeTab), (.payslipsTab, .payslipsTab), (.insightsTab, .insightsTab), (.settingsTab, .settingsTab),
             (.privacyPolicy, .privacyPolicy), (.termsOfService, .termsOfService), (.changePin, .changePin),
             (.addPayslip, .addPayslip), (.scanner, .scanner), (.pinSetup, .pinSetup), 
             (.performanceMonitor, .performanceMonitor), (.taskDependencyExample, .taskDependencyExample):
            return true
        case (.payslipDetail(let lhsId), .payslipDetail(let rhsId)):
            return lhsId == rhsId
        case (.pdfPreview(let lhsDoc), .pdfPreview(let rhsDoc)):
            // Compare PDFDocument references for equality in this context
            return ObjectIdentifier(lhsDoc) == ObjectIdentifier(rhsDoc)
        default:
            return false
        }
    }
    
    // Hashable conformance
    func hash(into hasher: inout Hasher) {
        switch self {
        case .homeTab: 
            hasher.combine(0)
        case .payslipsTab: 
            hasher.combine(1)
        case .insightsTab: 
            hasher.combine(2)
        case .settingsTab: 
            hasher.combine(3)
        case .payslipDetail(let id):
            hasher.combine(4)
            hasher.combine(id)
        case .pdfPreview(let document):
            hasher.combine(5)
            hasher.combine(ObjectIdentifier(document))
        case .privacyPolicy: 
            hasher.combine(6)
        case .termsOfService: 
            hasher.combine(7)
        case .changePin: 
            hasher.combine(8)
        case .addPayslip: 
            hasher.combine(9)
        case .scanner: 
            hasher.combine(10)
        case .pinSetup: 
            hasher.combine(11)
        case .performanceMonitor: 
            hasher.combine(12)
        case .taskDependencyExample:
            hasher.combine(13)
        }
    }
    
    // Convenience property to access the PDF document if available
    var pdfDocument: PDFDocument? {
        if case .pdfPreview(let doc) = self { return doc }
        return nil
    }
} 