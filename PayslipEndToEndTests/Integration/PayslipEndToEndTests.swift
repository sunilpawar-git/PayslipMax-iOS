// Set up the factory to use our mock encryption service
PayslipItem.setEncryptionServiceFactory { [unowned self] in
    return self.mockEncryptionService as EncryptionServiceProtocolInternal
}

// Create a temporary URL for the PDF
let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("test.pdf")
try pdfData.write(to: tempURL)

// Mock decryption to ensure count is increased
try mockEncryptionService.decrypt("test".data(using: .utf8)!) 