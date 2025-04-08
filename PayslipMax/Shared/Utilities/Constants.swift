import Foundation

enum Constants {
    enum API {
        static let baseURL = "https://api.payslipmax.com"
        static let version = "v1"
    }
    
    enum Currency {
        static let symbol = "₹"
        static let code = "INR"
    }
    
    enum DateFormats {
        static let display = "dd MMM yyyy"
        static let api = "yyyy-MM-dd"
    }
    
    enum Military {
        static let ranks = [
            "Lieutenant",
            "Captain",
            "Major",
            "Lieutenant Colonel",
            "Colonel"
            // Add more ranks as needed
        ]
    }
} 