import Foundation
import SwiftUI
import PDFKit
import SwiftData

/// Represents all possible navigation destinations in the app
enum AppDestination: Identifiable, Hashable {
    // Main tab destinations
    case home
    case payslips
    case payslipDetail(payslip: PayslipItem)
    case insights
    case settings
    
    // Modal destinations
    case addPayslip
    case pinSetup
    case scanner
    case pdfPreview(document: PDFDocument)
    case privacyPolicy
    case termsOfService
    case changePin
    
    // Examples
    case taskDependencyExample
    
    // Identifiable conformance
    var id: String {
        switch self {
        case .home: return "home"
        case .payslips: return "payslips"
        case .payslipDetail(let payslip): return "payslip-\(payslip.id)"
        case .insights: return "insights"
        case .settings: return "settings"
        case .addPayslip: return "addPayslip"
        case .pinSetup: return "pinSetup"
        case .scanner: return "scanner"
        case .pdfPreview(let document): return "pdfPreview-\(ObjectIdentifier(document).hashValue)"
        case .privacyPolicy: return "privacyPolicy"
        case .termsOfService: return "termsOfService"
        case .changePin: return "changePin"
        case .taskDependencyExample: return "taskDependencyExample"
        }
    }
    
    // Make PDFDocument Hashable for use in an enum case
    static func == (lhs: AppDestination, rhs: AppDestination) -> Bool {
        switch (lhs, rhs) {
        case (.home, .home), 
             (.payslips, .payslips),
             (.insights, .insights),
             (.settings, .settings),
             (.addPayslip, .addPayslip),
             (.pinSetup, .pinSetup),
             (.scanner, .scanner),
             (.privacyPolicy, .privacyPolicy),
             (.termsOfService, .termsOfService),
             (.taskDependencyExample, .taskDependencyExample),
             (.changePin, .changePin):
            return true
        case (.payslipDetail(let lhsPayslip), .payslipDetail(let rhsPayslip)):
            return lhsPayslip.id == rhsPayslip.id
        case (.pdfPreview(let lhsDoc), .pdfPreview(let rhsDoc)):
            return lhsDoc === rhsDoc // Compare references
        default:
            return false
        }
    }
    
    func hash(into hasher: inout Hasher) {
        switch self {
        case .home: hasher.combine(0)
        case .payslips: hasher.combine(1)
        case .payslipDetail(let payslip): 
            hasher.combine(2)
            hasher.combine(payslip.id)
        case .insights: hasher.combine(3)
        case .settings: hasher.combine(4)
        case .addPayslip: hasher.combine(5)
        case .pinSetup: hasher.combine(6)
        case .scanner: hasher.combine(7)
        case .pdfPreview: 
            hasher.combine(8)
            // Can't hash PDFDocument directly, just use the case identifier
        case .privacyPolicy: hasher.combine(9)
        case .termsOfService: hasher.combine(10)
        case .changePin: hasher.combine(11)
        case .taskDependencyExample: hasher.combine(12)
        }
    }
} 