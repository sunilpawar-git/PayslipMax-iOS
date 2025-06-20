import SwiftUI

struct SupportSettingsView: View {
    @StateObject private var viewModel: SettingsViewModel
    @State private var showingFAQSheet = false
    
    init(viewModel: SettingsViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        SettingsSection(title: "SUPPORT") {
            VStack(spacing: 0) {
                SettingsRow(
                    icon: "questionmark.circle.fill",
                    iconColor: FintechColors.warningAmber,
                    title: "FAQ",
                    subtitle: "Frequently asked questions",
                    action: {
                        showingFAQSheet = true
                    }
                )
                
                FintechDivider()
                
                SettingsRow(
                    icon: "envelope.fill",
                    iconColor: FintechColors.chartSecondary,
                    title: "Contact Support",
                    subtitle: "Get help with your account",
                    action: {
                        viewModel.contactSupport()
                    }
                )
            }
        }
        .sheet(isPresented: $showingFAQSheet) {
            FAQView()
        }
    }
}

struct FAQView: View {
    @Environment(\.presentationMode) private var presentationMode
    @State private var selectedQuestion: String?
    
    let faqs = [
        "How do I add a new payslip?": "You can add a new payslip by tapping the '+' button on the Home screen and selecting one of the options: Upload PDF, Scan Document, or Enter Manually.",
        "Is my data secure?": "Yes, all sensitive data is encrypted using industry-standard encryption methods. Your data is stored locally on your device by default. If you upgrade to Premium, your data is additionally end-to-end encrypted in the cloud.",
        "Why should I upgrade to Premium?": "Premium gives you secure cloud storage, automatic backups, access across multiple devices, and advanced financial analytics to better track your earnings and deductions over time.",
        "How accurate is the PDF parsing?": "Our PDF parser has been trained on standard Indian Armed Forces payslip formats with high accuracy. However, variations may occur. You can always edit parsed data and train the system to improve accuracy over time.",
        "Can I use Face ID/Touch ID to secure the app?": "Yes, you can enable biometric authentication in Settings > Preferences > Use Biometric Authentication.",
        "How do I edit my personal details?": "Go to Settings > Personal Details to update your name, account number and PAN number. These details will be used to autofill when creating new payslips.",
        "What happens to my data if I uninstall the app?": "Free users: Your data is stored locally and will be lost if you uninstall the app. Premium users: Your data is securely stored in the cloud and will be available when you reinstall the app and sign in.",
        "How do I export my payslip data?": "On any payslip detail view, tap the share icon to export as PDF or text. You can also backup all your data if you're a Premium subscriber."
    ]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    ForEach(Array(faqs.keys.sorted()), id: \.self) { question in
                        FAQItem(
                            question: question,
                            answer: faqs[question] ?? "",
                            isExpanded: selectedQuestion == question,
                            onTap: {
                                if selectedQuestion == question {
                                    selectedQuestion = nil
                                } else {
                                    selectedQuestion = question
                                }
                            }
                        )
                    }
                }
                .padding()
            }
            .navigationTitle("FAQs")
            .navigationBarItems(trailing: Button("Done") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}

struct FAQItem: View {
    let question: String
    let answer: String
    let isExpanded: Bool
    let onTap: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button(action: onTap) {
                HStack {
                    Text(question)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                    
                    Spacer()
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.blue)
                }
            }
            
            if isExpanded {
                Text(answer)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .padding(.top, 4)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(8)
    }
}

#Preview {
    SupportSettingsView(viewModel: DIContainer.shared.makeSettingsViewModel())
} 