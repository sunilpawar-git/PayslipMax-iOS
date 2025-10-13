# PayslipMax Visual Dependency Map
**Interactive diagrams showing file relationships**

---

## 🎯 Core Architecture Diagram

```mermaid
graph TB
    subgraph "Application Entry"
        App[PayslipMaxApp.swift]
    end

    subgraph "Dependency Injection Layer"
        DIC[DIContainer.swift]
        CSC[CoreServiceContainer]
        PC[ProcessingContainer]
        VMC[ViewModelContainer]
        FC[FeatureContainer]
    end

    subgraph "Service Layer"
        PDF[PDFService]
        SEC[SecurityService]
        DATA[DataService]
        PROC[PDFProcessingService]
        UMP[UnifiedMilitaryPayslipProcessor]
        WEB[WebUploadService]
    end

    subgraph "ViewModel Layer"
        HVM[HomeViewModel]
        PVM[PayslipsViewModel]
        IVM[InsightsViewModel]
        SVM[SettingsViewModel]
    end

    subgraph "View Layer"
        HV[HomeView]
        PV[PayslipsListView]
        IV[InsightsView]
        SV[SettingsView]
    end

    App --> DIC
    DIC --> CSC
    DIC --> PC
    DIC --> VMC
    DIC --> FC

    CSC --> PDF
    CSC --> SEC
    CSC --> DATA

    PC --> PROC
    PC --> UMP
    PC -.depends on.-> CSC

    VMC --> HVM
    VMC --> PVM
    VMC --> IVM
    VMC --> SVM
    VMC -.depends on.-> PC
    VMC -.depends on.-> CSC

    FC --> WEB

    HVM --> HV
    PVM --> PV
    IVM --> IV
    SVM --> SV

    HVM -.uses.-> DATA
    HVM -.uses.-> PROC
    PVM -.uses.-> DATA
    IVM -.uses.-> DATA
    SVM -.uses.-> SEC
    SVM -.uses.-> DATA
```

---

## 📄 PDF Processing Pipeline

```mermaid
graph LR
    subgraph "User Action"
        UI[User Imports PDF]
    end

    subgraph "Handler Layer"
        FIH[FileImportHandler]
    end

    subgraph "ViewModel Layer"
        HVM[HomeViewModel]
    end

    subgraph "Service Layer"
        PDFS[PDFProcessingService]
        PPP[PayslipProcessingPipeline]
    end

    subgraph "Pipeline Steps"
        VS[ValidationStep]
        TES[TextExtractionStep]
        FDS[FormatDetectionStep]
        PS[ProcessingStep]
    end

    subgraph "Processing"
        UMP[UnifiedMilitaryPayslipProcessor]
        UPCS[UniversalPayCodeSearchEngine]
        SA[SpatialAnalyzer]
    end

    subgraph "Result"
        PI[PayslipItem]
        DS[DataService.save]
    end

    UI --> FIH
    FIH --> HVM
    HVM --> PDFS
    PDFS --> PPP
    PPP --> VS
    VS --> TES
    TES --> FDS
    FDS --> PS
    PS --> UMP
    UMP --> UPCS
    UMP --> SA
    UPCS --> PI
    SA --> PI
    PI --> DS
```

---

## 🔍 Parsing Layer Dependencies

```mermaid
graph TD
    subgraph "Main Processor"
        UMP[UnifiedMilitaryPayslipProcessor]
    end

    subgraph "Universal Search"
        UPCS[UniversalPayCodeSearchEngine]
        PCPG[PayCodePatternGenerator]
        PCCE[PayCodeClassificationEngine]
        PPC[ParallelPayCodeProcessor]
    end

    subgraph "Spatial Intelligence"
        SA[SpatialAnalyzer]
        SRC[SpatialRelationshipCalculator]
        CBD[ColumnBoundaryDetector]
        RA[RowAssociator]
        MCD[MergedCellDetector]
        MLCM[MultiLineCellMerger]
    end

    subgraph "Classification"
        RHP[RiskHardshipProcessor]
        PSC[PayslipSectionClassifier]
        MAS[MilitaryAbbreviationsService]
    end

    subgraph "Data"
        JSON[military_abbreviations.json]
    end

    UMP --> UPCS
    UMP --> SA
    UMP --> RHP

    UPCS --> PCPG
    UPCS --> PCCE
    UPCS --> PPC

    SA --> SRC
    SA --> CBD
    SA --> RA
    SA --> MCD

    RA --> MLCM

    RHP --> PSC

    MAS --> JSON
    PCCE --> MAS
```

---

## 🏠 Home Feature Module

```mermaid
graph TB
    subgraph "Views"
        HV[HomeView]
        HQS[HomeQuizSection]
        HSS[HomeStatsSection]
        PC[PayslipCard]
        QA[QuickActionsView]
    end

    subgraph "ViewModels"
        HVM[HomeViewModel]
        QVM[QuizViewModel]
    end

    subgraph "Handlers"
        PDFHandler[PDFProcessingHandler]
        ErrorHandler[ErrorHandler]
        FileHandler[FileImportHandler]
    end

    subgraph "Services"
        DATA[DataService]
        PDFS[PDFProcessingService]
        ANAL[AnalyticsService]
        PDFM[PDFManager]
    end

    HV --> HVM
    HV --> HQS
    HV --> HSS
    HV --> PC
    HV --> QA

    HQS --> QVM
    HSS --> HVM

    HVM --> DATA
    HVM --> PDFS
    HVM --> ANAL

    PDFHandler --> PDFS
    FileHandler --> PDFM

    HVM -.uses.-> PDFHandler
    HVM -.uses.-> FileHandler
    HVM -.uses.-> ErrorHandler
```

---

## 📊 Insights Feature Module

```mermaid
graph TB
    subgraph "Views"
        IV[InsightsView]
        STC[SalaryTrendChart]
        DB[DeductionBreakdown]
        MCC[MonthlyComparisonChart]
        IC[InsightCard]
    end

    subgraph "ViewModels"
        IVM[InsightsViewModel]
        CVM[ChartViewModel]
        TVM[TrendsViewModel]
    end

    subgraph "Services"
        AS[AnalyticsService]
        CDS[ChartDataService]
        TAS[TrendAnalysisService]
        IGS[InsightGeneratorService]
        DATA[DataService]
    end

    subgraph "Models"
        ID[InsightData]
        TD[TrendData]
        CC[ChartConfiguration]
    end

    IV --> IVM
    IV --> STC
    IV --> DB
    IV --> MCC
    IV --> IC

    STC --> CVM
    DB --> CVM
    MCC --> CVM

    IVM --> AS
    CVM --> CDS
    TVM --> TAS

    AS --> CDS
    AS --> TAS
    AS --> IGS

    CDS --> DATA
    TAS --> DATA
    IGS --> DATA

    CVM --> CC
    IVM --> ID
    TVM --> TD
```

---

## ⚙️ Settings Feature Module

```mermaid
graph TB
    subgraph "Views"
        SV[SettingsView]
        SSV[SecuritySettingsView]
        ASV[AppearanceSettingsView]
        DMV[DataManagementView]
        SR[SettingsRow]
        TR[ToggleRow]
    end

    subgraph "ViewModels"
        SVM[SettingsViewModel]
        SecVM[SecurityViewModel]
        AppVM[AppearanceViewModel]
    end

    subgraph "Services"
        DATA[DataService]
        SEC[SecurityService]
        BIO[BiometricAuthService]
        AM[AppearanceManager]
        SSS[SettingsStorageService]
    end

    SV --> SVM
    SV --> SSV
    SV --> ASV
    SV --> DMV
    SV --> SR
    SV --> TR

    SSV --> SecVM
    ASV --> AppVM
    DMV --> SVM

    SVM --> DATA
    SVM --> SEC
    SVM --> AM
    SVM --> SSS

    SecVM --> BIO
    AppVM --> AM

    BIO --> LA[LocalAuthentication]
```

---

## 📱 Feature Module Interactions

```mermaid
graph LR
    subgraph "Features"
        HOME[Home Feature]
        PAYSLIPS[Payslips Feature]
        INSIGHTS[Insights Feature]
        SETTINGS[Settings Feature]
        WEBUPLOAD[WebUpload Feature]
    end

    subgraph "Shared Services"
        DATA[DataService]
        PDFS[PDFProcessingService]
        ANAL[AnalyticsService]
        SEC[SecurityService]
    end

    subgraph "Shared Data"
        PI[PayslipItem Model]
    end

    HOME --> DATA
    HOME --> PDFS
    HOME --> ANAL

    PAYSLIPS --> DATA
    PAYSLIPS --> PDFS

    INSIGHTS --> DATA
    INSIGHTS --> ANAL

    SETTINGS --> DATA
    SETTINGS --> SEC

    WEBUPLOAD --> PDFS

    DATA --> PI
    PDFS --> PI
```

---

## 🧪 Testing Architecture

```mermaid
graph TB
    subgraph "Test Layers"
        UT[Unit Tests]
        IT[Integration Tests]
        UIT[UI Tests]
    end

    subgraph "Unit Test Targets"
        SUT[Service Tests]
        VMT[ViewModel Tests]
        MT[Model Tests]
        PT[Parser Tests]
    end

    subgraph "Integration Test Targets"
        E2E[End-to-End Pipeline]
        FT[Feature Tests]
        DIT[DI Container Tests]
    end

    subgraph "Mock Layer"
        MS[MockServices]
        MD[MockData]
        MP[MockProtocols]
    end

    UT --> SUT
    UT --> VMT
    UT --> MT
    UT --> PT

    IT --> E2E
    IT --> FT
    IT --> DIT

    SUT --> MS
    VMT --> MS
    VMT --> MD
    PT --> MD

    MS --> MP
```

---

## 🔐 Security Layer

```mermaid
graph TD
    subgraph "Security Entry Points"
        AUTH[Authentication Flow]
        ENCRYPT[Data Encryption]
        STORAGE[Secure Storage]
    end

    subgraph "Security Services"
        SEC[SecurityService]
        BIO[BiometricAuthService]
        ENC[PayslipEncryptionService]
        KS[KeychainSecureStorage]
    end

    subgraph "System Frameworks"
        LA[LocalAuthentication]
        CK[CryptoKit]
        KC[Keychain]
    end

    subgraph "Protected Data"
        PI[PayslipItem.sensitiveData]
        CREDS[User Credentials]
        KEYS[Encryption Keys]
    end

    AUTH --> SEC
    ENCRYPT --> SEC
    STORAGE --> SEC

    SEC --> BIO
    SEC --> ENC
    SEC --> KS

    BIO --> LA
    ENC --> CK
    KS --> KC

    ENC --> PI
    KS --> CREDS
    KS --> KEYS
```

---

## 📦 Data Flow Architecture

```mermaid
sequenceDiagram
    participant User
    participant HomeView
    participant HomeViewModel
    participant PDFProcessingService
    participant UnifiedMilitaryPayslipProcessor
    participant DataService
    participant SwiftData

    User->>HomeView: Imports PDF
    HomeView->>HomeViewModel: processPDF(data)
    HomeViewModel->>PDFProcessingService: processPDFData(data)
    PDFProcessingService->>UnifiedMilitaryPayslipProcessor: process(text, elements)
    UnifiedMilitaryPayslipProcessor-->>PDFProcessingService: PayslipItem
    PDFProcessingService-->>HomeViewModel: Result.success(payslip)
    HomeViewModel->>DataService: save(payslip)
    DataService->>SwiftData: insert(payslip)
    SwiftData-->>DataService: Success
    DataService-->>HomeViewModel: Success
    HomeViewModel-->>HomeView: Update UI
    HomeView-->>User: Show success
```

---

## 🎯 Critical Paths

### Path 1: App Launch to Ready State

```mermaid
graph LR
    A[App Launch] --> B[PayslipMaxApp.init]
    B --> C[DIContainer.shared]
    C --> D[Create CoreServiceContainer]
    C --> E[Create ProcessingContainer]
    C --> F[Create ViewModelContainer]
    D --> G[Services Ready]
    E --> G
    F --> G
    G --> H[MainTabView Displayed]
    H --> I[App Ready]
```

### Path 2: PDF Import to Saved Payslip

```mermaid
graph LR
    A[User Selects PDF] --> B[FileImportHandler]
    B --> C[HomeViewModel.processPDF]
    C --> D[PDFProcessingService]
    D --> E[Pipeline Execution]
    E --> F[UnifiedMilitaryPayslipProcessor]
    F --> G[PayslipItem Created]
    G --> H[DataService.save]
    H --> I[SwiftData Persistence]
    I --> J[UI Updated]
```

### Path 3: View Payslip Details

```mermaid
graph LR
    A[User Taps Card] --> B[Navigation]
    B --> C[PayslipDetailView]
    C --> D[PayslipDetailViewModel.load]
    D --> E[DataService.fetch]
    E --> F[PayslipItem Retrieved]
    F --> G[PDFManager.loadPDF]
    G --> H[PDF Displayed]
```

---

## 🔗 Module Dependency Matrix

| Module | Core DI | PDF Service | Data Service | Security | Analytics |
|--------|---------|-------------|--------------|----------|-----------|
| **Home** | ✅ | ✅ | ✅ | ❌ | ✅ |
| **Payslips** | ✅ | ✅ | ✅ | ❌ | ❌ |
| **Insights** | ✅ | ❌ | ✅ | ❌ | ✅ |
| **Settings** | ✅ | ❌ | ✅ | ✅ | ❌ |
| **WebUpload** | ✅ | ✅ | ❌ | ❌ | ❌ |
| **Authentication** | ✅ | ❌ | ❌ | ✅ | ❌ |
| **Backup** | ✅ | ✅ | ✅ | ❌ | ❌ |

---

## 📊 File Count by Category

```mermaid
pie title Swift Files Distribution
    "Services (260)" : 260
    "Views (77)" : 77
    "Features (100+)" : 100
    "Models (57)" : 57
    "Core (120+)" : 120
    "Navigation (24)" : 24
    "Protocols (23)" : 23
    "ViewModels (20+)" : 20
    "Shared (13)" : 13
    "Managers (4)" : 4
    "Extensions (3)" : 3
```

---

## 🎭 Protocol Hierarchy

```mermaid
graph TD
    subgraph "Service Protocols"
        PSP[PDFProcessingServiceProtocol]
        DSP[DataServiceProtocol]
        SSP[SecurityServiceProtocol]
        PCP[PDFParsingCoordinatorProtocol]
        UPCSP[UniversalPayCodeSearchEngineProtocol]
        SAP[SpatialAnalyzerProtocol]
    end

    subgraph "Data Protocols"
        PP[PayslipProtocol]
        PBP[PayslipBaseProtocol]
        PDP[PayslipDataProtocol]
        PEP[PayslipEncryptionProtocol]
        PMP[PayslipMetadataProtocol]
    end

    subgraph "Container Protocols"
        CSCP[CoreServiceContainerProtocol]
        PCP2[ProcessingContainerProtocol]
        VMCP[ViewModelContainerProtocol]
        FCP[FeatureContainerProtocol]
    end

    PP --> PBP
    PP --> PDP
    PP --> PEP
    PP --> PMP

    PSP -.implemented by.-> PDFS[PDFProcessingService]
    DSP -.implemented by.-> DS[DataService]
    SSP -.implemented by.-> SS[SecurityService]
```

---

## 🚀 Performance Monitoring Flow

```mermaid
graph LR
    subgraph "Monitoring Points"
        A[PDF Import]
        B[Text Extraction]
        C[Parsing]
        D[Validation]
        E[Save]
    end

    subgraph "Performance Trackers"
        PT[PerformanceTracker]
        DSP[DualSectionPerformanceMonitor]
        EMM[EnhancedMemoryManager]
    end

    subgraph "Metrics"
        T[Time]
        M[Memory]
        S[Success Rate]
    end

    A --> PT
    B --> PT
    C --> DSP
    D --> PT
    E --> PT

    PT --> T
    DSP --> T
    DSP --> M
    EMM --> M

    T --> LOGS[Performance Logs]
    M --> LOGS
    S --> LOGS
```

---

## 📝 Summary

### Key Insights

1. **4-Layer DI Architecture**
   - Clear separation: Core → Processing → ViewModel → Feature
   - Protocol-first design enables testability

2. **Service Dependencies**
   - DataService: Used by every ViewModel
   - PDFProcessingService: Core value proposition
   - UnifiedMilitaryPayslipProcessor: Parsing brain

3. **Feature Independence**
   - Each feature module is self-contained
   - Shared services accessed via DI
   - No cross-feature dependencies

4. **MVVM Compliance**
   - Views only know ViewModels
   - ViewModels coordinate Services
   - Services never import SwiftUI

5. **Testing Strategy**
   - Protocols enable mocking
   - DI supports test injection
   - Integration tests validate full pipeline

---

**For Interactive Viewing:**
Copy any Mermaid diagram into [Mermaid Live Editor](https://mermaid.live/) for interactive exploration.

