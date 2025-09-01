# Deep Linking Documentation

## Overview
PayslipMax supports deep linking to navigate directly to specific screens within the app. This allows for integration with other apps and services, as well as providing convenient ways to navigate to specific content.

## URL Scheme
The app registers the custom URL scheme `payslipmax://`.

## Supported Deep Links

### Main Tabs
- `payslipmax://home` - Navigate to Home tab
- `payslipmax://payslips` - Navigate to Payslips tab
- `payslipmax://insights` - Navigate to Insights tab
- `payslipmax://settings` - Navigate to Settings tab

### Detailed Content
- `payslipmax://payslip?id=<UUID>` - Open a specific payslip by its UUID
  - Example: `payslipmax://payslip?id=123e4567-e89b-12d3-a456-426614174000`

### Modals
- `payslipmax://privacy` - Open the Privacy Policy
- `payslipmax://terms` - Open the Terms of Service

## Implementation
The deep linking is handled by the `NavRouter.handleDeepLink()` method, which parses the URL and navigates to the appropriate screen.

## Testing Deep Links
You can test deep links through:

1. Safari: Type the deep link URL in the address bar
2. Notes app: Type the deep link and tap on it
3. Terminal command: `xcrun simctl openurl booted "payslipmax://payslips"`

## Example Integration
```swift
// Opening a payslip from another app
if let url = URL(string: "payslipmax://payslip?id=\(payslipId.uuidString)") {
    UIApplication.shared.open(url)
}
``` 