#!/usr/bin/env swift

import Foundation

print("🔄 ChartDataPreparationService Async Test")
print(String(repeating: "=", count: 42))

struct PayslipChartData {
    let month: String
    let credits: Double
    let debits: Double
    let net: Double
}

struct TestPayslip {
    let month: String
    let year: Int
    let credits: Double
    let debits: Double
}

class ChartDataPreparationService {
    func prepareChartData(from payslips: [TestPayslip]) -> [PayslipChartData] {
        return payslips.map { payslip in
            PayslipChartData(
                month: payslip.month,
                credits: payslip.credits,
                debits: payslip.debits,
                net: payslip.credits - payslip.debits
            )
        }
    }
    
    func prepareChartDataInBackground(from payslips: [TestPayslip]) async -> [PayslipChartData] {
        return prepareChartData(from: payslips)
    }
}

let service = ChartDataPreparationService()
let testPayslips = [
    TestPayslip(month: "January", year: 2024, credits: 5000, debits: 1000),
    TestPayslip(month: "February", year: 2024, credits: 5500, debits: 1200)
]

print("\n🧪 Testing sync method...")
let syncResult = service.prepareChartData(from: testPayslips)
print("✅ Sync result: \(syncResult.count) items")
print("   Jan net: \(syncResult[0].net)")
print("   Feb net: \(syncResult[1].net)")

print("\n🧪 Testing async method...")
Task {
    let asyncResult = await service.prepareChartDataInBackground(from: testPayslips)
    print("✅ Async result: \(asyncResult.count) items")
    print("   Jan net: \(asyncResult[0].net)")
    print("   Feb net: \(asyncResult[1].net)")
    
    let resultsMatch = syncResult.count == asyncResult.count &&
                      syncResult[0].net == asyncResult[0].net &&
                      syncResult[1].net == asyncResult[1].net
    
    if resultsMatch {
        print("\n🎉 ASYNC TEST PASSED! Both methods produce identical results")
    } else {
        print("\n❌ ASYNC TEST FAILED! Results differ")
    }
    exit(0)
}

RunLoop.main.run()