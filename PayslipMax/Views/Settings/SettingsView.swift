import SwiftUI
import SwiftData

struct SettingsView: View {
    @StateObject private var viewModel: SettingsViewModel
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) var colorScheme
    
    @State private var showingBiometricSetup = false
    @State private var showingFAQSheet = false
    @State private var showingSubscriptionSheet = false
    @State private var showingBackupSheet = false
    @State private var showingDebugMenu = false

    @State private var showingWebUploadSheet = false
    
    init(viewModel: SettingsViewModel? = nil) {
        // Use provided viewModel or create one from DIContainer
        let model = viewModel ?? DIContainer.shared.makeSettingsViewModel()
        self._viewModel = StateObject(wrappedValue: model)
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // MARK: - Subscription Section
                    SettingsSection(title: "SUBSCRIPTION") {
                        SettingsRow(
                            icon: "crown.fill",
                            iconColor: FintechColors.warningAmber,
                            title: "Go Pro - ₹99/Year",
                            subtitle: "Cloud backup & cross-device sync",
                            action: {
                                showingSubscriptionSheet = true
                            }
                        )
                    }
                    
                    // MARK: - Cloud Backup Section (Pro Feature)
                    SettingsSection(title: "CLOUD BACKUP") {
                        SettingsRow(
                            icon: "icloud.and.arrow.up",
                            iconColor: FintechColors.primaryBlue,
                            title: "Backup & Restore",
                            subtitle: "Export to any cloud service or import from backup",
                            action: {
                                showingBackupSheet = true
                            }
                        )
                    }
                    
                    // MARK: - Preferences Section
                    SettingsSection(title: "PREFERENCES") {
                        VStack(spacing: 0) {
                            // Custom biometric authentication row - optimized layout
                            HStack(spacing: 12) {
                                // Icon background
                                ZStack {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(FintechColors.successGreen.opacity(0.15))
                                        .frame(width: 32, height: 32)
                                    
                                    Image(systemName: "faceid")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(FintechColors.successGreen)
                                }
                                
                                // Simplified title
                                Text("Face/Touch ID")
                                    .font(.body)
                                    .fontWeight(.medium)
                                    .foregroundColor(FintechColors.textPrimary)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.8)
                                
                                Spacer()
                                
                                Toggle("", isOn: $viewModel.useBiometricAuth)
                                    .onChange(of: viewModel.useBiometricAuth) { _, newValue in
                                        viewModel.updateBiometricPreference(enabled: newValue)
                                    }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            
                            FintechDivider()
                            
                            // Theme Picker Row - Inline dropdown instead of sheet
                            HStack(spacing: 16) {
                                // Icon background
                                ZStack {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(FintechColors.chartSecondary.opacity(0.15))
                                        .frame(width: 32, height: 32)
                                    
                                    Image(systemName: "paintpalette.fill")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(FintechColors.chartSecondary)
                                }
                                
                                // Content
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Theme")
                                        .font(.body)
                                        .fontWeight(.medium)
                                        .foregroundColor(FintechColors.textPrimary)
                                }
                                
                                Spacer()
                                
                                // Inline Theme Picker
                                Picker("Theme", selection: $viewModel.appTheme) {
                                    ForEach(AppTheme.allCases, id: \.self) { theme in
                                        Text(theme.rawValue).tag(theme)
                                    }
                                }
                                .pickerStyle(MenuPickerStyle())
                                .onChange(of: viewModel.appTheme) { oldValue, newValue in
                                    // Theme is automatically applied via ThemeManager
                                    viewModel.updateAppearancePreference(theme: newValue)
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                        }
                    }
                    
                    // MARK: - Web Upload Section
                    SettingsSection(title: "WEB UPLOAD") {
                        SettingsRow(
                            icon: "icloud.and.arrow.down",
                            iconColor: FintechColors.chartSecondary,
                            title: "Manage Web Uploads",
                            subtitle: "PDFs uploaded from PayslipMax.com",
                            action: {
                                showingWebUploadSheet = true
                            }
                        )
                    }
                    
                    // MARK: - Data Management Section
                    SettingsSection(title: "DATA MANAGEMENT") {
                        SettingsRow(
                            icon: "trash.fill",
                            iconColor: FintechColors.dangerRed,
                            title: "Clear All Data",
                            subtitle: "Remove all payslips",
                            action: {
                                viewModel.clearAllData(context: modelContext)
                            }
                        )
                    }
                    
                    // MARK: - Support Section
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
                    
                    // MARK: - About Section
                    SettingsSection(title: "ABOUT") {
                        VStack(spacing: 0) {
                            SettingsInfoRow(
                                icon: "info.circle.fill",
                                iconColor: FintechColors.textSecondary,
                                title: "Version",
                                value: "1.0.0"
                            )
                            
                            FintechDivider()
                            
                            SettingsRow(
                                icon: "doc.text.fill",
                                iconColor: FintechColors.textSecondary,
                                title: "Privacy Policy",
                                subtitle: "View our privacy policy",
                                action: {
                                    // Open privacy policy
                                }
                            )
                        }
                    }
                    
                    Spacer(minLength: 60)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 20)
            }
            .background(FintechColors.appBackground)
            .navigationTitle("Settings")
            .sheet(isPresented: $showingSubscriptionSheet) {
                PremiumPaywallView()
            }
            .sheet(isPresented: $showingBackupSheet) {
                BackupViewWrapper()
            }
            .sheet(isPresented: $showingFAQSheet) {
                FAQView()
            }

            .sheet(isPresented: $showingWebUploadSheet) {
                let webUploadViewModel = DIContainer.shared.makeWebUploadViewModel()
                WebUploadListView(viewModel: webUploadViewModel)
            }
            .overlay {
                if viewModel.isLoading {
                    ProgressView()
                        .scaleEffect(1.5)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(FintechColors.textSecondary.opacity(0.1))
                }
            }
        }
        .onAppear {
            // Only load payslips if we need to - this avoids unnecessary data fetching
            if viewModel.payslips.isEmpty && !viewModel.isLoading {
                viewModel.loadPayslips(context: modelContext)
            }
        }
    }
    
    // MARK: - Helper Methods
    
    // Helper methods removed - theme management now handled by ThemeManager
}

// MARK: - Settings Components

struct SettingsSection<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(FintechColors.textSecondary)
                .padding(.horizontal)
            
            content
                .fintechCardStyle()
        }
    }
}

struct SettingsRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String?
    let action: () -> Void
    
    init(icon: String, iconColor: Color, title: String, subtitle: String? = nil, action: @escaping () -> Void) {
        self.icon = icon
        self.iconColor = iconColor
        self.title = title
        self.subtitle = subtitle
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Icon background
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(iconColor.opacity(0.15))
                        .frame(width: 32, height: 32)
                    
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(iconColor)
                }
                
                // Content
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(FintechColors.textPrimary)
                    
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundColor(FintechColors.textSecondary)
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(FintechColors.textSecondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ToggleSettingsRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String?
    @Binding var isOn: Bool
    let onChange: (Bool) -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon background
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 32, height: 32)
                
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(iconColor)
            }
            
            // Content - Fixed text wrapping and truncation
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(FintechColors.textPrimary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.9)
                    .multilineTextAlignment(.leading)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(FintechColors.textSecondary)
                        .lineLimit(2)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            Spacer(minLength: 8)
            
            Toggle("", isOn: $isOn)
                .onChange(of: isOn) { oldValue, newValue in
                    onChange(newValue)
                }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

struct SettingsInfoRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let value: String
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon background
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 32, height: 32)
                
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(iconColor)
            }
            
            // Content
            Text(title)
                .font(.body)
                .fontWeight(.medium)
                .foregroundColor(FintechColors.textPrimary)
            
            Spacer()
            
            Text(value)
                .font(.body)
                .foregroundColor(FintechColors.textSecondary)
        }
        .padding()
    }
}

struct FintechDivider: View {
    var body: some View {
        Rectangle()
            .fill(FintechColors.divider)
            .frame(height: 1)
            .padding(.horizontal)
    }
}

struct PersonalDetailsView: View {
    @Environment(\.presentationMode) private var presentationMode
    @FocusState private var focusedField: FocusField?
    
    @AppStorage("userName") private var userName: String = ""
    @AppStorage("userAccountNumber") private var accountNumber: String = ""
    @AppStorage("userPANNumber") private var panNumber: String = ""
    
    enum FocusField {
        case name, accountNumber, panNumber
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                FintechColors.appBackground
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Personal Information")
                                .font(.headline)
                            
                            VStack(alignment: .leading, spacing: 5) {
                                Text("Name")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                TextField("Enter your name", text: $userName)
                                    .focused($focusedField, equals: .name)
                                    .padding()
                                    .frame(maxWidth: .infinity, minHeight: 44)
                                    .background(Color(UIColor.secondarySystemBackground))
                                    .cornerRadius(8)
                                    .submitLabel(.next)
                                    .onSubmit {
                                        focusedField = .accountNumber
                                    }
                            }
                            
                            VStack(alignment: .leading, spacing: 5) {
                                Text("Account Number")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                TextField("Enter your account number", text: $accountNumber)
                                    .focused($focusedField, equals: .accountNumber)
                                    .keyboardType(.numberPad)
                                    .padding()
                                    .frame(maxWidth: .infinity, minHeight: 44)
                                    .background(Color(UIColor.secondarySystemBackground))
                                    .cornerRadius(8)
                            }
                            
                            VStack(alignment: .leading, spacing: 5) {
                                Text("PAN Number")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                TextField("Enter your PAN number", text: $panNumber)
                                    .focused($focusedField, equals: .panNumber)
                                    .autocapitalization(.allCharacters)
                                    .padding()
                                    .frame(maxWidth: .infinity, minHeight: 44)
                                    .background(Color(UIColor.secondarySystemBackground))
                                    .cornerRadius(8)
                                    .submitLabel(.done)
                                    .onSubmit {
                                        focusedField = nil
                                    }
                            }
                        }
                        .padding()
                        .background(Color(UIColor.systemBackground))
                        .cornerRadius(10)
                        
                        Text("These details will be used to autofill when creating new payslips or when the PDF parser cannot extract this information.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.horizontal)
                    }
                    .padding()
                }
            }
            .navigationTitle("Personal Details")
            .navigationBarItems(trailing: Button("Done") {
                focusedField = nil
                presentationMode.wrappedValue.dismiss()
            })
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        focusedField = nil
                    }
                }
            }
        }
    }
}

struct SubscriptionView: View {
    @Environment(\.presentationMode) private var presentationMode
    @State private var selectedPlan: SubscriptionPlan = .monthly
    
    enum SubscriptionPlan: String, CaseIterable, Identifiable {
        case monthly = "Monthly"
        case yearly = "Yearly"
        
        var id: String { self.rawValue }
        
        var price: String {
            switch self {
            case .monthly: return "₹199/month"
            case .yearly: return "₹1,999/year (Save 16%)"
            }
        }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    VStack(spacing: 12) {
                        Image(systemName: "cloud")
                            .font(.system(size: 60))
                            .foregroundColor(.blue)
                        
                        Text("PayslipMax Premium")
                            .font(.title)
                            .fontWeight(.bold)
                            .lineLimit(1)
                            .fixedSize(horizontal: false, vertical: true)
                        
                        Text("Secure cloud storage for your payslips")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 30)
                    
                    // Features
                    VStack(alignment: .leading, spacing: 15) {
                        FeatureRow(icon: "cloud.fill", title: "Cloud Storage", description: "Access your payslips from any device")
                        FeatureRow(icon: "arrow.clockwise.icloud", title: "Automatic Backups", description: "Never lose your payslip data")
                        FeatureRow(icon: "lock.shield.fill", title: "Enhanced Security", description: "End-to-end encrypted storage")
                        FeatureRow(icon: "chart.pie.fill", title: "Advanced Analytics", description: "Get deeper insights into your finances")
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 20)
                    
                    // Plan Selection
                    VStack(spacing: 20) {
                        Text("Choose Your Plan")
                            .font(.headline)
                        
                        ForEach(SubscriptionPlan.allCases) { plan in
                            Button(action: {
                                selectedPlan = plan
                            }) {
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(plan.rawValue)
                                            .font(.headline)
                                        Text(plan.price)
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                    }
                                    Spacer()
                                    if selectedPlan == plan {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.blue)
                                    }
                                }
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(selectedPlan == plan ? Color.blue : Color.gray.opacity(0.3), lineWidth: selectedPlan == plan ? 2 : 1)
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.horizontal)
                    
                    // Terms
                    Text("Premium features will be available across all your devices. Subscription automatically renews unless cancelled.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                        .padding(.top, 20)
                    
                    Spacer(minLength: 30)
                }
                .padding(.bottom, 80) // Add padding at bottom for the fixed button
            }
            .safeAreaInset(edge: .bottom) {
                // Subscribe Button (fixed at bottom)
                VStack {
                    Button(action: {
                        // Implement subscription logic
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Text("Subscribe Now")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                    }
                    .background(Color.blue)
                    .cornerRadius(10)
                    .padding(.horizontal)
                    .padding(.vertical, 10)
                }
                .background(
                    Rectangle()
                        .fill(Color(UIColor.systemBackground))
                        .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: -2)
                )
            }
            .navigationTitle("Premium Plan")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Close") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}

struct BiometricSetupView: View {
    @Environment(\.presentationMode) private var presentationMode
    @StateObject private var viewModel = DIContainer.shared.makeSecurityViewModel()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "faceid")
                    .font(.system(size: 60))
                    .foregroundColor(.accentColor)
                
                Text("Enable Biometric Authentication")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Use Face ID or Touch ID to quickly and securely access your payslip data.")
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                Button("Enable") {
                    Task {
                        await viewModel.authenticate()
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                .buttonStyle(.borderedProminent)
                .padding(.top)
                
                Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                }
                .buttonStyle(.bordered)
            }
            .padding()
            .navigationTitle("Biometric Setup")
            .navigationBarTitleDisplayMode(.inline)
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

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.blue)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
    SettingsView()
    }
} 