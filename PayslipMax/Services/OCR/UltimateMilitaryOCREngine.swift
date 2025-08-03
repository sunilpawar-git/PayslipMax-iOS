import UIKit

/// A protocol for parsing military payslips.
protocol MilitaryPayslipParserProtocol {
    func processPayslip(image: UIImage) async -> MilitaryPayslip
}

/// The ultimate military payslip OCR engine with geometric validation.
final class UltimateMilitaryOCREngine: MilitaryPayslipParserProtocol {

    private let visionService = UltimateVisionService()

    /// A list of keywords to search for in the payslip.
    private let keywords = ["BASIC PAY", "NET PAY", "ALLOWANCES", "DEDUCTIONS"]

    func processPayslip(image: UIImage) async -> MilitaryPayslip {
        guard let visionResult = await visionService.performUltimateOCR(on: image) else {
            return MilitaryPayslip(fields: [:], confidence: 0)
        }

        var extractedFields: [String: String] = [:]
        var totalConfidence: Double = 0
        var fieldCount: Int = 0

        for table in visionResult.recognizedTables {
            for row in table.rows {
                for i in 0..<(row.cells.count - 1) {
                    guard let keyText = row.cells[i].text else { continue }
                    
                    let (bestMatch, distance) = findBestKeywordMatch(keyText)
                    
                    if let bestMatch = bestMatch, distance <= 2 { // Allow up to 2 errors
                        if let valueText = row.cells[i+1].text {
                            let (cleanedValue, confidence) = cleanAndValidateFinancialValue(valueText)
                            if let finalValue = cleanedValue {
                                extractedFields[bestMatch] = finalValue
                                // Adjust confidence based on fuzzy match distance
                                totalConfidence += confidence * (1.0 - Double(distance) * 0.1)
                                fieldCount += 1
                            }
                        }
                    }
                }
            }
        }

        let averageConfidence = fieldCount > 0 ? totalConfidence / Double(fieldCount) : 0
        return MilitaryPayslip(fields: extractedFields, confidence: averageConfidence)
    }

    /// Finds the best keyword match for a given string using Levenshtein distance.
    private func findBestKeywordMatch(_ text: String) -> (String?, Int) {
        var bestMatch: String? = nil
        var minDistance = Int.max

        for keyword in keywords {
            let distance = levenshteinDistance(a: text.uppercased(), b: keyword)
            if distance < minDistance {
                minDistance = distance
                bestMatch = keyword
            }
        }
        return (bestMatch, minDistance)
    }

    /// Calculates the Levenshtein distance between two strings.
    private func levenshteinDistance(a: String, b: String) -> Int {
        let aCount = a.count
        let bCount = b.count
        var matrix = [[Int]](repeating: [Int](repeating: 0, count: bCount + 1), count: aCount + 1)

        for i in 0...aCount { matrix[i][0] = i }
        for j in 0...bCount { matrix[0][j] = j }

        for i in 1...aCount {
            for j in 1...bCount {
                let cost = a[a.index(a.startIndex, offsetBy: i - 1)] == b[b.index(b.startIndex, offsetBy: j - 1)] ? 0 : 1
                matrix[i][j] = min(matrix[i - 1][j] + 1, matrix[i][j - 1] + 1, matrix[i - 1][j - 1] + cost)
            }
        }
        return matrix[aCount][bCount]
    }

    /// Cleans and validates a string to ensure it's a valid financial value.
    private func cleanAndValidateFinancialValue(_ rawValue: String) -> (String?, Double) {
        var cleaned = rawValue.uppercased()
            .replacingOccurrences(of: "S", with: "5")
            .replacingOccurrences(of: "O", with: "0")
            .replacingOccurrences(of: "I", with: "1")
            .replacingOccurrences(of: "B", with: "8")

        let regex = try! NSRegularExpression(pattern: "[\\d,]+\\.\\d{2}", options: [])
        let range = NSRange(location: 0, length: cleaned.utf16.count)
        
        if let match = regex.firstMatch(in: cleaned, options: [], range: range) {
            if let swiftRange = Range(match.range, in: cleaned) {
                return (String(cleaned[swiftRange]), 0.95)
            }
        }
        
        cleaned = cleaned.filter { "0123456789.,".contains($0) }
        if !cleaned.isEmpty {
             return (cleaned, 0.75)
        }

        return (nil, 0)
    }
}

/// Represents a parsed military payslip.
struct MilitaryPayslip {
    let fields: [String: String]
    let confidence: Double
}