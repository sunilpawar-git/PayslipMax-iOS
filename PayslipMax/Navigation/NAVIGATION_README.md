# Navigation System for PayslipMax

This module contains the navigation architecture for the PayslipMax app, implementing a type-safe, scalable navigation system.

## Key Components

### NavRouter

The `NavRouter` is the core class that manages navigation state and provides methods for navigating through the app. It keeps separate navigation stacks for each tab and handles modal presentations.

Key features:
- Tab-specific navigation stacks
- Sheet and fullscreen presentations
- Deep link handling

Usage example:
```swift
// In a view with @EnvironmentObject access to NavRouter
@EnvironmentObject private var router: NavRouter

// Navigate within current tab
Button("Show Details") {
    router.navigate(to: .payslipDetail(id: payslip.id))
}

// Switch tabs
Button("Go to Payslips") {
    router.switchTab(to: 1)
}

// Present a sheet
Button("Add Payslip") {
    router.presentSheet(.addPayslip)
}
```

### NavDestination

The `NavDestination` enum defines all possible navigation destinations in the app, with associated values for destinations that require parameters.

It conforms to:
- `Identifiable` for use with SwiftUI's `.sheet(item:)` API
- `Hashable` for use with NavigationStack's `.navigationDestination(for:)` API

### DeepLinkHandler

The `DeepLinkHandler` extension on `NavRouter` handles deep links to various parts of the app.

## Implementation Structure

1. **MainTabView.swift** - The root view that sets up the tab structure and navigation stacks
2. **NavRouter.swift** - The navigation state manager and coordinator
3. **NavDestination.swift** - The enum defining all possible destinations
4. **DeepLinkHandler.swift** - Handles deep link URL parsing and routing

## Deep Linking

The app supports deep linking with the `payslipmax://` URL scheme. See `../Documentation/DeepLinking.md` for detailed documentation on the supported deep links.

## Best Practices

1. Always use the router for navigation rather than SwiftUI's navigation APIs directly
2. Keep the NavDestination enum updated with all possible destinations
3. When adding a new screen, update both the destination enum and the appropriate view builder methods in MainTabView
4. For complex navigation flows, consider extending NavRouter with convenience methods

## Testing

The `DeepLinkTestView` in the Debug folder provides a way to test deep links during development.

## Extension Points

1. Add analytics tracking to navigation events
2. Implement transition animations
3. Add navigation history tracking 