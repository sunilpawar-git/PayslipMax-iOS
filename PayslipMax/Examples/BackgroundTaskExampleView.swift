import SwiftUI
import UniformTypeIdentifiers

/// Example view demonstrating the use of the BackgroundTaskCoordinator with TaskPriorityQueue
struct BackgroundTaskExampleView: View {
    @StateObject private var viewModel = BackgroundTaskExampleViewModel()
    @State private var showingFilePicker = false
    
    var body: some View {
        mainView(viewModel: viewModel)
    }
    
    private func mainView(viewModel: BackgroundTaskExampleViewModel) -> some View {
        VStack(spacing: 20) {
            // Header
            Text("Background Task Processing Demo")
                .font(.title)
                .padding(.top)
            
            // Overall progress
            VStack(alignment: .leading) {
                Text("Overall Progress: \(Int(viewModel.overallProgress * 100))%")
                    .font(.headline)
                
                ProgressView(value: viewModel.overallProgress)
                    .progressViewStyle(LinearProgressViewStyle())
                    .frame(height: 10)
                
                Text(viewModel.statusMessage)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(10)
            .shadow(radius: 2)
            .padding(.horizontal)
            
            // Task list
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(Array(viewModel.taskStatuses.values).sorted { $0.name < $1.name }) { taskInfo in
                        TaskInfoRow(taskInfo: taskInfo)
                    }
                }
                .padding(.horizontal)
            }
            
            // Action buttons
            HStack(spacing: 20) {
                Button(action: {
                    showingFilePicker = true
                }) {
                    Label("Select PDFs", systemImage: "doc.badge.plus")
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                
                Button(action: {
                    Task {
                        await viewModel.cancelAllTasks()
                    }
                }) {
                    Label("Cancel All", systemImage: "xmark.circle")
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .disabled(!viewModel.isProcessing)
            }
            .padding()
        }
        .padding()
        .sheet(isPresented: $showingFilePicker) {
            ExampleDocumentPicker(contentTypes: [.pdf]) { urls in
                Task {
                    await viewModel.processMultiplePDFs(urls: urls)
                }
            }
        }
    }
}

/// Row displaying information about a single task
struct TaskInfoRow: View {
    let taskInfo: TaskInfo
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text(taskInfo.name)
                    .font(.headline)
                
                Spacer()
                
                PriorityBadge(priority: taskInfo.priority)
            }
            
            ProgressView(value: taskInfo.progress)
                .progressViewStyle(LinearProgressViewStyle())
                .frame(height: 8)
            
            HStack {
                Text(taskInfo.status)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("\(Int(taskInfo.progress * 100))%")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(10)
    }
}

/// Badge displaying the priority level
struct PriorityBadge: View {
    let priority: ExampleTaskPriority
    
    var body: some View {
        Text(priorityString)
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(priorityColor)
            .foregroundColor(.white)
            .cornerRadius(8)
    }
    
    private var priorityString: String {
        switch priority {
        case .low: return "Low"
        case .medium: return "Medium"
        case .high: return "High"
        case .background: return "Background"
        }
    }
    
    private var priorityColor: Color {
        switch priority {
        case .low: return .gray
        case .medium: return .orange
        case .high: return .red
        case .background: return .blue
        }
    }
}

/// Document picker for selecting files
struct ExampleDocumentPicker: UIViewControllerRepresentable {
    let contentTypes: [UTType]
    let completion: ([URL]) -> Void
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: contentTypes)
        picker.allowsMultipleSelection = true
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let parent: ExampleDocumentPicker
        
        init(_ parent: ExampleDocumentPicker) {
            self.parent = parent
        }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            parent.completion(urls)
        }
    }
} 