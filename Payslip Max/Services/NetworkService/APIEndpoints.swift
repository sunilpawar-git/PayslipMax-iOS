import Foundation

struct APIEndpoints {
    static let baseURL = "https://api.payslipmax.com" // This will be changed when you have a real API
    
    struct Auth {
        static let login = "\(baseURL)/auth/login"
        static let register = "\(baseURL)/auth/register"
        static let verify = "\(baseURL)/auth/verify"
    }
    
    struct Payslips {
        static let sync = "\(baseURL)/payslips/sync"
        static let backup = "\(baseURL)/payslips/backup"
        static let restore = "\(baseURL)/payslips/restore"
    }
    
    struct Premium {
        static let status = "\(baseURL)/premium/status"
        static let upgrade = "\(baseURL)/premium/upgrade"
    }
} 