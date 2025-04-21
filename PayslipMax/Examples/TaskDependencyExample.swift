import Foundation
import Combine
import SwiftUI

/// Example showing task dependency execution with visualization
class TaskDependencyExample {
    private var processingSteps: [String: TaskInfo] = [:]
    private var isProcessing = false
    private var statusMessage = "Ready to process tasks"
    
    /// Shows the task dependency example view
    static func showExampleView() -> some View {
        TaskDependencyExampleView()
    }
    
    /// Run the example programmatically
    static func runExample() {
        let viewModel = TaskDependencyViewModel()
        viewModel.processSelectedFile(url: URL(fileURLWithPath: "/tmp/example.pdf"))
        
        // Add a delay to allow tasks to complete
        DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
            viewModel.cancelAllTasks()
        }
    }
} 