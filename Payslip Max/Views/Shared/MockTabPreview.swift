import SwiftUI

/// A mock tab view that doesn't depend on any external components
/// Useful for debugging when the real MainTabView preview isn't working
struct MockTabPreview: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Home Tab
            NavigationStack {
                Text("Home View")
                    .font(.largeTitle)
                    .padding()
            }
            .tabItem {
                Label("Home", systemImage: "house.fill")
            }
            .tag(0)
            
            // Payslips Tab
            NavigationStack {
                Text("Payslips View")
                    .font(.largeTitle)
                    .padding()
                    .navigationTitle("Payslips")
            }
            .tabItem {
                Label("Payslips", systemImage: "doc.text.fill")
            }
            .tag(1)
            
            // Insights Tab
            NavigationStack {
                Text("Insights View")
                    .font(.largeTitle)
                    .padding()
                    .navigationTitle("Insights")
            }
            .tabItem {
                Label("Insights", systemImage: "chart.bar.fill")
            }
            .tag(2)
            
            // Settings Tab
            NavigationStack {
                Text("Settings View")
                    .font(.largeTitle)
                    .padding()
                    .navigationTitle("Settings")
            }
            .tabItem {
                Label("Settings", systemImage: "gear")
            }
            .tag(3)
        }
    }
}

#Preview("Mock Tab View") {
    MockTabPreview()
}

#Preview("Mock Tab View - Dark") {
    MockTabPreview()
        .environment(\.colorScheme, .dark)
} 