## PayslipMax Technical Debt Assessment and Reduction Plan

### Executive summary
PayslipMax has made strong progress toward a modular, offline‑first architecture (DI consolidation, async/await adoption, diagnostics, robust parsing pipeline). However, several areas still carry material technical debt: oversized files breaching the 300‑line policy, residual complexity in parsing and performance hot spots, incomplete automation of quality gates, and uneven test depth for legacy formats. This document inventories key debt, defines risks and impact, and presents a phased, checkbox‑driven plan to eliminate the remaining debt while protecting stability and velocity.

Key guardrails remain in force: 300‑line per file rule [[memory:1178975]], small, incremental changes, and build/test verification after each step.

---

### High‑level health snapshot
- Build status: App builds successfully (Simulator) per recent hardening docs
- Tests: Comprehensive unit tests passing (Phase 7–10 documents report full green on CI Simulator)
- Concurrency: Repo scan shows 0 `DispatchSemaphore` usages in code (only references in comments/docs). `fatalError(` only appears in disabled test files.
- DI: Single container in `Core/DI` with protocol‑oriented design per consolidation plan
- Observability: Local diagnostics bundle implemented; redaction policies in place
- Security: Keychain‑backed secure storage and deterministic backups re‑enabled

---

### Debt inventory (by category)

#### 1) Size violations (>300 lines per file)
These are the most persistent and visible violations, increasing cognitive load, merge conflicts, and defect rates. Ground‑truth scan (top examples with current line counts):
- 1110 `Services/Extraction/Military/MilitaryFinancialDataExtractor.swift`
- 1070 `Services/Extraction/ExtractionResultValidator.swift`
- 855 `Features/Insights/Services/AdvancedAnalyticsEngine.swift`
- 839 `Services/PDFParsingCoordinator.swift`
- 823 `Services/Processing/MilitaryPayslipProcessor.swift`
- 807 `Services/Extraction/TextProcessingPipeline.swift`
- 686 `Features/Payslips/ViewModels/PayslipDetailViewModel.swift`
- 662 `Services/Extraction/PayslipParserService.swift`
- 658 `Services/DocumentAnalysis.swift`
- 617 `Features/WebUpload/Views/WebUploadListView.swift`
- 606 `Models/PayslipItem.swift`
- 591 `Views/Insights/InsightsView.swift`
- 585 `Views/Subscription/PremiumPaywallView.swift`
- 566 `Services/Patterns/CorePatternsProvider.swift`
- 539 `Services/Extraction/ExtractionStrategySelector.swift`

Risk/Impact
- High: Slows feature work, hides bugs, discourages testing; complicates reviews and refactors.

Mitigation
- Extract coordinators, services, and view components into focused files; enforce 300‑line rule in CI.

#### 2) Concurrency and responsiveness
- Risk: Any residual blocking calls, implicit main‑thread work in services, or missing cancellation can cause UI hitches and poor device‑class scaling.
- Status: Roadmap indicates 0 `DispatchSemaphore` usages and migration to async/await with device‑class adaptive streaming. Needs continual audit.

Mitigation
- Repo‑wide auditors (static check in CI) for semaphore usage, synchronous PDFKit calls on main, and missing cancellation tokens.

#### 3) Error handling and recovery
- Risk: Legacy `fatalError` and insufficient error surface in edge extraction paths can lead to silent failures or crashes.
- Status: Production `fatalError` removed in critical paths per hardening notes; continue verifying across modules and examples.

Mitigation
- Centralize domain errors; surface recoverable states to UI and diagnostics; add contract tests.

#### 4) Parsing accuracy for legacy tabular PDFs
- Risk: Bilingual headers, merged cells, and right‑panel contamination degrade totals consistency and cell assignment.
- Status: Phases 11–16 in the gold checklist improve detector, spatial extractor, OCR tuning, and numeric normalization for legacy PCDA.

Mitigation
- Adopt hybrid table extraction (vector‑first lattice, then stream, then OCR) and totals‑first gating; see `Tabulated_PDF_Accuracy_Strategy.md` for prioritized plan.

#### 5) Performance and memory
- Risk: Large PDFs can still cause memory spikes if streaming thresholds or cache limits regress; need device‑class adaptive behavior.
- Status: Adaptive streaming and cache policies added; maintain baselines and continuous perf checks.

Mitigation
- Keep performance benchmarks in CI; fail on regressions beyond tolerance; memory alerts should downshift parallelism.

#### 6) Testing breadth and depth
- Risk: Disabled property tests/UI tests, limited adverse dataset breadth can hide regressions.
- Status: Broad unit coverage is strong; property/UI testing program needs further enablement and automation.

Mitigation
- Systematically enable disabled tests, expand golden/adverse datasets, and gate via CI.

#### 7) Observability and privacy
- Risk: Insufficient SLO tracking, or accidental PII in logs.
- Status: Diagnostics bundle exists with redaction; SLO dashboards can be expanded.

Mitigation
- Track latency, memory, accuracy/validation rates; ensure redaction tests and privacy checks pass.

---

### Phased technical debt reduction plan (checkboxes)

Each phase is small, independently shippable, and gated by acceptance criteria. Maintain the 300‑line policy throughout [[memory:1178975]].

#### Phase 1: Enforce file size and module boundaries (2 weeks)
Tasks
- [ ] Split `Services/Extraction/Military/MilitaryFinancialDataExtractor.swift` → `MilitaryBasicDataExtractor`, `MilitaryFinancialDataAssembler`, `MilitaryExtractionCoordinator`
- [ ] Split `Services/Extraction/ExtractionResultValidator.swift` → `TotalsReconciliationValidator`, `ComponentConsistencyValidator`, `ValidationPolicy`
- [ ] Split `Services/Processing/MilitaryPayslipProcessor.swift` → `MilitaryPipelineCoordinator`, `MilitaryPostProcessing`, `MilitaryFormatAdapters`
- [ ] Split `Services/Extraction/TextProcessingPipeline.swift` → `Tokenization`, `Normalization`, `Clustering` modules
- [ ] Split `Services/Extraction/PayslipParserService.swift` → `PayslipParsingCoordinator`, `PayslipPostProcessing`, `PayslipValidationBridge`
- [ ] Break up `Features/WebUpload/Views/WebUploadListView.swift` into smaller view components and a lightweight coordinator
- [ ] Reduce `Models/PayslipItem.swift` by extracting nested types/extensions into focused files

Acceptance
- [ ] No files > 300 lines in modified areas (verified by CI rule)
- [ ] Build + tests green

#### Phase 2: Concurrency hardening and cancellation (1–2 weeks)
Tasks
- [ ] Repo audit proves 0 usages of `DispatchSemaphore` (scripted check)
- [ ] Add cooperative cancellation throughout extraction/parsing pipeline
- [ ] Ensure heavy work is off main; audit `@MainActor` annotations and move to background actors where applicable
- [ ] Add timeouts and fallback strategies for long‑running OCR/extraction tasks

Acceptance
- [ ] Concurrency audit script passes; UI remains responsive during imports
- [ ] Smoke tests demonstrate cancellation and recovery without leaks

#### Phase 3: Parsing accuracy uplift for legacy PCDA (2–3 weeks)
Tasks
- [ ] Implement vector‑first lattice parsing and integrate with existing detector/parser
- [ ] Add Core ML table mask to gate legacy PCDA grid crops; suppress right panel
- [ ] Hybrid selection with confidence: lattice → stream → OCR; totals‑first gating
- [ ] Expand numeric normalization and descriptor mapping for bilingual variants

Acceptance
- [ ] Legacy pre‑2023 golden dataset: +3–5 pts field accuracy; ≥98% totals agreement; modern formats unchanged (bit‑for‑bit)
- [ ] Unit and property tests updated; CI regression gates added

#### Phase 4: Performance and memory SLOs (1 week)
Tasks
- [ ] Establish device‑class baselines (latency, memory) for representative PDFs
- [ ] Enforce adaptive streaming thresholds and cache limits via configuration
- [ ] Add CI perf checks with tolerances and failure gates

Acceptance
- [ ] p95 latency and memory within budget on test matrix; alerts on drift

#### Phase 5: Error handling and resilience (4–5 days)
Tasks
- [ ] Standardize error taxonomy across extraction/parsing services
- [ ] Replace any remaining `fatalError`/asserts in production paths with recoverable flows
- [ ] Surface low‑confidence and validation failures to UI as reviewable states

Acceptance
- [ ] Repo scan: 0 `fatalError(` in production modules
- [ ] UI shows review state instead of committing low‑confidence parses

#### Phase 6: Testing expansion and automation (1–2 weeks)
Tasks
- [ ] Enable disabled property tests; add generators for adverse PDFs (rotation/blur/merged cells)
- [ ] Add critical UI tests for import → parse → review flows
- [ ] Increase regression corpus breadth with weekly triage and dataset versioning

Acceptance
- [ ] CI includes property/UI tests; failures block merges
- [ ] Dataset versioned; drift reports visible in CI artifacts

#### Phase 7: Observability, privacy, and governance (3–4 days)
Tasks
- [ ] Add SLO summaries to diagnostics bundle: latency, memory, confidence/validation rates
- [ ] Expand redaction tests to ensure zero PII in logs/exports
- [ ] Document rollback plans and feature flag policies per module

Acceptance
- [ ] Diagnostics export shows SLO histograms; privacy checks pass

---

### CI enforcement and tooling
- [ ] CI step: fail build if any Swift file > 300 lines
- [ ] CI step: grep audit for `DispatchSemaphore` and `fatalError(` in production targets
- [ ] CI step: run performance smoke tests; compare to stored baselines
- [ ] CI step: dataset regression test for legacy PCDA and modern formats
- [ ] Scripted report: top 20 largest files with suggested splits (run in PR comments)

---

### Metrics and success criteria
- Parsing accuracy (legacy pre‑2023) on golden/adverse sets: target +3–5 pts improvement, ≥98% totals agreement
- Zero regressions on modern (post–Nov 2023) formats: bit‑for‑bit equality on key fields
- Performance SLOs: p95 latency and memory within device‑class budgets; no OOMs
- Code health: 0 files > 300 lines in touched areas; 0 `DispatchSemaphore`, 0 `fatalError(` in production modules
- Test health: unit, property, and critical UI tests green in CI; dataset drift tracked

---

### References
- 300‑line policy and prior tech‑debt roadmap [[memory:1178975]]
- Tabulated PDF accuracy plan: `Documentation/TechnicalDebtReduction/Tabulated_PDF_Accuracy_Strategy.md`
- Hardening roadmap: `Documentation/TechnicalDebtReduction/Phase7_Hardening_Roadmap.md`


