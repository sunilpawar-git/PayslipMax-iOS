import SwiftUI

/// A view that displays earnings and deductions categorized by type
struct CategorizedPayItemsView: View {
    let earnings: [String: Double]
    let deductions: [String: Double]
    
    init(earnings: [String: Double], deductions: [String: Double]) {
        self.earnings = earnings
        self.deductions = deductions
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Earnings Section
            VStack(alignment: .leading, spacing: 10) {
                Text("EARNINGS")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                // Categorized earnings
                ForEach(categorizedEarnings.keys.sorted(), id: \.self) { category in
                    if let items = categorizedEarnings[category], !items.isEmpty {
                        CategorySection(
                            title: category,
                            items: items,
                            color: .green
                        )
                    }
                }
                
                // Total earnings
                HStack {
                    Text("Total Earnings")
                        .font(.headline)
                    Spacer()
                    Text("₹\(formatCurrency(totalEarnings))")
                        .font(.headline)
                }
                .padding(.top, 8)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(10)
            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
            
            // Deductions Section
            VStack(alignment: .leading, spacing: 10) {
                Text("DEDUCTIONS")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                // Categorized deductions
                ForEach(categorizedDeductions.keys.sorted(), id: \.self) { category in
                    if let items = categorizedDeductions[category], !items.isEmpty {
                        CategorySection(
                            title: category,
                            items: items,
                            color: .red
                        )
                    }
                }
                
                // Total deductions
                HStack {
                    Text("Total Deductions")
                        .font(.headline)
                    Spacer()
                    Text("₹\(formatCurrency(totalDeductions))")
                        .font(.headline)
                }
                .padding(.top, 8)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(10)
            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
            
            // Net Pay Section
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("NET PAY")
                        .font(.headline)
                    Spacer()
                    Text("₹\(formatCurrency(totalEarnings - totalDeductions))")
                        .font(.headline)
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(10)
            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        }
    }
    
    // MARK: - Computed Properties
    
    /// Total earnings amount
    private var totalEarnings: Double {
        earnings.values.reduce(0, +)
    }
    
    /// Total deductions amount
    private var totalDeductions: Double {
        deductions.values.reduce(0, +)
    }
    
    /// Earnings categorized by type
    private var categorizedEarnings: [String: [PayItem]] {
        categorizePayItems(earnings)
    }
    
    /// Deductions categorized by type
    private var categorizedDeductions: [String: [PayItem]] {
        categorizePayItems(deductions)
    }
    
    // MARK: - Helper Methods
    
    /// Categorizes pay items by type
    private func categorizePayItems(_ items: [String: Double]) -> [String: [PayItem]] {
        var categorized: [String: [PayItem]] = [:]
        
        for (name, amount) in items {
            let category = determineCategory(for: name)
            var categoryItems = categorized[category] ?? []
            categoryItems.append(PayItem(name: name, amount: amount))
            categorized[category] = categoryItems
        }
        
        // Sort items within each category by amount (descending)
        for (category, items) in categorized {
            categorized[category] = items.sorted { $0.amount > $1.amount }
        }
        
        return categorized
    }
    
    /// Determines the category for a pay item based on its name
    private func determineCategory(for itemName: String) -> String {
        let normalizedName = itemName.lowercased()
        
        // Standard earnings components
        if itemName == "BPAY" || normalizedName.contains("basic") || normalizedName == "pay" || normalizedName == "salary" {
            return "Basic Pay"
        }
        
        if itemName == "DA" || normalizedName.contains("dearness") {
            return "Dearness Allowance"
        }
        
        // Commented out HRA categorization as it's now in blacklisted terms
        // if itemName == "HRA" || normalizedName.contains("house rent") || normalizedName.contains("housing") {
        //     return "Housing Allowance"
        // }
        
        if itemName == "MSP" || normalizedName.contains("military service") {
            return "Military Service Pay"
        }
        
        // Standard deductions components
        if itemName == "DSOP" || normalizedName.contains("provident") || normalizedName.contains("fund") {
            return "Provident Fund"
        }
        
        if itemName == "AGIF" || normalizedName.contains("insurance") {
            return "Insurance"
        }
        
        if itemName == "ITAX" || normalizedName.contains("tax") || normalizedName.contains("tds") {
            return "Tax Deductions"
        }
        
        // Allowances
        if normalizedName.contains("allowance") || 
           normalizedName.contains("ta") ||
           itemName == "TPTA" ||
           itemName == "TPTADA" {
            return "Allowances"
        }
        
        // Special Pay
        if normalizedName.contains("special") || 
           normalizedName.contains("bonus") || 
           normalizedName.contains("incentive") {
            return "Special Pay"
        }
        
        // Retirement Contributions
        if normalizedName.contains("pension") || 
           normalizedName.contains("pf") {
            return "Retirement Contributions"
        }
        
        // Loans and Advances
        if normalizedName.contains("loan") || 
           normalizedName.contains("advance") || 
           normalizedName.contains("recovery") ||
           itemName == "FUR" ||
           itemName == "LF" {
            return "Loans & Advances"
        }
        
        // Accommodation
        if normalizedName.contains("accommodation") || 
           normalizedName.contains("quarters") || 
           normalizedName.contains("rent") {
            return "Accommodation"
        }
        
        // Utilities
        if normalizedName.contains("electricity") || 
           normalizedName.contains("water") || 
           normalizedName.contains("utility") || 
           normalizedName.contains("gas") ||
           itemName == "WATER" {
            return "Utilities"
        }
        
        // Mess and Food
        if normalizedName.contains("mess") || 
           normalizedName.contains("food") || 
           normalizedName.contains("ration") {
            return "Mess & Food"
        }
        
        // Default category
        return "Other"
    }
    
    /// Formats a currency value
    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        formatter.minimumFractionDigits = 0
        formatter.usesGroupingSeparator = true
        
        if let formattedValue = formatter.string(from: NSNumber(value: value)) {
            return formattedValue
        }
        
        return String(format: "%.0f", value)
    }
}

// MARK: - Supporting Types and Views

/// Represents a pay item with a name and amount
struct PayItem: Identifiable {
    let id = UUID()
    let name: String
    let amount: Double
}

/// A section that displays a category of pay items
struct CategorySection: View {
    let title: String
    let items: [PayItem]
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
            
            ForEach(items) { item in
                HStack {
                    Text(item.name)
                        .font(.subheadline)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    Text("₹\(formatCurrency(item.amount))")
                        .font(.subheadline)
                        .foregroundColor(.primary)
                        .frame(alignment: .trailing)
                }
            }
            
            Divider()
                .padding(.vertical, 4)
        }
    }
    
    /// Maximum amount in the items list
    private var maxAmount: Double {
        items.map { $0.amount }.max() ?? 1.0
    }
    
    /// Formats a currency value
    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        formatter.minimumFractionDigits = 0
        formatter.usesGroupingSeparator = true
        
        if let formattedValue = formatter.string(from: NSNumber(value: value)) {
            return formattedValue
        }
        
        return String(format: "%.0f", value)
    }
}

// MARK: - Preview

struct CategorizedPayItemsView_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            CategorizedPayItemsView(
                earnings: [
                    "Basic Pay": 50000,
                    "Dearness Allowance": 10000,
                    "House Rent Allowance": 15000,
                    "Transport Allowance": 3000,
                    "Special Duty Allowance": 5000
                ],
                deductions: [
                    "Income Tax": 8000,
                    "DSOP Fund": 5000,
                    "AGIF": 2000,
                    "Mess Bill": 3000,
                    "Electricity Charges": 1500,
                    "Water Charges": 500
                ]
            )
            .padding()
        }
        .previewLayout(.sizeThatFits)
    }
} 