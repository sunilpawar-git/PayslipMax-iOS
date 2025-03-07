import Foundation

// A standalone version of PayslipItem that doesn't depend on SwiftData or the main app's code
struct StandalonePayslipItem: Identifiable, Codable {
    var id: UUID
    var month: String
    var year: Int
    var credits: Double
    var debits: Double
    var dspof: Double
    var tax: Double
    var location: String
    var name: String
    var accountNumber: String
    var panNumber: String
    var timestamp: Date
    
    init(id: UUID = UUID(), 
         month: String, 
         year: Int, 
         credits: Double, 
         debits: Double, 
         dspof: Double, 
         tax: Double, 
         location: String, 
         name: String, 
         accountNumber: String, 
         panNumber: String,
         timestamp: Date = Date()) {
        self.id = id
        self.month = month
        self.year = year
        self.credits = credits
        self.debits = debits
        self.dspof = dspof
        self.tax = tax
        self.location = location
        self.name = name
        self.accountNumber = accountNumber
        self.panNumber = panNumber
        self.timestamp = timestamp
    }
    
    // Helper method to create a sample payslip item
    static func sample() -> StandalonePayslipItem {
        return StandalonePayslipItem(
            month: "January",
            year: 2023,
            credits: 5000.0,
            debits: 1000.0,
            dspof: 200.0,
            tax: 800.0,
            location: "New York",
            name: "John Doe",
            accountNumber: "1234567890",
            panNumber: "ABCDE1234F",
            timestamp: Date()
        )
    }
} 