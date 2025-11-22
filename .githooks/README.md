# Git Hooks

This directory contains shared git hooks for the MentorMe project.

## What are Git Hooks?

Git hooks are scripts that run automatically at certain points in the git workflow (e.g., before committing). They help enforce code quality and prevent issues.

## Available Hooks

### `pre-commit`

Automatically runs local CI/CD validation before every commit.

**What it does:**
- Runs `./scripts/local-ci-build.sh --skip-build`
- Validates code with Flutter analyzer
- Runs all tests (37+ tests)
- Validates schema integrity
- Checks provider tests

**Result:**
- ✅ If passes: commit proceeds
- ❌ If fails: commit is aborted

This **prevents CI/CD failures** by catching issues before you push!

## Installation

### Quick Install (Recommended)

Run from the repository root:

```bash
./.githooks/install.sh
```

This will:
1. Copy hooks from `.githooks/` to `.git/hooks/`
2. Make them executable
3. Enable automatic validation

### Manual Install

```bash
cp .githooks/pre-commit .git/hooks/pre-commit
chmod +x .git/hooks/pre-commit
```

### Verification

Check the hook is installed:

```bash
ls -la .git/hooks/pre-commit
# Should show: -rwxr-xr-x (executable)
```

## Usage

Once installed, the hooks run automatically:

```bash
# 1. Make changes
vim lib/screens/chat_screen.dart

# 2. Stage changes
git add lib/screens/chat_screen.dart

# 3. Commit (hook runs automatically)
git commit -m "Add new feature"
# → Hook validates your code
# → If passes: commit succeeds
# → If fails: commit aborted

# 4. Push
git push
```

## Bypassing Hooks (Emergency Only)

If you **absolutely must** commit without validation:

```bash
git commit --no-verify -m "Emergency fix"
```

⚠️ **Warning:** This may cause CI/CD failures. Only use in emergencies!

## Why Use Hooks?

### Before Hooks ❌
1. Make changes
2. Commit
3. Push
4. Wait 5-10 minutes for CI/CD
5. **Build fails** (missing import, test failure, etc.)
6. Fix issue
7. Repeat steps 2-6

### With Hooks ✅
1. Make changes
2. Commit → **Hook validates locally (1-2 minutes)**
3. If fails: Fix immediately
4. Push with confidence
5. **CI/CD passes!**

## Benefits

- 🚀 **Faster feedback** - Know in 1-2 minutes vs waiting for CI/CD
- 🛡️ **Prevent failures** - Catch issues before they reach CI/CD
- 💰 **Save time** - No more failed builds and re-pushes
- ✅ **Quality assurance** - All commits are pre-validated

## For Repository Maintainers

### Adding New Hooks

1. Create hook file in `.githooks/` (e.g., `.githooks/commit-msg`)
2. Make it executable: `chmod +x .githooks/commit-msg`
3. Update `install.sh` to copy the new hook
4. Update this README
5. Commit and push

### Updating Existing Hooks

1. Edit the hook file in `.githooks/`
2. Commit and push
3. All developers must re-run `.githooks/install.sh` to update their local hooks

**Note:** Changes to hooks in `.githooks/` do NOT automatically update `.git/hooks/`. Developers must reinstall.

## Troubleshooting

**Hook not running:**
```bash
# Verify installation
ls -la .git/hooks/pre-commit

# Reinstall
./.githooks/install.sh
```

**Hook fails with "permission denied":**
```bash
chmod +x .git/hooks/pre-commit
```

**Hook fails with "script not found":**
```bash
# Ensure you're in the repository root
pwd
# Should be: /path/to/mentor-me-fork

# Check script exists
ls -la scripts/local-ci-build.sh
```

## Technical Details

**Why `.githooks/` instead of `.git/hooks/`?**

- `.git/` is **never committed** (in `.gitignore`)
- `.githooks/` **is tracked** and shared with all developers
- Installation script copies from `.githooks/` → `.git/hooks/`

**Hook execution:**

When you run `git commit`:
1. Git checks `.git/hooks/pre-commit`
2. If exists and executable, Git runs it
3. If script exits with code 0: commit proceeds
4. If script exits with non-zero: commit aborted

## Further Reading

- [Git Hooks Documentation](https://git-scm.com/docs/githooks)
- [Local CI/CD Script](../scripts/README.md#local-ci-build)
