import CoreGraphics
import Foundation
@testable import PayslipMax

/// **Plan Phase 5 — corpus hardening.**
///
/// The full regression corpus of PII-free positional officer slips spanning 2022–2025,
/// both totals templates (`oldFolded` / `newDirect`) and every layout the coordinate
/// analysis surfaced — old 7th-CPC, new bilingual, and the Nov-2023 interleaved variant —
/// plus the narrative-column and `ETKT`-both-columns edge cases. Every entry must parse
/// fully, reconcile three ways, and build a valid item; the corpus is the proof of
/// "100% perfect officers, offline".
enum OfficerPositionalCorpus {
    /// Every reconciling fixture, ordered by statement date.
    static let all: [PositionalFixture] = [
        OfficerPositionalFixturesOldFormat.aug2022,        // 2022 — old folded
        OfficerPositionalFixturesOldFormat.aug2023,        // 2023 — old folded + narrative
        OfficerPositionalFixturesInterleaved.nov2023,      // 2023 — interleaved + narrative
        OfficerPositionalFixturesInterleaved.jan2024Etkt,  // 2024 — interleaved + ETKT both cols
        OfficerPositionalFixturesNewFormat.dec2024,        // 2024 — new direct
        OfficerPositionalFixturesNewFormat.aug2025         // 2025 — new direct
    ]

    /// A deliberately corrupted slip: a dropped earnings line means Σ earnings ≠ gross, so
    /// the reconciliation gate must reject it and the pipeline fall back to the cascade.
    /// (Same totals row as `aug2025`, with `MSP` and `RH12` removed.)
    static let corruptedDroppedEarning = PositionalFixture(
        label: "corrupted — dropped earnings line (must fail the gate)",
        elements: corruptedElements,
        expectedEarnings: [:],
        expectedDeductions: [:],
        expectedGrossPay: 275015,
        expectedTotalDeductions: 102029,
        expectedNetRemittance: 172986
    )

    private static let layout = ColumnLayout(
        creditLabelX: 94, creditAmountX: 237, debitLabelX: 300, debitAmountX: 452
    )

    private static var corruptedElements: [PositionalElement] {
        var elements: [PositionalElement] = layout.stack([
            .init(credit: ("BPAY", "144700"), debit: ("DSOP", "40000")),
            .init(credit: ("DA", "88110"), debit: ("AGIF", "12500")),
            // MSP / RH12 credit lines intentionally dropped → earnings under-sum.
            .init(debit: ("ITAX", "47624")),
            .init(debit: ("EHCESS", "1905"))
        ])
        elements += layout.row(y: 280, credit: ("Gross Pay", "275015"), debit: ("Total Deductions", "102029"))
        return elements
    }
}
