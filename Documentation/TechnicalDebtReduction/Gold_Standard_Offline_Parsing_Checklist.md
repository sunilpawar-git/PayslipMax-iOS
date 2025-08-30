# Gold‑Standard Offline Parsing Checklist

This checklist consolidates completed hardening phases and proposes final guardrails to reach a gold‑standard, offline‑first PDF payslip parser. All completed phases are checked. New phases are actionable with clear acceptance and test gates.

---

## Build & Test Status
- [x] Project builds successfully (Simulator)
- [x] All unit tests pass (per latest roadmap)
- [x] No `DispatchSemaphore` usage; production `fatalError` paths removed

---

## Scope & Rollout Safety
- Applicability: Phases 11–12 target legacy PCDA layout (pre–Nov 2023). Modern post–Nov 2023 flows remain unchanged.
- Gating: Enable via legacy PCDA detector + feature flag (e.g., `pcdaLegacyHardening`); only active when legacy PCDA is detected.
- OCR: Phase 15 settings apply only to PCDA grid crops when legacy PCDA detected; do not alter global OCR for modern formats.
- Numeric normalization: Phase 16 behind a flag (e.g., `numericNormalizationV2`) with A/B and regression verification before wider rollout.
- Validator/Builder: Phases 13–14 initially enforced for legacy PCDA only; consider expansion after stability is proven.
- Confidence/Differential: Phases 19–20 opt‑in per format; start with legacy PCDA and expand later.
- Regression protection: Maintain two regression suites—legacy pre‑2023 (must improve) and modern post‑Nov 2023 (must be bit‑for‑bit stable).
 - Regression protection: Maintain two regression suites—legacy pre‑2023 (must improve) and modern post‑Nov 2023 (must be bit‑for‑bit stable).
 - [x] Added `Feature.pcdaLegacyHardening` and wired bootstrap in app; detector gated on this flag.
 - [x] Added `Feature.numericNormalizationV2` (Phase 16) behind a flag; initially applied in legacy PCDA parsing path.

---

## Phase 11: PCDA Detector Hardening (Bilingual, Grid & Panel Segmentation)
- Scope: Legacy PCDA (pre–Nov 2023) only; gated by detector + feature flag. No effect on post–Nov 2023.
- [x] Detect bilingual/multi‑line headers: "जमा/CREDIT", "नावे/DEBIT", "विवरण/DESCRIPTION", "राशि/AMOUNT"
- [x] Infer 4 columns via numeric clustering (x‑position bins) independent of header text
- [x] Return strict `pcdaTable.bounds` and `detailsPanel.bounds` (right panel) from detector
- [x] Expose column indices for credit: (desc, amount) and debit: (desc, amount)
- [x] Unit tests for header variations and panel segmentation

Acceptance/Test Gate
- [ ] Detector finds 4‑column grid and excludes details panel on pre‑2023 PDFs (golden set)

---

## Phase 12: Spatial Extractor Hardening (Row Pairing & Totals‑First)
- Scope: Legacy PCDA only; page‑wide numeric fallbacks are disabled only in this legacy PCDA path.
- [x] Filter elements to `pcdaTable.bounds` minus `detailsPanel.bounds` before any parsing
- [x] Row gating: accept only when desc digit density < 30%, amount digit density > 70%, y‑overlap ≥ 60%
- [ ] Choose nearest numeric cell in correct column bin as the amount per side
- [x] Choose nearest numeric cell in correct column bin as the amount per side
- [x] Remove ambiguous tokens from `earningCodes`/`deductionCodes` (drop "L", "FEE", "FUR")
- [x] Add `MilitaryDescriptionNormalizer` mapping phrases ("Lic Fee", "Fur", "A/o DA‑", "A/o TRAN‑1") → canonical codes (initial set)
- [x] Totals‑first: read printed totals from grid; set `__CREDITS_TOTAL`/`__DEBITS_TOTAL`; reconcile components within ±1.5% (logging)
- [x] Disable page‑wide numeric fallbacks for PCDA hardened path

Acceptance/Test Gate
- [ ] Components + totals match printed totals within ±0.5% on golden pre‑2023 set; zero contamination from right panel

---

## Phase 13: Validator Enforcement (Hard Constraints)
- Scope: Enable for legacy PCDA first; expand to modern formats only after regression stability.
- [x] Enforce: credits == debits (± tolerance), both > 0 (validator in place)
- [x] Component sums ≤ printed totals per side (reconciliation check + enforcement behind flag)
- [ ] Remittance consistency when present
- [x] Fail fast and mark result low‑confidence on violation (behind `pcdaValidatorEnforcement`)

Acceptance/Test Gate
- [ ] Validator blocks all discrepant parses in regression tests; only reconciled results pass

---

## Phase 14: Builder Gating & Totals Preference
- Scope: Apply totals preference and save gating in legacy PCDA path first; modern path unchanged.
- [x] Prefer `__CREDITS_TOTAL`/`__DEBITS_TOTAL` when present
- [x] For PCDA parses, refuse saving totals derived from arbitrary component sums unless validator passed
- [x] Surface low‑confidence state to UI instead of committing data

Acceptance/Test Gate
- [x] No auto‑save when validation fails; UI shows Review state with context

---

## Phase 15: OCR Tuning (Vision)
- Scope: Apply OCR settings to PCDA grid crops only when legacy PCDA detected; do not change global OCR defaults.
- [x] Set `recognitionLanguages`: `en-IN`, `hi-IN`
- [x] Add `customWords`: BPAY, BASIC PAY, DSOPF, DSOP, AGIF, MSP, TPT, INCM TAX, EDUC CESS, BARRACK, LICENSE FEE
- [x] Preprocess grid region: binarization, contrast boost before recognition
- [x] Page‑region recognition: run Vision only on grid crop when PCDA detected (per‑page ROI using `pcdaTableBounds`)

Acceptance/Test Gate
- [x] Improved recognition accuracy for bilingual headers and amounts; fewer split tokens in tests
  - Added unit tests in `VisionOCRTuningTests.swift` verifying bilingual header grid detection, custom vocabulary robustness, and tight grid bounds.

---

## Phase 16: Numeric & Currency Normalization
- Scope: Roll out behind a feature flag with A/B; verify no output changes for modern post–Nov 2023 payslips.
 - [x] Handle negatives via parentheses; enforce Indian numbering without inflation
 - [x] Character confusion guards: O↔0, I↔1, S↔5; reject alpha‑heavy tokens as amounts
 - [x] Unified normalization applied before validation and reconciliation

Acceptance/Test Gate
- [ ] Fuzz tests over numeric variants pass; no over‑inflation in golden/adverse sets

---

## Phase 17: Multilingual/Locale Robustness
- [x] Hindi numerals and bilingual synonyms expansion
  - Implemented in `NumericNormalizationService` (Devanagari → Western digits), tests in `NumericNormalizationServiceTests`
  - Hindi header synonyms mapped in `PCDATableParser.convertDescriptionToCode` (e.g., "विवरण" → DESCRIPTION, "राशि" → AMOUNT)
- [x] Punctuation/spacing variants; mixed-script headers
  - `SimpleTableDetector.detectBilingualHeaders` recognizes separators: `/ : - — |` and mixed-script header band (Devanagari + English)
  - Unicode punctuation collapsed in `collapseUnicodePunctuation` for robust tokenization
- [x] Locale-aware tokenization for headers and descriptors
  - `PCDATableParser` regexes switched to Unicode-aware `\p{L}` for description fields; amount tokens normalized via Phase 16 service

Acceptance/Test Gate
- [ ] Locale tests pass; PCDA variants parse across language mixes

---

## Phase 18: Multipage Table Continuity
- Scope: Apply stitching and noise suppression rules to legacy PCDA; modern flows remain as‑is.
- [ ] Stitch rows across pages; handle repeated headers and partial rows
- [ ] Footer/footnote noise suppression
- [ ] Row identity preservation across page breaks

Acceptance/Test Gate
- [ ] Multipage regression suite passes; totals match after stitching

---

## Phase 19: Confidence‑Driven UX Gate
- Scope: Start with legacy PCDA; extend to other formats after thresholds are validated.
- [ ] Centralized ConfidenceScoring service with per‑field scores
- [ ] ThresholdPolicy to gate saves/exports
- [ ] “Review & Confirm” UI for low‑confidence or validation‑failed cases
- [ ] Block auto‑save when totals disagree or confidence < threshold

Acceptance/Test Gate
- [ ] Unit/UI tests for gating flows; analytics show zero silent low‑confidence saves

---

## Phase 20: Differential Validation Cross‑Check
- Scope: Enable for legacy PCDA initially; expand to modern formats after evaluation.
- [ ] Cross‑check spatial extraction vs text‑based fallback
- [ ] Discrepancy escalation to Review UI with context
- [ ] Automatic selection of higher‑confidence source per field

Acceptance/Test Gate
- [ ] Tests simulating divergence; correct escalation and final reconciliation

---

## Phase 21: Dataset Breadth & Drift Control
- [ ] Expand adverse dataset (rotation, blur, stamps, low contrast)
- [ ] Weekly failure triage; add new cases to dataset
- [ ] Versioned golden set; diff‑based regression checks in CI

Acceptance/Test Gate
- [ ] CI gates fail on drift; dashboard of pass rates over time

---

## Phase 22: Privacy‑By‑Default Diagnostics
- [ ] Verify no PII in logs; redact sensitive tokens/paths
- [ ] Ensure OCR image buffers are ephemeral/non‑persisted
- [ ] Signed diagnostics export with explicit user action

Acceptance/Test Gate
- [ ] Static/Dynamic analysis and tests confirm zero PII leakage

---

## Phase 23: Energy/Thermal Guardrails
- [ ] Power/thermal aware throttling on lower device classes
- [ ] Graceful degradation maintains latency and memory SLOs
- [ ] Budgeted OCR pre‑processing paths for low‑power mode

Acceptance/Test Gate
- [ ] Device‑matrix tests (simulated) meet SLOs under thermal pressure

---

## Phase 24: SLO Tracking in Diagnostics
- [ ] Track latency, memory, confidence histograms, validation pass rates
- [ ] Export aggregates in diagnostics bundle; offline‑first
- [ ] Threshold alerts surfaced in debug UI

Acceptance/Test Gate
- [ ] Diagnostics show stable SLOs across device classes and datasets

---

## Goal Statement
Aim: gold‑standard offline parsing that robustly parses any PDF payslip. With Phases 1–10 complete and Phases 11–19 as targeted guardrails, failure modes become detectable and recoverable, sustaining high accuracy across formats and conditions.


