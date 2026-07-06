#!/bin/sh
set -eu

VERSION="${1:-v0.7.6}"

if [ "$(uname -s)" != "Darwin" ]; then
  echo "error: MediaRemoteAdapter.framework must be built on macOS." >&2
  exit 1
fi

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
VENDOR_DIR="$ROOT_DIR/third_party/mediaremote-adapter"
WORK_DIR="${TMPDIR:-/tmp}/fluent_lyrics_mediaremote_adapter_${VERSION}"
ARCHIVE="$WORK_DIR/source.tar.gz"
SOURCE_DIR="$WORK_DIR/source"
BUILD_DIR="$WORK_DIR/build"
ARCHIVE_URL="https://github.com/ungive/mediaremote-adapter/archive/refs/tags/$VERSION.tar.gz"

require_command() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "error: required command not found: $1" >&2
    exit 1
  fi
}

require_command curl
require_command cmake
require_command tar

rm -rf "$WORK_DIR"
mkdir -p "$SOURCE_DIR" "$BUILD_DIR" "$VENDOR_DIR/bin"

curl -fL "$ARCHIVE_URL" -o "$ARCHIVE"
tar -xzf "$ARCHIVE" -C "$SOURCE_DIR" --strip-components=1

cmake -S "$SOURCE_DIR" -B "$BUILD_DIR" -DCMAKE_BUILD_TYPE=Release
cmake --build "$BUILD_DIR" --config Release

rm -rf "$VENDOR_DIR/MediaRemoteAdapter.framework"
cp -R "$BUILD_DIR/MediaRemoteAdapter.framework" \
  "$VENDOR_DIR/MediaRemoteAdapter.framework"

if [ -f "$BUILD_DIR/MediaRemoteAdapterTestClient" ]; then
  cp "$BUILD_DIR/MediaRemoteAdapterTestClient" \
    "$VENDOR_DIR/MediaRemoteAdapterTestClient"
  chmod 755 "$VENDOR_DIR/MediaRemoteAdapterTestClient"
fi

cp "$SOURCE_DIR/bin/mediaremote-adapter.pl" \
  "$VENDOR_DIR/bin/mediaremote-adapter.pl"
chmod 755 "$VENDOR_DIR/bin/mediaremote-adapter.pl"

cp "$SOURCE_DIR/LICENSE" "$VENDOR_DIR/LICENSE"
printf '%s\n' "$VERSION" > "$VENDOR_DIR/VERSION"

echo "Prepared mediaremote-adapter $VERSION in $VENDOR_DIR"
