import SwiftUI

/// View extension to add a debug menu in settings
struct DebugSettingView: View {
    @AppStorage("debug_mode_enabled") private var debugModeEnabled = false
    @State private var showingDebugMenu = false
    @State private var tapCount = 0
    
    var body: some View {
        #if DEBUG
        Section(header: Text("Developer Options")) {
            Toggle("Debug Mode", isOn: $debugModeEnabled)
            
            if debugModeEnabled {
                Button("Open Debug Menu") {
                    showingDebugMenu = true
                }
            }
            
            // Hidden developer mode activator - tap 7 times to reveal
            Text("App Version: 1.0.0")
                .foregroundStyle(.secondary)
                .font(.footnote)
                .onTapGesture {
                    tapCount += 1
                    
                    if tapCount >= 7 && !debugModeEnabled {
                        tapCount = 0
                        debugModeEnabled = true
                    }
                    
                    // Reset tap count after 3 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        tapCount = 0
                    }
                }
        }
        .sheet(isPresented: $showingDebugMenu) {
            // If we have the debug menu view ready:
            DebugMenuView()
            
            // Otherwise use a simple placeholder:
            /*
            NavigationView {
                List {
                    NavigationLink("Deep Link Tester") {
                        DeepLinkTestView()
                    }
                    
                    NavigationLink("Deep Link Demo") {
                        DeepLinkDemoView()
                    }
                }
                .navigationTitle("Debug Menu")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") {
                            showingDebugMenu = false
                        }
                    }
                }
            }
            */
        }
        #else
        // Expose developer options during UI tests even in non-DEBUG builds
        if ProcessInfo.processInfo.arguments.contains("UI_TESTING") {
            Section(header: Text("Developer Options")) {
                Button("Open Debug Menu") {
                    showingDebugMenu = true
                }
            }
            .sheet(isPresented: $showingDebugMenu) {
                DebugMenuView()
            }
        }
        #endif
    }
}

#Preview {
    List {
        DebugSettingView()
    }
} 