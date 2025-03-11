import SwiftUI
import SwiftData

/// This file contains preview helpers for MainTabView with sample data
struct MainTabViewWithDataPreview: View {
    var body: some View {
        MainTabView()
            .modelContainer(sampleDataContainer)
    }
    
    // Create a container with sample data
    var sampleDataContainer: ModelContainer {
        let schema = Schema([
            PayslipItem.self,
            Payslip.self,
            Deduction.self,
            PostingDetails.self,
            Item.self
        ])
        
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        
        do {
            let container = try ModelContainer(for: schema, configurations: config)
            let context = ModelContext(container)
            
            // Add sample data
            createSampleData(in: context)
            
            return container
        } catch {
            fatalError("Failed to create preview container: \(error)")
        }
    }
    
    // Create sample data for previews
    func createSampleData(in context: ModelContext) {
        // Sample payslips
        let currentDate = Date()
        let calendar = Calendar.current
        
        // Get month names
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMMM"
        
        // Sample payslip 1 - Current month
        let payslip1 = PayslipItem(
            id: UUID(),
            month: dateFormatter.string(from: currentDate),
            year: calendar.component(.year, from: currentDate),
            credits: 75000.0,
            debits: 25000.0,
            dsop: 5000.0,
            tax: 15000.0,
            location: "Mumbai",
            name: "John Doe",
            accountNumber: "XXXX1234",
            panNumber: "ABCDE1234F",
            timestamp: currentDate
        )
        context.insert(payslip1)
        
        // Sample payslip 2 - Previous month
        let previousMonth = calendar.date(byAdding: .month, value: -1, to: currentDate)!
        let payslip2 = PayslipItem(
            id: UUID(),
            month: dateFormatter.string(from: previousMonth),
            year: calendar.component(.year, from: previousMonth),
            credits: 72000.0,
            debits: 24000.0,
            dsop: 4800.0,
            tax: 14500.0,
            location: "Mumbai",
            name: "John Doe",
            accountNumber: "XXXX1234",
            panNumber: "ABCDE1234F",
            timestamp: previousMonth
        )
        context.insert(payslip2)
        
        // Sample payslip 3 - Two months ago
        let twoMonthsAgo = calendar.date(byAdding: .month, value: -2, to: currentDate)!
        let payslip3 = PayslipItem(
            id: UUID(),
            month: dateFormatter.string(from: twoMonthsAgo),
            year: calendar.component(.year, from: twoMonthsAgo),
            credits: 70000.0,
            debits: 23000.0,
            dsop: 4600.0,
            tax: 14000.0,
            location: "Mumbai",
            name: "John Doe",
            accountNumber: "XXXX1234",
            panNumber: "ABCDE1234F",
            timestamp: twoMonthsAgo
        )
        context.insert(payslip3)
        
        do {
            try context.save()
        } catch {
            print("Error saving sample data: \(error)")
        }
    }
}

// Preview with sample data
#Preview("With Sample Data") {
    MainTabViewWithDataPreview()
} 