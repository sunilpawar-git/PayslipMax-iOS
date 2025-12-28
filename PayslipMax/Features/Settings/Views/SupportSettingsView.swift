import SwiftUI
import SwiftData

struct SupportSettingsView: View {
    @StateObject private var viewModel: SettingsViewModel
    @Environment(\.modelContext) private var modelContext
    @State private var showingFAQSheet = false
    @State private var showingPrivacyInfo = false
    @State private var showingClearDataConfirmation = false

    init(viewModel: SettingsViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        SettingsSection(title: "SUPPORT") {
            VStack(spacing: 0) {
                SettingsRow(
                    icon: "shield.fill",
                    iconColor: FintechColors.primaryBlue,
                    title: "Privacy & Security",
                    subtitle: "How your data is protected",
                    action: {
                        showingPrivacyInfo = true
                    }
                )

                FintechDivider()

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

                FintechDivider()

                // Clear All Data
                SettingsRow(
                    icon: "trash.fill",
                    iconColor: FintechColors.dangerRed,
                    title: "Clear All Data",
                    subtitle: "Remove all payslips & relevant data",
                    action: {
                        showingClearDataConfirmation = true
                    }
                )
            }
        }
        .sheet(isPresented: $showingFAQSheet) {
            FAQView()
        }
        .sheet(isPresented: $showingPrivacyInfo) {
            LLMPrivacyInfoView()
        }
        .confirmationDialog(
            "Clear All Data",
            isPresented: $showingClearDataConfirmation,
            titleVisibility: .visible
        ) {
            Button("Yes", role: .destructive) {
                viewModel.clearAllData(context: modelContext)
            }
            Button("No", role: .cancel) { }
        } message: {
            Text("Are you sure you want to delete all payslips & relevant data from the app?")
        }
    }
}

struct FAQView: View {
    @Environment(\.presentationMode) private var presentationMode
    @State private var selectedQuestion: String?

    // swiftlint:disable line_length
    let faqs = [
        // EXISTING FAQs (Unchanged)
        "How do I add a new payslip?": "You can add a new payslip by tapping the '+' button on the Home screen and selecting one of the options: Upload PDF, Scan Document, or Enter Manually.",
        "Is my data secure?": "Yes, all sensitive data is encrypted using industry-standard encryption methods. Your data is stored locally on your device by default. If you upgrade to Premium, your data is additionally end-to-end encrypted in the cloud.",
        "Why should I upgrade to Premium?": "Premium gives you secure cloud storage, automatic backups, access across multiple devices, and advanced financial analytics to better track your earnings and deductions over time.",
        "How accurate is the PDF parsing?": "Our PDF parser has been trained on standard Indian Armed Forces payslip formats with high accuracy. However, variations may occur. You can always edit parsed data and train the system to improve accuracy over time.",
        "Can I use Face ID/Touch ID to secure the app?": "Yes, you can enable biometric authentication in Settings > Preferences > Use Biometric Authentication.",
        "How do I edit my personal details?": "Go to Settings > Personal Details to update your name, account number and PAN number. These details will be used to autofill when creating new payslips.",
        "What happens to my data if I uninstall the app?": "Free users: Your data is stored locally and will be lost if you uninstall the app. Premium users: Your data is securely stored in the cloud and will be available when you reinstall the app and sign in.",
        "How do I export my payslip data?": "On any payslip detail view, tap the share icon to export as PDF or text. You can also backup all your data if you're a Premium subscriber.",

        // NEW: Financial Literacy FAQs
        "How does PayslipMax help me understand my salary?": """
        PayslipMax breaks down your payslip into clear categories:

        📈 **Earnings**: Basic Pay, DA, MSP, allowances
        📉 **Deductions**: DSOP, AGIF, Income Tax, loans
        💰 **Net Pay**: What you actually receive

        Our X-Ray Salary feature shows month-to-month changes, helping you spot unexpected deductions, missing allowances, or tax variations.
        """,

        "What's the difference between Upload and Scan?": """
        **Upload (PDF)**: Best for digital payslips from SPARSH/PCDA portal
        • Faster processing
        • Uses text extraction + AI verification

        **Scan (Photo)**: Best for printed payslips or screenshots
        • Works with any format (Officer/JCO/OR)
        • You crop to remove personal info before AI processing

        Choose Upload for digital PDFs, Scan for physical payslips or screenshots.
        """,

        "Which option should I use for JCO/OR payslips?": """
        For JCO/OR payslips (JCOs, Hawaldars, Naiks, Sepoys), we recommend:

        1. **Scan** option for best results
        2. Select "JCO/OR" in the parsing preference (if available)
        3. Crop to show only the financial data portion

        Our AI vision is specially optimized for tabulated JCO/OR formats and can handle Hindi/English mixed content.
        """,

        "Is my data secure when using AI parsing?": """
        Yes! Your privacy is our priority:

        🔒 **Upload**: Names, accounts, PAN are redacted BEFORE AI sees them
        🔒 **Scan**: YOU control what's in the cropped image
        🔒 **No Storage**: AI provider doesn't store your data
        🔒 **Encryption**: All data is encrypted in transit

        We use selective redaction and mandatory cropping to protect your personal information.
        """,

        "How can I track my financial health over time?": """
        PayslipMax helps you become financially aware:

        📊 **Monthly Trends**: See how your salary changes
        🔍 **X-Ray Salary**: Compare any two months side-by-side
        ⚠️ **Alerts**: Get notified of unusual changes (Premium)
        📈 **Tax Planning**: Track annual tax deductions

        Understanding your payslip is the first step to financial literacy!
        """,

        "What if parsing gives incorrect results?": """
        If results don't look right:

        1. Try the other input method (Upload vs Scan)
        2. For scans, ensure good lighting and clear photo
        3. Switch between Officer/JCO-OR preferences if available
        4. You can always edit values manually after parsing

        Each correction helps improve the system's accuracy over time!
        """
    ]
    // swiftlint:enable line_length

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
