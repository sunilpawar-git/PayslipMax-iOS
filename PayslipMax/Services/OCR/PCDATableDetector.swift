import Foundation
import CoreGraphics

struct PCDATableStructure {
    let baseStructure: TableStructure
    let headerRow: TableStructure.TableRow?
    let dataRows: [TableStructure.TableRow]
    let creditColumns: (description: Int, amount: Int)
    let debitColumns: (description: Int, amount: Int)
    let isPCDAFormat: Bool
    let pcdaTableBounds: CGRect
    let detailsPanelBounds: CGRect?

    // Compatibility/computed properties
    var bounds: CGRect { baseStructure.bounds }
    var columnCount: Int { baseStructure.columns.count }
    var totalRowCount: Int { baseStructure.rows.count }
    var dataRowCount: Int { dataRows.count }

    init(
        baseStructure: TableStructure,
        headerRow: TableStructure.TableRow?,
        dataRows: [TableStructure.TableRow],
        creditColumns: (description: Int, amount: Int),
        debitColumns: (description: Int, amount: Int),
        isPCDAFormat: Bool,
        pcdaTableBounds: CGRect,
        detailsPanelBounds: CGRect?
    ) {
        self.baseStructure = baseStructure
        self.headerRow = headerRow
        self.dataRows = dataRows
        self.creditColumns = creditColumns
        self.debitColumns = debitColumns
        self.isPCDAFormat = isPCDAFormat
        self.pcdaTableBounds = pcdaTableBounds
        self.detailsPanelBounds = detailsPanelBounds
    }

    // Backward-compatible initializer (used by older tests)
    init(
        baseStructure: TableStructure,
        headerRow: TableStructure.TableRow?,
        dataRows: [TableStructure.TableRow],
        creditColumns: (description: Int, amount: Int),
        debitColumns: (description: Int, amount: Int),
        isPCDAFormat: Bool
    ) {
        self.init(
            baseStructure: baseStructure,
            headerRow: headerRow,
            dataRows: dataRows,
            creditColumns: creditColumns,
            debitColumns: debitColumns,
            isPCDAFormat: isPCDAFormat,
            pcdaTableBounds: baseStructure.bounds,
            detailsPanelBounds: nil
        )
    }
}

protocol PCDATableDetectorProtocol {
    func detectPCDATableStructure(from textElements: [TextElement]) -> PCDATableStructure?
}

final class PCDATableDetector: PCDATableDetectorProtocol {
    private let minimumRowSpacing: CGFloat = 5.0
    private let minimumColumnSpacing: CGFloat = 10.0
    private let alignmentTolerance: CGFloat = 3.0

    init() {}

    func detectPCDATableStructure(from textElements: [TextElement]) -> PCDATableStructure? {
        guard !textElements.isEmpty else { return nil }
        
        // Use SimpleTableDetector for base grid
        let baseDetector = SimpleTableDetector()
        guard let baseStructure = baseDetector.detectTableStructure(from: textElements) else { return nil }
        guard isPCDATableFormat(baseStructure: baseStructure, textElements: textElements) else { return nil }
        let (headerRow, dataRows) = identifyPCDARows(from: baseStructure, textElements: textElements)
        let columnLayout = determinePCDAColumnLayout(baseStructure: baseStructure, textElements: textElements)
        let (gridBounds, panelBounds) = computePCDABounds(
            baseStructure: baseStructure,
            headerRow: headerRow,
            dataRows: dataRows,
            columnLayout: columnLayout,
            textElements: textElements
        )
        return PCDATableStructure(
            baseStructure: baseStructure,
            headerRow: headerRow,
            dataRows: dataRows,
            creditColumns: columnLayout.credit,
            debitColumns: columnLayout.debit,
            isPCDAFormat: true,
            pcdaTableBounds: gridBounds,
            detailsPanelBounds: panelBounds
        )
    }

    private func isPCDATableFormat(baseStructure: TableStructure, textElements: [TextElement]) -> Bool {
        guard baseStructure.columns.count >= 4 else { return false }
        let hasBilingual = detectBilingualHeaders(textElements: textElements)
        let hasTerms = detectPCDATerms(textElements: textElements)
        let hasRows = baseStructure.rows.count >= 3
        return hasBilingual || hasTerms || hasRows
    }

    private func detectBilingualHeaders(textElements: [TextElement]) -> Bool {
        let englishTokens = ["DESCRIPTION", "AMOUNT", "CREDIT", "DEBIT", "EARNINGS", "DEDUCTIONS"]
        let hindiTokens = ["विवरण", "राशि", "जमा", "नावे"]
        let joined = textElements.map { $0.text }.joined(separator: " ")
        let upper = joined.uppercased()
        func containsPair(_ a: String, _ b: String) -> Bool {
            return upper.contains("\(a.uppercased())/\(b)") || upper.contains("\(b)/\(a.uppercased())") ||
                   upper.contains("\(a.uppercased()) \(b)") || upper.contains("\(b) \(a.uppercased())")
        }
        for h in hindiTokens { for e in englishTokens { if containsPair(h, e) { return true } } }
        if let headerY = textElements.min(by: { $0.bounds.minY < $1.bounds.minY })?.bounds.minY {
            let band = textElements.filter { abs($0.bounds.minY - headerY) <= alignmentTolerance * 2 }
            let header = band.map { $0.text.uppercased() }.joined(separator: " ")
            let hasHindi = hindiTokens.contains { header.contains($0.uppercased()) }
            let hasEnglish = englishTokens.contains { header.contains($0) }
            return hasHindi && hasEnglish
        }
        return false
    }

    private func detectPCDATerms(textElements: [TextElement]) -> Bool {
        let pcdaTerms = [
            "PCDA", "PRINCIPAL CONTROLLER", "DEFENCE ACCOUNTS",
            "DSOPF", "AGIF", "MSP", "MILITARY SERVICE PAY",
            "BASIC PAY", "DA", "DEARNESS ALLOWANCE",
            "TPTALLC", "TRANSPORT ALLOWANCE",
            "INCM TAX", "INCOME TAX",
            "TOTAL CREDIT", "TOTAL DEBIT", "NET REMITTANCE"
        ]
        let allText = textElements.map { $0.text.uppercased() }.joined(separator: " ")
        let matchCount = pcdaTerms.filter { allText.contains($0) }.count
        return matchCount >= 3
    }

    private func identifyPCDARows(from baseStructure: TableStructure, textElements: [TextElement]) -> (header: TableStructure.TableRow?, data: [TableStructure.TableRow]) {
        guard !baseStructure.rows.isEmpty else { return (nil, []) }
        let headerRow = baseStructure.rows.first
        let dataRows = Array(baseStructure.rows.dropFirst())
        let headerValid = headerRow.map { row in
            let headerElements = textElements.filter { $0.bounds.intersects(row.bounds) }
            let headerText = headerElements.map { $0.text.uppercased() }.joined(separator: " ")
            return headerText.contains("DESCRIPTION") || headerText.contains("AMOUNT") || headerText.contains("विवरण") || headerText.contains("राशि")
        } ?? false
        return (headerValid ? headerRow : nil, dataRows)
    }

    private func determinePCDAColumnLayout(baseStructure: TableStructure, textElements: [TextElement]) -> (credit: (description: Int, amount: Int), debit: (description: Int, amount: Int)) {
        if let inferred = inferColumnsByNumericClustering(baseStructure: baseStructure, textElements: textElements) {
            return inferred
        }
        let count = baseStructure.columns.count
        if count >= 4 { return (credit: (0, 1), debit: (2, 3)) }
        if count == 3 { return (credit: (0, 1), debit: (0, 2)) }
        return (credit: (0, min(1, max(1, count - 1))), debit: (min(2, max(1, count - 1)), min(3, max(1, count - 1))))
    }

    private func inferColumnsByNumericClustering(baseStructure: TableStructure, textElements: [TextElement]) -> (credit: (description: Int, amount: Int), debit: (description: Int, amount: Int))? {
        let numericPattern = try? NSRegularExpression(pattern: "^[\\p{Sc}]?\\s*[0-9,.()]+$", options: [])
        let numericElements = textElements.filter { el in
            guard let regex = numericPattern else { return false }
            let ns = el.text as NSString
            return regex.firstMatch(in: el.text, options: [], range: NSRange(location: 0, length: ns.length)) != nil
        }
        guard numericElements.count >= 2 else { return nil }
        let xs = numericElements.map { $0.bounds.midX }
        guard let minX = xs.min(), let maxX = xs.max(), maxX > minX else { return nil }
        var c1 = minX, c2 = maxX
        for _ in 0..<5 {
            var left: [CGFloat] = [], right: [CGFloat] = []
            for x in xs { if abs(x - c1) <= abs(x - c2) { left.append(x) } else { right.append(x) } }
            if !left.isEmpty { c1 = left.reduce(0, +) / CGFloat(left.count) }
            if !right.isEmpty { c2 = right.reduce(0, +) / CGFloat(right.count) }
        }
        let centers = [c1, c2].sorted()
        func nearestColumnIndex(to x: CGFloat) -> Int? {
            let pairs = baseStructure.columns.map { ($0.index, abs($0.xPosition + $0.width/2 - x)) }
            return pairs.min(by: { $0.1 < $1.1 })?.0
        }
        guard let leftAmount = nearestColumnIndex(to: centers[0]), let rightAmount = nearestColumnIndex(to: centers[1]) else { return nil }
        let sortedCols = baseStructure.columns.sorted(by: { $0.xPosition < $1.xPosition })
        func descriptionColumn(leftOf amountIdx: Int) -> Int {
            let amountX = baseStructure.columns.first(where: { $0.index == amountIdx })?.xPosition ?? 0
            var candidate: Int = amountIdx
            for col in sortedCols { if col.xPosition < amountX { candidate = col.index } else { break } }
            return candidate
        }
        let creditDesc = descriptionColumn(leftOf: leftAmount)
        let debitDesc = descriptionColumn(leftOf: rightAmount)
        return (credit: (creditDesc, leftAmount), debit: (debitDesc, rightAmount))
    }

    private func computePCDABounds(
        baseStructure: TableStructure,
        headerRow: TableStructure.TableRow?,
        dataRows: [TableStructure.TableRow],
        columnLayout: (credit: (description: Int, amount: Int), debit: (description: Int, amount: Int)),
        textElements: [TextElement]
    ) -> (grid: CGRect, panel: CGRect?) {
        let cols = baseStructure.columns
        guard let leftDesc = cols.first(where: { $0.index == columnLayout.credit.description }),
              let leftAmt = cols.first(where: { $0.index == columnLayout.credit.amount }),
              let rightDesc = cols.first(where: { $0.index == columnLayout.debit.description }),
              let rightAmt = cols.first(where: { $0.index == columnLayout.debit.amount }) else {
            return (baseStructure.bounds, nil)
        }
        let minX = min(leftDesc.bounds.minX, leftAmt.bounds.minX, rightDesc.bounds.minX, rightAmt.bounds.minX)
        let maxX = max(leftDesc.bounds.maxX, leftAmt.bounds.maxX, rightDesc.bounds.maxX, rightAmt.bounds.maxX)
        let topY = headerRow?.bounds.minY ?? baseStructure.rows.first?.bounds.minY ?? baseStructure.bounds.minY
        let bottomY = dataRows.last?.bounds.maxY ?? baseStructure.rows.last?.bounds.maxY ?? baseStructure.bounds.maxY
        let gridBounds = CGRect(x: minX, y: topY, width: maxX - minX, height: max(0, bottomY - topY))

        let margin: CGFloat = 6.0
        let panelCandidates = textElements.filter { el in
            let inVerticalBand = el.bounds.maxY >= topY - margin && el.bounds.minY <= bottomY + margin
            return inVerticalBand && el.bounds.minX >= gridBounds.maxX + minimumColumnSpacing
        }
        if panelCandidates.isEmpty { return (gridBounds, nil) }
        let panelMinX = panelCandidates.map { $0.bounds.minX }.min() ?? 0
        let panelMaxX = panelCandidates.map { $0.bounds.maxX }.max() ?? 0
        let panelMinY = panelCandidates.map { $0.bounds.minY }.min() ?? 0
        let panelMaxY = panelCandidates.map { $0.bounds.maxY }.max() ?? 0
        let panelBounds = CGRect(x: panelMinX, y: panelMinY, width: panelMaxX - panelMinX, height: panelMaxY - panelMinY)
        if panelBounds.width >= max(40, gridBounds.width * 0.2) { return (gridBounds, panelBounds) }
        return (gridBounds, nil)
    }
}


