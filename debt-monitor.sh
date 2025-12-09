#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT"

echo "== Tech Debt Monitor =="

if ! command -v rg >/dev/null 2>&1; then
  echo "ripgrep (rg) is required. Install rg and re-run."
  exit 1
fi

issue_count=0

# 1) Enforce 300-line limit for Swift files
echo "-- Checking Swift file lengths (<= 300 lines)"
while IFS= read -r -d '' file; do
  lines=$(wc -l < "$file")
  if [ "$lines" -gt 300 ]; then
    echo "❌ $lines lines: $file"
    issue_count=$((issue_count + 1))
  fi
done < <(find "$ROOT/PayslipMax" -name "*.swift" \
  -not -path "*/.build/*" \
  -not -path "*/DerivedData/*" \
  -print0)

# 2) Blocking constructs (DispatchSemaphore / DispatchGroup) - code-level, not comments
echo "-- Checking for blocking constructs"
if rg --glob '*.swift' "DispatchSemaphore\\s*\\(|DispatchGroup\\s*\\(" "$ROOT/PayslipMax" >/tmp/debt-blocking.log 2>/dev/null; then
  echo "❌ Blocking constructs found:"
  cat /tmp/debt-blocking.log
  issue_count=$((issue_count + 1))
else
  echo "✅ No blocking constructs found"
fi

# 3) SwiftUI imports inside Services (allowed: UIAppearanceService)
echo "-- Checking SwiftUI imports in Services"
if rg --glob 'PayslipMax/Services/**/*.swift' "import SwiftUI" "$ROOT" \
  | grep -v "UIAppearanceService" >/tmp/debt-swiftui.log 2>/dev/null; then
  echo "❌ SwiftUI import inside Services (except UIAppearanceService):"
  cat /tmp/debt-swiftui.log
  issue_count=$((issue_count + 1))
else
  echo "✅ No disallowed SwiftUI imports in Services"
fi

if [ "$issue_count" -gt 0 ]; then
  echo "== Tech debt check FAILED ($issue_count issue(s)) =="
  exit 1
fi

echo "== Tech debt check PASSED =="
exit 0

