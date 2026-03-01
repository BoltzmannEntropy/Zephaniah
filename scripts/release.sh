#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
WEBSITE_DIR="$(dirname "$PROJECT_DIR")/ZephaniahWEB"
APP_NAME="Zephaniah"

usage() {
  cat <<'EOF'
Usage: ./scripts/release.sh [version] [options]

Options:
  --upload           Upload artifacts to GitHub Release (default: enabled)
  --no-upload        Skip GitHub Release upload
  --sync-website     Update website download links (default: enabled)
  --no-sync-website  Skip website sync
  -h, --help         Show this help
EOF
}

read_version_from_pubspec() {
  local pubspec="$PROJECT_DIR/pubspec.yaml"
  if [ -f "$pubspec" ]; then
    grep '^version:' "$pubspec" | head -1 | cut -d'+' -f1 | cut -d':' -f2 | xargs
  fi
}

VERSION=""
UPLOAD_TO_GITHUB=true
SYNC_WEBSITE=true

while [[ $# -gt 0 ]]; do
  case "$1" in
    --upload)
      UPLOAD_TO_GITHUB=true
      ;;
    --no-upload)
      UPLOAD_TO_GITHUB=false
      ;;
    --sync-website)
      SYNC_WEBSITE=true
      ;;
    --no-sync-website)
      SYNC_WEBSITE=false
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    --*)
      echo "Unknown option: $1" >&2
      usage
      exit 1
      ;;
    *)
      if [ -z "$VERSION" ]; then
        VERSION="$1"
      else
        echo "Unexpected extra argument: $1" >&2
        usage
        exit 1
      fi
      ;;
  esac
  shift
done

if [ -z "$VERSION" ]; then
  VERSION="$(read_version_from_pubspec)"
fi
if [ -z "$VERSION" ]; then
  echo "Unable to determine version from pubspec.yaml" >&2
  exit 1
fi

DIST_DIR="$PROJECT_DIR/dist"
DMG_PATH="$DIST_DIR/${APP_NAME}-${VERSION}-macos.dmg"
DMG_SHA_PATH="$DMG_PATH.sha256"
SRC_ZIP_PATH="$DIST_DIR/${APP_NAME}-${VERSION}-source.zip"
SRC_SHA_PATH="$SRC_ZIP_PATH.sha256"
RN_PATH="$DIST_DIR/${APP_NAME}-${VERSION}-RELEASE_NOTES.md"
RN_SHA_PATH="$RN_PATH.sha256"
TAG="v$VERSION"
NOTES_FILE="$PROJECT_DIR/RELEASE_NOTES.md"

echo "=== Zephaniah Release ==="
echo "Version: $VERSION"
echo "Upload to GitHub: $UPLOAD_TO_GITHUB"
echo "Sync website: $SYNC_WEBSITE"
echo ""

# Build release artifacts only (release upload + sync are handled by this script)
"$SCRIPT_DIR/build_dmg.sh" "$VERSION"

if [ "$UPLOAD_TO_GITHUB" = true ]; then
  command -v gh >/dev/null || {
    echo "GitHub CLI (gh) not found. Install with: brew install gh" >&2
    exit 1
  }
  gh auth status >/dev/null || {
    echo "Not authenticated with GitHub. Run: gh auth login" >&2
    exit 1
  }

  for required in "$DMG_PATH" "$DMG_SHA_PATH" "$SRC_ZIP_PATH" "$SRC_SHA_PATH" "$RN_PATH" "$RN_SHA_PATH"; do
    [ -f "$required" ] || {
      echo "Missing required release asset: $required" >&2
      exit 1
    }
  done

  if ! gh release view "$TAG" >/dev/null 2>&1; then
    gh release create "$TAG" --title "$APP_NAME $VERSION" --notes-file "$NOTES_FILE" --draft
  else
    gh release edit "$TAG" --title "$APP_NAME $VERSION" --notes-file "$NOTES_FILE"
  fi

  gh release upload "$TAG" \
    "$DMG_PATH" "$DMG_SHA_PATH" \
    "$SRC_ZIP_PATH" "$SRC_SHA_PATH" \
    "$RN_PATH" "$RN_SHA_PATH" \
    --clobber
fi

if [ "$SYNC_WEBSITE" = true ]; then
  WEBSITE_INDEX="$WEBSITE_DIR/index.html"
  [ -f "$WEBSITE_INDEX" ] || {
    echo "Website index not found: $WEBSITE_INDEX" >&2
    exit 1
  }

  sed -i '' -E "s|/releases/download/v[0-9]+\\.[0-9]+\\.[0-9]+/Zephaniah-[0-9]+\\.[0-9]+\\.[0-9]+-macos\\.dmg|/releases/download/v$VERSION/Zephaniah-$VERSION-macos.dmg|g" "$WEBSITE_INDEX"
  sed -i '' -E "s|v[0-9]+\\.[0-9]+\\.[0-9]+ \\&bull; macOS|v$VERSION \\&bull; macOS|g" "$WEBSITE_INDEX"

  (
    cd "$WEBSITE_DIR"
    if ! git diff --quiet; then
      git add index.html
      git commit -m "Update to v$VERSION"
      git push
    fi
  )
fi
