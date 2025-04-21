import Foundation
import SwiftUI

enum TaskPriority: Int, Comparable, CaseIterable {
    case background = 0
    case low = 1
    case medium = 2
    case high = 3
    
    static func < (lhs: TaskPriority, rhs: TaskPriority) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
}

struct TaskInfo: Identifiable {
    let id: String
    let name: String
    var priority: TaskPriority
    var status: String = "Waiting"
    var progress: Double = 0.0
    var dependencies: [String] = []
    
    init(id: String, name: String, priority: TaskPriority, status: String = "Waiting", progress: Double = 0.0, dependencies: [String] = []) {
        self.id = id
        self.name = name
        self.priority = priority
        self.status = status
        self.progress = progress
        self.dependencies = dependencies
    }
}

extension TaskInfo: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: TaskInfo, rhs: TaskInfo) -> Bool {
        return lhs.id == rhs.id
    }
} 