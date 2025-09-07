# PayslipMax Phase 4 Scripts - Workflow Guide

This guide shows you how to use the Phase 4 Bulletproof Prevention System scripts to maintain PayslipMax's architectural excellence.

## 🎯 **Quick Start - Essential Commands**

```bash
# Check current status (run this first)
./Scripts/debt-trend-monitor.sh --dashboard

# Full architecture health check
./Scripts/architecture-guard.sh

# Analyze all violations
./Scripts/component-extraction-helper.sh --analyze-all

# Collect metrics for trending
./Scripts/debt-trend-monitor.sh --collect
```

---

## 📋 **Daily Developer Workflow**

### 🌅 **1. Morning Routine (Start of Work)**

```bash
# Check current project health
./Scripts/debt-trend-monitor.sh --dashboard

# Collect daily metrics
./Scripts/debt-trend-monitor.sh --collect

# Quick architecture check
./Scripts/architecture-guard.sh
```

**Expected Output:**
```
📈 Current Status
   Compliance Rate: 95.55%
   Violation Files: 28
   Quality Score: 98.66/100
```

### ✍️ **2. During Development**

#### **Before Adding Features to Large Files**
```bash
# Check if file is approaching limit
wc -l PayslipMax/Path/To/YourFile.swift

# Get quick suggestions if >250 lines
./Scripts/component-extraction-helper.sh --quick-suggestions PayslipMax/Path/To/YourFile.swift
```

#### **When File Approaches 280+ Lines**
```bash
# Get detailed extraction guidance
./Scripts/component-extraction-helper.sh --analyze-file PayslipMax/Path/To/YourFile.swift

# This provides:
# - Structure analysis
# - Specific refactoring suggestions
# - Command-line helpers
# - Step-by-step guidance
```

### 🔍 **3. Before Committing Code**

```bash
# The pre-commit hook runs automatically, but you can test manually:
./Scripts/architecture-guard.sh --build-mode

# If violations found, get specific fix suggestions:
./Scripts/architecture-guard.sh --fix-suggestions
```

**Automatic Behavior:**
- Pre-commit hook **blocks commits** if violations exist
- Shows which files need attention
- Provides fix suggestions

---

## 🔧 **File Refactoring Workflow**

### **Step 1: Identify Target Files**
```bash
# See all files needing attention
./Scripts/component-extraction-helper.sh --analyze-all

# Example output:
# 1. PatternEditView.swift: 515 lines
#    Priority: CRITICAL
#    Suggested approach: View (Core + Components + Helpers)
```

### **Step 2: Analyze Specific File**
```bash
# Deep analysis of target file
./Scripts/component-extraction-helper.sh --analyze-file "PayslipMax/Features/Settings/Views/PatternEditView.swift"
```

**This provides:**
- Structure breakdown (protocols, classes, functions, etc.)
- File type detection (ViewModel, Service, View, Model)
- Specific extraction strategy
- Command-line helpers for extraction

### **Step 3: Execute Refactoring**

The script provides tailored suggestions. For example, for a **View**:

```bash
# 1. Create backup
cp "PayslipMax/Features/Settings/Views/PatternEditView.swift" "PatternEditView.swift.backup"

# 2. Extract components (the script provides specific commands)
mkdir -p "PayslipMax/Features/Settings/Views/Components"

# 3. Follow the step-by-step guidance provided by the script
# 4. Test compilation after each step
# 5. Verify with architecture check
./Scripts/architecture-guard.sh
```

### **Step 4: Validate Results**
```bash
# Check all extracted files are <300 lines
find PayslipMax/Features/Settings/Views/ -name "PatternEdit*.swift" -exec wc -l {} +

# Run full architecture check
./Scripts/architecture-guard.sh

# Update metrics
./Scripts/debt-trend-monitor.sh --collect
```

---

## 📊 **Weekly Review Workflow**

### **Monday Morning - Team Review**
```bash
# Generate comprehensive trend report
./Scripts/debt-trend-monitor.sh --report

# Check compliance trend
./Scripts/debt-trend-monitor.sh --dashboard

# Identify files needing attention this week
./Scripts/component-extraction-helper.sh --analyze-all
```

### **Weekly Planning**
```bash
# Count current violations for planning
./Scripts/architecture-guard.sh --count-violations

# Get fix suggestions for prioritization
./Scripts/architecture-guard.sh --fix-suggestions
```

---

## 🚨 **Emergency Workflows**

### **When Build Fails Due to Architecture Violations**

```bash
# 1. See what's wrong
./Scripts/architecture-guard.sh --fix-suggestions

# 2. Get specific file guidance
./Scripts/component-extraction-helper.sh --analyze-file "path/to/problem/file.swift"

# 3. Quick temporary fix (if deadline pressure)
# - Move some functions to private extensions
# - Extract obvious helper methods
# - Plan proper refactoring for later

# 4. Validate fix
./Scripts/architecture-guard.sh --count-violations
```

### **When Multiple Violations Accumulate**

```bash
# 1. Get overview of all problems
./Scripts/component-extraction-helper.sh --analyze-all

# 2. Prioritize by file size and type
# Focus on:
# - Files >400 lines (CRITICAL)
# - ViewModels and Services (high impact)
# - Frequently modified files

# 3. Tackle one at a time using the refactoring workflow above
```

---

## 🎯 **Specific Use Cases**

### **Case 1: New Feature Development**

```bash
# Before starting
./Scripts/debt-trend-monitor.sh --dashboard

# While coding - check file growth
wc -l CurrentWorkingFile.swift

# If approaching 250 lines
./Scripts/component-extraction-helper.sh --quick-suggestions CurrentWorkingFile.swift

# Plan extraction BEFORE hitting 300 lines
```

### **Case 2: Code Review Process**

```bash
# Reviewer runs this before approving PR
./Scripts/architecture-guard.sh --ci-mode

# Check trend impact
./Scripts/debt-trend-monitor.sh --collect
./Scripts/debt-trend-monitor.sh --dashboard
```

### **Case 3: Monthly Architecture Health Review**

```bash
# Generate comprehensive report
./Scripts/debt-trend-monitor.sh --report > "architecture-report-$(date +%Y%m).md"

# Clean up old data
./Scripts/debt-trend-monitor.sh --cleanup 30

# Validate all systems
./Scripts/setup-phase4-prevention.sh --validate-only
```

### **Case 4: Onboarding New Developer**

```bash
# 1. New developer reads DEVELOPER_ONBOARDING.md

# 2. Verify their setup
./Scripts/setup-phase4-prevention.sh --validate-only

# 3. Show them current status
./Scripts/debt-trend-monitor.sh --dashboard

# 4. Practice with a violation file
./Scripts/component-extraction-helper.sh --analyze-file "SomeLargeFile.swift"
```

---

## ⚙️ **Automation Setup**

### **Daily Automation (Recommended)**

Add to your crontab (`crontab -e`):

```bash
# Daily metrics collection (9 AM)
0 9 * * * cd /Users/sunil/Downloads/PayslipMax && ./Scripts/debt-trend-monitor.sh --collect

# Daily health check (8 AM, before work)
0 8 * * * cd /Users/sunil/Downloads/PayslipMax && ./Scripts/architecture-guard.sh > /tmp/payslipmax-health.log 2>&1
```

### **Weekly Automation**

```bash
# Weekly trend report (Monday 10 AM)
0 10 * * 1 cd /Users/sunil/Downloads/PayslipMax && ./Scripts/debt-trend-monitor.sh --report

# Monthly cleanup (1st of month, 11 PM)
0 23 1 * * cd /Users/sunil/Downloads/PayslipMax && ./Scripts/debt-trend-monitor.sh --cleanup 30
```

---

## 🔍 **Troubleshooting**

### **Script Not Working?**

```bash
# Check script permissions
ls -la Scripts/

# Make executable if needed
chmod +x Scripts/*.sh

# Validate Phase 4 installation
./Scripts/setup-phase4-prevention.sh --validate-only
```

### **No Metrics Data?**

```bash
# Collect initial metrics
./Scripts/debt-trend-monitor.sh --collect

# Check if file exists
ls -la .architecture-metrics.json
```

### **Pre-commit Hook Not Working?**

```bash
# Check if installed
ls -la .git/hooks/pre-commit

# Reinstall if needed
cp Scripts/pre-commit-enforcement.sh .git/hooks/pre-commit
chmod +x .git/hooks/pre-commit
```

---

## 📈 **Success Metrics**

Track these metrics to ensure the system is working:

```bash
# Weekly check - should trend toward 0
./Scripts/architecture-guard.sh --count-violations

# Monthly review - should trend upward
./Scripts/debt-trend-monitor.sh --dashboard | grep "Compliance Rate"

# Quality target: 94+/100
./Scripts/debt-trend-monitor.sh --dashboard | grep "Quality Score"
```

---

## 🎯 **Best Practices**

### **DO:**
✅ Run `--dashboard` daily to track progress
✅ Use `--analyze-file` before refactoring large files
✅ Collect metrics regularly for trend analysis
✅ Plan extraction at 250+ lines, not 300+
✅ Follow the provided refactoring patterns

### **DON'T:**
❌ Skip the pre-commit checks
❌ Ignore warnings at 280+ lines
❌ Try to "fix" violations by just adding line breaks
❌ Refactor multiple files simultaneously without testing
❌ Forget to validate with `architecture-guard.sh` after changes

---

## 🚀 **Quick Reference Card**

| Task | Command |
|------|---------|
| **Daily Status** | `./Scripts/debt-trend-monitor.sh --dashboard` |
| **Full Health Check** | `./Scripts/architecture-guard.sh` |
| **Analyze Large File** | `./Scripts/component-extraction-helper.sh --analyze-file <file>` |
| **See All Violations** | `./Scripts/component-extraction-helper.sh --analyze-all` |
| **Get Fix Suggestions** | `./Scripts/architecture-guard.sh --fix-suggestions` |
| **Collect Metrics** | `./Scripts/debt-trend-monitor.sh --collect` |
| **Generate Report** | `./Scripts/debt-trend-monitor.sh --report` |
| **Count Violations** | `./Scripts/architecture-guard.sh --count-violations` |
| **Validate System** | `./Scripts/setup-phase4-prevention.sh --validate-only` |

---

**Remember: The goal is 0 files >300 lines and a quality score of 94+/100. These scripts make that achievable and maintainable!** 🎯
