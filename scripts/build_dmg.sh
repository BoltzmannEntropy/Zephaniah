#!/usr/bin/env bash
# =============================================================================
# Zephaniah - DMG Builder Script
# =============================================================================
# Creates a macOS DMG installer for distribution.
# Run: ./scripts/build_dmg.sh
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
FLUTTER_DIR="$ROOT_DIR"
DIST_DIR="$ROOT_DIR/dist"

# App info
APP_NAME="Zephaniah"
VERSION="${1:-1.0.0}"

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
# Preflight Checks
# =============================================================================
info "=== Zephaniah DMG Builder ==="
echo ""
info "Version: $VERSION"
info "Building for macOS..."

# Check Flutter
if ! command -v flutter &> /dev/null; then
    fail "Flutter not found. Please install Flutter first."
fi
ok "Flutter found: $(flutter --version 2>&1 | head -1 | cut -d' ' -f2)"

# =============================================================================
# Build Flutter Release
# =============================================================================
info ""
info "Building Flutter release..."

cd "$FLUTTER_DIR"
flutter clean
flutter pub get
flutter build macos --release

APP_PATH="$FLUTTER_DIR/build/macos/Build/Products/Release/$APP_NAME.app"

if [ ! -d "$APP_PATH" ]; then
    fail "Build failed: $APP_PATH not found"
fi
ok "Build complete: $APP_PATH"

# =============================================================================
# Create Distribution Directory
# =============================================================================
mkdir -p "$DIST_DIR"
info ""
info "Creating DMG..."

DMG_NAME="$APP_NAME-$VERSION-macos.dmg"
DMG_PATH="$DIST_DIR/$DMG_NAME"

# Remove old DMG if exists
rm -f "$DMG_PATH"

# =============================================================================
# Create DMG
# =============================================================================
if command -v create-dmg &> /dev/null; then
    # Use create-dmg for professional DMG with background and icon layout
    info "Using create-dmg for professional DMG..."

    create-dmg \
        --volname "$APP_NAME" \
        --volicon "$FLUTTER_DIR/macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_512.png" \
        --window-pos 200 120 \
        --window-size 600 400 \
        --icon-size 100 \
        --icon "$APP_NAME.app" 150 185 \
        --app-drop-link 450 185 \
        --hide-extension "$APP_NAME.app" \
        "$DMG_PATH" \
        "$APP_PATH" \
        2>/dev/null || {
            # Fallback if create-dmg fails (e.g., missing icon)
            warn "create-dmg failed, falling back to hdiutil..."
            hdiutil create -volname "$APP_NAME" -srcfolder "$APP_PATH" \
                -ov -format UDZO "$DMG_PATH"
        }
else
    # Fallback to basic hdiutil
    info "Using hdiutil (install create-dmg for better DMG: brew install create-dmg)..."
    hdiutil create -volname "$APP_NAME" -srcfolder "$APP_PATH" \
        -ov -format UDZO "$DMG_PATH"
fi

if [ ! -f "$DMG_PATH" ]; then
    fail "DMG creation failed"
fi
ok "DMG created: $DMG_PATH"

# =============================================================================
# Generate Checksum
# =============================================================================
info ""
info "Generating SHA256 checksum..."

cd "$DIST_DIR"
shasum -a 256 "$DMG_NAME" > "$DMG_NAME.sha256"
ok "Checksum: $(cat "$DMG_NAME.sha256")"

# =============================================================================
# Summary
# =============================================================================
echo ""
echo -e "${GREEN}=== Build Complete ===${NC}"
echo ""
echo "DMG:      $DMG_PATH"
echo "Size:     $(du -h "$DMG_PATH" | cut -f1)"
echo "Checksum: $DIST_DIR/$DMG_NAME.sha256"
echo ""
echo "To install:"
echo "  1. Open $DMG_NAME"
echo "  2. Drag Zephaniah to Applications"
echo ""
