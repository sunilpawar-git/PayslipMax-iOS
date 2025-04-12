#!/bin/bash

# This script finds all Swift files with PayslipItem initialization where 'timestamp:' appears after 'month:' 
# and fixes the parameter order.

echo "Searching for files with PayslipItem initializations that need parameter order fixes..."

# Use grep to find files with the pattern
grep -r "timestamp: .*,$" --include="*.swift" . | grep -B 10 "month: " > /tmp/files_to_fix.txt

# Process each file to fix the parameter order
while read -r line; do
  if [[ $line == --* ]]; then
    # Skip separator lines
    continue
  fi
  
  file=$(echo "$line" | cut -d':' -f1)
  if [[ -f "$file" ]]; then
    echo "Processing file: $file"
    
    # Use sed to fix the parameter order in place
    # This moves 'timestamp:' line before 'month:' line
    # This is a complex operation and might need manual review
    perl -i -p0e 's/(.*?)(.*?month: .*?,\n)(.*?timestamp: .*?,\n)/$1$3$2/s' "$file"
  fi
done < /tmp/files_to_fix.txt

echo "Parameter order fix attempt completed. Please review the changed files." 