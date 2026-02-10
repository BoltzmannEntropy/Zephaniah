#!/usr/bin/env bash
# =============================================================================
# Zephaniah - Installation Script
# =============================================================================
# Sets up the development environment for Zephaniah.
# Run: ./install.sh
# =============================================================================

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

info()  { echo -e "${BLUE}$*${NC}"; }
ok()    { echo -e "${GREEN}✓ $*${NC}"; }
warn()  { echo -e "${YELLOW}$*${NC}"; }
fail()  { echo -e "${RED}✗ $*${NC}"; exit 1; }

# =============================================================================
# 1. Prerequisites
# =============================================================================
info "=== Zephaniah Installation ==="
echo ""
info "Checking prerequisites..."

# Check macOS
if [[ "$(uname)" != "Darwin" ]]; then
    warn "This installer is designed for macOS."
    warn "For other platforms, please install Flutter manually."
fi

# Homebrew
if ! command -v brew &> /dev/null; then
    warn "Homebrew not found. Installing..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi
ok "Homebrew"

# Xcode Command Line Tools
if ! xcode-select -p &> /dev/null; then
    info "Installing Xcode Command Line Tools..."
    xcode-select --install
    echo "Please complete the Xcode installation and run this script again."
    exit 0
fi
ok "Xcode Command Line Tools"

# =============================================================================
# 2. Flutter
# =============================================================================
echo ""
info "Checking Flutter..."

if ! command -v flutter &> /dev/null; then
    warn "Flutter not found. Installing via Homebrew..."
    brew install --cask flutter
fi

FLUTTER_VERSION=$(flutter --version 2>&1 | head -1)
ok "$FLUTTER_VERSION"

# Enable macOS desktop
info "Enabling macOS desktop support..."
flutter config --enable-macos-desktop 2>/dev/null || true
ok "macOS desktop enabled"

# =============================================================================
# 3. Flutter Dependencies
# =============================================================================
echo ""
info "Installing Flutter dependencies..."

cd "$ROOT_DIR"
flutter pub get
ok "Dependencies installed"

# =============================================================================
# 4. Verify Build
# =============================================================================
echo ""
info "Verifying Flutter project..."

# Check for common issues
if [ ! -f "$ROOT_DIR/pubspec.yaml" ]; then
    fail "pubspec.yaml not found. Are you in the right directory?"
fi

if [ ! -d "$ROOT_DIR/macos" ]; then
    fail "macos directory not found. Run: flutter create --platforms=macos ."
fi

# Run flutter doctor
info "Running Flutter doctor..."
flutter doctor --verbose 2>&1 | head -30

# =============================================================================
# 5. Create Required Directories
# =============================================================================
echo ""
info "Setting up directories..."

mkdir -p "$ROOT_DIR/.logs"
mkdir -p "$ROOT_DIR/.pids"
mkdir -p "$ROOT_DIR/dist"
ok "Directories created"

# =============================================================================
# 6. Make Scripts Executable
# =============================================================================
info "Setting script permissions..."

chmod +x "$ROOT_DIR/bin/zephaniahctl" 2>/dev/null || true
chmod +x "$ROOT_DIR/scripts/"*.sh 2>/dev/null || true
chmod +x "$ROOT_DIR/install.sh" 2>/dev/null || true
chmod +x "$ROOT_DIR/issues.sh" 2>/dev/null || true
ok "Scripts are executable"

# =============================================================================
# Done
# =============================================================================
echo ""
echo -e "${GREEN}=== Installation Complete ===${NC}"
echo ""
echo "To run Zephaniah:"
echo -e "  ${BLUE}./bin/zephaniahctl up${NC}"
echo ""
echo "Or run directly with Flutter:"
echo -e "  ${BLUE}flutter run -d macos${NC}"
echo ""
echo "To build a release DMG:"
echo -e "  ${BLUE}./scripts/build_dmg.sh${NC}"
echo ""
echo "For diagnostics/troubleshooting:"
echo -e "  ${BLUE}./issues.sh${NC}"
echo ""
