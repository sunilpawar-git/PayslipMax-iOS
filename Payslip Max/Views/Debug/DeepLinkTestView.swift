import SwiftUI

/// A debug view for testing deep links
struct DeepLinkTestView: View {
    @State private var customPath = "/home"
    @State private var customParams = ""
    @State private var payslipId = UUID().uuidString
    @State private var lastTestedURL = ""
    @Environment(\.openURL) private var openURL
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Last Tested URL")) {
                    Text(lastTestedURL.isEmpty ? "None" : lastTestedURL)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Section(header: Text("Main Navigation")) {
                    Button("Open Home") {
                        openDeepLink(path: "/home")
                    }
                    
                    Button("Open Payslips") {
                        openDeepLink(path: "/payslips")
                    }
                    
                    Button("Open Insights") {
                        openDeepLink(path: "/insights")
                    }
                    
                    Button("Open Settings") {
                        openDeepLink(path: "/settings")
                    }
                }
                
                Section(header: Text("Modal Sheets")) {
                    Button("Open Privacy Policy") {
                        openDeepLink(path: "/privacy")
                    }
                    
                    Button("Open Terms of Service") {
                        openDeepLink(path: "/terms")
                    }
                }
                
                Section(header: Text("Detail Views")) {
                    TextField("Payslip UUID", text: $payslipId)
                    
                    Button("Open Payslip Detail") {
                        openDeepLink(path: "/payslip", queryItems: [
                            URLQueryItem(name: "id", value: payslipId)
                        ])
                    }
                }
                
                Section(header: Text("Custom Deep Link")) {
                    TextField("Path (e.g. /home)", text: $customPath)
                    
                    TextField("Query params (e.g. id=123&type=test)", text: $customParams)
                    
                    Button("Open Custom Deep Link") {
                        let queryItems = parseQueryParams(customParams)
                        openDeepLink(path: customPath, queryItems: queryItems)
                    }
                }
            }
            .navigationTitle("Deep Link Tester")
        }
    }
    
    private func openDeepLink(path: String, queryItems: [URLQueryItem] = []) {
        var components = URLComponents()
        
        components.scheme = "payslipmax"
        components.host = ""
        components.path = path
        
        if !queryItems.isEmpty {
            components.queryItems = queryItems
        }
        
        guard let url = components.url else { return }
        
        lastTestedURL = url.absoluteString
        print("Testing deep link: \(url.absoluteString)")
        
        // Use the SwiftUI openURL environment value
        openURL(url)
    }
    
    private func parseQueryParams(_ queryString: String) -> [URLQueryItem] {
        let pairs = queryString.components(separatedBy: "&")
        return pairs.compactMap { pair -> URLQueryItem? in
            let components = pair.components(separatedBy: "=")
            guard components.count == 2,
                  let key = components.first,
                  let value = components.last,
                  !key.isEmpty else {
                return nil
            }
            return URLQueryItem(name: key, value: value)
        }
    }
}

#Preview {
    DeepLinkTestView()
} 