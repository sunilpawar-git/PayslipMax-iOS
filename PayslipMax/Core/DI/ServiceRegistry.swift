import Foundation
import Dispatch

final class ServiceRegistry {
    static let shared = ServiceRegistry()

    private var services: [String: Any] = [:]
    private let queue = DispatchQueue(label: "ServiceRegistry.queue", attributes: .concurrent)

    private init() {}

    // Register default services at startup
    func bootstrapDefaults() {
        if resolve(FeatureFlagProtocol.self) as FeatureFlagProtocol? == nil {
            register(FeatureFlagProtocol.self, instance: FeatureFlagService.shared)
        }
    }

    func register<ServiceType>(_ type: ServiceType.Type, instance: ServiceType) {
        let key = String(describing: type)
        queue.async(flags: .barrier) { [weak self] in
            self?.services[key] = instance
        }
    }

    func resolve<ServiceType>(_ type: ServiceType.Type) -> ServiceType? {
        let key = String(describing: type)
        var result: ServiceType?
        queue.sync {
            result = services[key] as? ServiceType
        }
        return result
    }
}


