import SwiftUI

struct SettingsView: View {
    private let viewModel: SettingsViewModel
    
    init(viewModel: SettingsViewModel) {
        self.viewModel = viewModel
    }
    
    var body: some View {
        SettingsCoordinator(viewModel: viewModel)
    }
}

#Preview {
    SettingsView(viewModel: DIContainer.shared.makeSettingsViewModel())
} 