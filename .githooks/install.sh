#!/bin/bash
# Install git hooks from .githooks/ to .git/hooks/

echo "Installing git hooks..."

# Copy pre-commit hook
cp .githooks/pre-commit .git/hooks/pre-commit
chmod +x .git/hooks/pre-commit

echo "✅ Pre-commit hook installed at .git/hooks/pre-commit"
echo ""
echo "The hook will now run automatically before every commit."
echo "It validates your code to prevent CI/CD failures."
echo ""
echo "To bypass (NOT recommended): git commit --no-verify"
