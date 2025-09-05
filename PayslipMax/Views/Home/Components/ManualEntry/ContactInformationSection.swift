import SwiftUI

/// Contact information section for manual payslip entry
struct ContactInformationSection: View {
    @Binding var contactPhone: String
    @Binding var contactEmail: String
    @Binding var contactWebsite: String
    
    var body: some View {
        Section {
            TextField("Phone Number", text: $contactPhone)
                .keyboardType(.phonePad)
                .autocorrectionDisabled(true)
                .accessibilityIdentifier("contact_phone_field")
                .textFieldStyle(.roundedBorder)
            
            TextField("Email Address", text: $contactEmail)
                .keyboardType(.emailAddress)
                .autocorrectionDisabled(true)
                .autocapitalization(.none)
                .accessibilityIdentifier("contact_email_field")
                .textFieldStyle(.roundedBorder)
            
            TextField("Website URL", text: $contactWebsite)
                .keyboardType(.URL)
                .autocorrectionDisabled(true)
                .autocapitalization(.none)
                .accessibilityIdentifier("contact_website_field")
                .textFieldStyle(.roundedBorder)
            
        } header: {
            Text("Contact Information")
                .font(.headline)
                .foregroundColor(.primary)
        } footer: {
            Text("Optional contact details for this payslip")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    Form {
        ContactInformationSection(
            contactPhone: .constant("+91 9876543210"),
            contactEmail: .constant("john.doe@example.com"),
            contactWebsite: .constant("https://example.com")
        )
    }
}
