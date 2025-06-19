# PayslipMax Development Workflow
## Phase 1: Prevention Infrastructure

This document outlines the development workflow designed to prevent technical debt accumulation while maintaining development velocity.

## 🎯 Core Principles

### 1. **Boy Scout Rule Plus**
- Leave the code better than you found it
- For every file you touch, consider cleaning up nearby debt
- No compromise on quality for speed

### 2. **Prevention Over Cure**
- Stop new debt at the source
- Quality gates prevent problematic code from entering the codebase
- Continuous monitoring of debt indicators

## 🚦 Quality Gates

### Critical Gates (Must Pass)

#### 1. File Size Rule
- **Limit**: 300 lines maximum per Swift file
- **Warning**: 250+ lines triggers refactoring consideration
- **Check**: `find PayslipMax -name "*.swift" -exec wc -l {} + | awk '$1 > 300'`
- **Action**: If approaching 250 lines, split into focused components

#### 2. Concurrency Rule
- **Prohibition**: No `DispatchSemaphore` for async/sync conversion
- **Requirement**: Use structured concurrency (async/await) throughout
- **Check**: `grep -r "DispatchSemaphore" PayslipMax --include="*.swift"`
- **Action**: Refactor entire call chain to async/await

#### 3. Error Handling Rule
- **Prohibition**: No `fatalError` for recoverable conditions
- **Requirement**: Graceful error handling with proper recovery
- **Check**: Review any new `fatalError` usage in PR diff
- **Action**: Replace with proper error handling and recovery

#### 4. Single Responsibility Rule
- **Requirement**: Each class/service has one clear purpose
- **Check**: Manual review during code review
- **Action**: Extract mixed responsibilities into focused components

## 🔄 Development Process

### Before Starting Work

1. **Check Current Debt Status**
   ```bash
   bash Scripts/debt-monitor.sh
   ```

2. **Identify Related Debt**
   - Look for large files in the area you're working
   - Check for existing semaphore usage
   - Note any error handling issues

3. **Plan Debt Reduction**
   - If working in a problematic area, plan to clean it up first
   - Allocate 20% of story time to debt reduction

### During Development

1. **File Size Monitoring**
   - Before adding to existing files, check line count
   - If file is 250+ lines, consider splitting first
   - Extract reusable components during feature work

2. **Two-File Rule**
   - For every new file added, consider splitting an existing large file
   - Use file creation as an opportunity to reduce debt

3. **Concurrency Compliance**
   - Never introduce `DispatchSemaphore` for async/sync conversion
   - If existing code blocks you, refactor the caller to async first

4. **Error Handling Standards**
   - Design error recovery strategies
   - Use `Result<Success, Error>` for fallible operations
   - Document error conditions and recovery approaches

### Before Committing

1. **Run Quality Checks**
   ```bash
   bash Scripts/debt-monitor.sh
   ```

2. **Self-Review Checklist**
   - [ ] No files exceed 300 lines
   - [ ] No new `DispatchSemaphore` usage
   - [ ] Proper error handling (no new `fatalError`)
   - [ ] Single responsibility maintained
   - [ ] Memory considerations for large data

## 🛠️ Tools & Scripts

### 1. Debt Monitor
```bash
# Check current debt status
bash Scripts/debt-monitor.sh

# Quick file size check
find PayslipMax -name "*.swift" -exec wc -l {} + | awk '$1 > 300 {print $2 " (" $1 " lines)"}'
```

### 2. Git Hooks Setup
```bash
# Install pre-commit hooks
bash Scripts/install-git-hooks.sh
```

### 3. Xcode Integration
- Add `Scripts/xcode-build-phase.sh` as a build phase
- Provides real-time debt feedback during development

## 📋 Code Review Process

### For Reviewers

1. **Verify PR Checklist**
   - Ensure all critical quality gates are checked
   - Run `bash Scripts/debt-monitor.sh` on the branch

2. **Architecture Review**
   - Check for proper layer separation (View → ViewModel → Service → Repository)
   - Verify protocol usage for testability
   - Confirm dependency injection patterns

3. **Technical Debt Impact**
   - Does this PR reduce, maintain, or add debt?
   - Are large files being split appropriately?
   - Is concurrency handled correctly?

### For Authors

1. **Pre-Review Preparation**
   - Run complete quality check suite
   - Document any technical debt decisions
   - Explain any quality gate bypasses

2. **Documentation**
   - Update relevant documentation
   - Add comments for complex logic
   - Document architectural decisions

## 🎯 Feature Integration Strategy

### Adding New Features

#### Traditional Approach ❌
```
1. Add to existing large ViewModels
2. Create monolithic services
3. Mix UI and business logic
4. Ignore existing debt in the area
```

#### Debt-Conscious Approach ✅
```
1. Identify related debt in target area
2. Refactor/clean existing code first
3. Create focused, single-responsibility components
4. Extract reusable patterns during development
5. Leave area cleaner than before
```

### Example: Adding Analytics Feature

#### Step 1: Assessment
- Check if InsightsViewModel is already large (it is - 1,061 lines!)
- Identify what can be extracted

#### Step 2: Refactoring First
- Extract chart data preparation into `ChartDataViewModel`
- Extract financial calculations into `FinancialSummaryViewModel`
- Extract trend analysis into `TrendAnalysisViewModel`

#### Step 3: Clean Implementation
- Create new `AnalyticsViewModel` with single responsibility
- Use extracted components for common functionality
- Result: Multiple focused ViewModels instead of one giant one

## 📈 Success Metrics

### Weekly Targets
- Files > 300 lines: Reduce by 2-3 files
- DispatchSemaphore usage: Reduce by 1-2 instances
- fatalError count: Replace 1-2 with proper error handling
- New feature areas: 100% compliance with quality gates

### Monthly Targets
- 80% of files under 300 lines
- Zero DispatchSemaphore usage
- Comprehensive error handling strategy
- Quality score > 80/100

## 🚀 Getting Started

### Immediate Setup (Week 1)

1. **Install Quality Gates**
   ```bash
   # Set up git hooks
   bash Scripts/install-git-hooks.sh
   
   # Test debt monitoring
   bash Scripts/debt-monitor.sh
   ```

2. **Team Alignment**
   - Review this workflow with team
   - Agree on quality gate enforcement
   - Choose first debt reduction target

3. **Xcode Integration**
   - Add build phase script for real-time feedback
   - Configure warnings for debt indicators

### First Sprint Integration (Week 2)

1. **Apply to Current Work**
   - Use workflow for all new PRs
   - Apply refactor-first approach to feature work
   - Document any quality gate bypasses

2. **Monitor Progress**
   - Track weekly debt metrics
   - Celebrate debt reduction wins
   - Adjust workflow based on learnings

---

**Remember**: The goal is not to sacrifice development velocity, but to ensure that every development cycle leaves the codebase in a better state. Quality gates may seem restrictive initially, but they prevent much larger refactoring efforts later. 