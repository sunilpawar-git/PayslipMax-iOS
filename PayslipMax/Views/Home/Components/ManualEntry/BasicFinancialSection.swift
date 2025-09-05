import SwiftUI

/// Basic financial information section for manual payslip entry
struct BasicFinancialSection: View {
    @Binding var credits: String
    @Binding var debits: String
    @Binding var tax: String
    @Binding var dsop: String
    @Binding var basicPay: String
    @Binding var dearnessPay: String
    @Binding var militaryServicePay: String
    
    var body: some View {
        Section {
            CurrencyTextField("Credits (Total Earnings)", value: $credits)
                .accessibilityIdentifier("credits_field")
            
            CurrencyTextField("Debits (Total Deductions)", value: $debits)
                .accessibilityIdentifier("debits_field")
            
            CurrencyTextField("Income Tax", value: $tax)
                .accessibilityIdentifier("tax_field")
            
            CurrencyTextField("DSOP Amount", value: $dsop)
                .accessibilityIdentifier("dsop_field")
            
            CurrencyTextField("Basic Pay", value: $basicPay)
                .accessibilityIdentifier("basic_pay_field")
            
            CurrencyTextField("Dearness Allowance", value: $dearnessPay)
                .accessibilityIdentifier("dearness_pay_field")
            
            CurrencyTextField("Military Service Pay", value: $militaryServicePay)
                .accessibilityIdentifier("military_service_pay_field")
                
        } header: {
            Text("Basic Financial Information")
                .font(.headline)
                .foregroundColor(.primary)
        } footer: {
            Text("Enter the main financial amounts from your payslip")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

/// Currency-specific text field component
struct CurrencyTextField: View {
    let title: String
    @Binding var value: String
    
    init(_ title: String, value: Binding<String>) {
        self.title = title
        self._value = value
    }
    
    var body: some View {
        HStack {
            Text("₹")
                .foregroundColor(.secondary)
                .font(.system(.body, design: .monospaced))
            
            TextField(title, text: $value)
                .keyboardType(.decimalPad)
                .autocorrectionDisabled(true)
        }
        .textFieldStyle(.roundedBorder)
    }
}

#Preview {
    Form {
        BasicFinancialSection(
            credits: .constant("75000"),
            debits: .constant("15000"),
            tax: .constant("8000"),
            dsop: .constant("5000"),
            basicPay: .constant("50000"),
            dearnessPay: .constant("15000"),
            militaryServicePay: .constant("10000")
        )
    }
}
