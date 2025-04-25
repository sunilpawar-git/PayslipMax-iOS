import Foundation
@testable import Payslip_Max

/* 
This file previously contained various mock implementations that have now been
moved to domain-specific directories for better organization.

Current mock organization:

- Abbreviation/ - MockAbbreviationManager
- Analytics/ - MockChartDataPreparationService
- Core/ - MockDataService, MockDataServiceHelper
- Error/ - MockErrorHandler
- Parser/ - MockParsingCoordinator, MockPayslipPatternManager
- PDF/ - MockPDFService, MockPDFExtractor, MockTextExtractionService, MockPDFProcessingHandler, MockPasswordProtectedPDFHandler
- Payslip/ - MockPayslipValidationService, MockPayslipFormatDetectionService
- Security/ - MockEncryptionService, MockBiometricAuthService
- UI/ - MockHomeNavigationCoordinator

See README.md in this directory for more information on the organization and usage of mocks.
*/

/*
// MARK: - Mock Service Implementations
// NOTE: These mock implementations have been moved to domain-specific directories.
// See README.md in the Mocks directory for the new organization structure.

// MockEncryptionService has been moved to PayslipMaxTests/Mocks/Security/MockEncryptionService.swift
/* 
class MockEncryptionService: SensitiveDataEncryptionService {
    var encryptionCount = 0
    var decryptionCount = 0
    var shouldFailEncryption = false
    var shouldFailDecryption = false
    var shouldFailKeyManagement = false
    
    func encrypt(_ data: Data) throws -> Data {
        encryptionCount += 1
        if shouldFailEncryption {
            throw EncryptionService.EncryptionError.encryptionFailed
        }
        if shouldFailKeyManagement {
            throw EncryptionService.EncryptionError.keyNotFound
        }
        return data.base64EncodedData()
    }
    
    func decrypt(_ data: Data) throws -> Data {
        decryptionCount += 1
        if shouldFailDecryption {
            throw EncryptionService.EncryptionError.decryptionFailed
        }
        if shouldFailKeyManagement {
            throw EncryptionService.EncryptionError.keyNotFound
        }
        return Data(base64Encoded: data) ?? data
    }
    
    func reset() {
        shouldFailEncryption = false
        shouldFailDecryption = false
        shouldFailKeyManagement = false
        encryptionCount = 0
        decryptionCount = 0
    }
}
*/

// MockDataServiceHelper has been moved to PayslipMaxTests/Mocks/Core/MockDataServiceHelper.swift
/*
// MARK: - Data Service Helper
class MockDataServiceHelper {
    // ... existing code ...
}
*/

// MockDataService has been moved to PayslipMaxTests/Mocks/Core/MockDataService.swift
/*
// MARK: - Mock Data Service
class MockDataService: DataServiceProtocol {
    // ... existing code ...
}
*/

// MockPDFService has been moved to PayslipMaxTests/Mocks/PDF/MockPDFService.swift
/*
// MARK: - Mock PDF Service
class MockPDFService: PDFServiceProtocol {
    // ... existing code ...
}
*/