import Foundation

enum PipelineStage: String, CaseIterable {
    case validation = "validate"
    case textExtraction = "extract"
    case formatDetection = "format"
    case processing = "process"

    var processingContext: ProcessingContext {
        switch self {
        case .validation: return .validation
        case .textExtraction: return .textExtraction
        case .formatDetection: return .formatDetection
        case .processing: return .processing
        }
    }
}

final class SimpleCacheManager {
    private var cache: [String: Any] = [:]
    private let queue = DispatchQueue(label: "com.payslipmax.simple.cache", attributes: .concurrent)

    func store<T: Codable>(_ value: T, forKey key: String) {
        queue.async(flags: .barrier) { self.cache[key] = value }
    }

    func retrieve<T: Codable>(forKey key: String) -> T? {
        queue.sync { cache[key] as? T }
    }

    func remove(forKey key: String) {
        queue.async(flags: .barrier) { self.cache.removeValue(forKey: key) }
    }

    func clearAll() {
        queue.async(flags: .barrier) { self.cache.removeAll() }
    }

    var count: Int { queue.sync { cache.count } }
}
