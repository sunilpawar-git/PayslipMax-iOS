# Directory Structure Optimization and Naming Standardization Plan

## Current Issues

1. **Redundant Directories**:
   - `Utils` and `Utilities` serve similar purposes
   - `DI` and `DependencyInjection` both contain dependency injection code
   - Multiple test directories with inconsistent naming

2. **Inconsistent Naming**:
   - Some directories contain spaces (`Payslip Max` vs `PayslipMax`)
   - Inconsistent file naming conventions

3. **Suboptimal Organization**:
   - Some files are not placed in logical locations
   - Feature-related files are scattered across different directories

## Target Structure

```
PayslipMax/
├── Core/
│   ├── DI/                 <- Consolidated dependency injection
│   ├── Models/             <- Core data models
│   └── Services/           <- Core services
├── Features/               <- Feature-based organization
│   ├── Home/
│   │   ├── Models/
│   │   ├── Views/
│   │   └── ViewModels/
│   ├── Payslips/
│   └── Settings/
├── Shared/
│   ├── Utilities/          <- Consolidated utilities
│   ├── Extensions/
│   └── Components/         <- Reusable UI components
├── Documentation/          <- Centralized documentation
└── Resources/
    └── Assets.xcassets/
```

## Implementation Plan

### Phase 1: Preparation and Analysis (No Code Changes)

1. **Identify Used Files**:
   - Use grep to find all imports and references
   - Document dependencies between files
   - Create a mapping of old → new file locations

2. **Create Backup**:
   - Create a git branch for the refactoring
   - Ensure all changes are committed before starting

### Phase 2: Consolidation of Utilities (Incremental Changes)

1. **Create Target Directory Structure**:
   - Create `Shared/Utilities` if it doesn't exist

2. **Move Files One by One**:
   - For each file in `Utils`:
     - Move to new location using Xcode's refactoring tools
     - Update imports in all referencing files
     - Build and test after each move
     - Commit changes if build succeeds

3. **Repeat for Utilities**:
   - Follow the same process for files in `Utilities`

4. **Remove Empty Directories**:
   - Once all files are moved, remove the empty directories

### Phase 3: Dependency Injection Consolidation

1. **Follow Similar Process for DI**:
   - Move files from `DependencyInjection` to `Core/DI`
   - Update imports
   - Build and test
   - Remove empty directories

### Phase 4: Directory Name Standardization

1. **Rename Directories**:
   - Use git mv to rename directories (remove spaces)
   - Update all import statements
   - Build and test

### Phase 5: Feature-Based Reorganization

1. **Identify Feature-Related Files**:
   - Group files by feature
   - Plan moves to feature-based directories

2. **Move Files by Feature**:
   - Move one feature at a time
   - Build and test after each feature

## Risk Mitigation

1. **Incremental Changes**:
   - Move one file at a time
   - Build and test after each move
   - Commit working changes frequently

2. **Reference Tracking**:
   - Track all file references to ensure imports are updated
   - Use grep to find usages before and after moves

3. **Rollback Plan**:
   - Each step should be committed separately
   - Ability to revert to the previous commit if issues arise

## Success Criteria

1. Project builds successfully after all changes
2. All tests pass
3. Directory structure matches target structure
4. No redundant directories remain
5. Consistent naming conventions are applied throughout

## Next Steps

Start with Phase 1: Preparation and Analysis to gather detailed information before making any code changes. 