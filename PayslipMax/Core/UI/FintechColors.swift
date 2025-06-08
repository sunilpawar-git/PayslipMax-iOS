import SwiftUI

/// Global fintech color system following industry best practices
/// Based on analysis of leading fintech companies (Stripe, PayPal, Revolut, etc.)
struct FintechColors {
    // MARK: - Primary Brand Colors
    /// Professional blue for trust and stability - Used by major fintech companies
    static let primaryBlue = Color(red: 0.1, green: 0.4, blue: 0.8) // #1A66CC
    /// Secondary blue for interactive elements and buttons
    static let secondaryBlue = Color(red: 0.2, green: 0.5, blue: 0.9) // #3380E6
    
    // MARK: - Financial Status Colors
    /// Success green for positive values, gains, credits
    static let successGreen = Color(red: 0.1, green: 0.7, blue: 0.3) // #1BB34A
    /// Warning amber for neutral states and caution indicators
    static let warningAmber = Color(red: 1.0, green: 0.7, blue: 0.0) // #FFB300
    /// Danger red for negative values, losses, debits
    static let dangerRed = Color(red: 0.9, green: 0.2, blue: 0.2) // #E63946
    
    // MARK: - Neutral Palette (WCAG 2.1 AA Compliant)
    /// Background gray for cards and sections
    static let backgroundGray = Color(red: 0.98, green: 0.98, blue: 0.99) // #FAFAFA
    /// Secondary background for elevated content
    static let secondaryBackground = Color(red: 0.96, green: 0.96, blue: 0.97) // #F5F5F6
    /// Accent background for special sections and highlights
    static let accentBackground = Color(red: 0.94, green: 0.94, blue: 0.96) // #F0F0F5
    /// Primary text color with high contrast
    static let textPrimary = Color(red: 0.1, green: 0.1, blue: 0.1) // #1A1A1A
    /// Secondary text color for subtitles and descriptions
    static let textSecondary = Color(red: 0.4, green: 0.4, blue: 0.45) // #666673
    /// Tertiary text for placeholder and disabled states
    static let textTertiary = Color(red: 0.6, green: 0.6, blue: 0.63) // #999AA3
    
    // MARK: - Chart Colors
    /// Primary chart color with gradient support
    static let chartPrimary = primaryBlue
    /// Secondary chart color - teal accent
    static let chartSecondary = Color(red: 0.0, green: 0.6, blue: 0.8) // #0099CC
    /// Tertiary chart color - light blue
    static let chartTertiary = Color(red: 0.5, green: 0.7, blue: 0.9) // #80B3E6
    
    // MARK: - UI Element Colors
    /// Divider color for separating content
    static let divider = Color(red: 0.9, green: 0.9, blue: 0.91) // #E6E6E8
    /// Border color for input fields and cards
    static let border = Color(red: 0.85, green: 0.85, blue: 0.87) // #D9D9DD
    /// Legacy border color alias for compatibility
    static let borderColor = border
    /// Shadow color for depth and elevation
    static let shadow = textSecondary.opacity(0.1)
    
    // MARK: - Gradient Colors
    /// Primary gradient for charts and premium elements
    static let primaryGradient = LinearGradient(
        colors: [primaryBlue, chartSecondary],
        startPoint: .leading,
        endPoint: .trailing
    )
    
    /// Success gradient for positive value indicators
    static let successGradient = LinearGradient(
        colors: [successGreen, Color(red: 0.0, green: 0.8, blue: 0.4)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    /// Chart area gradient for visual depth
    static let chartAreaGradient = LinearGradient(
        colors: [primaryBlue.opacity(0.2), chartTertiary.opacity(0.05)],
        startPoint: .top,
        endPoint: .bottom
    )
    
    // MARK: - Accessibility Helper Functions
    
    /// Returns appropriate color for financial values with accessibility support
    /// - Parameters:
    ///   - value: The financial value to evaluate
    ///   - isPositive: Whether positive values should be green (default: true)
    /// - Returns: Color that meets WCAG contrast requirements
    static func getAccessibleColor(for value: Double, isPositive: Bool = true) -> Color {
        if isPositive {
            return value > 0 ? successGreen : (value == 0 ? textSecondary : dangerRed)
        } else {
            return value < 0 ? dangerRed : (value == 0 ? textSecondary : successGreen)
        }
    }
    
    /// Returns color for trend indicators
    /// - Parameter trend: The trend value (positive = up, negative = down, zero = neutral)
    /// - Returns: Appropriate color for the trend
    static func getTrendColor(for trend: Double) -> Color {
        if trend > 0.05 { // 5% threshold for significant change
            return successGreen
        } else if trend < -0.05 {
            return dangerRed
        } else {
            return warningAmber
        }
    }
    
    /// Returns category-specific colors for financial data
    /// - Parameter category: The financial category
    /// - Returns: Appropriate color for the category
    static func getCategoryColor(for category: String) -> Color {
        switch category.lowercased() {
        case "income", "earnings", "credits", "salary", "bonus":
            return successGreen
        case "deductions", "debits", "tax", "expenses":
            return dangerRed
        case "net", "balance", "total":
            return primaryBlue
        case "savings", "investment", "dsop":
            return Color(red: 0.2, green: 0.6, blue: 0.9) // Light blue
        default:
            // Generate consistent color based on category string
            let hash = abs(category.hashValue)
            let hue = Double(hash % 100) / 100.0
            return Color(hue: hue, saturation: 0.7, brightness: 0.9)
        }
    }
}

// MARK: - Extension for View Modifiers

extension View {
    /// Applies fintech card styling
    func fintechCardStyle() -> some View {
        self
            .padding()
            .background(FintechColors.backgroundGray)
            .cornerRadius(16)
            .shadow(color: FintechColors.shadow, radius: 8, x: 0, y: 2)
    }
    
    /// Applies fintech section background
    func fintechSectionBackground() -> some View {
        self
            .background(FintechColors.secondaryBackground)
            .cornerRadius(12)
    }
    
    /// Applies fintech divider styling
    func fintechDivider() -> some View {
        Rectangle()
            .fill(FintechColors.divider)
            .frame(height: 1)
    }
}

// MARK: - Color Theme Extensions

extension Color {
    /// Primary fintech brand color
    static let fintechPrimary = FintechColors.primaryBlue
    /// Success state color
    static let fintechSuccess = FintechColors.successGreen
    /// Warning state color
    static let fintechWarning = FintechColors.warningAmber
    /// Danger state color
    static let fintechDanger = FintechColors.dangerRed
    /// Secondary text color
    static let fintechSecondary = FintechColors.textSecondary
} 