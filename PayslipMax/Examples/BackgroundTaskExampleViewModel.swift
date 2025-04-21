import Foundation
import Combine
import SwiftUI

/// Example view model demonstrating how to use the BackgroundTaskCoordinator with TaskPriorityQueue
@MainActor
class BackgroundTaskExampleViewModel: ObservableObject {
    // MARK: - Properties
    
    /// Background task coordinator for managing tasks
    private var taskCoordinator: BackgroundTaskCoordinator
    
    /// Progress and status information for all tasks
    @Published var taskStatuses: [TaskIdentifier: TaskInfo] = [:]
    
    /// Overall progress across all tasks (0.0 to 1.0)
    @Published var overallProgress: Double = 0.0
    
    /// Status message for the current operation
    @Published var statusMessage: String = "Ready"
    
    /// Whether any tasks are currently running
    @Published var isProcessing: Bool = false
    
    /// Cancellables for subscription management
    private var cancellables = Set<AnyCancellable>()
    
    /// Aggregate progress reporter for combined progress
    private let progressReporter = AggregateProgressReporter()
    
    // MARK: - Initialization
    
    init(taskCoordinator: BackgroundTaskCoordinator? = nil) {
        if let coordinator = taskCoordinator {
            self.taskCoordinator = coordinator
        } else {
            // Use BackgroundTaskCoordinator.shared as a placeholder initially
            self.taskCoordinator = BackgroundTaskCoordinator.shared
            
            // Use DI to get the taskCoordinator on the main thread
            Task { @MainActor in
                self.taskCoordinator = DIContainer.shared.makeBackgroundTaskCoordinator()
                // Setup subscriptions after getting the coordinator
                self.setupSubscriptions()
            }
        }
    }
    
    // MARK: - Public Methods
    
    /// Process multiple PDFs with proper priority handling
    /// - Parameter urls: Array of PDF URLs to process
    func processMultiplePDFs(urls: [URL]) async {
        guard !urls.isEmpty else {
            statusMessage = "No PDFs to process"
            return
        }
        
        isProcessing = true
        statusMessage = "Starting to process \(urls.count) PDFs"
        
        do {
            // Create a task for each PDF with appropriate priority
            var taskIds: [TaskIdentifier] = []
            
            for (index, url) in urls.enumerated() {
                // Assign priority based on position (first ones get higher priority)
                let priority: TaskPriority = index < 2 ? .high : (index < 5 ? .medium : .low)
                
                // Create a unique progress reporter for this task
                let taskReporter = ProgressReporter()
                
                // Create the task with the coordinator
                let taskId = try await taskCoordinator.createTask(
                    name: "PDF_\(url.lastPathComponent)",
                    category: .processing,
                    priority: priority
                ) { progressCallback in
                    // Simulate PDF processing with random duration
                    let totalSteps = Int.random(in: 5...15)
                    
                    for step in 1...totalSteps {
                        // Check for cancellation
                        try Task.checkCancellation()
                        
                        // Process a "page" (simulated)
                        let progress = Double(step) / Double(totalSteps)
                        let message = "Processing page \(step)/\(totalSteps)"
                        
                        // Report progress back
                        progressCallback(progress, message)
                        
                        // Simulate work
                        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
                    }
                    
                    // Return the "processed" result and update the reporter
                    let result = "Processed \(url.lastPathComponent)"
                    taskReporter.update(progress: 1.0, message: result)
                    return result
                }
                
                // Store the task ID
                taskIds.append(taskId)
                
                // Add the task's progress reporter to the aggregate
                progressReporter.addReporter(taskReporter, id: taskId.description)
                
                // Initialize task status
                taskStatuses[taskId] = TaskInfo(
                    id: taskId.description,
                    name: url.lastPathComponent,
                    priority: index < 2 ? .high : (index < 5 ? .medium : .low),
                    status: "Queued",
                    progress: 0.0
                )
            }
            
            // Start each task - they will be executed according to priority
            for taskId in taskIds {
                // Start the task, but don't await its completion (fire and forget)
                Task {
                    do {
                        // Call startTask
                        let result = try await taskCoordinator.startTask(id: taskId) as String
                        
                        // Update completion status
                        await MainActor.run {
                            taskStatuses[taskId]?.status = "Completed: \(result)"
                        }
                    } catch {
                        // Handle errors
                        await MainActor.run {
                            taskStatuses[taskId]?.status = "Failed: \(error.localizedDescription)"
                        }
                    }
                }
            }
            
            // Wait for all tasks to complete (or be cancelled)
            for taskId in taskIds {
                do {
                    try await taskCoordinator.waitForTask(id: taskId)
                } catch {
                    // Individual task errors are handled in the task-specific block above
                    print("Task \(taskId) failed: \(error)")
                }
            }
            
            // All tasks completed
            statusMessage = "All PDFs processed"
            isProcessing = false
            
        } catch {
            // Handle setup errors
            statusMessage = "Error: \(error.localizedDescription)"
            isProcessing = false
        }
    }
    
    /// Cancel all running tasks
    func cancelAllTasks() async {
        statusMessage = "Cancelling tasks..."
        
        // Get all tasks from the coordinator
        let allTasks = await taskCoordinator.getAllTasks()
        
        // Cancel each task
        for (id, _) in allTasks {
            await taskCoordinator.cancelTask(id: id)
        }
        
        statusMessage = "All tasks cancelled"
        isProcessing = false
    }
    
    // MARK: - Private Methods
    
    @MainActor
    private func setupSubscriptions() {
        // Subscribe to task coordinator events
        taskCoordinator.publisher
            .receive(on: RunLoop.main)
            .sink { [weak self] event in
                guard let self = self else { return }
                
                switch event {
                case .progressed(let id, let progress, let message):
                    if var taskInfo = self.taskStatuses[id] {
                        taskInfo.progress = progress
                        taskInfo.status = message
                        self.taskStatuses[id] = taskInfo
                    }
                    
                case .started(let id):
                    if var taskInfo = self.taskStatuses[id] {
                        taskInfo.status = "Running"
                        self.taskStatuses[id] = taskInfo
                    }
                    
                case .completed(let id):
                    if var taskInfo = self.taskStatuses[id] {
                        taskInfo.progress = 1.0
                        if taskInfo.status != "Completed" && !taskInfo.status.starts(with: "Completed:") {
                            taskInfo.status = "Completed"
                        }
                        self.taskStatuses[id] = taskInfo
                    }
                    
                case .failed(let id, let error):
                    if var taskInfo = self.taskStatuses[id] {
                        taskInfo.status = "Failed: \(error.localizedDescription)"
                        self.taskStatuses[id] = taskInfo
                    }
                    
                case .cancelled(let id):
                    if var taskInfo = self.taskStatuses[id] {
                        taskInfo.status = "Cancelled"
                        self.taskStatuses[id] = taskInfo
                    }
                    
                case .registered(_):
                    // Task registered, but status already initialized in processMultiplePDFs
                    break
                    
                case .queued(_, _):
                    // No specific action needed for queued tasks in this view model
                    break
                    
                case .throttled(_, _):
                    // No specific action needed for throttled tasks in this view model
                    break
                }
            }
            .store(in: &cancellables)
        
        // Subscribe to aggregate progress updates
        progressReporter.progressPublisher
            .receive(on: RunLoop.main)
            .sink { [weak self] update in
                self?.overallProgress = update.progress
                if !update.message.isEmpty {
                    self?.statusMessage = update.message
                }
            }
            .store(in: &cancellables)
    }
}