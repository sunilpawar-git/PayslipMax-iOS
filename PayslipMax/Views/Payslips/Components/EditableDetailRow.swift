import SwiftUI

/// A reusable component for displaying an editable row with a title and value.
struct EditableDetailRow: View {
    let title: String
    @Binding var value: String
    let placeholder: String
    
    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(.secondary)
            Spacer()
            TextField(placeholder, text: $value)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .frame(width: 120)
        }
    }
}

#Preview {
    EditableDetailRow(
        title: "Basic Pay",
        value: .constant("50000"),
        placeholder: "50000.00"
    )
} 