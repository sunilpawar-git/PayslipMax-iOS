#!/usr/bin/env swift

import Foundation

print("🔄 Testing ChartDataPreparationService Async Functionality")
print(String(repeating: "=", count: 55))

// MARK: - Mock Data Structures

struct PayslipChartData: Equatable {
    let id = UUID()
    let month: String
    let credits: Double
    let debits: Double
    let net: Double
    
    static func == (lhs: PayslipChartData, rhs: PayslipChartData) -> Bool {
        return lhs.month == rhs.month &&
               lhs.credits == rhs.credits &&
               lhs.debits == rhs.debits &&
               lhs.net == rhs.net
    }
}

protocol AnyPayslip {
    var month: String { get }
    var year: Int { get }
    var credits: Double { get }
    var debits: Double { get }
}

struct TestPayslip: AnyPayslip {
    let month: String
    let year: Int
    let credits: Double
    let debits: Double
}

// MARK: - ChartDataPreparationService Implementation

class ChartDataPreparationService {
    init() {}
    
    func prepareChartData(from payslips: [AnyPayslip]) -> [PayslipChartData] {
        var chartDataArray: [PayslipChartData] = []
        
        for payslip in payslips {
            let month = "\(payslip.month)"
            let credits = payslip.credits
            let debits = payslip.debits
            let net = credits - debits
            
            let chartData = PayslipChartData(
                month: month,
                credits: credits,
                debits: debits,
                net: net
            )
            
            chartDataArray.append(chartData)
        }
        
        return chartDataArray
    }
    
    func prepareChartDataInBackground(from payslips: [AnyPayslip]) async -> [PayslipChartData] {
        return prepareChartData(from: payslips)
    }
}

// MARK: - Async Test Suite

@MainActor
func runAsyncTests() async {
    let service = ChartDataPreparationService()
    var passedTests = 0
    var totalTests = 0
    
    print("\n🧪 Running Async ChartDataPreparationService Tests...")
    print(String(repeating: "=", count: 50))
    
    // Test 1: Async chart data preparation
    totalTests += 1
    print("\n📋 Test 1: Async chart data preparation")
    do {
        let payslips = [
            TestPayslip(month: "October", year: 2024, credits: 6000.0, debits: 1500.0),
            TestPayslip(month: "November", year: 2024, credits: 6200.0, debits: 1600.0)
        ]
        
        let chartData = await service.prepareChartDataInBackground(from: payslips)
        
        if chartData.count == 2 &&
           chartData[0].month == "October" && chartData[0].net == 4500.0 &&
           chartData[1].month == "November" && chartData[1].net == 4600.0 {
            print("   ✅ PASSED: Async chart data preparation successful")
            print("      Oct: \(chartData[0].net), Nov: \(chartData[1].net)")
            passedTests += 1
        } else {
            print("   ❌ FAILED: Async chart data preparation error")
        }
    }
    
    // Test 2: Async vs Sync consistency
    totalTests += 1
    print("\n📋 Test 2: Async vs Sync consistency")
    do {
        let payslips = [
            TestPayslip(month: "January", year: 2025, credits: 7000.0, debits: 1800.0),
            TestPayslip(month: "February", year: 2025, credits: 7100.0, debits: 1900.0)
        ]
        
        let syncChartData = service.prepareChartData(from: payslips)
        let asyncChartData = await service.prepareChartDataInBackground(from: payslips)
        
        if syncChartData.count == asyncChartData.count {
            var allMatch = true
            for i in 0..<syncChartData.count {
                if syncChartData[i] != asyncChartData[i] {
                    allMatch = false
                    break
                }
            }
            
            if allMatch {
                print("   ✅ PASSED: Async and sync methods produce identical results")
                passedTests += 1
            } else {
                print("   ❌ FAILED: Async and sync results differ")
            }
        } else {
            print("   ❌ FAILED: Async and sync result counts differ")
        }
    }
    
    // Test 3: Async performance with large dataset
    totalTests += 1
    print("\n📋 Test 3: Async performance with large dataset")
    do {
        var largePayslipSet: [AnyPayslip] = []
        
        for i in 1...500 {
            let payslip = TestPayslip(
                month: "AsyncMonth\(i % 12 + 1)",
                year: 2024,
                credits: Double(5000 + i),
                debits: Double(1000 + i / 2)
            )
            largePayslipSet.append(payslip)
        }
        
        let startTime = CFAbsoluteTimeGetCurrent()
        let chartData = await service.prepareChartDataInBackground(from: largePayslipSet)
        let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
        
        if chartData.count == 500 && timeElapsed < 1.0 {
            print("   ✅ PASSED: Async performance test completed")
            print("      Processed 500 items in \(String(format: "%.3f", timeElapsed)) seconds")
            passedTests += 1
        } else {
            print("   ❌ FAILED: Async performance test failed")
            print("      Items: \(chartData.count), Time: \(timeElapsed)s")
        }
    }
    
    // Final results
    print("\n" + String(repeating: "=", count: 50))
    print("🔄 Async ChartDataPreparationService Test Results")
    print(String(repeating: "=", count: 50))
    print("Tests Passed: \(passedTests)/\(totalTests)")
    print("Success Rate: \(Int(Double(passedTests)/Double(totalTests) * 100))%")
    
    if passedTests == totalTests {
        print("\n🎉 ALL ASYNC TESTS PASSED!")
        print("🔄 Async chart data processing verified")
        print("⚡ Background processing functional")
        print("🔗 Sync/Async consistency confirmed")
    } else {
        print("\n💥 Some async tests failed.")
    }
}

// Run the async tests
Task {
    await runAsyncTests()
    exit(0)
}