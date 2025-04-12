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
        
        // Generate current month payslip
        let payslip1 = PayslipItem(
            id: UUID(),
            timestamp: currentDate,
            month: Calendar.current.monthSymbols[Calendar.current.component(.month, from: currentDate) - 1],
            year: Calendar.current.component(.year, from: currentDate),
            credits: 75000,
            debits: 15000,
            dsop: 8000,
            tax: 10000,
            name: "John Doe",
            accountNumber: "123456789",
            panNumber: "ABCDE1234F",
            pdfData: nil
        )
        context.insert(payslip1)
        
        // Generate previous month payslip
        let previousMonth = calendar.date(byAdding: .month, value: -1, to: currentDate)!
        let payslip2 = PayslipItem(
            id: UUID(),
            timestamp: previousMonth,
            month: Calendar.current.monthSymbols[Calendar.current.component(.month, from: previousMonth) - 1],
            year: Calendar.current.component(.year, from: previousMonth),
            credits: 72000,
            debits: 14500,
            dsop: 7800,
            tax: 9800,
            name: "John Doe",
            accountNumber: "123456789",
            panNumber: "ABCDE1234F",
            pdfData: nil
        )
        context.insert(payslip2)
        
        // Generate two months ago payslip
        let twoMonthsAgo = calendar.date(byAdding: .month, value: -2, to: currentDate)!
        let payslip3 = PayslipItem(
            id: UUID(),
            timestamp: twoMonthsAgo,
            month: Calendar.current.monthSymbols[Calendar.current.component(.month, from: twoMonthsAgo) - 1],
            year: Calendar.current.component(.year, from: twoMonthsAgo),
            credits: 70000,
            debits: 14000,
            dsop: 7500,
            tax: 9500,
            name: "John Doe",
            accountNumber: "123456789",
            panNumber: "ABCDE1234F",
            pdfData: nil
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