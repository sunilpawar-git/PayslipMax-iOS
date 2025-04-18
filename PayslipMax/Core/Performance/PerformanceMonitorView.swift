import SwiftUI
import Foundation

/// A view that displays performance metrics for the app
struct PerformanceMonitorView: View {
    @ObservedObject private var metrics = PerformanceMetrics.shared
    @ObservedObject private var viewTracker = ViewPerformanceTracker.shared
    @State private var selectedTab = 0
    @State private var showingDetailedReport = false
    @State private var reportText = ""
    
    var body: some View {
        List {
            Section(header: Text("Current Performance")) {
                PerformanceStatView(
                    title: "FPS",
                    value: String(format: "%.1f", metrics.currentFPS),
                    description: "Current frames per second"
                )
                
                PerformanceStatView(
                    title: "Memory Usage",
                    value: formatBytes(metrics.memoryUsage),
                    description: "Current memory consumption"
                )
                
                PerformanceStatView(
                    title: "CPU Usage",
                    value: String(format: "%.1f%%", metrics.cpuUsage),
                    description: "Current CPU utilization"
                )
            }
            
            Section(header: Text("View Rendering Metrics")) {
                // Filter the top 5 views by render time
                ForEach(viewTracker.renderHistory.keys.sorted(by: { viewName1, viewName2 in
                    let metrics1 = viewTracker.metricsForView(viewName1)
                    let metrics2 = viewTracker.metricsForView(viewName2)
                    return metrics1.totalRenderTime > metrics2.totalRenderTime
                }).prefix(5), id: \.self) { viewName in
                    let viewMetrics = viewTracker.metricsForView(viewName)
                    let avgRenderTime = viewMetrics.totalRenderCount > 0 
                        ? viewMetrics.totalRenderTime / Double(viewMetrics.totalRenderCount) 
                        : 0
                    
                    HStack {
                        VStack(alignment: .leading) {
                            Text(viewName)
                                .font(.headline)
                            Text("Renders: \(viewMetrics.totalRenderCount)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing) {
                            Text("\(String(format: "%.2f", avgRenderTime * 1000)) ms")
                                .font(.headline)
                            Text("Avg. Render Time")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            
            Section(header: Text("View Redraw Counts")) {
                // Show top 5 views by redraw count
                ForEach(metrics.viewRedrawCounts.sorted { $0.value > $1.value }.prefix(5), id: \.key) { viewName, count in
                    HStack {
                        Text(viewName)
                        Spacer()
                        Text("\(count) redraws")
                            .foregroundColor(count > 10 ? .red : .primary)
                    }
                }
            }
            
            Section(header: Text("Time to First Render")) {
                // Show top 5 slowest initial renders
                ForEach(metrics.timeToFirstRender.sorted { $0.value > $1.value }.prefix(5), id: \.key) { viewName, time in
                    HStack {
                        Text(viewName)
                        Spacer()
                        Text("\(String(format: "%.2f", time * 1000)) ms")
                            .foregroundColor(time > 0.1 ? .red : .primary)
                    }
                }
            }
            
            Section {
                Button("View Detailed Report") {
                    generateReport()
                    showingDetailedReport = true
                }
                
                Button("Reset Performance Data") {
                    metrics.resetMetrics()
                    viewTracker.resetAllTracking()
                }
                .foregroundColor(.red)
            }
        }
        .navigationTitle("Performance Monitor")
        .sheet(isPresented: $showingDetailedReport) {
            NavigationView {
                ScrollView {
                    VStack(alignment: .leading) {
                        Text(reportText)
                            .font(.system(.body, design: .monospaced))
                            .padding()
                    }
                }
                .navigationTitle("Detailed Report")
                .navigationBarItems(trailing: Button("Close") {
                    showingDetailedReport = false
                })
            }
        }
        .onAppear {
            metrics.startMonitoring()
        }
    }
    
    private func generateReport() {
        var report = metrics.getPerformanceReport()
        report += "\n\n" + viewTracker.generateReport()
        reportText = report
    }
    
    private func formatBytes(_ bytes: UInt64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useAll]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytes))
    }
}

/// A view for displaying a single performance statistic
struct PerformanceStatView: View {
    let title: String
    let value: String
    let description: String
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(value)
                .font(.system(.title3, design: .monospaced))
                .fontWeight(.bold)
        }
        .padding(.vertical, 4)
    }
}

struct PerformanceMonitorView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            PerformanceMonitorView()
        }
    }
} 