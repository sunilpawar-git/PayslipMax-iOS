import Foundation

/// A utility for consistent application logging with support for different levels and categories
enum LogLevel: String {
    case debug = "DEBUG"
    case info = "INFO"
    case warning = "WARNING"
    case error = "ERROR"
    case critical = "CRITICAL"
    
    var emoji: String {
        switch self {
        case .debug: return "🔍"
        case .info: return "ℹ️"
        case .warning: return "⚠️"
        case .error: return "🔴"
        case .critical: return "🚨"
        }
    }
}

/// A simple, structured logging system for the application
struct Logger {
    /// The minimum log level to display. Messages below this level will be ignored.
    static var minLevel: LogLevel = .debug
    
    /// Whether to include the source file, function name, and line number in log messages.
    static var includeLocation: Bool = true
    
    /// The maximum length for a log message before it gets truncated. `nil` means no truncation.
    static var maxMessageLength: Int? = nil
    
    /// Log a message at the specified level
    /// - Parameters:
    ///   - level: The severity level of the log
    ///   - message: The message to log
    ///   - category: Optional category for the log (e.g., "Network", "PDF", "UI")
    ///   - file: The file where the log was called from
    ///   - function: The function where the log was called from
    ///   - line: The line where the log was called from
    static func log(
        _ level: LogLevel,
        _ message: String,
        category: String? = nil,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        guard level.rawValue >= minLevel.rawValue else { return }
        
        let filename = URL(fileURLWithPath: file).lastPathComponent
        let truncatedMessage = maxMessageLength.map { message.count > $0 ? message.prefix($0) + "..." : message } ?? message
        
        var logComponents = [String]()
        logComponents.append("\(level.emoji) [\(level.rawValue)]")
        if let category = category {
            logComponents.append("[\(category)]")
        }
        logComponents.append(truncatedMessage)
        
        if includeLocation {
            logComponents.append("- \(filename):\(line) in \(function)")
        }
        
        #if DEBUG
        print(logComponents.joined(separator: " "))
        #else
        // In production, we would send this to a logging service
        // sendToLoggingService(level: level, message: message, category: category, file: file, function: function, line: line)
        #endif
    }
    
    /// Log a debug message.
    /// - Parameters:
    ///   - message: The message to log.
    ///   - category: Optional category for the log.
    ///   - file: The file where the log was called from (automatically captured).
    ///   - function: The function where the log was called from (automatically captured).
    ///   - line: The line where the log was called from (automatically captured).
    static func debug(_ message: String, category: String? = nil, file: String = #file, function: String = #function, line: Int = #line) {
        log(.debug, message, category: category, file: file, function: function, line: line)
    }
    
    /// Log an informational message.
    /// - Parameters:
    ///   - message: The message to log.
    ///   - category: Optional category for the log.
    ///   - file: The file where the log was called from (automatically captured).
    ///   - function: The function where the log was called from (automatically captured).
    ///   - line: The line where the log was called from (automatically captured).
    static func info(_ message: String, category: String? = nil, file: String = #file, function: String = #function, line: Int = #line) {
        log(.info, message, category: category, file: file, function: function, line: line)
    }
    
    /// Log a warning message.
    /// - Parameters:
    ///   - message: The message to log.
    ///   - category: Optional category for the log.
    ///   - file: The file where the log was called from (automatically captured).
    ///   - function: The function where the log was called from (automatically captured).
    ///   - line: The line where the log was called from (automatically captured).
    static func warning(_ message: String, category: String? = nil, file: String = #file, function: String = #function, line: Int = #line) {
        log(.warning, message, category: category, file: file, function: function, line: line)
    }
    
    /// Log an error message.
    /// - Parameters:
    ///   - message: The message to log.
    ///   - category: Optional category for the log.
    ///   - file: The file where the log was called from (automatically captured).
    ///   - function: The function where the log was called from (automatically captured).
    ///   - line: The line where the log was called from (automatically captured).
    static func error(_ message: String, category: String? = nil, file: String = #file, function: String = #function, line: Int = #line) {
        log(.error, message, category: category, file: file, function: function, line: line)
    }
    
    /// Log a critical error message.
    /// - Parameters:
    ///   - message: The message to log.
    ///   - category: Optional category for the log.
    ///   - file: The file where the log was called from (automatically captured).
    ///   - function: The function where the log was called from (automatically captured).
    ///   - line: The line where the log was called from (automatically captured).
    static func critical(_ message: String, category: String? = nil, file: String = #file, function: String = #function, line: Int = #line) {
        log(.critical, message, category: category, file: file, function: function, line: line)
    }
    
    /// Log an error object, automatically extracting its localized description.
    /// - Parameters:
    ///   - error: The `Error` object to log.
    ///   - category: Optional category for the log.
    ///   - file: The file where the log was called from (automatically captured).
    ///   - function: The function where the log was called from (automatically captured).
    ///   - line: The line where the log was called from (automatically captured).
    static func log(
        _ error: Error,
        category: String? = nil,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        let errorMessage = (error as NSError).localizedDescription
        self.error("Error: \(errorMessage)", category: category, file: file, function: function, line: line)
    }
} 