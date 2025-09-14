import Foundation

/// Protocol for RH12 processing service
protocol RH12ProcessingServiceProtocol {
    /// Processes RH12 components from payslip text using enhanced detection
    /// - Parameters:
    ///   - text: The payslip text to process
    ///   - legacyData: Extracted financial data from legacy patterns
    ///   - earnings: Inout dictionary to store earnings components
    ///   - deductions: Inout dictionary to store deduction components
    func processRH12Components(
        from text: String,
        legacyData: [String: Double],
        earnings: inout [String: Double],
        deductions: inout [String: Double]
    )
}

/// Service responsible for processing RH12 (Risk and Hardship) components
/// Handles enhanced RH12 detection with cross-validation to prevent false positives
class RH12ProcessingService: RH12ProcessingServiceProtocol {

    // MARK: - Properties

    /// Enhanced RH12 detector for dual-section detection
    private let rh12Detector: EnhancedRH12Detector

    /// Risk and Hardship processor for component handling
    private let rhProcessor: RiskHardshipProcessor

    // MARK: - Initialization

    /// Initializes the RH12 processing service
    /// - Parameters:
    ///   - rh12Detector: Enhanced RH12 detector (optional, will create default if nil)
    ///   - rhProcessor: Risk and Hardship processor (optional, will create default if nil)
    init(rh12Detector: EnhancedRH12Detector? = nil,
         rhProcessor: RiskHardshipProcessor? = nil) {
        self.rh12Detector = rh12Detector ?? EnhancedRH12Detector()
        self.rhProcessor = rhProcessor ?? RiskHardshipProcessor()
    }

    // MARK: - RH12ProcessingServiceProtocol Implementation

    /// Processes RH12 components from payslip text using enhanced detection
    /// Uses synchronous pattern matching with cross-validation to prevent false positives
    /// - Parameters:
    ///   - text: The payslip text to process
    ///   - legacyData: Extracted financial data from legacy patterns
    ///   - earnings: Inout dictionary to store earnings components
    ///   - deductions: Inout dictionary to store deduction components
    func processRH12Components(
        from text: String,
        legacyData: [String: Double],
        earnings: inout [String: Double],
        deductions: inout [String: Double]
    ) {
        print("[RH12ProcessingService] Processing RH12 components from \(text.count) characters")

        // Extract known deductions for validation (exclude RH12 as we're detecting it)
        let knownDeductions = legacyData.filter { key, _ in
            !key.contains("RH12") && !key.contains("RH") &&
            !key.contains("Risk") && !key.contains("Hardship")
        }.map { $0.value }

        // Get stated total for validation (from legacy extraction)
        let statedTotalDeductions = legacyData["debits"] ?? 0.0

        // Detect RH12 instances with cross-validation to prevent false positives
        let rh12Instances = rh12Detector.detectAllRH12Instances(
            in: text,
            statedDeductionsTotal: statedTotalDeductions > 0 ? statedTotalDeductions : nil,
            knownDeductions: knownDeductions
        )

        for (value, context) in rh12Instances {
            print("[RH12ProcessingService] Enhanced RH12 detection found: ₹\(value)")
            rhProcessor.processRiskHardshipComponent(
                key: "RH12",
                value: value,
                text: context,
                earnings: &earnings,
                deductions: &deductions
            )
        }

        print("[RH12ProcessingService] Processed \(rh12Instances.count) RH12 instances")
    }
}
