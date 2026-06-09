# PayslipMax Parsing Pipeline — Offline Parsing Analysis

Purpose: guidance document for improving offline payslip parsing and making the
app genuinely "100% Offline Mode" capable. Based on a full trace of the
upload→parse→save pipeline as of 2026-06-08 (branch `feature/offlineimpl`).

---

## 1. Entry points (3 distinct flows — each behaves differently offline)

**A. PDF import** (`PayslipImportView` → `PDFProcessingHandler.processPDFData` →
`PDFProcessingService+Processing.processPDFData`)
```
PDFDocument → extract text → formatDetectionService.detectFormatEnhanced()
  ├─ .jcoOR        → convertPDFToImage() → processWithVisionLLM()  [HARD CLOUD ROUTE]
  └─ .defense/.unknown → processingPipeline.executePipeline(data) → HybridPayslipProcessor
```

**B. Gallery image import** (`PayslipImportView.process(image:)` →
`ImageImportProcessor.process` → `pdfHandler.processScannedImage`)
```
imageProcessingStep.process(image) → PDF → executePipeline
  on textExtraction failure:
    1. processWithStructuredOCR (position-aware OCR, JCO/OR tabular)  [offline]
    2. flat OCR (top-band / full / preprocessed)                      [offline]
    → processOCRText → HybridPayslipProcessor (regex → on-device LLM → cloud LLM)
```

**C. Camera scan + crop** (`PayslipScannerView` →
`PayslipParsingProgressService.startParsing` → `ImageImportProcessor.processBothImages`
/ `processCroppedImageLLMOnly`)
```
PDFProcessingService+Scan.processScannedImages / processScannedImageLLMOnly:
  0. Vision LLM (cloud, image-based)
  1. fallback: OCR + text LLM (cloud)
  [NO regex/on-device branch at all]
```

## 2. The Hybrid cascade (the offline-aware "good" path — flows A-defense and B)

`HybridPayslipProcessor.processPayslip` (`HybridPayslipProcessor.swift:72`):
1. **Regex** — `UniversalPayslipProcessor` (anchor extraction + parallel pay-code
   search across 243 military codes from `military_abbreviations.json`)
2. **Guarded fallback** — if BPAY/ITAX missing, totals mismatch >5%, or net was
   derived → escalate
3. **Confidence score** (`HybridParsingHeuristics.calculateParsingConfidence`) —
   penalizes missing BPAY/DSOP, totals mismatch, low component count, missing
   DA/ITAX on high-value slips
4. **Threshold gate** — online: skip-LLM at 0.9, backup-only at 0.7;
   **offline: relaxed to 0.6 / 0.4**
5. **On-device LLM** (`FoundationModelPayslipService`, iOS 26+ Apple Foundation
   Models) — zero network, deliberately strips PII (name/account/PAN left blank
   by design)
6. **Cloud LLM** (Gemini, gated by `BuildConfiguration.useBackendProxy` +
   `OfflineModeService`)
7. Fallback to raw regex result

`OfflineModeService` → `LLMSettingsService.getConfiguration()` correctly returns
`nil` whenever `isOfflineModeEnabled == true`, which suppresses cloud LLM
everywhere it's checked.

---

## 3. Critical gaps — where "100% Offline Mode" silently breaks

The settings toast (`Localizable.strings:5`) promises:
*"Offline Mode Enabled — all parsing runs on-device."* That promise is
**false** for two major flows:

### 🔴 Gap 1 — JCO/OR text-PDF imports are hard-routed to cloud Vision LLM with no fallback
`PDFProcessingService+Processing.swift:50-56`: any PDF whose text matches
JCO/OR markers (`JCOORFormatDetector`) is converted to an image and sent
straight to `processWithVisionLLM`, bypassing the entire Hybrid/regex/on-device
cascade — *unconditionally*; format detection doesn't even check offline state.
When offline, `resolveVisionLLMConfiguration()` returns `nil` (because
`LLMSettingsService.getConfiguration()` checks `isOfflineModeEnabled`), so
`processWithVisionLLM` fails outright with `.processingFailed`. The user gets a
hard failure for an entire payslip category — JCO/OR is precisely the tabular
two-column format the app *already* has an offline-capable structured-OCR +
regex path for (`processWithStructuredOCR` / `JCOORTextSectionSplitter` /
`PayCodeCatalogue`), but that path is only reachable from the *scanned image*
flow, never from text-PDF imports.

### 🔴 Gap 2 — Camera-scan-with-crop flow is LLM-only, no regex/OCR fallback
`PayslipScannerView` (the primary "scan a physical payslip" UX) →
`PayslipParsingProgressService` → `ImageImportProcessor.processBothImages` /
`processCroppedImageLLMOnly` → `PDFProcessingService+Scan.processScannedImages`
/ `processScannedImageLLMOnly`. These two methods *only* try: (0) Vision LLM,
(1) OCR + text LLM. Neither calls `HybridPayslipProcessor`, the
structured-OCR tabular path, nor `attemptOnDeviceLLM`. Offline → both
`resolveVisionLLMConfiguration()` and `resolveLLMConfiguration()` return `nil`
→ the OCR text is extracted (works fine, fully on-device) but then
**discarded** because there's no parser left to run it through. Net result:
scanning a payslip with the camera is **completely non-functional in offline
mode**, even though the OCR itself ran on-device successfully.

Compare this to flow B (`processScannedImage`, used for gallery import) which
*does* have the full offline cascade — structured OCR → `processOCRText` →
`HybridPayslipProcessor` (regex → on-device LLM). The crop-flow methods look
like they were written for "best LLM accuracy" and never retrofitted with an
offline branch when `OfflineModeService` was introduced.

### 🟡 Gap 3 — On-device LLM is iOS 26+ only, and deliberately incomplete
`FoundationModelPayslipService` requires `@available(iOS 26, *)` (Apple
Foundation Models / `SystemLanguageModel`). Below iOS 26, `onDeviceService` is
`nil` in `PayslipProcessorFactory` (`PayslipProcessorFactory.swift:79-83`), so
offline mode on older devices has *only* the regex engine — no LLM safety net
at all. Also, by design (`OnDeviceLLMResultConverter`), the on-device model
never extracts name/account/PAN — those fields stay blank, which is correct
for privacy but means offline-parsed payslips from the LLM path are missing
personal info that regex extraction (`MilitaryDateExtractor.extractPersonalInfo`)
would normally fill in.

### 🟡 Gap 4 — `attemptOnDeviceLLM` discards low-value results outright
`HybridPayslipProcessor+OnDevice.swift:27`: if `result.grossPay <= 0`, the
entire on-device result is thrown away (no partial merge with regex output).
For low-confidence regex *and* a zero-grossPay on-device result, the user ends
up with the deficient regex result and a `parsing.deficient` flag — there's no
cross-validation/merge step that could combine partial regex anchors with
partial LLM line items.

---

## 4. Where the regex engine itself has known weak spots
(relevant since offline relies on it more)

- **Anchor extraction is regex-pattern-driven and fragile to OCR noise**
  (`PayslipAnchorExtractor`): gross/deductions/net patterns assume specific
  label phrases (`Gross Pay`, `TOTAL CREDITS`, `AMOUNT CREDITED TO BANK`, Hindi
  equivalents). Any payslip whose totals use phrasing outside these patterns
  falls through to the "derived net" branch, which then trips
  `guardedFallbackReason` ("Net derived from anchors") and forces an LLM
  escalation that's unavailable offline.
- **Confidence heuristics are tuned around a fixed component vocabulary**
  (`HybridParsingHeuristics.basicPayKeys`/`taxKeys`, DSOP/AGIF/MSP/DA):
  non-defense or unusual payslip layouts will systematically score low and
  route to LLM, which — offline — just returns the deficient regex result with
  a `parsing.deficient` metadata flag and no further recourse.
- **`military_abbreviations.json`** has only 243 codes / 103 component
  mappings — `ParsingDiagnosticsService.recordUnclassifiedComponent` exists
  specifically to surface codes the regex engine doesn't recognize, suggesting
  this catalogue is a known, actively-tracked gap (worth mining
  `unclassifiedComponents`/`patternFailures` from real usage to grow the
  catalogue).

---

## 5. Recommendations to make the app genuinely "offline smart"

1. **Fix Gap 1**: Remove the unconditional JCO/OR → Vision-LLM hard route in
   `processPDFData`, or at minimum gate it on
   `offlineModeService.isOfflineModeEnabled` and fall back to
   `processingPipeline.executePipeline(data)` (which already routes through
   `HybridPayslipProcessor` and would work for JCO/OR text PDFs via the
   regex/`PayCodeCatalogue` classification it already has).
2. **Fix Gap 2** (highest impact — this is the primary capture flow): Rewrite
   `processScannedImages`/`processScannedImageLLMOnly` to mirror
   `processScannedImage`'s cascade — try `processWithStructuredOCR` first
   (it's already offline, position-aware, and built for exactly this
   two-column layout), then flat OCR, then route the resulting text through
   `HybridPayslipProcessor` (regex → on-device LLM → cloud LLM), with Vision
   LLM only as an *enhancement* when online/available — not a hard dependency.
3. **Make `attemptOnDeviceLLM` complementary rather than all-or-nothing**:
   when the on-device result has `grossPay <= 0` or low component count, merge
   it with the regex anchors (use regex anchors as ground truth, LLM
   line-items to fill gaps) instead of discarding the whole thing.
4. **Surface offline-capability per-format up front**: since
   `formatDetectionService` already knows the format before routing, it could
   pre-flight check `offlineModeService.isOfflineModeEnabled && !onDeviceAvailable`
   and warn the user *before* attempting (rather than failing mid-flow), or
   auto-select the best available offline path.
5. **Grow the regex/pay-code coverage from diagnostics data**:
   `ParsingDiagnosticsService` already tracks `unclassifiedComponents` /
   `patternFailures` / `nearMissTotals` — wiring this into a periodic export
   (even anonymized, on-device aggregate counts) would directly inform which
   of the 243 codes/anchor patterns need expansion, reducing how often offline
   parsing has to fall back to a (possibly unavailable) LLM at all.
6. **Honor offline mode symmetrically for on-device-LLM availability gating**:
   consider a lightweight bundled regex-only "confidence floor" mode for
   pre-iOS-26 devices in offline mode, so `guardedFallbackReason` doesn't
   escalate to a dead-end (`onDeviceService == nil && isOffline`) — e.g.,
   relax thresholds further or accept "near-miss" results with a clear in-app
   disclosure rather than marking them silently `parsing.deficient`.
