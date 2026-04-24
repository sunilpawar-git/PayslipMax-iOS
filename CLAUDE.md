# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

---

## Build & Test Commands

```bash
# Build
xcodebuild clean build -scheme PayslipMax -configuration Debug

# Run all tests
xcodebuild test -scheme PayslipMax -destination 'platform=iOS Simulator,name=iPhone 17 Pro'

# Run a specific test suite
xcodebuild test -scheme PayslipMax -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -only-testing:PayslipMaxTests/HomeViewModelTests

# Lint
swiftlint lint --config .swiftlint.yml

# Check architecture violations
./Scripts/architecture-guard.sh

# Deploy backend (Cloud Functions)
cd backend/functions && firebase deploy --only functions
```

---

## Architecture Overview

**MVVM + Protocol-based Dependency Injection**, targeting iOS 18.1+, Swift 6.0.

### Layer map

```
Views (SwiftUI)
  └── ViewModels (@MainActor ObservableObject)
        └── Services (protocol-based, injected via DI containers)
              └── Models (SwiftData: PayslipItem, LLMUsageRecord)
```

Features live under `PayslipMax/Features/<FeatureName>/` — each folder has `Views/`, `ViewModels/`, `Services/`, `Models/`. Cross-cutting services live under `PayslipMax/Services/`.

---

## Dependency Injection

`DIContainer.shared` is the root container. It owns four sub-containers wired at init time:

| Container | Owns |
|-----------|------|
| `CoreServiceContainer` | PDF, security, data, encryption, validation services |
| `ProcessingContainer` | Payslip parsing pipeline, LLM services, batch processing |
| `ViewModelContainer` | ViewModel factories |
| `FeatureContainer` | Feature-specific services (XRay, Insights, Subscription) |

**How to resolve a service:** call the appropriate `make*()` factory on the relevant container or use `AppContainer.shared.resolve(SomeProtocol.self)`.

**Rules enforced by SwiftLint custom rules:**
- Services must not `import SwiftUI` (MVVM separation).
- Views must not instantiate services directly (`let fooService = FooService()`); use the ViewModel/DI path instead.
- Avoid `.shared` singletons for business logic — use the DI containers. Exceptions are tracked in `AllowedSharedWhitelist.md`.
- Blocking APIs (`DispatchSemaphore`, `DispatchGroup`, `sleep()`) are banned — use `async/await`.

---

## Payslip Parsing Pipeline

Two entry paths feed into `HybridPayslipProcessor`:

```
PDFProcessingService
  ├── Text PDF  →  text extraction  →  HybridPayslipProcessor
  └── Scanned image
        ├── Structured OCR path (JCO/OR tabular layout detected)
        │     StructuredOCRService (Vision) → TabularTextAssembler → processOCRText
        └── Flat OCR path (fallback)
              top-band crop / full image / preprocessed image → processOCRText

HybridPayslipProcessor  (three-tier cascade)
  ├── Step 1: UniversalPayslipProcessor
  │     ├── regex + 243 military pay codes (Resources/military_abbreviations.json)
  │     ├── JCOORTextSectionSplitter  — splits flat-PDF "ACCOUNTS AT A GLANCE" text
  │     │     into credit / debit / summary streams before regex runs
  │     └── PayslipValidationCoordinator  — totals reconciliation
  ├── Step 2 (guarded fallback or low confidence): On-device LLM
  │     └── FoundationModelPayslipService  (iOS 26+, Apple Foundation Models)
  │           — zero network, zero PII; returns nil when model unavailable
  ├── Step 3 (if not offline): Cloud LLM
  │     ├── DEBUG  → GeminiLLMService (direct Gemini API)
  │     └── RELEASE → LLMBackendService → Firebase Cloud Function `parseLLM`
  └── TotalsReconciliationService  — final sanity check
```

**Confidence thresholds** differ by mode:

| Mode | Skip-LLM (excellent) | Backup-only skip (good) |
|------|----------------------|-------------------------|
| Online | 0.9 | 0.7 |
| Offline | 0.6 | 0.4 |

`BuildConfiguration.useBackendProxy` (false in DEBUG, true in RELEASE) gates the cloud LLM path. Offline mode (`OfflineModeService`) gates it independently — when enabled, only Steps 1–2 run regardless of `useBackendProxy`.

`ScanThreshold` (`Services/ScanThreshold.swift`) holds all magic numbers for the OCR pipeline (digit-count minimums, crop ratios). `VisionActor` serialises all `VNImageRequestHandler` calls onto a single actor.

---

## Navigation

`NavRouter` manages tab-specific navigation stacks, sheet presentations, and deep links. It is provided as `@EnvironmentObject` from `PayslipMaxApp`. All navigation goes through `NavRouter` — do not use SwiftUI's navigation APIs directly in views.

Deep links use the `payslipmax://` URL scheme; handled by `DeepLinkCoordinator`.

---

## Feature Flags

`FeatureFlagManager.shared` — check `FeatureFlagService` + `FeatureFlagConfiguration` for defaults. To add a new flag: add a case to the `Feature` enum in `FeatureFlagProtocol.swift`, then set a default in `FeatureFlagConfiguration.swift`. DI-migration feature flags were fully removed in October 2025.

---

## API Key Architecture

| Environment | Key location | LLM call path |
|-------------|-------------|---------------|
| DEBUG | Xcode scheme env var `GEMINI_API_KEY` | Direct to Gemini API |
| RELEASE | Firebase Secret (backend only) | Firebase Cloud Function `parseLLM` |

**Setup (DEBUG):** Edit Scheme → Run → Arguments → Environment Variables → `GEMINI_API_KEY`. Ensure "Shared" is **unchecked**.

`Config/APIKeys.swift` is gitignored. The pre-commit hook at `.git/hooks/pre-commit` blocks commits containing detected secrets.

---

## Offline Mode

`OfflineModeService` (`Services/Processing/OnDevice/OfflineModeService.swift`) persists the user's "100% Offline Mode" preference to UserDefaults under `OfflineModeService.offlineModeUserDefaultsKey`. One singleton is registered in `AppContainer.registerLLMServices()`.

When offline mode is on: cloud LLM (Step 3) is skipped; on-device LLM (Step 2) is still attempted if iOS 26+ device model is available. Confidence thresholds relax (see table above) so regex results are accepted more readily.

`FoundationModelPayslipService` requires `@available(iOS 26, *)` and never extracts PII (name, account, PAN fields are left empty by design — see `OnDeviceLLMResultConverter`).

---

## SwiftLint Constraints

Limits that affect day-to-day editing:

| Rule | Warning | Error |
|------|---------|-------|
| `file_length` | 280 lines | **300 lines** |
| `type_body_length` | 200 lines | 250 lines |
| `function_body_length` | 40 lines | 80 lines |
| `line_length` | 120 chars | 200 chars |

**The 300-line file limit is strictly enforced.** When a file approaches the limit, extract focused sub-components (e.g., `HomeViewModel` → `HomeViewModelActions`, `HomeViewModelSetup`, `HomeViewModelSupport`).

SwiftLint version pinned to **0.62.2** (matching CI).

---

## Data Model

`PayslipItem` is a `@Model` (SwiftData). Its source is split across:
- `PayslipItemCore.swift` — class definition and basic properties
- `PayslipItemExtensions.swift` — `Codable` and protocol conformances
- `PayslipItemFactory.swift` — factory/creation methods

`LLMUsageRecord` tracks per-user LLM call history (also a SwiftData `@Model`).

Sensitive fields (name, account number, PAN) are encrypted at rest via `PayslipEncryptionService` / `AsyncSensitiveDataHandler`.

---

## Testing Notes

- Test files mirror the source structure under `PayslipMaxTests/`.
- Mocks live in `PayslipMaxTests/Mocks/` — one file per service interface.
- Test files also have the 300-line limit; split them the same way as source files.
- UI tests pass `UI_TESTING` launch argument to use an in-memory `ModelContainer` with pre-seeded data (see `PayslipMaxApp+Startup.swift`).
- The `BaseTestCase` + `TestDIContainer` pattern provides a pre-wired mock container for unit tests.

---

## CI Pipeline (`ios-ci.yml`)

Runs on all branches and PRs. Stages:

1. **Validate** (ubuntu) — detects whether Swift/lint files changed.
2. **SwiftLint** (macos-latest) — strict; failures block merge.
3. **Build + Test** (macos-15, Xcode 16.1, iPhone 17 Pro simulator).

Architecture quality workflow (`architecture-quality.yml`) is disabled for automatic runs — trigger manually via `workflow_dispatch` if needed.
