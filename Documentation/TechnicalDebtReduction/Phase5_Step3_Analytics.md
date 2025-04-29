# Analytics Framework Documentation

This document describes the analytics framework implemented as part of Phase 5, Step 3 of the Technical Debt Reduction Plan. The framework provides a centralized, protocol-based approach to tracking analytics across the PayslipMax application.

## Architecture Overview

The analytics system follows a layered architecture:

1. **Core Layer**: Protocol definitions and central manager
   - `AnalyticsProtocol`: Core interface for analytics operations
   - `AnalyticsProvider`: Provider interface for specific analytics implementations
   - `AnalyticsManager`: Central coordinator for multiple providers

2. **Provider Layer**: Specific analytics implementations
   - `FirebaseAnalyticsProvider`: Firebase-specific implementation (currently a stub)
   - Can be extended with additional providers (e.g., Mixpanel, Amplitude)

3. **Service Layer**: Domain-specific analytics services
   - `PerformanceAnalyticsService`: Tracks performance metrics
   - `UserAnalyticsService`: Tracks user behavior and actions

4. **Constants Layer**: Standardized event and property names
   - `AnalyticsEvents`: Standard event names
   - `AnalyticsUserProperties`: Standard user property names

## Integration with Feature Flags

The analytics framework is fully integrated with the feature flag system:

- All analytics tracking is controlled by the `.enhancedAnalytics` feature flag
- Provider registration only happens if the feature flag is enabled
- Each method in `AnalyticsManager` checks if analytics is enabled before proceeding

This ensures that analytics can be toggled on/off without any code changes.

## Key Components

### AnalyticsProtocol

Core protocol defining the analytics tracking capabilities:

```swift
protocol AnalyticsProtocol {
    func logEvent(_ name: String, parameters: [String: Any]?)
    func setUserProperty(_ value: String?, forName name: String)
    func setUserID(_ userID: String?)
    func beginTimedEvent(_ name: String, parameters: [String: Any]?)
    func endTimedEvent(_ name: String, parameters: [String: Any]?)
}
```

### AnalyticsProvider

Protocol for specific analytics implementations:

```swift
protocol AnalyticsProvider {
    func logEvent(_ name: String, parameters: [String: Any]?)
    func setUserProperty(_ value: String?, forName name: String)
    func setUserID(_ userID: String?)
    func beginTimedEvent(_ name: String, parameters: [String: Any]?)
    func endTimedEvent(_ name: String, parameters: [String: Any]?)
}
```

### AnalyticsManager

Central manager that coordinates multiple analytics providers:

```swift
class AnalyticsManager: AnalyticsProtocol {
    static let shared = AnalyticsManager()
    
    func registerProvider(_ provider: AnalyticsProvider)
    func logEvent(_ name: String, parameters: [String: Any]?)
    func setUserProperty(_ value: String?, forName name: String)
    func setUserID(_ userID: String?)
    func beginTimedEvent(_ name: String, parameters: [String: Any]?)
    func endTimedEvent(_ name: String, parameters: [String: Any]?)
}
```

### Specialized Analytics Services

Domain-specific services for tracking different aspects of the application:

- `PerformanceAnalyticsService`: Tracks PDF processing performance, parser execution, memory warnings, etc.
- `UserAnalyticsService`: Tracks user actions, navigation, payslip operations, etc.

## Standard Events and Properties

The framework defines standardized event and property names through:

- `AnalyticsEvents`: Struct with static constants for event names
- `AnalyticsUserProperties`: Struct with static constants for user property names

## Usage Examples

### Tracking a Simple Event

```swift
AnalyticsManager.shared.logEvent(AnalyticsEvents.screenView, parameters: [
    "screen_name": "HomeScreen",
    "screen_class": "HomeView"
])
```

### Tracking a Timed Event

```swift
// Start timer
AnalyticsManager.shared.beginTimedEvent(AnalyticsEvents.pdfProcessingStarted, parameters: [
    "file_size_bytes": 1024000,
    "page_count": 4
])

// End timer and log results
AnalyticsManager.shared.endTimedEvent(AnalyticsEvents.pdfProcessingStarted, parameters: [
    "success": true,
    "extracted_field_count": 15
])
```

### Using Domain-Specific Services

```swift
// Track parser execution
PerformanceAnalyticsService.shared.trackParserExecution(
    parserID: "military-v2",
    payslipType: "PCDA",
    confidence: 0.95
)

// Track screen view
UserAnalyticsService.shared.trackScreenView(
    screenName: "PayslipDetail",
    screenClass: "PayslipDetailView"
)
```

## Best Practices

1. **Always use the standardized event and property names** from `AnalyticsEvents` and `AnalyticsUserProperties`
2. **Prefer the specialized services** over direct `AnalyticsManager` usage
3. **Use timed events** for operations that have meaningful duration
4. **Include relevant contextual information** in event parameters
5. **Consider privacy implications** when logging events and properties

## Future Enhancements

1. **Complete Firebase Implementation**: Replace the stub implementation with actual Firebase SDK integration
2. **Add Additional Providers**: Implement additional analytics providers as needed
3. **Add Data Validation**: Add validation to ensure analytics data adheres to standards
4. **Enhance Error Handling**: Add more robust error handling for analytics operations
5. **Add Analytics Dashboard**: Create an internal tool for viewing analytics data 