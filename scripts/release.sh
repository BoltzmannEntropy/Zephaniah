#!/usr/bin/env bash
# =============================================================================
# Zephaniah - Release Script
# =============================================================================
# Wrapper for build_dmg.sh that performs a full release:
# - Builds DMG with checksums and source archive
# - Uploads to GitHub Releases
# - Updates website download links
#
# Usage:
#   ./scripts/release.sh [version]
#
# Examples:
#   ./scripts/release.sh 1.2.0
#   ./scripts/release.sh          # Uses version from pubspec.yaml
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Get version from argument or pubspec.yaml
if [ -n "${1:-}" ]; then
    VERSION="$1"
else
    VERSION=$(grep 'version:' "$PROJECT_DIR/pubspec.yaml" | head -1 | cut -d'+' -f1 | cut -d':' -f2 | xargs)
fi

echo "=== Zephaniah Full Release ==="
echo ""
echo "Version: $VERSION"
echo ""
echo "This will:"
echo "  1. Build the DMG"
echo "  2. Generate SHA256 checksum"
echo "  3. Create source code archive"
echo "  4. Upload to GitHub Releases (as draft)"
echo "  5. Update website download links"
echo ""
read -p "Continue? [y/N] " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Aborted."
    exit 0
fi

# Run build_dmg.sh with full release flags
exec "$SCRIPT_DIR/build_dmg.sh" "$VERSION" --upload --sync-website
