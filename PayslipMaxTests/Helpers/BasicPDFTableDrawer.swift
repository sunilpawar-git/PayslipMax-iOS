import Foundation
import PDFKit
import UIKit

/// Helper class for drawing table content in PDFs
class BasicPDFTableDrawer {

    private let pageRect: CGRect

    init(pageRect: CGRect) {
        self.pageRect = pageRect
    }

    func createPDFWithTable() -> Data {
        let pdfMetaData: [String: String] = [
            kCGPDFContextCreator as String: "PayslipMax Tests",
            kCGPDFContextAuthor as String: "Test Framework"
        ]
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]

        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)

        return renderer.pdfData { context in
            context.beginPage()
            self.drawTableContent(in: context)
        }
    }

    private func drawTableContent(in context: UIGraphicsPDFRendererContext) {
        let cgContext = context.cgContext
        let textFont = UIFont.systemFont(ofSize: 8.0, weight: .regular)
        let headerFont = UIFont.systemFont(ofSize: 10.0, weight: .bold)
        let titleFont = UIFont.systemFont(ofSize: 14.0, weight: .bold)

        // Draw title
        let titleAttributes = [NSAttributedString.Key.font: titleFont]
        "Complex Multi-Column Table Document with High Text Density".draw(
            with: CGRect(x: 50, y: 30, width: 500, height: 40),
            options: .usesLineFragmentOrigin,
            attributes: titleAttributes,
            context: nil
        )

        // Draw columns with dense text
        drawTableColumns(textFont: textFont, headerFont: headerFont)

        // Draw table grid
        drawTableGrid(cgContext: cgContext)

        // Draw table headers and data
        drawTableHeadersAndData(headerFont: headerFont, textFont: textFont)

        // Add additional dense text
        addAdditionalDenseText(textFont: textFont)
    }

    private func drawTableColumns(textFont: UIFont, headerFont: UIFont) {
        let leftColumnX: CGFloat = 50
        let rightColumnX: CGFloat = 320
        let columnWidth: CGFloat = 200

        let shortLine = "Short line text content for density"
        let longLine = "This is a much longer line of text for column detection."
        let mediumLine = "Medium length text for better distribution."
        let extraLongLine = "Long line designed to boost character count and text density."

        let shortLines = Array(repeating: shortLine, count: 100)
        let longLines = Array(repeating: longLine, count: 100)
        let mediumLines = Array(repeating: mediumLine, count: 100)
        let extraLongLines = Array(repeating: extraLongLine, count: 50)

        let leftColumnLines = shortLines + longLines + mediumLines + extraLongLines
        let rightColumnLines = longLines + shortLines + mediumLines + extraLongLines

        let leftColumnText = "LEFT COLUMN HEADER:\n\n" + leftColumnLines.joined(separator: "\n")
        let rightColumnText = "RIGHT COLUMN HEADER:\n\n" + rightColumnLines.joined(separator: "\n")

        let textAttributes = [NSAttributedString.Key.font: textFont]

        leftColumnText.draw(
            with: CGRect(x: leftColumnX, y: 80, width: columnWidth, height: 350),
            options: .usesLineFragmentOrigin,
            attributes: textAttributes,
            context: nil
        )

        rightColumnText.draw(
            with: CGRect(x: rightColumnX, y: 80, width: columnWidth, height: 350),
            options: .usesLineFragmentOrigin,
            attributes: textAttributes,
            context: nil
        )
    }

    private func drawTableGrid(cgContext: CGContext) {
        let tableX: CGFloat = 50
        let tableY: CGFloat = 450
        let cellWidth: CGFloat = 120
        let cellHeight: CGFloat = 25
        let columns = 4
        let rows = 8

        cgContext.setStrokeColor(UIColor.black.cgColor)
        cgContext.setLineWidth(1.0)

        // Draw vertical lines
        for col in 0...columns {
            let xPos = tableX + CGFloat(col) * cellWidth
            cgContext.move(to: CGPoint(x: xPos, y: tableY))
            cgContext.addLine(to: CGPoint(x: xPos, y: tableY + CGFloat(rows) * cellHeight))
            cgContext.strokePath()
        }

        // Draw horizontal lines
        for row in 0...rows {
            let yPos = tableY + CGFloat(row) * cellHeight
            cgContext.move(to: CGPoint(x: tableX, y: yPos))
            cgContext.addLine(to: CGPoint(x: tableX + CGFloat(columns) * cellWidth, y: yPos))
            cgContext.strokePath()
        }
    }

    private func drawTableHeadersAndData(headerFont: UIFont, textFont: UIFont) {
        let tableX: CGFloat = 50
        let tableY: CGFloat = 450
        let cellWidth: CGFloat = 120
        let cellHeight: CGFloat = 25

        let headers = ["Item | Desc", "Amount | Curr", "Type | Class", "Status | State"]
        let headerAttributes = [NSAttributedString.Key.font: headerFont]
        let textAttributes = [NSAttributedString.Key.font: textFont]

        // Draw headers
        for (col, header) in headers.enumerated() {
            let cellRect = CGRect(
                x: tableX + CGFloat(col) * cellWidth + 2,
                y: tableY + 2,
                width: cellWidth - 4,
                height: cellHeight - 4
            )
            header.draw(
                with: cellRect,
                options: .usesLineFragmentOrigin,
                attributes: headerAttributes,
                context: nil
            )
        }

        // Draw data rows
        let tableData = [
            ["Basic Pay | BP001", "5000.00 | INR", "Credit | CR", "Active | ACT"],
            ["Allowances | AL002", "1500.00 | INR", "Credit | CR", "Active | ACT"],
            ["House Rent | HR003", "2000.00 | INR", "Credit | CR", "Active | ACT"],
            ["Transport | TR004", "800.00 | INR", "Credit | CR", "Active | ACT"],
            ["Deductions | DED005", "800.00 | INR", "Debit | DR", "Active | ACT"],
            ["Income Tax | TAX006", "600.00 | INR", "Debit | DR", "Active | ACT"],
            ["DSOP Fund | DSOP007", "300.00 | INR", "Debit | DR", "Active | ACT"]
        ]

        for (row, rowData) in tableData.enumerated() {
            for (col, cellData) in rowData.enumerated() {
                let cellRect = CGRect(
                    x: tableX + CGFloat(col) * cellWidth + 2,
                    y: tableY + CGFloat(row + 1) * cellHeight + 2,
                    width: cellWidth - 4,
                    height: cellHeight - 4
                )
                cellData.draw(
                    with: cellRect,
                    options: .usesLineFragmentOrigin,
                    attributes: textAttributes,
                    context: nil
                )
            }
        }
    }

    private func addAdditionalDenseText(textFont: UIFont) {
        let textAttributes = [NSAttributedString.Key.font: textFont]

        let additionalLine = "Dense text for table extraction strategy validation. "
        let additionalText = String(repeating: additionalLine, count: 150)
        additionalText.draw(
            with: CGRect(x: 50, y: 650, width: 500, height: 180),
            options: .usesLineFragmentOrigin,
            attributes: textAttributes,
            context: nil
        )

        let footerLine = "Footer text for additional text density boost. "
        let footerText = String(repeating: footerLine, count: 80)
        footerText.draw(
            with: CGRect(x: 50, y: 750, width: 500, height: 80),
            options: .usesLineFragmentOrigin,
            attributes: textAttributes,
            context: nil
        )
    }
}

