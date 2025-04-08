#!/bin/bash

# Run all standalone tests
echo "Running all standalone tests..."
echo "==============================="

# Find and execute all test scripts
find . -name "run_tests.sh" -type f -exec sh -c 'echo "\n\033[1;34mRunning {}\033[0m"; sh {}' \;

# Run Swift Package tests
echo -e "\n\033[1;34mRunning Swift Package tests\033[0m"
cd ..
swift run

echo -e "\n\033[1;32mAll standalone tests completed!\033[0m" 