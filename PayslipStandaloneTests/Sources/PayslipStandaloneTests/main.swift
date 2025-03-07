import Foundation

print("PayslipStandaloneTests - Testing PayslipItem functionality")

// Create a sample payslip item
let sample = StandalonePayslipItem.sample()

// Print the sample payslip item details
print("\nSample PayslipItem:")
print("ID: \(sample.id)")
print("Month: \(sample.month)")
print("Year: \(sample.year)")
print("Credits: \(sample.credits)")
print("Debits: \(sample.debits)")
print("DSPOF: \(sample.dspof)")
print("Tax: \(sample.tax)")
print("Location: \(sample.location)")
print("Name: \(sample.name)")
print("Account Number: \(sample.accountNumber)")
print("PAN Number: \(sample.panNumber)")
print("Timestamp: \(sample.timestamp)")

// Test Codable functionality
print("\nTesting Codable functionality:")
do {
    let encoder = JSONEncoder()
    let data = try encoder.encode(sample)
    print("Successfully encoded PayslipItem to JSON")
    
    let decoder = JSONDecoder()
    let decoded = try decoder.decode(StandalonePayslipItem.self, from: data)
    print("Successfully decoded PayslipItem from JSON")
    
    // Verify the decoded object matches the original
    if decoded.id == sample.id &&
       decoded.month == sample.month &&
       decoded.year == sample.year &&
       decoded.credits == sample.credits &&
       decoded.debits == sample.debits &&
       decoded.dspof == sample.dspof &&
       decoded.tax == sample.tax &&
       decoded.location == sample.location &&
       decoded.name == sample.name &&
       decoded.accountNumber == sample.accountNumber &&
       decoded.panNumber == sample.panNumber {
        print("Decoded PayslipItem matches the original")
    } else {
        print("ERROR: Decoded PayslipItem does not match the original")
    }
} catch {
    print("ERROR: Failed to encode/decode PayslipItem: \(error)")
}

print("\nAll tests completed successfully!") 