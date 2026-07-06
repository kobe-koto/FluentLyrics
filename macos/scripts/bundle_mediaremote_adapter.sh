#!/bin/sh
set -eu

PROJECT_ROOT="$(cd "$PROJECT_DIR/.." && pwd)"
VENDOR_DIR="$PROJECT_ROOT/third_party/mediaremote-adapter"
SCRIPT_SRC="$VENDOR_DIR/bin/mediaremote-adapter.pl"
FRAMEWORK_SRC="$VENDOR_DIR/MediaRemoteAdapter.framework"
HELPER_SRC="$VENDOR_DIR/MediaRemoteAdapterTestClient"
DEST_DIR="$TARGET_BUILD_DIR/$UNLOCALIZED_RESOURCES_FOLDER_PATH/MediaRemoteAdapter"

fail() {
  echo "error: $1" >&2
  echo "error: run ./tool/macos_prepare_mediaremote_adapter.sh on macOS to prepare bundled adapter artifacts." >&2
  exit 1
}

[ -f "$SCRIPT_SRC" ] || fail "Missing $SCRIPT_SRC"
[ -d "$FRAMEWORK_SRC" ] || fail "Missing $FRAMEWORK_SRC"
[ -f "$FRAMEWORK_SRC/MediaRemoteAdapter" ] || fail "Invalid framework: $FRAMEWORK_SRC"

rm -rf "$DEST_DIR"
mkdir -p "$DEST_DIR"

cp "$SCRIPT_SRC" "$DEST_DIR/mediaremote-adapter.pl"
chmod 755 "$DEST_DIR/mediaremote-adapter.pl"

ditto "$FRAMEWORK_SRC" "$DEST_DIR/MediaRemoteAdapter.framework"

if [ -f "$HELPER_SRC" ]; then
  cp "$HELPER_SRC" "$DEST_DIR/MediaRemoteAdapterTestClient"
  chmod 755 "$DEST_DIR/MediaRemoteAdapterTestClient"
fi

if [ "${CODE_SIGNING_ALLOWED:-YES}" != "NO" ]; then
  SIGN_IDENTITY="${EXPANDED_CODE_SIGN_IDENTITY:-}"
  if [ -z "$SIGN_IDENTITY" ]; then
    SIGN_IDENTITY="-"
  fi

  /usr/bin/codesign --force --deep --sign "$SIGN_IDENTITY" \
    "$DEST_DIR/MediaRemoteAdapter.framework"

  if [ -f "$DEST_DIR/MediaRemoteAdapterTestClient" ]; then
    /usr/bin/codesign --force --sign "$SIGN_IDENTITY" \
      "$DEST_DIR/MediaRemoteAdapterTestClient"
  fi
fi

echo "Bundled mediaremote-adapter into $DEST_DIR"
