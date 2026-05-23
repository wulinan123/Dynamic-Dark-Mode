#!/bin/bash
set -euo pipefail

CONFIGURATION="${CONFIGURATION:-Release}"
DERIVED_DATA_PATH="${DERIVED_DATA_PATH:-build/DerivedData}"
ARTIFACT_DIR="${ARTIFACT_DIR:-build/artifacts}"
WORKSPACE="Dynamic Dark Mode.xcworkspace"
SCHEME="Dynamic Dark Mode"
APP_PATH="$DERIVED_DATA_PATH/Build/Products/$CONFIGURATION/Dynamic Dark Mode.app"
DMG_PATH="$ARTIFACT_DIR/Dynamic-Dark-Mode-$CONFIGURATION.dmg"

usage() {
  cat <<'USAGE'
Usage: ./create_dmg_and_release.sh [--configuration Debug|Release] [--release-tag TAG]

Builds Dynamic Dark Mode and creates a DMG. A GitHub release is created only
when --release-tag is provided. The gh CLI must already be authenticated for
release publishing.
USAGE
}

RELEASE_TAG=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --configuration)
      CONFIGURATION="${2:?Missing configuration value}"
      shift 2
      ;;
    --release-tag)
      RELEASE_TAG="${2:?Missing release tag}"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 64
      ;;
  esac
done

if [[ "$CONFIGURATION" != "Debug" && "$CONFIGURATION" != "Release" ]]; then
  echo "Configuration must be Debug or Release." >&2
  exit 64
fi

if ! command -v xcodebuild >/dev/null 2>&1; then
  echo "xcodebuild is required. Install Xcode and select it with xcode-select." >&2
  exit 69
fi

mkdir -p "$ARTIFACT_DIR"
CURRENT_ARCH="$(uname -m)"

xcodebuild \
  -workspace "$WORKSPACE" \
  -scheme "$SCHEME" \
  -configuration "$CONFIGURATION" \
  -destination "platform=macOS" \
  -derivedDataPath "$DERIVED_DATA_PATH" \
  ARCHS="$CURRENT_ARCH" \
  ONLY_ACTIVE_ARCH=YES \
  COMPILER_INDEX_STORE_ENABLE=NO \
  build

if [[ ! -d "$APP_PATH" ]]; then
  echo "Built app not found at $APP_PATH" >&2
  exit 66
fi

hdiutil create \
  -volname "Dynamic-Dark-Mode" \
  -srcfolder "$APP_PATH" \
  -ov \
  -format UDZO \
  "$DMG_PATH"

echo "Created $DMG_PATH"

if [[ -n "$RELEASE_TAG" ]]; then
  if ! command -v gh >/dev/null 2>&1; then
    echo "gh is required to publish a release." >&2
    exit 69
  fi
  gh release view "$RELEASE_TAG" >/dev/null 2>&1 \
    || gh release create "$RELEASE_TAG" --title "Release $RELEASE_TAG" --notes "Release $RELEASE_TAG"
  gh release upload "$RELEASE_TAG" "$DMG_PATH" --clobber
fi
