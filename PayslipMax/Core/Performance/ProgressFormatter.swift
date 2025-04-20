import Foundation

/// A formatter for human-readable progress information
public struct ProgressFormatter {
    /// Format time remaining in a human-readable format
    /// - Parameter timeInterval: Time interval in seconds
    /// - Returns: Formatted string like "2m 30s remaining"
    public static func formatTimeRemaining(_ timeInterval: TimeInterval?) -> String {
        guard let interval = timeInterval, interval.isFinite, interval > 0 else {
            return "Calculating..."
        }
        
        if interval < 1 {
            return "Less than 1 second remaining"
        }
        
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60
        let seconds = Int(interval) % 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m remaining"
        } else if minutes > 0 {
            return "\(minutes)m \(seconds)s remaining"
        } else {
            return "\(seconds)s remaining"
        }
    }
    
    /// Format progress as a percentage
    /// - Parameter progress: Progress value (0.0 to 1.0)
    /// - Returns: Formatted percentage string
    public static func formatProgressPercentage(_ progress: Double) -> String {
        return String(format: "%.0f%%", progress * 100)
    }
    
    /// Create a comprehensive progress string with percentage and time
    /// - Parameter update: The progress update
    /// - Returns: Formatted string like "50% - 2m 30s remaining - Processing file xyz"
    public static func formatProgressUpdate(_ update: ProgressUpdate) -> String {
        let percentage = formatProgressPercentage(update.progress)
        
        if update.progress >= 0.999 {
            return "Complete"
        }
        
        if let timeRemaining = update.estimatedTimeRemaining {
            let timeString = formatTimeRemaining(timeRemaining)
            return "\(percentage) - \(timeString) - \(update.message)"
        } else {
            return "\(percentage) - \(update.message)"
        }
    }
} 