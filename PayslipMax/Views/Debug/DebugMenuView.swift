import SwiftUI

/// Debug menu view that provides access to developer tools
struct DebugMenuView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Deep Linking Tools")) {
                    NavigationLink(destination: DeepLinkTestView()) {
                        Label("Deep Link Tester", systemImage: "link")
                    }
                    
                    NavigationLink(destination: DeepLinkDemoView()) {
                        Label("Deep Link Demo", systemImage: "play.fill")
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
}

#Preview {
    DebugMenuView()
} 