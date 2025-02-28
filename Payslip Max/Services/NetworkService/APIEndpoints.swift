import Foundation

/// Struct defining API endpoints for the application
struct APIEndpoints {
    /// Base URLs for different environments
    struct BaseURL {
        static let development = "https://dev-api.payslipmax.com/api/v1"
        static let staging = "https://staging-api.payslipmax.com/api/v1"
        static let production = "https://api.payslipmax.com/api/v1"
        
        /// Returns the appropriate base URL based on the current environment
        static var current: String {
            #if DEBUG
            return development
            #else
            return production
            #endif
        }
    }
    
    /// Authentication endpoints
    struct Auth {
        static let login = "/auth/login"
        static let register = "/auth/register"
        static let refreshToken = "/auth/refresh"
        static let forgotPassword = "/auth/forgot-password"
        static let resetPassword = "/auth/reset-password"
        static let verifyEmail = "/auth/verify-email"
    }
    
    /// User endpoints
    struct User {
        static let profile = "/user/profile"
        static let updateProfile = "/user/profile"
        static let changePassword = "/user/change-password"
        static let deleteAccount = "/user/delete-account"
    }
    
    /// Payslip endpoints
    struct Payslips {
        static let list = "/payslips"
        static let details = "/payslips/" // Append ID
        static let upload = "/payslips/upload"
        static let sync = "/payslips/sync"
        static let backup = "/payslips/backup"
        static let restore = "/payslips/restore"
    }
    
    /// Premium features endpoints
    struct Premium {
        static let plans = "/premium/plans"
        static let subscribe = "/premium/subscribe"
        static let status = "/premium/status"
        static let cancel = "/premium/cancel"
        static let features = "/premium/features"
    }
    
    /// Helper method to construct a full URL from an endpoint
    /// - Parameter endpoint: The API endpoint
    /// - Returns: The full URL string
    static func url(for endpoint: String) -> String {
        return BaseURL.current + endpoint
    }
} 