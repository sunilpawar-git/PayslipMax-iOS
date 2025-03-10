import SwiftUI
import SwiftData

struct SettingsView: View {
    @StateObject private var viewModel = DIContainer.shared.makeSettingsViewModel()
    @Environment(\.modelContext) private var modelContext
    
    @State private var showingAuthSheet = false
    @State private var showingExportSheet = false
    @State private var showingDeleteConfirmation = false
    @State private var showingAboutSheet = false
    @State private var showingPrivacySheet = false
    @State private var showingHelpSheet = false
    @State private var showingBiometricSetup = false
    @State private var showingPINSetup = false
    @State private var showingDebugMenu = false
    
    var body: some View {
        NavigationView {
            List {
                // Account Section
                Section(header: Text("Account")) {
                    if viewModel.isAuthenticated {
                        authenticatedAccountSection
                    } else {
                        Button(action: {
                            showingAuthSheet = true
                        }) {
                            HStack {
                                Image(systemName: "person.crop.circle")
                                    .foregroundColor(.blue)
                                Text("Sign In")
                            }
                        }
                    }
                }
                
                // Preferences Section
                Section(header: Text("Preferences")) {
                    Toggle("Use Biometric Authentication", isOn: $viewModel.useBiometricAuth)
                        .onChange(of: viewModel.useBiometricAuth) { _, newValue in
                            viewModel.updateBiometricPreference(enabled: newValue)
                        }
                    
                    Toggle("Dark Mode", isOn: $viewModel.useDarkMode)
                        .onChange(of: viewModel.useDarkMode) { _, newValue in
                            viewModel.updateAppearancePreference(darkMode: newValue)
                        }
                    
                    Picker("Currency", selection: $viewModel.selectedCurrency) {
                        ForEach(viewModel.availableCurrencies, id: \.self) { currency in
                            Text(currency).tag(currency)
                        }
                    }
                    .onChange(of: viewModel.selectedCurrency) { _, newValue in
                        viewModel.updateCurrencyPreference(currency: newValue)
                    }
                }
                
                // Data Management Section
                Section(header: Text("Data Management")) {
                    NavigationLink(destination: PDFExtractionTrainingView()) {
                        Label("PDF Extraction Training", systemImage: "doc.text.magnifyingglass")
                    }
                    
                    Button(action: {
                        showingExportSheet = true
                    }) {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                                .foregroundColor(.blue)
                            Text("Export Data")
                        }
                    }
                    
                    Button(action: {
                        viewModel.importData()
                    }) {
                        HStack {
                            Image(systemName: "square.and.arrow.down")
                                .foregroundColor(.blue)
                            Text("Import Data")
                        }
                    }
                    
                    Button(action: {
                        showingDeleteConfirmation = true
                    }) {
                        HStack {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                            Text("Delete All Data")
                                .foregroundColor(.red)
                        }
                    }
                }
                
                // App Information Section
                Section(header: Text("App Information")) {
                    Button(action: {
                        showingAboutSheet = true
                    }) {
                        HStack {
                            Image(systemName: "info.circle")
                                .foregroundColor(.blue)
                            Text("About Payslip Max")
                        }
                    }
                    
                    Button(action: {
                        showingPrivacySheet = true
                    }) {
                        HStack {
                            Image(systemName: "hand.raised")
                                .foregroundColor(.blue)
                            Text("Privacy Policy")
                        }
                    }
                    
                    Button(action: {
                        showingHelpSheet = true
                    }) {
                        HStack {
                            Image(systemName: "questionmark.circle")
                                .foregroundColor(.blue)
                            Text("Help & Support")
                        }
                    }
                    
                    if let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
                        HStack {
                            Text("Version")
                            Spacer()
                            Text(appVersion)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                // Debug Section (only in debug builds)
                #if DEBUG
                Section(header: Text("Debug")) {
                    Button("Generate Sample Data") {
                        viewModel.generateSampleData(context: modelContext)
                    }
                    
                    Button("Clear Sample Data") {
                        viewModel.clearSampleData(context: modelContext)
                    }
                    
                    Button("Debug Menu") {
                        showingDebugMenu = true
                    }
                }
                #endif
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("Settings")
            .sheet(isPresented: $showingAuthSheet) {
                AuthenticationView(onComplete: { success in
                    if success {
                        viewModel.refreshAuthenticationStatus()
                    }
                })
            }
            .sheet(isPresented: $showingExportSheet) {
                ExportDataView(payslips: viewModel.payslips)
            }
            .sheet(isPresented: $showingAboutSheet) {
                AboutView()
            }
            .sheet(isPresented: $showingPrivacySheet) {
                PrivacyPolicyView()
            }
            .sheet(isPresented: $showingHelpSheet) {
                HelpSupportView()
            }
            .sheet(isPresented: $showingBiometricSetup) {
                BiometricSetupView()
            }
            .sheet(isPresented: $showingPINSetup) {
                PINSetupView(isPresented: $showingPINSetup)
            }
            .sheet(isPresented: $showingDebugMenu) {
                DebugMenuView()
            }
            .alert("Delete All Data", isPresented: $showingDeleteConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    viewModel.deleteAllData(context: modelContext)
                }
            } message: {
                Text("Are you sure you want to delete all your payslip data? This action cannot be undone.")
            }
            .alert(isPresented: .constant(viewModel.error != nil)) {
                Alert(
                    title: Text("Error"),
                    message: Text(viewModel.error?.localizedDescription ?? "An unknown error occurred"),
                    dismissButton: .default(Text("OK")) {
                        DispatchQueue.main.async {
                            viewModel.clearError()
                        }
                    }
                )
            }
            .overlay {
                if viewModel.isLoading {
                    ProgressView()
                        .scaleEffect(1.5)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black.opacity(0.1))
                }
            }
        }
        .onAppear {
            viewModel.refreshAuthenticationStatus()
            viewModel.loadPayslips(context: modelContext)
        }
    }
    
    private var authenticatedAccountSection: some View {
        Group {
            HStack {
                Image(systemName: "person.crop.circle.fill")
                    .foregroundColor(.blue)
                    .font(.title2)
                
                VStack(alignment: .leading) {
                    Text(viewModel.userName)
                        .font(.headline)
                    
                    Text(viewModel.userEmail)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            Button(action: {
                viewModel.signOut()
            }) {
                HStack {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                        .foregroundColor(.red)
                    Text("Sign Out")
                        .foregroundColor(.red)
                }
            }
        }
    }
}

// MARK: - Supporting Views

struct AuthenticationView: View {
    @StateObject private var viewModel = DIContainer.shared.makeAuthViewModel()
    @Environment(\.presentationMode) private var presentationMode
    
    let onComplete: (Bool) -> Void
    
    @State private var username = ""
    @State private var password = ""
    @State private var isSigningUp = false
    
    var body: some View {
        NavigationView {
            Form(content: {
                Section(header: Text(isSigningUp ? "Create Account" : "Sign In")) {
                    TextField("Username", text: $username)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                    
                    SecureField("Password", text: $password)
                }
                
                Section {
                    Button(isSigningUp ? "Sign Up" : "Sign In") {
                        // Use a different approach to handle sign up/sign in
                        if isSigningUp {
                            // For sign up, just print a message for now
                            print("Sign up with username: \(username), password: \(password)")
                        } else {
                            // For sign in, just print a message for now
                            print("Sign in with username: \(username), password: \(password)")
                        }
                        
                        // Simulate successful authentication
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                            onComplete(true)
                            presentationMode.wrappedValue.dismiss()
                        }
                    }
                    .disabled(username.isEmpty || password.isEmpty || viewModel.isLoading)
                    
                    Button(isSigningUp ? "Already have an account? Sign In" : "Don't have an account? Sign Up") {
                        isSigningUp.toggle()
                    }
                    .foregroundColor(.blue)
                }
                
                // Biometric Authentication
                Section {
                    Toggle("Use Biometric Authentication", isOn: $viewModel.isBiometricAuthEnabled)
                        .disabled(!viewModel.isBiometricAvailable)
                }
            })
            .navigationTitle(isSigningUp ? "Create Account" : "Sign In")
            .navigationBarItems(trailing: Button("Cancel") {
                presentationMode.wrappedValue.dismiss()
            })
            .overlay {
                if viewModel.isLoading {
                    ProgressView()
                        .scaleEffect(1.5)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black.opacity(0.1))
                }
            }
            .alert(isPresented: .constant(viewModel.error != nil)) {
                Alert(
                    title: Text("Error"),
                    message: Text(viewModel.error?.localizedDescription ?? "An unknown error occurred"),
                    dismissButton: .default(Text("OK")) {
                        DispatchQueue.main.async {
                            viewModel.error = nil
                        }
                    }
                )
            }
            .onChange(of: viewModel.isAuthenticated) { _, isAuthenticated in
                if isAuthenticated {
                    onComplete(true)
                    presentationMode.wrappedValue.dismiss()
                }
            }
        }
    }
}

struct ExportDataView: View {
    let payslips: [any PayslipItemProtocol]
    
    @State private var exportFormat = ExportFormat.csv
    @State private var includePersonalInfo = false
    @State private var isExporting = false
    @State private var showShareSheet = false
    @State private var exportedFileURL: URL?
    
    @Environment(\.presentationMode) private var presentationMode
    
    enum ExportFormat: String, CaseIterable, Identifiable {
        case csv = "CSV"
        case json = "JSON"
        case pdf = "PDF"
        
        var id: String { self.rawValue }
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Export Format")) {
                    Picker("Format", selection: $exportFormat) {
                        ForEach(ExportFormat.allCases) { format in
                            Text(format.rawValue).tag(format)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                Section(header: Text("Options")) {
                    Toggle("Include Personal Information", isOn: $includePersonalInfo)
                    
                    Text("Personal information includes your name, account number, and PAN number.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Section(header: Text("Summary")) {
                    HStack {
                        Text("Payslips to Export")
                        Spacer()
                        Text("\(payslips.count)")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Date Range")
                        Spacer()
                        if let oldest = payslips.min(by: { $0.timestamp < $1.timestamp }),
                           let newest = payslips.max(by: { $0.timestamp < $1.timestamp }) {
                            Text("\(formatDate(oldest.timestamp)) - \(formatDate(newest.timestamp))")
                                .foregroundColor(.secondary)
                        } else {
                            Text("N/A")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Section {
                    Button(action: {
                        exportData()
                    }) {
                        Text("Export Data")
                            .frame(maxWidth: .infinity, alignment: .center)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(8)
                    }
                    .disabled(payslips.isEmpty || isExporting)
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .navigationTitle("Export Data")
            .navigationBarItems(trailing: Button("Cancel") {
                presentationMode.wrappedValue.dismiss()
            })
            .overlay {
                if isExporting {
                    ProgressView("Exporting...")
                        .scaleEffect(1.5)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black.opacity(0.1))
                }
            }
            .sheet(isPresented: $showShareSheet) {
                if let url = exportedFileURL {
                    ShareSheet(items: [url] as [Any])
                }
            }
        }
    }
    
    private func exportData() {
        isExporting = true
        
        // Simulate export process
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            // In a real app, you would generate the file here
            // For now, we'll just simulate it
            
            let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            let fileName = "payslips_export.\(exportFormat.rawValue.lowercased())"
            let fileURL = documentsDirectory.appendingPathComponent(fileName)
            
            // In a real app, you would write the actual data to the file
            // For now, we'll just create a dummy file
            let dummyData = "This is a simulated export file for \(payslips.count) payslips."
            try? dummyData.write(to: fileURL, atomically: true, encoding: .utf8)
            
            self.exportedFileURL = fileURL
            self.showShareSheet = true
            self.isExporting = false
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}

struct AboutView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Image("AppIcon")
                    .resizable()
                    .frame(width: 100, height: 100)
                    .cornerRadius(20)
                    .padding(.top, 40)
                
                Text("Payslip Max")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Version \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                VStack(alignment: .leading, spacing: 16) {
                    Text("About")
                        .font(.headline)
                    
                    Text("Payslip Max is a comprehensive payslip management app designed specifically for Indian Armed Forces personnel. It helps you track, analyze, and gain insights from your payslips.")
                        .font(.body)
                    
                    Text("Features")
                        .font(.headline)
                        .padding(.top)
                    
                    FeatureRow(icon: "doc.text.magnifyingglass", title: "Payslip Scanning", description: "Scan and extract data from your payslips automatically")
                    
                    FeatureRow(icon: "chart.bar", title: "Financial Insights", description: "Get detailed insights and visualizations of your financial data")
                    
                    FeatureRow(icon: "lock.shield", title: "Secure Storage", description: "Your sensitive data is encrypted and stored securely")
                    
                    FeatureRow(icon: "arrow.up.doc", title: "Export Options", description: "Export your data in various formats for external use")
                    
                    Text("Credits")
                        .font(.headline)
                        .padding(.top)
                    
                    Text("Developed by Sunil Pawar")
                        .font(.body)
                    
                    Text("© 2023 Payslip Max. All rights reserved.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top)
                }
                .padding(.horizontal)
                .padding(.bottom, 40)
            }
        }
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

struct PrivacyPolicyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Privacy Policy")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Payslip Max is committed to protecting your privacy. This Privacy Policy explains how we collect, use, and safeguard your information when you use our application.")
                
                Text("Information We Collect")
                    .font(.headline)
                
                Text("We collect information that you provide directly to us, such as your payslip data. This data is stored locally on your device and is not transmitted to our servers unless you explicitly choose to back it up.")
                
                Text("How We Use Your Information")
                    .font(.headline)
                
                Text("We use the information we collect to provide, maintain, and improve our services, and to develop new ones.")
                
                Text("Data Security")
                    .font(.headline)
                
                Text("We implement appropriate security measures to protect your personal information. Your payslip data is encrypted on your device and can only be accessed with your PIN or biometric authentication.")
            }
            .padding()
        }
        .navigationTitle("Privacy Policy")
    }
}

struct TermsOfServiceView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Terms of Service")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("By using Payslip Max, you agree to these terms. Please read them carefully.")
                
                Text("Use of the Application")
                    .font(.headline)
                
                Text("You may use Payslip Max for personal, non-commercial purposes. You may not use the application for any illegal purpose or in violation of any local laws.")
                
                Text("Your Content")
                    .font(.headline)
                
                Text("You retain ownership of any content you upload to Payslip Max. By uploading content, you grant us a license to use it to provide and improve our services.")
                
                Text("Disclaimer of Warranties")
                    .font(.headline)
                
                Text("Payslip Max is provided 'as is' without any warranties, expressed or implied.")
            }
            .padding()
        }
        .navigationTitle("Terms of Service")
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

struct HelpSupportView: View {
    @State private var selectedQuestion: String?
    
    let faqs = [
        "How do I add a new payslip?": "You can add a new payslip by tapping the '+' button on the Home screen and selecting one of the options: Upload PDF, Scan Document, or Enter Manually.",
        "Is my data secure?": "Yes, all sensitive data is encrypted using industry-standard encryption methods. Your data is stored locally on your device and is not shared with any third parties without your consent.",
        "How do I export my data?": "You can export your data by going to Settings > Data Management > Export Data. You can choose to export in CSV, JSON, or PDF format.",
        "Can I use Face ID to secure the app?": "Yes, you can enable biometric authentication in Settings > Preferences > Use Biometric Authentication.",
        "How do I delete my data?": "You can delete all your data by going to Settings > Data Management > Delete All Data. Please note that this action cannot be undone.",
        "How do I contact support?": "You can contact our support team by emailing support@payslipmax.com or by using the contact form on our website."
    ]
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Help & Support")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.bottom)
                
                Text("Frequently Asked Questions")
                    .font(.headline)
                
                VStack(spacing: 16) {
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
                
                Divider()
                    .padding(.vertical)
                
                Text("Contact Us")
                    .font(.headline)
                
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "envelope")
                            .foregroundColor(.blue)
                            .frame(width: 24)
                        
                        Text("support@payslipmax.com")
                    }
                    
                    HStack {
                        Image(systemName: "globe")
                            .foregroundColor(.blue)
                            .frame(width: 24)
                        
                        Text("www.payslipmax.com")
                    }
                    
                    HStack {
                        Image(systemName: "phone")
                            .foregroundColor(.blue)
                            .frame(width: 24)
                        
                        Text("+91 123 456 7890")
                    }
                }
                .padding(.bottom, 40)
            }
            .padding()
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

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
    SettingsView()
    }
} 