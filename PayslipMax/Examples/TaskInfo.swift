import Foundation
import Combine
import SwiftUI

/// Priority level for a task
enum ExampleTaskPriority: Int, Comparable {
    case background = 0
    case low = 1
    case medium = 2
    case high = 3
    
    static func < (lhs: ExampleTaskPriority, rhs: ExampleTaskPriority) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
}

/// Information about a task
struct TaskInfo: Identifiable {
    let id: String
    var name: String
    var priority: ExampleTaskPriority
    var status: String = "Waiting"
    var progress: Double = 0.0
    var dependencies: [String] = []
    
    init(id: String, name: String, priority: ExampleTaskPriority, status: String = "Waiting", progress: Double = 0.0, dependencies: [String] = []) {
        self.id = id
        self.name = name
        self.priority = priority
        self.status = status
        self.progress = progress
        self.dependencies = dependencies
    }
}

// Extension to make TaskInfo identifiable for SwiftUI lists
extension TaskInfo: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: TaskInfo, rhs: TaskInfo) -> Bool {
        return lhs.id == rhs.id
    }
} 