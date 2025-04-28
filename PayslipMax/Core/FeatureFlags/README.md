# Feature Flag System

The Feature Flag system allows for controlled rollout of features, A/B testing, and toggling experimental functionality. It provides a way to enable or disable features at runtime without requiring code changes or app updates.

## Architecture

The feature flag system consists of several key components:

1. **Feature Enum**: The `Feature` enum defines all available feature flags in the application.
2. **FeatureFlagProtocol**: Defines the interface for the feature flag system.
3. **FeatureFlagConfiguration**: Manages the default state of features and remote configuration.
4. **FeatureFlagService**: Implements the `FeatureFlagProtocol` and handles feature flag evaluation.
5. **FeatureFlagManager**: Provides a simplified API for checking features and controlling feature toggling.

### Component Relationships

```
┌─────────────────────┐     ┌─────────────────────┐
│   Feature (enum)    │     │ FeatureFlagProtocol │
└─────────────────────┘     └──────────┬──────────┘
          ▲                            │
          │                            │
          │                 implements │
          │                            │
          │                            ▼
┌─────────┴──────────┐     ┌─────────────────────┐
│ FeatureFlagManager │◄────│  FeatureFlagService │
└─────────────────────┘     └──────────┬──────────┘
                                       │
                                       │ uses
                                       │
                                       ▼
                            ┌─────────────────────┐
                            │FeatureFlagConfiguration│
                            └─────────────────────┘
```

## Usage

### Checking If a Feature is Enabled

```swift
// Using the manager (recommended)
if FeatureFlagManager.shared.isEnabled(.enhancedDashboard) {
    // Show enhanced dashboard
} else {
    // Show standard dashboard
}

// Or using the when method for cleaner code
FeatureFlagManager.shared.when(.enhancedDashboard) {
    // Show enhanced dashboard
} else: {
    // Show standard dashboard
}

// Selecting a value based on a feature flag
let dashboardType = FeatureFlagManager.shared.select(
    .enhancedDashboard,
    trueValue: DashboardType.enhanced,
    falseValue: DashboardType.standard
)
```

### In SwiftUI Views

```swift
// Show a view only if a feature is enabled
Button(action: showAnnotationTools) {
    Image(systemName: "pencil")
}
.featureEnabled(.pdfAnnotation)

// Apply a modifier conditionally based on a feature flag
Text("Dashboard")
    .featureConditional(.enhancedDashboard) { view in
        view.foregroundColor(.blue)
    }

// Show different views based on a feature flag
Group {
    if FeatureFlagManager.shared.isEnabled(.enhancedDashboard) {
        EnhancedDashboardView()
    } else {
        StandardDashboardView()
    }
}
```

### Adding a New Feature Flag

To add a new feature flag:

1. Add a new case to the `Feature` enum in `FeatureFlagProtocol.swift`:

```swift
enum Feature: String, CaseIterable {
    // Existing features...
    
    /// Description of your new feature
    case yourNewFeature
}
```

2. Set the default state in `FeatureFlagConfiguration.swift`:

```swift
private var defaultStates: [Feature: Bool] = [
    // Existing defaults...
    .yourNewFeature: false,  // Set to true to enable by default
]
```

### Toggling Features for Testing

During development or testing, you can override feature states:

```swift
// Enable a feature
FeatureFlagManager.shared.toggleFeature(.yourFeature, enabled: true)

// Disable a feature
FeatureFlagManager.shared.toggleFeature(.yourFeature, enabled: false)

// Reset to default state
FeatureFlagManager.shared.resetFeature(.yourFeature)
```

## Remote Configuration

The feature flag system supports remote configuration to allow changing feature states without updating the app. The configuration is refreshed when the app starts and can be manually refreshed using:

```swift
FeatureFlagManager.shared.refreshConfiguration { success in
    if success {
        print("Configuration refreshed successfully")
    } else {
        print("Failed to refresh configuration")
    }
}
```

## Demo

The `FeatureFlagDemoView` provides a UI for toggling features and demonstrates how to use the feature flag system. It can be useful during development and testing. 