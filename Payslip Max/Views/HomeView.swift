import SwiftUI

/// View model for the home screen
class HomeViewModel: ObservableObject {
    /// PDF upload manager
    private let pdfManager: PDFUploadManager
    
    /// Initializes a new home view model
    /// - Parameter pdfManager: The PDF upload manager
    init(pdfManager: PDFUploadManager) {
        self.pdfManager = pdfManager
    }
}

/// PDF upload manager for handling PDF files
class PDFUploadManager {
    /// Uploads a PDF file
    /// - Parameter url: The URL of the PDF file
    /// - Returns: Success indicator
    func uploadPDF(from url: URL) async throws -> Bool {
        // Placeholder implementation
        return true
    }
}

/// Home view displaying recent payslips and actions
struct HomeView: View {
    /// View model for the home screen
    @ObservedObject var viewModel: HomeViewModel
    
    /// Navigation router
    @EnvironmentObject private var router: NavRouter
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                Text("Welcome to Payslip Max")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                Spacer()
            }
            .padding(.horizontal)
            
            // Quick actions
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    quickActionButton(
                        title: "Add Payslip",
                        systemImage: "plus.circle",
                        color: .blue
                    ) {
                        router.showAddPayslip()
                    }
                    
                    quickActionButton(
                        title: "Scan Document",
                        systemImage: "doc.text.viewfinder",
                        color: .green
                    ) {
                        router.presentSheet(.scanner)
                    }
                    
                    quickActionButton(
                        title: "View Insights",
                        systemImage: "chart.bar",
                        color: .orange
                    ) {
                        router.switchTab(to: 2)
                    }
                    
                    quickActionButton(
                        title: "Settings",
                        systemImage: "gear",
                        color: .gray
                    ) {
                        router.switchTab(to: 3)
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
            
            // Recent payslips section
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Recent Payslips")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    Button("See All") {
                        router.switchTab(to: 1)
                    }
                    .foregroundColor(.blue)
                }
                
                // Placeholder for recent payslips
                ForEach(0..<3) { index in
                    recentPayslipRow(index: index)
                }
            }
            .padding(.horizontal)
            
            Spacer()
        }
        .padding(.top)
        .navigationTitle("Home")
    }
    
    /// Creates a quick action button
    /// - Parameters:
    ///   - title: The button title
    ///   - systemImage: The system image name
    ///   - color: The button color
    ///   - action: The action to perform when tapped
    /// - Returns: A button view
    private func quickActionButton(
        title: String,
        systemImage: String,
        color: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: systemImage)
                    .font(.system(size: 30))
                    .foregroundColor(.white)
                    .frame(width: 60, height: 60)
                    .background(color)
                    .clipShape(Circle())
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(width: 100)
        }
    }
    
    /// Creates a recent payslip row
    /// - Parameter index: The row index
    /// - Returns: A row view
    private func recentPayslipRow(index: Int) -> some View {
        let dates = [
            "May 2023",
            "April 2023",
            "March 2023"
        ]
        
        let amounts = [
            "$3,250.00",
            "$3,250.00",
            "$3,100.00"
        ]
        
        return Button(action: {
            // Navigate to payslip detail
            router.navigate(to: .payslipDetail(id: UUID()))
        }) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Monthly Salary")
                        .font(.headline)
                    
                    Text(dates[index])
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Text(amounts[index])
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(10)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    NavigationStack {
        HomeView(viewModel: HomeViewModel(pdfManager: PDFUploadManager()))
            .environmentObject(NavRouter())
    }
} 