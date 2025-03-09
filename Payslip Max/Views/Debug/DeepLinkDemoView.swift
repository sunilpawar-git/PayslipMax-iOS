import SwiftUI

/// A wrapper struct for identifiable string values
struct SheetIdentifier: Identifiable {
    let id = UUID()
    let title: String
    
    init(_ title: String) {
        self.title = title
    }
}

/// A demonstration view to show how deep linking works
struct DeepLinkDemoView: View {
    @State private var showingInfo = false
    @State private var selectedTab = 0
    @State private var navigationPath = NavigationPath()
    @State private var sheet: SheetIdentifier?
    
    // Simulate deep link handling
    @State private var deepLinkLog: [String] = []
    
    var body: some View {
        VStack {
            // Mock tab bar to show tab switching
            TabView(selection: $selectedTab) {
                NavigationStack(path: $navigationPath) {
                    List {
                        Text("Home Tab")
                            .font(.title)
                            .padding()
                            
                        ForEach(deepLinkLog, id: \.self) { entry in
                            Text(entry)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .navigationTitle("Deep Link Demo")
                }
                .tabItem {
                    Label("Home", systemImage: "house")
                }
                .tag(0)
                
                Text("Payslips Tab")
                    .tabItem {
                        Label("Payslips", systemImage: "doc.text")
                    }
                    .tag(1)
                
                Text("Insights Tab")
                    .tabItem {
                        Label("Insights", systemImage: "chart.bar")
                    }
                    .tag(2)
                
                Text("Settings Tab")
                    .tabItem {
                        Label("Settings", systemImage: "gear")
                    }
                    .tag(3)
            }
            
            Divider()
            
            // Deep link buttons
            VStack(spacing: 10) {
                Text("Test Deep Links")
                    .font(.headline)
                
                HStack {
                    Button("Home") {
                        simulateDeepLink(path: "/home")
                    }
                    .buttonStyle(.bordered)
                    
                    Button("Payslips") {
                        simulateDeepLink(path: "/payslips")
                    }
                    .buttonStyle(.bordered)
                    
                    Button("Insights") {
                        simulateDeepLink(path: "/insights")
                    }
                    .buttonStyle(.bordered)
                    
                    Button("Settings") {
                        simulateDeepLink(path: "/settings")
                    }
                    .buttonStyle(.bordered)
                }
                
                HStack {
                    Button("Payslip Detail") {
                        let uuid = UUID()
                        simulateDeepLink(path: "/payslip", queryItems: [URLQueryItem(name: "id", value: uuid.uuidString)])
                    }
                    .buttonStyle(.bordered)
                    
                    Button("Privacy") {
                        simulateDeepLink(path: "/privacy")
                    }
                    .buttonStyle(.bordered)
                    
                    Button("Terms") {
                        simulateDeepLink(path: "/terms")
                    }
                    .buttonStyle(.bordered)
                }
                
                Button("Show Info") {
                    showingInfo = true
                }
                .buttonStyle(.bordered)
            }
            .padding()
        }
        .sheet(isPresented: $showingInfo) {
            VStack(alignment: .leading, spacing: 20) {
                Text("Deep Linking Demo")
                    .font(.title)
                    .bold()
                
                Text("This demo simulates how deep linking works in the app. When a deep link is received, the app would:")
                    .font(.body)
                
                VStack(alignment: .leading, spacing: 10) {
                    Text("1. Parse the URL")
                    Text("2. Extract the path and query parameters")
                    Text("3. Navigate to the appropriate screen")
                }
                .padding(.leading)
                
                Text("In a real implementation, the app would use the navigation router to handle the navigation.")
                    .font(.body)
                
                Spacer()
                
                Button("Dismiss") {
                    showingInfo = false
                }
                .frame(maxWidth: .infinity)
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
        .sheet(item: $sheet) { sheetType in
            VStack {
                Text(sheetType.title)
                    .font(.title)
                    .padding()
                
                Button("Dismiss") {
                    sheet = nil
                }
                .buttonStyle(.bordered)
            }
            .padding()
        }
    }
    
    // Simulate deep link handling
    private func simulateDeepLink(path: String, queryItems: [URLQueryItem] = []) {
        // Build the URL string for logging
        var url = "payslipmax://\(path)"
        
        if !queryItems.isEmpty {
            url += "?"
            url += queryItems.map { "\($0.name)=\($0.value ?? "")" }.joined(separator: "&")
        }
        
        logDeepLink("Received deep link: \(url)")
        
        // Simulate handling
        switch path {
        case "/home":
            logDeepLink("Switching to Home tab")
            selectedTab = 0
            
        case "/payslips":
            logDeepLink("Switching to Payslips tab")
            selectedTab = 1
            
        case "/insights":
            logDeepLink("Switching to Insights tab")
            selectedTab = 2
            
        case "/settings":
            logDeepLink("Switching to Settings tab")
            selectedTab = 3
            
        case "/payslip":
            if let idString = queryItems.first(where: { $0.name == "id" })?.value {
                logDeepLink("Navigating to payslip detail with ID: \(idString)")
                selectedTab = 1 // Switch to payslips tab
                navigationPath.append("PayslipDetail-\(idString)")
            }
            
        case "/privacy":
            logDeepLink("Opening Privacy Policy sheet")
            sheet = SheetIdentifier("Privacy Policy")
            
        case "/terms":
            logDeepLink("Opening Terms of Service sheet")
            sheet = SheetIdentifier("Terms of Service")
            
        default:
            logDeepLink("Unknown deep link path: \(path)")
        }
    }
    
    private func logDeepLink(_ message: String) {
        deepLinkLog.insert(message, at: 0)
        if deepLinkLog.count > 10 {
            deepLinkLog.removeLast()
        }
    }
}

#Preview {
    DeepLinkDemoView()
} 