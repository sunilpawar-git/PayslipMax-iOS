import Foundation

/// Protocol for military payslip representation
protocol MilitaryPayslipRepresentable {
    var rank: String { get set }
    var serviceNumber: String { get set }
    var allowances: [String: Double] { get set }
}

/// Protocol for PCDA payslip representation (defense personnel)
protocol PCDAPayslipRepresentable {
    var serviceNumber: String { get set }
    var rank: String { get set }
    var unit: String { get set }
    var basicPay: Double { get set }
    var msp: Double { get set }
    var specialAllowance: Double { get set }
    var providentFund: Double { get set }
    var professionalTax: Double { get set }
}

/// Protocol for detailed payslip breakdowns
protocol DetailedPayslipRepresentable {
    var creditsBreakdown: [String: Double] { get set }
    var debitsBreakdown: [String: Double] { get set }
}

/// Factory protocol for creating payslip test data generators
protocol PayslipTestDataFactory {
    /// Creates a basic payslip generator
    func createBasicGenerator() -> BasicPayslipGeneratorProtocol

    /// Creates a complex payslip generator
    func createComplexGenerator() -> ComplexPayslipGeneratorProtocol

    /// Creates an edge case generator
    func createEdgeCaseGenerator() -> EdgeCaseGeneratorProtocol

    /// Creates a PDF generator
    func createPDFGenerator() -> PDFGeneratorProtocol
}

/// Default implementation of the payslip test data factory
class DefaultPayslipTestDataFactory: PayslipTestDataFactory {
    func createBasicGenerator() -> BasicPayslipGeneratorProtocol {
        return BasicPayslipGenerator()
    }

    func createComplexGenerator() -> ComplexPayslipGeneratorProtocol {
        return ComplexPayslipGenerator()
    }

    func createEdgeCaseGenerator() -> EdgeCaseGeneratorProtocol {
        return EdgeCaseGenerator()
    }

    func createPDFGenerator() -> PDFGeneratorProtocol {
        return PDFGenerator()
    }
}
