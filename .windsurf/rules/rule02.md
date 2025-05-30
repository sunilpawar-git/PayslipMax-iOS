---
trigger: always_on
---

---
description: Technical debt prevention guidelines
globs: 
alwaysApply: true
---

# Technical Debt Prevention Rules

## Concurrency Patterns

1. **Asynchronous Code**
   - No synchronous wrappers around asynchronous code (ban semaphores for this purpose)
   - Use structured concurrency (async/await) for asynchronous operations
   - Document thread safety requirements for all shared resources
   - Use Swift's structured concurrency (async/await)
   - Document actor isolation requirements
   - Clearly mark thread-unsafe APIs

2. **ViewModels**
   - ViewModels should not reference UIKit/SwiftUI directly
   - ViewModels must expose state through published properties only
   - ViewModels should not contain coordination logic

## Error Handling

1. **Standardized Error Handling**
   - Define domain-specific error hierarchies for each feature
   - Include recovery suggestions in all error types
   - Enforce consistent error mapping at module boundaries

2. **Error Propagation**
   - Document error handling strategy for each function
   - Establish clear ownership of error recovery responsibility
   - Ensure UI always displays user-friendly error messages

## Memory Management

1. **Resource Lifecycle**
   - Implement explicit cleanup for disposable resources
   - Audit large object retention in regular code reviews
   - Document ownership model for all resources

2. **Performance Considerations**
   - Document time and space complexity for algorithms
   - Implement pagination for all collection-based views
   - Use lazy initialization for expensive resources

## Swift-Specific Rules

1. **Swift Idioms**
   - Prefer value types over reference types
   - Use strong typing instead of stringly-typed code
   - Leverage Swift's type system for compile-time safety

2. **SwiftUI Best Practices**
   - Use ViewBuilder for complex view construction
   - Keep view modifier chains logical and organized
   - Use property wrappers appropriately (@State, @Binding, etc.)

## Refactoring Triggers

1. **Metrics**
   - Functions > 30 lines
   - Files > 300 lines
   - Cyclomatic complexity > 15
   - Test coverage < 80%
   - Duplicate code > 10 lines

2. **When to Refactor**
   - Before adding new features to an area
   - When fixing bugs in complex code
   - When the same area has had multiple bugs
   - When extending an API

## Code Review Standards

1. **Review Checklist**
   - Adherence to architectural patterns
   - Error handling completeness
   - Memory management
   - Test coverage
   - Documentation quality
   - Performance considerations

2. **Review Process**
   - Require architectural review for changes affecting multiple modules
   - Enforce "no new warnings" policy
   - Use automated tools to check compliance with standards

## Technical Debt Management

1. **Debt Tracking**
   - Track technical debt items in issue tracker
   - Categorize debt by impact and difficulty
   - Allocate 20% of development time to debt reduction

2. **Prevention Strategies**
   - Regular architecture reviews (bi-weekly)
   - Rotating "code quality" role among team members
   - "Boy Scout Rule": Leave code cleaner than you found it

## Documentation Standards

1. **Architecture Documentation**
   - Maintain up-to-date architecture diagrams
   - Document all third-party dependencies with justification
   - Create decision logs for architectural choices

## Process Enhancements

1. **Tech Debt Sprints**
   - Dedicate one sprint per quarter to technical debt reduction
   - Measure and report on debt reduction progress

2. **Continuous Integration**
   - Automated checks for rule compliance
   - Block merges that violate critical rules
   - Generate metrics reports on technical debt indicators

3. **Knowledge Sharing**
   - Weekly code review sessions focusing on quality
   - Maintain living documentation of architectural decisions
   - Regular training on debt prevention techniques