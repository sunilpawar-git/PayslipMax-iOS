#!/bin/bash

# Navigate to the project directory
cd "$(dirname "$0")"

# Run the cleanup script
./cleanup.sh

# Keep the terminal window open until the user presses a key
echo ""
echo "Press any key to close this window..."
read -n 1 -s 