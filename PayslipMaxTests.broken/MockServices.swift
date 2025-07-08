import Foundation
@testable import PayslipMax

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

