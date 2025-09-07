# PayslipMax Developer Onboarding - Architecture Quality

Welcome to PayslipMax! This checklist ensures you're set up to maintain our 94+/100 architecture quality score.

## ✅ Setup Checklist

### 1. Quality Gate Activation
- [ ] Verify git pre-commit hook: `ls -la .git/hooks/pre-commit`
- [ ] Test pre-commit hook: `echo "test" > test.swift && git add test.swift && git commit -m "test"`
- [ ] Should see: "🔍 PayslipMax Quality Gate Enforcement..."
- [ ] Clean up: `git reset HEAD~ && rm test.swift`

### 2. IDE Configuration
- [ ] Xcode templates installed (run `./Scripts/xcode-integration.sh`)
- [ ] VS Code configured with 300-line rulers
- [ ] Architecture checking commands available

### 3. Architecture Rules Training
- [ ] Read [Technical Debt Elimination Roadmap](Documentation/TechnicalDebtReduction/DebtEliminationRoadmap2024.md)
- [ ] Understand the 300-line rule (NON-NEGOTIABLE)
- [ ] Review MVVM-SOLID compliance guidelines
- [ ] Practice component extraction patterns

### 4. Quality Tools Training
- [ ] Run `./Scripts/architecture-guard.sh --help`
- [ ] Run `./Scripts/debt-trend-monitor.sh --dashboard`
- [ ] Practice with `./Scripts/component-extraction-helper.sh`
- [ ] Understand violation reporting system

## 🏗️ Architecture Rules (CRITICAL)

### File Size Rule
- **Every Swift file MUST be under 300 lines**
- Check with: `wc -l filename.swift`
- Start extraction at 250+ lines
- **Never compromise on this rule**

### MVVM Compliance
- Views NEVER import business logic directly
- Services NEVER import SwiftUI (except UIAppearanceService)
- All dependencies via DI container
- Use protocol-based design

### Async-First Development
- All I/O operations use async/await
- No DispatchSemaphore or blocking operations
- Background processing through async coordinators

## 🔧 Daily Workflow

### Before Coding
1. Check current status: `./Scripts/architecture-guard.sh`
2. Collect metrics: `./Scripts/debt-trend-monitor.sh --collect`

### During Development
1. Monitor file sizes regularly
2. Use provided Xcode templates for new files
3. Extract components before hitting 280 lines

### Before Committing
1. Architecture check will run automatically
2. Fix any violations before proceeding
3. Use `./Scripts/architecture-guard.sh --fix-suggestions` for help

## 🚨 Emergency Procedures

### When Build Fails Due to Architecture Violations
1. Run `./Scripts/architecture-guard.sh --fix-suggestions`
2. Identify the largest files causing violations
3. Use `./Scripts/component-extraction-helper.sh <filename>` for guidance
4. Follow established refactoring patterns

### When Unsure About Architecture Decisions
1. Check existing similar implementations
2. Review successful refactoring examples in roadmap
3. Follow protocol-first, async-first principles
4. Ask for architecture review if needed

## 📊 Monitoring Tools

### Daily Commands
- `./Scripts/architecture-guard.sh` - Full architecture check
- `./Scripts/debt-trend-monitor.sh --dashboard` - Current status
- `./Scripts/debt-trend-monitor.sh --collect` - Update metrics

### Weekly Commands
- `./Scripts/debt-trend-monitor.sh --report` - Generate trend report
- Review architecture compliance trends

## 🎯 Success Metrics

- **100% of files under 300 lines**
- **Zero MVVM violations**
- **Zero DispatchSemaphore usage**
- **Quality score 94+/100**

## 📚 Resources

- [Architecture Documentation](Documentation/Architecture/)
- [Component Extraction Examples](Documentation/TechnicalDebtReduction/)
- [MVVM-SOLID Guidelines](Documentation/Architecture/MVVMSOLIDCompliancePlan.md)

---

**Remember**: Architecture quality is NOT optional. These rules maintain the codebase quality that enables rapid development and prevents technical debt.

Welcome to the team! 🚀
