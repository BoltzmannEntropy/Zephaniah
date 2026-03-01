#!/usr/bin/env bash
# =============================================================================
# Zephaniah - DMG Builder Script
# =============================================================================
# Creates a macOS DMG installer for distribution.
#
# Usage:
#   ./scripts/build_dmg.sh [version]                        # Build DMG only
#   ./scripts/build_dmg.sh [version] --upload               # Build and upload to GitHub
#   ./scripts/build_dmg.sh [version] --sync-website         # Build and update website
#   ./scripts/build_dmg.sh [version] --upload --sync-website # Full release
#
# Examples:
#   ./scripts/build_dmg.sh 1.1.0
#   ./scripts/build_dmg.sh 1.1.0 --upload --sync-website
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
PROJECT_DIR="$ROOT_DIR"
FLUTTER_DIR="$ROOT_DIR"
DIST_DIR="$ROOT_DIR/dist"
WEBSITE_DIR="$(dirname "$ROOT_DIR")/ZephaniahWEB"

# App info
APP_NAME="Zephaniah"

# Auto-extract version from pubspec.yaml if not provided
read_version_from_pubspec() {
    local pubspec="$ROOT_DIR/pubspec.yaml"
    if [ -f "$pubspec" ]; then
        grep '^version:' "$pubspec" | head -1 | cut -d'+' -f1 | cut -d':' -f2 | xargs
    fi
}

# First positional arg that doesn't start with -- is the version
VERSION=""
for arg in "$@"; do
    case $arg in
        --*) ;;
        *) VERSION="$arg" ;;
    esac
done

# Fall back to pubspec version or default
if [ -z "$VERSION" ]; then
    VERSION="$(read_version_from_pubspec)"
fi
if [ -z "$VERSION" ]; then
    VERSION="1.0.0"
fi

UPLOAD_TO_GITHUB=false
SYNC_WEBSITE=false

# Parse arguments
for arg in "$@"; do
    case $arg in
        --upload)
            UPLOAD_TO_GITHUB=true
            ;;
        --sync-website)
            SYNC_WEBSITE=true
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

# Embed license files in the app bundle
RESOURCES_DIR="$APP_PATH/Contents/Resources"
if [ -f "$PROJECT_DIR/LICENSE" ]; then
    cp "$PROJECT_DIR/LICENSE" "$RESOURCES_DIR/LICENSE"
fi
if [ -f "$PROJECT_DIR/BINARY-LICENSE.txt" ]; then
    cp "$PROJECT_DIR/BINARY-LICENSE.txt" "$RESOURCES_DIR/BINARY-LICENSE.txt"
fi

# =============================================================================
# Create Distribution Directory
# =============================================================================
mkdir -p "$DIST_DIR"
info ""
info "Creating DMG..."

DMG_NAME="$APP_NAME-$VERSION-macos.dmg"
DMG_PATH="$DIST_DIR/$DMG_NAME"

# Prepare DMG staging directory (include licenses at root)
DMG_STAGE="$DIST_DIR/dmg-stage"
rm -rf "$DMG_STAGE"
mkdir -p "$DMG_STAGE"
cp -R "$APP_PATH" "$DMG_STAGE/$APP_NAME.app"
ln -s /Applications "$DMG_STAGE/Applications"
if [ -f "$PROJECT_DIR/LICENSE" ]; then
    cp "$PROJECT_DIR/LICENSE" "$DMG_STAGE/LICENSE"
fi
if [ -f "$PROJECT_DIR/BINARY-LICENSE.txt" ]; then
    cp "$PROJECT_DIR/BINARY-LICENSE.txt" "$DMG_STAGE/BINARY-LICENSE.txt"
fi

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
        "$DMG_STAGE" \
        2>/dev/null || {
            # Fallback if create-dmg fails (e.g., missing icon)
            warn "create-dmg failed, falling back to hdiutil..."
            hdiutil create -volname "$APP_NAME" -srcfolder "$DMG_STAGE" \
                -ov -format UDZO "$DMG_PATH"
        }
else
    # Fallback to basic hdiutil
    info "Using hdiutil (install create-dmg for better DMG: brew install create-dmg)..."
    hdiutil create -volname "$APP_NAME" -srcfolder "$DMG_STAGE" \
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

# Copy release notes if present
RELEASE_NOTES_SRC="$ROOT_DIR/RELEASE_NOTES.md"
RELEASE_NOTES_NAME="${APP_NAME}-${VERSION}-RELEASE_NOTES.md"
if [ -f "$RELEASE_NOTES_SRC" ]; then
    cp "$RELEASE_NOTES_SRC" "$DIST_DIR/$RELEASE_NOTES_NAME"
    shasum -a 256 "$RELEASE_NOTES_NAME" > "$RELEASE_NOTES_NAME.sha256"
    ok "Release notes copied: $RELEASE_NOTES_NAME"
fi

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

# Generate source ZIP checksum
cd "$DIST_DIR"
shasum -a 256 "$SOURCE_ZIP_NAME" > "$SOURCE_ZIP_NAME.sha256"
ok "Source checksum: $(cat "$SOURCE_ZIP_NAME.sha256")"
cd "$ROOT_DIR"

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

    NOTES_FILE="$ROOT_DIR/RELEASE_NOTES.md"
    DMG_SHA_PATH="$DIST_DIR/$DMG_NAME.sha256"
    SOURCE_SHA_PATH="$DIST_DIR/$SOURCE_ZIP_NAME.sha256"
    RELEASE_NOTES_PATH="$DIST_DIR/$RELEASE_NOTES_NAME"
    RELEASE_NOTES_SHA_PATH="$DIST_DIR/$RELEASE_NOTES_NAME.sha256"

    # Check if release exists, create if not
    if ! gh release view "$TAG" &> /dev/null; then
        info "Creating release $TAG..."
        if [ -f "$NOTES_FILE" ]; then
            gh release create "$TAG" \
                --title "$APP_NAME $VERSION" \
                --notes-file "$NOTES_FILE" \
                --draft
        else
            gh release create "$TAG" \
                --title "$APP_NAME $VERSION" \
                --notes "Release $APP_NAME $VERSION" \
                --draft
        fi
        ok "Release $TAG created as draft"
    elif [ -f "$NOTES_FILE" ]; then
        gh release edit "$TAG" --title "$APP_NAME $VERSION" --notes-file "$NOTES_FILE"
        ok "Release $TAG updated with latest release notes"
    fi

    # Upload assets (required release set)
    RELEASE_ASSETS=(
        "$DMG_PATH"
        "$DMG_SHA_PATH"
        "$SOURCE_ZIP_PATH"
        "$SOURCE_SHA_PATH"
    )
    if [ -f "$RELEASE_NOTES_PATH" ] && [ -f "$RELEASE_NOTES_SHA_PATH" ]; then
        RELEASE_ASSETS+=("$RELEASE_NOTES_PATH" "$RELEASE_NOTES_SHA_PATH")
    else
        warn "Release notes assets not found in dist/, uploading core assets only"
    fi

    info "Uploading release assets..."
    gh release upload "$TAG" "${RELEASE_ASSETS[@]}" --clobber
    ok "Uploaded ${#RELEASE_ASSETS[@]} assets to $TAG"

    echo ""
    echo -e "${GREEN}=== Upload Complete ===${NC}"
    echo "Release URL: $(gh release view "$TAG" --json url -q .url)"
    echo ""
    echo -e "${YELLOW}Note: Release is created as DRAFT. Publish it manually on GitHub.${NC}"
fi

# =============================================================================
# Sync Website (if --sync-website flag)
# =============================================================================
if [ "$SYNC_WEBSITE" = true ]; then
    info ""
    info "Syncing website with release v$VERSION..."

    WEBSITE_INDEX="$WEBSITE_DIR/index.html"

    if [ ! -f "$WEBSITE_INDEX" ]; then
        warn "Website not found at $WEBSITE_DIR. Skipping website sync."
    else
        # Update download URLs (replace any version pattern)
        sed -i '' -E "s|/releases/download/v[0-9]+\.[0-9]+\.[0-9]+/Zephaniah-[0-9]+\.[0-9]+\.[0-9]+-macos\.dmg|/releases/download/v$VERSION/Zephaniah-$VERSION-macos.dmg|g" "$WEBSITE_INDEX"
        ok "Updated download URLs to v$VERSION"

        # Update version display text
        sed -i '' -E "s|v[0-9]+\.[0-9]+\.[0-9]+ \&bull; macOS|v$VERSION \&bull; macOS|g" "$WEBSITE_INDEX"
        ok "Updated version display to v$VERSION"

        # Commit and push website changes
        cd "$WEBSITE_DIR"
        if git diff --quiet; then
            info "No website changes to commit"
        else
            git add index.html
            git commit -m "Update to v$VERSION"
            git push
            ok "Website changes pushed to GitHub"
        fi
        cd "$ROOT_DIR"

        echo ""
        echo -e "${GREEN}=== Website Synced ===${NC}"
        echo "Website will update shortly at: https://boltzmannentropy.github.io/zephaniah.github.io/"
    fi
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
echo "Source SHA: $DIST_DIR/$SOURCE_ZIP_NAME.sha256"
echo ""
echo "To install:"
echo "  1. Open $DMG_NAME"
echo "  2. Drag Zephaniah to Applications"
echo ""
if [ "$UPLOAD_TO_GITHUB" = false ] || [ "$SYNC_WEBSITE" = false ]; then
    echo "Additional options:"
    if [ "$UPLOAD_TO_GITHUB" = false ]; then
        echo "  --upload        Upload to GitHub Releases"
    fi
    if [ "$SYNC_WEBSITE" = false ]; then
        echo "  --sync-website  Update website download links"
    fi
    echo ""
    echo "Full release command:"
    echo "  ./scripts/build_dmg.sh $VERSION --upload --sync-website"
    echo ""
fi
