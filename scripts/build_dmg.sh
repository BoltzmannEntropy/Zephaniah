#!/usr/bin/env bash
# =============================================================================
# Zephaniah - DMG Builder Script
# =============================================================================
# Creates a macOS DMG installer for distribution.
#
# Usage:
#   ./scripts/build_dmg.sh [version]              # Build DMG only
#   ./scripts/build_dmg.sh [version] --upload     # Build and upload to GitHub
#
# Examples:
#   ./scripts/build_dmg.sh 1.0.0
#   ./scripts/build_dmg.sh 1.0.0 --upload
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
FLUTTER_DIR="$ROOT_DIR"
DIST_DIR="$ROOT_DIR/dist"

# App info
APP_NAME="Zephaniah"
VERSION="${1:-1.0.0}"
UPLOAD_TO_GITHUB=false

# Parse arguments
for arg in "$@"; do
    case $arg in
        --upload)
            UPLOAD_TO_GITHUB=true
            ;;
    esac
done

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
# Create Source Code Zip
# =============================================================================
info ""
info "Creating source code archive..."

SOURCE_ZIP_NAME="$APP_NAME-$VERSION-source.zip"
SOURCE_ZIP_PATH="$DIST_DIR/$SOURCE_ZIP_NAME"

# Remove old zip if exists
rm -f "$SOURCE_ZIP_PATH"

# Create zip excluding build artifacts and downloaded files
cd "$ROOT_DIR"
zip -r "$SOURCE_ZIP_PATH" . \
    -x "*.git/*" \
    -x "*build/*" \
    -x "*dist/*" \
    -x "*.dart_tool/*" \
    -x "*.pub-cache/*" \
    -x "*node_modules/*" \
    -x "*.idea/*" \
    -x "*.vscode/*" \
    -x "*.DS_Store" \
    -x "*.pub/*" \
    -x "*Pods/*" \
    -x "*.symlinks/*" \
    -x "*DerivedData/*" \
    -x "*.flutter-plugins*" \
    -x "*ephemeral/*" \
    -x "*.dmg" \
    -x "*.zip" \
    > /dev/null

if [ ! -f "$SOURCE_ZIP_PATH" ]; then
    fail "Source zip creation failed"
fi
ok "Source zip created: $SOURCE_ZIP_PATH ($(du -h "$SOURCE_ZIP_PATH" | cut -f1))"

# =============================================================================
# Upload to GitHub Release (if --upload flag)
# =============================================================================
if [ "$UPLOAD_TO_GITHUB" = true ]; then
    info ""
    info "Uploading to GitHub Release..."

    # Check gh CLI
    if ! command -v gh &> /dev/null; then
        fail "GitHub CLI (gh) not found. Install with: brew install gh"
    fi

    # Check if authenticated
    if ! gh auth status &> /dev/null; then
        fail "Not authenticated with GitHub. Run: gh auth login"
    fi

    TAG="v$VERSION"

    # Check if release exists, create if not
    if ! gh release view "$TAG" &> /dev/null; then
        info "Creating release $TAG..."
        gh release create "$TAG" \
            --title "$APP_NAME $VERSION" \
            --notes "## $APP_NAME $VERSION

### Downloads
- **DMG Installer**: $DMG_NAME
- **Source Code**: $SOURCE_ZIP_NAME

### Installation
1. Download the DMG file
2. Open it and drag Zephaniah to Applications
3. On first launch, right-click and select Open (macOS Gatekeeper)

### Checksums
\`\`\`
$(cat "$DIST_DIR/$DMG_NAME.sha256")
\`\`\`
" \
            --draft
        ok "Release $TAG created as draft"
    fi

    # Upload assets
    info "Uploading DMG..."
    gh release upload "$TAG" "$DMG_PATH" --clobber
    ok "Uploaded: $DMG_NAME"

    info "Uploading source zip..."
    gh release upload "$TAG" "$SOURCE_ZIP_PATH" --clobber
    ok "Uploaded: $SOURCE_ZIP_NAME"

    info "Uploading checksum..."
    gh release upload "$TAG" "$DIST_DIR/$DMG_NAME.sha256" --clobber
    ok "Uploaded: $DMG_NAME.sha256"

    echo ""
    echo -e "${GREEN}=== Upload Complete ===${NC}"
    echo "Release URL: $(gh release view "$TAG" --json url -q .url)"
    echo ""
    echo -e "${YELLOW}Note: Release is created as DRAFT. Publish it manually on GitHub.${NC}"
fi

# =============================================================================
# Summary
# =============================================================================
echo ""
echo -e "${GREEN}=== Build Complete ===${NC}"
echo ""
echo "DMG:        $DMG_PATH"
echo "Source:     $SOURCE_ZIP_PATH"
echo "Size:       DMG=$(du -h "$DMG_PATH" | cut -f1), Source=$(du -h "$SOURCE_ZIP_PATH" | cut -f1)"
echo "Checksum:   $DIST_DIR/$DMG_NAME.sha256"
echo ""
echo "To install:"
echo "  1. Open $DMG_NAME"
echo "  2. Drag Zephaniah to Applications"
echo ""
if [ "$UPLOAD_TO_GITHUB" = false ]; then
    echo "To upload to GitHub:"
    echo "  ./scripts/build_dmg.sh $VERSION --upload"
    echo ""
fi
