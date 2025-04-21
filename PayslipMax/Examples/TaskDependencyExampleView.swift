import SwiftUI
import Combine
import Foundation

struct TaskDependencyExampleView: View {
    @StateObject private var viewModel = TaskDependencyViewModel()
    @State private var selectedFilePath: String = ""
    
    var body: some View {
        VStack(spacing: 16) {
            headerSection
            overallProgressSection
            taskListSection
            controlSection
        }
        .padding()
        .animation(.easeInOut, value: viewModel.tasks)
        .animation(.easeInOut, value: viewModel.isProcessing)
    }
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Task Dependency Example")
                .font(.largeTitle)
                .bold()
            
            Text("This example demonstrates background processing with task dependencies")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text(viewModel.statusMessage)
                .font(.headline)
                .foregroundColor(viewModel.isProcessing ? .blue : .green)
                .padding(.top, 4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var overallProgressSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Overall Progress")
                .font(.headline)
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 20)
                    
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.blue)
                        .frame(width: max(geometry.size.width * CGFloat(viewModel.overallProgress), 0), height: 20)
                    
                    Text("\(Int(viewModel.overallProgress * 100))%")
                        .font(.caption)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
            }
            .frame(height: 20)
        }
    }
    
    private var taskListSection: some View {
        List {
            Section(header: Text("Task Dependency Graph")) {
                ForEach(viewModel.tasks) { task in
                    TaskRowView(task: task)
                }
            }
        }
        .listStyle(InsetGroupedListStyle())
        .frame(minHeight: 300)
    }
    
    private var controlSection: some View {
        HStack(spacing: 16) {
            Button(action: {
                // Simulate file selection
                selectedFilePath = "/path/to/sample/file.pdf"
                viewModel.processSelectedFile(url: URL(fileURLWithPath: selectedFilePath))
            }) {
                Text("Process Sample Tasks")
                    .fontWeight(.semibold)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .disabled(viewModel.isProcessing)
            
            Button(action: {
                viewModel.cancelAllTasks()
            }) {
                Text("Cancel")
                    .fontWeight(.semibold)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .disabled(!viewModel.isProcessing)
        }
        .padding(.vertical)
    }
}

struct TaskRowView: View {
    let task: TaskInfo
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(task.name)
                    .font(.headline)
                
                Spacer()
                
                priorityBadge
            }
            
            if !task.dependencies.isEmpty {
                Text("Dependencies: \(task.dependencies.joined(separator: ", "))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Text(task.status)
                    .font(.subheadline)
                    .foregroundColor(statusColor)
                
                Spacer()
                
                Text("\(Int(task.progress * 100))%")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 8)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(progressColor)
                        .frame(width: max(geometry.size.width * CGFloat(task.progress), 0), height: 8)
                }
            }
            .frame(height: 8)
        }
        .padding(.vertical, 4)
    }
    
    private var priorityBadge: some View {
        Text(priorityText)
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(priorityColor.opacity(0.2))
            .foregroundColor(priorityColor)
            .cornerRadius(4)
    }
    
    private var priorityText: String {
        switch task.priority {
        case .high:
            return "High"
        case .medium:
            return "Medium"
        case .low:
            return "Low"
        case .background:
            return "Background"
        }
    }
    
    private var priorityColor: Color {
        switch task.priority {
        case .high:
            return Color.red
        case .medium:
            return Color.orange
        case .low:
            return Color.blue
        case .background:
            return Color.purple
        }
    }
    
    private var statusColor: Color {
        switch task.status {
        case "Completed":
            return Color.green
        case "In Progress":
            return Color.blue
        case "Waiting":
            return Color.gray
        case "Cancelled":
            return Color.red
        default:
            return Color.primary
        }
    }
    
    private var progressColor: Color {
        switch task.status {
        case "Completed":
            return Color.green
        case "In Progress":
            return Color.blue
        case "Cancelled":
            return Color.red
        default:
            return Color.gray
        }
    }
}

struct TaskDependencyExampleView_Previews: PreviewProvider {
    static var previews: some View {
        TaskDependencyExampleView()
    }
}

// Extension to TaskDependencyExample to make properties observable
extension TaskDependencyExample {
    func publisher<T>(for keyPath: KeyPath<TaskDependencyExample, T>) -> AnyPublisher<T, Never> {
        // This is a simplified example - in a real app you would use proper publishers
        // from your model. For this example, we're simulating the behavior.
        Just(self[keyPath: keyPath]).eraseToAnyPublisher()
    }
} 