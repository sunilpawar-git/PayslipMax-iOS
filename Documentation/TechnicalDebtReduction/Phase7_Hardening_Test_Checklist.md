## Phase 7 Hardening: Test Additions Checklist (Phases 1–8)

Use this checklist to add and track the new Unit/UI tests that lock in behaviors introduced during Phases 1–8 of the Reliability & Offline-First hardening roadmap.

Conventions:
- Each item links to a suggested target path for the test file under `PayslipMaxTests/` or `PayslipMaxUITests/`.
- Keep each new file under 300 lines (Cursor rule); split into multiple files if needed.
- Check off each item once implemented and green locally/CI.

---

## Phase 1: Concurrency Cleanup (Async/Await Only)

- [x] Unit: EnhancedTextExtractionService – cancellation
  - Path: `PayslipMaxTests/Services/Extraction/EnhancedTextExtractionServiceCancellationTests.swift`
  - Verifies: cancelling mid-extraction cancels child tasks quickly, no main-thread hops, resources cleaned up.

- [x] Unit: ParallelTextExtractor – adaptive concurrency cap
  - Path: `PayslipMaxTests/Services/Extraction/ParallelTextExtractorAdaptiveCapTests.swift`
  - Verifies: never exceeds cap; metrics reflect bounded parallelism across inputs.

- [x] Unit: StreamingTextExtractionService – backpressure & threading
  - Path: `PayslipMaxTests/Services/Extraction/StreamingTextExtractionServiceBackpressureTests.swift`
  - Verifies: streaming pauses/resumes under simulated backpressure; non-UI work stays off main.

---

## Phase 2: DI Consolidation

- [x] Unit: DI container wiring & mock swapping
  - Path: `PayslipMaxTests/Core/DI/DIContainerWiringTests.swift`
  - Verifies: container factory methods resolve implementations; mocks swap cleanly via `useMocks` and feature toggles; registry overrides work; resolve returns nil for unknown types. All tests green locally.

---

## Phase 3: Backup Integrity (Deterministic, Verifiable)

- [x] Unit: Backup checksum edge cases
  - Path: `PayslipMaxTests/Services/Backup/BackupChecksumEdgeCaseTests.swift`
  - Verifies: corrupted checksum rejected with friendly error; unknown fields tolerated; locale/timezone safe.

- [x] Unit: Large dataset round-trip determinism
  - Path: `PayslipMaxTests/Services/Backup/BackupRoundTripLargeDatasetTests.swift`
  - Verifies: 10k-item export→import→export yields identical checksums; bounded memory footprint.

- [x] UI: Backup checksum error UX (hooks and navigation)
  - Path: `PayslipMaxUITests/Critical/BackupChecksumErrorUITests.swift`
  - Verifies: navigation to Backup & Restore available; import UI exposed with stable accessibility IDs. Full picker-based import flow is unit/integration covered.

---

## Phase 4: Security Standardization (Keychain Everywhere)

- [ ] Unit: Secure storage failure modes (Keychain)
  - Path: `PayslipMaxTests/Services/Security/SecureStorageKeychainFailureModeTests.swift`
  - Verifies: locked/unavailable keychain, missing access control, and key rotation surface graceful recoverable errors.

- [ ] Unit: EncryptionService migration from legacy defaults
  - Path: `PayslipMaxTests/Services/Security/EncryptionServiceMigrationTests.swift`
  - Verifies: migrate→decrypt path works across versions; no plaintext persists; integrity preserved.

---

## Phase 5: Military PCDA Table Parsing v1.0 (Robust Baseline)

- [ ] Unit: Totals mismatch classification
  - Path: `PayslipMaxTests/Services/Extraction/Military/PCDATotalsMismatchClassificationTests.swift`
  - Verifies: validator produces actionable error codes and explanations for reconciliation failures.

- [ ] Unit: Header/alias variant robustness
  - Path: `PayslipMaxTests/Services/Extraction/Military/PCDAHeaderVariantRobustnessTests.swift`
  - Verifies: alias sets normalize to stable keys (BPAY, DA, MSP, DSOP, ITAX, AGIF, …) across variants.

---

## Phase 6: Military PCDA Table Parsing v1.1 (Adverse Conditions)

- [ ] Unit: Spatial/OCR adverse conditions coverage
  - Path: `PayslipMaxTests/Services/Extraction/Military/PCDAAdverseConditionsParsingTests.swift`
  - Verifies: rotated/skewed/low-contrast/merged-cell scenarios parse ≥90% fields; totals consistency ≥98%.

---

## Phase 7: Observability (Offline Diagnostics)

- [ ] Unit: Diagnostics export – PII redaction
  - Path: `PayslipMaxTests/Core/Diagnostics/DiagnosticsServiceRedactionTests.swift`
  - Verifies: no PII present; redactions applied; export schema snapshot stable.

- [ ] Unit: Feature flag behavior (`Feature.localDiagnostics`)
  - Path: `PayslipMaxTests/Core/Diagnostics/DiagnosticsFeatureFlagBehaviorTests.swift`
  - Verifies: off → no writes; on → writes; rotation/size limits enforced.

- [ ] UI: Diagnostics export flow
  - Path: `PayslipMaxUITests/High/DiagnosticsExportFlowTests.swift`
  - Verifies: navigate Debug → Export; export succeeds; bundle exists; spot-check for absence of PII strings.

---

## Phase 8: Performance & Memory Tuning

- [ ] Unit: DeviceClass defaults → ExtractionOptions
  - Path: `PayslipMaxTests/Core/Performance/DeviceClassDefaultsTests.swift`
  - Verifies: defaults (parallelism cap, batch size, cache limits) match device class.

- [ ] Unit: Memory alert degradation path
  - Path: `PayslipMaxTests/Core/Performance/MemoryAlertDegradationTests.swift`
  - Verifies: simulated memory alert reduces parallelism and engages streaming; system stabilizes.

- [ ] Unit: PDF processing cache policy (LRU + cap)
  - Path: `PayslipMaxTests/Core/Performance/PDFProcessingCachePolicyTests.swift`
  - Verifies: eviction at cap; no growth beyond limit; recency respected.

- [ ] UI: Import flow – streaming fallback UX
  - Path: `PayslipMaxUITests/High/PDFImportStreamingFallbackTests.swift`
  - Verifies: on threshold crossing, UI shows optimization banner and maintains stable progress.

---

## Notes & Usage

- Implement in priority order: concurrency cancellation/adaptive cap → diagnostics redaction/export → backup checksum edge cases → device-class/memory adaptation → DI wiring → PCDA robustness.
- After each group lands, run full build + tests; keep files under 300 lines by splitting where needed.


