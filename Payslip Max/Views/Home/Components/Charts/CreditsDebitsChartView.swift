import SwiftUI
import Charts

struct CreditsDebitsChartView: View {
    let items: [PayslipItem]
    @State private var selectedItem: PayslipItem?
    
    var body: some View {
        VStack {
            Chart {
                ForEach(items.prefix(6)) { item in
                    // Credits Bar
                    BarMark(
                        x: .value("Month", item.month),
                        y: .value("Amount", item.credits)
                    )
                    .foregroundStyle(.green)
                    .annotation {
                        if selectedItem?.id == item.id {
                            Text("₹\(item.credits, specifier: "%.0f")")
                        }
                    }
                    
                    // Debits Bar
                    BarMark(
                        x: .value("Month", item.month),
                        y: .value("Amount", -item.debits)
                    )
                    .foregroundStyle(.red)
                    .annotation {
                        if selectedItem?.id == item.id {
                            Text("-₹\(item.debits, specifier: "%.0f")")
                        }
                    }
                }
            }
            .chartOverlay { proxy in
                GeometryReader { geometry in
                    Rectangle().fill(.clear).contentShape(Rectangle())
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    let currentX = value.location.x - geometry.frame(in: .local).origin.x
                                    guard currentX >= 0, currentX < geometry.size.width else { return }
                                    
                                    let xScale = geometry.size.width / CGFloat(items.prefix(6).count)
                                    let index = Int(currentX / xScale)
                                    guard index < items.prefix(6).count else { return }
                                    selectedItem = Array(items.prefix(6))[index]
                                }
                                .onEnded { _ in
                                    selectedItem = nil
                                }
                        )
                }
            }
            .frame(height: 200)
            
            // Summary
            if let selected = selectedItem {
                HStack {
                    VStack(alignment: .leading) {
                        Text(selected.month)
                            .font(.headline)
                        Text("Net: ₹\(selected.credits - selected.debits, specifier: "%.0f")")
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
                .padding(.horizontal)
            }
        }
    }
} 