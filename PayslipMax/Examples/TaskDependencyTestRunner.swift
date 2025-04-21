import SwiftUI

/// Test runner to help with testing our task dependency example
struct TaskDependencyTestRunner: View {
    var body: some View {
        TaskDependencyExampleView()
    }
    
    /// Run the example programmatically
    static func run() {
        TaskDependencyExample.runExample()
    }
} 