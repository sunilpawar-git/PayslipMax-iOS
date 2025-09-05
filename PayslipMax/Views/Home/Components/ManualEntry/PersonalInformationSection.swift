import SwiftUI

/// Personal information section for manual payslip entry
struct PersonalInformationSection: View {
    @Binding var name: String
    @Binding var month: String
    @Binding var year: Int
    @Binding var accountNumber: String
    @Binding var panNumber: String
    @Binding var rank: String
    @Binding var serviceNumber: String
    @Binding var postedTo: String
    
    var body: some View {
        Section {
            TextField("Full Name", text: $name)
                .autocorrectionDisabled(true)
                .accessibilityIdentifier("name_field")
                .textFieldStyle(.roundedBorder)
                .submitLabel(.next)
            
            TextField("Month (e.g., January)", text: $month)
                .autocorrectionDisabled(true)
                .accessibilityIdentifier("month_field")
                .textFieldStyle(.roundedBorder)
                .submitLabel(.next)
            
            Picker("Year", selection: $year) {
                ForEach((Calendar.current.component(.year, from: Date()) - 5)...(Calendar.current.component(.year, from: Date())), id: \.self) { year in
                    Text(String(year)).tag(year)
                }
            }
            .pickerStyle(.menu)
            .accessibilityIdentifier("year_field")
            
            TextField("Account Number", text: $accountNumber)
                .autocorrectionDisabled(true)
                .keyboardType(.numberPad)
                .accessibilityIdentifier("account_number_field")
                .textFieldStyle(.roundedBorder)
                .submitLabel(.next)
            
            TextField("PAN Number", text: $panNumber)
                .autocorrectionDisabled(true)
                .textInputAutocapitalization(.characters)
                .accessibilityIdentifier("pan_number_field")
                .textFieldStyle(.roundedBorder)
                .submitLabel(.next)
            
            TextField("Rank (Optional)", text: $rank)
                .autocorrectionDisabled(true)
                .accessibilityIdentifier("rank_field")
                .textFieldStyle(.roundedBorder)
                .submitLabel(.next)
            
            TextField("Service Number (Optional)", text: $serviceNumber)
                .autocorrectionDisabled(true)
                .accessibilityIdentifier("service_number_field")
                .textFieldStyle(.roundedBorder)
                .submitLabel(.next)
            
            TextField("Posted To (Optional)", text: $postedTo)
                .autocorrectionDisabled(true)
                .accessibilityIdentifier("posted_to_field")
                .textFieldStyle(.roundedBorder)
                .submitLabel(.next)
                
        } header: {
            Text("Personal Information")
                .font(.headline)
                .foregroundColor(.primary)
        }
    }
}

#Preview {
    Form {
        PersonalInformationSection(
            name: .constant("John Doe"),
            month: .constant("January"),
            year: .constant(2024),
            accountNumber: .constant("12345678901"),
            panNumber: .constant("ABCDE1234F"),
            rank: .constant("Captain"),
            serviceNumber: .constant("SER123"),
            postedTo: .constant("Delhi")
        )
    }
}
