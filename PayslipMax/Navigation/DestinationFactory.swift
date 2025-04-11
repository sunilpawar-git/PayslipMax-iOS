import SwiftUI
import PDFKit

/// Factory for creating destination views for navigation
@MainActor
protocol DestinationFactoryProtocol {
    associatedtype DestinationView: View
    associatedtype ModalView: View
    
    /// Build a view for a navigation destination
    @ViewBuilder
    func makeDestinationView(for destination: NavDestination) -> DestinationView
    
    /// Build a view for a modal presentation
    @ViewBuilder
    func makeModalView(for destination: NavDestination, isSheet: Bool, onDismiss: @escaping () -> Void) -> ModalView
}

/// Default implementation of DestinationFactoryProtocol
class DestinationFactory: DestinationFactoryProtocol {
    private let dataService: DataServiceProtocol
    private let pdfManager: PDFUploadManager
    
    init(dataService: DataServiceProtocol, pdfManager: PDFUploadManager) {
        self.dataService = dataService
        self.pdfManager = pdfManager
    }
    
    /// Build a view for a navigation destination
    @ViewBuilder
    func makeDestinationView(for destination: NavDestination) -> some View {
        switch destination {
        case .payslipDetail(let id):
            PayslipDetailContainerView(id: id, dataService: dataService)
        case .privacyPolicy:
            Text("Privacy Policy")
                .padding()
                .navigationTitle("Privacy Policy")
        case .termsOfService:
            Text("Terms of Service")
                .padding()
                .navigationTitle("Terms of Service")
        case .changePin:
            Text("Change PIN View")
                .padding()
                .navigationTitle("Change PIN")
        // Other cases should be handled as modals, not in the navigation stack
        default:
            Text("This should be presented as a modal")
                .padding()
        }
    }
    
    /// Build a view for a modal presentation
    @ViewBuilder
    func makeModalView(for destination: NavDestination, isSheet: Bool, onDismiss: @escaping () -> Void) -> some View {
        switch destination {
        case .pdfPreview(let document):
            PDFPreviewView(document: document)
        case .addPayslip:
            let isPresented = Binding<Bool>(
                get: { true },
                set: { if !$0 { onDismiss() } }
            )
            AddPayslipSheet(isPresented: isPresented, pdfManager: pdfManager)
        case .scanner:
            PayslipScannerView()
        case .privacyPolicy:
            NavigationView {
                Text("Privacy Policy Content")
                    .padding()
                    .navigationTitle("Privacy Policy")
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Done") {
                                onDismiss()
                            }
                        }
                    }
            }
        case .termsOfService:
            NavigationView {
                Text("Terms of Service Content")
                    .padding()
                    .navigationTitle("Terms of Service")
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Done") {
                                onDismiss()
                            }
                        }
                    }
            }
        default:
            Text("Modal not implemented")
                .padding()
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
    let destination: NavDestination
    
    var body: some View {
        Text("Mock destination: \(destination.id)")
            .padding()
    }
}

struct MockModalView: View {
    let destination: NavDestination
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
    func makeDestinationView(for destination: NavDestination) -> MockDestinationView {
        MockDestinationView(destination: destination)
    }
    
    func makeModalView(for destination: NavDestination, isSheet: Bool, onDismiss: @escaping () -> Void) -> MockModalView {
        MockModalView(destination: destination, isSheet: isSheet, onDismiss: onDismiss)
    }
}
*/ 