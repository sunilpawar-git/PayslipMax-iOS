#!/bin/sh

# Safe checkout script for Xcode projects
# Usage: ./Scripts/safe-checkout.sh branch-name

if [ -z "$1" ]; then
    echo "Usage: $0 <branch-name>"
    exit 1
fi

BRANCH_NAME="$1"

# Check if Xcode is running
if pgrep -x "Xcode" > /dev/null; then
    echo "Detected Xcode running. Closing it before switching branches..."
    osascript -e 'tell application "Xcode" to quit'
    # Give Xcode a moment to close properly
    sleep 2
fi

# Switch branch
git checkout "$BRANCH_NAME"

echo "Switched to branch: $BRANCH_NAME"
echo "You can now reopen Xcode safely." 