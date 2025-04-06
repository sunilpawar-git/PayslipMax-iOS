import SwiftUI

struct ContactSupportView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var subject = ""
    @State private var message = ""
    @State private var includeDeviceInfo = true
    @State private var showingEmailSuccess = false
    
    private let supportEmail = "support@payslipmax.com"
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header section
                VStack(alignment: .leading, spacing: 8) {
                    Text("Contact Support")
                        .font(.title2)
                        .bold()
                    
                    Text("Need help with PayslipMax? Our support team is ready to assist you.")
                        .foregroundColor(.secondary)
                }
                .padding(.bottom)
                
                // Subject field
                VStack(alignment: .leading, spacing: 8) {
                    Text("Subject")
                        .font(.headline)
                    
                    TextField("Brief description of your issue", text: $subject)
                        .padding()
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(8)
                }
                
                // Message field
                VStack(alignment: .leading, spacing: 8) {
                    Text("Message")
                        .font(.headline)
                    
                    ZStack(alignment: .topLeading) {
                        if message.isEmpty {
                            Text("Please describe your issue in detail...")
                                .foregroundColor(Color.gray.opacity(0.7))
                                .padding(.top, 8)
                                .padding(.leading, 5)
                        }
                        
                        TextEditor(text: $message)
                            .padding(4)
                            .frame(minHeight: 150)
                            .background(Color(UIColor.secondarySystemBackground))
                    }
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(8)
                }
                
                // Device info toggle
                Toggle(isOn: $includeDeviceInfo) {
                    VStack(alignment: .leading) {
                        Text("Include Device Information")
                            .font(.headline)
                        
                        Text("This helps us better understand your issue")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.vertical, 8)
                
                // Send button
                Button {
                    sendEmail()
                } label: {
                    Text("Send Message")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(10)
                }
                .disabled(subject.isEmpty || message.isEmpty)
                .opacity((subject.isEmpty || message.isEmpty) ? 0.6 : 1.0)
                
                // Alternative contact info
                VStack(alignment: .leading, spacing: 4) {
                    Text("Alternative Contact Methods")
                        .font(.headline)
                        .padding(.top)
                    
                    HStack {
                        Image(systemName: "envelope")
                            .foregroundColor(.blue)
                        
                        Text(supportEmail)
                            .foregroundColor(.blue)
                            .onTapGesture {
                                if let url = URL(string: "mailto:\(supportEmail)") {
                                    UIApplication.shared.open(url)
                                }
                            }
                    }
                    .padding(.top, 4)
                    
                    HStack {
                        Image(systemName: "phone")
                            .foregroundColor(.blue)
                        
                        Text("+91 9876543210")
                            .foregroundColor(.blue)
                            .onTapGesture {
                                if let url = URL(string: "tel:+919876543210") {
                                    UIApplication.shared.open(url)
                                }
                            }
                    }
                    .padding(.top, 2)
                }
                .padding(.top)
            }
            .padding()
        }
        .navigationTitle("Contact Support")
        .alert("Message Sent", isPresented: $showingEmailSuccess) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text("Thank you for contacting us. We'll respond to your query as soon as possible.")
        }
    }
    
    private func sendEmail() {
        // In a real app, this would handle the email sending logic
        // For now, we'll just show a success message
        
        // Simulate network delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            showingEmailSuccess = true
        }
    }
    
    private func getDeviceInfo() -> String {
        let device = UIDevice.current
        return """
        Device: \(device.model)
        iOS Version: \(device.systemVersion)
        App Version: \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown")
        """
    }
}

struct ContactSupportView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ContactSupportView()
        }
    }
} 