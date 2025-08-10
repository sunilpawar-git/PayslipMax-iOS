# Phase 7: Reliability & Offline-First Hardening Roadmap

This plan eliminates the remaining weaknesses while amplifying strengths (adaptive/streaming extraction, on-device OCR, modular parsers). Each phase has checkbox tasks, measurable acceptance criteria, and a build/test gate. Follow the 300-line per file rule for all edits.

---

## Success Criteria (Global)
- [ ] 0 usages of DispatchSemaphore across app and tests
- [ ] Single DI container in `Core/DI`, no duplicates
- [ ] Backup checksum validation re-enabled and deterministic (no bypass)
- [ ] 100% Keychain-backed secure storage (no UserDefaults stubs)
- [ ] PCDA tabular parsing robust for common Army/Navy/AF formats with poor scans
- [ ] Services run off-main where possible; UI only on main
- [ ] All unit tests pass; key UI flows green; no files > 300 lines

---

## Phase 1: Concurrency Cleanup (Async/Await Only)
Duration: 1–2 weeks

Tasks
- [x] Convert `ModularPDFExtractor` APIs to async; remove sync wrappers and semaphores
- [x] Replace any remaining semaphore-based bridges with `async let` / `TaskGroup` (repo-wide check: none remaining)
- [x] Review `@MainActor` on services; move heavy work to background actors/isolated types (processing steps/pipeline off main)
- [x] Align extraction paths used in benchmarks and smoke tests to structured concurrency (parallel/sequential/streaming)

Acceptance
- [x] Repo-wide search shows zero `DispatchSemaphore`
- [ ] No deadlocks; PDF imports complete successfully for large files (>50 MB)

Build/Test Gate
- [x] Full build + unit tests (497 tests, all passing)
- [x] Performance smoke: 5 multi-page PDFs complete < 10s each on iPhone-class device (added `SmokePerformanceTests`, all ≤0.014s)

---

## Phase 2: DI Consolidation
Duration: 3–5 days

Tasks
- [ ] Consolidate to `Core/DI/DIContainer` family
- [ ] Move/merge `AppContainer` into `Core/DI` per `DependencyInjectionConsolidation.md`
- [ ] Remove unused/duplicate DI entry points
- [ ] Update all callers and tests to use the unified container

Acceptance
- [ ] Single source of truth for factories; tests can swap mocks cleanly

Build/Test Gate
- [ ] Full build + unit tests; no runtime DI crashes

---

## Phase 3: Backup Integrity (Deterministic, Verifiable)
Duration: 3–4 days

Tasks
- [ ] Lock JSON encoding: sorted keys, fixed date/number formats
- [ ] Re-enable checksum validation (remove temporary bypass)
- [ ] Round-trip tests (export → import → export) produce identical checksums
- [ ] Large backup performance test (1000+ items)

Acceptance
- [ ] Checksum validation on by default; mismatch fails import with user-friendly error

Build/Test Gate
- [ ] Unit tests for deterministic encoding and round-trips

---

## Phase 4: Security Standardization (Keychain Everywhere)
Duration: 4–5 days

Tasks
- [ ] Replace UserDefaults secure storage stubs with Keychain-backed `SecureStorageProtocol`
- [ ] Centralize crypto in `EncryptionService`; rotate/recover key paths covered by tests
- [ ] Audit and remove any plaintext persistence/temp file leaks

Acceptance
- [ ] All secure paths use Keychain; tests validate encrypt→store→load→decrypt

Build/Test Gate
- [ ] Security unit tests green; no stubs remain

---

## Phase 5: Military PCDA Table Parsing v1.0 (Robust Baseline)
Duration: 2 weeks

Tasks
- [ ] Table detection using PDFKit text positions + Vision bounding boxes
- [ ] Header/signature detection (e.g., columns for earnings/deductions, totals rows)
- [ ] Schema-aware parsing: normalized keys (BPAY, DA, MSP, DSOP, ITAX, AGIF, etc.)
- [ ] Totals reconciliation: cross-validate credits/debits vs. parsed components
- [ ] Golden dataset: representative PCDA variants (Army/Navy/AF), clean PDFs

Acceptance
- [ ] ≥95% correct field extraction on golden dataset (clean PDFs)

Build/Test Gate
- [ ] Property-based tests for table edge cases; regression tests for known variants

---

## Phase 6: Military PCDA Table Parsing v1.1 (Adverse Conditions)
Duration: 2 weeks

Tasks
- [ ] Handling for: rotated pages, skewed scans, low contrast, merged cells, irregular spacing
- [ ] Preprocessing pipeline: de-skew, contrast boost, binarization (Vision/CoreImage)
- [ ] Confidence scoring & fallback paths; structured error reports for field corrections
- [ ] Expand golden dataset with poor scans; annotate failures and iterate

Acceptance
- [ ] ≥90% correct field extraction on adverse dataset; ≥98% totals consistency

Build/Test Gate
- [ ] Performance budget: OCR+parse < 12s for 5-page scan on mid-tier device

---

## Phase 7: Observability (Offline Diagnostics)
Duration: 2–3 days

Tasks
- [ ] Structured logs for extraction decisions (strategy chosen, memory optimization)
- [ ] Feature-flagged analytics; redacted, local-only debugging by default
- [ ] Toggle to export anonymized diagnostics bundle for field support

Acceptance
- [ ] Debug bundle contains decisions, timings, and parse scores; no PII

Build/Test Gate
- [ ] Manual QA: simulate failures and verify actionable diagnostics

---

## Phase 8: Performance & Memory Tuning
Duration: 2–3 days

Tasks
- [ ] Tune streaming thresholds; adaptive parallelism caps by device class
- [ ] Add memory alerts; gracefully degrade to streaming when threshold crossed
- [ ] Cache policy review (page-level/text-level)

Acceptance
- [ ] No OOMs on large PDFs; stable latency distributions on test corpus

Build/Test Gate
- [ ] Performance tests recorded; baseline stored for regression monitoring

---

## Phase 9: Web Upload Readiness (Backend when available)
Duration: 3–5 days (once API exists)

Tasks
- [ ] Signed URLs/HMAC for deep links; short expiry and device binding
- [ ] Background processing with retry/backoff; progress UI hooks
- [ ] Security-scoped resource handling verified for downloads

Acceptance
- [ ] End-to-end upload→download→parse flow succeeds offline after initial fetch

Build/Test Gate
- [ ] Integration tests with mocked backend

---

## Phase 10: Release Gate & Policies
Duration: 2 days

Tasks
- [ ] Repo checks: 0 semaphores, no fatalError in production paths, all files < 300 lines
- [ ] Full unit + critical UI tests green
- [ ] Security & privacy review checklist complete

Acceptance
- [ ] Ship-ready build with documented metrics and rollback plan

---

## Execution Notes
- Build & test after each phase to respect step-by-step quality gates
- Keep edits small; if a file approaches 300 lines, extract components immediately
- Prefer actor-isolated services over `@MainActor` for non-UI work
- Track metrics: success rates on golden/adverse datasets, median parse time, memory peaks

