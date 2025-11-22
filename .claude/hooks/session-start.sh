#!/bin/bash
set -euo pipefail

# Only run in Claude Code web environment
if [ "${CLAUDE_CODE_REMOTE:-}" != "true" ]; then
  echo "Skipping session-start hook (not in Claude Code web environment)"
  exit 0
fi

echo "=== MentorMe Flutter SessionStart Hook ==="
echo "Setting up Flutter development environment..."

# Configuration
FLUTTER_VERSION="3.27.1"
FLUTTER_CHANNEL="stable"
# Handle empty $HOME (use /root as fallback)
HOME_DIR="${HOME:-/root}"
FLUTTER_INSTALL_DIR="$HOME_DIR/flutter"

# Function to install Flutter SDK
install_flutter() {
  echo "Installing Flutter SDK ${FLUTTER_VERSION}..."

  # Download Flutter SDK
  cd "$HOME_DIR"
  wget -q --show-progress "https://storage.googleapis.com/flutter_infra_release/releases/${FLUTTER_CHANNEL}/linux/flutter_linux_${FLUTTER_VERSION}-${FLUTTER_CHANNEL}.tar.xz" -O flutter.tar.xz

  # Extract Flutter
  tar xf flutter.tar.xz
  rm flutter.tar.xz

  echo "Flutter SDK installed successfully"
}

# Check if Flutter is already installed
if [ ! -d "$FLUTTER_INSTALL_DIR" ]; then
  install_flutter
else
  echo "Flutter SDK already installed at $FLUTTER_INSTALL_DIR"
fi

# Add Flutter to PATH for this session
export PATH="$FLUTTER_INSTALL_DIR/bin:$PATH"

# Persist Flutter PATH for all future commands in this session
if [ -n "${CLAUDE_ENV_FILE:-}" ]; then
  echo "export PATH=\"$FLUTTER_INSTALL_DIR/bin:\$PATH\"" >> "$CLAUDE_ENV_FILE"
  echo "Flutter added to PATH via CLAUDE_ENV_FILE"
fi

# Fix git ownership issues with Flutter SDK
git config --global --add safe.directory "$FLUTTER_INSTALL_DIR"

# Verify Flutter installation
echo "Verifying Flutter installation..."
flutter --version

# Configure Flutter for web development
echo "Configuring Flutter..."
flutter config --no-analytics
flutter config --enable-web

# Install Flutter dependencies
echo "Installing Flutter dependencies..."
cd "$CLAUDE_PROJECT_DIR"
flutter pub get

# Install proxy server dependencies for web development
if [ -d "proxy" ] && [ -f "proxy/package.json" ]; then
  echo "Installing proxy server dependencies..."
  cd proxy
  npm install
  cd "$CLAUDE_PROJECT_DIR"
  echo "Proxy dependencies installed"
fi

echo "=== Flutter environment setup complete! ==="
echo "You can now run:"
echo "  - flutter test       # Run tests"
echo "  - flutter analyze    # Run code analysis"
echo "  - flutter run -d chrome  # Run web app (requires: cd proxy && npm start in another terminal)"
