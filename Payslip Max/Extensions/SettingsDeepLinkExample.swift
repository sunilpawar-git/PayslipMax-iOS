import SwiftUI

/// Example of how to implement deep link options in a settings view
struct SettingsDeepLinkExample: View {
    @Environment(\.openURL) private var openURL
    
    var body: some View {
        List {
            Section(header: Text("Support")) {
                Button("Privacy Policy") {
                    if let url = makeDeepLink(path: "/privacy") {
                        openURL(url)
                    }
                }
                
                Button("Terms of Service") {
                    if let url = makeDeepLink(path: "/terms") {
                        openURL(url)
                    }
                }
            }
            
            Section(header: Text("Quick Navigation")) {
                Button("Go to Home") {
                    if let url = makeDeepLink(path: "/home") {
                        openURL(url)
                    }
                }
                
                Button("Go to Payslips") {
                    if let url = makeDeepLink(path: "/payslips") {
                        openURL(url)
                    }
                }
                
                Button("Go to Insights") {
                    if let url = makeDeepLink(path: "/insights") {
                        openURL(url)
                    }
                }
            }
            
            #if DEBUG
            NavigationLink("Deep Link Tester", destination: DeepLinkTestView())
            #endif
        }
    }
    
    private func makeDeepLink(path: String, queryItems: [URLQueryItem] = []) -> URL? {
        var components = URLComponents()
        components.scheme = "payslipmax"
        components.host = ""
        components.path = path
        
        if !queryItems.isEmpty {
            components.queryItems = queryItems
        }
        
        return components.url
    }
}

#Preview {
    NavigationView {
        SettingsDeepLinkExample()
            .navigationTitle("Settings")
    }
} 