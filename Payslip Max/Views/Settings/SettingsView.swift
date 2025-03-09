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
            .alert("Delete All Data", isPresented: $showingDeleteConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    viewModel.deleteAllData(context: modelContext)
                }
            } message: {
                Text("Are you sure you want to delete all your payslip data? This action cannot be undone.")
            }
            .errorAlert(error: $viewModel.error)
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
            Form {
                Section(header: Text(isSigningUp ? "Create Account" : "Sign In")) {
                    TextField("Username", text: $username)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                    
                    SecureField("Password", text: $password)
                }
                
                Section {
                    Button(isSigningUp ? "Sign Up" : "Sign In") {
                        if isSigningUp {
                            viewModel.signUp(username: username, password: password)
                        } else {
                            viewModel.signIn(username: username, password: password)
                        }
                    }
                    .disabled(username.isEmpty || password.isEmpty || viewModel.isLoading)
                    
                    Button(isSigningUp ? "Already have an account? Sign In" : "Don't have an account? Sign Up") {
                        isSigningUp.toggle()
                    }
                    .foregroundColor(.blue)
                }
                
                if viewModel.isBiometricAvailable {
                    Section {
                        Button(action: {
                            viewModel.authenticateWithBiometrics()
                        }) {
                            HStack {
                                Image(systemName: "faceid")
                                    .foregroundColor(.blue)
                                Text("Use Face ID")
                            }
                            .frame(maxWidth: .infinity, alignment: .center)
                        }
                    }
                }
            }
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
            .errorAlert(error: $viewModel.error)
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
            .sheet(item: $exportedFileURL) { url in
                ShareSheet(items: [url])
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
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.bottom)
                
                Text("Last Updated: March 1, 2023")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text("Introduction")
                    .font(.headline)
                    .padding(.top)
                
                Text("Payslip Max is committed to protecting your privacy. This Privacy Policy explains how we collect, use, and safeguard your information when you use our mobile application.")
                
                Text("Information We Collect")
                    .font(.headline)
                    .padding(.top)
                
                Text("We collect the following types of information:")
                
                VStack(alignment: .leading, spacing: 8) {
                    BulletPoint(text: "Personal information from your payslips, including name, account numbers, and financial data")
                    BulletPoint(text: "Device information such as device type, operating system, and unique device identifiers")
                    BulletPoint(text: "Usage data including app features used and time spent in the app")
                }
                
                Text("How We Use Your Information")
                    .font(.headline)
                    .padding(.top)
                
                Text("We use the collected information for the following purposes:")
                
                VStack(alignment: .leading, spacing: 8) {
                    BulletPoint(text: "To provide and maintain our service")
                    BulletPoint(text: "To notify you about changes to our service")
                    BulletPoint(text: "To provide customer support")
                    BulletPoint(text: "To gather analysis or valuable information so that we can improve our service")
                    BulletPoint(text: "To monitor the usage of our service")
                }
                
                Text("Data Security")
                    .font(.headline)
                    .padding(.top)
                
                Text("We implement appropriate technical and organizational measures to protect your personal data against unauthorized or unlawful processing, accidental loss, destruction, or damage. All sensitive data is encrypted using industry-standard encryption methods.")
                
                Text("Your Rights")
                    .font(.headline)
                    .padding(.top)
                
                Text("You have the right to:")
                
                VStack(alignment: .leading, spacing: 8) {
                    BulletPoint(text: "Access your personal data")
                    BulletPoint(text: "Correct inaccurate personal data")
                    BulletPoint(text: "Delete your personal data")
                    BulletPoint(text: "Object to processing of your personal data")
                    BulletPoint(text: "Data portability")
                }
                
                Text("Contact Us")
                    .font(.headline)
                    .padding(.top)
                
                Text("If you have any questions about this Privacy Policy, please contact us at privacy@payslipmax.com")
                    .padding(.bottom, 40)
            }
            .padding()
        }
    }
}

struct BulletPoint: View {
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text("•")
                .font(.body)
            
            Text(text)
                .font(.body)
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

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

extension URL: Identifiable {
    public var id: String {
        self.absoluteString
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
} 