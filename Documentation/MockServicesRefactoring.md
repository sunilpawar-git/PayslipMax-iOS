# MockServices.swift Refactoring Plan

## Current Issues
1. **Excessive Size**: The file is 1163 lines long with multiple mock service implementations
2. **Lack of Organization**: Multiple mock services in one file makes it difficult to locate specific mocks
3. **Low Cohesion**: Unrelated services are grouped together
4. **Maintenance Challenges**: Changes to one mock might affect others

## Proposed Directory Structure

```
PayslipMaxTests/
├── Mocks/
│   ├── Core/
│   │   ├── MockError.swift
│   │   ├── MockSecurityService.swift
│   │   └── MockDataService.swift
│   ├── PDF/
│   │   ├── MockPDFService.swift
│   │   ├── MockPDFExtractor.swift
│   │   ├── MockTextExtractionService.swift
│   │   └── MockPayslipValidationService.swift
│   └── Payslip/
│       ├── MockPayslipFormatDetectionService.swift
│       ├── MockPayslipProcessingService.swift
│       ├── MockPayslipProcessor.swift
│       ├── MockPayslipProcessorFactory.swift
│       └── MockPayslipProcessingPipeline.swift
```

## Service Breakdown 

### Core Services
1. **MockError** - Enum defining common error types for mocks
   - Lines: 8-41

2. **MockSecurityService** - Security-related mocking
   - Lines: 44-123

3. **MockDataService** - Data persistence mocking
   - Lines: 126-196

### PDF Services
4. **MockPDFService** - PDF processing mocking
   - Lines: 199-280

5. **MockPDFProcessingService** - PDF processing pipeline mocking
   - Lines: 283-369

6. **MockPDFExtractor** - PDF extraction mocking
   - Lines: 372-422

7. **MockPDFTextExtractionService** - Text extraction mocking
   - Lines: 625-661

8. **MockPayslipValidationService** - Validation mocking
   - Lines: 472-511

### Payslip Services
9. **MockPayslipProcessor** - Payslip processing mocking
   - Lines: 514-571

10. **MockPayslipProcessorFactory** - Processor factory mocking
   - Lines: 574-622

11. **MockPayslipProcessingPipeline** - Processing pipeline mocking
   - Lines: 664-756

12. **MockParsingCoordinator** - Parsing coordination mocking
   - Lines: 759-810  

13. **MockPayslipParser** - Payslip format-specific parser mocking
   - Lines: 813-887

## Implementation Approach

### Phase 1: Directory Structure
- Create the directory structure as outlined
- Move just 1-2 services to test the approach

### Phase 2: Core Services Migration
- Move MockError
- Move MockSecurityService
- Move MockDataService
- Update imports where needed

### Phase 3: PDF Services Migration
- Move MockPDFService
- Move MockPDFExtractor
- etc.

### Phase 4: Payslip Services Migration
- Move all payslip-related services
- Update imports

### Phase 5: Cleanup
- Add summary comments to each file
- Verify all tests still pass
- Remove the original MockServices.swift file

## Benefits
1. **Improved Organization**: Each mock service has its own file
2. **Better Discoverability**: Easier to find specific mocks
3. **Enhanced Maintainability**: Changes to one mock won't affect others
4. **Follows Project Guidelines**: Adheres to the code organization rules (max 300 lines per file) 