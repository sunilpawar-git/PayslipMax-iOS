# PayslipMax Development Workflow
**Maintaining 94+/100 Architecture Quality Through Automated Enforcement**

## 🎯 Overview

This workflow ensures your PayslipMax application maintains the exceptional architecture quality achieved through successful MVVM-SOLID compliance and debt elimination. Follow these patterns to prevent technical debt and preserve your 94+/100 quality score.

## 🚀 Quick Start Checklist

Before writing any code:
```bash
# 1. Check current architecture health
./Scripts/architecture-guard.sh

# 2. If adding to existing file, check its size
wc -l PayslipMax/Path/To/YourFile.swift

# 3. If file is approaching 250+ lines, plan extraction
./Scripts/component-extraction-helper.sh --analyze PayslipMax/Path/To/YourFile.swift
```

## 📋 Development Patterns

### 1. Starting New Features

```bash
# Step 1: Design protocol first
# Create PayslipMax/Core/Protocols/YourFeatureProtocol.swift
protocol YourFeatureProtocol {
    func performAction() async throws -> Result
}

# Step 2: Create implementation with DI
# Create PayslipMax/Services/YourFeatureService.swift (keep <300 lines)
class YourFeatureService: YourFeatureProtocol {
    // Implementation with async/await
}

# Step 3: Register in DI container
# Add to appropriate container (Core/Processing/ViewModel/Feature)

# Step 4: Create ViewModel if needed
# PayslipMax/Features/YourFeature/ViewModels/YourFeatureViewModel.swift
class YourFeatureViewModel: ObservableObject {
    private let service: YourFeatureProtocol
    
    init(service: YourFeatureProtocol) {
        self.service = service
    }
}

# Step 5: Create View with proper injection
# PayslipMax/Features/YourFeature/Views/YourFeatureView.swift
struct YourFeatureView: View {
    @StateObject private var viewModel: YourFeatureViewModel
    
    init(viewModel: YourFeatureViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }
}
```

### 2. Refactoring Existing Code

```bash
# Step 1: Analyze current file
./Scripts/component-extraction-helper.sh --analyze YourFile.swift

# Step 2: Get extraction suggestions
./Scripts/component-extraction-helper.sh --suggest YourFile.swift

# Step 3: Preview extraction plan
./Scripts/component-extraction-helper.sh --preview YourFile.swift

# Step 4: Extract components following suggestions
# Keep original interface intact, extract implementation
```

### 3. Pre-Commit Validation

```bash
# Run before every commit
./Scripts/pre-commit-enforcement.sh

# This checks:
# ✅ File sizes (<300 lines)
# ✅ MVVM compliance
# ✅ Async-first patterns
# ✅ Build integrity
# ✅ Singleton usage
```

## 🏗️ Architecture Patterns

### MVVM Pattern
```swift
// ✅ Correct: View → ViewModel → Service
struct FeatureView: View {
    @StateObject private var viewModel: FeatureViewModel
    
    var body: some View {
        // UI only, no business logic
    }
}

class FeatureViewModel: ObservableObject {
    @Published var state: ViewState = .idle
    private let service: FeatureServiceProtocol
    
    func performAction() async {
        // Coordinate services, manage UI state
        state = .loading
        do {
            let result = try await service.performAction()
            state = .success(result)
        } catch {
            state = .error(error)
        }
    }
}
```

### Dependency Injection Pattern
```swift
// ✅ Correct: Protocol-based DI
class FeatureService: FeatureServiceProtocol {
    private let dependency: DependencyProtocol
    
    init(dependency: DependencyProtocol) {
        self.dependency = dependency
    }
}

// Register in appropriate DI container
extension CoreServiceContainer {
    func makeFeatureService() -> FeatureServiceProtocol {
        return FeatureService(dependency: makeDependency())
    }
}
```

### Async-First Pattern
```swift
// ✅ Correct: Async operations
class DataService: DataServiceProtocol {
    func loadData() async throws -> [DataItem] {
        // Use async/await, never DispatchSemaphore
        let data = try await networkService.fetchData()
        return try await processData(data)
    }
    
    private func processData(_ data: Data) async throws -> [DataItem] {
        // Background processing with proper async handling
        return try await withTaskGroup(of: DataItem.self) { group in
            // Parallel processing
        }
    }
}
```

### Memory-Efficient Pattern
```swift
// ✅ Correct: Memory optimization for large files
class LargeFileProcessor {
    private let memoryManager = EnhancedMemoryManager.shared
    
    func processLargeFile(_ data: Data) async throws -> Result {
        if data.count > 10_000_000 { // 10MB
            return try await LargePDFStreamingProcessor().process(data)
        } else {
            return try await standardProcess(data)
        }
    }
}
```

## ⚠️ Anti-Patterns to Avoid

### ❌ File Size Violations
```swift
// NEVER create files over 300 lines
class HugeViewModel: ObservableObject {
    // 400+ lines of code
    // Extract to multiple focused components!
}
```

### ❌ MVVM Violations
```swift
// NEVER import SwiftUI in services
import SwiftUI // Wrong in service layer
class MyService {
    // Business logic should not know about UI
}

// NEVER call services directly from views
struct MyView: View {
    var body: some View {
        Button("Action") {
            DIContainer.shared.makeService().doSomething() // Wrong!
            // Use ViewModel instead
        }
    }
}
```

### ❌ Blocking Operations
```swift
// NEVER use blocking patterns
func processData() {
    let semaphore = DispatchSemaphore(value: 0) // FORBIDDEN!
    // Use async/await instead
}
```

### ❌ Singleton Abuse
```swift
// AVOID excessive singleton usage
BusinessLogicService.shared.doSomething() // Use DI instead
```

## 🔧 Tools and Scripts

### Architecture Guard
```bash
# Real-time monitoring
./Scripts/architecture-guard.sh

# Monitors:
# - File size compliance
# - MVVM violations
# - Async compliance
# - Singleton usage
# - Memory patterns
```

### Component Extraction Helper
```bash
# Analyze file for extraction opportunities
./Scripts/component-extraction-helper.sh --analyze File.swift

# Get specific extraction suggestions
./Scripts/component-extraction-helper.sh --suggest File.swift

# Preview extraction plan
./Scripts/component-extraction-helper.sh --preview File.swift
```

### Pre-Commit Enforcement
```bash
# Quality gate validation
./Scripts/pre-commit-enforcement.sh

# Prevents commits with:
# - File size violations
# - MVVM violations
# - Async violations
# - Build failures
```

## 📊 Quality Metrics

### Target Metrics
- **File Size Compliance**: 90%+ files under 300 lines
- **MVVM Violations**: 0 (except legitimate UI services)
- **Async Operations**: 100% for I/O operations
- **Build Performance**: <10 seconds clean build
- **Architecture Quality**: 94+/100 score

### Red Flags (Address Immediately)
- Any file >350 lines
- SwiftUI imports in Services/ (except UIAppearanceService)
- DispatchSemaphore usage
- Build failures
- Memory leaks or retain cycles

## 🎯 Success Validation

### Daily Health Check
```bash
# Run architecture guard
./Scripts/architecture-guard.sh

# Check overall compliance
find PayslipMax -name "*.swift" -exec wc -l {} + | awk '$1 > 300 {print "VIOLATION: " $2}'
```

### Weekly Deep Analysis
```bash
# Comprehensive debt analysis
./Scripts/debt-monitor.sh

# MVVM compliance check
./Scripts/mvvm-compliance-monitor.sh

# Architecture quality assessment
./Scripts/architecture-guard.sh > weekly_report.txt
```

## 📚 References

- **Achieved Quality Score**: 94+/100
- **File Size Compliance**: 89.2% (436/489 files)
- **Elimination Success**: 13,938+ lines removed
- **Architecture**: MVVM + SOLID + Single Source of Truth
- **Processing**: 100% async, unified pipeline

## 🎉 Conclusion

Following this workflow maintains the exceptional architecture quality you've achieved. The combination of automated enforcement, clear patterns, and proven tools ensures your PayslipMax application continues to demonstrate architectural excellence while preventing technical debt accumulation.

**Remember**: These patterns are based on your successful elimination of 95%+ technical debt and achievement of 94+/100 architecture quality. Consistency with these patterns ensures long-term maintainability and scalability.
