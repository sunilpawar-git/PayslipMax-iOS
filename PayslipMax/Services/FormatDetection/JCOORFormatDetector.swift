import Foundation

/// Detects JCO/OR format payslips based on specific text markers
final class JCOORFormatDetector: JCOORFormatDetectorProtocol {

    // MARK: - Constants

    private enum Constants {
        /// Minimum number of markers required to identify JCO/OR format
        static let minimumMarkerMatches = 2
    }

    /// Text markers commonly found in JCO/OR payslips
    private let jcoORMarkers = [
        "STATEMENT OF ACCOUNT FOR MONTH ENDING",
        "PAO",
        "SUS NO",
        "TASK",
        "AMOUNT CREDITED TO BANK",
        "वेतन विवरण",           // Hindi: Salary Statement
        "बैंक में जमा राशि"     // Hindi: Amount Credited to Bank
    ]

    // MARK: - JCOORFormatDetectorProtocol

    func isJCOORFormat(text: String) async -> Bool {
        let uppercased = text.uppercased()

        let matchCount = jcoORMarkers.filter { marker in
            uppercased.contains(marker.uppercased())
        }.count

        return matchCount >= Constants.minimumMarkerMatches
    }
}
