import Foundation
import Combine
import SwiftUI

class TaskDependencyViewModel: ObservableObject {
    @Published var tasks: [TaskInfo] = []
    @Published var isProcessing: Bool = false
    @Published var overallProgress: Double = 0.0
    @Published var statusMessage: String = "Ready to process tasks"
    
    private var cancellables = Set<AnyCancellable>()
    private var processingQueue = DispatchQueue(label: "com.payslipmax.taskprocessing", qos: .userInitiated, attributes: .concurrent)
    private var taskCancelled: [String: Bool] = [:]
    private var processQueue = DispatchQueue(label: "com.payslipmax.fileprocessing", qos: .userInitiated)
    
    init() {
        setupSampleTasks()
    }
    
    private func setupSampleTasks() {
        tasks = [
            TaskInfo(id: "task1", name: "Parse PDF Document", priority: .high),
            TaskInfo(id: "task2", name: "Extract Payslip Data", priority: .high, dependencies: ["task1"]),
            TaskInfo(id: "task3", name: "Calculate Tax Information", priority: .medium, dependencies: ["task2"]),
            TaskInfo(id: "task4", name: "Format Results", priority: .medium, dependencies: ["task3"]),
            TaskInfo(id: "task5", name: "Generate Report", priority: .low, dependencies: ["task4"]),
            TaskInfo(id: "task6", name: "Cache Results", priority: .background, dependencies: ["task2"]),
            TaskInfo(id: "task7", name: "Backup Data", priority: .background, dependencies: ["task5", "task6"])
        ]
    }
    
    func processSelectedFile(url: URL) {
        processQueue.async {
            self.processFile(url: url)
        }
    }
    
    private func processFile(url: URL) {
        // This would typically be an async method, but for demonstration purposes we're using a queue
        DispatchQueue.main.async {
            self.isProcessing = true
            self.statusMessage = "Processing file..."
            
            // Reset all tasks to initial state
            for index in self.tasks.indices {
                self.tasks[index].status = "Waiting"
                self.tasks[index].progress = 0.0
            }
            
            // Reset cancellation flags
            self.taskCancelled = [:]
        }
        
        // Create a dependency graph
        let taskGraph = buildTaskDependencyGraph()
        
        // Get tasks with no dependencies to start with
        let startingTasks = tasks.filter { $0.dependencies.isEmpty }
        
        // Start processing tasks
        for task in startingTasks {
            processTask(task, taskGraph: taskGraph)
        }
    }
    
    private func buildTaskDependencyGraph() -> [String: [String]] {
        var graph: [String: [String]] = [:]
        
        // Initialize empty dependents lists for all tasks
        for task in tasks {
            graph[task.id] = []
        }
        
        // Build the reverse dependency graph (which tasks depend on which)
        for task in tasks {
            for dependency in task.dependencies {
                graph[dependency]?.append(task.id)
            }
        }
        
        return graph
    }
    
    private func processTask(_ task: TaskInfo, taskGraph: [String: [String]]) {
        guard let index = tasks.firstIndex(where: { $0.id == task.id }) else { return }
        
        // Initialize cancellation flag for this task
        taskCancelled[task.id] = false
        
        // Update task status
        DispatchQueue.main.async {
            self.tasks[index].status = "In Progress"
        }
        
        // Determine QoS based on priority
        let qos: DispatchQoS.QoSClass
        switch task.priority {
        case .high:
            qos = .userInteractive
        case .medium:
            qos = .userInitiated
        case .low:
            qos = .utility
        case .background:
            qos = .background
        }
        
        // Execute task on the processing queue
        processingQueue.async(qos: DispatchQoS(qosClass: qos, relativePriority: 0)) { [weak self] in
            guard let self = self else { return }
            
            // Simulate task processing with random duration between 2-5 seconds
            let totalSteps = 10
            let taskDuration = Double.random(in: 2...5)
            let stepDuration = taskDuration / Double(totalSteps)
            
            for step in 1...totalSteps {
                // Check if task was cancelled
                if self.taskCancelled[task.id] == true {
                    DispatchQueue.main.async {
                        self.tasks[index].status = "Cancelled"
                    }
                    return
                }
                
                // Update progress
                let progress = Double(step) / Double(totalSteps)
                DispatchQueue.main.async {
                    self.tasks[index].progress = progress
                    self.updateOverallProgress()
                }
                
                // Sleep to simulate work
                Thread.sleep(forTimeInterval: stepDuration)
            }
            
            // Task completed
            DispatchQueue.main.async {
                self.tasks[index].status = "Completed"
                self.tasks[index].progress = 1.0
                self.updateOverallProgress()
                
                // Process dependent tasks
                if let dependentTasks = taskGraph[task.id] {
                    for dependentTaskId in dependentTasks {
                        // Check if all dependencies for this task are completed
                        if let dependentTask = self.tasks.first(where: { $0.id == dependentTaskId }) {
                            let allDependenciesCompleted = dependentTask.dependencies.allSatisfy { dependencyId in
                                self.tasks.first(where: { $0.id == dependencyId })?.status == "Completed"
                            }
                            
                            if allDependenciesCompleted {
                                self.processTask(dependentTask, taskGraph: taskGraph)
                            }
                        }
                    }
                }
                
                // Check if all tasks are completed
                self.checkAllTasksCompleted()
            }
        }
    }
    
    private func updateOverallProgress() {
        let totalProgress = tasks.reduce(0.0) { $0 + $1.progress }
        overallProgress = totalProgress / Double(tasks.count)
    }
    
    private func checkAllTasksCompleted() {
        let allCompleted = tasks.allSatisfy { $0.status == "Completed" }
        if allCompleted {
            isProcessing = false
            statusMessage = "All tasks completed successfully!"
        }
    }
    
    func cancelAllTasks() {
        // Mark all tasks as cancelled
        for taskId in taskCancelled.keys {
            taskCancelled[taskId] = true
        }
        
        // Update status for all in-progress tasks
        DispatchQueue.main.async {
            for index in self.tasks.indices {
                if self.tasks[index].status == "In Progress" || self.tasks[index].status == "Waiting" {
                    self.tasks[index].status = "Cancelled"
                }
            }
            
            self.isProcessing = false
            self.statusMessage = "Tasks cancelled"
            self.updateOverallProgress()
        }
    }
} 