import Foundation

/// Investment tips data that can be used throughout the app
struct InvestmentTipsData {
    /// A collection of investment tips for users
    static let tips = [
        "Start investing early to benefit from compound interest over time",
        "Maintain an emergency fund of 3-6 months of expenses before investing",
        "Diversify your investments across different asset classes to reduce risk",
        "Consider tax-advantaged retirement accounts for long-term growth",
        "Regularly review and rebalance your investment portfolio",
        "Dollar-cost averaging can help reduce the impact of market volatility",
        "Keep investment costs low by choosing funds with minimal expense ratios",
        "Understand your risk tolerance before making investment decisions",
        "Avoid emotional buying or selling based on short-term market movements",
        "Consider seeking professional financial advice for complex investments"
    ]
    
    /// Returns a subset of tips
    static func getTips(count: Int = 5) -> [String] {
        return Array(tips.prefix(count))
    }
} 