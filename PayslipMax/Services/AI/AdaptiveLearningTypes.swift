import Foundation

// MARK: - User Correction Types

/// Represents a user correction to an extracted field
public struct UserCorrection: Codable, Identifiable {
    public let id: UUID
    public let fieldName: String
    public let originalValue: String
    public let correctedValue: String
    public let documentType: LiteRTDocumentFormatType
    public let parserUsed: String
    public let timestamp: Date
    public let confidenceImpact: Double
    public let extractedPattern: String?
    public let suggestedValidationRule: ValidationRule?
    public let totalExtractions: Int
    
    public init(
        id: UUID = UUID(),
        fieldName: String,
        originalValue: String,
        correctedValue: String,
        documentType: LiteRTDocumentFormatType,
        parserUsed: String,
        timestamp: Date = Date(),
        confidenceImpact: Double = -0.1,
        extractedPattern: String? = nil,
        suggestedValidationRule: ValidationRule? = nil,
        totalExtractions: Int = 1
    ) {
        self.id = id
        self.fieldName = fieldName
        self.originalValue = originalValue
        self.correctedValue = correctedValue
        self.documentType = documentType
        self.parserUsed = parserUsed
        self.timestamp = timestamp
        self.confidenceImpact = confidenceImpact
        self.extractedPattern = extractedPattern
        self.suggestedValidationRule = suggestedValidationRule
        self.totalExtractions = totalExtractions
    }
}

/// Validation rule derived from user corrections
public struct ValidationRule: Codable, Hashable {
    public let id: UUID
    public let fieldName: String
    public let ruleType: ValidationRuleType
    public let pattern: String?
    public let minValue: Double?
    public let maxValue: Double?
    public let allowedValues: [String]?
    public let confidence: Double
    
    public init(
        id: UUID = UUID(),
        fieldName: String,
        ruleType: ValidationRuleType,
        pattern: String? = nil,
        minValue: Double? = nil,
        maxValue: Double? = nil,
        allowedValues: [String]? = nil,
        confidence: Double = 0.8
    ) {
        self.id = id
        self.fieldName = fieldName
        self.ruleType = ruleType
        self.pattern = pattern
        self.minValue = minValue
        self.maxValue = maxValue
        self.allowedValues = allowedValues
        self.confidence = confidence
    }
}

/// Types of validation rules
public enum ValidationRuleType: String, Codable, CaseIterable {
    case regex = "regex"
    case range = "range"
    case allowlist = "allowlist"
    case format = "format"
    case dependency = "dependency"
    case pattern = "pattern"
}

// MARK: - Personalization Types

/// Personalized suggestion for user
public struct PersonalizedSuggestion: Identifiable {
    public let id: UUID
    public let type: SuggestionType
    public let field: String
    public let suggestion: String
    public let confidence: Double
    public let timestamp: Date
    
    public init(
        id: UUID = UUID(),
        type: SuggestionType,
        field: String,
        suggestion: String,
        confidence: Double,
        timestamp: Date = Date()
    ) {
        self.id = id
        self.type = type
        self.field = field
        self.suggestion = suggestion
        self.confidence = confidence
        self.timestamp = timestamp
    }
}

/// Types of personalized suggestions
public enum SuggestionType: String, CaseIterable {
    case fieldValidation = "field_validation"
    case formatOptimization = "format_optimization"
    case validationRule = "validation_rule"
    case parserSelection = "parser_selection"
    case confidenceAdjustment = "confidence_adjustment"
}

// MARK: - Pattern Analysis Types

/// Pattern identified from user corrections
public struct CorrectionPattern: Codable, Sendable {
    public let id: UUID
    public let fieldName: String
    public let documentType: LiteRTDocumentFormatType
    public let patternType: PatternType
    public let pattern: String
    public let frequency: Int
    public let confidence: Double
    public let confidenceAdjustment: Double
    public let lastSeen: Date
    
    public init(
        id: UUID = UUID(),
        fieldName: String,
        documentType: LiteRTDocumentFormatType,
        patternType: PatternType,
        pattern: String,
        frequency: Int,
        confidence: Double,
        confidenceAdjustment: Double,
        lastSeen: Date = Date()
    ) {
        self.id = id
        self.fieldName = fieldName
        self.documentType = documentType
        self.patternType = patternType
        self.pattern = pattern
        self.frequency = frequency
        self.confidence = confidence
        self.confidenceAdjustment = confidenceAdjustment
        self.lastSeen = lastSeen
    }
}

/// Types of patterns that can be learned
public enum PatternType: String, CaseIterable, Codable, Sendable {
    case regex = "regex"
    case format = "format"
    case position = "position"
    case context = "context"
    case value = "value"
    case validationRule = "validation_rule"
}

/// User pattern for personalization
public struct UserPattern {
    public let id: UUID
    public let fieldName: String
    public let type: UserPatternType
    public let commonValue: String
    public let preferredParser: String
    public let validationRule: String
    public let confidence: Double
    public let frequency: Int
    
    public init(
        id: UUID = UUID(),
        fieldName: String,
        type: UserPatternType,
        commonValue: String,
        preferredParser: String = "",
        validationRule: String = "",
        confidence: Double,
        frequency: Int
    ) {
        self.id = id
        self.fieldName = fieldName
        self.type = type
        self.commonValue = commonValue
        self.preferredParser = preferredParser
        self.validationRule = validationRule
        self.confidence = confidence
        self.frequency = frequency
    }
}

/// Types of user patterns
public enum UserPatternType: String, CaseIterable {
    case fieldExtraction = "field_extraction"
    case formatPreference = "format_preference"
    case validationRule = "validation_rule"
    case parserPreference = "parser_preference"
}

// MARK: - Parser Adaptation Types

/// Adaptation parameters for a parser
public struct ParserAdaptation {
    public let parserName: String
    public let adaptations: [String: Any]
    public let confidenceMultiplier: Double
    public let priority: AdaptationPriority
    public let timestamp: Date
    
    public init(
        parserName: String,
        adaptations: [String: Any],
        confidenceMultiplier: Double,
        priority: AdaptationPriority,
        timestamp: Date = Date()
    ) {
        self.parserName = parserName
        self.adaptations = adaptations
        self.confidenceMultiplier = confidenceMultiplier
        self.priority = priority
        self.timestamp = timestamp
    }
}

/// Field-specific adaptation
public struct FieldAdaptation {
    public let fieldName: String
    public let preferredPatterns: [String]
    public let confidenceAdjustment: Double
    public let validationRules: [ValidationRule]
    
    public init(
        fieldName: String,
        preferredPatterns: [String],
        confidenceAdjustment: Double,
        validationRules: [ValidationRule]
    ) {
        self.fieldName = fieldName
        self.preferredPatterns = preferredPatterns
        self.confidenceAdjustment = confidenceAdjustment
        self.validationRules = validationRules
    }
}

// MARK: - Performance Tracking Types

/// Performance metrics for parser tracking
public struct ParserPerformanceMetrics {
    public let id: UUID
    public let parserName: String
    public let documentType: LiteRTDocumentFormatType
    public let processingTime: TimeInterval
    public let accuracy: Double
    public let fieldsExtracted: Int
    public let fieldsCorrect: Int
    public let timestamp: Date
    public let memoryUsage: Int64
    public let cpuUsage: Double
    
    public init(
        id: UUID = UUID(),
        parserName: String,
        documentType: LiteRTDocumentFormatType,
        processingTime: TimeInterval,
        accuracy: Double,
        fieldsExtracted: Int,
        fieldsCorrect: Int,
        timestamp: Date = Date(),
        memoryUsage: Int64 = 0,
        cpuUsage: Double = 0.0
    ) {
        self.id = id
        self.parserName = parserName
        self.documentType = documentType
        self.processingTime = processingTime
        self.accuracy = accuracy
        self.fieldsExtracted = fieldsExtracted
        self.fieldsCorrect = fieldsCorrect
        self.timestamp = timestamp
        self.memoryUsage = memoryUsage
        self.cpuUsage = cpuUsage
    }
}

// MARK: - Feedback Types

/// User feedback on extraction results
public struct UserFeedback {
    public let id: UUID
    public let documentId: String
    public let overallRating: Int // 1-5 scale
    public let fieldFeedback: [FieldFeedback]
    public let suggestions: String?
    public let timestamp: Date
    public let processingTime: TimeInterval
    
    public init(
        id: UUID = UUID(),
        documentId: String,
        overallRating: Int,
        fieldFeedback: [FieldFeedback],
        suggestions: String? = nil,
        timestamp: Date = Date(),
        processingTime: TimeInterval
    ) {
        self.id = id
        self.documentId = documentId
        self.overallRating = overallRating
        self.fieldFeedback = fieldFeedback
        self.suggestions = suggestions
        self.timestamp = timestamp
        self.processingTime = processingTime
    }
}

/// Feedback for individual fields
public struct FieldFeedback {
    public let fieldName: String
    public let wasCorrect: Bool
    public let confidence: Double
    public let userConfidence: Int // 1-5 scale
    public let correctionNeeded: Bool
    
    public init(
        fieldName: String,
        wasCorrect: Bool,
        confidence: Double,
        userConfidence: Int,
        correctionNeeded: Bool = false
    ) {
        self.fieldName = fieldName
        self.wasCorrect = wasCorrect
        self.confidence = confidence
        self.userConfidence = userConfidence
        self.correctionNeeded = correctionNeeded
    }
}

// MARK: - Learning Context Types

/// Context for learning operations
public struct LearningContext {
    public let userId: String?
    public let deviceId: String
    public let appVersion: String
    public let osVersion: String
    public let timestamp: Date
    public let privacyMode: PrivacyMode
    
    public init(
        userId: String? = nil,
        deviceId: String,
        appVersion: String,
        osVersion: String,
        timestamp: Date = Date(),
        privacyMode: PrivacyMode = .strict
    ) {
        self.userId = userId
        self.deviceId = deviceId
        self.appVersion = appVersion
        self.osVersion = osVersion
        self.timestamp = timestamp
        self.privacyMode = privacyMode
    }
}

/// Privacy modes for learning
public enum PrivacyMode: String, CaseIterable {
    case strict = "strict"     // No personal data stored
    case balanced = "balanced" // Anonymized patterns only
    case permissive = "permissive" // Full learning with consent
}
