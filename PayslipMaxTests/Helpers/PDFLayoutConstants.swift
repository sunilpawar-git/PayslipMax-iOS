import Foundation
import UIKit

/// Constants and layout utilities for PDF generation
/// Centralizes all layout-related constants and calculations
/// Follows SOLID principles with single responsibility focus
struct PDFLayoutConstants {

    // MARK: - Page Dimensions

    static let defaultPageRect = CGRect(x: 0, y: 0, width: 595.2, height: 841.8) // A4 size

    // MARK: - Layout Positions

    static let titleY: CGFloat = 50
    static let titleHeight: CGFloat = 30

    static let dateY: CGFloat = 100
    static let dateHeight: CGFloat = 20
    static let dateWidth: CGFloat = 200
    static let dateX: CGFloat = defaultPageRect.width - 230

    static let nameY: CGFloat = 150
    static let rankY: CGFloat = 170
    static let idY: CGFloat = 190
    static let personalInfoHeight: CGFloat = 20
    static let personalInfoX: CGFloat = 50
    static let personalInfoWidth: CGFloat = defaultPageRect.width - 100

    static let tableHeaderY: CGFloat = 250
    static let rowHeight: CGFloat = 30

    static let footerY: CGFloat = defaultPageRect.height - 50
    static let footerHeight: CGFloat = 20
    static let footerX: CGFloat = 50
    static let footerWidth: CGFloat = defaultPageRect.width - 100

    // MARK: - Table Layout

    static let tableX: CGFloat = 50
    static let tableWidth: CGFloat = defaultPageRect.width - 100
    static let descriptionColumnWidth: CGFloat = 200
    static let amountColumnWidth: CGFloat = 180
    static let amountColumnX: CGFloat = defaultPageRect.width - 250

    // MARK: - Font Sizes

    static let titleFontSize: CGFloat = 18.0
    static let headerFontSize: CGFloat = 14.0
    static let textFontSize: CGFloat = 12.0

    // MARK: - Calculations

    static func tableRowY(for row: Int, headerY: CGFloat = tableHeaderY) -> CGFloat {
        headerY + CGFloat(row) * rowHeight
    }

    static func tableDataY(for row: Int, headerY: CGFloat = tableHeaderY) -> CGFloat {
        headerY + CGFloat(row + 1) * rowHeight
    }

    static func netAmountY(headerY: CGFloat = tableHeaderY) -> CGFloat {
        headerY + 5 * rowHeight + 10
    }

    static func separatorY(headerY: CGFloat = tableHeaderY) -> CGFloat {
        headerY + 5 * rowHeight
    }

    // MARK: - Font Creation

    static func titleFont() -> UIFont {
        UIFont.systemFont(ofSize: titleFontSize, weight: .bold)
    }

    static func headerFont() -> UIFont {
        UIFont.systemFont(ofSize: headerFontSize, weight: .bold)
    }

    static func textFont() -> UIFont {
        UIFont.systemFont(ofSize: textFontSize, weight: .regular)
    }
}

/// Protocol for PDF layout operations
/// Defines interface for layout-related calculations and utilities
protocol PDFLayoutProvider {
    var pageRect: CGRect { get }
    func calculateRowY(for row: Int, headerY: CGFloat) -> CGFloat
    func calculateTableDataY(for row: Int, headerY: CGFloat) -> CGFloat
}

/// Default implementation of PDFLayoutProvider
extension PDFLayoutConstants: PDFLayoutProvider {
    var pageRect: CGRect {
        PDFLayoutConstants.defaultPageRect
    }

    func calculateRowY(for row: Int, headerY: CGFloat) -> CGFloat {
        PDFLayoutConstants.tableRowY(for: row, headerY: headerY)
    }

    func calculateTableDataY(for row: Int, headerY: CGFloat) -> CGFloat {
        PDFLayoutConstants.tableDataY(for: row, headerY: headerY)
    }
}
