import SwiftUI
import PDFKit
import Charts
import Vision
import VisionKit

@MainActor
struct HomeView: View {
    @StateObject private var viewModel = DIContainer.shared.makeHomeViewModel()
    @State private var showingDocumentPicker = false
    @State private var showingScanner = false
    @State private var showingActionSheet = false
    @State private var dsop = ""

    var body: some View {
        ZStack {
            // Base background color - system background for the tab bar area
            Color(.systemBackground)
                .edgesIgnoringSafeArea(.all)
            
            // Navy blue background that extends beyond the top edge
            Color(red: 0, green: 0, blue: 0.5) // Navy blue color
                .edgesIgnoringSafeArea(.all) // Ignore safe area on all edges to ensure full coverage when pulling down
                .frame(height: UIScreen.main.bounds.height * 0.4) // Limit height to top portion
                .frame(maxHeight: .infinity, alignment: .top) // Align to top
            
            ScrollView {
                VStack(spacing: 0) {
                    // Header with Logo and Action Buttons
                    ZStack {
                        // Background that extends to top including status bar
                        Color(red: 0, green: 0, blue: 0.5) // Navy blue color
                            .edgesIgnoringSafeArea(.top)
                        
                        VStack(spacing: 60) {
                            // App Logo and Name
                            HStack {
                                Image(systemName: "doc.text.fill")
                                    .font(.system(size: 26))
                                    .foregroundColor(.white)
                                    .accessibilityIdentifier("home_logo")
                                Text("Payslip Max")
                                    .font(.system(size: 34, weight: .bold))
                                    .foregroundColor(.white)
                                    .accessibilityIdentifier("home_title")
                                Spacer()
                            }
                            .padding(.horizontal, 24)
                            .padding(.top, 40)
                            .accessibilityIdentifier("home_header")
                            
                            // Action Buttons
                            HStack(spacing: 50) {
                                // Upload Button
                                ActionButton(
                                    icon: "arrow.up.doc.fill",
                                    title: "Upload",
                                    action: { showingDocumentPicker = true },
                                    accessibilityId: "upload_button"
                                )
                                
                                // Scan Button
                                ActionButton(
                                    icon: "doc.text.viewfinder",
                                    title: "Scan",
                                    action: { showingScanner = true },
                                    accessibilityId: "scan_button"
                                )
                                
                                // Manual Button
                                ActionButton(
                                    icon: "square.and.pencil",
                                    title: "Manual",
                                    action: { viewModel.showManualEntryForm = true },
                                    accessibilityId: "manual_button"
                                )
                            }
                            .padding(.bottom, 40)
                            .accessibilityIdentifier("action_buttons")
                        }
                    }
                    
                    // Main Content
                    VStack(spacing: 20) {
                        PayslipCountdownView()
                            .padding(.horizontal, 8)
                            .padding(.top, 10)
                            .accessibilityIdentifier("countdown_view")
                        
                        // Recent Activity
                        if !viewModel.recentPayslips.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Recent Payslips")
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                    .padding(.horizontal)
                                    .accessibilityIdentifier("recent_payslips_title")
                                
                                RecentActivityView(payslips: viewModel.recentPayslips)
                                    .accessibilityIdentifier("recent_activity_view")
                            }
                        }
                        
                        // Charts Section
                        if !viewModel.payslipData.isEmpty {
                            ChartsView(data: viewModel.payslipData)
                                .accessibilityIdentifier("charts_view")
                        } else {
                            EmptyStateView()
                                .accessibilityIdentifier("empty_state_view")
                        }
                        
                        // Tips Section
                        TipsView()
                            .accessibilityIdentifier("tips_view")
                    }
                    .padding()
                    .background(Color(.systemBackground))
                }
            }
            .background(Color.clear) // Make ScrollView background clear
        }
        .navigationBarHidden(true) // Hide navigation bar to show our custom header
        .sheet(isPresented: $showingDocumentPicker) {
            DocumentPickerView(onDocumentPicked: { url in
                handleDocumentPicked(url: url)
            })
        }
        .sheet(isPresented: $showingScanner) {
            ScannerView(onScanCompleted: { image in
                viewModel.processScannedPayslip(from: image)
            })
        }
        .sheet(isPresented: $viewModel.showManualEntryForm) {
            ManualEntryView(onSave: { payslipData in
                viewModel.processManualEntry(payslipData)
            })
        }
        .sheet(isPresented: $viewModel.showPasswordEntryView) {
            if let pdfData = viewModel.currentPasswordProtectedPDFData {
                PasswordProtectedPDFView(
                    pdfData: pdfData,
                    onUnlock: { unlockedData in
                        Task {
                            await viewModel.handleUnlockedPDF(unlockedData)
                        }
                    }
                )
            }
        }
        .background(
            Group {
                if #available(iOS 16.0, *) {
                    NavigationStack {
                        EmptyView()
                            .navigationDestination(isPresented: $viewModel.navigateToNewPayslip) {
                                if let payslip = viewModel.newlyAddedPayslip {
                                    PayslipNavigation.detailView(for: payslip)
                                }
                            }
                    }
                    .opacity(0) // Hide the stack but keep it functional
                } else {
                    // Legacy NavigationLink for iOS 15 and earlier
                    NavigationLink(
                        destination: Group {
                            if let payslip = viewModel.newlyAddedPayslip {
                                PayslipNavigation.detailView(for: payslip)
                            }
                        },
                        isActive: $viewModel.navigateToNewPayslip
                    ) { EmptyView() }
                }
            }
        )
        .actionSheet(isPresented: $showingActionSheet) {
            ActionSheet(
                title: Text("Add Payslip"),
                message: Text("Choose how you want to add a payslip"),
                buttons: [
                    .default(Text("Upload PDF")) {
                        showingDocumentPicker = true
                    },
                    .default(Text("Scan Document")) {
                        showingScanner = true
                    },
                    .default(Text("Manual Entry")) {
                        viewModel.showManualEntryForm = true
                    },
                    .cancel()
                ]
            )
        }
        .alert(item: $viewModel.error) { error in
            Alert(
                title: Text("Error"),
                message: Text(error.localizedDescription),
                dismissButton: .default(Text("OK"))
            )
        }
        .overlay {
            if viewModel.isLoading {
                LoadingOverlay()
            }
        }
        .onAppear {
            Task {
                viewModel.loadRecentPayslips()
            }
        }
        .onDisappear {
            // Ensure loading indicator is hidden when navigating away
            viewModel.cancelLoading()
        }
        .accessibilityIdentifier("home_view")
    }
    
    // Document Picker
    private func showDocumentPicker() {
        showingDocumentPicker = true
    }
    
    private func handleDocumentPicked(url: URL) {
        // Process the document
        print("HomeView: Processing document from \(url.absoluteString)")
        Task {
            await viewModel.processPayslipPDF(from: url)
        }
    }
}

// Action Button Component
struct ActionButton: View {
    let icon: String
    let title: String
    let action: () -> Void
    var accessibilityId: String? = nil
    
    var body: some View {
        Button(action: action) {
            VStack {
                Circle()
                    .fill(Color(red: 0.4, green: 0.6, blue: 1.0)) // Sky blue color
                    .frame(width: 65, height: 65) // Increased size
                    .overlay(
                        Image(systemName: icon)
                            .font(.system(size: 28)) // Increased icon size
                            .foregroundColor(.white)
                    )
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
            }
        }
        .modifier(AccessibilityModifier(id: accessibilityId))
    }
}

// Modifier to handle optional accessibility identifiers
struct AccessibilityModifier: ViewModifier {
    let id: String?
    
    func body(content: Content) -> some View {
        if let id = id {
            content.accessibilityIdentifier(id)
        } else {
            content
        }
    }
}

// MARK: - Recent Activity View

struct RecentActivityView: View {
    let payslips: [any PayslipItemProtocol]
    
    var body: some View {
        VStack(spacing: 16) {
            // Recent Payslips in Vertical Ribbons
            ForEach(Array(payslips.prefix(3)), id: \.id) { payslip in
                NavigationLink {
                    PayslipNavigation.detailView(for: payslip)
                } label: {
                    VStack(alignment: .leading, spacing: 12) {
                        // Payslip Month and Year
                        Text("\(payslip.month) \(formatYear(payslip.year))")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        // Credits and Debits in one line
                        HStack(spacing: 16) {
                            // Credits
                            HStack(spacing: 4) {
                                Text("Credits:")
                                    .font(.system(size: 16))
                                    .foregroundColor(.secondary)
                                Text("₹\(formatCurrency(payslip.credits))/-")
                                    .font(.system(size: 16))
                                    .foregroundColor(.primary)
                            }
                            
                            // Debits
                            HStack(spacing: 4) {
                                Text("Debits:")
                                    .font(.system(size: 16))
                                    .foregroundColor(.secondary)
                                Text("₹\(formatCurrency(payslip.debits))/-")
                                    .font(.system(size: 16))
                                    .foregroundColor(.primary)
                            }
                        }
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)
                }
            }
            
            // View Previous Payslips Link
            NavigationLink(destination: PayslipsView()) {
                Text("View Previous Payslips")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Color(red: 0.2, green: 0.5, blue: 1.0))
                    .padding(.top, 8)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 3) // Add padding to the entire VStack
    }
    
    // Helper function to format currency with Indian format
    private func formatCurrency(_ value: Double) -> String {
        // Don't format zero values as they might be actual data
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        formatter.groupingSize = 3
        formatter.secondaryGroupingSize = 2
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        
        let number = NSNumber(value: value)
        return formatter.string(from: number) ?? String(format: "%.2f", value)
    }
    
    // Helper function to format year without grouping
    private func formatYear(_ year: Int) -> String {
        return "\(year)"
    }
}

// MARK: - Charts View

struct ChartsView: View {
    let data: [PayslipChartData]
    @State private var selectedChart = 0
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Financial Overview")
                .font(.headline)
                .padding(.bottom, 4)
            
            Picker("Chart Type", selection: $selectedChart) {
                Text("Monthly").tag(0)
                Text("Yearly").tag(1)
                Text("Categories").tag(2)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.bottom, 8)
            
            if #available(iOS 16.0, *) {
                chartView
                    .frame(height: 220)
                    .padding(.vertical)
            } else {
                // Fallback for iOS 15
                legacyChartView
                    .frame(height: 220)
                    .padding(.vertical)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    @available(iOS 16.0, *)
    private var chartView: some View {
        Group {
            switch selectedChart {
            case 0:
                Chart {
                    ForEach(data) { item in
                        BarMark(
                            x: .value("Month", item.month),
                            y: .value("Amount", item.credits),
                            width: .ratio(0.4)
                        )
                        .foregroundStyle(Color.green.gradient)
                        .position(by: .value("Type", "Credits"))
                        
                        BarMark(
                            x: .value("Month", item.month),
                            y: .value("Amount", item.debits),
                            width: .ratio(0.4)
                        )
                        .foregroundStyle(Color.red.gradient)
                        .position(by: .value("Type", "Debits"))
                    }
                }
                .chartLegend(position: .bottom)
            case 1:
                Chart {
                    ForEach(data) { item in
                        LineMark(
                            x: .value("Month", item.month),
                            y: .value("Amount", item.credits)
                        )
                        .foregroundStyle(Color.green)
                        .symbol(Circle().strokeBorder(lineWidth: 2))
                        .symbolSize(30)
                        
                        LineMark(
                            x: .value("Month", item.month),
                            y: .value("Amount", item.debits)
                        )
                        .foregroundStyle(Color.red)
                        .symbol(Circle().strokeBorder(lineWidth: 2))
                        .symbolSize(30)
                        
                        LineMark(
                            x: .value("Month", item.month),
                            y: .value("Amount", item.net)
                        )
                        .foregroundStyle(Color.blue)
                        .symbol(Circle().strokeBorder(lineWidth: 2))
                        .symbolSize(30)
                    }
                }
                .chartLegend(position: .bottom)
                .chartForegroundStyleScale([
                    "Credits": Color.green,
                    "Debits": Color.red,
                    "Net": Color.blue
                ])
            case 2:
                Chart {
                    ForEach(data) { item in
                        SectorMark(
                            angle: .value("Amount", item.credits),
                            innerRadius: .ratio(0.5),
                            angularInset: 1.5
                        )
                        .foregroundStyle(Color.green.gradient)
                        .annotation(position: .overlay) {
                            Text("Credits")
                                .font(.caption)
                                .foregroundColor(.white)
                        }
                        
                        SectorMark(
                            angle: .value("Amount", item.debits),
                            innerRadius: .ratio(0.5),
                            angularInset: 1.5
                        )
                        .foregroundStyle(Color.red.gradient)
                        .annotation(position: .overlay) {
                            Text("Debits")
                                .font(.caption)
                                .foregroundColor(.white)
                        }
                    }
                }
                .chartLegend(position: .bottom)
            default:
                EmptyView()
            }
        }
    }
    
    // Fallback chart view for iOS 15
    private var legacyChartView: some View {
        GeometryReader { geometry in
            HStack(alignment: .bottom, spacing: 8) {
                ForEach(data) { item in
                    VStack {
                        Rectangle()
                            .fill(Color.accentColor)
                            .frame(width: (geometry.size.width - CGFloat(data.count) * 8) / CGFloat(data.count),
                                   height: CGFloat(item.credits) / CGFloat(maxValue) * geometry.size.height * 0.8)
                        
                        Text(item.month)
                            .font(.caption)
                            .frame(height: 20)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        }
    }
    
    private var maxValue: Double {
        data.map { $0.credits }.max() ?? 1.0
    }
}

// MARK: - Empty State View

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("No Payslip Data Yet")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Upload your first payslip to see insights and charts")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

// MARK: - Tips View

struct TipsView: View {
    let tips = [
        "Upload your payslips regularly to track your finances",
        "Compare your monthly earnings to identify trends",
        "Check deductions to ensure they're accurate",
        "Save your payslips securely for future reference"
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Tips & Tricks")
                .font(.headline)
                .padding(.bottom, 4)
            
            ForEach(tips, id: \.self) { tip in
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "lightbulb.fill")
                        .foregroundColor(.yellow)
                    
                    Text(tip)
                        .font(.subheadline)
                }
                .padding(.vertical, 4)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

// MARK: - Loading View

struct LoadingView: View {
    @State private var shouldDismiss = false
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 20) {
                ProgressView()
                    .scaleEffect(1.5)
                
                Text("Processing...")
                    .font(.headline)
                    .foregroundColor(.white)
            }
            .padding(30)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground).opacity(0.8))
            )
        }
        .opacity(shouldDismiss ? 0 : 1)
        .animation(.easeOut(duration: 0.3), value: shouldDismiss)
        .onAppear {
            // Auto-dismiss after 3 seconds to prevent lingering
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                shouldDismiss = true
            }
        }
    }
}

// MARK: - Loading Overlay with Delay

struct LoadingOverlay: View {
    @State private var isVisible = false
    
    var body: some View {
        if isVisible {
            LoadingView()
        } else {
            Color.clear
                .onAppear {
                    // Only show loading indicator after a short delay
                    // This prevents flashing for quick operations
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        isVisible = true
                    }
                }
        }
    }
}

// MARK: - Document Picker View

struct DocumentPickerView: UIViewControllerRepresentable {
    let onDocumentPicked: (URL) -> Void
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.pdf])
        picker.delegate = context.coordinator
        picker.allowsMultipleSelection = false
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let parent: DocumentPickerView
        
        init(_ parent: DocumentPickerView) {
            self.parent = parent
        }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let originalURL = urls.first else { return }
            
            print("Document picked: \(originalURL.absoluteString)")
            
            // Start accessing the security-scoped resource
            let didStartAccessing = originalURL.startAccessingSecurityScopedResource()
            
            defer {
                // Make sure to release the security-scoped resource when finished
                if didStartAccessing {
                    originalURL.stopAccessingSecurityScopedResource()
                }
            }
            
            do {
                // Create a unique filename in the app's temporary directory
                let tempDirectoryURL = FileManager.default.temporaryDirectory
                let uniqueFilename = UUID().uuidString + ".pdf"
                let destinationURL = tempDirectoryURL.appendingPathComponent(uniqueFilename)
                
                print("Copying file to: \(destinationURL.absoluteString)")
                
                // Copy the file to our app's temporary directory
                try FileManager.default.copyItem(at: originalURL, to: destinationURL)
                
                // Verify the file was copied successfully
                guard FileManager.default.fileExists(atPath: destinationURL.path) else {
                    print("Error: File was not copied successfully")
                    throw NSError(domain: "DocumentPickerError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to copy file to temporary location"])
                }
                
                // Get file attributes to verify size
                let attributes = try FileManager.default.attributesOfItem(atPath: destinationURL.path)
                if let fileSize = attributes[.size] as? NSNumber {
                    print("Copied file size: \(fileSize) bytes")
                }
                
                // Now we can safely use this URL without permission issues
                DispatchQueue.main.async {
                    self.parent.onDocumentPicked(destinationURL)
                }
            } catch {
                print("Error copying file: \(error.localizedDescription)")
                
                // If copying fails, try to create a direct data copy
                do {
                    let fileData = try Data(contentsOf: originalURL)
                    print("Read \(fileData.count) bytes directly from original URL")
                    
                    let tempDirectoryURL = FileManager.default.temporaryDirectory
                    let uniqueFilename = UUID().uuidString + ".pdf"
                    let destinationURL = tempDirectoryURL.appendingPathComponent(uniqueFilename)
                    
                    try fileData.write(to: destinationURL)
                    print("Wrote data directly to: \(destinationURL.absoluteString)")
                    
                    // Verify the file was written successfully
                    guard FileManager.default.fileExists(atPath: destinationURL.path) else {
                        print("Error: File was not written successfully")
                        throw NSError(domain: "DocumentPickerError", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to write file data to temporary location"])
                    }
                    
                    // Get file attributes to verify size
                    let attributes = try FileManager.default.attributesOfItem(atPath: destinationURL.path)
                    if let fileSize = attributes[.size] as? NSNumber {
                        print("Written file size: \(fileSize) bytes")
                    }
                    
                    DispatchQueue.main.async {
                        self.parent.onDocumentPicked(destinationURL)
                    }
                } catch {
                    print("Error creating direct data copy: \(error.localizedDescription)")
                    // Last resort: try with the original URL
                    DispatchQueue.main.async {
                        self.parent.onDocumentPicked(originalURL)
                    }
                }
            }
        }
    }
}

// MARK: - Scanner View

struct ScannerView: UIViewControllerRepresentable {
    let onScanCompleted: (UIImage) -> Void
    
    func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
        let scanner = VNDocumentCameraViewController()
        scanner.delegate = context.coordinator
        return scanner
    }
    
    func updateUIViewController(_ uiViewController: VNDocumentCameraViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {
        let parent: ScannerView
        
        init(_ parent: ScannerView) {
            self.parent = parent
        }
        
        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
            guard scan.pageCount > 0 else { return }
            let image = scan.imageOfPage(at: 0)
            parent.onScanCompleted(image)
            controller.dismiss(animated: true)
        }
        
        func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
            controller.dismiss(animated: true)
        }
        
        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFailWithError error: Error) {
            ErrorLogger.log(error)
            controller.dismiss(animated: true)
        }
    }
}

// MARK: - Manual Entry View

struct ManualEntryView: View {
    let onSave: (PayslipManualEntryData) -> Void
    
    @State private var name = ""
    @State private var month = ""
    @State private var year = Calendar.current.component(.year, from: Date())
    @State private var credits = ""
    @State private var debits = ""
    @State private var tax = ""
    @State private var dsop = ""
    @State private var location = ""
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Personal Details")) {
                    TextField("Name", text: $name)
                        .autocorrectionDisabled(true)
                        .accessibilityIdentifier("name_field")
                    TextField("Month", text: $month)
                        .autocorrectionDisabled(true)
                        .accessibilityIdentifier("month_field")
                    
                    Picker("Year", selection: $year) {
                        ForEach((Calendar.current.component(.year, from: Date()) - 5)...(Calendar.current.component(.year, from: Date())), id: \.self) { year in
                            Text(String(year)).tag(year)
                        }
                    }
                    .accessibilityIdentifier("year_field")
                    
                    TextField("Location", text: $location)
                        .autocorrectionDisabled(true)
                        .accessibilityIdentifier("location_field")
                }
                
                Section(header: Text("Financial Details")) {
                    TextField("Credits", text: $credits)
                        .keyboardType(.decimalPad)
                        .accessibilityIdentifier("credits_field")
                    
                    TextField("Debits", text: $debits)
                        .keyboardType(.decimalPad)
                        .accessibilityIdentifier("debits_field")
                    
                    TextField("Tax", text: $tax)
                        .keyboardType(.decimalPad)
                        .accessibilityIdentifier("tax_field")
                    
                    TextField("DSOP", text: $dsop)
                        .keyboardType(.decimalPad)
                        .accessibilityIdentifier("dsop_field")
                }
                
                Section {
                    Button("Save") {
                        savePayslip()
                    }
                    .disabled(!isValid)
                    .accessibilityIdentifier("save_button")
                }
                
                // Add extra padding at the bottom to move fields away from system gesture area
                Section {
                    Color.clear.frame(height: 50)
                }
            }
            .navigationTitle("Manual Entry")
            .navigationBarItems(trailing: Button("Cancel") {
                dismiss()
            }
            .accessibilityIdentifier("cancel_button"))
            .onAppear {
                // Add a small delay before focusing on fields
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    // This helps avoid gesture conflicts on form appearance
                }
            }
        }
    }
    
    private var isValid: Bool {
        !name.isEmpty && !month.isEmpty && !credits.isEmpty
    }
    
    private func savePayslip() {
        let data = PayslipManualEntryData(
            name: name,
            month: month,
            year: year,
            credits: Double(credits) ?? 0,
            debits: Double(debits) ?? 0,
            tax: Double(tax) ?? 0,
            dsop: Double(dsop) ?? 0,
            location: location
        )
        
        onSave(data)
        dismiss()
    }
}

// MARK: - Supporting Types

struct PayslipChartData: Identifiable {
    let id = UUID()
    let month: String
    let credits: Double
    let debits: Double
    let net: Double
}

struct PayslipManualEntryData {
    let name: String
    let month: String
    let year: Int
    let credits: Double
    let debits: Double
    let tax: Double
    let dsop: Double
    let location: String
}

// MARK: - Preview

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}

// MARK: - Payslip Countdown View

struct PayslipCountdownView: View {
    @State private var daysRemaining: Int = 0
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack(spacing: 16) {
            HStack(spacing: 12) {
                Image(systemName: "calendar")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 26)
                
                Text("Days till Next Payslip")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)
            }
            
            Spacer(minLength: 32)
            
            Text("\(daysRemaining) Days")
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(.white)
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 24)
        .frame(maxWidth: .infinity, minHeight: 56)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(red: 0.2, green: 0.5, blue: 1.0),
                            Color(red: 0.3, green: 0.6, blue: 1.0)
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .shadow(color: Color.black.opacity(0.15), radius: 5, x: 0, y: 2)
        )
        .onAppear {
            updateDaysRemaining()
        }
    }
    
    private func updateDaysRemaining() {
        let calendar = Calendar.current
        let now = Date()
        
        // Get the current month's last day
        guard let lastDayOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: calendar.startOfDay(for: now))),
              let lastDay = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: lastDayOfMonth) else {
            return
        }
        
        // Calculate days remaining
        if let days = calendar.dateComponents([.day], from: now, to: lastDay).day {
            daysRemaining = max(days + 1, 0) // Add 1 to include the current day
        }
        
        // Set up a timer to update daily
        Timer.scheduledTimer(withTimeInterval: 86400, repeats: true) { _ in // 86400 seconds = 24 hours
            updateDaysRemaining()
        }
    }
} 
