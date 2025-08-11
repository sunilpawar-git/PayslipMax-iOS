import SwiftUI
import Foundation

/// Debug menu view that provides access to developer tools
struct DebugMenuView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Deep Linking Tools")) {
                    NavigationLink(destination: DeepLinkTesterView()) {
                        Label("Deep Link Tester", systemImage: "link")
                    }
                    
                    NavigationLink(destination: DeepLinkDemoView()) {
                        Label("Deep Link Demo", systemImage: "play.fill")
                    }
                }
                
                Section(header: Text("Web Upload Testing")) {
                    Button {
                        // Test a web upload deep link
                        Task {
                            let urlString = "payslipmax://upload?id=6819ecb162f8d&filename=test.pdf&size=119688&source=web&token=eb8b7c095cf8b3babca806440ada88db&protected=false"
                            await testWebUploadDeepLink(urlString: urlString)
                        }
                    } label: {
                        Label("Test Web Upload Deep Link", systemImage: "icloud.and.arrow.down")
                    }
                    
                    NavigationLink(destination: DeepLinkTesterView()) {
                        Label("Custom Deep Link Test", systemImage: "hammer")
                    }
                }
                
                Section(header: Text("Documentation")) {
                    Button {
                        showMarkdownFile("DeepLinking.md")
                    } label: {
                        Label("Deep Linking Documentation", systemImage: "doc.text")
                    }
                    
                    Button {
                        showMarkdownFile("README.md")
                    } label: {
                        Label("Navigation System README", systemImage: "doc.text")
                    }
                }
                
                Section(header: Text("Diagnostics")) {
                    NavigationLink(destination: DiagnosticsExportView()) {
                        Label("Export Diagnostics Bundle", systemImage: "tray.and.arrow.up.fill")
                    }
                }
                
                Section(header: Text("Actions")) {
                    Button(role: .destructive) {
                        dismiss()
                    } label: {
                        Label("Close Debug Menu", systemImage: "xmark.circle")
                    }
                }
            }
            .navigationTitle("Debug Menu")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func showMarkdownFile(_ filename: String) {
        // In a real app, this would display the markdown file
        // For simplicity, we're just printing to the console
        print("Would display \(filename)")
    }
    
    // Helper method to run DeepLinkTester asynchronously
    @MainActor
    private func testWebUploadDeepLink(urlString: String) async {
        guard let url = URL(string: urlString) else {
            print("Failed to create URL from string")
            return
        }
        
        // Process the URL directly using the WebUploadDeepLinkHandler
        let coordinator = DIContainer.shared.makeWebUploadDeepLinkHandler()
        let handled = coordinator.processURL(url)
        print("Deep link handled: \(handled)")
    }
}

#Preview {
    DebugMenuView()
} 