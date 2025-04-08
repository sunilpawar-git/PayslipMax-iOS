import SwiftUI

/// A view for displaying and categorizing unknown payslip components
struct UnknownComponentsView: View {
    @ObservedObject var viewModel: PayslipDetailViewModel
    
    var body: some View {
        if !viewModel.unknownComponents.isEmpty {
            VStack(alignment: .leading, spacing: 16) {
                Text("New Components Detected")
                    .font(.headline)
                
                ForEach(Array(viewModel.unknownComponents.keys), id: \.self) { code in
                    if let (amount, category) = viewModel.unknownComponents[code] {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(code)
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                
                                Text("₹\(String(format: "%.2f", amount))")
                                    .font(.caption)
                            }
                            
                            Spacer()
                            
                            HStack {
                                Button(action: {
                                    viewModel.userCategorizedComponent(code: code, asCategory: "earnings")
                                }) {
                                    Text("Earnings")
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(category == "earnings" ? Color.green.opacity(0.2) : Color.gray.opacity(0.1))
                                        .cornerRadius(4)
                                }
                                
                                Button(action: {
                                    viewModel.userCategorizedComponent(code: code, asCategory: "deductions")
                                }) {
                                    Text("Deductions")
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(category == "deductions" ? Color.red.opacity(0.2) : Color.gray.opacity(0.1))
                                        .cornerRadius(4)
                                }
                            }
                        }
                        .padding()
                        .background(Color.gray.opacity(0.05))
                        .cornerRadius(8)
                    }
                }
            }
            .padding()
            .background(Color.yellow.opacity(0.1))
            .cornerRadius(12)
            .padding(.horizontal)
        }
    }
} 