import Foundation

// MARK: - Error Handling Extensions

extension Result where Failure == Error {
    func mapError() -> Result<Success, AppError> {
        mapError { AppError.from($0) }
    }
}

// MARK: - Error Logging

class ErrorLogger {
    static func log(_ error: Error, file: String = #file, function: String = #function, line: Int = #line) {
        Logger.error("Error: \(AppError.from(error).debugDescription)", category: "Error", file: file, function: function, line: line)
    }
}
