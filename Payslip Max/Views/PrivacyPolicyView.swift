import SwiftUI

/// View for displaying the privacy policy
struct PrivacyPolicyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Privacy Policy")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.bottom, 8)
                
                Text("Last Updated: \(Date().formatted(date: .long, time: .omitted))")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.bottom, 16)
                
                Group {
                    Text("Introduction")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("Payslip Max respects your privacy and is committed to protecting your personal data. This privacy policy will inform you about how we look after your personal data when you use our application and tell you about your privacy rights and how the law protects you.")
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                Group {
                    Text("Data We Collect")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .padding(.top, 8)
                    
                    Text("We collect and process your payslip information that you provide to us. This includes salary details, tax information, allowances, deductions, and other employment-related data. All data is stored locally on your device unless you explicitly enable cloud backup features.")
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                Group {
                    Text("How We Use Your Data")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .padding(.top, 8)
                    
                    Text("We use your data to provide the core functionality of the app, including payslip management, insights, and reporting. If you enable premium features, we may use your data to provide cloud backup and synchronization services.")
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                Group {
                    Text("Data Security")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .padding(.top, 8)
                    
                    Text("We have implemented appropriate security measures to prevent your personal data from being accidentally lost, used, or accessed in an unauthorized way. We limit access to your personal data to those employees, agents, contractors, and other third parties who have a business need to know.")
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                Group {
                    Text("Your Legal Rights")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .padding(.top, 8)
                    
                    Text("Under certain circumstances, you have rights under data protection laws in relation to your personal data, including the right to access, correct, erase, restrict, transfer, or object to the processing of your personal data.")
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                Group {
                    Text("Contact Us")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .padding(.top, 8)
                    
                    Text("If you have any questions about this privacy policy or our privacy practices, please contact us at privacy@payslipmax.com")
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding()
        }
        .navigationTitle("Privacy Policy")
        #if !os(macOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }
}

#Preview {
    NavigationStack {
        PrivacyPolicyView()
    }
} 