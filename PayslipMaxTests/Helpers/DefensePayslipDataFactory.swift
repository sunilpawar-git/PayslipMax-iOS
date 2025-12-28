import Foundation
@testable import PayslipMax

/// Defense service branches supported by the unified parser
enum DefenseServiceBranch: String, CaseIterable {
    case army = "Army"
    case navy = "Navy"
    case airForce = "Air Force"
    case pcda = "PCDA"

    var displayName: String { rawValue }
}

/// Protocol for generating defense-specific payslip data
protocol DefensePayslipDataFactoryProtocol {
    /// Creates a defense payslip item using parameter struct
    func createDefensePayslipItem(params: DefensePayslipDataParams) -> PayslipItem

    func createDefensePayslipItems(count: Int, serviceBranch: DefenseServiceBranch) -> [PayslipItem]

    func createEdgeCaseDefensePayslip(type: DefenseEdgeCaseType) -> PayslipItem
}

/// Types of edge cases specific to defense payslips
enum DefenseEdgeCaseType {
    case zeroMSP
    case highDSOP
    case arrearsPay
    case riskHardshipAllowance
    case transportAllowance
    case invalidServiceNumber
    case negativeValues
}

/// Factory for creating defense-specific payslip test data
class DefensePayslipDataFactory: DefensePayslipDataFactoryProtocol {

    // MARK: - DefensePayslipDataFactoryProtocol Implementation

    func createDefensePayslipItem(params: DefensePayslipDataParams = .default) -> PayslipItem {
        let payslipItem = PayslipItem(
            id: UUID(),
            timestamp: Date(),
            month: params.month,
            year: params.year,
            credits: params.totalCredits,
            debits: params.totalDebits,
            dsop: params.dsop,
            tax: params.incomeTax,
            name: params.name,
            accountNumber: params.serviceNumber,
            panNumber: generatePANForService(params.serviceBranch)
        )

        // Set detailed earnings and deductions for defense payslip
        payslipItem.earnings = [
            "Basic Pay": params.basicPay,
            "Military Service Pay": params.msp,
            "Dearness Allowance": params.da
        ]

        payslipItem.deductions = [
            "DSOP": params.dsop,
            "AGIF": params.agif,
            "Income Tax": params.incomeTax
        ]

        return payslipItem
    }

    func createDefensePayslipItems(count: Int, serviceBranch: DefenseServiceBranch = .army) -> [PayslipItem] {
        var payslips: [PayslipItem] = []

        for i in 0..<count {
            let months = ["January", "February", "March", "April", "May", "June",
                         "July", "August", "September", "October", "November", "December"]
            let month = months[i % 12]
            let year = 2023 + (i / 12)

            let params = DefensePayslipDataParams(
                serviceBranch: serviceBranch,
                name: "Personnel \(i + 1)",
                rank: getRankForIndex(i),
                serviceNumber: generateServiceNumber(serviceBranch, index: i),
                month: month,
                year: year,
                basicPay: 45000.0 + Double(i) * 1000.0,
                msp: 12000.0 + Double(i) * 500.0,
                da: 4500.0 + Double(i) * 100.0,
                dsop: 1000.0 + Double(i) * 50.0,
                agif: 120.0,
                incomeTax: 2000.0 + Double(i) * 100.0
            )
            let payslip = createDefensePayslipItem(params: params)
            payslips.append(payslip)
        }

        return payslips
    }

    func createEdgeCaseDefensePayslip(type: DefenseEdgeCaseType) -> PayslipItem {
        let baseParams = DefensePayslipDataParams.default
        switch type {
        case .zeroMSP:
            let params = DefensePayslipDataParams(
                serviceBranch: baseParams.serviceBranch, name: baseParams.name, rank: baseParams.rank,
                serviceNumber: baseParams.serviceNumber, month: baseParams.month, year: baseParams.year,
                basicPay: baseParams.basicPay, msp: 0.0, da: baseParams.da,
                dsop: baseParams.dsop, agif: baseParams.agif, incomeTax: baseParams.incomeTax
            )
            return createDefensePayslipItem(params: params)
        case .highDSOP:
            let params = DefensePayslipDataParams(
                serviceBranch: baseParams.serviceBranch, name: baseParams.name, rank: baseParams.rank,
                serviceNumber: baseParams.serviceNumber, month: baseParams.month, year: baseParams.year,
                basicPay: baseParams.basicPay, msp: baseParams.msp, da: baseParams.da,
                dsop: 5000.0, agif: baseParams.agif, incomeTax: baseParams.incomeTax
            )
            return createDefensePayslipItem(params: params)
        case .arrearsPay:
            let payslip = createDefensePayslipItem(params: baseParams)
            payslip.earnings["Arrears DA"] = 2500.0
            payslip.credits += 2500.0
            return payslip
        case .riskHardshipAllowance:
            let payslip = createDefensePayslipItem(params: baseParams)
            payslip.earnings["Risk and Hardship Allowance"] = 8000.0
            payslip.credits += 8000.0
            return payslip
        case .transportAllowance:
            let payslip = createDefensePayslipItem(params: baseParams)
            payslip.earnings["Transport Allowance"] = 1920.0
            payslip.credits += 1920.0
            return payslip
        case .invalidServiceNumber:
            let params = DefensePayslipDataParams(
                serviceBranch: baseParams.serviceBranch, name: baseParams.name, rank: baseParams.rank,
                serviceNumber: "INVALID", month: baseParams.month, year: baseParams.year,
                basicPay: baseParams.basicPay, msp: baseParams.msp, da: baseParams.da,
                dsop: baseParams.dsop, agif: baseParams.agif, incomeTax: baseParams.incomeTax
            )
            return createDefensePayslipItem(params: params)
        case .negativeValues:
            let params = DefensePayslipDataParams(
                serviceBranch: baseParams.serviceBranch, name: baseParams.name, rank: baseParams.rank,
                serviceNumber: baseParams.serviceNumber, month: baseParams.month, year: baseParams.year,
                basicPay: baseParams.basicPay, msp: baseParams.msp, da: baseParams.da,
                dsop: -1000.0, agif: baseParams.agif, incomeTax: baseParams.incomeTax
            )
            return createDefensePayslipItem(params: params)
        }
    }

    // MARK: - Private Helper Methods

    private func getRankForIndex(_ index: Int) -> String {
        let ranks = ["Sepoy", "Lance Naik", "Naik", "Havildar", "Naib Subedar",
                    "Subedar", "Subedar Major", "Lt", "Capt", "Major", "Lt Col", "Col"]
        return ranks[index % ranks.count]
    }

    private func generateServiceNumber(_ branch: DefenseServiceBranch, index: Int) -> String {
        let prefix: String
        switch branch {
        case .army: prefix = "IC"
        case .navy: prefix = "NAV"
        case .airForce: prefix = "IAF"
        case .pcda: prefix = "PCDA"
        }
        return "\(prefix)-\(String(format: "%05d", index + 10000))"
    }

    private func generatePANForService(_ branch: DefenseServiceBranch) -> String {
        let serviceCode: String
        switch branch {
        case .army: serviceCode = "ARMY"
        case .navy: serviceCode = "NAVY"
        case .airForce: serviceCode = "IAF"
        case .pcda: serviceCode = "PCDA"
        }

        // Generate a valid PAN-like format for testing
        let randomNumbers = String(format: "%04d", Int.random(in: 1000...9999))
        let randomLetter = String("ABCDEFGHIJKLMNOPQRSTUVWXYZ".randomElement()!)
        return "\(serviceCode.prefix(4))\(randomNumbers)\(randomLetter)"
    }
}
