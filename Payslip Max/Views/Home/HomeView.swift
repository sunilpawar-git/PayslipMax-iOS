import SwiftUI
import SwiftData

@MainActor
struct HomeView: View {
    @Query(sort: \PayslipItem.id) private var items: [PayslipItem]
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel: HomeViewModel
    @EnvironmentObject private var router: NavRouter
    
    init() {
        let pdfManager = PDFUploadManager()
        let viewModel = HomeViewModel(pdfManager: pdfManager)
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Welcome Header
                if let latestItem = items.last {
                    WelcomeHeader(item: latestItem)
                }
                
                // Upload Section
                Button {
                    router.showAddPayslip()
                } label: {
                    UploadSection()
                }
                
                // Financial Overview
                ChartsSection(items: items)
                
                // Recent Payslips List
                if !items.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Recent Payslips")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        ForEach(items.suffix(3)) { item in
                            Button {
                                router.showPayslipDetail(id: item.id)
                            } label: {
                                PayslipRow(payslip: item)
                                    .padding(.horizontal)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        
                        Button("View All") {
                            router.switchTab(to: 1) // Switch to Payslips tab
                        }
                        .font(.footnote.bold())
                        .padding(.top, 4)
                        .padding(.horizontal)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical)
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .padding(.horizontal)
                }
            }
            .padding(.top)
        }
        .navigationTitle("Home")
    }
}

// MARK: - Subviews
private struct WelcomeHeader: View {
    let item: PayslipItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Welcome, \(item.name)")
                .font(.title)
                .bold()
            
            Text("PCDA (O) Account No: \(item.accountNumber)")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text("PAN: \(item.panNumber)")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal)
    }
}

private struct AddPayslipButton: View {
    @Binding var showingSheet: Bool
    
    var body: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                Button(action: {
                    showingSheet = true
                }) {
                    Image(systemName: "plus")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(width: 56, height: 56)
                        .background(
                            Circle()
                                .fill(Color.blue)
                                .shadow(radius: 4)
                        )
                }
                .padding(.trailing, 20)
                .padding(.bottom, 20)
            }
        }
    }
} 