#!/bin/bash
set -euo pipefail

VERSION_STRING=$(echo "$RELEASE_VERSION" | sed 's/^v//')
IFS='+'
read -r -a parts <<< "$VERSION_STRING"
unset IFS

VERSION_NAME="${parts[0]}"
VERSION_CODE="${parts[1]:-}"

DIST_DIR="dist/$VERSION_STRING"
if [ ! -d "$DIST_DIR" ] && [ -n "$VERSION_CODE" ] && [ -d "dist/$VERSION_NAME+$VERSION_CODE" ]; then
    DIST_DIR="dist/$VERSION_NAME+$VERSION_CODE"
fi

if [ ! -d "$DIST_DIR" ]; then
    for dir in dist/*; do
        [ -d "$dir" ] || continue
        DIST_DIR="$dir"
        break
    done
fi

mkdir -p "$DIST_DIR"

if command -v rename.ul >/dev/null 2>&1; then
    RENAME_CMD="rename.ul"
elif command -v rename >/dev/null 2>&1 && rename --version 2>&1 | grep -q 'util-linux'; then
    RENAME_CMD="rename"
fi

rm -f "$DIST_DIR"/*.apk

for apk in build/app/outputs/flutter-apk/app-*-release.apk; do
    [ -e "$apk" ] || continue
    abi="${apk##*/app-}"
    abi="${abi%-release.apk}"
    cp "$apk" "$DIST_DIR/fluent_lyrics-$VERSION_NAME-$abi-android.apk"
done

if [ -n "${RENAME_CMD:-}" ]; then
    $RENAME_CMD -- "$VERSION_STRING" "$VERSION_NAME" "$DIST_DIR"/* 2>/dev/null || true
    $RENAME_CMD -- "$(basename "$DIST_DIR")" "$VERSION_NAME" "$DIST_DIR"/* 2>/dev/null || true
    $RENAME_CMD -- "-release" "" "$DIST_DIR"/* 2>/dev/null || true
fi
