import XCTest

/// Screen object representing the PayslipDetailView
class PayslipDetailScreen {
    let app: XCUIApplication
    
    init(app: XCUIApplication) {
        self.app = app
    }
    
    // MARK: - Navigation Elements
    
    var navigationBar: XCUIElement {
        app.navigationBars["Payslip Details"]
    }
    
    var backButton: XCUIElement {
        navigationBar.buttons.element(boundBy: 0)
    }
    
    var deleteButton: XCUIElement {
        app.buttons["trash"]
    }
    
    var shareButton: XCUIElement {
        app.buttons["square.and.arrow.up"]
    }
    
    // MARK: - Section Headers
    
    var personalDetailsHeader: XCUIElement {
        app.staticTexts["PERSONAL DETAILS"]
    }
    
    var financialDetailsHeader: XCUIElement {
        app.staticTexts["FINANCIAL DETAILS"]
    }
    
    var earningsDeductionsHeader: XCUIElement {
        app.staticTexts["EARNINGS & DEDUCTIONS"]
    }
    
    var diagnosticsHeader: XCUIElement {
        app.staticTexts["DIAGNOSTICS"]
    }
    
    // MARK: - Personal Details Elements
    
    var nameLabel: XCUIElement {
        app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH %@", "Name:")).element
    }
    
    var nameValue: XCUIElement {
        // Find the text element that follows the name label
        let nameElements = app.staticTexts.allElementsBoundByIndex
        for (index, element) in nameElements.enumerated() {
            if element.label.starts(with: "Name:") && index + 1 < nameElements.count {
                return nameElements[index + 1]
            }
        }
        return app.staticTexts.element(boundBy: 0) // Fallback
    }
    
    var accountLabel: XCUIElement {
        app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH %@", "Account:")).element
    }
    
    var accountValue: XCUIElement {
        // Similar approach to find the account value
        let accountElements = app.staticTexts.allElementsBoundByIndex
        for (index, element) in accountElements.enumerated() {
            if element.label.starts(with: "Account:") && index + 1 < accountElements.count {
                return accountElements[index + 1]
            }
        }
        return app.staticTexts.element(boundBy: 0) // Fallback
    }
    
    var panLabel: XCUIElement {
        app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH %@", "PAN:")).element
    }
    
    var panValue: XCUIElement {
        // Similar approach to find the PAN value
        let panElements = app.staticTexts.allElementsBoundByIndex
        for (index, element) in panElements.enumerated() {
            if element.label.starts(with: "PAN:") && index + 1 < panElements.count {
                return panElements[index + 1]
            }
        }
        return app.staticTexts.element(boundBy: 0) // Fallback
    }
    
    // MARK: - Financial Details Elements
    
    var creditsRow: XCUIElement {
        app.staticTexts["Credits"]
    }
    
    var creditsValue: XCUIElement {
        // Find the text element that follows the credits label
        let creditsElements = app.staticTexts.allElementsBoundByIndex
        for (index, element) in creditsElements.enumerated() {
            if element.label == "Credits" && index + 1 < creditsElements.count {
                return creditsElements[index + 1]
            }
        }
        return app.staticTexts.element(boundBy: 0) // Fallback
    }
    
    var debitsRow: XCUIElement {
        app.staticTexts["Debits"]
    }
    
    var dsopRow: XCUIElement {
        app.staticTexts["DSOP"]
    }
    
    var incomeTaxRow: XCUIElement {
        app.staticTexts["Income Tax"]
    }
    
    // MARK: - Earnings & Deductions Elements
    
    var viewToggleButton: XCUIElement {
        app.buttons["chart.pie"] // or "list.bullet" depending on current state
    }
    
    var earningsBreakdownHeader: XCUIElement {
        app.staticTexts["DETAILED EARNINGS"]
    }
    
    var deductionsBreakdownHeader: XCUIElement {
        app.staticTexts["DETAILED DEDUCTIONS"]
    }
    
    // MARK: - Diagnostics Elements
    
    var viewExtractionPatternsButton: XCUIElement {
        app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "View Extraction Patterns")).element
    }
    
    // MARK: - Actions
    
    func tapBackButton() {
        backButton.tap()
    }
    
    func tapDeleteButton() {
        deleteButton.tap()
    }
    
    func confirmDelete() {
        app.buttons["Delete"].tap()
    }
    
    func cancelDelete() {
        app.buttons["Cancel"].tap()
    }
    
    func tapShareButton() {
        shareButton.tap()
    }
    
    func tapEditButton() {
        app.buttons["Edit"].tap()
    }
    
    func toggleViewMode() {
        viewToggleButton.tap()
    }
    
    func tapViewExtractionPatternsButton() {
        viewExtractionPatternsButton.tap()
    }
    
    func scrollToSection(_ sectionName: String) {
        let section = app.staticTexts[sectionName]
        if !UITestHelper.isElementVisible(section) {
            let scrollView = app.scrollViews.firstMatch
            var attempts = 0
            while !UITestHelper.isElementVisible(section) && attempts < 5 {
                scrollView.swipeUp()
                attempts += 1
            }
        }
    }
    
    // MARK: - Verification
    
    func isOnPayslipDetailScreen() -> Bool {
        return navigationBar.exists
    }
    
    func hasPersonalDetails() -> Bool {
        return nameLabel.exists && accountLabel.exists && panLabel.exists
    }
    
    func hasFinancialDetails() -> Bool {
        return creditsRow.exists && debitsRow.exists && dsopRow.exists && incomeTaxRow.exists
    }
    
    func hasEarningsAndDeductions() -> Bool {
        scrollToSection("EARNINGS & DEDUCTIONS")
        return earningsDeductionsHeader.exists
    }
    
    func hasDiagnosticsSection() -> Bool {
        scrollToSection("DIAGNOSTICS")
        return diagnosticsHeader.exists && viewExtractionPatternsButton.exists
    }
} 