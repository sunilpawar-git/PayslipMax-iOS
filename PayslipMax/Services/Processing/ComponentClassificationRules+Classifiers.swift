import Foundation

// MARK: - Component-Specific Classification Methods

extension ComponentClassificationRules {

    /// HRA classification logic - typically earnings unless explicitly in deductions section
    func classifyHRAComponent(
        value: Double,
        text: String,
        spatialAnalyzer: (String, Double, String) -> PayslipSection
    ) -> PayslipSection {
        if value <= 5000 {
            let spatialSection = spatialAnalyzer("HRA", value, text)
            if spatialSection == .deductions {
                return .deductions
            }
        }
        return .earnings
    }

    /// CEA classification logic - similar to HRA
    func classifyCEAComponent(
        value: Double,
        text: String,
        spatialAnalyzer: (String, Double, String) -> PayslipSection
    ) -> PayslipSection {
        if value <= 2000 {
            let spatialSection = spatialAnalyzer("CEA", value, text)
            if spatialSection == .deductions {
                return .deductions
            }
        }
        return .earnings
    }

    /// SICHA classification logic - high-value allowance
    func classifySICHAComponent(
        value: Double,
        text: String,
        spatialAnalyzer: (String, Double, String) -> PayslipSection
    ) -> PayslipSection {
        if value >= 10000 {
            return .earnings
        }
        return spatialAnalyzer("SICHA", value, text)
    }

    /// DA classification logic - common allowance with potential recoveries
    func classifyDAComponent(
        value: Double,
        text: String,
        spatialAnalyzer: (String, Double, String) -> PayslipSection
    ) -> PayslipSection {
        let spatialSection = spatialAnalyzer("DA", value, text)
        if spatialSection != .unknown {
            return spatialSection
        }
        return .earnings
    }

    /// LTC classification logic - travel allowance with recoveries
    func classifyLTCComponent(
        value: Double,
        text: String,
        spatialAnalyzer: (String, Double, String) -> PayslipSection
    ) -> PayslipSection {
        let spatialSection = spatialAnalyzer("LTC", value, text)
        if spatialSection != .unknown {
            return spatialSection
        }
        if value >= 5000 && value <= 20000 {
            let uppercaseText = text.uppercased()
            if uppercaseText.contains("LTC") && uppercaseText.contains("RECOVERY") {
                return .deductions
            }
        }
        return .earnings
    }

    /// Medical allowance classification logic
    func classifyMedicalComponent(
        value: Double,
        text: String,
        spatialAnalyzer: (String, Double, String) -> PayslipSection
    ) -> PayslipSection {
        let spatialSection = spatialAnalyzer("MEDICAL", value, text)
        if spatialSection != .unknown {
            return spatialSection
        }
        if value <= 3000 {
            return .deductions
        }
        return .earnings
    }

    /// Conveyance allowance classification logic
    func classifyConveyanceComponent(
        value: Double,
        text: String,
        spatialAnalyzer: (String, Double, String) -> PayslipSection
    ) -> PayslipSection {
        let spatialSection = spatialAnalyzer("CONVEYANCE", value, text)
        if spatialSection != .unknown {
            return spatialSection
        }
        return .earnings
    }

    /// TPTA classification logic - transport allowance
    func classifyTPTAComponent(
        value: Double,
        text: String,
        spatialAnalyzer: (String, Double, String) -> PayslipSection
    ) -> PayslipSection {
        if value >= 1500 {
            let recoveryIndicators = ["RECOVERY", "REC", "REFUND", "EXCESS", "OVERPAYMENT"]
            let uppercaseText = text.uppercased()

            for indicator in recoveryIndicators where
                uppercaseText.contains("TPTA") && uppercaseText.contains(indicator) {
                return .deductions
            }
            return .earnings
        }

        let spatialSection = spatialAnalyzer("TPTA", value, text)
        if spatialSection != .unknown {
            return spatialSection
        }
        return .earnings
    }

    /// TPTADA (Transport Allowance DA) classification logic
    func classifyTPTADAComponent(
        value: Double,
        text: String,
        spatialAnalyzer: (String, Double, String) -> PayslipSection
    ) -> PayslipSection {
        if value >= 1000 {
            let recoveryIndicators = ["RECOVERY", "REC", "REFUND", "EXCESS", "OVERPAYMENT", "DA RECOVERY"]
            let uppercaseText = text.uppercased()

            for indicator in recoveryIndicators where
                uppercaseText.contains("TPTADA") && uppercaseText.contains(indicator) {
                return .deductions
            }
            return .earnings
        }

        let spatialSection = spatialAnalyzer("TPTADA", value, text)
        if spatialSection != .unknown {
            return spatialSection
        }
        return .earnings
    }
}
