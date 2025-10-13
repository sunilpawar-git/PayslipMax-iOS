# PayslipMax Dependency Tree Documentation

This folder contains comprehensive dependency analysis for the entire PayslipMax project.

---

## 📚 Available Documents

### 1. **COMPLETE_DEPENDENCY_TREE.md** ⭐⭐⭐⭐⭐
**Purpose**: Detailed text-based dependency tree showing how every file interacts

**Contains**:
- High-level architecture map
- Core layer dependencies (DIContainer, CoreServiceContainer, ProcessingContainer, ViewModelContainer)
- Feature module dependencies (Home, Payslips, Insights, Settings, WebUpload)
- Services layer dependencies
- Spatial intelligence layer
- Models layer dependencies
- Views layer dependencies
- Critical dependency paths
- Testing dependencies
- Protocol definitions
- File relationship metrics

**Best For**: Understanding specific file interactions and dependency chains

---

### 2. **VISUAL_DEPENDENCY_MAP.md** ⭐⭐⭐⭐⭐
**Purpose**: Interactive Mermaid diagrams showing visual dependency flows

**Contains**:
- Core architecture diagram
- PDF processing pipeline
- Parsing layer dependencies
- Feature module diagrams (Home, Insights, Settings)
- Feature module interactions
- Testing architecture
- Security layer
- Data flow sequences
- Critical paths
- Module dependency matrix
- Protocol hierarchy
- Performance monitoring flow

**Best For**: Visual learners, presentations, understanding architecture at a glance

**How to View**:
- Copy any Mermaid diagram to [Mermaid Live Editor](https://mermaid.live/)
- Many IDEs have Mermaid preview plugins
- GitHub renders Mermaid diagrams automatically

---

## 🎯 Quick Navigation Guide

### "I want to understand..."

#### **...how the app starts**
→ See: COMPLETE_DEPENDENCY_TREE.md § Dependency Injection Flow  
→ Diagram: VISUAL_DEPENDENCY_MAP.md § Critical Paths → App Launch

#### **...how PDF parsing works**
→ See: COMPLETE_DEPENDENCY_TREE.md § Critical Dependency Paths → Path 1  
→ Diagram: VISUAL_DEPENDENCY_MAP.md § PDF Processing Pipeline

#### **...how a specific feature works**
→ See: COMPLETE_DEPENDENCY_TREE.md § Feature Module Dependencies  
→ Diagram: VISUAL_DEPENDENCY_MAP.md § Feature Module Diagrams

#### **...what services a ViewModel uses**
→ See: COMPLETE_DEPENDENCY_TREE.md § ViewModelContainer  
→ Diagram: VISUAL_DEPENDENCY_MAP.md § Feature Module Interactions

#### **...which files depend on a specific file**
→ Search: COMPLETE_DEPENDENCY_TREE.md for the filename  
→ Check: § Most Referenced Files section

#### **...how to add a new feature**
→ See: COMPLETE_DEPENDENCY_TREE.md § Dependency Injection Flow  
→ Study: Existing feature modules (Home, Payslips, etc.)

---

## 📊 Project Statistics

- **Total Swift Files**: 993 (822 main + 171 tests)
- **Service Protocols**: 40+
- **ViewModels**: 20+
- **Feature Modules**: 6 (Home, Payslips, Insights, Settings, WebUpload, Authentication)
- **DI Container Layers**: 4 (Core, Processing, ViewModel, Feature)
- **Core Services**: 15+ (PDFService, SecurityService, DataService, etc.)
- **Processing Services**: 12+ (PDFProcessingService, UnifiedMilitaryPayslipProcessor, etc.)

---

## 🔑 Key Architecture Concepts

### 1. **Four-Layer DI Container**
```
CoreServiceContainer (Foundation services)
    ↓
ProcessingContainer (Business logic)
    ↓
ViewModelContainer (UI coordination)
    ↓
FeatureContainer (Feature-specific services)
```

### 2. **MVVM Flow**
```
View → ViewModel → Service → Data
```

### 3. **Protocol-First Design**
Every service has a protocol interface:
- Enables testability (mocking)
- Enables flexibility (multiple implementations)
- Enforces clear contracts

### 4. **Dependency Injection**
No service creates its own dependencies:
- All dependencies injected via constructor
- DIContainer manages creation
- Supports test injection

### 5. **Feature Module Independence**
Each feature is self-contained:
- Own ViewModels, Views, Services
- Accesses shared services via DI
- No cross-feature dependencies

---

## 🎓 Understanding Dependency Relationships

### **"Depends On" (Uses)**
File A depends on File B if:
- A imports B
- A references types from B
- A calls methods from B

Example:
```swift
// HomeViewModel.swift depends on DataService
class HomeViewModel {
    private let dataService: DataServiceProtocol  // Dependency
}
```

### **"Used By" (Dependents)**
File A is used by File B if:
- B imports A
- B references types from A
- B calls methods from A

Example:
```swift
// DataService is used by HomeViewModel
// (from DataService's perspective)
```

### **Hub Files** (Many dependents)
Files that many other files depend on:
- PayslipItem.swift (200+ files)
- DIContainer.swift (150+ files)
- PDFProcessingService.swift (80+ files)

### **Leaf Files** (Few/no dependents)
Files that depend on others but aren't depended upon:
- Views (HomeView, PayslipCard, etc.)
- UI Components
- Handlers

---

## 🛠️ Common Use Cases

### **Adding a New Service**

1. Create protocol:
```swift
// PayslipMax/Core/Protocols/
protocol MyNewServiceProtocol {
    func doSomething() async throws -> Result
}
```

2. Implement service:
```swift
// PayslipMax/Services/
class MyNewService: MyNewServiceProtocol {
    func doSomething() async throws -> Result {
        // Implementation
    }
}
```

3. Register in DI Container:
```swift
// PayslipMax/Core/DI/DIContainer.swift
func makeMyNewService() -> MyNewServiceProtocol {
    return MyNewService()
}

// In resolve<T>():
case is MyNewServiceProtocol.Type:
    return makeMyNewService() as? T
```

4. Use in ViewModel:
```swift
class MyViewModel: ObservableObject {
    private let myService: MyNewServiceProtocol
    
    init(myService: MyNewServiceProtocol) {
        self.myService = myService
    }
}
```

**See**: COMPLETE_DEPENDENCY_TREE.md § Dependency Injection Flow

---

### **Adding a New Feature Module**

1. Create directory structure:
```
PayslipMax/Features/MyFeature/
├── ViewModels/
├── Views/
├── Services/
└── Models/
```

2. Create ViewModel:
```swift
class MyFeatureViewModel: ObservableObject {
    private let dataService: DataServiceProtocol
    
    init(dataService: DataServiceProtocol) {
        self.dataService = dataService
    }
}
```

3. Register in ViewModelContainer:
```swift
func makeMyFeatureViewModel() -> MyFeatureViewModel {
    return MyFeatureViewModel(
        dataService: coreContainer.makeDataService()
    )
}
```

4. Create View:
```swift
struct MyFeatureView: View {
    @StateObject private var viewModel: MyFeatureViewModel
    
    init() {
        let vm = DIContainer.shared.makeMyFeatureViewModel()
        self._viewModel = StateObject(wrappedValue: vm)
    }
}
```

**See**: COMPLETE_DEPENDENCY_TREE.md § Feature Module Dependencies

---

### **Debugging Parsing Issues**

1. Check pipeline execution:
→ See: VISUAL_DEPENDENCY_MAP.md § PDF Processing Pipeline

2. Identify which component is failing:
→ See: COMPLETE_DEPENDENCY_TREE.md § Critical Dependency Paths → Path 1

3. Common failure points:
- **ValidationStep**: PDF corrupt or password-protected
- **TextExtractionStep**: PDF is scanned image (needs OCR)
- **FormatDetectionStep**: Unknown format
- **ProcessingStep**: Parsing patterns don't match

4. Debug specific processor:
→ See: COMPLETE_DEPENDENCY_TREE.md § Processing Layer Dependencies

---

## 🧪 Testing Guidelines

### **Unit Testing a Service**

1. Create mock protocol:
```swift
class MockDataService: DataServiceProtocol {
    var fetchCallCount = 0
    var mockPayslips: [PayslipItem] = []
    
    func fetchPayslips() async throws -> [PayslipItem] {
        fetchCallCount += 1
        return mockPayslips
    }
}
```

2. Test with mock:
```swift
func testViewModel() async {
    let mockService = MockDataService()
    mockService.mockPayslips = [/* test data */]
    
    let viewModel = MyViewModel(dataService: mockService)
    await viewModel.loadData()
    
    XCTAssertEqual(mockService.fetchCallCount, 1)
    XCTAssertEqual(viewModel.items.count, mockService.mockPayslips.count)
}
```

**See**: COMPLETE_DEPENDENCY_TREE.md § Testing Dependencies

---

### **Integration Testing**

Test full pipeline with real implementations:

```swift
func testFullPDFProcessingPipeline() async throws {
    let container = DIContainer.shared
    let service = container.makePDFProcessingService()
    
    let testPDF = loadTestPDF() // Real PDF data
    let result = await service.processPDFData(testPDF)
    
    XCTAssertTrue(result.isSuccess)
    // Validate extracted data
}
```

**See**: VISUAL_DEPENDENCY_MAP.md § Testing Architecture

---

## 📈 Metrics and Analysis

### **File Size Distribution**
- Services: 260 files (~32%)
- Views: 77 files (~9%)
- Features: 100+ files (~12%)
- Models: 57 files (~7%)
- Core: 120+ files (~15%)
- Other: ~200 files (~25%)

### **Most Complex Dependencies**
1. **PDFProcessingService**: 15+ direct dependencies
2. **UnifiedMilitaryPayslipProcessor**: 10+ direct dependencies
3. **HomeViewModel**: 8+ direct dependencies
4. **DIContainer**: Orchestrates 40+ services

### **Most Coupled Files**
1. **PayslipItem.swift**: 200+ dependents
2. **DIContainer.swift**: 150+ dependents
3. **PDFProcessingService.swift**: 80+ dependents
4. **DataService.swift**: 100+ dependents

**See**: COMPLETE_DEPENDENCY_TREE.md § Critical File Relationships

---

## 🔍 Deep Dive Sections

For detailed analysis of specific areas:

### **PDF Parsing Deep Dive**
→ COMPLETE_DEPENDENCY_TREE.md § Processing Layer Dependencies  
→ VISUAL_DEPENDENCY_MAP.md § Parsing Layer Dependencies

### **Spatial Intelligence Deep Dive**
→ COMPLETE_DEPENDENCY_TREE.md § Spatial Intelligence Layer  
→ Shows: SpatialAnalyzer, ColumnBoundaryDetector, RowAssociator, etc.

### **Security Deep Dive**
→ COMPLETE_DEPENDENCY_TREE.md § Security Services  
→ VISUAL_DEPENDENCY_MAP.md § Security Layer

### **Feature Modules Deep Dive**
→ COMPLETE_DEPENDENCY_TREE.md § Feature Module Dependencies  
→ VISUAL_DEPENDENCY_MAP.md § Feature Module Diagrams

---

## 🎯 Pro Tips

### **Finding Dependencies Quickly**

1. **Use text search** in COMPLETE_DEPENDENCY_TREE.md:
   - Search for filename to see what it depends on
   - Search for "Used by" to see dependents

2. **Use visual diagrams** for overview:
   - Start with Core Architecture Diagram
   - Drill down to specific feature/service

3. **Follow dependency chains**:
   - Start from top (DIContainer)
   - Follow arrows down to your target
   - Understand full context

### **Understanding New Code**

1. Find the file in COMPLETE_DEPENDENCY_TREE.md
2. Check its "Dependencies" section
3. Check its "Dependents" section
4. Look at visual diagram for context
5. Trace critical paths to understand flow

### **Refactoring Safely**

1. Check dependents before changing file
2. If many dependents, change protocol first
3. Update implementation while maintaining interface
4. Run tests to catch breaking changes

---

## 📞 Questions?

If you can't find what you're looking for:

1. Search both documents for keywords
2. Check visual diagrams for overview
3. Look at similar existing features
4. Review protocol definitions in code

---

**Last Updated**: October 13, 2025  
**Files Analyzed**: 993 Swift files  
**Documentation Version**: 1.0
