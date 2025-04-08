import SwiftUI
import PDFKit
import Charts
import Vision
import VisionKit
import UIKit

// Additional imports for extracted components
@MainActor
struct HomeView: View {
    @StateObject private var viewModel = DIContainer.shared.makeHomeViewModel()
    @State private var showingDocumentPicker = false
    @State private var showingScanner = false
    @State private var showingActionSheet = false
    
    var body: some View {
        ZStack {
            // Base background color - system background for the tab bar area
            Color(.systemBackground)
                .edgesIgnoringSafeArea(.all)
            
            // Navy blue background that extends beyond the top edge
            Color(red: 0, green: 0, blue: 0.5) // Navy blue color
                .edgesIgnoringSafeArea(.all) 
                .frame(height: UIScreen.main.bounds.height * 0.4) // Limit height to top portion
                .frame(maxHeight: .infinity, alignment: .top) // Align to top
            
            ScrollView {
                VStack(spacing: 0) {
                    // Header with Logo and Action Buttons
                    HomeHeaderView(
                        onUploadTapped: { showingDocumentPicker = true },
                        onScanTapped: { showingScanner = true },
                        onManualTapped: { viewModel.showManualEntry() }
                    )
                    
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
                        InvestmentTipsView()
                            .accessibilityIdentifier("tips_view")
                    }
                    .padding()
                    .background(Color(.systemBackground))
                }
            }
            .accessibilityIdentifier("home_scroll_view")
            .background(Color.clear) // Make ScrollView background clear
        }
        .navigationBarHidden(true) // Hide navigation bar to show our custom header
        // Apply extracted modifiers
        .homeSheetModifiers(
            viewModel: viewModel,
            showingDocumentPicker: $showingDocumentPicker,
            showingScanner: $showingScanner,
            onDocumentPicked: handleDocumentPicked
        )
        .homeNavigation(viewModel: viewModel)
        .homeActionSheet(
            showingActionSheet: $showingActionSheet,
            showingDocumentPicker: $showingDocumentPicker,
            showingScanner: $showingScanner,
            onManualEntryTapped: viewModel.showManualEntry
        )
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
        .homeTestingSetup()
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
    
    // Handle document picked from document picker
    private func handleDocumentPicked(url: URL) {
        // Process the document
        print("HomeView: Processing document from \(url.absoluteString)")
        Task {
            await viewModel.processPayslipPDF(from: url)
        }
    }
}

// MARK: - Preview

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}

// MARK: - Supporting Types
// All supporting types have been moved to their own files
// - HomeSheetModifiers
// - HomeNavigation
// - HomeActionSheet
// - HomeTestingSetup

// MARK: - Modifier to handle optional accessibility identifiers

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

// MARK: - Charts View
// ChartsView is now moved to Components/ChartsView.swift

// MARK: - Scanner View
// ScannerView is now moved to Utilities/ScannerView.swift
// struct ScannerView: UIViewControllerRepresentable {
//     let onScanCompleted: (UIImage) -> Void
//     
//     func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
//         let scanner = VNDocumentCameraViewController()
//         scanner.delegate = context.coordinator
//         return scanner
//     }
//     
//     func updateUIViewController(_ uiViewController: VNDocumentCameraViewController, context: Context) {}
//     
//     func makeCoordinator() -> Coordinator {
//         Coordinator(self)
//     }
//     
//     class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {
//         let parent: ScannerView
//         
//         init(_ parent: ScannerView) {
//             self.parent = parent
//         }
//         
//         func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentScan) {
//             guard scan.pageCount > 0 else { return }
//             let image = scan.imageOfPage(at: 0)
//             parent.onScanCompleted(image)
//             controller.dismiss(animated: true)
//         }
//         
//         func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
//             controller.dismiss(animated: true)
//         }
//         
//         func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFailWithError error: Error) {
//             ErrorLogger.log(error)
//             controller.dismiss(animated: true)
//         }
//     }
// }

// MARK: - Manual Entry View
// ManualEntryView is now moved to Components/ManualEntryView.swift

// MARK: - Payslip Countdown View

// PayslipCountdownView is now moved to its own file in Components/PayslipCountdownView.swift
// struct PayslipCountdownView: View {
//     @State private var daysRemaining: Int = 0
//     @Environment(\.colorScheme) var colorScheme
//     
//     var body: some View {
//         HStack(spacing: 16) {
//             HStack(spacing: 12) {
//                 Image(systemName: "calendar")
//                     .font(.system(size: 22, weight: .semibold))
//                     .foregroundColor(.white)
//                     .frame(width: 26)
//                 
//                 Text("Days till Next Payslip")
//                     .font(.system(size: 17, weight: .semibold))
//                     .foregroundColor(.white)
//                     .lineLimit(1)
//                     .fixedSize(horizontal: true, vertical: false)
//             }
//             
//             Spacer(minLength: 32)
//             
//             Text("\(daysRemaining) Days")
//                 .font(.system(size: 17, weight: .bold))
//                 .foregroundColor(.white)
//                 .lineLimit(1)
//                 .fixedSize(horizontal: true, vertical: false)
//         }
//         .padding(.vertical, 16)
//         .padding(.horizontal, 24)
//         .frame(maxWidth: .infinity, minHeight: 56)
//         .background(
//             RoundedRectangle(cornerRadius: 14)
//                 .fill(
//                     LinearGradient(
//                         gradient: Gradient(colors: [
//                             Color(red: 0.2, green: 0.5, blue: 1.0),
//                             Color(red: 0.3, green: 0.6, blue: 1.0)
//                         ]),
//                         startPoint: .leading,
//                         endPoint: .trailing
//                     )
//                 )
//                 .shadow(color: Color.black.opacity(0.15), radius: 5, x: 0, y: 2)
//         )
//         .onAppear {
//             updateDaysRemaining()
//         }
//     }
//     
//     private func updateDaysRemaining() {
//         let calendar = Calendar.current
//         let now = Date()
//         
//         // Get the current month's last day
//         guard let lastDayOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: calendar.startOfDay(for: now))),
//               let lastDay = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: lastDayOfMonth) else {
//             return
//         }
//         
//         // Calculate days remaining
//         if let days = calendar.dateComponents([.day], from: now, to: lastDay).day {
//             daysRemaining = max(days + 1, 0) // Add 1 to include the current day
//         }
//         
//         // Set up a timer to update daily
//         Timer.scheduledTimer(withTimeInterval: 86400, repeats: true) { _ in // 86400 seconds = 24 hours
//             updateDaysRemaining()
//         }
//     }
// } 
