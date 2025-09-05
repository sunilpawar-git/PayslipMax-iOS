#!/bin/bash

# PayslipMax Git Hooks Installer
# Sets up quality gates in git workflow

echo "🔧 Installing PayslipMax git hooks..."

# Check if we're in a git repository
if [ ! -d ".git" ]; then
    echo "❌ Error: Not in a git repository"
    exit 1
fi

# Create hooks directory if it doesn't exist
mkdir -p .git/hooks

# Install pre-commit hook
if [ -f "Scripts/pre-commit-hook.sh" ]; then
    cp Scripts/pre-commit-hook.sh .git/hooks/pre-commit
    chmod +x .git/hooks/pre-commit
    echo "✅ Pre-commit hook installed"
else
    echo "❌ Error: Scripts/pre-commit-hook.sh not found"
    exit 1
fi

echo "🎉 Git hooks installation complete!"
echo "📝 Quality gates will now run before each commit"
echo "💡 To bypass quality gates (not recommended): git commit --no-verify" 