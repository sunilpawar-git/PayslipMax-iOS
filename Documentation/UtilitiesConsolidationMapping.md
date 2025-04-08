# Utilities Consolidation - File Mapping

## Current Files

### Utils Directory

| File | Description | New Location | Dependencies |
|------|-------------|--------------|--------------|
| AbbreviationLearningSystem.swift | Learning system for abbreviations | Shared/Utilities | Unknown |
| AbbreviationManager.swift | Manager for abbreviations | Shared/Utilities | Used in multiple parsers |
| Constants.swift | Application constants | Shared/Utilities | Likely used throughout the app |
| Formatters.swift | Date and number formatters | Shared/Utilities | Unknown |
| PayslipLearningSystem.swift | Learning system for payslips | Shared/Utilities | Unknown |
| PayslipPatternManager.swift | Manager for payslip patterns | Shared/Utilities | Unknown |
| ViewModifiers.swift | SwiftUI view modifiers | Shared/Components | SwiftUI views |

### Utilities Directory

| File | Description | New Location | Dependencies |
|------|-------------|--------------|--------------|
| DocumentPickerView.swift | View for document picking | Shared/Components | SwiftUI views |
| ScannerView.swift | View for scanning documents | Shared/Components | SwiftUI views |

## Implementation Steps

For each file in the Utils directory:

1. Create the target directory if it doesn't exist
2. Create a new file in the target location
3. Copy the content from the original file
4. Update imports if necessary
5. Build and test
6. If successful, delete the original file

Repeat the same process for files in the Utilities directory.

## Order of Implementation

1. Start with files that have fewer dependencies:
   - Constants.swift
   - Formatters.swift
   - ViewModifiers.swift

2. Progress to more dependent files:
   - ScannerView.swift
   - DocumentPickerView.swift
   - AbbreviationManager.swift
   - AbbreviationLearningSystem.swift
   - PayslipLearningSystem.swift
   - PayslipPatternManager.swift

## Verification Steps

After each file is moved:

1. Build the project
2. Run basic UI tests
3. Ensure the functionality works as expected

## Rollback Plan

If issues arise:

1. Revert the changes for the problematic file
2. Document the issue
3. Consider alternative approaches 