## Tabulated PDF Parsing – Accuracy Maximization Strategy

### Problem statement
Legacy and adverse tabulated PDFs (e.g., legacy PCDA pre–Nov 2023) exhibit bilingual headers, irregular grids, merged cells, skew/rotation, and right‑panel contamination. Scanned PDFs lack reliable vector lines; digital PDFs may include vector grids but mixed text flows. OCR confusions (O/0, I/1, S/5), locale scripts (Devanagari/English), and multipage breaks degrade row pairing and totals consistency. We need a robust, offline‑first approach that maximizes cell‑level accuracy and totals reconciliation without destabilizing modern formats.

### Suggested solutions (complementary to existing checklists)
- **Vector‑first lattice parsing**: Parse PDF content streams (lines/paths) to reconstruct grid geometry when present; map tokens to cells via line intersections.
- **Learned table mask (on‑device)**: Lightweight Core ML model (Doc layout/table mask) to segment table area and suppress right‑panel contamination; used to guide OCR/text clustering.
- **Hybrid ensemble (lattice → stream → OCR)**: Try vector lattice; fall back to text clustering (stream/Tabula‑style); final fallback OCR on table crop; pick per‑cell by confidence.
- **Graph‑based cell reconstruction**: Build token adjacency graph (baseline/y‑overlap/spacing) and partition into rows/columns with spectral clustering or bipartite matching; handles merged cells.
- **Constraint solving for reconciliation**: Small LP/ILP to minimally reassign ambiguous amounts under constraints (column, sign, proximity) to satisfy printed totals.
- **Template anchoring (issuer‑specific)**: RANSAC alignment to canonical templates using header baselines/logo corners; project canonical cell boxes for noisy scans.
- **OCR ensemble + numeric language model**: Run Vision+Tesseract (or two Vision passes with different params) and reconcile digits with an Indian‑numerics n‑gram model; domain lexicon for BPAY/DA/AGIF.
- **Multipage continuity via dynamic programming**: Preserve row identity across page breaks; suppress footers/footnotes via simple classifier; stitch totals.
- **Human‑in‑the‑loop micro‑corrections**: Fast “tap to confirm” UI for low‑confidence cells; bounded edits dramatically lift field‑level accuracy.

### Recommended approach (prioritized)

#### P1 (highest priority: low‑risk, high‑ROI; 2–3 weeks)
- Implement **vector‑first lattice parser** integrated ahead of current detector/parser; fall back automatically when no reliable line geometry.
- Add **tiny Core ML table mask** to gate table bounds and suppress the right panel in legacy PCDA path; reuse existing crops for OCR.
- Ship **hybrid pipeline** switcher with confidence‑based selection (prefer printed totals when available; existing validator/builder gating already in place).
- KPIs: legacy pre‑2023 golden set field accuracy +3–5 pts, totals agreement ≥98%, zero regressions on modern formats.

#### P2 (medium priority: accuracy depth; 3–4 weeks)
- Add **graph‑based token clustering** for merged/irregular cells in stream fallback.
- Introduce **constraint solver** pass to satisfy printed totals with minimal reassignment.
- Add **template anchoring** for high‑volume issuers (PCDA variants) with robust alignment.
- Enhance OCR with **ensemble + numeric LM** to reduce O/0, I/1, S/5 confusions in amounts.

#### P3 (lower priority: robustness at scale; 3–6 weeks)
- **Multipage continuity** (DP stitching, footer suppression) for long statements.
- **Human‑in‑the‑loop micro‑UI** to resolve remaining low‑confidence cells quickly.
- **Differential validation & SLO tracking** when dataset breadth increases (gate behind flags).

### Implementation notes
- Keep scope gated to legacy PCDA via a single umbrella flag (e.g., `pcdaHardeningV1`) that enables detector hardening, lattice/stream/OCR hybrid, and totals‑first builder gating. Modern formats remain unchanged.
- Maintain the 300‑line per file rule by extracting new functionality into focused components and extensions.
- Prefer offline‑first execution: no network, small on‑device models, predictable latency.


