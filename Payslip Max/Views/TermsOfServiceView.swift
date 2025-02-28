import SwiftUI

/// View for displaying the terms of service
struct TermsOfServiceView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Terms of Service")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.bottom, 8)
                
                Text("Last Updated: \(Date().formatted(date: .long, time: .omitted))")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.bottom, 16)
                
                Group {
                    Text("1. Acceptance of Terms")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("By accessing or using Payslip Max, you agree to be bound by these Terms of Service. If you do not agree to these terms, please do not use the application.")
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                Group {
                    Text("2. Description of Service")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .padding(.top, 8)
                    
                    Text("Payslip Max provides tools for managing, analyzing, and storing payslip information. The application offers both free and premium features, with premium features available through subscription.")
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                Group {
                    Text("3. User Accounts")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .padding(.top, 8)
                    
                    Text("To access certain features of the application, you may be required to create an account. You are responsible for maintaining the confidentiality of your account information and for all activities that occur under your account.")
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                Group {
                    Text("4. Premium Features")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .padding(.top, 8)
                    
                    Text("Premium features are available through subscription. Subscription fees are charged in advance and are non-refundable. You can cancel your subscription at any time, but no refunds will be provided for any unused portion of the subscription period.")
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                Group {
                    Text("5. User Data")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .padding(.top, 8)
                    
                    Text("You retain all rights to your data. We will not access, use, or share your data except as necessary to provide the service or as required by law. Please refer to our Privacy Policy for more information on how we handle your data.")
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                Group {
                    Text("6. Limitation of Liability")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .padding(.top, 8)
                    
                    Text("To the maximum extent permitted by law, we shall not be liable for any indirect, incidental, special, consequential, or punitive damages, or any loss of profits or revenues, whether incurred directly or indirectly, or any loss of data, use, goodwill, or other intangible losses, resulting from your use of the application.")
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                Group {
                    Text("7. Changes to Terms")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .padding(.top, 8)
                    
                    Text("We reserve the right to modify these terms at any time. We will provide notice of significant changes by updating the date at the top of these terms and by providing notice through the application. Your continued use of the application after such changes constitutes your acceptance of the new terms.")
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                Group {
                    Text("8. Contact Us")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .padding(.top, 8)
                    
                    Text("If you have any questions about these Terms of Service, please contact us at terms@payslipmax.com")
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding()
        }
        .navigationTitle("Terms of Service")
        #if !os(macOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }
}

#Preview {
    NavigationStack {
        TermsOfServiceView()
    }
} 