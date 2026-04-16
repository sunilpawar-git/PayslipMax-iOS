# SwiftLint Integration Guide

## Overview

SwiftLint has been successfully integrated into the PayslipMax Xcode project build process. This ensures code quality and style compliance with Apple/Swift guidelines during every build.

## Configuration Quality

### ✅ Alignment with Apple/Swift Guidelines

Our SwiftLint configuration follows the latest Apple/Swift standards:

1. **Swift 6 Concurrency Support**
   - `async_without_await` - Detects async functions without await
   - Modern async/await patterns enforced

2. **Performance Optimizations**
   - `contains_over_filter_count` - Prefer `contains` over `filter().count > 0`
   - `contains_over_filter_is_empty` - Prefer `contains` over `filter().isEmpty`
   - `contains_over_first_not_nil` - Prefer `contains` over `first != nil`
   - `closure_body_length` - Limits closure complexity

3. **Code Quality Rules**
   - `direct_return` - Encourages direct returns
   - `sorted_imports` - Enforces import ordering
   - `modifier_order` - Ensures proper access modifier ordering
   - `explicit_self` - Analyzer rule for explicit self usage

4. **Project-Specific Custom Rules**
   - `no_swiftui_in_services` - MVVM compliance (Services must not import SwiftUI)
   - `no_service_init_in_views` - DI compliance (Services via ViewModels only)
   - `no_shared_business_singletons` - Prefer DI containers
   - `no_hardcoded_strings` - Localization enforcement
   - `async_blocking_calls` - Bans DispatchSemaphore/DispatchGroup (use async/await)

### Configuration File

Location: `.swiftlint.yml` (project root)

Key Settings:
- **File Length**: Warning at 280 lines, Error at 300 lines (matches project rules)
- **Function Body Length**: Warning at 40 lines, Error at 80 lines
- **Line Length**: Warning at 120 chars, Error at 200 chars
- **Closure Body Length**: Warning at 20 lines, Error at 40 lines
- **Cyclomatic Complexity**: Warning at 10, Error at 20

## Build Integration

### Build Phase Script

Location: `Scripts/swiftlint-build-phase.sh`

**Features**:
- ✅ Runs automatically during Debug builds
- ✅ Skips in Release builds (for faster builds)
- ✅ Non-blocking warnings (build continues)
- ✅ Strict mode available for CI/CD (`SWIFTLINT_STRICT=1`)
- ✅ Always-run mode available (`SWIFTLINT_ALWAYS_RUN=1`)

### Integration Status

✅ **Successfully Integrated**

The SwiftLint build phase has been added to the PayslipMax target:
- **Build Phase ID**: `00E56E947AA446FCA8F47A9C`
- **Position**: After "Resources" phase
- **Script Path**: `${SRCROOT}/Scripts/swiftlint-build-phase.sh`

### Verification

To verify the integration:

1. **Open Xcode**:
   ```bash
   open PayslipMax.xcodeproj
   ```

2. **Check Build Phases**:
   - Select PayslipMax target
   - Go to "Build Phases" tab
   - Verify "SwiftLint" phase appears after "Resources"

3. **Test Build**:
   ```bash
   xcodebuild clean build -scheme PayslipMax -configuration Debug
   ```

4. **Run SwiftLint Manually**:
   ```bash
   swiftlint lint --config .swiftlint.yml
   ```

## Usage

### During Development

SwiftLint runs automatically during Debug builds. Warnings appear in Xcode's Issue Navigator:

- **Warnings**: Shown but don't block builds
- **Errors**: Shown but don't block builds (in normal mode)
- **Strict Mode**: Set `SWIFTLINT_STRICT=1` to fail builds on violations

### Environment Variables

| Variable | Purpose | Default |
|----------|---------|---------|
| `SWIFTLINT_STRICT` | Treat warnings as errors | `0` (disabled) |
| `SWIFTLINT_ALWAYS_RUN` | Run in Release builds too | `0` (Debug only) |

### CI/CD Integration

For continuous integration, enable strict mode:

```bash
# In your CI script
export SWIFTLINT_STRICT=1
xcodebuild clean build -scheme PayslipMax -configuration Debug
```

Or run SwiftLint separately:

```bash
swiftlint lint --config .swiftlint.yml --strict
```

## Fixing Violations

### Common Violations

1. **Sorted Imports**
   ```swift
   // ❌ Wrong
   import Foundation
   import SwiftUI

   // ✅ Correct
   import Foundation
   import SwiftUI  // Already sorted, but ensure alphabetical order
   ```

2. **Vertical Whitespace**
   ```swift
   // ❌ Wrong
   func example() {

       let value = 1
   }

   // ✅ Correct
   func example() {
       let value = 1
   }
   ```

3. **File Length**
   - If file exceeds 300 lines, extract components
   - Use component extraction helper: `Scripts/component-extraction-helper.sh`

### Auto-Fix

Some violations can be auto-fixed:

```bash
swiftlint lint --fix --config .swiftlint.yml
```

**Note**: Auto-fix only applies to "correctable" rules. Review changes before committing.

## Disabling Rules (When Necessary)

### File-Level Disable

```swift
// swiftlint:disable rule_name
// Your code here
// swiftlint:enable rule_name
```

### Line-Level Disable

```swift
let value = something() // swiftlint:disable:next force_unwrapping
```

### Project-Level Disable

Edit `.swiftlint.yml`:

```yaml
disabled_rules:
  - trailing_whitespace  # Already disabled
  - another_rule
```

## Best Practices

1. **Fix Violations Early**: Don't accumulate technical debt
2. **Use Auto-Fix**: Run `swiftlint lint --fix` regularly
3. **Review Custom Rules**: Ensure project-specific rules align with architecture
4. **CI Integration**: Enable strict mode in CI/CD pipelines
5. **Team Alignment**: Ensure all team members have SwiftLint installed

## Troubleshooting

### SwiftLint Not Running

1. **Check Installation**:
   ```bash
   swiftlint version
   # Should show: 0.62.2 or later
   ```

2. **Install SwiftLint**:
   ```bash
   brew install swiftlint
   ```

3. **Verify Build Phase**:
   - Open Xcode → Build Phases → Check "SwiftLint" phase exists
   - Verify script path: `${SRCROOT}/Scripts/swiftlint-build-phase.sh`

### Too Many Warnings

If you have many existing violations:

1. **Gradual Fix**: Fix violations file-by-file
2. **Disable Temporarily**: Add problematic files to `excluded` in `.swiftlint.yml`
3. **Baseline**: Create a baseline file (future enhancement)

### Performance Issues

SwiftLint can be slow on large projects:

1. **Exclude Generated Files**: Already configured in `.swiftlint.yml`
2. **Use Analyzer Rules Sparingly**: Analyzer rules are slower
3. **Run Selectively**: Use `--path` flag to lint specific directories

## Resources

- **SwiftLint Documentation**: https://github.com/realm/SwiftLint
- **Apple Swift Style Guide**: https://swift.org/documentation/api-design-guidelines/
- **Project Rules**: See `CLAUDE.md` for architecture constraints

## Summary

✅ **SwiftLint is fully integrated and ready to use**

- Configuration aligns with latest Apple/Swift guidelines
- Build phase runs automatically during Debug builds
- Custom rules enforce MVVM and architecture compliance
- Non-blocking by default (warnings don't fail builds)
- Strict mode available for CI/CD

**Next Steps**:
1. Build the project to see SwiftLint in action
2. Fix any existing violations gradually
3. Enable strict mode in CI/CD for quality gates


