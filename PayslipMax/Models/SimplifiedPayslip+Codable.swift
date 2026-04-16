import Foundation
import SwiftData

// MARK: - Codable Implementation

extension SimplifiedPayslip {

    enum CodingKeys: String, CodingKey {
        case id
        case timestamp
        case name
        case month
        case year
        case basicPay
        case dearnessAllowance
        case militaryServicePay
        case otherEarnings
        case grossPay
        case dsop
        case agif
        case incomeTax
        case otherDeductions
        case totalDeductions
        case netRemittance
        case otherEarningsBreakdown
        case otherDeductionsBreakdown
        case parsingConfidence
        case pdfData
        case source
        case isEdited
    }

    convenience init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let id = try container.decode(UUID.self, forKey: .id)
        let timestamp = try container.decode(Date.self, forKey: .timestamp)
        let name = try container.decode(String.self, forKey: .name)
        let month = try container.decode(String.self, forKey: .month)
        let year = try container.decode(Int.self, forKey: .year)
        let basicPay = try container.decode(Double.self, forKey: .basicPay)
        let dearnessAllowance = try container.decode(Double.self, forKey: .dearnessAllowance)
        let militaryServicePay = try container.decode(Double.self, forKey: .militaryServicePay)
        let otherEarnings = try container.decode(Double.self, forKey: .otherEarnings)
        let grossPay = try container.decode(Double.self, forKey: .grossPay)
        let dsop = try container.decode(Double.self, forKey: .dsop)
        let agif = try container.decode(Double.self, forKey: .agif)
        let incomeTax = try container.decode(Double.self, forKey: .incomeTax)
        let otherDeductions = try container.decode(Double.self, forKey: .otherDeductions)
        let totalDeductions = try container.decode(Double.self, forKey: .totalDeductions)
        let netRemittance = try container.decode(Double.self, forKey: .netRemittance)
        let otherEarningsBreakdown = try container.decode([String: Double].self, forKey: .otherEarningsBreakdown)
        let otherDeductionsBreakdown = try container.decode([String: Double].self, forKey: .otherDeductionsBreakdown)
        let parsingConfidence = try container.decode(Double.self, forKey: .parsingConfidence)
        let pdfData = try container.decodeIfPresent(Data.self, forKey: .pdfData)
        let source = try container.decode(String.self, forKey: .source)
        let isEdited = try container.decode(Bool.self, forKey: .isEdited)

        self.init(
            id: id,
            timestamp: timestamp,
            name: name,
            month: month,
            year: year,
            basicPay: basicPay,
            dearnessAllowance: dearnessAllowance,
            militaryServicePay: militaryServicePay,
            otherEarnings: otherEarnings,
            grossPay: grossPay,
            dsop: dsop,
            agif: agif,
            incomeTax: incomeTax,
            otherDeductions: otherDeductions,
            totalDeductions: totalDeductions,
            netRemittance: netRemittance,
            otherEarningsBreakdown: otherEarningsBreakdown,
            otherDeductionsBreakdown: otherDeductionsBreakdown,
            parsingConfidence: parsingConfidence,
            pdfData: pdfData,
            source: source,
            isEdited: isEdited
        )
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(id, forKey: .id)
        try container.encode(timestamp, forKey: .timestamp)
        try container.encode(name, forKey: .name)
        try container.encode(month, forKey: .month)
        try container.encode(year, forKey: .year)
        try container.encode(basicPay, forKey: .basicPay)
        try container.encode(dearnessAllowance, forKey: .dearnessAllowance)
        try container.encode(militaryServicePay, forKey: .militaryServicePay)
        try container.encode(otherEarnings, forKey: .otherEarnings)
        try container.encode(grossPay, forKey: .grossPay)
        try container.encode(dsop, forKey: .dsop)
        try container.encode(agif, forKey: .agif)
        try container.encode(incomeTax, forKey: .incomeTax)
        try container.encode(otherDeductions, forKey: .otherDeductions)
        try container.encode(totalDeductions, forKey: .totalDeductions)
        try container.encode(netRemittance, forKey: .netRemittance)
        try container.encode(otherEarningsBreakdown, forKey: .otherEarningsBreakdown)
        try container.encode(otherDeductionsBreakdown, forKey: .otherDeductionsBreakdown)
        try container.encode(parsingConfidence, forKey: .parsingConfidence)
        try container.encodeIfPresent(pdfData, forKey: .pdfData)
        try container.encode(source, forKey: .source)
        try container.encode(isEdited, forKey: .isEdited)
    }
}

// MARK: - Factory Methods

extension SimplifiedPayslip {

    /// Creates a sample payslip for testing and previews
    static func createSample() -> SimplifiedPayslip {
        return SimplifiedPayslip(
            name: "Sunil Suresh Pawar",
            month: "August",
            year: 2025,
            basicPay: 144700,
            dearnessAllowance: 88110,
            militaryServicePay: 15500,
            otherEarnings: 27355,
            grossPay: 275665,
            dsop: 40000,
            agif: 12500,
            incomeTax: 47624,
            otherDeductions: 2905,
            totalDeductions: 103029,
            netRemittance: 172636,
            otherEarningsBreakdown: [
                "RH12": 21125,
                "TPTA": 3600,
                "TPTADA": 1980,
                "RSHNA": 650
            ],
            otherDeductionsBreakdown: [
                "EHCESS": 1905,
                "MISC": 1000
            ],
            parsingConfidence: 0.95,
            source: "Sample Data",
            isEdited: false
        )
    }
}
