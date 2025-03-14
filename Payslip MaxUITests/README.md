# Payslip Max UI Tests

This directory contains UI tests for the Payslip Max iOS application. These tests verify that the user interface works correctly and that users can perform key actions in the app.

## Test Structure

The UI tests are organized using the Screen Object Pattern:

- **Screen Objects**: Classes that represent screens in the app and encapsulate element queries and actions
- **Test Cases**: Classes that contain test methods for specific screens or features
- **UITestHelper**: A utility class with common testing functions

## Running the Tests

### From Xcode

1. Open the Payslip Max project in Xcode
2. Select the "Payslip MaxUITests" scheme
3. Choose Product > Test (⌘U) to run all tests
4. To run a specific test class, select it in the Test Navigator and click the "Run" button

### From Command Line

```bash
xcodebuild test -project "Payslip Max.xcodeproj" -scheme "Payslip MaxUITests" -destination "platform=iOS Simulator,name=iPhone 14"
```

Replace "iPhone 14" with your preferred simulator device.

## Test Coverage

Current UI test coverage includes:

- **HomeView**: Basic elements, action buttons, tab navigation
- **PayslipsView**: Basic elements, filter button, navigation
- **PayslipDetailView**: Basic elements, scrolling, diagnostics, navigation, deletion

## Adding New Tests

To add a new UI test:

1. Create a screen object in the `Screens` directory if needed
2. Create a test class in the root directory
3. Use the UITestHelper and screen objects to write your tests
4. Add accessibility identifiers to UI elements in the app code

## Best Practices

- Use accessibility identifiers for reliable element identification
- Keep tests independent of each other
- Test real user flows and interactions
- Use screenshots for debugging and documentation
- Handle asynchronous operations with proper waiting mechanisms

## Troubleshooting

If tests are failing:

1. Check the test reports for error messages
2. Look at the screenshots taken during the test
3. Verify that accessibility identifiers match between tests and app code
4. Run the test with the debugger to step through the test execution 