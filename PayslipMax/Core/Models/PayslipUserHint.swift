import Foundation

/// User-provided hint to bias payslip parsing without disabling auto-detect
enum PayslipUserHint: String, CaseIterable, Hashable, Sendable {
    case auto
    case officer
    case jcoOr
}

