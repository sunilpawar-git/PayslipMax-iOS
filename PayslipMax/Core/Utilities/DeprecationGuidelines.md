# PayslipMax Deprecation Guidelines

## Overview

This document outlines best practices for handling API deprecation in the PayslipMax application. Following these guidelines ensures a consistent approach to evolving the codebase while maintaining backward compatibility and providing clear migration paths for developers.

## Why Use Structured Deprecation?

- **Reduce Technical Debt**: Plan the lifecycle of APIs from introduction to removal
- **Improve Developer Experience**: Clear warnings and migration paths
- **Maintain Backward Compatibility**: Support existing code while evolving the API
- **Track Deprecated Code**: Centralized versioning and tracking of deprecated features

## Deprecation Utilities

The PayslipMax codebase includes several utilities to help manage API deprecation:

1. **DeprecationUtilities**: Centralized version tracking and message formatting
2. **DeprecationSupporting protocol**: Easy implementation of deprecation support
3. **Example implementations**: See `DeprecationDemo.swift` for practical examples

## Deprecation Workflow

### Step 1: Mark APIs for Deprecation

When deprecating an API, use Swift's `@available` attribute with `deprecated` option:

```swift
@available(*, deprecated, 
           message: "Use newMethod() instead. Will be removed in v3.0.")
public func oldMethod() {
    // Implementation or forwarding to new method
}
```

For standardized messages, use the deprecation utilities:

```swift
@available(*, deprecated, 
           message: DeprecationUtilities.standardDeprecationMessage(
               "Use newMethod() instead",
               replacementAPI: "newMethod()",
               deprecatedIn: "2.0", 
               removedIn: "3.0"))
public func oldMethod() {
    // Implementation
}
```

### Step 2: Document Migration Path

Always provide clear documentation about the replacement API:

```swift
/**
 * This method processes text with the legacy algorithm.
 *
 * \(DeprecationUtilities.documentationTemplate(
 *     item: "processText()",
 *     replacement: "processTextV2(text:options:)",
 *     deprecatedIn: "2.0",
 *     removedIn: "3.0"))
 */
@available(*, deprecated, ...)
public func processText(_ text: String) -> String {
    // Implementation
}

/**
 * Processes text with enhanced options.
 *
 * @param text The text to process
 * @param options Additional processing options
 * @return The processed text
 */
public func processTextV2(text: String, options: [String: Any]? = nil) -> String {
    // New implementation
}
```

### Step 3: Provide Runtime Warnings

For critical deprecations, consider logging runtime warnings:

```swift
@available(*, deprecated, ...)
public func oldMethod() {
    // Log deprecation warning at runtime
    DeprecationSupporting.logDeprecation(
        item: "oldMethod()",
        replacement: "newMethod()",
        file: #file,
        line: #line)
    
    // Forward to new implementation
    newMethod()
}
```

### Step 4: Schedule Removal

Plan for API removal according to semantic versioning principles:

1. **Minor Version**: Introduce new APIs, deprecate old ones
2. **Major Version**: Remove previously deprecated APIs

Track deprecated APIs with clear removal timelines:

```swift
/**
 * Deprecated APIs Schedule
 *
 * v2.0 (Current)
 * - Deprecated: processText()
 * - Deprecated: LegacyMode enum
 * - Deprecated: settings property
 *
 * v3.0 (Future)
 * - Remove: processText()
 * - Remove: LegacyMode enum
 * - Remove: settings property
 */
```

## Best Practices

1. **Forward Compatibility**: Deprecated methods should forward to new implementations
2. **Minimal Disruption**: Deprecation should not break existing code
3. **Clear Migration Path**: Always provide equivalent replacement APIs
4. **Deprecation Period**: Allow at least one major version cycle before removal
5. **Documentation**: Keep documentation updated with deprecation notices
6. **Testing**: Maintain tests for both deprecated and new APIs

## Examples

See `DeprecationDemo.swift` for practical examples of:

- Method deprecation
- Property deprecation
- Enum deprecation
- Type conversion between old and new APIs

## Summary

Consistent deprecation practices improve code maintainability and developer experience. By following these guidelines, we ensure smooth evolution of the PayslipMax API while maintaining compatibility for existing code. 