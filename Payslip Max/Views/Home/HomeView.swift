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
        NavigationView {
        ScrollView {
            VStack(spacing: 20) {
                    // Header
                    HeaderView(title: "Welcome to Payslip Max")
                    
                    // Upload Section
                    UploadSectionView(
                        showingActionSheet: $showingActionSheet,
                        showingDocumentPicker: $showingDocumentPicker,
                        showingScanner: $showingScanner,
                        isUploading: viewModel.isUploading
                    )
                    
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
            .navigationTitle("Home")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        // Show settings or profile
                    }) {
                        Image(systemName: "person.circle")
                            .font(.title2)
                    }
                }
            }
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
            .actionSheet(isPresented: $showingActionSheet) {
                ActionSheet(
                    title: Text("Add Payslip"),
                    message: Text("Choose how you want to add your payslip"),
                    buttons: [
                        .default(Text("Upload PDF")) {
                            showingDocumentPicker = true
                        },
                        .default(Text("Scan Document")) {
                            showingScanner = true
                        },
                        .default(Text("Enter Manually")) {
                            viewModel.showManualEntryForm = true
                        },
                        .cancel()
                    ]
                )
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
                setupNotificationObserver()
            }
            .onDisappear {
                removeNotificationObserver()
            }
        }
        .onAppear {
            viewModel.loadRecentPayslips()
        }
    }
    
    private func setupNotificationObserver() {
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("ShowManualEntryForm"),
            object: nil,
            queue: .main
        ) { _ in
            viewModel.showManualEntryForm = true
        }
    }
    
    private func removeNotificationObserver() {
        NotificationCenter.default.removeObserver(
            self,
            name: NSNotification.Name("ShowManualEntryForm"),
            object: nil
        )
    }
}

// MARK: - Header View

struct HeaderView: View {
    let title: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Upload or scan your payslip to get started")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical)
    }
}

// MARK: - Upload Section View

struct UploadSectionView: View {
    @Binding var showingActionSheet: Bool
    @Binding var showingDocumentPicker: Bool
    @Binding var showingScanner: Bool
    let isUploading: Bool
    
    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 20) {
                QuickActionButton(
                    title: "Upload",
                    systemImage: "doc.fill",
                    action: { showingDocumentPicker = true }
                )
                
                QuickActionButton(
                    title: "Scan",
                    systemImage: "camera.fill",
                    action: { showingScanner = true }
                )
                
                QuickActionButton(
                    title: "Manual",
                    systemImage: "keyboard",
                    action: { 
                        // Show manual entry form directly instead of action sheet
                        showingActionSheet = false
                        DispatchQueue.main.async {
                            NotificationCenter.default.post(name: NSNotification.Name("ShowManualEntryForm"), object: nil)
                        }
                    }
                )
            }
                                    .padding(.horizontal)
                            }
    }
}

struct QuickActionButton: View {
    let title: String
    let systemImage: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                Image(systemName: systemImage)
                    .font(.title2)
                    .foregroundColor(.white)
                    .frame(width: 60, height: 60)
                    .background(Color.accentColor)
                    .cornerRadius(15)
                    .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                
                Text(title)
                    .font(.callout)
                    .fontWeight(.medium)
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
                            .buttonStyle(PlainButtonStyle())
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
            guard let url = urls.first else { return }
            parent.onDocumentPicked(url)
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
    
    @Environment(\.presentationMode) private var presentationMode
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Personal Details")) {
                    TextField("Name", text: $name)
                    TextField("Month", text: $month)
                    
                    Picker("Year", selection: $year) {
                        ForEach((Calendar.current.component(.year, from: Date()) - 5)...(Calendar.current.component(.year, from: Date())), id: \.self) { year in
                            Text("\(year)").tag(year)
                        }
                    }
                    
                    TextField("Location", text: $location)
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
            }
            .navigationTitle("Manual Entry")
            .navigationBarItems(trailing: Button("Cancel") {
                presentationMode.wrappedValue.dismiss()
            })
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
        presentationMode.wrappedValue.dismiss()
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