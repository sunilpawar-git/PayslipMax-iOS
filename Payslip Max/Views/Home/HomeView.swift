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

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Header with Logo and Action Buttons
                ZStack {
                    // Background that extends to top including status bar
                    Color(red: 0, green: 0, blue: 0.5) // Navy blue color
                        .edgesIgnoringSafeArea(.all)
                    
                    VStack(spacing: 20) {
                        // App Logo and Name
                        HStack {
                            Image(systemName: "doc.text.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.white)
                            Text("Payslip Max")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(.white)
                            Spacer()
                        }
                        .padding(.horizontal)
                        .padding(.top, 70) // Increased from 50 to 70 to move title down
                        
                        // Action Buttons
                        HStack(spacing: 40) {
                            // Upload Button
                            ActionButton(
                                icon: "arrow.up.doc.fill",
                                title: "Upload",
                                action: { showingDocumentPicker = true }
                            )
                            
                            // Scan Button
                            ActionButton(
                                icon: "doc.text.viewfinder",
                                title: "Scan",
                                action: { showingScanner = true }
                            )
                            
                            // Manual Button
                            ActionButton(
                                icon: "square.and.pencil",
                                title: "Manual",
                                action: { viewModel.showManualEntryForm = true }
                            )
                        }
                        .padding(.bottom, 40)
                    }
                }
                
                // Main Content
                VStack(spacing: 20) {
                    // Recent Activity
                    if !viewModel.recentPayslips.isEmpty {
                        RecentActivityView(payslips: viewModel.recentPayslips)
                    }
                    
                    // Charts Section
                    if !viewModel.payslipData.isEmpty {
                        ChartsView(data: viewModel.payslipData)
                    } else {
                        EmptyStateView()
                    }
                    
                    // Tips Section
                    TipsView()
                }
                .padding()
            }
        }
        .edgesIgnoringSafeArea(.top) // Make ScrollView extend to top
        .navigationBarHidden(true) // Hide navigation bar to show our custom header
        .sheet(isPresented: $showingDocumentPicker) {
            DocumentPickerView(onDocumentPicked: { url in
                viewModel.processPayslipPDF(from: url)
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
        .errorAlert(error: $viewModel.error)
        .overlay {
            if viewModel.isLoading {
                LoadingView()
            }
        }
        .onAppear {
            viewModel.loadRecentPayslips()
        }
    }
}

// Action Button Component
struct ActionButton: View {
    let icon: String
    let title: String
    let action: () -> Void
    
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
    }
}

// MARK: - Recent Activity View

struct RecentActivityView: View {
    let payslips: [any PayslipItemProtocol]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Activity")
                .font(.headline)
                .padding(.bottom, 4)
            
            ForEach(payslips, id: \.id) { payslip in
                NavigationLink(destination: PayslipDetailView(payslip: payslip)) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(payslip.month) \(payslip.year)")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            
                            Text(payslip.name)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Text("₹\(payslip.credits, specifier: "%.2f")")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(8)
                }
            }
            
            NavigationLink(destination: PayslipsView()) {
                Text("View All Payslips")
                    .font(.subheadline)
                    .foregroundColor(.accentColor)
                    .padding(.top, 4)
            }
        }
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
                            x: .value("Month", item.label),
                            y: .value("Amount", item.value)
                        )
                        .foregroundStyle(Color.accentColor.gradient)
                    }
                }
            case 1:
                Chart {
                    ForEach(data) { item in
                        LineMark(
                            x: .value("Month", item.label),
                            y: .value("Amount", item.value)
                        )
                        .foregroundStyle(Color.accentColor.gradient)
                        .symbol(Circle().strokeBorder(lineWidth: 2))
                    }
                }
            case 2:
                Chart {
                    ForEach(data) { item in
                        SectorMark(
                            angle: .value("Amount", item.value),
                            innerRadius: .ratio(0.5),
                            angularInset: 1.5
                        )
                        .foregroundStyle(by: .value("Category", item.label))
                    }
                }
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
                                   height: CGFloat(item.value) / CGFloat(maxValue) * geometry.size.height * 0.8)
                        
                        Text(item.label)
                            .font(.caption)
                            .frame(height: 20)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        }
    }
    
    private var maxValue: Double {
        data.map { $0.value }.max() ?? 1.0
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
    @State private var dspof = ""
    @State private var location = ""
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Personal Details")) {
                    TextField("Name", text: $name)
                        .autocorrectionDisabled(true)
                    TextField("Month", text: $month)
                        .autocorrectionDisabled(true)
                    
                    Picker("Year", selection: $year) {
                        ForEach((Calendar.current.component(.year, from: Date()) - 5)...(Calendar.current.component(.year, from: Date())), id: \.self) { year in
                            Text("\(year)").tag(year)
                        }
                    }
                    
                    TextField("Location", text: $location)
                        .autocorrectionDisabled(true)
                }
                
                Section(header: Text("Financial Details")) {
                    TextField("Credits", text: $credits)
                        .keyboardType(.decimalPad)
                    
                    TextField("Debits", text: $debits)
                        .keyboardType(.decimalPad)
                    
                    TextField("Tax", text: $tax)
                        .keyboardType(.decimalPad)
                    
                    TextField("DSPOF", text: $dspof)
                        .keyboardType(.decimalPad)
                }
                
                Section {
                    Button("Save") {
                        savePayslip()
                    }
                    .disabled(!isValid)
                }
                
                // Add extra padding at the bottom to move fields away from system gesture area
                Section {
                    Color.clear.frame(height: 50)
                }
            }
            .navigationTitle("Manual Entry")
            .navigationBarItems(trailing: Button("Cancel") {
                dismiss()
            })
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
            dspof: Double(dspof) ?? 0,
            location: location
        )
        
        onSave(data)
        dismiss()
    }
}

// MARK: - Supporting Types

struct PayslipChartData: Identifiable {
    let id = UUID()
    let label: String
    let value: Double
}

struct PayslipManualEntryData {
    let name: String
    let month: String
    let year: Int
    let credits: Double
    let debits: Double
    let tax: Double
    let dspof: Double
    let location: String
}

// MARK: - Preview

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
} 