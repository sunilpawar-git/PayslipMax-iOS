import Foundation
import SwiftData

/// Utility class for converting NSPredicate to SwiftData Predicate
/// Handles complex predicate conversion logic
/// Follows SOLID principles with single responsibility focus
@MainActor
final class PayslipPredicateConverter {

    // MARK: - Predicate Conversion

    /// Converts an NSPredicate to a SwiftData Predicate
    /// - Parameter nsPredicate: The NSPredicate to convert
    /// - Returns: Equivalent Predicate for PayslipItem
    /// - Throws: InvalidPredicate or UnsupportedPredicateOperator error
    static func convertNSPredicateToPredicate(_ nsPredicate: NSPredicate) throws -> Predicate<PayslipItem> {
        if let comparisonPredicate = nsPredicate as? NSComparisonPredicate {
            return try convertComparisonPredicate(comparisonPredicate)
        } else if let compoundPredicate = nsPredicate as? NSCompoundPredicate {
            return try convertCompoundPredicate(compoundPredicate)
        }
        throw PayslipRepositoryError.invalidPredicate
    }

    /// Converts an NSComparisonPredicate to a SwiftData Predicate
    /// - Parameter predicate: The comparison predicate to convert
    /// - Returns: Equivalent Predicate for PayslipItem
    /// - Throws: UnsupportedPredicateOperator error for unsupported operators
    private static func convertComparisonPredicate(_ predicate: NSComparisonPredicate) throws -> Predicate<PayslipItem> {
        let keyPathString = predicate.leftExpression.keyPath
        let value = predicate.rightExpression.constantValue

        switch (keyPathString, predicate.predicateOperatorType) {
        case ("timestamp", .equalTo):
            if let date = value as? Date {
                return #Predicate<PayslipItem> { $0.timestamp == date }
            }
        case ("timestamp", .greaterThan):
            if let date = value as? Date {
                return #Predicate<PayslipItem> { $0.timestamp > date }
            }
        case ("timestamp", .lessThan):
            if let date = value as? Date {
                return #Predicate<PayslipItem> { $0.timestamp < date }
            }
        case ("schemaVersion", .equalTo):
            if let version = value as? PayslipSchemaVersion {
                let versionValue = version.rawValue
                return #Predicate<PayslipItem> { $0.schemaVersion == versionValue }
            }
        case ("id", .equalTo):
            if let uuid = value as? UUID {
                return #Predicate<PayslipItem> { $0.id == uuid }
            }
        default:
            break
        }

        throw PayslipRepositoryError.unsupportedPredicateOperator
    }

    /// Converts an NSCompoundPredicate to a SwiftData Predicate
    /// - Parameter predicate: The compound predicate to convert
    /// - Returns: Equivalent Predicate for PayslipItem
    /// - Throws: InvalidPredicate or UnsupportedPredicateOperator error
    private static func convertCompoundPredicate(_ predicate: NSCompoundPredicate) throws -> Predicate<PayslipItem> {
        let subpredicates = try predicate.subpredicates.map { subpredicate in
            guard let nsPredicate = subpredicate as? NSPredicate else {
                throw PayslipRepositoryError.invalidPredicate
            }
            return try convertNSPredicateToPredicate(nsPredicate)
        }

        guard let first = subpredicates.first else {
            throw PayslipRepositoryError.invalidPredicate
        }

        switch predicate.compoundPredicateType {
        case .and:
            return subpredicates.dropFirst().reduce(first) { result, next in
                #Predicate<PayslipItem> { item in
                    result.evaluate(item) && next.evaluate(item)
                }
            }
        case .or:
            return subpredicates.dropFirst().reduce(first) { result, next in
                #Predicate<PayslipItem> { item in
                    result.evaluate(item) || next.evaluate(item)
                }
            }
        case .not:
            return #Predicate<PayslipItem> { item in
                !first.evaluate(item)
            }
        @unknown default:
            throw PayslipRepositoryError.unsupportedPredicateOperator
        }
    }
}
