import SwiftUI
import SwiftData
import PDFKit

/// Concrete factory for creating views based on navigation destinations.
@MainActor
class DestinationFactory: DestinationFactoryProtocol {
    // Dependencies required by the views this factory creates
    private let dataService: DataServiceProtocol
    private let pdfManager: PDFUploadManager
    // Add other dependencies as needed (e.g., view models, services)

    init(dataService: DataServiceProtocol, pdfManager: PDFUploadManager) {
        self.dataService = dataService
        self.pdfManager = pdfManager
        // Initialize other dependencies
    }

    /// Creates views for stack navigation
    func makeDestinationView(for destination: AppNavigationDestination) -> AnyView { // Use new enum
        switch destination {
        // Tab roots are handled by the TabView itself, not pushed
        case .homeTab, .payslipsTab, .insightsTab, .settingsTab:
            return AnyView(EmptyView()) // Explicit return + AnyView
            
        case .payslipDetail(let id):
            // Placeholder until ViewModel is ready
            return AnyView(Text("Payslip Detail View for ID: \(id.uuidString)")) // Explicit return + AnyView
            
        case .webUploads:
            // Create the web upload view
            let viewModel = DIContainer.shared.makeWebUploadViewModel()
            return AnyView(WebUploadListView(viewModel: viewModel))
            
        case .taskDependencyExample:
            return AnyView(TaskDependencyExampleView())
            
        // Modal destinations shouldn't be handled here
        case .pdfPreview, .privacyPolicy, .termsOfService, .changePin, .addPayslip, .scanner, .pinSetup, .performanceMonitor:
             return AnyView(Text("Error: Trying to push modal destination \(destination.id) onto stack.")) // Explicit return + AnyView
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
                    HStack {
                        Spacer()
                        Button("Done", action: onDismiss)
                            .padding()
                    }
                    
                    Text("Privacy Policy Content")
                        .padding()
                    
                    Spacer()
                }
                .navigationTitle("Privacy Policy")
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

/// Mock implementation for testing and previews
/// This would typically be in a test target or test helper file
struct MockDestinationView: View {
    let destination: AppNavigationDestination // Use new enum
    
    var body: some View {
        Text("Mock destination: \(destination.id)")
            .padding()
    }
}

struct MockModalView: View {
    let destination: AppNavigationDestination // Use new enum
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

/// For reference only - this would be in a test target rather than the main app
/// because we can't use it directly due to the protocol's associated type requirements
/*
class MockDestinationFactory: DestinationFactoryProtocol {
    func makeDestinationView(for destination: AppNavigationDestination) -> MockDestinationView {
        MockDestinationView(destination: destination)
    }
    
    func makeModalView(for destination: AppNavigationDestination, isSheet: Bool, onDismiss: @escaping () -> Void) -> MockModalView {
        MockModalView(destination: destination, isSheet: isSheet, onDismiss: onDismiss)
    }
}
*/ 