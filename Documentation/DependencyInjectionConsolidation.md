# Dependency Injection Consolidation Plan

## Current State

We currently have multiple directories that contain dependency injection code:

1. `Payslip Max/DI/` - Appears to be empty or minimally used
2. `Payslip Max/DependencyInjection/` - Contains AppContainer.swift
3. `Payslip Max/Core/DI/` - Contains DIContainer.swift and MockServices.swift

## Target State

Consolidate all dependency injection code into `Core/DI`:

```
Core/
└── DI/
    ├── DIContainer.swift     (existing)
    ├── MockServices.swift    (existing)
    ├── AppContainer.swift    (to be moved from DependencyInjection)
    └── [Other DI files]
```

## Implementation Steps

### 1. Analysis

- Verify the contents and dependencies of each DI file
- Document any imports that need to be updated
- Check for any circular dependencies

### 2. Consolidation

1. Move `AppContainer.swift` from `DependencyInjection` to `Core/DI`:
   - Create a copy in the new location
   - Update any imports
   - Build and test
   - If successful, delete the original file

2. Check `DI` directory:
   - If it contains any files, follow the same process to move them
   - If empty, schedule for removal

### 3. Cleanup

1. Once all files are moved and the build is successful:
   - Remove the empty `DependencyInjection` directory
   - Remove the empty `DI` directory

## Verification

1. Build the project after each move
2. Ensure all dependency injection features work as expected
3. Check that no references to the old paths remain

## Rollback Plan

If issues arise:
1. Keep original files in place
2. Remove new copies
3. Revert any modified imports
4. Document the issue for further analysis 