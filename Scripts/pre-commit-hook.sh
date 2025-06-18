#!/bin/bash

# PayslipMax Pre-commit Hook
# Prevents commits that violate quality standards

set -e

echo "🔍 Running pre-commit quality checks..."

# Run the debt monitor
if bash Scripts/debt-monitor.sh > /tmp/debt-check.log 2>&1; then
    echo "✅ Quality gates passed - proceeding with commit"
    exit 0
else
    echo "❌ Quality gates failed!"
    echo "📄 Full report:"
    cat /tmp/debt-check.log
    echo
    echo "💡 To commit anyway (not recommended), use: git commit --no-verify"
    echo "🔧 To fix issues, address the violations shown above"
    exit 1
fi 