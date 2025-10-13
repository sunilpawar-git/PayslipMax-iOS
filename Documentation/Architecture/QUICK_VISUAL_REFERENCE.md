# PayslipMax Quick Visual Reference
**All Key Diagrams in One Place**

---

## 🏗️ 1. Complete System Architecture

```mermaid
graph TB
    subgraph "Application Entry"
        App[PayslipMaxApp.swift]
    end

    subgraph "Dependency Injection Layer"
        DIC[DIContainer.swift<br/>40+ Services]
        CSC[CoreServiceContainer<br/>PDF, Security, Data]
        PC[ProcessingContainer<br/>Parsing Pipeline]
        VMC[ViewModelContainer<br/>8+ ViewModels]
        FC[FeatureContainer<br/>Features]
    end

    subgraph "Service Layer"
        PDF[PDFService]
        SEC[SecurityService]
        DATA[DataService]
        PROC[PDFProcessingService]
        UMP[UnifiedMilitaryPayslipProcessor<br/>⭐ Parsing Brain]
        UPCS[UniversalPayCodeSearchEngine<br/>⭐ Code Detection]
        SA[SpatialAnalyzer<br/>⭐ Spatial Intelligence]
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
    PC --> UPCS
    PC --> SA
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

    style UMP fill:#ff9999
    style UPCS fill:#ff9999
    style SA fill:#ff9999
    style DIC fill:#99ccff
    style DATA fill:#99ff99
```

---

## 📄 2. PDF Processing Pipeline (End-to-End)

```mermaid
graph LR
    subgraph "1. User Action"
        UI[👤 User Imports PDF]
    end

    subgraph "2. Handler"
        FIH[FileImportHandler]
    end

    subgraph "3. ViewModel"
        HVM[HomeViewModel<br/>processPDF]
    end

    subgraph "4. Main Service"
        PDFS[PDFProcessingService<br/>processPDFData]
    end

    subgraph "5. Pipeline Execution"
        PPP[PayslipProcessingPipeline]
        VS[1️⃣ ValidationStep<br/>Check password, integrity]
        TES[2️⃣ TextExtractionStep<br/>PDFKit + Vision OCR]
        FDS[3️⃣ FormatDetectionStep<br/>Detect defense format]
        PS[4️⃣ ProcessingStep<br/>Parse data]
    end

    subgraph "6. Parsing"
        UMP[UnifiedMilitaryPayslipProcessor]
        UPCS[Universal Search<br/>40+ codes]
        SA[Spatial Analysis<br/>Table detection]
    end

    subgraph "7. Result"
        PI[✅ PayslipItem<br/>100% Accuracy]
        DS[DataService.save<br/>SwiftData]
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

    style UI fill:#ffcccc
    style PI fill:#ccffcc
    style UMP fill:#ff9999
    style UPCS fill:#ff9999
    style SA fill:#ff9999
```

---

## 🔍 3. Five-Layer Parsing Architecture

```mermaid
graph TD
    PDF[📄 PDF Document Input]

    subgraph "Layer 1: Validation"
        VAL[Password Check<br/>Integrity Verification<br/>Format Compatibility]
    end

    subgraph "Layer 2: Text Extraction"
        TEX[PDFKit Text Extraction<br/>Vision Framework OCR<br/>Memory-Efficient Processing]
    end

    subgraph "Layer 3: Format Detection"
        FMT[Defense Format ID<br/>PCDA Detection<br/>Confidence Scoring]
    end

    subgraph "Layer 4: Parallel Extraction"
        UPCS2[Universal Pay Code Search<br/>✓ 40+ military codes<br/>✓ Parallel processing]
        SA2[Spatial Intelligence<br/>✓ Column boundaries<br/>✓ Row association<br/>✓ Merged cells]
        PAT[Pattern Matching<br/>✓ 200+ regex patterns<br/>✓ Dynamic arrears<br/>✓ Grade-agnostic]
        TAB[Tabular Extraction<br/>✓ Table structure<br/>✓ Multi-column<br/>✓ Multi-line cells]
        LEG[Legacy Handler<br/>✓ Pre-Nov 2023<br/>✓ Fallback logic]
    end

    subgraph "Layer 5: Validation & QA"
        QA[Confidence Scoring 0-100<br/>Total Variance Check ±2%<br/>Component Presence Check<br/>Realistic Value Ranges]
    end

    RESULT[✅ PayslipItem Validated]

    PDF --> VAL
    VAL --> TEX
    TEX --> FMT
    FMT --> UPCS2
    FMT --> SA2
    FMT --> PAT
    FMT --> TAB
    FMT --> LEG

    UPCS2 --> QA
    SA2 --> QA
    PAT --> QA
    TAB --> QA
    LEG --> QA

    QA --> RESULT

    style PDF fill:#e1f5ff
    style RESULT fill:#c8e6c9
    style UPCS2 fill:#fff9c4
    style SA2 fill:#fff9c4
    style QA fill:#ffccbc
```

---

## 🧠 4. Parsing Intelligence Layer

```mermaid
graph TD
    subgraph "Main Processor"
        UMP[UnifiedMilitaryPayslipProcessor<br/>⭐ Orchestrator]
    end

    subgraph "🔍 Universal Search Engine"
        UPCS[UniversalPayCodeSearchEngine]
        PCPG[PayCodePatternGenerator<br/>Dynamic pattern creation]
        PCCE[PayCodeClassificationEngine<br/>200+ codes from JSON]
        PPC[ParallelPayCodeProcessor<br/>Concurrent processing]
    end

    subgraph "📐 Spatial Intelligence"
        SA[SpatialAnalyzer]
        SRC[SpatialRelationshipCalculator<br/>Proximity + Alignment scoring]
        CBD[ColumnBoundaryDetector<br/>White-space analysis]
        RA[RowAssociator<br/>Vertical clustering]
        MCD[MergedCellDetector<br/>Span detection]
        MLCM[MultiLineCellMerger<br/>Multi-line text]
    end

    subgraph "🎯 Classification"
        RHP[RiskHardshipProcessor<br/>RH11-RH33 handling]
        PSC[PayslipSectionClassifier<br/>Earnings vs Deductions]
        MAS[MilitaryAbbreviationsService]
    end

    subgraph "📊 Data Source"
        JSON[military_abbreviations.json<br/>200+ codes]
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

    style UMP fill:#ff9999
    style UPCS fill:#ffeb3b
    style SA fill:#4caf50
    style JSON fill:#2196f3,color:#fff
```

---

## 🏠 5. Home Feature Module Architecture

```mermaid
graph TB
    subgraph "Views"
        HV[HomeView<br/>Main Dashboard]
        HQS[HomeQuizSection<br/>Quiz Widget]
        HSS[HomeStatsSection<br/>Statistics]
        PC[PayslipCard<br/>Recent payslips]
        QA[QuickActionsView<br/>Import, Scan, etc.]
    end

    subgraph "ViewModels"
        HVM[HomeViewModel<br/>⭐ Coordinator]
        QVM[QuizViewModel<br/>Gamification]
    end

    subgraph "Handlers"
        PDFHandler[PDFProcessingHandler<br/>Import logic]
        ErrorHandler[ErrorHandler<br/>Error handling]
        FileHandler[FileImportHandler<br/>File operations]
    end

    subgraph "Services Used"
        DATA[DataService<br/>SwiftData]
        PDFS[PDFProcessingService<br/>Parsing]
        ANAL[AnalyticsService<br/>Tracking]
        PDFM[PDFManager<br/>Storage]
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

    HVM -.coordinates.-> PDFHandler
    HVM -.coordinates.-> FileHandler
    HVM -.coordinates.-> ErrorHandler

    style HVM fill:#ff9999
    style PDFS fill:#ffeb3b
    style DATA fill:#4caf50
```

---

## 📊 6. Insights Feature Module

```mermaid
graph TB
    subgraph "Views"
        IV[InsightsView<br/>Analytics Dashboard]
        STC[SalaryTrendChart<br/>Line chart]
        DB[DeductionBreakdown<br/>Pie chart]
        MCC[MonthlyComparisonChart<br/>Bar chart]
        IC[InsightCard<br/>AI insights]
    end

    subgraph "ViewModels"
        IVM[InsightsViewModel<br/>⭐ Coordinator]
        CVM[ChartViewModel<br/>Chart data]
        TVM[TrendsViewModel<br/>Trend analysis]
    end

    subgraph "Services"
        AS[AnalyticsService]
        CDS[ChartDataService<br/>Data formatting]
        TAS[TrendAnalysisService<br/>ML predictions]
        IGS[InsightGeneratorService<br/>AI insights]
        DATA[DataService<br/>Fetch payslips]
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

    style IVM fill:#ff9999
    style AS fill:#ffeb3b
    style DATA fill:#4caf50
```

---

## 🔐 7. Security Architecture

```mermaid
graph TD
    subgraph "Entry Points"
        AUTH[🔐 Authentication]
        ENCRYPT[🔒 Encryption]
        STORAGE[💾 Secure Storage]
    end

    subgraph "Security Services"
        SEC[SecurityService<br/>⭐ Orchestrator]
        BIO[BiometricAuthService<br/>Face ID / Touch ID]
        ENC[PayslipEncryptionService<br/>AES-256]
        KS[KeychainSecureStorage<br/>Credentials]
    end

    subgraph "System Frameworks"
        LA[LocalAuthentication<br/>iOS Framework]
        CK[CryptoKit<br/>iOS Framework]
        KC[Keychain<br/>iOS System]
    end

    subgraph "Protected Data"
        PI[PayslipItem.sensitiveData<br/>Name, Account, PAN]
        CREDS[User Credentials]
        KEYS[Encryption Keys<br/>Rotation support]
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

    style SEC fill:#ff9999
    style BIO fill:#ffeb3b
    style ENC fill:#4caf50
    style PI fill:#2196f3,color:#fff
```

---

## 🧪 8. Testing Architecture

```mermaid
graph TB
    subgraph "Test Types"
        UT[Unit Tests<br/>171 files]
        IT[Integration Tests<br/>End-to-end]
        UIT[UI Tests<br/>Critical paths]
    end

    subgraph "Unit Test Targets"
        SUT[Service Tests<br/>Mock protocols]
        VMT[ViewModel Tests<br/>Mock services]
        MT[Model Tests<br/>Data validation]
        PT[Parser Tests<br/>100% accuracy]
    end

    subgraph "Integration Tests"
        E2E[End-to-End Pipeline<br/>PDF → PayslipItem]
        FT[Feature Tests<br/>Home, Insights]
        DIT[DI Container Tests<br/>40+ services]
    end

    subgraph "Mock Layer"
        MS[MockServices<br/>Protocol implementations]
        MD[MockData<br/>Reference payslips]
        MP[MockProtocols<br/>Test doubles]
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

    style UT fill:#4caf50
    style IT fill:#ffeb3b
    style E2E fill:#ff9999
```

---

## 🔄 9. Data Flow Sequence (PDF Import)

```mermaid
sequenceDiagram
    participant U as 👤 User
    participant HV as HomeView
    participant HVM as HomeViewModel
    participant PDFS as PDFProcessingService
    participant UMP as UnifiedMilitaryPayslipProcessor
    participant UPCS as UniversalPayCodeSearchEngine
    participant SA as SpatialAnalyzer
    participant DS as DataService
    participant SD as SwiftData

    U->>HV: Taps Import PDF
    HV->>HVM: processPDF(data)
    HVM->>PDFS: processPDFData(data)

    PDFS->>PDFS: Validate PDF
    PDFS->>PDFS: Extract Text
    PDFS->>PDFS: Detect Format

    PDFS->>UMP: process(text, elements)

    par Parallel Processing
        UMP->>UPCS: searchAllPayCodes(text)
        UPCS-->>UMP: Pay codes detected
    and
        UMP->>SA: extractFinancialData(elements)
        SA-->>UMP: Spatial data extracted
    end

    UMP-->>PDFS: PayslipItem created
    PDFS-->>HVM: Result.success(payslip)

    HVM->>DS: save(payslip)
    DS->>SD: insert(payslip)
    SD-->>DS: ✅ Saved
    DS-->>HVM: ✅ Success

    HVM-->>HV: Update UI
    HV-->>U: ✅ Show Success

    Note over UPCS,SA: 5-Layer parsing<br/>100% accuracy
```

---

## 🎯 10. Critical Path: App Launch

```mermaid
graph LR
    A[🚀 App Launch] --> B[PayslipMaxApp.init]
    B --> C[DIContainer.shared]

    C --> D[Create CoreServiceContainer]
    C --> E[Create ProcessingContainer]
    C --> F[Create ViewModelContainer]
    C --> G[Create FeatureContainer]

    D --> H{Services Ready}
    E --> H
    F --> H
    G --> H

    H --> I[MainTabView Displayed]
    I --> J[HomeView Loaded]
    J --> K[HomeViewModel Initialized]
    K --> L[✅ App Ready]

    style A fill:#e1f5ff
    style L fill:#c8e6c9
    style H fill:#fff9c4
```

---

## 📦 11. Module Dependency Matrix

```mermaid
graph LR
    subgraph "Feature Modules"
        HOME[🏠 Home]
        PAY[📄 Payslips]
        INS[📊 Insights]
        SET[⚙️ Settings]
        WEB[📤 WebUpload]
    end

    subgraph "Shared Services"
        DATA[DataService<br/>Used by ALL]
        PDFS[PDFProcessingService<br/>Used by 3]
        ANAL[AnalyticsService<br/>Used by 2]
        SEC[SecurityService<br/>Used by 1]
    end

    subgraph "Core Data"
        PI[PayslipItem<br/>⭐ Central Model]
    end

    HOME --> DATA
    HOME --> PDFS
    HOME --> ANAL

    PAY --> DATA
    PAY --> PDFS

    INS --> DATA
    INS --> ANAL

    SET --> DATA
    SET --> SEC

    WEB --> PDFS

    DATA --> PI
    PDFS --> PI

    style DATA fill:#4caf50
    style PDFS fill:#ffeb3b
    style PI fill:#ff9999
```

---

## 📊 12. File Distribution

```mermaid
pie title "Swift Files by Category (993 total)"
    "Services (260)" : 260
    "Core Infrastructure (120)" : 120
    "Features (100)" : 100
    "Views (77)" : 77
    "Models (57)" : 57
    "Navigation (24)" : 24
    "Protocols (23)" : 23
    "ViewModels (20)" : 20
    "Tests (171)" : 171
    "Shared (13)" : 13
    "Extensions (3)" : 3
    "Managers (4)" : 4
```

---

## 🎓 Legend

**Color Code**:
- 🔴 Red/Pink: Critical files (Parsers, ViewModels, Orchestrators)
- 🟡 Yellow: Search & Detection engines
- 🟢 Green: Data & Storage services
- 🔵 Blue: External data sources (JSON, System frameworks)

**Symbols**:
- ⭐ Star: Core/Central component
- 👤 Person: User interaction point
- ✅ Checkmark: Success/Validation point
- 🔐 Lock: Security-related
- 📊 Chart: Analytics/Insights
- 🏠 House: Home feature
- 📄 Document: Payslip-related

---

## 📝 Quick Reference

**Most Important Diagrams**:
1. **#1** - Complete System Architecture (understand overall structure)
2. **#2** - PDF Processing Pipeline (understand core value proposition)
3. **#4** - Parsing Intelligence Layer (understand 100% accuracy achievement)
4. **#9** - Data Flow Sequence (understand execution flow)

**For Developers**:
- New to project? Start with **#1, #2**
- Adding feature? See **#5, #6, #7** (feature modules)
- Debugging parsing? See **#3, #4** (parsing layers)
- Understanding security? See **#7** (security architecture)

---

**Tip**: Your Mermaid plugin should render these diagrams automatically!
If not, check plugin settings or copy to https://mermaid.live/

