import Combine

@MainActor
protocol XRaySubscribable: AnyObject {
    var xRaySettings: any XRaySettingsServiceProtocol { get }
    var xRayToggleCancellable: AnyCancellable? { get set }

    func onXRayToggleChanged()
}

extension XRaySubscribable {
    func setupXRaySubscription() {
        xRayToggleCancellable = xRaySettings.xRayEnabledPublisher
            .sink { [weak self] _ in
                Task { @MainActor in
                    self?.onXRayToggleChanged()
                }
            }
    }
}

