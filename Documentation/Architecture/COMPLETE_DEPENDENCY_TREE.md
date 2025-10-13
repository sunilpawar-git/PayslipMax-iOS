# PayslipMax Complete Dependency Tree
**Generated**: October 13, 2025
**Purpose**: Comprehensive map showing how every file interacts in the project

---

## 📊 Project Overview

- **Total Swift Files**: 822 (Main App) + 171 (Tests) = 993 files
- **Architecture Pattern**: MVVM with 4-Layer DI Container
- **Dependency Flow**: Protocols → Services → ViewModels → Views

---

## 🏗️ High-Level Architecture Map

```
┌─────────────────────────────────────────────────────────────┐
│                      PayslipMaxApp.swift                     │
│                    (Application Entry Point)                 │
└──────────────────────────┬──────────────────────────────────┘
                           │
                ┌──────────┴──────────┐
                │   DIContainer.swift  │
                │  (Service Registry)  │
                └──────────┬──────────┘
                           │
        ┌──────────────────┼──────────────────┐
        │                  │                  │
┌───────▼────────┐ ┌──────▼──────┐ ┌────────▼────────┐
│ CoreService    │ │ Processing  │ │ ViewModel       │
│ Container      │ │ Container   │ │ Container       │
│ (15+ services) │ │ (12+ svcs)  │ │ (8+ ViewModels) │
└───────┬────────┘ └──────┬──────┘ └────────┬────────┘
        │                  │                  │
        │                  │                  │
┌───────▼──────────────────▼──────────────────▼────────┐
│                  FEATURE MODULES                      │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐           │
│  │   Home   │  │ Payslips │  │ Insights │  Settings │
│  └──────────┘  └──────────┘  └──────────┘           │
└───────────────────────────────────────────────────────┘
```

---

## 🔍 Core Layer Dependencies

### 1️⃣ **DIContainer.swift** (Main Orchestrator)
**Location**: `PayslipMax/Core/DI/DIContainer.swift`

**Dependencies**:
- `CoreServiceContainer` → Creates PDF, Security, Data services
- `ProcessingContainer` → Creates parsing, extraction services
- `ViewModelContainer` → Creates all ViewModels
- `FeatureContainer` → Creates feature-specific services

**Dependents**: Every ViewModel, View, Service in the app

**Key Methods**:
```swift
func resolve<T>(_ type: T.Type) -> T?  // 35+ type resolutions
func makeHomeViewModel() -> HomeViewModel
func makePDFProcessingService() -> PDFProcessingServiceProtocol
```

---

### 2️⃣ **CoreServiceContainer** (Foundation Services)
**Location**: `PayslipMax/Core/DI/Containers/CoreServiceContainer.swift`

**Creates**:
- `PDFService` → PDF operations
- `SecurityService` → Encryption, Biometric auth
- `DataService` → SwiftData persistence
- `ValidationService` → Data validation
- `EncryptionService` → AES-256 encryption

**Dependencies**:
```swift
PDFService
  ├─► PDFValidationService
  ├─► PDFTextExtractionService
  └─► PDFRepairService

SecurityService
  ├─► BiometricAuthService
  ├─► KeychainSecureStorage
  └─► PayslipEncryptionService

DataService
  ├─► SwiftData ModelContext
  └─► PayslipRepository
```

**Dependents**: All feature modules, processing services

---

### 3️⃣ **ProcessingContainer** (Parsing Pipeline)
**Location**: `PayslipMax/Core/DI/Containers/ProcessingContainer.swift`

**Creates**:
- `PDFProcessingService` → Main PDF processing orchestrator
- `UnifiedMilitaryPayslipProcessor` → Military payslip parsing
- `UniversalPayCodeSearchEngine` → Pay code detection
- `SpatialAnalyzer` → Spatial intelligence for PDFs
- `PayslipProcessingPipeline` → Modular processing pipeline

**Dependency Chain**:
```swift
PDFProcessingService
  ├─► PDFService (from CoreServiceContainer)
  ├─► PDFExtractor
  │   └─► UniversalPayCodeSearchEngine
  │       ├─► PayCodePatternGenerator
  │       ├─► PayCodeClassificationEngine
  │       └─► ParallelPayCodeProcessor
  │
  ├─► ParsingCoordinator
  │   └─► UnifiedPDFParsingCoordinator
  │       └─► PayslipProcessingPipeline
  │           ├─► ValidationStep
  │           ├─► TextExtractionStep
  │           ├─► FormatDetectionStep
  │           └─► ProcessingStep
  │
  └─► FormatDetectionService
      └─► PayslipFormatDetectionService
          └─► TextExtractionService

UnifiedMilitaryPayslipProcessor
  ├─► UniversalPayCodeSearchEngine (shared)
  ├─► SpatialAnalyzer
  │   ├─► SpatialRelationshipCalculator
  │   ├─► ColumnBoundaryDetector
  │   └─► RowAssociator
  │
  ├─► RiskHardshipProcessor
  │   └─► PayslipSectionClassifier
  │
  └─► MilitaryAbbreviationsService
      └─► military_abbreviations.json
```

**Dependents**: HomeViewModel, PayslipsViewModel, PDF processing features

---

### 4️⃣ **ViewModelContainer** (UI Coordination)
**Location**: `PayslipMax/Core/DI/Containers/ViewModelContainer.swift`

**Creates**:
- `HomeViewModel` → Home screen logic
- `PayslipsViewModel` → Payslip list management
- `InsightsViewModel` → Analytics and insights
- `SettingsViewModel` → App settings
- `PayslipDetailViewModel` → Individual payslip details
- `BackupViewModel` → Backup/restore logic
- `WebUploadViewModel` → Web upload feature
- `QuizViewModel` → Quiz/gamification

**Dependency Chain**:
```swift
HomeViewModel
  ├─► DataService (from CoreServiceContainer)
  ├─► PDFProcessingService (from ProcessingContainer)
  ├─► AnalyticsService
  └─► GamificationCoordinator

PayslipsViewModel
  ├─► DataService
  ├─► BackupService
  ├─► PDFManager
  └─► ValidationService

InsightsViewModel
  ├─► DataService
  ├─► AnalyticsService
  ├─► ChartDataService
  └─► TrendAnalysisService

SettingsViewModel
  ├─► DataService
  ├─► SecurityService
  ├─► BiometricAuthService
  └─► AppearanceManager
```

**Dependents**: All View files in Features/

---

## 📁 Feature Module Dependencies

### 🏠 **Home Feature** (`Features/Home/`)

#### File Structure:
```
Features/Home/
├── ViewModels/
│   └── HomeViewModel.swift ────► DataService, PDFProcessingService
│
├── Views/
│   ├── HomeView.swift ──────────► HomeViewModel
│   ├── HomeQuizSection.swift ───► QuizViewModel
│   ├── HomeStatsSection.swift ──► InsightsViewModel
│   └── Components/
│       ├── PayslipCard.swift
│       └── QuickActionsView.swift
│
├── Handlers/
│   ├── PDFProcessingHandler.swift ─► PDFProcessingService
│   ├── ErrorHandler.swift
│   └── FileImportHandler.swift ────► PDFManager
│
├── Coordinators/
│   └── HomeCoordinator.swift ──────► NavRouter
│
└── Services/
    └── HomeAnalyticsService.swift ─► AnalyticsManager
```

#### Dependency Flow:
```
HomeView
  └─► HomeViewModel
      ├─► PDFProcessingService
      │   └─► UnifiedMilitaryPayslipProcessor
      │       └─► UniversalPayCodeSearchEngine
      │
      ├─► DataService
      │   └─► SwiftData ModelContext
      │
      └─► AnalyticsService
          └─► AnalyticsManager

PDFProcessingHandler
  └─► PDFProcessingService
      └─► (Same chain as above)

FileImportHandler
  └─► PDFManager
      └─► FileManager + PDF storage
```

---

### 📄 **Payslips Feature** (`Features/Payslips/`)

#### File Structure:
```
Features/Payslips/
├── ViewModels/
│   ├── PayslipsViewModel.swift ────────► DataService, BackupService
│   ├── PayslipDetailViewModel.swift ───► PDFManager, ValidationService
│   └── PayslipDetailPDFHandler.swift ──► PDFProcessingService
│
├── Views/
│   ├── PayslipsListView.swift ─────────► PayslipsViewModel
│   ├── PayslipDetailView.swift ────────► PayslipDetailViewModel
│   ├── Components/
│   │   ├── PayslipRowView.swift
│   │   ├── FilterView.swift
│   │   └── SortOptionsView.swift
│   │
│   └── PDF/
│       ├── PDFViewerView.swift ────────► PDFKit
│       └── PDFExportView.swift ────────► PDFManager
│
├── Services/
│   ├── PayslipFilterService.swift
│   ├── PayslipSortService.swift
│   └── PayslipExportService.swift ─────► PDFManager
│
└── Models/
    ├── PayslipFilter.swift
    └── PayslipSortOption.swift
```

#### Dependency Flow:
```
PayslipsListView
  └─► PayslipsViewModel
      ├─► DataService
      │   └─► SwiftData queries (fetch, filter, sort)
      │
      └─► BackupService
          └─► FileManager + Cloud sync

PayslipDetailView
  └─► PayslipDetailViewModel
      ├─► PDFManager (view PDF)
      ├─► ValidationService (validate data)
      └─► PayslipDetailPDFHandler
          └─► PDFProcessingService (re-process if needed)
```

---

### 📊 **Insights Feature** (`Features/Insights/`)

#### File Structure:
```
Features/Insights/
├── ViewModels/
│   ├── InsightsViewModel.swift ─────────► AnalyticsService
│   ├── ChartViewModel.swift ────────────► ChartDataService
│   └── TrendsViewModel.swift ───────────► TrendAnalysisService
│
├── Views/
│   ├── InsightsView.swift ──────────────► InsightsViewModel
│   ├── Components/
│   │   ├── SalaryTrendChart.swift ─────► ChartViewModel
│   │   ├── DeductionBreakdown.swift ───► ChartViewModel
│   │   ├── MonthlyComparisonChart.swift
│   │   └── InsightCard.swift
│   │
│   └── TrendsView.swift ────────────────► TrendsViewModel
│
├── Services/
│   ├── Analytics/
│   │   ├── ChartDataService.swift ─────► DataService
│   │   ├── TrendAnalysisService.swift ─► DataService
│   │   └── InsightGeneratorService.swift
│   │
│   └── InsightsCalculationService.swift
│
└── Models/
    ├── InsightData.swift
    ├── TrendData.swift
    └── ChartConfiguration.swift
```

#### Dependency Flow:
```
InsightsView
  └─► InsightsViewModel
      └─► AnalyticsService
          ├─► ChartDataService
          │   └─► DataService (fetch payslips)
          │       └─► Calculate trends, averages, totals
          │
          └─► TrendAnalysisService
              └─► DataService (historical data)
                  └─► ML-based trend prediction

SalaryTrendChart
  └─► ChartViewModel
      └─► ChartDataService
          └─► Format data for Charts library
```

---

### ⚙️ **Settings Feature** (`Features/Settings/`)

#### File Structure:
```
Features/Settings/
├── ViewModels/
│   ├── SettingsViewModel.swift ─────────► SecurityService, DataService
│   ├── SecurityViewModel.swift ─────────► BiometricAuthService
│   └── AppearanceViewModel.swift ───────► AppearanceManager
│
├── Views/
│   ├── SettingsView.swift ──────────────► SettingsViewModel
│   ├── SecuritySettingsView.swift ──────► SecurityViewModel
│   ├── AppearanceSettingsView.swift ────► AppearanceViewModel
│   ├── DataManagementView.swift ────────► SettingsViewModel
│   │
│   └── Components/
│       ├── SettingsRow.swift
│       ├── ToggleRow.swift
│       └── InfoRow.swift
│
└── Services/
    └── SettingsStorageService.swift ────► UserDefaults
```

#### Dependency Flow:
```
SettingsView
  └─► SettingsViewModel
      ├─► DataService (data management)
      ├─► SecurityService (security settings)
      └─► AppearanceManager (theme settings)

SecuritySettingsView
  └─► SecurityViewModel
      └─► BiometricAuthService
          └─► LocalAuthentication (Face ID/Touch ID)
```

---

### 📤 **WebUpload Feature** (`Features/WebUpload/`)

#### File Structure:
```
Features/WebUpload/
├── ViewModels/
│   └── WebUploadViewModel.swift ────────► WebUploadService
│
├── Views/
│   ├── WebUploadView.swift ─────────────► WebUploadViewModel
│   └── UploadProgressView.swift ────────► WebUploadViewModel
│
├── Services/
│   ├── WebUploadService.swift ──────────► NetworkClient
│   ├── Components/
│   │   ├── UploadProgressTracker.swift
│   │   └── UploadRetryHandler.swift
│   │
│   └── WebUploadNetworkService.swift ───► URLSession
│
├── Handlers/
│   └── UploadErrorHandler.swift
│
└── Models/
    ├── UploadRequest.swift
    ├── UploadResponse.swift
    └── UploadProgress.swift
```

#### Dependency Flow:
```
WebUploadView
  └─► WebUploadViewModel
      └─► WebUploadService
          ├─► NetworkClient (HTTP requests)
          ├─► UploadProgressTracker (progress monitoring)
          └─► UploadRetryHandler (retry logic)
```

---

## 🔧 Services Layer Dependencies

### **PDF Processing Services**

```
PDFService.swift (Core PDF operations)
  ├─► PDFKit
  └─► Used by: PDFProcessingService, PDFManager

PDFProcessingService.swift (Main orchestrator)
  ├─► PDFService
  ├─► PDFExtractor
  ├─► ParsingCoordinator
  └─► FormatDetectionService
  └─► Used by: HomeViewModel, PayslipDetailViewModel

UnifiedMilitaryPayslipProcessor.swift (Military parsing)
  ├─► UniversalPayCodeSearchEngine
  ├─► SpatialAnalyzer
  ├─► RiskHardshipProcessor
  ├─► MilitaryAbbreviationsService
  └─► Used by: PDFProcessingService

UniversalPayCodeSearchEngine.swift (Pay code detection)
  ├─► PayCodePatternGenerator
  ├─► PayCodeClassificationEngine
  ├─► ParallelPayCodeProcessor
  └─► Used by: UnifiedMilitaryPayslipProcessor, PDFExtractor
```

### **Data Services**

```
DataService.swift (SwiftData wrapper)
  ├─► SwiftData ModelContext
  ├─► PayslipRepository
  └─► Used by: All ViewModels

BackupService.swift (Backup/Restore)
  ├─► FileManager
  ├─► CloudKitManager
  └─► Used by: PayslipsViewModel, SettingsViewModel

AnalyticsService.swift (Analytics tracking)
  ├─► AnalyticsManager
  ├─► EventTracker
  └─► Used by: HomeViewModel, InsightsViewModel
```

### **Security Services**

```
SecurityService.swift (Security orchestrator)
  ├─► BiometricAuthService
  ├─► EncryptionService
  ├─► KeychainSecureStorage
  └─► Used by: SettingsViewModel, AuthenticationView

BiometricAuthService.swift (Biometric auth)
  ├─► LocalAuthentication
  └─► Used by: SecurityViewModel, PayslipMaxApp

PayslipEncryptionService.swift (Data encryption)
  ├─► CryptoKit
  ├─► KeychainSecureStorage
  └─► Used by: DataService, BackupService
```

---

## 📐 Spatial Intelligence Layer

### **SpatialAnalyzer Dependencies**

```
SpatialAnalyzer.swift (Main spatial processor)
  ├─► SpatialRelationshipCalculator
  ├─► ColumnBoundaryDetector
  ├─► RowAssociator
  ├─► MergedCellDetector
  └─► Used by: UnifiedMilitaryPayslipProcessor, TabularDataExtractor

SpatialRelationshipCalculator.swift (Relationship scoring)
  ├─► Mathematical algorithms for proximity, alignment
  └─► Used by: SpatialAnalyzer

ColumnBoundaryDetector.swift (Column detection)
  ├─► BoundaryValidationService
  ├─► WhitespaceAnalyzer
  └─► Used by: SpatialAnalyzer, TabularDataExtractor

RowAssociator.swift (Row grouping)
  ├─► VerticalClusterAnalyzer
  ├─► MultiLineCellMerger
  └─► Used by: SpatialAnalyzer, TabularDataExtractor

MergedCellDetector.swift (Merged cell detection)
  ├─► Span analysis algorithms
  └─► Used by: SpatialAnalyzer
```

---

## 🎯 Models Layer Dependencies

### **Core Models**

```
PayslipItem.swift (Main data model)
  ├─► SwiftData @Model
  ├─► Codable
  ├─► PayslipProtocol
  └─► Used by: DataService, all ViewModels

PayslipProtocol.swift (Protocol hierarchy)
  ├─► PayslipBaseProtocol
  ├─► PayslipDataProtocol
  ├─► PayslipEncryptionProtocol
  └─► Implemented by: PayslipItem, PayslipDTO

PayslipDTO.swift (Data Transfer Object)
  ├─► Codable
  └─► Used by: PDFProcessingService, ParsingCoordinator

EarningsDeductionsData.swift (Financial data)
  ├─► Earnings dictionary
  ├─► Deductions dictionary
  └─► Used by: UnifiedMilitaryPayslipProcessor
```

### **Parsing Models**

```
PositionalElement.swift (PDF element)
  ├─► Position (x, y)
  ├─► Bounds (width, height)
  ├─► Text content
  └─► Used by: SpatialAnalyzer, PDFExtractor

TableStructure.swift (Table data)
  ├─► Rows
  ├─► Column boundaries
  ├─► Merged cells
  └─► Used by: TabularDataExtractor

PatternDefinition.swift (Extraction pattern)
  ├─► Pattern type
  ├─► Regex pattern
  ├─► Priority
  └─► Used by: PatternExtractor, PatternMatcher
```

---

## 🎨 Views Layer Dependencies

### **Shared Components**

```
PayslipCard.swift
  └─► Uses: PayslipItem model

ChartView.swift
  └─► Uses: ChartData model, Charts framework

LoadingView.swift
  └─► Uses: GlobalLoadingManager

ErrorView.swift
  └─► Uses: ErrorHandlingViews, PayslipError model
```

### **Navigation Components**

```
MainTabView.swift (Tab container)
  ├─► HomeTab
  ├─► PayslipsTab
  ├─► InsightsTab
  ├─► SettingsTab
  └─► Uses: TabConfiguration

NavRouter.swift (Navigation state)
  ├─► NavigationPath (per tab)
  ├─► RouterProtocol
  └─► Used by: All navigation coordinators

AppCoordinator.swift (Main coordinator)
  ├─► NavRouter
  ├─► DeepLinkCoordinator
  └─► Used by: PayslipMaxApp
```

---

## 🔄 Critical Dependency Paths

### **Path 1: PDF Import → Parsed Payslip**

```
1. User taps import button
   └─► FileImportHandler

2. FileImportHandler.swift
   └─► PDFManager.savePDF()

3. HomeViewModel.processPDF()
   └─► PDFProcessingService.processPDFData()

4. PDFProcessingService
   └─► PayslipProcessingPipeline.executePipeline()

5. PayslipProcessingPipeline
   ├─► ValidationStep (validate PDF)
   ├─► TextExtractionStep (extract text)
   ├─► FormatDetectionStep (detect format)
   └─► ProcessingStep (parse data)

6. ProcessingStep
   └─► UnifiedMilitaryPayslipProcessor.process()

7. UnifiedMilitaryPayslipProcessor
   ├─► UniversalPayCodeSearchEngine.searchAllPayCodes()
   ├─► SpatialAnalyzer.extractFinancialData()
   └─► PayslipBuilder.buildPayslipItem()

8. Result: PayslipItem created
   └─► DataService.save()
   └─► HomeViewModel updates UI
```

### **Path 2: View Payslip Detail**

```
1. User taps payslip card
   └─► PayslipsListView navigation

2. PayslipDetailView appears
   └─► PayslipDetailViewModel.loadPayslip()

3. PayslipDetailViewModel
   ├─► DataService.fetchPayslip(id)
   └─► PDFManager.loadPDF(url)

4. PDF displayed
   └─► PDFViewerView (using PDFKit)
```

### **Path 3: Generate Insights**

```
1. User opens Insights tab
   └─► InsightsView

2. InsightsViewModel.onAppear()
   └─► AnalyticsService.generateInsights()

3. AnalyticsService
   ├─► ChartDataService.getMonthlyData()
   │   └─► DataService.fetchPayslips(dateRange)
   │
   └─► TrendAnalysisService.analyzeTrends()
       └─► DataService.fetchPayslips(all)

4. Data formatted for charts
   └─► SalaryTrendChart displays
```

---

## 🧪 Testing Dependencies

### **Test File Organization**

```
PayslipMaxTests/
├── Core/
│   ├── DIContainerTests.swift ──────────► Tests DI resolution
│   └── ServiceFactoryTests.swift ───────► Tests factory methods
│
├── Services/
│   ├── PDFProcessingServiceTests.swift ─► Mock PDFService
│   ├── DataServiceTests.swift ──────────► Mock ModelContext
│   └── ValidationServiceTests.swift ────► Mock validators
│
├── Parsing/
│   ├── UnifiedMilitaryPayslipProcessorTests.swift
│   ├── UniversalPayCodeSearchEngineTests.swift
│   └── SpatialAnalyzerTests.swift
│
├── ViewModels/
│   ├── HomeViewModelTests.swift ────────► Mock services
│   └── PayslipsViewModelTests.swift ───► Mock services
│
└── Integration/
    ├── EndToEndParsingTests.swift ─────► Full pipeline
    └── RH12DualSectionTests.swift ─────► Specific scenarios
```

---

## 📚 Protocol Definitions (Interfaces)

### **Service Protocols**

```
PDFProcessingServiceProtocol
  └─► Implemented by: PDFProcessingService
  └─► Used by: HomeViewModel, PayslipDetailViewModel

DataServiceProtocol
  └─► Implemented by: DataService
  └─► Used by: All ViewModels

PDFParsingCoordinatorProtocol
  └─► Implemented by: UnifiedPDFParsingCoordinator
  └─► Used by: PDFProcessingService

UniversalPayCodeSearchEngineProtocol
  └─► Implemented by: UniversalPayCodeSearchEngine
  └─► Used by: UnifiedMilitaryPayslipProcessor

SpatialAnalyzerProtocol
  └─► Implemented by: SpatialAnalyzer
  └─► Used by: UnifiedMilitaryPayslipProcessor, TabularDataExtractor
```

---

## 🔗 Critical File Relationships

### **Most Referenced Files (Hub Files)**

1. **PayslipItem.swift** (Data Model)
   - Referenced by: 200+ files
   - Used in: ViewModels, Services, Views, Tests

2. **DIContainer.swift** (Service Registry)
   - Referenced by: 150+ files
   - Used by: All ViewModels, Tests

3. **PDFProcessingService.swift** (PDF Orchestrator)
   - Referenced by: 80+ files
   - Used by: ViewModels, Handlers

4. **DataService.swift** (Data Layer)
   - Referenced by: 100+ files
   - Used by: All ViewModels, Services

5. **UnifiedMilitaryPayslipProcessor.swift** (Parser)
   - Referenced by: 50+ files
   - Used by: PDFProcessingService, Tests

### **Most Dependent Files (Leaf Files)**

1. **HomeView.swift**
   - Depends on: HomeViewModel only
   - No files depend on it

2. **PayslipCard.swift**
   - Depends on: PayslipItem model
   - Used by: HomeView, PayslipsListView

3. **SalaryTrendChart.swift**
   - Depends on: ChartViewModel, Charts library
   - Used by: InsightsView

---

## 🎯 Dependency Injection Flow

```
App Launch
  └─► PayslipMaxApp.swift
      └─► DIContainer.shared initialized
          │
          ├─► CoreServiceContainer created
          │   ├─► PDFService registered
          │   ├─► SecurityService registered
          │   ├─► DataService registered
          │   └─► ValidationService registered
          │
          ├─► ProcessingContainer created (depends on CoreServiceContainer)
          │   ├─► PDFProcessingService registered
          │   ├─► UnifiedMilitaryPayslipProcessor registered
          │   └─► ParsingCoordinator registered
          │
          ├─► ViewModelContainer created (depends on both above)
          │   ├─► HomeViewModel registered
          │   ├─► PayslipsViewModel registered
          │   └─► InsightsViewModel registered
          │
          └─► FeatureContainer created
              ├─► WebUploadService registered
              └─► GamificationCoordinator registered

View Creation
  └─► HomeView.init()
      └─► DIContainer.shared.makeHomeViewModel()
          └─► HomeViewModel initialized with injected services
              ├─► DataService (from CoreServiceContainer)
              ├─► PDFProcessingService (from ProcessingContainer)
              └─► AnalyticsService (from FeatureContainer)
```

---

## 🧩 Module Interaction Matrix

| Module | Depends On | Used By |
|--------|-----------|---------|
| DIContainer | None | Everyone |
| PDFService | PDFKit | PDFProcessingService, PDFManager |
| PDFProcessingService | PDFService, Parsers | HomeViewModel, PayslipDetailViewModel |
| UnifiedMilitaryPayslipProcessor | UniversalPayCodeSearchEngine, SpatialAnalyzer | PDFProcessingService |
| DataService | SwiftData | All ViewModels |
| HomeViewModel | DataService, PDFProcessingService | HomeView |
| PayslipsViewModel | DataService, BackupService | PayslipsListView |
| InsightsViewModel | DataService, AnalyticsService | InsightsView |
| SecurityService | BiometricAuthService, EncryptionService | SettingsViewModel |

---

## 📝 Key Takeaways

### **Architectural Patterns**
1. **Protocol-First Design**: Every service has a protocol interface
2. **Dependency Injection**: 4-layer container system prevents tight coupling
3. **MVVM Separation**: Views never directly access Services
4. **Single Responsibility**: Each file <300 lines, one clear purpose

### **Critical Dependencies**
- **DIContainer** is the root of all service creation
- **DataService** is used by every ViewModel
- **PDFProcessingService** is the core of the app's value proposition
- **PayslipItem** is the central data model

### **Dependency Flow**
```
Protocols → Services → ViewModels → Views
```

### **Testing Strategy**
- Mock protocols for unit tests
- DI container supports test injection
- Integration tests use real pipeline

---

**End of Dependency Tree**

For questions about specific file interactions, search this document for the filename.

