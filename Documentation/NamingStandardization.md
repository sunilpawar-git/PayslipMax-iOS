# Naming Standardization Guidelines for PayslipMax

## Directory Naming

1. **PascalCase for All Directories**:
   - Use: `PayslipMax`, `Features`, `Models`
   - Avoid: `payslipmax`, `features`, `Payslip Max`

2. **No Spaces in Directory Names**:
   - Use: `CoreServices`, `UIComponents` 
   - Avoid: `Core Services`, `UI Components`

3. **Descriptive Directory Names**:
   - Use names that clearly indicate the contents
   - Group related files under logical directories

## File Naming

1. **PascalCase for Swift Files**:
   - Use: `HomeViewModel.swift`, `PayslipView.swift`
   - Avoid: `homeViewModel.swift`, `payslip_view.swift`

2. **Consistent Type Suffixes**:
   - Views: `*View.swift`
   - View Models: `*ViewModel.swift`
   - Models: no suffix or `*Model.swift` if clarification needed
   - Services: `*Service.swift`
   - Protocols: `*Protocol.swift`
   - Extensions: `*+Extension.swift`

3. **Test Files**:
   - Always append `Tests` to the end: `HomeViewModelTests.swift`
   - Mirror the structure of the files being tested

4. **Mock Files**:
   - Prefix with `Mock`: `MockDataService.swift`
   - Should implement the same interface as the real component

## Import Statements

1. **Organize Imports**:
   - Foundation/SwiftUI first
   - Third-party libraries next
   - Project modules last
   - Alphabetize within each group

2. **No Unused Imports**:
   - Remove any import statements not actually used in the file

## Code Organization

1. **MARK Comments**:
   - Use consistent MARK structure within files
   - Example:
     ```swift
     // MARK: - Properties
     
     // MARK: - Initialization
     
     // MARK: - Public Methods
     
     // MARK: - Private Methods
     ```

2. **Property Organization**:
   - Group properties by access level and purpose
   - Published properties first
   - Computed properties after stored properties

## Implementation Guidelines

1. **Granular Changes**:
   - Rename one file at a time
   - Update all references
   - Build and test after each rename

2. **Keep Xcode Project Structure Updated**:
   - When moving files, make sure to update the Xcode project structure
   - Use Xcode's refactoring tools when possible

3. **Document Exceptions**:
   - If a naming convention needs to be broken for a specific reason, document why

## Practical Examples

| Old Name | New Name | Reason |
|----------|----------|--------|
| `payslip max.swift` | `PayslipMax.swift` | PascalCase, no spaces |
| `data_service.swift` | `DataService.swift` | PascalCase, no underscores |
| `PDFprocessor.swift` | `PDFProcessor.swift` | Consistent capitalization |
| `TestMockService.swift` | `MockServiceTests.swift` | Tests suffix at end |

## Validation Checklist

When standardizing names, verify:

1. The file/directory name follows conventions
2. All imports are updated in referencing files
3. Xcode project structure is updated
4. Build succeeds after each change
5. Tests pass after each change 