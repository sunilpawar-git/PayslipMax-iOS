import SwiftUI

/// Global fintech color system following industry best practices
/// Based on analysis of leading fintech companies (Stripe, PayPal, Revolut, etc.)
struct FintechColors {
    // MARK: - Primary Brand Colors
    /// Professional blue for trust and stability - Used by major fintech companies
    static let primaryBlue = Color(red: 0.1, green: 0.4, blue: 0.8) // #1A66CC
    /// Secondary blue for interactive elements and buttons
    static let secondaryBlue = Color(red: 0.2, green: 0.5, blue: 0.9) // #3380E6
    /// Deep navy blue matching home screen - P3 color space for enhanced blue depth
    static let deepNavyBlue = Color(.displayP3, red: 0.0, green: 0.0, blue: 0.478) // P3 #00007A
    /// Light blue for accent circles and highlights
    static let accentLightBlue = Color(red: 0.345, green: 0.561, blue: 0.969) // #588FF7

    // MARK: - Financial Status Colors
    /// Success green for positive values, gains, credits
    static let successGreen = Color(red: 0.1, green: 0.7, blue: 0.3) // #1BB34A
    /// Warning amber for neutral states and caution indicators
    static let warningAmber = Color(red: 1.0, green: 0.7, blue: 0.0) // #FFB300
    /// Danger red for negative values, losses, debits
    static let dangerRed = Color(red: 0.9, green: 0.2, blue: 0.2) // #E63946
    /// Premium gold for exclusive features and achievements
    static let premiumGold = Color(red: 0.85, green: 0.65, blue: 0.13) // #D9A521
    /// X-Ray positive tint (semantic, theme-aware via asset)
    static let xRayPositiveTint = Color("XRayTintPositive")
    /// X-Ray negative tint (semantic, theme-aware via asset)
    static let xRayNegativeTint = Color("XRayTintNegative")
    /// Subtle accent stroke for positive X-Ray highlights
    static var xRayPositiveAccent: Color {
        Color(UIColor { traitCollection in
            UIColor(red: 0.1, green: 0.7, blue: 0.3, alpha: traitCollection.userInterfaceStyle == .dark ? 0.45 : 0.3)
        })
    }
    /// Subtle accent stroke for negative X-Ray highlights
    static var xRayNegativeAccent: Color {
        Color(UIColor { traitCollection in
            UIColor(red: 0.9, green: 0.2, blue: 0.2, alpha: traitCollection.userInterfaceStyle == .dark ? 0.45 : 0.3)
        })
    }

    // MARK: - Neutral Palette (WCAG 2.1 AA Compliant, Theme-Aware)

    /// Main app background - the base background color for screens
    static let appBackground = Color(.systemBackground)

    /// Card background - for cards and sections that need to stand out from main background
    static var cardBackground: Color {
        Color(UIColor { traitCollection in
            if traitCollection.userInterfaceStyle == .dark {
                return UIColor.secondarySystemBackground
            } else {
                return UIColor(red: 0.96, green: 0.96, blue: 0.97, alpha: 1.0)  // Perfect light gray that matches Home screen
            }
        })
    }

    /// Background gray (legacy) - now maps to card background for compatibility
    static let backgroundGray = cardBackground

    /// Secondary background for elevated content - adapts to theme
    static let secondaryBackground = cardBackground

    /// Accent background for special sections and highlights - adapts to theme
    static let accentBackground = Color(.tertiarySystemBackground)

    /// Primary text color with high contrast - adapts to theme
    static let textPrimary = Color(.label)

    /// Secondary text color for subtitles and descriptions - adapts to theme
    static let textSecondary = Color(.secondaryLabel)

    /// Tertiary text for placeholder and disabled states - adapts to theme
    static let textTertiary = Color(.tertiaryLabel)

    // MARK: - Chart Colors
    /// Primary chart color with gradient support
    static let chartPrimary = primaryBlue
    /// Secondary chart color - teal accent
    static let chartSecondary = Color(red: 0.0, green: 0.6, blue: 0.8) // #0099CC
    /// Tertiary chart color - light blue
    static let chartTertiary = Color(red: 0.5, green: 0.7, blue: 0.9) // #80B3E6

    // MARK: - UI Element Colors (Theme-Aware)
    /// Divider color for separating content - adapts to theme
    static let divider = Color(.separator)

    /// Border color for input fields and cards - adapts to theme
    static let border = Color(.separator).opacity(0.5)

    /// Legacy border color alias for compatibility
    static let borderColor = border

    /// Shadow color for depth and elevation - adapts to theme
    static var shadow: Color {
        Color(UIColor { traitCollection in
            if traitCollection.userInterfaceStyle == .dark {
                return UIColor.systemGray4.withAlphaComponent(0.3)
            } else {
                return UIColor.black.withAlphaComponent(0.08)  // Slightly stronger shadow for light mode
            }
        })
    }

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
    /// Applies fintech card styling with proper contrast - matches Home screen style
    func fintechCardStyle() -> some View {
        self
            .padding()
            .background(FintechColors.cardBackground)
            .cornerRadius(12)
            .shadow(color: FintechColors.shadow, radius: 2, x: 0, y: 1)
    }

    /// Applies fintech section background
    func fintechSectionBackground() -> some View {
        self
            .background(FintechColors.cardBackground)
            .cornerRadius(12)
    }

    /// Applies main app background for screens
    func fintechScreenBackground() -> some View {
        self
            .background(FintechColors.appBackground)
    }

    /// Applies settings row styling with proper contrast
    func fintechSettingsRowStyle() -> some View {
        self
            .padding()
            .background(FintechColors.cardBackground)
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
