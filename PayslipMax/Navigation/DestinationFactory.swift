import SwiftUI
import SwiftData
import PDFKit

/// Concrete factory for creating views based on navigation destinations.
@MainActor
class DestinationFactory: DestinationFactoryProtocol {
    // Dependencies required by the views this factory creates
    private let dataService: DataServiceProtocol
    private let pdfManager: PDFUploadManager
    private weak var homeViewModel: HomeViewModel?
    // Add other dependencies as needed (e.g., view models, services)

    init(dataService: DataServiceProtocol, pdfManager: PDFUploadManager, homeViewModel: HomeViewModel? = nil) {
        self.dataService = dataService
        self.pdfManager = pdfManager
        self.homeViewModel = homeViewModel
        // Initialize other dependencies
        
        // Listen for HomeViewModel updates from NavigationCoordinator
        setupHomeViewModelNotificationObserver()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    private func setupHomeViewModelNotificationObserver() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleHomeViewModelUpdate(_:)),
            name: NSNotification.Name("UpdateDestinationFactoryHomeViewModel"),
            object: nil
        )
    }
    
    @objc private func handleHomeViewModelUpdate(_ notification: Notification) {
        if let homeViewModel = notification.object as? HomeViewModel {
            print("[DestinationFactory] Received HomeViewModel update")
            self.homeViewModel = homeViewModel
        }
    }

    /// Creates views for stack navigation
    func makeDestinationView(for destination: AppNavigationDestination) -> AnyView {
        switch destination {
        // Tab roots are handled by the TabView itself, not pushed
        case .homeTab, .payslipsTab, .insightsTab, .settingsTab:
            return AnyView(EmptyView())
            
        case .payslipDetail(let id):
            return AnyView(PayslipDetailContainerView(id: id, dataService: dataService))
            
        case .webUploads:
            let viewModel = DIContainer.shared.makeWebUploadViewModel()
            return AnyView(WebUploadListView(viewModel: viewModel))
            
        case .taskDependencyExample:
            return AnyView(TaskDependencyExampleView())
            
        // Modal destinations shouldn't be handled here
        case .pdfPreview, .privacyPolicy, .termsOfService, .changePin, .addPayslip, .scanner, .pinSetup, .performanceMonitor, .documentPicker, .cameraScanner:
            return AnyView(Text("Error: Trying to push modal destination \(destination.id) onto stack."))
        }
    }

    /// Creates views for modal presentations (sheets or full screen covers)
    func makeModalView(for destination: AppNavigationDestination, isSheet: Bool, onDismiss: @escaping () -> Void) -> AnyView {
        switch destination {
        case .pdfPreview(let document):
            return AnyView(PDFPreviewView(document: document, onConfirm: onDismiss))
            
        case .privacyPolicy:
            let view = NavigationView {
                VStack {
                    Text("This app is designed for 100% offline use, to ease the pain of storing & analysing payslips. Your data is stored only on your device and is never transmitted to any external servers.")
                        .padding()
                    
                    Spacer()
                    
                    Button("Close") {
                        onDismiss()
                    }
                    .padding()
                }
                .navigationTitle("Privacy Policy")
                .navigationBarTitleDisplayMode(.inline)
            }
            return AnyView(view)
            
        case .termsOfService:
            let view = NavigationView {
                VStack {
                    HStack {
                        Spacer()
                        Button("Done", action: onDismiss)
                            .padding()
                    }
                    
                    Text("Terms of Service Content")
                        .padding()
                    
                    Spacer()
                }
                .navigationTitle("Terms of Service")
            }
            return AnyView(view)
            
        case .changePin:
            return AnyView(Text("Change PIN View"))
            
        case .addPayslip:
            return AnyView(AddPayslipSheet(isPresented: .constant(true), pdfManager: self.pdfManager))
            
        case .scanner:
            return AnyView(PayslipScannerView())
            
        case .pinSetup:
            return AnyView(PINSetupView(isPresented: .constant(true)))
            
        case .performanceMonitor:
            return AnyView(
                NavigationView {
                    PerformanceMonitorView()
                        .navigationBarItems(trailing: Button("Done", action: onDismiss))
                }
            )
            
        case .taskDependencyExample:
            return AnyView(
                NavigationView {
                    TaskDependencyExampleView()
                        .navigationBarItems(trailing: Button("Done", action: onDismiss))
                }
            )
            
        // MARK: - Direct Document Processing Destinations
        
        case .documentPicker:
            // Create a document picker that integrates with HomeViewModel's PDF processing
            let documentPicker = DocumentPickerView { selectedURL in
                print("[DestinationFactory] Document selected: \(selectedURL)")
                
                // Use the injected HomeViewModel instead of creating a new one
                Task { @MainActor in
                    guard let homeViewModel = self.homeViewModel else {
                        print("[DestinationFactory] Error: HomeViewModel not available")
                        onDismiss()
                        return
                    }
                    
                    // Process the PDF using HomeViewModel's existing pipeline
                    // This will handle password-protected PDFs through the existing UI system
                    await homeViewModel.processPayslipPDF(from: selectedURL)
                }
                
                // Always dismiss the document picker immediately
                // The password dialog (if needed) will be shown in the main app UI
                onDismiss()
            }
            return AnyView(documentPicker)
            
        case .cameraScanner:
            // Create a camera scanner that integrates with HomeViewModel
            let cameraScanner = ScannerView { scannedImage in
                print("[DestinationFactory] Image scanned")
                
                // Use the injected HomeViewModel instead of creating a new one
                Task { @MainActor in
                    guard let homeViewModel = self.homeViewModel else {
                        print("[DestinationFactory] Error: HomeViewModel not available")
                        onDismiss()
                        return
                    }
                    
                    // Use HomeViewModel's existing scanned image processing
                    homeViewModel.processScannedPayslip(from: scannedImage)
                    
                    // Dismiss the scanner after processing starts
                    onDismiss()
                }
            }
            return AnyView(cameraScanner)
            
        // Stack/Tab destinations shouldn't be presented modally
        case .homeTab, .payslipsTab, .insightsTab, .settingsTab, .payslipDetail, .webUploads:
            return AnyView(Text("Error: Trying to present stack/tab destination \(destination.id) modally."))
        }
    }
}

/// A container view that handles loading the payslip asynchronously
struct PayslipDetailContainerView: View {
    let id: UUID
    let dataService: DataServiceProtocol
    @State private var payslip: PayslipItem?
    @State private var isLoading = true
    @State private var errorMessage: String?
    
    var body: some View {
        Group {
            if isLoading {
                ProgressView("Loading payslip...")
            } else if let payslip = payslip {
                PayslipNavigation.detailView(for: payslip)
            } else {
                VStack {
                    Text("Payslip not found")
                        .padding()
                    
                    if let errorMessage = errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                            .padding()
                    }
                }
            }
        }
        .onAppear {
            loadPayslip()
        }
    }
    
    private func loadPayslip() {
        Task {
            isLoading = true
            do {
                let payslips = try await dataService.fetch(PayslipItem.self)
                if let payslip = payslips.first(where: { $0.id == id }) {
                    self.payslip = payslip
                }
            } catch {
                errorMessage = "Error: \(error.localizedDescription)"
                print("Error fetching payslip: \(error)")
            }
            isLoading = false
        }
    }
}

// MARK: - Preview Support

/// Mock views for SwiftUI previews - these should eventually be moved to test target
struct MockDestinationView: View {
    let destination: AppNavigationDestination
    
    var body: some View {
        Text("Mock destination: \(destination.id)")
            .padding()
    }
}

struct MockModalView: View {
    let destination: AppNavigationDestination
    let isSheet: Bool
    let onDismiss: () -> Void
    
    var body: some View {
        VStack {
            Text("Mock modal: \(destination.id)")
                .padding()
            
            Button("Dismiss") {
                onDismiss()
            }
            .padding()
        }
    }
} 